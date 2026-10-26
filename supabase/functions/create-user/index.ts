// supabase/functions/create-user/index.ts
// Edge Function: crea un usuario en Supabase Auth (service_role) con la
// contraseña definida por el admin e inserta su fila en public.usuario.
// Solo puede invocarla un usuario con rol 'admin'.
import { createClient } from 'supabase'

const ROLES_PERMITIDOS = ['admin', 'veterinario', 'ayudante', 'usuario']
const RE_EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

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

Deno.serve(async (req) => {
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

    const authHeader = req.headers.get('Authorization') ?? ''
    const jwt = authHeader.replace('Bearer ', '').trim()
    if (!jwt) {
      return json({ error: 'No autenticado' }, 401)
    }

    const { data: userData, error: userError } =
      await supabaseAdmin.auth.getUser(jwt)
    if (userError || !userData?.user) {
      return json({ error: 'Token inválido' }, 401)
    }
    const adminId = userData.user.id

    const { data: perfil, error: perfilError } = await supabaseAdmin
      .from('usuario')
      .select('rol')
      .eq('id_usuario', adminId)
      .maybeSingle()
    if (perfilError) {
      return json(
        { error: `No se pudo verificar el rol: ${perfilError.message}` },
        500,
      )
    }
    if (perfil?.rol !== 'admin') {
      return json({ error: 'Acceso denegado: se requiere rol admin' }, 403)
    }

    const body = (await req.json().catch(() => ({}))) as Record<string, unknown>
    const email = String(body?.email ?? '').trim().toLowerCase()
    const password = String(body?.password ?? '')
    const nombre = String(body?.nombre ?? '').trim()
    const rol = String(body?.rol ?? '').trim()

    if (!RE_EMAIL.test(email)) {
      return json({ error: 'Email inválido' }, 400)
    }
    if (!nombre) {
      return json({ error: 'El nombre es obligatorio' }, 400)
    }
    if (!ROLES_PERMITIDOS.includes(rol)) {
      return json({ error: 'Rol inválido' }, 400)
    }

    const { data: creado, error: createError } =
      await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
      })
    if (createError || !creado?.user) {
      return json(
        { error: createError?.message ?? 'No se pudo crear el usuario' },
        400,
      )
    }
    const idUsuario = creado.user.id

    const { error: insertError } = await supabaseAdmin
      .from('usuario')
      .upsert(
        {
          id_usuario: idUsuario,
          nombre,
          email,
          rol,
          activo: true,
          created_by: adminId,
        },
        { onConflict: 'id_usuario' },
      )
    if (insertError) {
      await supabaseAdmin.auth.admin.deleteUser(idUsuario).catch(() => {})
      return json({ error: insertError.message }, 500)
    }

    return json({ id_usuario: idUsuario }, 200)
  } catch (err) {
    return json({ error: `Error interno: ${String(err)}` }, 500)
  }
})
