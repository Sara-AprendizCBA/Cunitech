from fastapi import FastAPI
from app.services.supabase_client import supabase

app = FastAPI(title="CUNITECH API")

@app.get("/")
def inicio():
    return {"mensaje": "API de CUNITECH funcionando"}

@app.get("/test-db")
def test_db():
    try:
        # Nota: Si tu tabla se llama "conejos" en plural, cámbialo aquí abajo
        respuesta = supabase.table("conejo").select("*").limit(1).execute()
        return {"estado": "Conexión exitosa", "datos_de_prueba": respuesta.data}
    except Exception as e:
        return {"error": str(e)}
