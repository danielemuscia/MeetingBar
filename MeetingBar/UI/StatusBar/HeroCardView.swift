// HeroCardView.swift
// NO animations. Pulsing dot removed — static accent circle.
import SwiftUI
import Defaults

struct HeroCardView: View {
    let event: MBEvent
    var density: DensityPreset = .comfortable
    var selected: Bool = false
    var onSelect: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var pulsing = false

    private var minutesRemaining: Int {
        max(0, Int(event.endDate.timeIntervalSinceNow / 60))
    }

    private var timeString: String {
        let f = DateFormatter()
        f.locale = I18N.instance.locale
        f.dateFormat = Defaults[.timeFormat] == .am_pm ? "h:mm a" : "HH:mm"
        return "\(f.string(from: event.startDate)) – \(f.string(from: event.endDate))"
    }

    var body: some View {
        VStack(spacing: 0) {
            mainRow
            if !event.attendees.isEmpty {
                footerRow
            }
        }
        .padding(.vertical, density.heroPaddingV)
        .padding(.horizontal, 14)
        .background(cardBackground)
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onAppear { pulsing = true }
    }

    // MARK: - Main row

    private var mainRow: some View {
        HStack(alignment: .top, spacing: 12) {
            if event.meetingLink != nil {
                ServiceMarkView(service: event.meetingLink?.service, size: 32)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                        .scaleEffect(pulsing ? 0.75 : 1.0)
                        .opacity(pulsing ? 0.7 : 1.0)
                        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulsing)
                    Text("NOW · ENDS IN \(minutesRemaining)M")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(Color.accentColor)
                }

                Text(event.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.mbText1(scheme))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(timeString)
                        .font(.system(size: 12).monospacedDigit())
                        .foregroundColor(Color.mbText2(scheme))
                        .fixedSize()

                    if let loc = event.location, !loc.isEmpty {
                        Text("·").foregroundColor(Color.mbText2(scheme).opacity(0.5)).fixedSize()
                        HStack(spacing: 4) {
                            Image(systemName: "mappin").font(.system(size: 10))
                            Text(loc).lineLimit(1)
                        }
                        .font(.system(size: 12))
                        .foregroundColor(Color.mbText2(scheme))
                    }
                }
                .lineLimit(1)
            }

            Spacer(minLength: 0)

            if event.meetingLink != nil {
                Button { event.openMeeting() } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "video").font(.system(size: 12))
                        Text("Join").font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 14)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Footer

    private var footerRow: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.mbStrokeSoft(scheme))
                .frame(height: 0.5)
                .padding(.top, 10)
            HStack(spacing: 10) {
                AvatarStackView(people: event.attendees.map(\.name), max: 5, size: 20)
                Text("\(event.attendees.count) attendees")
                    .font(.system(size: 11.5))
                    .foregroundColor(Color.mbText2(scheme))
                Spacer()
            }
            .padding(.top, 10)
        }
    }

    // MARK: - Background

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(Color.mbHeroBg(scheme))
            RoundedRectangle(cornerRadius: 12).fill(
                LinearGradient(
                    colors: [Color.accentColor.opacity(scheme == .dark ? 0.22 : 0.14),
                             Color.accentColor.opacity(0)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            RoundedRectangle(cornerRadius: 12)
                .stroke(selected ? Color.accentColor.opacity(0.55) : Color.black.opacity(0.06),
                        lineWidth: selected ? 2 : 0.5)
        }
    }
}
