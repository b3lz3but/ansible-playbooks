from flask import Flask, request, jsonify
from functools import wraps
import subprocess
import os
import base64

app = Flask(__name__)

# Basic Auth credentials (set as environment variables or hardcoded here)
API_USER = os.getenv("API_USER", "admin")
API_PASS = os.getenv("API_PASS", "supersecret")

PLAYBOOKS_DIR = "/ansible/playbooks"
INVENTORY = "/ansible/inventory.ini"
LOG_FILE = "/var/log/ansible/api-playbook.log"


# Authentication decorator
def require_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get("Authorization")
        if not auth_header or not auth_header.startswith("Basic "):
            return (
                jsonify({"error": "Authentication required."}),
                401,
                {"WWW-Authenticate": 'Basic realm="Login Required"'},
            )

        auth_decoded = base64.b64decode(auth_header.split(" ")[1]).decode("utf-8")
        username, password = auth_decoded.split(":", 1)

        if username != API_USER or password != API_PASS:
            return jsonify({"error": "Invalid credentials."}), 403

        return f(*args, **kwargs)

    return decorated


def run_playbook(playbook):
    playbook_path = os.path.join(PLAYBOOKS_DIR, playbook)
    if not os.path.isfile(playbook_path):
        return False, f"Playbook {playbook} not found."

    try:
        cmd = ["ansible-playbook", "-i", INVENTORY, playbook_path]
        with open(LOG_FILE, "a") as logfile:
            result = subprocess.run(cmd, stdout=logfile, stderr=logfile)
        if result.returncode == 0:
            return True, f"{playbook} executed successfully."
        else:
            return False, f"{playbook} failed. Check logs."
    except Exception as e:
        return False, str(e)


@app.route("/run", methods=["POST"])
@require_auth
def run():
    data = request.get_json()
    playbook = data.get("playbook")
    if not playbook:
        return jsonify({"error": "No playbook specified."}), 400

    success, message = run_playbook(playbook)
    status_code = 200 if success else 500
    return jsonify({"message": message}), status_code


@app.route("/health", methods=["GET"])
@require_auth
def health():
    return jsonify({"status": "ok"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
