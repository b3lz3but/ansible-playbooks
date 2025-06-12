# 🚀 Ansible Runner with REST API

A lightweight, Docker-based Ansible environment with:

✅ Playbook execution via REST API (Flask)  
✅ Basic Authentication  
✅ Persistent logging  
✅ SSH key support  

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
├── nginx/
│   └── nginx.conf
├── webui/
│   ├── index.html
│   ├── script.js
│   └── style.css
├── playbooks/
│   ├── playbook1.yml
│   ├── playbook2.yml
├── templates/
│   └── *.j2
├── logs/
│   ├── ansible.log
│   ├── api-playbook.log
└── ssh/
    └── id_rsa
```

## ⚙️ Environment Variables (.env)

Copy `.env.example` to `.env` and edit the credentials used for API authentication:

```shell
cp .env.example .env
API_USER=yourusername
API_PASS=yourpassword
```
The `docker-compose.yml` file maps host port **5000** to the API running on
port **5001** inside the container.

## 🚀 Quick Start

### 1️⃣ Build and start the project:

```shell
docker-compose build
docker-compose up -d
```

The API will be available on `http://localhost:5000` and the optional web
interface will be served via Nginx on `http://localhost:8180` (or `https://localhost:9443` if you provide certificates).

### 🌐 Web UI

Open your browser at `http://localhost:8180` to use the simple dashboard for
executing playbooks. The UI communicates with the API using the credentials from
your `.env` file.

### 🖥️ Interactive CLI

Run `Interactive_script.sh` inside the container to select and execute
available playbooks directly from the command line.

### 2️⃣ Access the container (optional):

```shell
docker exec -it ansible_runner bash
```

## 🛠️ REST API Endpoints

| Method | Endpoint  | Auth Required | Description            |
| ------ | --------- | ------------- | ---------------------- |
| GET    | `/api/health` | ✅             | API health check       |
| POST   | `/api/run`    | ✅             | Trigger a playbook run |

### ▶️ Example: Run a playbook

```shell
curl -X POST "http://localhost:5000/api/run"
  -u admin:supersecret \
  -H "Content-Type: application/json" \
  -d '{"playbook": "playbook1.yml"}'
```

### ▶️ Example: Health check

```shell
curl -u admin:supersecret "http://localhost:5000/api/health"
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

- For production, use HTTPS via reverse proxy (like Nginx).

## 🧩 Future Ideas
- Token-based authentication work in progress 🚧
- Rate limiting work in progress 🚧
- User logging
- Web dashboard - work in progress 🚧
