# Mumbai Local – Architecture

**Stack:** Flutter 3 (one codebase, Android + iOS), Riverpod (state), sqflite (offline SQLite), shared_preferences (favorites/recents/theme).

**Layers:** `data/` (schema, models, JSON importer) → `domain/` (route search, fare, crowd) → `ui/` (theme, screens). UI only talks to providers; providers only talk to the repository; the repository owns SQLite. Nothing touches the network at runtime: JSON is bundled in `assets/` and imported once (re-imported when `meta.data_version` changes).

```
lib/
  main.dart            ProviderScope + theme mode
  data/schema.dart     CREATE TABLE + indexes
  data/models.dart     Station, Train, Stop, TrainResult
  data/importer.dart   JSON -> SQLite (spec format + your "Railway Stations" format)
  domain/search.dart   direct search, connecting search, first/last train, crowd
  domain/fare.dart     distance-slab fare + pass calculator (config-driven)
  ui/theme.dart        line colors, badge colors, light/dark
  ui/home_screen.dart  search card, favorites, results
  ui/train_card.dart   result card with badges
```
Remaining screens (Station Board, Route Timeline, Fare, Settings) follow the same pattern: a `FutureProvider` over a query in `search.dart` + a stateless widget.

**Time storage:** all times are integer *minutes since midnight* (values >1439 = after midnight). This makes sorting, duration and "arriving in N min" simple integer maths and handles the last-train-after-midnight case.
