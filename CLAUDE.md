# ClusterPulse - CLAUDE.md

## Project Overview

ClusterPulse is Project #51 in the AI Portfolio series. It is an AI-powered data clustering REST API built with **Lua 5.4** and the **Pegasus** web framework. The project provides K-means clustering, data point management, similarity computation, nearest neighbor search, and AI-powered cluster analysis via a mock Claude client.

- **Language**: Lua 5.4 (originally planned in Gleam, replaced due to ecosystem breakage)
- **Framework**: Pegasus 1.1.0 (lightweight Lua HTTP server)
- **JSON Library**: dkjson
- **Test Framework**: luaunit
- **Lines of Code**: ~690
- **GitHub**: https://github.com/malbinjvc/cluster-pulse

## Project Structure

```
cluster-pulse/
  main.lua                         # Entry point - starts the Pegasus server
  src/
    app.lua                        # HTTP routing, request handling, JSON responses
    models.lua                     # Data structures (DataPoint, Cluster, Stats, etc.)
    services.lua                   # Business logic (K-means, similarity, nearest neighbors)
  tests/
    test_cluster_pulse.lua         # 24 tests covering all service functions
  Dockerfile                       # Multi-stage Alpine build
  .github/workflows/ci.yml         # GitHub Actions CI (test + Docker build)
  .gitignore
  ClusterPulse_Error_Log.md        # All build/CI errors and resolutions
  ClusterPulse_Project_Report.pdf  # Project report (generated via fpdf2)
```

## Architecture

- **main.lua**: Entry point, calls `app.start()`
- **src/app.lua**: Pegasus server setup, route matching via `match_route()`, JSON response helpers, all HTTP handler functions
- **src/models.lua**: Factory functions for domain objects (`new_data_point`, `new_cluster`, `new_similarity_result`, `new_nearest_result`, `new_stats`), ID generation
- **src/services.lua**: Core logic - in-memory state store, CRUD operations, K-means clustering (10 iterations, Euclidean distance), cosine similarity, nearest neighbor search, statistics, mock AI analysis
- State is held in a module-level `state` table with `points` (hash map) and `clusters` (array)

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /health | Health check |
| POST | /api/points | Create data point (body: `{name, features, label?}`) |
| GET | /api/points | List all data points |
| GET | /api/points/:id | Get point by ID |
| DELETE | /api/points/:id | Delete point by ID |
| POST | /api/cluster | Run K-means clustering (body: `{k}`) |
| GET | /api/clusters | List current clusters |
| POST | /api/similarity | Cosine similarity (body: `{point_a, point_b}`) |
| POST | /api/nearest | K-nearest neighbors (body: `{query_id, k}`) |
| GET | /api/stats | Dataset statistics |

## Build & Run Commands

### Local Development

```bash
# Run the server (requires Lua 5.4 + luarocks packages)
lua5.4 main.lua

# Run tests
lua5.4 tests/test_cluster_pulse.lua

# On macOS, if luarocks installed to user paths, may need:
LUA_PATH="/usr/local/share/lua/5.4/?.lua;./?.lua;./?/init.lua;;" \
LUA_CPATH="/usr/local/lib/lua/5.4/?.so;./?.so;;" \
lua5.4 tests/test_cluster_pulse.lua
```

### Docker

```bash
docker build -t cluster-pulse .
docker run -p 8080:8080 cluster-pulse
```

### CI

CI runs on GitHub Actions (ubuntu-latest):
- Installs lua5.4, luarocks, pegasus, dkjson, luaunit via apt-get/luarocks
- Sets `LUA_PATH` and `LUA_CPATH` env vars covering both 5.1 and 5.4 paths (luarocks installs to 5.1 paths by default)
- Runs `lua5.4 tests/test_cluster_pulse.lua`
- Builds Docker image

## Testing

- **24 tests** covering: Point CRUD (9), Math helpers (6), Similarity (2), Nearest neighbors (3), Clustering (4), Stats (2), Analysis (2)
- Each test calls `reset()` at the start to clear state (luaunit does not invoke global `setUp()` for non-class tests)
- Run with: `lua5.4 tests/test_cluster_pulse.lua`
- All tests must pass before committing

## Docker Details

- **Multi-stage build**: Alpine 3.20 builder (with gcc, luarocks) -> Alpine 3.20 runtime (lua5.4 only)
- **Pegasus deps installed manually**: mimetypes, luasocket, luafilesystem installed separately, then `pegasus --deps-mode=none` to skip lzlib (optional gzip support that fails to build on Alpine)
- **Non-root user**: appuser:appgroup (UID/GID 1001)
- **Healthcheck**: `wget -qO- http://localhost:8080/health`
- **Port**: 8080 (configurable via `PORT` env var)

## Known Issues & Workarounds

