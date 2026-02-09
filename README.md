# CloudBees CI Traditional HA Setup with HAProxy

This project provides a Docker Compose setup for CloudBees CI (Traditional) using HAProxy as a reverse proxy/load balancer.

## Quickstart

### Prerequisites

1. **Docker & Docker Compose**: Ensure Docker is installed and running.
2. **Java**: Required for initial certificate generation (if applicable) or environment checks.
3. **Host Entries**: Add the following entries to your `/etc/hosts` file to resolve the local domains:

    ```bash
    127.0.0.1 cjoc.local controller.local
    ```

### Start the Environment

Run the main startup script:

```bash
./up.sh
```

This script will:

- Check for Java.
- Generate SSL certificates if missing.
- Generate HAProxy configuration using `envsubst`.
- Start the Docker containers (`haproxy`, `operations-center`, `controller`).

### Accessing the Application

- **Operations Center (CJOC):** [https://cjoc.local](https://cjoc.local)
- **Managed Controller:** [https://controller.local](https://controller.local)

*(Accept the self-signed certificate warnings in your browser)*

---

## Architecture

The setup includes an HAProxy instance that routes traffic based on the Host header (`cjoc.local` vs `controller.local`) to the respective backend containers.

```mermaid
graph TD
    User((User / Browser))
    
    subgraph "Docker Network (172.47.0.0/24)"
        HAProxy[("HAProxy
        (SSL Termination)
        Port: 443")]
        
        CJOC["Operations Center
        (cjoc.local)"]
        
        Controller["Managed Controller
        (controller.local)"]
        
        HAProxy -->|Host: cjoc.local| CJOC
        HAProxy -->|Host: controller.local| Controller
        
        Controller -.->|Connects to| CJOC
    end
    
    User -->|https://cjoc.local| HAProxy
    User -->|https://controller.local| HAProxy
```

## Troubleshooting

- **Check Logs**:

    ```bash
    docker-compose logs -f
    ```

- **Restart Containers**:

    ```bash
    ./down.sh
    ./up.sh
    ```

- **SSL Certificates**: If you encounter SSL issues, remove the `ssl/` directory content and restart to regenerate:

    ```bash
    rm -rf ssl/*
    ./up.sh
    ```

## Development

- **Modify HAProxy Config**: Edit `haproxy-config/haproxy-ssl.cfg`.
- **Environment Variables**: Adjust settings in `.env`.
