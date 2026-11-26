from fastapi import FastAPI
from app.services.supabase_client import supabase
from app.api.routes import predictions
from apscheduler.schedulers.background import BackgroundScheduler 

app = FastAPI(title="CUNITECH API")

app.include_router(predictions.router, prefix="/api", tags=["Notificaciones"])

scheduler = BackgroundScheduler()
scheduler.add_job(predictions.logica_generar_alertas, 'cron', hour=6, minute=0)
scheduler.start()

@app.on_event("shutdown")
def shutdown_event():
    scheduler.shutdown()

@app.get("/")
def inicio():
    return {"mensaje": "API de CUNITECH funcionando"}

@app.get("/test-db")
def test_db():
    try:
        respuesta = supabase.table("coneja").select("*").limit(1).execute()
        return {"estado": "Conexión exitosa", "datos_de_prueba": respuesta.data}
    except Exception as e:
        return {"error": str(e)}