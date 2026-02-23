## PPA Desktop – Functional Change Log

This document summarizes the functional changes made to the packaged PPA Desktop application in this repository. It is written for stakeholders and users, not just developers.

### Completed changes

- **Local Docker + Windows packaging for PPA Desktop (early Dec 2025)**  
  - Packaged the PPA Desktop Spring Boot web app as a prebuilt JAR with a Dockerfile and Procfile, so it can run both locally and on PaaS platforms (e.g. Elastic Beanstalk).  
  - Added a local Docker stack with PostgreSQL and Rserve, so a full PPA environment can be started on a developer machine with Docker only.  
  - Created a Windows installer concept (Inno Setup script plus PowerShell run/stop scripts), so end users can install and start/stop the wizard from the Windows Start menu without touching Docker directly.

- **Local R/S3 setup and developer utilities (Dec 2025)**  
  - Added the `Auto.PPA.UI.R` script and an S3-like folder structure, so the local stack mimics the production R and S3 integration as closely as possible.  
  - Improved the local database restore script and Rserve Dockerfile so developers can reliably spin up a realistic environment, restore data, and run PPA calculations locally.

- **Demo / convenience users for testing (Dec 2025)**  
  - Introduced SQL helper scripts to create demo users and local test accounts (including a dedicated "Job van Rest" user and a generic "local" user).  
  - This makes it much easier to log in and demonstrate or debug the application without manual user setup each time.

- **Upgrade of bundled PPA application and UI assets to v3/v4/v5 (Dec 2025 - Feb 2026)**  
  - Updated the bundled application and exploded JAR contents to a newer upstream PPA application release (v3, then v4, then v5), bringing in the latest core workflow, security, and data-handling logic from the original project.  
  - Refreshed the front-end stack: new/updated CSS, JavaScript and UI libraries (Angular, Bootstrap, jQuery EasyUI themes, icons, fonts, intro.js, GoJS, etc.), giving the wizard a more modern and consistent look.  
  - Reworked the home/index templates and step fragments (e.g. Identify Variables, Map Aggregation Levels, Upload & Prep Data, Select Output) to align with the current PPA process and make the step-by-step navigation clearer.  
  - Added an offline index page and other static assets so the UI works more robustly in different hosting setups (e.g. behind CloudFront, local stack).  
  - Improved Windows installer metadata and icon, plus the run script, so the installed app feels more polished and easier to start/stop for non-technical users.

- **Local data, S3 content and Windows documentation (Feb 2026)**  
  - Added sample PPA datasets to the local S3 folder and refined the R script / Docker configuration, so developers can run realistic end-to-end scenarios (upload, mapping, outputs) out of the box.  
  - Extended the Windows user guide and installer notes, clarifying how the local stack works (Docker, database, Rserve) and how end users should install and operate the Windows version.

- **Repository scope and AWS infra clean-up (Feb 2026)**  
  - Removed the tracked `ppa-infra` submodule and updated `.gitignore` so AWS infrastructure code now lives outside this repository, keeping this project focused on the application artefacts and local/Windows packaging.  
  - This reduces noise in the repo and avoids accidental changes to infrastructure when the goal is only to update the wizard and its packaging.

- **Account screen behaviour changes (Feb 2026)**  
  - In the single-account view (`Account.js`), fixed the logout confirmation logic by making the alert title/message local variables instead of implicitly global, preventing side-effects between controllers or screens.  
  - In the accounts overview (`Accounts.js`), removed the in-UI `createAccount` action, so accounts are no longer created directly from this screen and must be created via a controlled path (e.g. elsewhere in the system or by admins), aligning the UI with the intended account-management policy.

- **Rebranding to PPA Desktop (Feb 2026)**  
  - Renamed the application from "PPA Wizard" to "PPA Desktop" across documentation, Windows installer assets, and user-facing UI text, so the branding clearly reflects that this is an installable desktop version of the PPA tool.

- **Guest login / skip-login mode (Feb 2026)**  
  - Added a "Continue without login" button on the home screen so that users can access PPAs on a shared desktop PC without creating an account or logging in.
  - Behind the scenes a dedicated guest user (with ROLE_USER only, no admin rights) is automatically created on first use and linked to a "Public" account. PPAs attached to this Public account are available to everyone; PPAs in other accounts still require a real login.
  - This feature is only active when the application runs in local/desktop mode (`LOCAL_MODE=true`). In cloud/hosted mode the guest login endpoint is rejected.
