# Features

This directory is required by the project FSD architecture.

Put user actions and reusable business flows here, for example:

- `agent` — chat send/stop, tools, memory update
- `manage_ai_provider` — provider/model CRUD and remote model fetch
- `transfer_ai_provider` — provider JSON import/export
- `transfer_mcp` — MCP `mcpServers` JSON import/export (streamable_http)

Each feature should expose a public entry file:

```text
features/<feature_name>/
  <feature_name>.dart
  provider/
  widget/
  model/
  service/
  api/                 # optional: external backend / SDK adapters
```

Segment roles:

- `provider/` — Riverpod state and action entry for this feature
- `widget/` — action-oriented UI
- `model/` — feature DTOs / state models
- `service/` — business orchestration (no third-party SDK imports)
- `api/` — HTTP / SDK adapters only; third-party client SDKs stay here

Do not import pages or widgets from this layer. Features may depend on `entities` and `shared`.

Feature-specific protocol adapters (for example OpenAI-compatible LLM clients) belong in that feature's `api/`, not in `shared/` and not mixed into `service/`.

Public barrels should stay narrow: export providers, necessary models, and action widgets — not concrete tool/SDK implementations.
