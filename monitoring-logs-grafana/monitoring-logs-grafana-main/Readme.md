# 📊 Logs-Grafana

A centralized log collection, storage, and visualization stack using **Fluent Bit**, **Loki**, and **Grafana**, deployed with **Docker Compose**.

## 🧱 System Architecture

```
[ App Containers ]
       ↓
  [ Fluent Bit ]
       ↓
     [ Loki ]
       ↓
   [ Grafana ]
```

- **Fluent Bit**: collects logs from containers.
- **Loki**: stores logs.
- **Grafana**: visualizes and queries logs.

---

## 🚀 Getting Started

### 1. Requirements

- Docker
- Docker Compose

### 2. Launch the Stack

```bash
git clone https://github.com/Nguyencrc19/Logs-Grafana.git
cd Logs-Grafana
docker-compose up -d
```

### 3. Access the UI

- **Grafana**: http://localhost:3000  
  - Default credentials:
    - User: `admin`
    - Password: `admin`

---

## ⚙️ Configuration Details

### Fluent Bit

- `fluent-bit/conf/fluent-bit.conf`: defines the logging pipeline.
  - Input: `tail` logs from `/var/log/containers/*.log`
  - Filter: adds labels like `container_name`, `pod_name`
  - Output: sends logs to Loki via HTTP

```ini
[OUTPUT]
    Name          loki
    Match         *
    Host          loki
    Port          3100
    Labels        job=fluentbit,container_name=$container_name
    Auto_Kubernetes_Labels  on
```

### Loki

- `loki/config.yaml`: Loki config (uses local filesystem, listens on port 3100)

```yaml
auth_enabled: false
server:
  http_listen_port: 3100
  grpc_listen_port: 9095
```

### Grafana

- Dashboards and data sources are provisioned automatically from:

```
grafana/provisioning/
├── datasources/loki.yaml
├── dashboards/default.yaml
```

---

## 📒 Sample Dashboard

A default dashboard is auto-imported. You can modify or create new dashboards via the Grafana UI.

---

## 🐳 Monitor Fluent Bit Logs

To check Fluent Bit logs:

```bash
docker logs fluent-bit
```

---

## 🛠️ Adding More Applications

When adding a new app container:

1. Ensure logs are available to Fluent Bit (e.g., via `/var/log/containers` or by mounting logs).
2. Adjust Fluent Bit config if needed to match new container patterns.

---

## ✅ Query Logs

Open Grafana → Explore → Select `Loki` → Query with:

```logql
{container_name="your_container_name"}
```

---

## 🧹 Cleanup

```bash
docker-compose down -v
```

---

## 📌 Notes

- If you see Loki errors like `compactor`, check `storage_config` in `loki/config.yaml`.
- Mount a volume (e.g. `/loki`) to persist log data.