1. **lzlib build failure on Alpine**: Pegasus optionally depends on lzlib for gzip. lzlib's rockspec can't find zlib headers on Alpine even with zlib-dev. Workaround: install pegasus deps manually and use `--deps-mode=none`.
2. **luarocks 5.1/5.4 path mismatch**: On Ubuntu, luarocks installs to Lua 5.1 paths by default, but lua5.4 looks in 5.4 paths. Must set `LUA_PATH`/`LUA_CPATH` in CI.
3. **Gleam ecosystem broken**: Originally planned in Gleam/Wisp, but `gleam_stdlib >= 0.68` removed `dynamic.from` which breaks gleam_erlang, glisten, and other packages. Replaced with Lua.

---

## Portfolio Procedures & Standards

This project is part of a 51-project AI portfolio. All projects follow the same procedures documented below.

### Project Delivery Pipeline

Every project goes through this pipeline in order:

1. **Build**: Scaffold the project with appropriate language/framework, implement all source code, routes, services, models, and clients
2. **Install Dependencies**: Set up local dev environment, install all packages/libraries
3. **Run Tests**: Write comprehensive tests, run until all pass. Fix any failures before proceeding
4. **Security Audit**: Perform mandatory pre-commit security inspection (see checklist below)
5. **Git Init + Commit**: Initialize repo, commit all files (NO Co-Authored-By lines - all commits under user's name only)
6. **GitHub Repo + Push**: Create repo via `gh repo create`, push code, verify CI passes
7. **Error Log**: Document ALL errors encountered during build in `<ProjectName>_Error_Log.md`
8. **PDF Report**: Generate project report PDF via fpdf2 saved as `<ProjectName>_Project_Report.pdf`

### Error Logging Standard

Every project maintains an error log at the project root:

- **File**: `<ProjectName>_Error_Log.md` (e.g., `ClusterPulse_Error_Log.md`)
- **Location**: Project root directory
- **Format**: Each error gets its own numbered section with:
  - **Error**: The exact error message or symptom
  - **Root Cause**: Why it happened
  - **Resolution**: How it was fixed
- **Summary section** at the bottom with total errors, resolution status, test count, CI status
- Updated throughout the build process as new errors are discovered and resolved
- Committed and pushed to GitHub alongside the project code

### PDF Report Standard

Every project gets a detailed PDF report:

- **File**: `<ProjectName>_Project_Report.pdf` (e.g., `ClusterPulse_Project_Report.pdf`)
- **Location**: Project root directory
- **Generated via**: Python fpdf2 library (no pdflatex on this machine)
- **Sections**: Project Overview, Architecture, Key Features, API Endpoints, Testing (results + error summaries), Docker, CI/CD Pipeline, Final Status
- **Key details**: Language, framework, lines of code, date, GitHub URL, test counts, error counts
- Reports are regenerated if error logs are updated after initial generation

### Pre-Commit Security Audit

**MANDATORY** before every git commit. Full checklist:

1. **Hardcoded Credentials & Secrets**
   - Search for API keys (`sk-`, `sk_test_`, `AKIA`, etc.)
   - Search for tokens, passwords, credentials with assigned values
   - Search for private keys (`-----BEGIN`, `PRIVATE KEY`)
   - Check `.env` files are NOT staged

2. **Sensitive File Exposure**
   - `.gitignore` covers: `.env`, `.env.*`, `*.pem`, `*.key`, `*.p12`, `*.pfx`
   - No database dumps, SQL files with real data, certificate/key files

3. **Input Validation & Injection**
   - All DB queries use parameterized queries (if applicable)
   - User input validated on all API endpoints
   - Content-Type headers set properly

4. **Docker Security**
   - Multi-stage builds (no build tools in production image)
   - Non-root user in containers
   - No secrets in Dockerfiles
   - Base images version-pinned (no floating `latest`)

5. **Dependency & Supply Chain**
   - No known vulnerable dependency versions
   - Lock files committed where applicable
   - No unnecessary dev dependencies in production

### Commit Guidelines

- **No Co-Authored-By lines** - all commits under the user's name only
- Commit messages are concise and describe the "why" not just the "what"
- Security audit must pass before every commit
- Error logs and PDF reports are committed alongside project code

### CI/CD Standard

All projects use GitHub Actions with:
- Trigger on push/PR to `main`
- Test job: install deps, run full test suite
- Docker job: build Docker image (depends on test job passing)
- CI must be green before project is considered complete

### Portfolio Project Index

This is project #51 of 51. The full portfolio spans 25+ programming languages including:
Go, Rust, TypeScript, Python, Java, Kotlin, Scala, Ruby, Zig, C#, Elixir, Swift, Dart, Clojure, PHP, Crystal, Nim, Perl, Haskell, OCaml, F#, Lua, and more.

Each project is an AI-themed REST API or CLI tool demonstrating:
- Idiomatic use of the language and framework
- Clean architecture (routes, services, models, clients)
- Comprehensive test coverage
- Docker containerization with security best practices
- CI/CD via GitHub Actions
- Mock Claude AI client integration for AI-powered features
