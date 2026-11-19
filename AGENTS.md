# OtoKu agent notes

## MCP servers (`.pi/mcp.json`)

| Server | What it is for |
| --- | --- |
| `dart` | Official Dart/Flutter MCP (`dart mcp-server`): analyze, fix, format, run tests, pub, device/app lifecycle, hot reload, logs, runtime errors, widget inspector. |
| `marionette` | Drives the running app (`marionette_mcp`): see interactive elements, tap, type, scroll, swipe, screenshot, logs, hot reload/restart. |
| `stitch` | Google Stitch (`@google/stitch mcp start`): generate/edit UI screens and variants, capture/upload pages, manage design systems. |

Skills live in `.agents/skills/`: Flutter/Dart skills from `flutter/agent-plugins` and
`dart-lang/skills`, `marionette-flutter-drive-app`, and the Stitch skill.

## Launching the app for agents

- Always pass `--print-dtd` to `flutter run` so the Dart MCP server can find the app:

  ```sh
  flutter run --print-dtd
  ```

- `marionette_flutter` is wired in `lib/main.dart` behind `kDebugMode`. After changing
  `main.dart`, **hot restart** (`R`) or relaunch the app; a hot reload does not swap the
  binding.
- Marionette connects to the VM service WebSocket URI, e.g.
  `ws://127.0.0.1:<port>/<token>/ws` (the HTTP VM service URL plus `/ws`).
- Stitch requires `npx -y @google/stitch login` (OAuth) and, for projects/screens/
  design systems, `STITCH_API_KEY`.
