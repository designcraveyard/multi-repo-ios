# CLAUDE.md — multi-repo-ios

Platform-specific context for the SwiftUI iOS app.
See the root `CLAUDE.md` for workspace-wide context, skills, and shared conventions.

**Stack:** SwiftUI, Swift 5.0, iOS 26.2 deployment target

---

## Commands

```bash
# Build for iPhone 16 simulator
xcodebuild -project multi-repo-ios.xcodeproj \
  -scheme multi-repo-ios \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build

# Open in Xcode (preferred for day-to-day development)
open multi-repo-ios.xcodeproj
```

---

## Architecture

- `@main` entry: `multi_repo_iosApp.swift` — single `WindowGroup`
- `ContentView.swift` — Main entry view; add `NavigationLink` / `TabView` entries here as screens are added
- `DesignTokens.swift` — **Auto-generated** `Color`, `CGFloat`, `Font` extensions (run `/design-token-sync` to regenerate — do not edit manually)
- `Supabase/SupabaseManager.swift` — Supabase client singleton (scaffold; uncomment after SPM add)
- `Supabase/Config.swift` — Reads `SUPABASE_URL` / `SUPABASE_ANON_KEY` from Xcode scheme env vars
- `Models/` — Swift structs matching Supabase tables (one file per table)

---

## Concurrency Model

- `SWIFT_APPROACHABLE_CONCURRENCY = YES` — `@MainActor` is the **default isolation** project-wide
- ViewModels: `@MainActor final class XViewModel: ObservableObject` + `async/await`
- Views: use `.task { await viewModel.load() }` for async work triggered by appearance
- No need to manually annotate `@MainActor` on individual methods — it's the default

---

## Design Tokens

Use `Color.app*` and `CGFloat.space*` from `DesignTokens.swift` for all styling.
Never hardcode hex colors or numeric spacing in view files.

```swift
.background(Color.appBackground)
.padding(CGFloat.spaceMD)         // 16pt
.font(.appBody)
```

Run `/design-token-sync` after changes to `multi-repo-nextjs/app/globals.css`.

---

## Adding Dependencies (SPM)

No CocoaPods or Mint in this project — SPM only.

**Xcode**: File → Add Package Dependencies

Required packages (add when running `/supabase-setup`):
- **Supabase Swift**: `https://github.com/supabase/supabase-swift` — Up To Next Major from 2.0.0
  → Target: `multi-repo-ios`

---

## Supabase

Set credentials as **Xcode scheme environment variables** (not in code):
- `SUPABASE_URL` = `https://your-project-ref.supabase.co`
- `SUPABASE_ANON_KEY` = `your-anon-key`

(Edit Scheme → Run → Arguments → Environment Variables)

After adding supabase-swift SPM package, uncomment the `import Supabase` and client init in `SupabaseManager.swift`.

---

## Gotchas

- Bundle ID: `com.abhishekverma.multi-repo-ios` — do not change without updating all references
- Team ID: `L6KKWH5M53` — automatic code signing
- iOS 26.2 deployment target — modern SwiftUI APIs available (`NavigationStack`, `@Observable`, etc.)
- File system synchronization is enabled in Xcode — new `.swift` files added to `multi-repo-ios/multi-repo-ios/` are automatically included in the build target

---

## Screens / Views

- `ContentView.swift` — Main view (placeholder)

_Add new `*View.swift` entries here as features are added via `/cross-platform-feature` or `/new-screen`._
