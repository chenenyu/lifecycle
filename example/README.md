# lifecycle interactive example

This application is an interactive lab for the complete composable lifecycle
hierarchy:

```text
App → Navigator route → Page/Tab → Viewport item → Widget
```

Every demo combines a live status card with a structured transition log. The
log records phase changes, visible-fraction-only changes, causes, ordered
events, and the inherited Flutter app state.

## Included labs

- opaque routes, non-opaque dialogs, route disposal, and transition causes;
- `LifecycleListener`, `LifecycleStateMixin`, `LifecycleBuilder`, and custom
  `LifecycleBoundary` restrictions;
- settled and scrolling `LifecyclePageView` / `LifecycleTabBarView` state;
- stable page IDs while data is reordered or removed;
- visible fractions and independent thresholds in scrollable grid items;
- nested Navigators with independent route histories;
- declarative `Navigator.pages` additions and removals;
- direct parent/child `LifecycleController` composition.

The transition panel supports source filtering, event-only filtering,
pause/resume, expansion, copying, and clearing. On wide screens it appears as a
side panel; on narrow screens it moves below the active demo.

## Run

```sh
flutter run
```

The example supports Android, iOS, macOS, and Web project targets currently
checked into this repository.

## Tests

Run the example's unit and Widget tests:

```sh
flutter test
```

Run the integration smoke flows on a connected emulator, device, desktop, or browser:

```sh
flutter devices
flutter test integration_test -d <device-id>
```

The smoke suite starts each case with a fresh app tree and covers the native
Dialog route, PageView gesture, Viewport fling, nested Navigator, and
declarative `Navigator.pages` flows. Detailed state-machine and frame-by-frame
assertions remain in the package Widget tests so failures stay deterministic.

The package tests live one directory above the example and are run separately:

```sh
cd ..
flutter test
```

## Android toolchain

The Android example uses AGP 9.0.1, Gradle 9.1.0, and Java 17 bytecode. It
requires Flutter 3.44 or newer and JDK 17 or newer.

Flutter 3.44 still configures AGP 9 through its temporary compatibility mode,
so `android.newDsl=false` and `android.builtInKotlin=false` remain in
`android/gradle.properties`. Remove those flags and the external Kotlin plugin
when the project's Flutter baseline supports the completed built-in Kotlin and
new Android DSL migration.

## Source layout

```text
lib/
├── app.dart                 application and root Navigator setup
├── logging/                 structured transition records
├── screens/                 one focused lifecycle lab per file
└── widgets/                 status cards, instructions, and log panel
```
