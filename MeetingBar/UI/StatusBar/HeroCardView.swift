// HeroCardView.swift — "Happening now" hero card for the current meeting
import SwiftUI

struct HeroCardView: View {
    let event: MBEvent
    var density: DensityPreset = .comfortable
    var selected: Bool = false
    var onSelect: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 1.0

    private var minutesRemaining: Int {
        max(0, Int(event.endDate.timeIntervalSinceNow / 60))
    }

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return "\(f.string(from: event.startDate)) – \(f.string(from: event.endDate))"
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                mainRow
                if !event.attendees.isEmpty || event.notes != nil {
                    footerRow
                }
            }
            .padding(.vertical, density.heroPaddingV)
            .padding(.horizontal, 14)
            .background(heroBackground)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulseScale = 0.85
                pulseOpacity = 0.85
            }
        }
    }

    // MARK: - Subviews

    private var mainRow: some View {
        HStack(alignment: .top, spacing: 12) {
            ServiceMarkView(service: event.meetingLink?.service, size: 32)

            VStack(alignment: .leading, spacing: 4) {
                // Live indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                        .shadow(color: Color.accentColor.opacity(0.35), radius: 4)
                        .scaleEffect(pulseScale)
                        .opacity(pulseOpacity)

                    Text("HAPPENING NOW · ENDS IN \(minutesRemaining)M")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(Color.accentColor)
                }

                // Title
                Text(event.title)
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.4)
                    .foregroundColor(Color.mbText1(scheme))
                    .lineLimit(1)

                // Time + room (nowrap)
                HStack(spacing: 8) {
                    Text(timeString)
                        .font(.system(size: 12).monospacedDigit())
                        .foregroundColor(Color.mbText2(scheme))
                        .fixedSize()

                    if let location = event.location, !location.isEmpty {
                        Text("·")
                            .foregroundColor(Color.mbText2(scheme).opacity(0.5))
                            .fixedSize()
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.system(size: 10))
                            Text(location)
                                .lineLimit(1)
                        }
                        .font(.system(size: 12))
                        .foregroundColor(Color.mbText2(scheme))
                    }
                }
                .lineLimit(1)
            }

            Spacer(minLength: 0)

            // Join button — taps directly open the meeting link
            Button {
                event.openMeeting()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 12))
                    Text("Join")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 7)
                .padding(.horizontal, 14)
                .background(Color.accentColor)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(.plain)
        }
    }

    private var footerRow: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.mbStrokeSoft(scheme))
                .frame(height: 0.5)
                .padding(.top, 10)

            HStack(spacing: 10) {
                AvatarStackView(people: event.attendees.map(\.name), max: 4, size: 20)
                Text("\(event.attendees.count) attendees")
                    .font(.system(size: 11.5))
                    .foregroundColor(Color.mbText2(scheme))
                if let notes = event.notes, !notes.isEmpty {
                    Text("·")
                        .foregroundColor(Color.mbText2(scheme).opacity(0.4))
                    Text(notes)
                        .font(.system(size: 11.5))
                        .foregroundColor(Color.mbText2(scheme))
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.top, 10)
        }
    }

    private var heroBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.mbHeroBg(scheme))
            // Accent gradient wash
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(scheme == .dark ? 0.22 : 0.14),
                            Color.accentColor.opacity(0),
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            // Selection ring or hairline border
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    selected ? Color.accentColor.opacity(0.55) : Color.black.opacity(0.06),
                    lineWidth: selected ? 2 : 0.5
                )
        }
    }
}
