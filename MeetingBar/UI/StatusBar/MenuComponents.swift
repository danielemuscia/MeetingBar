// MenuComponents.swift — Shared UI primitives: Avatar, ServiceMark, Separator, SectionHeader, ActionRow
import SwiftUI

// MARK: - Avatar

private let kAvatarHues: [Double] = [12, 35, 145, 200, 235, 280, 320]

struct AvatarView: View {
    let name: String
    let idx: Int
    var size: CGFloat = 22

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined()
    }

    private var hue: Double { kAvatarHues[idx % kAvatarHues.count] / 360 }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hue: hue, saturation: 0.72, brightness: 0.85),
                            Color(hue: (kAvatarHues[idx % kAvatarHues.count] + 20) / 360,
                                  saturation: 0.76, brightness: 0.72),
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            Text(initials)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 0.5))
    }
}

struct AvatarStackView: View {
    let people: [String]
    var max: Int = 4
    var size: CGFloat = 22

    private var shown: [String] { Array(people.prefix(max)) }
    private var extra: Int { Swift.max(0, people.count - max) }

    var body: some View {
        HStack(spacing: -(size * 0.32)) {
            ForEach(Array(shown.enumerated()), id: \.offset) { idx, name in
                AvatarView(name: name, idx: idx, size: size)
                    .zIndex(Double(max - idx))
            }
            if extra > 0 {
                ZStack {
                    Circle()
                        .fill(Color.secondary.opacity(0.15))
                        .overlay(Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 0.5))
                    Text("+\(extra)")
                        .font(.system(size: size * 0.38, weight: .semibold))
                        .foregroundColor(Color.secondary.opacity(0.8))
                }
                .frame(width: size, height: size)
                .zIndex(0)
            }
        }
    }
}

// MARK: - ServiceMark

struct ServiceMarkView: View {
    let service: MeetingServices?
    var size: CGFloat = 22

    private var cfg: (bg: Color, letter: String) {
        switch service {
        case .zoom, .zoom_native, .zoomgov:
            return (Color(red: 0.176, green: 0.549, blue: 1.0), "Z")
        case .meet, .hangouts, .meetStream:
            return (Color(red: 0.0, green: 0.537, blue: 0.482), "M")
        case .teams:
            return (Color(red: 0.314, green: 0.349, blue: 0.788), "T")
        case .webex:
            return (Color(red: 0.055, green: 0.361, blue: 0.212), "W")
        case .slack:
            return (Color(red: 0.44, green: 0.02, blue: 0.42), "S")
        case .discord:
            return (Color(red: 0.345, green: 0.396, blue: 0.949), "D")
        case .facetime, .facetimeaudio:
            return (Color(red: 0.18, green: 0.8, blue: 0.44), "F")
        default:
            return (Color(red: 0.557, green: 0.557, blue: 0.576), "•")
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.27)
                .fill(cfg.bg)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.27)
                        .stroke(.white.opacity(0.12), lineWidth: 0.5)
                )
            Text(cfg.letter)
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.18), radius: 1.5, x: 0, y: 1)
    }
}

// MARK: - Separator

struct MenuSeparator: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Rectangle()
            .fill(Color.mbStroke(scheme))
            .frame(height: 0.5)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
    }
}

// MARK: - Section header

struct SectionHeaderView: View {
    let title: String
    var sub: String? = nil
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(Color.mbText3(scheme))
            Spacer()
            if let sub {
                Text(sub)
                    .font(.system(size: 11))
                    .foregroundColor(Color.mbText3(scheme))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }
}

// MARK: - Action row

struct ActionRowView: View {
    let icon: String
    let label: String
    var kbd: String? = nil
    var danger: Bool = false
    var action: (() -> Void)?

    @Environment(\.colorScheme) private var scheme
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color.mbText2(scheme))
                .frame(width: 16)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(danger ? Color.mbDanger : Color.mbText1(scheme))
            Spacer()
            if let kbd {
                Text(kbd)
                    .font(.system(size: 11.5))
                    .foregroundColor(Color.mbText3(scheme))
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(hovered ? Color.mbHover(scheme) : .clear)
        )
        .padding(.horizontal, 6)
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
        .onTapGesture { action?() }
    }
}

// MARK: - Icon button (header toolbar)

struct IconButtonView: View {
    let systemName: String
    var action: () -> Void
    @Environment(\.colorScheme) private var scheme
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(hovered ? Color.mbText1(scheme) : Color.mbText2(scheme))
                .frame(width: 26, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(hovered ? Color.mbHover(scheme) : .clear)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}
