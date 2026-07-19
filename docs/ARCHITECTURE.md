# Architecture

## Shape

FreeGrid Android is a Flutter app with an Android-native shell and shared Dart business logic. The first milestone is feature parity with the public iOS/Web app, not visual novelty.

## Layers

```text
lib/
  app/
    freegrid_app.dart
    theme/
  core/
    domain/
      models.dart
      freedom_math.dart
    data/
      backup_codec.dart
  features/
    dashboard/
    assets/
    history/
    check/
```

## Core Rules

- Domain code stays Flutter-independent where possible.
- `FreedomMath` is pure Dart and must stay covered by tests.
- `BackupCodec` owns the iOS/Web-compatible JSON surface.
- Persistence should adapt to domain models instead of leaking database types into UI.

## Planned Persistence

Recommended next choice: Drift + SQLite.

Why:

- real local database, not browser storage;
- easy queries for history/month summaries;
- migration-friendly;
- no network or account requirement.

## Planned UI Order

1. App shell and Silverline theme
2. Dashboard read-only with seeded in-memory data
3. SQLite repository
4. Add expense/income sheets
5. Assets and passive sources
6. History and monthly summary
7. Check tab
8. JSON import/export
