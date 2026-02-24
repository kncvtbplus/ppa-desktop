## PPA Desktop

PPA Desktop is a Windows application that guides the Patient Pathway Analysis (PPA) process end‑to‑end: uploading data, mapping variables, and generating PPA outputs. It runs locally on your machine using Docker containers — no internet connection is required after installation.

PPA Desktop is developed and maintained by **KNCV TB Plus**.

## Installation

1. Download the latest installer from [Releases](https://github.com/kncvtbplus/ppa-desktop/releases/latest).
2. Run `ppa-desktop-setup-<version>.exe` and follow the on‑screen instructions.
3. The installer will check for Docker Desktop and offer to download it if not already installed.
4. After installation, launch PPA Desktop from the Start Menu or desktop shortcut.

See the included **PPA Desktop Installation and Local Use Guide** (PDF) for detailed instructions.

### Auto‑updates

On startup, PPA Desktop checks for newer releases. If a new version is available, you are prompted to download and install the update automatically.

## How it works

PPA Desktop runs as a set of Docker containers on your local machine:

- **ppa-app** — the main Spring Boot web application, accessible at `http://localhost:8080`
- **ppa-postgres** — a PostgreSQL database for storing PPA data locally
- **ppa-rserve** — an R execution environment used to generate PPA outputs

All user data stays on your computer. The application opens in your default web browser.

## Functional overview

The application supports a step‑by‑step PPA workflow:

- **Team spaces & user management**: create spaces, manage users and roles.
- **PPA management**: PPAs per team, duplicate/delete, national/subnational aggregation.
- **Data sources**: upload (.csv/.dta), manage, subset, apply sample weights.
- **Identify variables**:
  - Global variables (facility type, health sector, geography)
  - Service availability variables per metric
- **Mapping**:
  - Define health sectors & levels and map data values
  - Define geographies and map data source values
- **Output**: generate, preview, and download PPA outputs.

## Architecture and tech stack

- **Platform**: Java (Spring Boot, embedded Tomcat)
- **Web layer**: Spring MVC, Thymeleaf, jQuery EasyUI
- **Security**: Spring Security with custom handlers/listeners
- **Data**: Spring Data JPA (Hibernate), PostgreSQL
- **R integration**: Rserve for R script execution
- **Packaging**: Docker containers orchestrated via Docker Compose
- **Installer**: Inno Setup (Windows)

### Background

PPA Desktop was originally developed as a cloud‑hosted web application (under the `com.linksbridge.ppa` namespace). It has since been converted into a standalone desktop application that runs entirely on the user's machine via Docker. Some legacy code related to the original cloud deployment (e.g. email flows, S3 references) remains in the repository but is not used in the desktop version.

## Docker images

Container images are published on Docker Hub under the `kncvtbplus` namespace:

- `kncvtbplus/ppa-app:latest` — main Spring Boot application image
- `kncvtbplus/ppa-rserve:latest` — Rserve sidecar image

The `local-dev/docker-compose.yml` file and the Windows installer use these images.

Both the app and Rserve containers share a `/s3` volume for file exchange (data uploads, R scripts, and generated output). On Windows this maps to `%LOCALAPPDATA%\PPA-Wizard\s3`.

## Building from source (for developers)

### Prerequisites

- Java JDK 11+
- Maven (or use the included `mvnw` wrapper)
- Docker Desktop
- Inno Setup 6 (for building the Windows installer)

### Build and release

The release script builds the JAR, Docker images, Windows installer, and publishes everything in a single command:

```powershell
pwsh .\windows\new-ppa-release.ps1 -Version 1.7.2
```

To build without publishing:

```powershell
pwsh .\windows\new-ppa-release.ps1 -Version 1.7.2 -SkipPublish
```

### Manual steps

1. Build the application JAR:
   ```powershell
   cd "PPA sourcecode\project\PPA"
   .\mvnw -DskipTests package
   ```
2. Build the Docker image:
   ```powershell
   docker build --no-cache -t kncvtbplus/ppa-app:1.7.2 .
   ```
3. Build the Windows installer with Inno Setup:
   - Open `windows/ppa-desktop-installer.iss` in the Inno Setup IDE
   - Build → Compile

## Database

PPA Desktop uses a local PostgreSQL instance (running in Docker). The database is created automatically on first run. SQL migration scripts are located in `PPA sourcecode/project/PPA/database/`.

## License

This project is licensed under the [MIT License](LICENSE).

## Support

For questions or issues, please open a [GitHub issue](https://github.com/kncvtbplus/ppa-desktop/issues) or contact the KNCV TB Plus team.
