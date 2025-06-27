import os
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import APIKeyHeader
from dotenv import load_dotenv

# Load environment variables from a .env file (for local development)
load_dotenv()

# --- App Configuration ---
app = FastAPI(
    title="AI Topic Generator API",
    description="Backend service for processing submissions and generating topics.",
    version="0.1.0",
)

# --- Security: API Key Authentication ---
API_KEY_NAME = "X-API-Key"
api_key_header = APIKeyHeader(name=API_KEY_NAME, auto_error=False)

# This is where we'll get the actual API key from our environment variables
# On Railway, you will set this in the service variables.
SECRET_KEY = os.getenv("BACKEND_SECRET_KEY", "default_secret_for_local_dev")

async def get_api_key(api_key: str = Depends(api_key_header)):
    """Dependency function to validate the API key."""
    if api_key == SECRET_KEY:
        return api_key
    else:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing API Key",
        )

# --- API Endpoints ---
@app.get("/")
def read_root():
    """Root endpoint to check if the server is running."""
    return {"status": "Server is running"}

# THIS IS OUR MAIN ENDPOINT FOR THE DEMO
@app.post("/api/admin/start_generation_round", dependencies=[Depends(get_api_key)])
async def trigger_generation_round():
    """
    An admin-only endpoint to manually trigger the topic generation process.
    """
    print("✅ Admin trigger received! Starting topic generation process...")
    
    # In future phases, all the AI logic will go here.
    # For now, we just return a success message.
    
    print("✅ Process placeholder finished.")
    return {"status": "success", "message": "Topic generation process started."} 