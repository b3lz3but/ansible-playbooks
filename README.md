🚀 Ansible Runner with REST API 
A lightweight, Dockerized Ansible environment with:

✅ Playbook execution via REST API (Flask)
✅ Basic Authentication
✅ Persistent logging
✅ SSH key support
📂 Project Structure
lua
Copy
your-project/
├── docker-compose.yml
├── Dockerfile
├── inventory.ini
├── config.yaml
├── logger.sh
├── utils.sh
├── Interactive_script.sh
├── api.py
├── .env
├── playbooks/
│   ├── playbook1.yml
│   ├── playbook2.yml
├── logs/
│   ├── ansible.log
│   ├── api-playbook.log
└── ssh/
    └── id_rsa
⚙️ Environment Variables (.env)
dotenv
Copy
API_USER=admin
API_PASS=supersecret
🚀 Quick Start
1️⃣ Build and start the project:
bash
Copy
docker-compose build
docker-compose up -d
2️⃣ Access the container (optional):
bash
Copy
docker exec -it ansible_runner bash
🛠️ REST API Endpoints
Method	Endpoint	Auth Required	Description
GET	/health	✅	API health check
POST	/run	✅	Trigger a playbook run
▶️ Example: Run a playbook
bash
Copy
curl -X POST http://localhost:5000/run \
  -u admin:supersecret \
  -H "Content-Type: application/json" \
  -d '{"playbook": "playbook1.yml"}'
▶️ Example: Health check
bash
Copy
curl -u admin:supersecret http://localhost:5000/health
📑 Logs
Logs are stored in the logs/ directory:

File	Description
ansible.log	General Ansible logs
api-playbook.log	Logs from API playbook runs
🔐 SSH Access
Place your SSH private key at:

bash
Copy
ssh/id_rsa
Ensure correct permissions:

bash
Copy
chmod 600 ssh/id_rsa
🛡️ Security Notes
Change default API_USER and API_PASS.
Protect sensitive files with .gitignore:
bash
Copy
.env
ssh/id_rsa
logs/
For production, use HTTPS via reverse proxy (like Nginx).
🧩 Future Ideas
Token-based authentication
Rate limiting
User logging
# 🚀 Ansible Runner with REST API (No AWX)

A lightweight, Dockerized Ansible environment with:

- ✅ Playbook execution via REST API (Flask)
- ✅ Basic Authentication
- ✅ Persistent logging
- ✅ SSH key support

## 📂 Project Structure

```text
your-project/
├── docker-compose.yml
├── Dockerfile
├── inventory.ini
├── config.yaml
├── logger.sh
├── utils.sh
├── Interactive_script.sh
├── api.py
├── .env
├── playbooks/
│   ├── playbook1.yml
│   ├── playbook2.yml
├── logs/
│   ├── ansible.log
│   ├── api-playbook.log
└── ssh/
  └── id_rsa
```

## ⚙️ Environment Variables (.env)

```shell
API_USER=admin
API_PASS=supersecret
```

## 🚀 Quick Start

### 1️⃣ Build and start the project:

```shell
docker-compose build
docker-compose up -d
```

### 2️⃣ Access the container (optional):

```shell
docker exec -it ansible_runner bash
```

## 🛠️ REST API Endpoints

| Method | Endpoint  | Auth Required | Description            |
| ------ | --------- | ------------- | ---------------------- |
| GET    | `/health` | ✅             | API health check       |
| POST   | `/run`    | ✅             | Trigger a playbook run |

### ▶️ Example: Run a playbook

```shell
curl -X POST "http://localhost:5000/run" \
  -u admin:supersecret \
  -H "Content-Type: application/json" \
  -d '{"playbook": "playbook1.yml"}'
```

### ▶️ Example: Health check

```shell
curl -u admin:supersecret "http://localhost:5000/health"
```

## 📑 Logs

Logs are stored in the `logs/` directory:

| File               | Description                 |
| ------------------ | --------------------------- |
| `ansible.log`      | General Ansible logs        |
| `api-playbook.log` | Logs from API playbook runs |

## 🔐 SSH Access

Place your SSH private key at:

```shell
ssh/id_rsa
```

Ensure correct permissions:

```shell
chmod 600 ssh/id_rsa
```

## 🛡️ Security Notes

- Change default `API_USER` and `API_PASS`
- Protect sensitive files with `.gitignore`:
```shell
.env
ssh/id_rsa
logs/
```
- For production, use HTTPS via reverse proxy (like Nginx)

## 🧩 Future Ideas

- Token-based authentication
- Rate limiting
- User logging
- Web dashboard