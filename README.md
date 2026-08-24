# BorderBeamKit

SwiftUI port of the [border-beam](https://beam.jakubantalik.com) web library by
[Jakub Antalik](https://x.com/jakubantalik) — animated border beam effects
rendered with SwiftUI Metal shaders. macOS 14+ / iOS 17+.

Extracted from the `ports/ios` tree of
[Jakubantalik/border-beam](https://github.com/Jakubantalik/border-beam) (MIT)
into a standalone package, with a macOS demo app that mirrors the website's
playground. All 5 types (`sm`, `md`, `line`, `pulse-outside`, `pulse-inner`)
× 4 color variants × dark/light are implemented, pixel-parity verified against
the web demo (worst mean diff 1.21/255 across the 40-combination matrix).

## Usage

```swift
import BorderBeamKit

// Wrapper view
BorderBeam(size: .md, colorVariant: .ocean, theme: .auto) {
    Card()
}

// Or as a modifier
Card().borderBeam(.md, colorVariant: .colorful)
```

All web props are mirrored:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `size` | `BeamSize` | `.md` | `.sm` / `.md` / `.line` (rotate family), `.pulseOutside` / `.pulseInner` (pulse family) |
| `colorVariant` | `BeamColorVariant` | `.colorful` | `.colorful` / `.mono` / `.ocean` / `.sunset` |
| `theme` | `BeamTheme` | `.dark` | `.dark` / `.light` / `.auto` (follows `colorScheme`) |
| `staticColors` | `Bool` | `false` | Disable the hue-shift animation (`mono` is always static) |
| `duration` | `Double?` | per family | Rotation/travel/pulse cycle in seconds |
| `active` | `Bool` | `true` | Fades in/out (0.6 s / 0.5 s) with `onActivate` / `onDeactivate` callbacks |
| `borderRadius` | `Double?` | preset | Explicit radius — SwiftUI has no auto-detection; falls back to the size preset |
| `brightness` | `Double?` | per type | Glow brightness multiplier |
| `saturation` | `Double?` | per theme | Glow saturation multiplier |
| `hueRange` | `Double` | `30` | Hue rotation range in degrees (`line` caps at 13°, web parity) |
| `strength` | `Double` | `1` | Overall effect opacity 0–1 (never affects the wrapped content) |
| `tuning` | `BeamTuning` | `.none` | Pulse-family tuning hooks; `.webDemoPulsePreset` in the demo matches the website's tuned `pulse-outside` card |
| `rendersStatically` | `Bool` | `false` | Freeze the beam at its fully visible reference frame for evidence or other deterministic rendering |

The pulse family's `.mono` palette remains neutral across appearances: its
light-on-dark source colors invert to dark-on-light when the resolved theme is
light. Colored variants retain their authored palettes in both appearances.

The pulse family honors Reduce Motion, matching the web library.

### AppKit host

`BorderBeamHostView` is a transparent, decorative `NSView` bridge for AppKit
callers. Live windows use the SwiftUI + Metal renderer. AppKit's
`cacheDisplay` path cannot preserve a transparent `NSHostingView` root and
otherwise paints its centre white, so callers producing screenshots or print
output must wrap that synchronous render in
`host.withCachedDisplayFallback { ... }`. The fallback draws a deterministic
ring from the same bundled palette and size spec while leaving the caller's
surface pixels untouched. Its pixel contract is covered by
`appKitHostPreservesTheSurfaceUnderItsTransparentCentre`.

## How it works

- All hand-tuned visual data (palettes, presets, oscillator tables) is decoded
  from the bundled `beam-spec.json`, generated from the web library's source —
  nothing visual is hard-coded in Swift. To sync after an upstream update, run
  `npm run spec` in the upstream repo and copy `spec/beam-spec.json` over
  `Sources/BorderBeamKit/Resources/beam-spec.json`.
- `BeamShaders.metal` reproduces the web's layer construction per pixel:
  CSS radial-gradient blob stacks (premultiplied source-over), conic
  highlight/bloom gradients, the rotating conic beam-window mask, rounded-rect
  ring geometry via SDF, and the CSS filter chain (`hue-rotate` → `brightness`
  → `saturate`) using the exact W3C feColorMatrix math.
- `TimelineView(.animation)` drives the beam angle and hue shift; the pulse
  family is driven by `PulseDriver` (a port of the web `pulseDriver.ts`).

## Building

Requires full Xcode — the `.metal` shader is compiled by Xcode's build system;
Command Line Tools alone can only build the Swift sources. No `sudo
xcode-select` needed; point `DEVELOPER_DIR` at Xcode instead:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -scheme BorderBeamKit -destination 'platform=macOS' build
```

## Demo app (macOS)

```bash
Demo/run.sh
```

Generates the Xcode project (XcodeGen), builds, and launches a native macOS
replica of the website's playground: Rotate/Pulse family tabs, type, color
variant and strength controls, a live preview card with play/pause, the
generated code snippet, and a dark/light theme toggle.

First-time setup: `brew install xcodegen`.

## Parity snapshots

`./snapshot.sh [output-dir]` renders all 40 combinations (5 types × 4 variants
× dark/light) to PNGs through the real SwiftUI + Metal pipeline, headlessly —
`ImageRenderer` does execute `colorEffect` shaders. Each capture is diffed
against a beam-off render of the same card so an empty frame fails the test;
diffing rather than color detection is what covers the greyscale `mono`
variant. Deterministic freeze times come from the internal `\.beamFrozenTime`
environment value; `line` must land between 32.5% and 67.5% of its cycle or
its `edgeFade` keyframe legitimately renders near-nothing.

## License

MIT — see [LICENSE](LICENSE). Original web library and visual design by
[Jakub Antalik](https://github.com/Jakubantalik/border-beam).
