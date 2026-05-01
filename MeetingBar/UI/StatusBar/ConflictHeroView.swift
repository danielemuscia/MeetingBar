// ConflictHeroView.swift
// NO animations. Static accent dot, no pulsing.
import SwiftUI
import Defaults

struct ConflictHeroView: View {
    let events: [MBEvent]
    var density: DensityPreset = .comfortable
    var selectedEventId: String?
    var onSelect: (String) -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var pulsing = false

    var body: some View {
        VStack(spacing: 0) {
            headerStrip
            ForEach(Array(events.enumerated()), id: \.element.id) { idx, event in
                if idx > 0 {
                    Rectangle()
                        .fill(Color.mbStrokeSoft(scheme))
                        .frame(height: 0.5)
                        .padding(.horizontal, 12)
                }
                eventRow(for: event)
            }
        }
        .background(cardBackground)
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .onAppear { pulsing = true }
    }

    // MARK: - Header strip

    private var headerStrip: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 6, height: 6)
                .scaleEffect(pulsing ? 0.75 : 1.0)
                .opacity(pulsing ? 0.7 : 1.0)
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulsing)
            Text("\(events.count) HAPPENING NOW")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(Color.accentColor)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Event row

    @ViewBuilder
    private func eventRow(for event: MBEvent) -> some View {
        let isSelected = selectedEventId == event.id
        let calColor   = Color(nsColor: event.calendar.color)

        HStack(spacing: 10) {
            Circle().fill(calColor).frame(width: 8, height: 8)

            if event.meetingLink != nil {
                ServiceMarkView(service: event.meetingLink?.service, size: 22)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.mbText1(scheme))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(timeString(for: event))
                        .font(.system(size: 11.5).monospacedDigit())
                        .foregroundColor(Color.mbText2(scheme))
                        .fixedSize()
                    if let loc = event.location, !loc.isEmpty {
                        Text("·").foregroundColor(Color.mbText2(scheme).opacity(0.5))
                        HStack(spacing: 4) {
                            Image(systemName: "mappin").font(.system(size: 10))
                            Text(loc).lineLimit(1)
                        }
                        .font(.system(size: 11.5))
                        .foregroundColor(Color.mbText2(scheme))
                    }
                }
                .lineLimit(1)
            }

            Spacer(minLength: 0)

            if event.meetingLink != nil {
                Button { event.openMeeting() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "video").font(.system(size: 11))
                        Text("Join").font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.accentColor)
                    .cornerRadius(7)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(isSelected
            ? Color.accentColor.opacity(scheme == .dark ? 0.18 : 0.12)
            : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { onSelect(event.id) }
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
            RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        }
    }

    private func timeString(for event: MBEvent) -> String {
        let f = DateFormatter()
        f.locale = I18N.instance.locale
        f.dateFormat = Defaults[.timeFormat] == .am_pm ? "h:mm a" : "HH:mm"
        return "\(f.string(from: event.startDate))–\(f.string(from: event.endDate))"
    }
}
