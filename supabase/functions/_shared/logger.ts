import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS'
}

export async function registrarLog(
  nivel: 'INFO' | 'WARNING' | 'ERROR',
  mensaje: string,
  origenIp: string
) {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { error } = await supabase.from('system_logs').insert({
      nivel,
      mensaje,
      origen_ip: origenIp
    })

    if (error) {
      console.error('No se pudo registrar el log:', error.message)
    }
  } catch (err) {
    console.error('No se pudo registrar el log:', err)
  }
}

export function obtenerIp(req: Request): string {
  const forwardedIp = req.headers.get('x-forwarded-for')?.split(',')[0].trim()
  const cloudflareIp = req.headers.get('cf-connecting-ip')?.trim()

  return forwardedIp || cloudflareIp || 'desconocida'
}