# DevSecOps Conduit

The course project for Introduction to DevSecOps: a FastAPI backend and a React
Router frontend implementing the [RealWorld](https://realworld-docs.netlify.app/)
Conduit application. Both applications are vendored here so the class uses one
stable version all year.

## Sources

- Backend: [`borys25ol/fastapi-realworld-backend`](https://github.com/borys25ol/fastapi-realworld-backend) at `55111c6b335455734c139a2245d98be8288be528`. The upstream snapshot had no licence file; see [`backend/NOTICE.md`](backend/NOTICE.md).
- Frontend: [`cjfff/realworld-remix`](https://github.com/cjfff/realworld-remix) at `59cf71947386f4ffac13f95b5f0ef47237e36c4a`, MIT licensed; see [`frontend/LICENSE`](frontend/LICENSE).

## Student setup

Download this repository with **Code → Download ZIP**, unzip it, and open a
terminal in the folder. You need Python 3.12 or newer; Docker and Node are not
needed on student laptops.

macOS or Linux:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-tests.txt
playwright install chromium
```

Windows PowerShell:

```powershell
py -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install -r requirements-tests.txt
playwright install chromium
```

The instructor writes `API_URL` and `WEB_URL` on the board. Set them in the
same terminal before running the tests:

```bash
export API_URL="https://api-address-from-the-board"
export WEB_URL="https://web-address-from-the-board"
```

PowerShell uses `$env:API_URL="..."` and `$env:WEB_URL="..."`.

## The three test levels

```bash
python -m pytest tests/unit -q
python -m pytest tests/integration -q
python -m pytest tests/e2e -q
python -m pytest tests/e2e --headed
```

The upstream backend also has an in-process suite in `backend/tests`. It is not
part of Lesson 01: it needs PostgreSQL, `APP_ENV=test`, and permission to create
and drop test databases.

## Instructor: run locally

The full stack needs Docker, Node.js, npm, Python, and `cloudflared`.

```bash
./scripts/run-class.sh
```

The script creates ignored local configuration, starts PostgreSQL on host port
5455, migrates the database, builds and starts both applications, opens two
Cloudflare Quick Tunnels, and writes the public addresses to the ignored
`class-urls.txt`. Run it just before class because Quick Tunnel addresses change.
Use `./scripts/run-class.sh --local-only` to start and verify everything without
making the applications public.

Run tests locally with the defaults while the stack is up:

```bash
backend/.venv/bin/python -m pytest tests/unit tests/integration -q
backend/.venv/bin/python -m pytest tests/e2e -q
```

For a clean one-command verification that starts and stops the local stack:

```bash
./scripts/verify-local.sh
```

Stop all class processes and the course database with:

```bash
./scripts/stop-class.sh
```

## VS Code

Open the repository root in VS Code, install the recommended Python extensions,
then open **Run and Debug** and select **Conduit: Full stack**. Press `F5`.
VS Code creates the backend virtual environment when missing, installs backend
and frontend dependencies, starts PostgreSQL, applies migrations, then launches
FastAPI under the Python debugger on port 8000 and the frontend development
server on port 3000. Stopping the compound debug session also stops the course
database.

The configuration is split as VS Code expects:

- `.vscode/settings.json` configures Python, pytest and source discovery;
- `.vscode/tasks.json` prepares PostgreSQL, dependencies and migrations;
- `.vscode/launch.json` starts backend and frontend together.

Local settings are copied from `backend/.env.example` only when `backend/.env`
does not already exist. The real `.env` remains ignored by Git.
