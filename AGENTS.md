# SqueezeBar agent guide

SqueezeBar is a macOS app for compressing images, videos, and PDFs and converting media. Its main interface is a status bar popover; the current app also has a Dock icon. Files are processed locally.

## Where to work

- `SqueezeBar/App/`: app entry point, status item, popover, and file-open handling.
- `SqueezeBar/Views/`: SwiftUI screens and reusable controls.
- `SqueezeBar/ViewModels/`: UI state and coordination of user actions.
- `SqueezeBar/Models/`: settings, options, and results.
- `SqueezeBar/Logic/`: compression and conversion managers and per-format strategies.
- `SqueezeBar/Resources/`: design helpers and the bundled Ghostscript binary used for PDF compression.

Follow the existing path for a feature: view → view model → manager → format strategy. Keep media processing out of views. Change only the layers the task needs.

## Implementation principles

- Keep it simple (KISS): prefer clear control flow, descriptive names, and small functions over clever or generic machinery.
- Build only what the task needs (YAGNI): do not add speculative formats, settings, protocols, dependencies, or fallback paths.
- Make code readable: follow nearby Swift style, keep related behavior together, and comment on non-obvious reasons rather than restating the code.
- Reuse existing models and strategies where they fit. Introduce a new abstraction only when it removes real duplication or clarifies a current behavior.
- Keep the popover responsive during long-running work. Update observable UI state on the main actor and propagate useful errors to the user.

## File handling

- Respect the app sandbox. Use security-scoped access for user-selected input files and output folders, and balance each successful access with a stop when the work ends.
- Write results to the chosen output folder without overwriting the source or an existing result. Clean up incomplete output on failure when relevant.
- Keep media and PDF processing local. Do not send user files to a network service.
- Preserve the behavior of unaffected formats when changing a compressor or converter.

## Verification

- Build the `SqueezeBar` scheme in `SqueezeBar.xcodeproj` for macOS. For a command-line check, use `xcodebuild -project SqueezeBar.xcodeproj -scheme SqueezeBar -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build`.
- There is currently no test target. Check the affected compression or conversion workflow manually when feasible, including an unsupported or failed input.
- Report what was verified and any pre-existing issue that prevented a check. Do not change unrelated worktree changes.
