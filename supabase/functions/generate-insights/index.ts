// supabase/functions/generate-insights/index.ts
// Edge Function: recibe el contexto del criadero y pide a Gemini 1.5 Flash
// un diagnóstico + 2-3 recomendaciones en JSON estricto. Si Gemini falla,
// devuelve un panel por defecto para que la app nunca se rompa.
// Solo usuarios autenticados.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ── Configuración / secretos (auto-inyectados por Supabase) ──────────────
const APP_URL = Deno.env.get('APP_URL') ?? 'http://localhost:60144'
const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY') ?? ''
const GEMINI_MODEL = 'gemini-3.5-flash-lite'
const GEMINI_URL =
  `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`

// ── CORS: solo el origen de la app (APP_URL) puede invocar ───────────────
const corsHeaders = {
  'Access-Control-Allow-Origin': APP_URL,
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

// Forma de una recomendación y del panel completo que devuelve Gemini.
type Recomendacion = {
  titulo: string
  detalle: string
  prioridad: string
  impacto: string
}

type PanelInsights = {
  diagnostico_general: string
  recomendaciones: Recomendacion[]
}

// Recomendaciones por defecto (si Gemini falla o responde inválido).
const RECOMENDACIONES_FALLBACK: Recomendacion[] = [
  {
    titulo: 'Revisa la tasa de fertilidad',
    detalle:
      'Analiza las montas fallidas y verifica el estado corporal de las conejas antes de programar nuevas montas.',
    prioridad: 'media',
    impacto: 'Mejora el porcentaje de montas efectivas.',
  },
  {
    titulo: 'Programa las palpaciones a tiempo',
    detalle:
      'Confirma la preñez entre el día 12 y 14 tras la monta para detectar a tiempo las conejas vacías.',
    prioridad: 'alta',
    impacto: 'Reduce los días perdidos por conejas vacías.',
  },
  {
    titulo: 'Mantén el registro al día',
    detalle:
      'Registra partos, destetes y alimentación para obtener mejores recomendaciones en el futuro.',
    prioridad: 'baja',
    impacto: 'Mejora la precisión de los análisis del criadero.',
  },
]

// Panel por defecto (fallback completo con diagnóstico + recomendaciones).
const PANEL_FALLBACK: PanelInsights = {
  diagnostico_general:
    'No se pudo contactar al asesor de IA en este momento. Estas son recomendaciones generales mientras tanto.',
  recomendaciones: RECOMENDACIONES_FALLBACK,
}

// Instrucciones y esquema para Gemini (JSON estricto).
const SYSTEM_PROMPT =
  `Eres un asesor experto en cunicultura. A partir del contexto del criadero ` +
  `(JSON) que recibirás, devuelve un diagnóstico general y entre 2 y 3 ` +
  `recomendaciones concretas y accionables para mejorar la productividad y el ` +
  `bienestar de los conejos. Responde ÚNICAMENTE con un JSON válido con la forma ` +
  `{"diagnostico_general":string,` +
  `"recomendaciones":[{"titulo":string,"detalle":string,` +
  `"prioridad":"alta"|"media"|"baja","impacto":string}]}.`

const RESPONSE_SCHEMA = {
  type: 'OBJECT',
  properties: {
    diagnostico_general: { type: 'STRING' },
    recomendaciones: {
      type: 'ARRAY',
      items: {
        type: 'OBJECT',
        properties: {
          titulo: { type: 'STRING' },
          detalle: { type: 'STRING' },
          prioridad: { type: 'STRING', enum: ['alta', 'media', 'baja'] },
          impacto: { type: 'STRING' },
        },
        required: ['titulo', 'detalle', 'prioridad', 'impacto'],
      },
    },
  },
  required: ['diagnostico_general', 'recomendaciones'],
}

// Normaliza la salida de Gemini a un panel (diagnóstico + recomendaciones).
function parsearRecomendaciones(texto: string): PanelInsights | null {
  try {
    const limpio = texto.trim().replace(/^```json\s*/i, '').replace(/```$/, '')
      .trim()
    const data = JSON.parse(limpio)
    const lista = Array.isArray(data) ? data : data?.recomendaciones
    if (!Array.isArray(lista)) return null
    const validas = lista
      .filter((r) => r && typeof r === 'object')
      .map((r) => ({
        titulo: String(r.titulo ?? '').trim(),
        detalle: String(r.detalle ?? '').trim(),
        prioridad: ['alta', 'media', 'baja'].includes(String(r.prioridad))
          ? String(r.prioridad)
          : 'media',
        impacto: String(r.impacto ?? '').trim(),
      }))
      .filter((r) => r.titulo && r.detalle)
    if (validas.length === 0) return null
    const diagnostico = String(
      (Array.isArray(data) ? '' : data?.diagnostico_general) ?? '',
    ).trim()
    return { diagnostico_general: diagnostico, recomendaciones: validas }
  } catch {
    return null
  }
}

// Llama a la API de Gemini y devuelve el panel, o null si falla.
async function generarConGemini(
  contexto: unknown,
): Promise<PanelInsights | null> {
  if (!GEMINI_API_KEY) return null
  try {
    const res = await fetch(`${GEMINI_URL}?key=${GEMINI_API_KEY}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
        contents: [{
          role: 'user',
          parts: [
            { text: `Contexto del criadero:\n${JSON.stringify(contexto)}` },
          ],
        }],
        generationConfig: {
          temperature: 0.7,
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
    return parsearRecomendaciones(texto)
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
    const userId = userData.user.id

    // 2. Leer el contexto enviado por la app (debe ser un objeto).
    const body = (await req.json().catch(() => ({}))) as Record<string, unknown>
    const contexto = body?.contexto && typeof body.contexto === 'object'
      ? body.contexto
      : {}

    // 3. Pedir el panel a Gemini (con fallback si falla).
    const generado = await generarConGemini(contexto)
    const panel = generado ?? PANEL_FALLBACK
    const fallback = generado === null

    // 4. Persistir el resultado (best-effort, no bloquea la respuesta).
    try {
      await supabaseAdmin.from('ai_insights').insert({
        user_id: userId,
        contexto,
        recomendaciones: panel.recomendaciones,
      })
    } catch (err) {
      console.error(`No se pudo guardar el insight: ${String(err)}`)
    }

    // 5. Responder.
    return json({
      success: true,
      fallback,
      modelo: GEMINI_MODEL,
      diagnostico_general: panel.diagnostico_general,
      recomendaciones: panel.recomendaciones,
      generado_en: new Date().toISOString(),
    })
  } catch (err) {
    // Ante cualquier error inesperado, la app recibe el panel por defecto.
    return json({
      success: true,
      fallback: true,
      diagnostico_general: PANEL_FALLBACK.diagnostico_general,
      recomendaciones: PANEL_FALLBACK.recomendaciones,
      error: `Error interno: ${String(err)}`,
    })
  }
})
