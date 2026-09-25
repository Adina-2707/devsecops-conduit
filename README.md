# DevSecOps Conduit

The course project for **Introduction to DevSecOps**: a FastAPI backend and a React
Router frontend implementing the [RealWorld](https://realworld-docs.netlify.app/)
Conduit application. Slides and reading: <https://devsecops-fieldbook.vercel.app>.

# Lesson 02 · Git express and your first CI check

By the end of the lesson:

- you have your own copy of Conduit on GitHub;
- you fixed one real bug through a pull request;
- a robot (GitHub Actions) runs the tests on every change;
- the robot said “no” twice: once to a broken test, once to a leaked secret.

Work in the **WSL or Linux terminal**, not in PowerShell. Follow the missions in
order; every mission ends with a **Checkpoint**. If something breaks, see
[Troubleshooting](#troubleshooting).

## Pre-flight

```bash
git --version
docker version
python3 --version
```

Checkpoint: three answers without errors. Python must be 3.12 or newer. If
`docker version` shows an error under **Server**, start Docker Desktop and try again.

Start this download now; you need it in Mission 3:

```bash
docker pull ghcr.io/gitleaks/gitleaks:v8.30.1
```

## Mission 1 · Key, fork, clone

**1. Hide your email.** On GitHub open **Settings → Emails** and tick
**Keep my email addresses private**. Copy the address that ends in
`@users.noreply.github.com`.

> [!NOTE]
> Every commit stores the author's email. In a public repository anyone can read
> it, including robots that collect addresses for spam.

**2. Tell Git who you are.** Your real name and the noreply address:

```bash
git config --global user.name "Aibek Asanov"
git config --global user.email "12345678+aibek@users.noreply.github.com"
git config --global init.defaultBranch main
```

**3. Make an SSH key.** Press Enter three times (default file, no passphrase).

```bash
ssh-keygen -t ed25519 -C "wsl-laptop"
cat ~/.ssh/id_ed25519.pub
```

Copy the whole line that starts with `ssh-ed25519`. On GitHub open
**Settings → SSH and GPG keys → New SSH key**, paste it, click **Add SSH key**. Test:

```bash
ssh -T git@github.com
```

Type `yes` if it asks about the fingerprint.

Checkpoint: `Hi <your-name>! You've successfully authenticated`.

> [!NOTE]
> A key has two halves. The public half (`.pub`) goes to GitHub; anyone may see it.
> The private half never leaves your laptop. Never show anyone the file without `.pub`.

**4. Fork this repository.** At the top of this page click **Fork → Create fork**.

**5. Clone your fork**, not this repository. Replace `<your-name>` with your GitHub username:

```bash
cd ~
git clone git@github.com:<your-name>/devsecops-conduit.git
cd devsecops-conduit
git remote -v
```

Checkpoint: both `origin` lines show your username.

> [!NOTE]
> A **fork** is your copy on GitHub. A **clone** is a copy of your fork on your
> laptop. You work in the clone and send changes to the fork, which Git calls `origin`.

**6. Prepare Python and run the unit tests:**

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-tests.txt
python -m pytest tests/unit -q
```

Checkpoint: `6 passed`, and your prompt starts with `(.venv)`. Your old ZIP folder
is not needed any more.

## Mission 2 · Fix a bug on a branch

**1. See the bug.** Conduit builds the web address of an article from its title.
Ask the function what it does with a title that has no letters:

```bash
cd backend
python -c 'from conduit.core.utils.slug import make_slug_from_title_and_code as s; print(s("!!!!!", "abc123"))'
cd ..
```

It prints `-abc123`: the address starts with a dash. We want `abc123`.

**2. Make a branch:**

```bash
git switch -c fix/empty-slug
git branch
```

Checkpoint: the star is next to `fix/empty-slug`.

> [!NOTE]
> A **branch** is a separate line of work. You try things on it while `main` stays
> safe. Good work joins `main` through a pull request.

**3. Write the test first.** Open `tests/unit/test_slug.py` in your editor
(`code tests/unit/test_slug.py` or `nano tests/unit/test_slug.py`) and add at the end:

```python
def test_title_without_letters_does_not_start_with_a_dash():
    assert make_slug_from_title_and_code("!!!!!", "abc123") == "abc123"
```

```bash
python -m pytest tests/unit/test_slug.py -q
```

Checkpoint: `1 failed, 4 passed`, with the line
`AssertionError: assert '-abc123' == 'abc123'`: what the code gave, and what the
test expected.

**4. Fix the code.** Open `backend/conduit/core/utils/slug.py`, find
`make_slug_from_title_and_code`. Its last two lines become four:

```python
    slug = slugify(text=title, max_length=32, lowercase=True)
    if not slug:
        return code
    return f"{slug}-{code}"
```

```bash
python -m pytest tests/unit -q
```

Checkpoint: `7 passed`.

**5. Look before you save:**

```bash
git status
git diff
```

> [!NOTE]
> A change lives in three places. **Files**: what you see in the editor.
> **Staging**: what goes into the next commit. **Commit**: a saved snapshot with an
> author, a time and a message. `git add` moves a change to staging, `git commit`
> saves the snapshot.

**6. Choose the files and commit:**

```bash
git add tests/unit/test_slug.py backend/conduit/core/utils/slug.py
git status
git commit -m "Do not start a slug with a dash when the title has no letters"
git log --oneline -3
```

Name each file in `git add`. With `git add .` you do not see what goes in; that is
how passwords and junk files end up in repositories.

**7. Push the branch:**

```bash
git push -u origin fix/empty-slug
```

**8. Open a pull request.** Open your fork on GitHub and click **Compare & pull request**.

> [!WARNING]
> GitHub suggests `dastanko/devsecops-conduit` as the base. Change
> **base repository** to `<your-name>/devsecops-conduit` and **base** to `main`.
> Your pull request must stay inside your fork.

Use the commit message as the title. In the description write what changed and
the command you ran with its result. Click **Create pull request**.

**9. Review.** Send the link to your neighbour. The neighbour opens
**Files changed**, clicks **+** next to one line and leaves one useful comment.
Answer it, then click **Merge pull request → Confirm merge**.

> [!NOTE]
> A **pull request** asks: “please take my branch into main”. A second person reads
> the change before it lands. Two pairs of eyes catch what one misses; that is a
> security control, not a formality.

**10. Update your laptop:**

```bash
git switch main
git pull
git log --oneline -3
```

Checkpoint: your commit is on `main`, together with a merge commit.

## Mission 3 · Git never forgets

**1. A branch for a drill:**

```bash
git switch -c drill/leaked-key
```

**2. Commit a fake key.** Create `backend/conduit/integrations/weather.py` with
these two lines. The key is fake; it only looks real.

```python
WEATHER_API_URL = "https://api.weather.example/v1"
weather_api_key = "q7Xk2Lm9Pz4Rt8Vw1Ny6Hb3Jc5Df0Gs"
```

```bash
git add backend/conduit/integrations/weather.py
git commit -m "Add weather integration"
```

**3. “Oops.” Delete it and commit again:**

```bash
git rm backend/conduit/integrations/weather.py
git commit -m "Remove weather integration"
```

**4. Is the key gone?**

```bash
git grep q7Xk2
git log -p | grep q7Xk2
```

The first command prints nothing: your files are clean. The second finds the key:
the history still has it.

**5. Ask a scanner.** Gitleaks reads the whole history and looks for anything that
looks like a secret:

```bash
docker run --rm -v "$PWD:/repo" ghcr.io/gitleaks/gitleaks:v8.30.1 git /repo --log-opts=HEAD --no-banner -v
```

Checkpoint: `leaks found: 1`, with the file, the line and the commit that added the key.

> [!WARNING]
> When a real key leaks: first revoke it where it was issued and make a new one.
> Deleting the commit is not enough; bots watch public GitHub and copy new keys
> within minutes. Clean the history after that.

**6. Why `.env` is safe:**

```bash
git check-ignore -v backend/.env
```

The answer names the rule in `backend/.gitignore`: Git never offers this file for a commit.

Do not push `drill/leaked-key` yet; you need it in Mission 6.

```bash
git switch main
```

## Mission 4 · Your first workflow

> [!NOTE]
> **CI** is a robot that runs the same checks on a clean machine for every change.
> A **workflow** is the file with the rules; a **job** is a group of steps on one
> machine; a **step** is one action or command; a **runner** is a fresh virtual
> machine that GitHub starts for the job and deletes afterwards.

**1. A branch for the workflow:**

```bash
git switch -c ci/unit-tests
mkdir -p .github/workflows
```

**2. Create `.github/workflows/ci.yml`.** Spaces, not tabs; indentation matters.

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-python@v7
        with:
          python-version: "3.12"
      - run: pip install -r requirements-tests.txt
      - run: python -m pytest tests/unit -v
```

`on` says *when* it runs, `runs-on` *where*, `steps` *what*. The last two steps are
the commands you ran in Mission 1.

**3. Commit and push:**

```bash
git add .github/workflows/ci.yml
git commit -m "Run unit tests in CI"
git push -u origin ci/unit-tests
```

**4. Open a pull request** in your fork (check the base repository again). A check
called **unit-tests** appears. Click **Details** and watch the runner.

Checkpoint: a green check and `7 passed` at the end of the log. Merge it, then:

```bash
git switch main
git pull
```

The **Actions** tab of your fork now shows one more run, on `main`.

## Mission 5 · The robot says no

**1. Break the fix on a new branch:**

```bash
git switch -c test/robot-says-no
```

In `backend/conduit/core/utils/slug.py` delete the two lines `if not slug:` and
`return code`. Do **not** run the tests; pretend you forgot.

```bash
git add backend/conduit/core/utils/slug.py
git commit -m "Simplify slug helper"
git push -u origin test/robot-says-no
```

**2. Open a pull request.** Wait for a red cross on **unit-tests**. Click
**Details** and find the name of the failed test and the `AssertionError` line.

Checkpoint: you can say which test failed and why, without looking at your code.

GitHub still shows the **Merge** button. A red check is only advice until you make
it a rule (see [Bonus A](#bonus)).

**3. Fix it.** Put the two lines back, run the tests yourself this time, and push:

```bash
python -m pytest tests/unit -q
git add backend/conduit/core/utils/slug.py
git commit -m "Restore the check for titles without letters"
git push
```

The same pull request runs again. Checkpoint: green. There is nothing new left in
it, so click **Close pull request** instead of merging.

```bash
git switch main
```

## Mission 6 · The robot finds the secret

**1. Add a second job.** On a new branch, add `secret-scan` at the end of `ci.yml`,
at the same indentation as `unit-tests`:

```bash
git switch -c ci/secret-scan
```

```yaml
  secret-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
      - run: docker run --rm -v "$PWD:/repo" ghcr.io/gitleaks/gitleaks:v8.30.1 git /repo --log-opts=HEAD --no-banner -v
```

The last step is the command from Mission 3.

> [!NOTE]
> By default the runner downloads only the newest commit, so a secret in an older
> commit would be missed. `fetch-depth: 0` downloads the whole history.

```bash
git add .github/workflows/ci.yml
git commit -m "Scan history for secrets in CI"
git push -u origin ci/secret-scan
```

Open a pull request. Checkpoint: two green checks, **unit-tests** and
**secret-scan**. Merge it, then:

```bash
git switch main
git pull
```

**2. Push the leaked key:**

```bash
git switch drill/leaked-key
git push -u origin drill/leaked-key
```

Open a pull request. The branch is older than the workflow, but GitHub runs the
checks from `main` on it anyway.

Checkpoint: **unit-tests** green, **secret-scan** red. In **Details** find the rule,
the file and the commit. The file no longer exists, but the robot found the key.

**3. Clean up.** Click **Close pull request**, then **Delete branch**. On your laptop:

```bash
git switch main
git branch -D drill/leaked-key
```

GitHub keeps the commits of a pull request even after the branch is deleted. With a
real key, only revoking it would help.

## Bonus

**A. Make red a rule.** In your fork open **Settings → Rules → Rulesets →
New ruleset → New branch ruleset**. Name it `main`, set **Enforcement status** to
**Active**, add the target **Include default branch**, tick
**Require a pull request before merging** and **Require status checks to pass**,
and add `unit-tests` and `secret-scan`. Save. Now `git push` straight to `main` is
rejected.

**B. The twin bug.** New articles use a second function in the same file,
`make_slug_from_title`, and it has the same bug. On a new branch, write a test that
fails for it, fix it, and open a pull request.

## Done? Submit

- `ssh -T git@github.com` greets you by name.
- `main` in your fork has the slug fix and `.github/workflows/ci.yml` with two jobs.
- The **Actions** tab shows a green run on `main`.
- The pull request from `test/robot-says-no` shows a red run, then a green one.
- The pull request from `drill/leaked-key` shows a red **secret-scan** and is closed.

Submit the link to your fork and the links to those two closed pull requests.

## Troubleshooting

1. **`ssh -T` hangs or times out.** The network may block port 22. Put the lines
   below into `~/.ssh/config` and test again.

   ```text
   Host github.com
     Hostname ssh.github.com
     Port 443
     User git
   ```

2. **`Permission denied (publickey)`.** The key on GitHub is not the one in
   `~/.ssh/id_ed25519.pub`. Compare the end of both lines.
3. **`python3 -m venv` fails.** Run `sudo apt install python3-venv` and repeat.
4. **The pull request went to `dastanko/devsecops-conduit`.** Close it and open a new
   one with your fork as the base repository.
5. **No check appears on the pull request.** Open the **Actions** tab; if there is
   a button to enable workflows, click it. The file must be in `.github/workflows/`.
6. **The workflow fails before it runs anything.** Almost always indentation. Compare
   with [the complete ci.yml](#the-complete-ciyml); spaces, not tabs.
7. **`git push` is rejected** with “fetch first”. Run `git pull`, then push again.
8. **`docker: permission denied` in WSL.** Start Docker Desktop and turn on WSL
   integration for your distribution.
9. **`(.venv)` is gone from the prompt.** You opened a new terminal. Run
   `source .venv/bin/activate` in the repository folder.

## Git commands for today

| Goal | Command |
|---|---|
| Copy a repository to the laptop | `git clone <address>` |
| What changed? | `git status` · `git diff` |
| New branch | `git switch -c <name>` |
| Switch branch | `git switch <name>` |
| Choose files for the commit | `git add <file> <file>` |
| Save a snapshot | `git commit -m "<what changed>"` |
| History | `git log --oneline -5` |
| History with changes | `git log -p` |
| Send the branch to GitHub | `git push -u origin <branch>` |
| Get the newest main | `git switch main`, then `git pull` |
| Delete a local branch | `git branch -D <name>` |

## The complete ci.yml

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-python@v7
        with:
          python-version: "3.12"
      - run: pip install -r requirements-tests.txt
      - run: python -m pytest tests/unit -v

  secret-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
      - run: docker run --rm -v "$PWD:/repo" ghcr.io/gitleaks/gitleaks:v8.30.1 git /repo --log-opts=HEAD --no-banner -v
```

---

# Reference

## Run the application on your laptop

Create the local settings and start PostgreSQL. The settings file lives in
`backend/`, and the project name `conduit` must match the one the scripts and
VS Code use:

```bash
cd backend
cp .env.example .env
docker compose -p conduit up -d --wait postgres
cd ..
```

Then start the backend and the frontend: press `F5` in VS Code with
**Conduit: Full stack** selected (see [VS Code](#vs-code)), or run
`./scripts/run-class.sh --local-only`. The backend answers on
http://127.0.0.1:8000 and the frontend on http://127.0.0.1:3000. The scripts
and VS Code tasks are written for macOS and Linux; on Windows run them inside
WSL.

### Point the tests at the application

For the copy on your own laptop:

```bash
export API_URL="http://127.0.0.1:8000"
export WEB_URL="http://127.0.0.1:3000"
```

These are also the defaults, so locally you can skip this step. To test the
instructor's copy instead, use the two addresses written on the board.
PowerShell uses `$env:API_URL="..."` and `$env:WEB_URL="..."`.

## The three test levels

```bash
python -m pytest tests/unit -q
python -m pytest tests/integration -q
python -m pytest tests/e2e -q
python -m pytest tests/e2e --headed
```

The upstream backend also has an in-process suite in `backend/tests`. It is not
part of the lessons: it needs PostgreSQL, `APP_ENV=test`, and permission to create
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

## Sources

- Backend: [`borys25ol/fastapi-realworld-backend`](https://github.com/borys25ol/fastapi-realworld-backend) at `55111c6b335455734c139a2245d98be8288be528`. The upstream snapshot had no licence file; see [`backend/NOTICE.md`](backend/NOTICE.md).
- Frontend: [`cjfff/realworld-remix`](https://github.com/cjfff/realworld-remix) at `59cf71947386f4ffac13f95b5f0ef47237e36c4a`, MIT licensed; see [`frontend/LICENSE`](frontend/LICENSE).
