import subprocess, threading, time
from fastapi import FastAPI

app = FastAPI()

def run_terraform(path, action):
    cmd = ["terraform", action, "-auto-approve"]
    subprocess.run(cmd, cwd=path)

def destroy_after(path, minutes):
    time.sleep(minutes * 60)
    run_terraform(path, "destroy")

@app.post("/start-lab/{lab_name}")
def start_lab(lab_name: str, duration: int = 60):
    path = f"../infra/labs/{lab_name}"
    threading.Thread(target=run_terraform, args=(path, "apply")).start()
    threading.Thread(target=destroy_after, args=(path, duration)).start()
    return {"status": "started", "lab": lab_name, "duration": duration}

@app.post("/stop-lab/{lab_name}")
def stop_lab(lab_name: str):
    path = f"../infra/labs/{lab_name}"
    run_terraform(path, "destroy")
    return {"status": "stopped", "lab": lab_name}
