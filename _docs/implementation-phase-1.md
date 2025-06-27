### **Goal: Create a secure, deployable, and triggerable backend service.**

By the end of this phase, you will have a Python application running on Railway that does nothing but wait for a secure signal from your local machine. This validates the entire communication and deployment pipeline before we add any of the complex AI logic.

### **Step 1: Set Up the Project Structure**

Inside your existing Flutter repository, create a new folder named backend. You will also create the CLI trigger script at the root level. Your project structure should look like this:

your_flutter_project/  
├── .gitignore  
├── backend/                  <-- NEW FOLDER  
│   ├── .gitignore  
│   ├── main.py               <-- NEW FILE  
│   ├── Procfile              <-- NEW FILE  
│   └── requirements.txt      <-- NEW FILE  
├── lib/  
├── pubspec.yaml  
└── trigger_generation.py     <-- NEW FILE

### **Step 2: Create the FastAPI Backend**

Navigate into your new backend directory. Here, you'll create the files that define your Python server.

**A. backend/requirements.txt**

This file tells Railway which Python packages to install.

fastapi  
uvicorn  
python-dotenv

**B. backend/Procfile**

This file is a single line that tells Railway how to start your web server. It will run the uvicorn server, pointing it to the app object inside your main.py file.

web: uvicorn main:app --host 0.0.0.0 --port $PORT

**C. backend/.gitignore**

It's good practice to have a separate .gitignore for your backend to keep Python's virtual environment folders out of version control.

__pycache__/  
*.pyc  
*.pyo  
*.pyd  
.Python  
env/  
venv/

**D. backend/main.py**

This is the core of your backend server. It creates the FastAPI app and the secure endpoint.

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

### **Step 3: Create the CLI Trigger Script**

Now, go to the root directory of your project (not the backend folder) to create the script you'll run from your computer.

**A. trigger_generation.py**

This script will make the secure API call to your deployed backend.

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

**B. Create a .env file** at the project root for local secrets. **Important:** Add .env to your main .gitignore file so you don't commit it to GitHub.

**.env file:**

RAILWAY_APP_URL="https://your-app-name.up.railway.app"  
BACKEND_SECRET_KEY="some-very-strong-and-random-key"

### **Step 4: Deployment to Railway**

1. **Commit and Push:** Commit all your new files (backend folder contents, trigger_generation.py, .env file, and updated .gitignore) and push them to your GitHub repository.  
2. **Create a New Service on Railway:**  
   * Go to your Railway dashboard and create a new project.  
   * Select "Deploy from GitHub repo" and choose your Flutter project repository.  
   * Railway will likely ask what to deploy. Choose to deploy a new service.  
3. **Configure the Service:**  
   * Go to the "Settings" tab for your new service.  
   * Under "Build", find the **Root Directory** setting.  
   * Set the Root Directory to ./backend. This is the crucial step that tells Railway to look inside your sub-folder.  
   * Under "Variables", add a new environment variable:  
     * **Name:** BACKEND_SECRET_KEY  
     * **Value:** Paste the same some-very-strong-and-random-key you used in your local .env file.

Railway will now automatically build and deploy your Python application from the backend folder.

### **Step 5: Verification (The Moment of Truth)**

1. Once Railway shows that your deployment is successful, copy the public URL it provides.  
2. Paste this URL into the RAILWAY_APP_URL variable in your local .env file.  
3. Open your local terminal at the root of your project.  
4. Run the script: python trigger_generation.py  
5. **Check Your Terminal:** You should see the ✅ Success! Backend process started. message.  
6. **Check Your Railway Logs:** Open the logs for your service on the Railway dashboard. You should see the ✅ Admin trigger received! Starting topic generation process... message printed by your Python server.

If you see both of these, **Phase 1 is complete!** You have a fully deployed, secure backend foundation ready to be built upon.
