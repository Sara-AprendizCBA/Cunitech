import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Se ejecuta una sola vez cuando la función arranca (cold start),
// y sirve como referencia para calcular cuánto tiempo lleva "viva" la instancia.
const startTime = Date.now()

Deno.serve(async (_req) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Ping real a la base de datos
    const { error } = await supabase
      .from('system_logs')
      .select('id')
      .limit(1)

    const isConnected = !error

    const uptimeSeconds = Math.floor((Date.now() - startTime) / 1000)

    const response = {
      status: isConnected ? 'ok' : 'error',
      uptime: uptimeSeconds,
      database: isConnected ? 'connected' : 'disconnected',
      timestamp: new Date().toISOString()
    }

    return new Response(JSON.stringify(response), {
      headers: { 'Content-Type': 'application/json' },
      status: 200
    })
  } catch (err) {
    return new Response(
      JSON.stringify({
        status: 'error',
        uptime: Math.floor((Date.now() - startTime) / 1000),
        database: 'disconnected',
        timestamp: new Date().toISOString()
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 500
      }
    )
  }
})