// supabase/functions/generate-insights/index.ts
// Edge Function: recibe el contexto del criadero y pide a Gemini 2.0 Flash
// un diagnóstico + 2-3 recomendaciones en JSON estricto. Si Gemini falla,
// devuelve un panel por defecto para que la app nunca se rompa.
// Solo usuarios autenticados.
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
    'Ahora mismo no he podido revisar los datos del criadero, así que te ' +
    'dejo las recomendaciones generales que mejor funcionan en un momento ' +
    'como este. En cuanto vuelva a conectarme, te contaré qué veo en la ' +
    'mortalidad y en los partos de las últimas semanas.',
  recomendaciones: RECOMENDACIONES_FALLBACK,
}

// Instrucciones y esquema para Gemini (JSON estricto).
const SYSTEM_PROMPT =
  `Eres el asesor del criadero CUNITECH: alguien con años de experiencia en ` +
  `cunicultura que conoce a los criadores y habla con ellos de tú a tú, con ` +
  `calma y cariño, como un colega que quiere ayudar de verdad.\n` +
  `A partir del contexto del criadero (JSON) que recibirás, escribe:\n` +
  `1. "diagnostico_general": un párrafo breve (2-4 frases) que analice ` +
  `ESPECÍFICAMENTE la mortalidad y el historial de partos del periodo, ` +
  `cuando esos datos estén disponibles. Empieza por lo que has observado ` +
  `(por ejemplo: "He notado que la mortalidad ha subido un 10%") y termina ` +
  `dónde conviene empezar. Usa solo cifras que aparezcan en el contexto: ` +
  `si un dato no está, no lo menciones ni lo inventes.\n` +
  `2. "recomendaciones": entre 2 y 3 recomendaciones concretas y accionables ` +
  `para mejorar la productividad y el bienestar de los conejos. Escribe el ` +
  `"detalle" en frases completas y amables (nada de listas de pasos secos) y ` +
  `el "impacto" explicando qué se gana con esa acción. Usa "alta" como ` +
  `prioridad si la recomendación afecta a la mortalidad o al bienestar animal.\n` +
  `Escribe en español natural, con un máximo de un emoji por texto y sin ` +
  `markdown. Responde ÚNICAMENTE con un JSON válido con la forma ` +
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
          temperature: 0.8,
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
