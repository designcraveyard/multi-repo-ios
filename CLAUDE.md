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

Use `Color.app*`, `CGFloat.space*`, `CGFloat.radius*`, and `Font.app*` from `DesignTokens.swift` for all styling.
**Never hardcode hex colors, numeric spacing, or px values in view files.**

```swift
.background(Color.appSurfaceBasePrimary)
.padding(CGFloat.space4)          // 16pt
.cornerRadius(CGFloat.radiusMD)   // 12pt (Mobile value)
.font(.appBodyLarge)              // 16pt regular
```

Run `/design-token-sync` after changes to `multi-repo-nextjs/app/globals.css`.

Token categories in `DesignTokens.swift`:
- **Colors** — `Color.appSurfaceBasePrimary`, `Color.appTextPrimary`, `Color.appIconPrimary`, etc.
- **Radius** — `CGFloat.radiusXS` … `CGFloat.radius2XL` (Mobile values only — no breakpoint in SwiftUI)
- **Spacing** — `CGFloat.space1` (4pt) … `CGFloat.space24` (96pt)
- **Typography** — `Font.appDisplayLarge` … `Font.appOverlineLarge` (28 named type styles)
- **Legacy aliases** — `CGFloat.spaceMD`, `Font.appBody`, `Font.appTitle` still work

---

## Icon System (Phosphor Icons)

**Package:** PhosphorSwift via SPM — `https://github.com/phosphor-icons/swift` (upToNextMajorVersion: 2.0.0)
**Helper:** `PhosphorIconHelper.swift` — `PhosphorIcon` view wrapper + `PhosphorIconSize` enum
**Same icon set used in Figma, web, and iOS.**

### Rules

- **Always** use `PhosphorIcon(...)` — not raw `Ph.*` API (except for advanced cases)
- Default weight: `.regular` · Default size: `.md` (20pt)
- Use `Color.appIcon*` tokens for color, not hardcoded hex/rgb

### Usage

```swift
import PhosphorSwift

// Basic (weight=.regular, size=.md, color=.primary)
PhosphorIcon(.house)

// With tokens
PhosphorIcon(.heart, weight: .fill, size: .lg, color: .appError)

// Accessible (adds accessibilityLabel, unhides from VoiceOver)
PhosphorIcon(.bell, label: "Notifications")

// Advanced (raw API — for special cases only)
Ph.house.regular.color(.appIconPrimary).frame(width: 24, height: 24)
```

### Size tokens

| Token | pt  | Web equivalent |
|-------|-----|----------------|
| `.xs` | 12  | `"xs"`         |
| `.sm` | 16  | `"sm"`         |
| `.md` | 20  | `"md"` _(default)_ |
| `.lg` | 24  | `"lg"`         |
| `.xl` | 32  | `"xl"`         |

### Figma → Code

Icon name in Figma sidebar (e.g. `House`) = `Ph.IconName` enum value (`.house`, `.arrowRight`). Weight layer = `.regular` / `.fill` / `.bold` etc.

---

## Adding Dependencies (SPM)

No CocoaPods or Mint in this project — SPM only.

**Xcode**: File → Add Package Dependencies

Installed packages:
- **PhosphorSwift**: `https://github.com/phosphor-icons/swift` — Up To Next Major from 2.0.0 ✓

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
