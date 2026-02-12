## PPA Desktop — Windows installable setup

Deze map bevat een voorstel hoe je van PPA Desktop een installeerbare Windows‑applicatie maakt, bovenop Docker.

### Architectuur

- **PPA Desktop app**: `application.jar` (Spring Boot) draait in een Docker‑container.
- **Database**: PostgreSQL draait in een tweede Docker‑container (via `local-dev/docker-compose.yml`), gevuld met een meegeleverde dump (`ppa-20251113153524.dump`).
- **R‑laag**: een aparte **Rserve‑container** (via `rserve/Dockerfile`) zodat R‑gebaseerde PPA‑functionaliteit lokaal beschikbaar is.
- **Windows laag**:
  - PowerShell‑scripts om de stack te starten/stoppen.
  - Een Inno Setup script (`ppa-desktop-installer.iss`) om een klassieke Windows‑installer (`ppa-desktop-setup-x.y.z.exe`) te bouwen.

De gebruiker ziet uiteindelijk alleen:

- Een **Start Menu‑shortcut / desktop‑icoon** “PPA Desktop”.
- De browser opent op `http://localhost:8080` met de applicatie.

Docker Desktop + internet (voor de eerste image‑pull) zijn vereist.

### 1. Lokale stack verifiëren (dev)

1. Installeer **Docker Desktop for Windows**.
2. Open PowerShell in de projectroot:

   ```powershell
   cd "C:\...\ppa wizard\windows"
   ```

3. Start de stack:

   ```powershell
   .\ppa-desktop-run.ps1
   ```

4. De script:
   - Checkt of Docker aanwezig is.
   - Voert `docker-compose up -d --build` uit in `local-dev` (app + PostgreSQL + Rserve).
   - Initialiseert bij de **eerste run** automatisch de database vanuit de meegeleverde dump.
   - Opent `http://localhost:8080` in de browser.

5. Stoppen kan met:

   ```powershell
   .\ppa-desktop-stop.ps1
   ```

### 2. Installer (.exe) genereren met Inno Setup

1. Installeer **Inno Setup** op je Windows‑machine.
2. Open `windows/ppa-desktop-installer.iss` in de Inno Setup IDE.
3. Controleer de paden in `[Files]`:
   - `..\application.jar` → verwijst naar de JAR in de projectroot.
   - `..\Dockerfile` → Dockerfile in de projectroot.
   - `..\local-dev\docker-compose.yml` → compose file voor de stack.
4. Klik op **Build → Compile** om bijvoorbeeld `ppa-desktop-setup-1.5.0.exe` te genereren (in dezelfde map als de `.iss`).

### 3. Wat de installer doet

- Kopieert:
  - `application.jar` naar `C:\Program Files\PPA Desktop\`.
  - `Dockerfile` naar dezelfde map.
  - `local-dev/docker-compose.yml` naar `C:\Program Files\PPA Desktop\local-dev\`.
  - `ppa-desktop-run.ps1` en `ppa-desktop-stop.ps1` naar `C:\Program Files\PPA Desktop\windows\`.
- Maakt Start Menu‑shortcuts:
  - **PPA Desktop (Start)** → start PowerShell met `ppa-desktop-run.ps1`.
  - **PPA Desktop (Stop)** → stopt de Docker‑stack.
- Optioneel: desktopicoon voor “PPA Desktop (Start)”.

### 4. Gebruik voor eindgebruikers

- **Installeren**:
  - Voer de gegenereerde installer uit, bijvoorbeeld `ppa-desktop-setup-1.5.0.exe`.
  - De installer **checkt automatisch of Docker Desktop aanwezig is**:
    - Indien **Docker al is geïnstalleerd** → installatie gaat direct verder.
    - Indien **Docker ontbreekt**:
      - Krijgt de gebruiker de vraag om Docker Desktop te downloaden en te starten.
      - De installer downloadt de officiële Docker Desktop installer en start deze.
      - Daarna wordt de PPA‑installer afgebroken met de instructie om, na succesvolle Docker‑installatie, de PPA‑installer opnieuw te starten.
- **Starten**:
  - Via Start Menu: “PPA Desktop (Start)” of desktopicoon.
  - Wacht tot de browser opent met `http://localhost:8080`.
- **Stoppen**:
  - Via Start Menu: “PPA Desktop (Stop)”.

### 5. Verdere uitbreidingen

- **Rserve lokaal in Docker** toevoegen aan `local-dev/docker-compose.yml` en `RSERVE_HOST`/`RSERVE_PORT` in de app‑container configureren.
- Eventueel een lokale S3‑compatibele service (zoals MinIO) toevoegen als vervanger voor AWS S3, mits de applicatie‑config dat toelaat.


