import os
import requests
from dotenv import load_dotenv

# Load environment variables from a local .env file
# This allows you to keep your secrets out of the code
load_dotenv()

# --- Configuration ---
# Get the deployed URL from your Railway project's settings page.
# Get the secret key from your .env file.
RAILWAY_URL = os.getenv("RAILWAY_APP_URL")
SECRET_KEY = os.getenv("BACKEND_SECRET_KEY")

def trigger_backend_process():
    """Sends a secure POST request to the deployed backend to start the process."""
    if not RAILWAY_URL or not SECRET_KEY:
        print("Error: Please set RAILWAY_APP_URL and BACKEND_SECRET_KEY in your .env file.")
        return

    endpoint = f"{RAILWAY_URL}/api/admin/start_generation_round"
    headers = {
        "X-API-Key": SECRET_KEY
    }

    print(f"🚀 Triggering backend process at: {endpoint}")

    try:
        response = requests.post(endpoint, headers=headers, timeout=30)

        if response.status_code == 200:
            print("✅ Success! Backend process started.")
            print("Server response:", response.json())
        else:
            print(f"❌ Error: Failed to trigger process.")
            print(f"Status Code: {response.status_code}")
            print("Server response:", response.text)

    except requests.exceptions.RequestException as e:
        print(f"❌ A network error occurred: {e}")

if __name__ == "__main__":
    trigger_backend_process() 