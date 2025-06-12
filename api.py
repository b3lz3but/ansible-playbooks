import os
import subprocess
import base64
from flask import Flask, request, jsonify
from functools import wraps
import logging

app = Flask(__name__)

# Configure logging
logging.basicConfig(
    filename="/var/log/ansible/api.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)

# Load configuration from environment variables
API_USER = os.getenv("API_USER")
API_PASS = os.getenv("API_PASS")
PLAYBOOKS_DIR = os.getenv("PLAYBOOKS_DIR", "/ansible/playbooks")
INVENTORY = os.getenv("INVENTORY", "/ansible/inventory.ini")


# Authentication decorator
def require_auth(f):
    """
    Decorated function to enforce Basic Auth on API endpoints.

    401 on no/malformed Authorization header
    403 on invalid credentials
    Call original function on valid credentials
    """

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

    # Input validation (example with a whitelist)
    allowed_playbooks = [
        "backup_files.yml",
        "check_disk_space.yml",
        "ci_cd.yml",
        "cloud_management.yml",
        "collaboration.yml",
        "containerization.yml",
        "database_admin.yml",
        "documentation.yml",
        "log_cleanup.yml",
        "monitoring_logging.yml",
        "network_check.yml",
        "networking.yml",
        "restart_services.yml",
        "scripting_automation.yml",
        "security_hardening.yml",
        "security_scan.yml",
        "system_administration.yml",
        "system_health_monitor.yml",
        "troubleshooting.yml",
        "update_packages.yml",
        "user_management.yml",
    ]  # Add your playbook names here
    if playbook not in allowed_playbooks:
        return False, f"Invalid playbook name: {playbook}", 400

    try:
        cmd = ["ansible-playbook", "-i", INVENTORY, playbook_path]
        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode == 0:
            logging.info(f"Playbook {playbook} executed successfully.")
            return (
                True,
                {
                    "message": f"{playbook} executed successfully.",
                    "output": result.stdout,
                },
                200,
            )
        else:
            logging.error(f"Playbook {playbook} failed: {result.stderr}")
            return (
                False,
                {"message": f"{playbook} failed.", "error": result.stderr},
                500,
            )
    except FileNotFoundError:
        logging.error(f"Playbook not found: {playbook_path}")
        return False, {"message": f"Playbook {playbook} not found."}, 404
    except Exception as e:
        logging.exception(f"An error occurred while running playbook {playbook}: {e}")
        return False, {"message": "An error occurred.", "error": str(e)}, 500


@app.route("/run", methods=["POST"])
@require_auth
def run():
    data = request.get_json()
    playbook = data.get("playbook")
    if not playbook:
        return jsonify({"error": "No playbook specified."}), 400

    success, message, status_code = run_playbook(playbook)
    return jsonify(message), status_code


@app.route("/api/health", methods=["GET"])
@require_auth
def health():
    return jsonify({"status": "ok"}), 200


if __name__ == "__main__":
    # The service is exposed on port 5001 via docker-compose and nginx
    app.run(host="0.0.0.0", port=5001)
