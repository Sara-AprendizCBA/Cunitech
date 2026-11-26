from fastapi import APIRouter
from datetime import date, timedelta
from app.services.supabase_client import supabase

router = APIRouter()

def logica_generar_alertas():
    try:
        respuesta = supabase.table("reproduccion").select("id_coneja, fecha_monta").execute()
        hoy = date.today()
        alertas_creadas = 0

        for reg in respuesta.data:
            if not reg.get("fecha_monta"):
                continue
                
            fecha_monta = date.fromisoformat(reg["fecha_monta"])
            fecha_parto = fecha_monta + timedelta(days=31)
            dias_restantes = (fecha_parto - hoy).days

            if 0 <= dias_restantes <= 3:
                usuarios = supabase.table("usuario").select("id_usuario").limit(1).execute()
                if not usuarios.data:
                    continue

                nueva_alerta = {
                    "mensaje": f"Alerta: La coneja ID {reg['id_coneja']} tiene parto estimado en {dias_restantes} días.",
                    "fecha_notificacion": str(hoy),
                    "leida": False,
                    "id_usuario": usuarios.data[0]["id_usuario"]
                }
                supabase.table("notificacion").insert(nueva_alerta).execute()
                alertas_creadas += 1
                
        print(f"[TAREA AUTOMÁTICA] Se generaron {alertas_creadas} alertas.")
        return alertas_creadas
    except Exception as e:
        print(f"Error en tarea automática: {e}")
        return 0

# 2. El endpoint sigue existiendo por si lo quieres probar manualmente
@router.post("/generar-alertas-partos")
def generar_alertas_partos():
    alertas = logica_generar_alertas()
    return {"estado": "Proceso completado", "alertas_creadas": alertas}