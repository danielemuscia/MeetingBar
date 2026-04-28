// DesignTokens.swift — Visual design tokens matching the Apple-native prototype
import SwiftUI

// MARK: - Color tokens

extension Color {
    // Text hierarchy (light/dark adaptive)
    static func mbText1(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.95) : .black.opacity(0.92)
    }
    static func mbText2(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.60) : .black.opacity(0.60)
    }
    static func mbText3(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.42) : .black.opacity(0.42)
    }
    static func mbStroke(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.10) : .black.opacity(0.08)
    }
    static func mbStrokeSoft(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.07) : .black.opacity(0.06)
    }
    static func mbHover(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.07) : .black.opacity(0.05)
    }
    static func mbChip(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.10) : .black.opacity(0.06)
    }
    static func mbHeroBg(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.07) : .white.opacity(0.70)
    }

    static let mbDanger = Color(red: 1.0, green: 0.231, blue: 0.188) // #FF3B30
}

// MARK: - Density preset

enum DensityPreset {
    case compact, comfortable, spacious

    var rowPaddingV: CGFloat {
        switch self {
        case .compact: return 7
        case .comfortable: return 10
        case .spacious: return 12
        }
    }

    var heroPaddingV: CGFloat {
        switch self {
        case .compact: return 12
        case .comfortable: return 16
        case .spacious: return 18
        }
    }

    var titleFontSize: CGFloat {
        self == .compact ? 13 : 13.5
    }
}
