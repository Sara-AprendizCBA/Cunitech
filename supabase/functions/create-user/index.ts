// supabase/functions/create-user/index.ts
// Edge Function: crea un usuario en Supabase Auth (service_role) + fila en
// public.usuario + envía 1 correo con Resend. Solo puede invocarla un admin.
import { createClient } from 'supabase'

// ── Configuración / secretos (auto-inyectados por Supabase) ──────────────
const APP_URL = Deno.env.get('APP_URL') ?? 'http://localhost:60144'
const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY') ?? ''
const FROM_EMAIL = 'CUNITECH <onboarding@resend.dev>'

const ROLES_PERMITIDOS = ['admin', 'veterinario', 'ayudante']
const RE_EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

// ── CORS: solo el origen de la app (APP_URL) puede invocar ───────────────
const corsHeaders = {
  'Access-Control-Allow-Origin': APP_URL,
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

// Respuesta JSON estándar con cabeceras CORS.
function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// Genera una contraseña temporal aleatoria (16 caracteres) y segura.
function generarPassword(longitud = 16): string {
  const charset =
    'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%&*'
  const bytes = new Uint8Array(longitud)
  crypto.getRandomValues(bytes)
  return Array.from(bytes, (b) => charset[b % charset.length]).join('')
}

// Extrae el token del action_link de Supabase (fallback de hashed_token).
function extraerTokenDelLink(actionLink: string): string | null {
  try {
    return new URL(actionLink).searchParams.get('token')
  } catch {
    return null
  }
}

// Envía un correo con Resend. Lanza error si la API responde != 2xx.
async function enviarEmail(
  to: string,
  subject: string,
  html: string,
): Promise<void> {
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ from: FROM_EMAIL, to: [to], subject, html }),
  })
  if (!res.ok) {
    const detalle = await res.text()
    throw new Error(`Resend (${res.status}): ${detalle}`)
  }
}

