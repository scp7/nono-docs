# Nono Documentation

Unified documentation site for the Nono sandboxing ecosystem, built with [Mintlify](https://mintlify.com).

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  nono/docs/     │     │  nono-py/docs/  │     │  nono-ts/docs/  │
│  └── cli/       │     │  └── python/    │     │  └── typescript/│
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │  multirepo-action       │
                    │  (GitHub Actions)       │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │  nono-docs (docs branch)│
                    │  ├── introduction.mdx   │
                    │  ├── quickstart.mdx     │
                    │  ├── core/overview.mdx  │
                    │  ├── cli/               │
                    │  ├── typescript/        │
                    │  └── python/            │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │  Mintlify               │
                    │  nono.sh/docs           │
                    └─────────────────────────┘
```

## Tabs

| Tab | Description | Source |
|-----|-------------|--------|
| Overview | Landing page + quickstart | `nono-docs/` |
| CLI | Command-line tool | `nono/docs/cli/` |
| Core | Rust library (placeholder) | `nono-docs/core/` |
| TypeScript | TypeScript SDK | `nono-ts/docs/typescript/` |
| Python | Python SDK | `nono-py/docs/python/` |

## Setup

### 1. Create a Personal Access Token

Create a GitHub PAT with `repo` scope and add it as `DOCS_PAT` secret to:
- `always-further/nono-docs`
- `always-further/nono`
- `always-further/nono-py`
- `always-further/nono-ts`

### 2. Connect Mintlify

1. Go to [Mintlify Dashboard](https://dashboard.mintlify.com)
2. Connect the `nono-docs` repository
3. Set deployment branch to `docs` (not `main`)

### 3. Enable Dispatch Workflows

Copy `.github/workflows/docs-dispatch.yml.example` to each sub-repo as
`.github/workflows/docs-dispatch.yml`.

## Local Development

```bash
# Install Mintlify CLI
npm i -g mintlify

# Build a local aggregated docs tree from sibling repos
./scripts/local-aggregate.sh

# Validate internal links in the aggregated output
./scripts/check-links.sh

# Run local preview
cd .local-aggregate/output
mintlify dev
```

## Contributing

| To edit... | Go to... |
|------------|----------|
| Overview pages | `nono-docs/` (this repo) |
| Core library docs | `nono-docs/core/` (this repo) |
| CLI documentation | `nono/docs/cli/` |
| TypeScript SDK docs | `nono-ts/docs/typescript/` |
| Python SDK docs | `nono-py/docs/python/` |

Changes to sub-repos automatically trigger a rebuild via repository dispatch.

## File Structure

```
nono-docs/
├── docs.json           # Main Mintlify configuration
├── introduction.mdx    # Landing page
├── quickstart.mdx      # Unified quickstart
├── core/
│   └── overview.mdx    # Core library placeholder
├── logo/               # Logo assets
└── .github/workflows/  # Aggregation workflow
```
