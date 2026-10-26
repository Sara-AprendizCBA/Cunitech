// supabase/functions/identify-breed/index.ts
// Edge Function: recibe una foto de un conejo en Base64 y pide a Gemini 2.0
// Flash que identifique la raza. Devuelve { raza, confianza, descripcion }.
// La API key de Gemini vive en los secretos de Supabase (GEMINI_API_KEY),
// nunca en el cliente. Solo usuarios autenticados.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ── Configuración / secretos (auto-inyectados por Supabase) ──────────────
const APP_URL = Deno.env.get('APP_URL') ?? 'http://localhost:60144'
const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY') ?? ''
const GEMINI_MODEL = 'gemini-2.0-flash'
const GEMINI_URL =
  `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`

// ── CORS ────────────────────────────────────────────────────────────────
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

type IdentificacionRaza = {
  raza: string
  confianza: 'alta' | 'media' | 'baja'
  descripcion: string
}

// Resultado por defecto (si Gemini falla o responde inválido).
const IDENTIFICACION_FALLBACK: IdentificacionRaza = {
  raza: 'No identificada',
  confianza: 'baja',
  descripcion: 'La IA de Google no pudo procesar la imagen',
}

const PROMPT =
  'Eres un experto en cunicultura. Identifica la raza del conejo en la ' +
  'imagen. Si la imagen no es clara, responde con raza "No identificada" y ' +
  'confianza "baja". Devuelve un JSON con ' +
  '{ "raza": "...", "confianza": "alta/media/baja", "descripcion": "..." }.'

const RESPONSE_SCHEMA = {
  type: 'OBJECT',
  properties: {
    raza: { type: 'STRING' },
    confianza: { type: 'STRING', enum: ['alta', 'media', 'baja'] },
    descripcion: { type: 'STRING' },
  },
  required: ['raza', 'confianza', 'descripcion'],
}

// Normaliza la salida de Gemini a una identificación válida.
function parsearIdentificacion(texto: string): IdentificacionRaza | null {
  try {
    const limpio = texto.trim().replace(/^```json\s*/i, '').replace(/```$/, '')
      .trim()
    const data = JSON.parse(limpio)
    if (!data || typeof data !== 'object') return null
    const raza = String(data.raza ?? '').trim()
    if (!raza) return null
    const confianzaCruda = String(data.confianza ?? 'media').trim()
      .toLowerCase()
    const confianza = ['alta', 'media', 'baja'].includes(confianzaCruda)
      ? confianzaCruda as IdentificacionRaza['confianza']
      : 'media'
    return {
      raza,
      confianza,
      descripcion: String(data.descripcion ?? '').trim(),
    }
  } catch {
    return null
  }
}

// Llama a la API de Gemini con la imagen en Base64 y devuelve la
// identificación, o null si falla.
async function identificarConGemini(imagenBase64: string): Promise<IdentificacionRaza | null> {
  if (!GEMINI_API_KEY) return null
  try {
    const res = await fetch(`${GEMINI_URL}?key=${GEMINI_API_KEY}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{
          role: 'user',
          parts: [
            { text: PROMPT },
            {
              inline_data: {
                mime_type: 'image/jpeg',
                data: imagenBase64,
              },
            },
          ],
        }],
        generationConfig: {
          temperature: 0.2,
          responseMimeType: 'application/json',
          responseSchema: RESPONSE_SCHEMA,
        },
      }),
    })
    if (!res.ok) {
      console.error(`Gemini (${res.status}): ${await res.text()}`)
      return null
    }
    const data = await res.json()
    const texto: string = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
    return parsearIdentificacion(texto)
  } catch (err) {
    console.error(`Error llamando a Gemini: ${String(err)}`)
    return null
  }
}

Deno.serve(async (req) => {
  // Preflight CORS.
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  if (req.method !== 'POST') {
    return json({ error: 'Método no permitido' }, 405)
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { autoRefreshToken: false, persistSession: false } },
    )

    // 1. Verificar autenticación (jwt del header).
    const authHeader = req.headers.get('Authorization') ?? ''
    const jwt = authHeader.replace('Bearer ', '').trim()
    if (!jwt) return json({ error: 'No autenticado' }, 401)
    const { data: userData, error: userError } = await supabaseAdmin.auth
      .getUser(jwt)
    if (userError || !userData?.user) {
      return json({ error: 'Token inválido' }, 401)
    }

    // 2. Leer la imagen enviada por la app (Base64 de un JPEG).
    const body = (await req.json().catch(() => ({}))) as Record<string, unknown>
    const imagenBase64 = typeof body?.imagen_base64 === 'string'
      ? body.imagen_base64.trim()
      : ''
    if (!imagenBase64) {
      return json({ error: 'Falta la imagen (imagen_base64)' }, 400)
    }

    // 3. Pedir la identificación a Gemini (con fallback si falla).
    const identificacion = await identificarConGemini(imagenBase64) ??
      IDENTIFICACION_FALLBACK

    // 4. Responder.
    return json({
      success: true,
      modelo: GEMINI_MODEL,
      ...identificacion,
    })
  } catch (err) {
    // Ante cualquier error inesperado, la app recibe el fallback.
    return json({
      success: true,
      ...IDENTIFICACION_FALLBACK,
      error: `Error interno: ${String(err)}`,
    })
  }
})
