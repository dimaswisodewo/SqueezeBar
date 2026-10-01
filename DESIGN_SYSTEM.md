# SqueezeBar design system

SqueezeBar is a local utility with a bold, utilitarian interface. The visual language is full brutalism: square geometry, black and white surfaces, thick outlines, crisp offset shadows, and neon fills. Both appearances follow macOS automatically.

## Foundations

`DesignTokens` is the source of truth. Use `DesignTokens.Palette(colorScheme)` when a view has an explicit appearance; adaptive `DesignTokens.Colors` serve shared controls and settings. Do not introduce screen-specific palettes.

| Role | Light | Dark | Usage |
| --- | --- | --- | --- |
| Canvas / surface | `#FFFFFF` | `#0A0A0A` | Backgrounds and panels |
| Ink / outline | `#0A0A0A` | `#FFFFFF` | Text, symbols, 2-point outlines |
| Inset | 94% white | 12% white | Fields, secondary surfaces |
| Muted text | 36% white | 73% white | Descriptions and metadata |
| Action / selection / success | `#C6FF00` | `#C6FF00` | Neon lime fills |
| Drop target / notice | `#F5FF00` | `#F5FF00` | Neon yellow fills |

Always use black text on neon fills. Neon is not a small-text color on white. Explain errors with text and an error symbol on a monochrome panel. Pair success, notices, and selection with explicit labels or symbols.

Use a 4-point spacing grid: 4, 8, 12, 16, 20, and 24 points. Panel padding is 16 points; outer padding is 20 points. Corners are square. Outlines are 2 points; raised panels and primary buttons use a zero-blur shadow offset 3 points right/down. Reserve layout space for shadows.

## Typography

| Token | Typeface | Size | Usage |
| --- | --- | --- | --- |
| `hero` | Archivo Black | 28 | Empty-state headline |
| `title` | Archivo Black | 20 | Wordmark and status headings |
| `heading` | IBM Plex Sans Semibold | 13 | Controls and filenames |
| `body` | IBM Plex Sans Regular | 13 | Explanatory text |
| `caption` | IBM Plex Sans Regular | 11 | Supporting text |
| `label` | IBM Plex Mono Medium | 11 | Section labels, badges, percentages |
| `metadata` | IBM Plex Mono Regular | 11 | Sizes, formats, dimensions, paths |

Uppercase short labels and prominent headings. Keep body text in sentence case and filenames in their original case. Long filenames truncate in the middle; multi-line messages wrap. SF Symbols retain system symbol fonts.

Fonts are bundled and registered once by `BundledFonts` before app views load. Typography tokens also trigger registration for previews. No font installation or runtime network request is needed.

Sources: [Archivo Black / Omnibus-Type](https://www.omnibus-type.com/fonts/archivo/), [IBM Plex](https://github.com/IBM/plex/), and [Google Fonts](https://github.com/google/fonts). Original font binaries and each family's Open Font License are in `SqueezeBar/Resources/Fonts`.

## Components and behavior

- `BrutalistPanel`: bordered, raised container; group related controls without nesting panels.
- `BrutalistPrimaryButton` / `BrutalistButtonStyle`: lime primary action or outlined secondary control. The primary shadow compresses on press in 120 ms. Native buttons keep keyboard activation and disabled behavior; keyboard focus adds a dashed outline.
- `BrutalistChoiceChip`, `BrutalistChoicePicker`, `BrutalistActionRow`: immediate selection, lime fill with black ink, selected accessibility traits. Use a grid rather than squeezing long options into one segmented row.
- `BrutalistQuietButtonStyle`: text and compact row actions; underline on hover/focus, without scaling.
- `BrutalistSlider`: square lime thumb and bordered track, implemented with a native `NSSlider` and custom cell drawing. Arrow keys adjust one configured step, dragging snaps relative to the lower bound, and the accessible value describes a percentage.
- `BrutalistToggleStyle`: square lime checkbox row with native button keyboard activation and a native toggle accessibility representation.
- `BrutalistSecureField`: native password input with inset fill, outline, and thicker bottom edge while focused.
- `BrutalistDropSurface`: dashed idle outline; yellow fill and solid black outline while targeted. Processing disables file changes.
- `BrutalistBadge`, `BrutalistStatusPanel`, `ProgressIndicatorView`: format metadata and explicit status feedback. Errors use symbols and text rather than introducing another palette.
- `OutputFolderSectionView`: shared destination selection; compact layout anchors the popover footer.

Reduce Motion disables positional press feedback. Selection and hover feedback remain immediate. Do not add bouncing, hover scaling, ornamental transitions, or popover opening animations. Native progress feedback remains system-controlled.

The popover is 420 points wide, with fixed header/footer and a scrolling workspace. Existing screen-height limits remain in effect. The component gallery is debug-only and accessible through light and dark SwiftUI previews in `DesignSystemGallery`; it is not a production screen. Check Reduce Motion using the macOS accessibility setting, which SwiftUI exposes as a read-only environment value.

## Verification checklist

Build the macOS scheme. Inspect light/dark and live appearance switching, idle/targeted drops, long names, image ordering, format and quality selection, secure inputs, password mismatch, disabled controls, missing destination, progress, errors, and results. Exercise keyboard focus, Command-Return, slider arrows, VoiceOver selection/values, and Reduce Motion. Verify fonts from the app bundle rather than relying on installed fonts. Manually smoke-test local compression/conversion and a failed input; processing behavior is outside the design system.
