// supabase/functions/chat-assistant/index.ts
// Edge Function: asistente conversacional de CUNITECH. Verifica al usuario,
// recolecta el contexto real de su criadero (montas del mes, conejas con
// montas fallidas, total de conejos) y responde la pregunta con Gemini.
// La API key de Gemini vive en los secretos de Supabase (GEMINI_API_KEY).
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

// Formato 'yyyy-MM-dd' para columnas tipo date.
function dateOnly(d: Date): string {
  return d.toISOString().split('T')[0]
}

// Respuesta por defecto si Gemini falla.
const RESPUESTA_FALLBACK =
  'No pude procesar tu pregunta en este momento. Intenta de nuevo en unos segundos.'

const SYSTEM_PROMPT =
  'Eres CUNITECH, un asistente experto en cunicultura. Respondes preguntas ' +
  'del criador usando el contexto real de su criadero que se te entrega ' +
  '(JSON). Sé claro, breve y accionable. Si el contexto no alcanza para ' +
  'responder, dilo con franqueza y sugiere qué dato registrar.'

// Llama a Gemini con el contexto y la pregunta, o null si falla.
async function responderConGemini(
  contexto: unknown,
  pregunta: string,
): Promise<string | null> {
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
            {
              text:
                `Contexto del criadero (JSON):\n${JSON.stringify(contexto)}\n\n` +
                `Pregunta del criador: ${pregunta}`,
            },
          ],
        }],
        generationConfig: { temperature: 0.5 },
      }),
    })
    if (!res.ok) {
      console.error(`Gemini (${res.status}): ${await res.text()}`)
      return null
    }
    const data = await res.json()
    const texto: string = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
    return texto.trim() || null
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

    // 2. Leer el mensaje del usuario.
    const body = (await req.json().catch(() => ({}))) as Record<string, unknown>
    const mensaje = typeof body?.mensaje === 'string' ? body.mensaje.trim() : ''
    if (!mensaje) {
      return json({ error: 'Falta el mensaje' }, 400)
    }

    // 3. Recolectar el contexto real del criadero.
    const now = new Date()
    const inicioMes = dateOnly(new Date(now.getFullYear(), now.getMonth(), 1))
    const hoy = dateOnly(now)

    const montasMes = await supabaseAdmin
      .from('reproduccion')
      .select('estado')
      .eq('user_id', userId)
      .gte('fecha_monta', inicioMes)

    const montasExitosas =
      (montasMes.data ?? []).filter((r) =>
        ['Gestante', 'Lactante'].includes(String(r.estado))
      ).length
    const montasFallidas =
      (montasMes.data ?? []).filter((r) => String(r.estado) === 'Fallida')
        .length

    // Conejas con más de 2 montas fallidas.
    const fallidas = await supabaseAdmin
      .from('reproduccion')
      .select('id_coneja')
      .eq('user_id', userId)
      .eq('estado', 'Fallida')
    const conteoPorConeja = new Map<number, number>()
    for (const row of fallidas.data ?? []) {
      const id = row.id_coneja as number
      conteoPorConeja.set(id, (conteoPorConeja.get(id) ?? 0) + 1)
    }
    const conejasProblematicas = [...conteoPorConeja.entries()]
      .filter(([, count]) => count > 2)
      .map(([id, count]) => ({ id_coneja: id, montas_fallidas: count }))

    const totalConejos = await supabaseAdmin
      .from('conejo')
      .select('id_conejo', { count: 'exact', head: true })
      .eq('user_id', userId)

    const contexto = {
      fecha: hoy,
      mes: inicioMes.slice(0, 7),
      montas_exitosas_mes: montasExitosas,
      montas_fallidas_mes: montasFallidas,
      conejas_mas_de_2_montas_fallidas: conejasProblematicas,
      total_conejos: totalConejos.count ?? 0,
    }

    // 4. Pedir la respuesta a Gemini.
    const respuesta = await responderConGemini(contexto, mensaje) ??
      RESPUESTA_FALLBACK

    // 5. Responder.
    return json({
      success: true,
      modelo: GEMINI_MODEL,
      respuesta,
    })
  } catch (err) {
    return json({
      success: true,
      respuesta: RESPUESTA_FALLBACK,
      error: `Error interno: ${String(err)}`,
    })
  }
})
