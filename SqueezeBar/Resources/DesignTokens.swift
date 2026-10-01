import SwiftUI
import CoreText

enum DesignTokens {
    enum Colors {
        static let black = Color(red: 10 / 255, green: 10 / 255, blue: 10 / 255)
        static let white = Color.white
        static let lime = Color(red: 198 / 255, green: 1, blue: 0)
        static let yellow = Color(red: 245 / 255, green: 1, blue: 0)

        static let canvas = adaptive(light: .white, dark: NSColor(white: 10 / 255, alpha: 1))
        static let ink = adaptive(light: NSColor(white: 10 / 255, alpha: 1), dark: .white)
        static let muted = adaptive(light: NSColor(white: 0.36, alpha: 1), dark: NSColor(white: 0.73, alpha: 1))
        static let inset = adaptive(light: NSColor(white: 0.94, alpha: 1), dark: NSColor(white: 0.12, alpha: 1))

        private static func adaptive(light: NSColor, dark: NSColor) -> Color {
            Color(nsColor: NSColor(name: nil) { appearance in
                appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
            })
        }
    }

    struct Palette {
        let canvas: Color
        let surface: Color
        let inset: Color
        let ink: Color
        let muted: Color
        let outline: Color
        let accent = Colors.lime
        let notice = Colors.yellow

        init(_ scheme: ColorScheme) {
            canvas = scheme == .dark ? Colors.black : Colors.white
            surface = canvas
            inset = scheme == .dark ? Color(white: 0.12) : Color(white: 0.94)
            ink = scheme == .dark ? Colors.white : Colors.black
            muted = scheme == .dark ? Color(white: 0.73) : Color(white: 0.36)
            outline = ink
        }
    }

    enum Typography {
        static var hero: Font { custom("ArchivoBlack-Regular", size: 28) }
        static var title: Font { custom("ArchivoBlack-Regular", size: 20) }
        static var heading: Font { custom("IBMPlexSans-SmBld", size: 13) }
        static var body: Font { custom("IBMPlexSans", size: 13) }
        static var caption: Font { custom("IBMPlexSans", size: 11) }
        static var label: Font { custom("IBMPlexMono-Medium", size: 11) }
        static var metadata: Font { custom("IBMPlexMono-Regular", size: 11) }
        static var tiny: Font { caption }

        private static func custom(_ name: String, size: CGFloat) -> Font {
            // Previews don't run the app entry point, so registration is also lazy.
            BundledFonts.register()
            return .custom(name, fixedSize: size)
        }
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let outer: CGFloat = 20
    }

    enum Geometry {
        static let border: CGFloat = 2
        static let shadowOffset: CGFloat = 3
        static let controlHeight: CGFloat = 36
        static let actionHeight: CGFloat = 44
        static let popoverWidth: CGFloat = 420
    }

    enum Motion {
        static let press = Animation.easeOut(duration: 0.12)
    }
}

enum BundledFonts {
    static let names = [
        "ArchivoBlack-Regular", "IBMPlexSans-Regular", "IBMPlexSans-SemiBold",
        "IBMPlexMono-Regular", "IBMPlexMono-Medium"
    ]

    private static let registration: Void = {
        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                NSLog("Missing bundled font: %@", name)
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error),
               let fontError = error?.takeRetainedValue(),
               CFErrorGetCode(fontError) != CTFontManagerError.alreadyRegistered.rawValue {
                NSLog("Could not register font %@: %@", name, String(describing: fontError))
            }
        }
    }()

    static func register() {
        _ = registration
    }
}
