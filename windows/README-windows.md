## PPA Desktop — Windows installable setup

This folder contains the scripts and installer configuration to package **PPA Desktop** as a Windows application that runs on top of Docker Desktop.

### Architecture

- **PPA Desktop app**: `application.jar` (Spring Boot) running in a Docker container.
- **Database**: PostgreSQL running in a second container (via `local-dev/docker-compose.yml`), seeded from the bundled dump (`ppa-20251113153524.dump`) on first run.
- **R layer**: a separate **Rserve container** (built from `rserve/Dockerfile` or pulled from `kncvtbplus/ppa-rserve:latest`) that executes the R scripts.
- **Windows layer**:
  - PowerShell scripts to start/stop the stack.
  - An Inno Setup script (`ppa-desktop-installer.iss`) to build a classic Windows installer (`ppa-desktop-setup-x.y.z.exe`).

The end user only sees:

- A **Start Menu shortcut / desktop icon** “PPA Desktop”.
- A browser window opening at `http://localhost:8080` with the application.

Docker Desktop + internet (for the first image pull) are required.

### 1. Verify the local stack (dev)

1. Install **Docker Desktop for Windows**.
2. Open PowerShell in the project root:

   ```powershell
   cd "C:\...\ppa wizard\windows"
   ```

3. Start the stack:

   ```powershell
   .\ppa-desktop-run.ps1
   ```

4. The script will:
   - Check that Docker is installed and the Docker daemon is running.
   - Set `$env:PPA_DATA_DIR` to a user‑writable data directory under `%LOCALAPPDATA%\PPA-Wizard\s3`.
   - Run `docker-compose pull` in `local-dev` (app + PostgreSQL + Rserve).
   - Run `docker-compose up -d --force-recreate` to start or refresh the containers.
   - On **first run**, automatically initialise the database from the bundled dump.
   - Open `http://localhost:8080` in the default browser.

5. To stop the stack:

   ```powershell
   .\ppa-desktop-stop.ps1
   ```

### 2. Building the installer (.exe) with Inno Setup

1. Install **Inno Setup** on your Windows machine.
2. Open `windows/ppa-desktop-installer.iss` in the Inno Setup IDE.
3. Verify the paths in the `[Files]` section:
   - `..\application.jar` → points to the JAR in the project root.
   - `..\Dockerfile` → Dockerfile in the project root.
   - `..\local-dev\docker-compose.yml` → compose file for the stack.
4. Click **Build → Compile** to generate e.g. `ppa-desktop-setup-1.5.1.exe` (in the same folder as the `.iss` file).

### 3. What the installer does

- Copies:
  - `application.jar` to `C:\Program Files\PPA Desktop\`.
  - `Dockerfile` to the same folder.
  - `local-dev/docker-compose.yml` to `C:\Program Files\PPA Desktop\local-dev\`.
  - `ppa-desktop-run.ps1` and `ppa-desktop-stop.ps1` to `C:\Program Files\PPA Desktop\windows\`.
- Creates Start Menu shortcuts:
  - **PPA Desktop (Start)** → starts PowerShell with `ppa-desktop-run.ps1`.
  - **PPA Desktop (Stop)** → stops the Docker stack.
- Optionally creates a desktop icon for “PPA Desktop (Start)”.

### 4. Usage for end users

- **Install**:
  - Run the generated installer, e.g. `ppa-desktop-setup-1.5.1.exe`.
  - The installer **automatically checks whether Docker Desktop is installed**:
    - If **Docker is already installed** → installation continues.
    - If **Docker is missing**:
      - The user is asked whether Docker Desktop should be downloaded and started.
      - The installer downloads the official Docker Desktop installer and starts it.
      - After Docker installation, the PPA installer exits with instructions to rerun the PPA installer.
- **Start**:
  - Via Start Menu: “PPA Desktop (Start)” or the desktop icon.
  - Wait until the browser opens at `http://localhost:8080`.
- **Stop**:
  - Via Start Menu: “PPA Desktop (Stop)”, which stops the containers (and optionally Docker Desktop if nothing else is running).

### 5. Further extensions and known pitfalls

- **Rserve in Docker**
  - Use the image `kncvtbplus/ppa-rserve:latest` (configured in `local-dev/docker-compose.yml`).  
    This image includes:
    - Support for modern Stata files (`readstata13`) so `.dta` files from Stata 13+ load correctly.
    - Small R wrappers so `read.dta()` and `local({ ... })` behave as expected by the Java code.

- **Shared `/s3` directory (critical for uploads)**
  - Both the app container and the Rserve container must mount **exactly the same host directory** as `/s3`.  
    In the Windows setup we use:
    - Host directory: `%LOCALAPPDATA%\PPA-Wizard\s3`
    - Docker mount: `- ${PPA_DATA_DIR:-./s3}:/s3` (for both `app` and `rserve`).
  - The start script `windows/ppa-desktop-run.ps1` therefore sets `$env:PPA_DATA_DIR` to this folder and runs:

    ```powershell
    docker-compose up -d --force-recreate
    ```

    so that all containers are recreated with the same `/s3` mount.
  - If app and Rserve see different `/s3` folders, R cannot read uploaded files and you will see errors such as  
    *“Cannot read column names from file.”* even for valid `.csv` / `.dta` files.

- You can optionally add a local S3‑compatible service (such as MinIO) as a replacement for AWS S3, provided the application configuration allows it.

