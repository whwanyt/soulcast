# Widgets

This directory is required by the project FSD architecture.

Put reusable business display blocks here, for example:

- drama cards
- drama sections
- ranking blocks

Widgets in this layer may depend on `features`, `entities`, and `shared`, but must not depend on `pages` or `app`.

User actions and business flows belong in `features`, not here.
