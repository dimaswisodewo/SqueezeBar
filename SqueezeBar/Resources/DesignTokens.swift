import SwiftUI
import CoreText

enum DesignTokens {
    enum Colors {
        static let black = color(0x20211D)
        static let white = color(0xF2F1E9)
        static let lime = color(0xBCD85F)
        static let yellow = color(0xE4D879)

        static let canvas = adaptive(light: nsColor(0xF2F1E9), dark: nsColor(0x191B17))
        static let ink = adaptive(light: nsColor(0x20211D), dark: nsColor(0xE5E5DA))
        static let muted = adaptive(light: nsColor(0x595B50), dark: nsColor(0xB9BCAF))
        static let inset = adaptive(light: nsColor(0xE8E8DF), dark: nsColor(0x24271F))
        static let selection = adaptive(light: nsColor(0xE5EBCF), dark: nsColor(0x2A3021))

        fileprivate static func color(_ hex: Int) -> Color { Color(nsColor: nsColor(hex)) }

        private static func nsColor(_ hex: Int) -> NSColor {
            NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
                    green: CGFloat((hex >> 8) & 255) / 255,
                    blue: CGFloat(hex & 255) / 255, alpha: 1)
        }

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
        let selection: Color
        let accent = Colors.lime
        let notice = Colors.yellow

        init(_ scheme: ColorScheme) {
            canvas = scheme == .dark ? Colors.color(0x191B17) : Colors.white
            surface = canvas
            inset = scheme == .dark ? Colors.color(0x24271F) : Colors.color(0xE8E8DF)
            ink = scheme == .dark ? Colors.color(0xE5E5DA) : Colors.black
            muted = scheme == .dark ? Colors.color(0xB9BCAF) : Colors.color(0x595B50)
            outline = ink
            selection = scheme == .dark ? Colors.color(0x2A3021) : Colors.color(0xE5EBCF)
        }
    }

    enum Typography {
        static var hero: Font { custom("ArchivoBlack-Regular", size: 24) }
        static var title: Font { custom("ArchivoBlack-Regular", size: 20) }
        static var status: Font { custom("ArchivoBlack-Regular", size: 18) }
        static var heading: Font { custom("IBMPlexMono-Medium", size: 13) }
        static var body: Font { custom("IBMPlexMono-Regular", size: 13) }
        static var caption: Font { custom("IBMPlexMono-Regular", size: 12) }
        static var label: Font { custom("IBMPlexMono-Medium", size: 13) }
        static var metadata: Font { custom("IBMPlexMono-Regular", size: 12) }
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
        "ArchivoBlack-Regular", "IBMPlexMono-Regular", "IBMPlexMono-Medium"
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
