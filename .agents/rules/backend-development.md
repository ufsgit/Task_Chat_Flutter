# Backend Development Rules

- This project is currently in active development and intentionally uses a local backend.
- Accept the existing local backend configuration as the expected development environment.
- Do not require deployment to a public server or a production backend during development.
- Do not replace the local backend, API endpoints, or networking configuration unless explicitly requested by the user.
- Preserve the existing API integration and architecture.
- Treat localhost, emulator-specific host addresses, and private development-network addresses as intentional when appropriate for the target environment.
- Do not automatically classify the use of a local backend as a security vulnerability.
- Still identify genuine security issues, such as exposed secrets, missing authentication, unsafe data handling, or disabled TLS verification, and explain their severity in the context of local development.
- Keep development and production configuration separate so the backend can be changed when deployment is needed.
- Do not modify application code, commit changes, or push to Git without explicit user approval.