// Plantilla: aviso al correo personal con botón para crear la contraseña.
function plantillaAviso(
  nombre: string,
  laboralEmail: string,
  enlace: string,
): string {
  return `<!DOCTYPE html>
<html lang="es"><body style="margin:0;background:#F5F3F0;padding:24px;">
  <div style="max-width:520px;margin:0 auto;background:#FFFFFF;border-radius:14px;padding:32px;font-family:Arial,Helvetica,sans-serif;color:#2C2C2C;">
    <h1 style="margin:0 0 16px;letter-spacing:3px;color:#9E7C5E;font-size:22px;">CUNITECH</h1>
    <p>Hola <strong>${nombre}</strong>,</p>
    <p>Tu cuenta en CUNITECH fue creada correctamente.</p>
    <p>Tu correo de acceso (login) es: <strong>${laboralEmail}</strong></p>
    <p>Para activar tu cuenta, crea tu contraseña con el siguiente botón:</p>
    <p style="text-align:center;margin:28px 0;">
      <a href="${enlace}" style="display:inline-block;background:#9E7C5E;color:#FFFFFF;text-decoration:none;font-weight:bold;padding:14px 28px;border-radius:10px;">Crear mi contraseña</a>
    </p>
    <p style="font-size:13px;color:#5A5A5A;">Si el botón no funciona, copia y pega este enlace en tu navegador:</p>
    <p style="font-size:12px;word-break:break-all;color:#9E7C5E;">${enlace}</p>
    <hr style="border:none;border-top:1px solid #E0E0E0;margin:24px 0;">
    <p style="font-size:12px;color:#888;">Este es un mensaje automático, por favor no responder.</p>
  </div>
</body></html>`
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
    // 1. Cliente con service_role (privilegios de administración de Auth).
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { autoRefreshToken: false, persistSession: false } },
    )

    // 2. Verificar que el solicitante esté autenticado (jwt del header).
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

    // 3. Verificar que su rol sea 'admin' (leído de public.usuario).
    const { data: perfil } = await supabaseAdmin
      .from('usuario')
      .select('rol')
      .eq('id_usuario', adminId)
      .maybeSingle()
    if (perfil?.rol !== 'admin') {
      return json({ error: 'Acceso denegado: se requiere rol admin' }, 403)
    }

    // 4. Validar inputs.
    const body = (await req.json().catch(() => ({}))) as Record<string, unknown>
    const personalEmail = String(body?.personalEmail ?? '').trim()
    const laboralEmail = String(body?.laboralEmail ?? '').trim().toLowerCase()
    const nombre = String(body?.nombre ?? '').trim()
    const rol = String(body?.rol ?? '').trim()

    if (!RE_EMAIL.test(personalEmail)) {
      return json({ error: 'Correo personal inválido' }, 400)
    }
    if (!RE_EMAIL.test(laboralEmail)) {
      return json({ error: 'Correo laboral inválido' }, 400)
    }
    if (!nombre) {
      return json({ error: 'El nombre es obligatorio' }, 400)
    }
    if (!ROLES_PERMITIDOS.includes(rol)) {
      return json({ error: 'Rol inválido' }, 400)
    }

    // 5. Crear el usuario en auth.users (auto-confirmado para poder loguearse).
    const passwordTemporal = generarPassword(16)
    const { data: creado, error: createError } =
      await supabaseAdmin.auth.admin.createUser({
        email: laboralEmail,
        email_confirm: true,
        password: passwordTemporal,
        user_metadata: { nombre, rol, personal_email: personalEmail },
      })
    if (createError || !creado?.user) {
      return json(
        {
          error: `No se pudo crear el usuario: ${
            createError?.message ?? 'desconocido'
          }`,
        },
        500,
      )
    }
    const userId = creado.user.id

    // 6. Insertar la fila en public.usuario (upsert por si un trigger ya la creó).
    const { error: perfilError } = await supabaseAdmin
      .from('usuario')
      .upsert(
        {
          id_usuario: userId,
          nombre,
          email: laboralEmail,
          rol,
          activo: true,
          created_by: adminId,
        },
        { onConflict: 'id_usuario' },
      )
    if (perfilError) {
      // Rollback best-effort para no dejar un usuario de Auth huérfano.
      await supabaseAdmin.auth.admin.deleteUser(userId).catch(() => {})
      return json(
        { error: `No se pudo crear el perfil: ${perfilError.message}` },
        500,
      )
    }

    // 7. Generar el enlace de invitación para crear la contraseña.
    //    Primario: 'invite'. Fallback: 'recovery' por si el correo ya está
    //    confirmado (email_confirm: true) y 'invite' no aplica.
    let tipoEnlace = 'invite'
    let linkResp = await supabaseAdmin.auth.admin.generateLink({
      type: 'invite',
      email: laboralEmail,
    })
    if (linkResp.error) {
      tipoEnlace = 'recovery'
      linkResp = await supabaseAdmin.auth.admin.generateLink({
        type: 'recovery',
        email: laboralEmail,
      })
    }
    if (linkResp.error || !linkResp.data?.properties) {
      return json(
        {
          error: `No se pudo generar la invitación: ${
            linkResp.error?.message ?? 'desconocido'
          }`,
        },
        500,
      )
    }
    const props = linkResp.data.properties
    const token =
      props.hashed_token ?? extraerTokenDelLink(props.action_link ?? '') ?? ''
    const enlace = `${APP_URL}/#/set-password?token=${token}&type=${tipoEnlace}`

    // 8. Enviar 1 correo con Resend (con el enlace para crear la contraseña)
    //    al correo personal. No se envía al correo laboral porque puede ser
    //    ficticio (p. ej. @cunitech.com sin verificar) y rebotaría.
    try {
      await enviarEmail(
        personalEmail,
        'Bienvenido a CUNITECH — Crea tu contraseña',
        plantillaAviso(nombre, laboralEmail, enlace),
      )
    } catch (emailError) {
      return json(
        {
          error: `Usuario creado, pero fallaron los correos: ${
            String(emailError)
          }`,
        },
        500,
      )
    }

    // 9. Éxito.
    return json({ success: true, userId }, 200)
  } catch (err) {
    return json({ error: `Error interno: ${String(err)}` }, 500)
  }
})
