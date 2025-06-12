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
| GET    | `/api/health` | ✅             | API health check       |
| POST   | `/api/run`    | ✅             | Trigger a playbook run |

### ▶️ Example: Run a playbook

```shell
 curl -X POST "http://localhost:5001/api/run" \
  -u admin:supersecret \
  -H "Content-Type: application/json" \
  -d '{"playbook": "playbook1.yml"}'
```

### ▶️ Example: Health check

```shell
 curl -u admin:supersecret "http://localhost:5001/api/health"
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
