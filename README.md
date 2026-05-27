# End-to-End DevOps Pipeline — Task Management Application

A production-grade DevOps portfolio project demonstrating a full software delivery pipeline: a containerized Spring Boot REST API with PostgreSQL, automated vulnerability scanning, multi-environment Docker Compose setups, database migrations, integration testing with Testcontainers, and code coverage reporting.

---

## 📐 Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                  Developer Machine                   │
│                                                      │
│  Source Code (Java / Spring Boot)                    │
│       │                                              │
│       ▼                                              │
│  Maven Build  ──►  Unit & Integration Tests          │
│       │               (Testcontainers + JaCoCo)      │
│       ▼                                              │
│  Multi-Stage Docker Build                            │
│  ┌────────────────────────────────┐                  │
│  │  Stage 1: Builder (Maven)      │                  │
│  │  Stage 2: Runtime (Alpine JRE) │                  │
│  │  - Non-root user               │                  │
│  │  - Health check (Actuator)     │                  │
│  └────────────────────────────────┘                  │
│       │                                              │
│       ▼                                              │
│  Trivy Vulnerability Scan (HIGH + CRITICAL CVEs)     │
│       │                                              │
│       ▼                                              │
│  Docker Compose (prod / dev environments)            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │ taskapp  │  │ postgres │  │ pgadmin  │           │
│  │ :8081    │  │ :5432    │  │ :5050    │           │
│  └──────────┘  └──────────┘  └──────────┘           │
└─────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Application | Java 17, Spring Boot 3.2, Spring Data JPA, Spring Actuator |
| Database | PostgreSQL 15, Flyway (schema migrations) |
| Containerization | Docker (multi-stage build), Docker Compose |
| Security Scanning | Trivy (Aqua Security) |
| Testing | JUnit 5, Testcontainers, Spring Boot Test |
| Code Coverage | JaCoCo |
| Build Tool | Maven 3.9 |

---

## 📁 Project Structure

```
My_project/
├── src/
│   ├── main/
│   │   ├── java/com/devops/taskapp/
│   │   │   ├── controller/        # REST endpoints
│   │   │   │   ├── TaskController.java
│   │   │   │   └── UserController.java
│   │   │   ├── model/             # JPA entities
│   │   │   │   ├── Task.java      # Task with Priority enum (LOW/MEDIUM/HIGH)
│   │   │   │   └── User.java
│   │   │   ├── repository/        # Spring Data repositories
│   │   │   ├── service/           # Business logic layer
│   │   │   └── TaskappApplication.java
│   │   └── resources/
│   │       ├── application.properties
│   │       └── db/migration/
│   │           └── V1__init_schema.sql   # Flyway migration
│   └── test/
│       └── java/com/devops/taskapp/
│           └── TaskControllerIntegrationTest.java  # Testcontainers tests
├── Dockerfile                 # Multi-stage production build
├── docker-compose.yml         # Production environment
├── docker-compose.dev.yml     # Dev overrides (debug port 5005)
├── trivy-scan.sh              # CVE vulnerability scanner
└── pom.xml
```

---

## 🚀 Getting Started

### Prerequisites

- Docker & Docker Compose installed
- Java 17+ (for local development only)
- Maven 3.9+ (for local development only)

### Run with Docker Compose (Recommended)

```bash
# Clone the repository
git clone https://github.com/Muhammed-jaseel/devops-end-to-end-pipeline.git
cd devops-end-to-end-pipeline

# Start all services (app + PostgreSQL + pgAdmin)
docker compose up --build

# App runs at:    http://localhost:8081
# pgAdmin runs at: http://localhost:5050  (admin@devops.com / admin)
```

### Run in Development Mode (with remote debugger)

```bash
# Merges docker-compose.dev.yml overrides
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build

# Remote debug port available at: localhost:5005
# Attach your IDE debugger to port 5005
```

### Run Locally (without Docker)

```bash
# Requires a local PostgreSQL instance
# Update src/main/resources/application.properties with your DB credentials

./mvnw spring-boot:run
```

---

## 🔒 Security Scanning with Trivy

The `trivy-scan.sh` script scans the built Docker image for known vulnerabilities (HIGH and CRITICAL severity) using Aqua Security's Trivy scanner. No local Trivy installation needed — it runs via Docker.

```bash
chmod +x trivy-scan.sh
./trivy-scan.sh
```

**What it does:**
- Builds the Docker image locally
- Pulls and runs the official `aquasec/trivy` container
- Scans for HIGH and CRITICAL CVEs in the image layers
- Exits with a non-zero code if vulnerabilities are found (CI/CD pipeline-friendly)

---

## 🧪 Testing

```bash
# Run all tests (unit + integration)
./mvnw test

# Generate JaCoCo code coverage report
./mvnw verify

# View coverage report
open target/site/jacoco/index.html
```

**Integration tests** use **Testcontainers** to spin up a real PostgreSQL 15 container at test time — no mocking, no H2 in-memory database. Tests verify actual HTTP endpoints end-to-end.

---

## 📡 API Endpoints

### Tasks

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/tasks` | Get all tasks |
| `GET` | `/api/tasks/user/{userId}` | Get tasks by user |
| `POST` | `/api/tasks` | Create a new task |

### Users

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/users` | Get all users |
| `POST` | `/api/users` | Create a new user |

### Health Check

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/actuator/health` | Spring Boot health status |

### Sample Request

```bash
# Create a user
curl -X POST http://localhost:8081/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Muhammed Jaseel", "email": "mhjaseelp@gmail.com"}'

# Create a task for that user (replace 1 with actual user ID)
curl -X POST http://localhost:8081/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Set up CI/CD pipeline", "priority": "HIGH", "user": {"id": 1}}'

# Get tasks for a user
curl http://localhost:8081/api/tasks/user/1
```

---

## 🐳 Docker — Key Design Decisions

### Multi-Stage Build
The Dockerfile uses two stages to keep the final image small and secure:
- **Stage 1 (builder):** Uses the full Maven + JDK image to compile and package the app
- **Stage 2 (runtime):** Uses a minimal Alpine JRE image — no build tools, no source code

### Security Hardening
- Runs as a **non-root user** (`appuser`) — limits blast radius if the container is compromised
- Uses **Alpine** base image — minimal attack surface, fewer CVEs
- **Health check** built into the image via Spring Actuator endpoint

### Environment Separation
- `docker-compose.yml` — production config with `restart: unless-stopped`
- `docker-compose.dev.yml` — overrides for development: disables restart, exposes JDWP debug port (5005)

---

## 🗄️ Database Migrations

Schema is managed by **Flyway** — all changes are versioned SQL scripts under `src/main/resources/db/migration/`. This ensures reproducible database state across all environments.

```
db/migration/
└── V1__init_schema.sql    # Creates users and tasks tables
```

---

## 📊 Code Coverage

After running `./mvnw verify`, JaCoCo generates an HTML coverage report at:

```
target/site/jacoco/index.html
```

---

## 👤 Author

**Muhammed Jaseel P** — DevOps Engineer at Tata Consultancy Services

- LinkedIn: [linkedin.com/in/muhammed-jaseel-p](https://linkedin.com/in/muhammed-jaseel-p)
- GitHub: [github.com/Muhammed-jaseel](https://github.com/Muhammed-jaseel)
- Email: mhjaseelp@gmail.com
