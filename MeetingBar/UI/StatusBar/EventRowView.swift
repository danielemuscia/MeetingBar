// EventRowView.swift — Individual event row in the menu list
import SwiftUI

struct EventRowView: View {
    let event: MBEvent
    var density: DensityPreset = .comfortable
    var showNotes: Bool = true
    var selected: Bool = false
    var onSelect: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var hovered = false

    private var isPast: Bool { event.endDate < Date() }
    private var isDeclined: Bool {
        event.participationStatus == .declined || event.status == .canceled
    }
    private var rowOpacity: Double {
        if isPast { return 0.42 }
        if isDeclined { return 0.55 }
        return 1.0
    }

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: event.startDate)
    }

    private var calendarColor: Color { Color(nsColor: event.calendar.color) }

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 10) {
                // Time column
                Text(timeString)
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundColor(isPast ? Color.mbText3(scheme) : Color.mbText2(scheme))
                    .strikethrough(isDeclined)
                    .frame(width: 42, alignment: .leading)
                    .padding(.top, 1)

                // Calendar color dot
                Circle()
                    .fill(calendarColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: calendarColor.opacity(isPast ? 0 : 0.28), radius: 2)
                    .padding(.top, 5)

                // Main content
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.system(size: density.titleFontSize, weight: .medium))
                        .tracking(-0.2)
                        .foregroundColor(Color.mbText1(scheme))
                        .strikethrough(isDeclined)
                        .lineLimit(1)

                    if density != .compact {
                        HStack(spacing: 6) {
                            if let location = event.location {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin")
                                        .font(.system(size: 10))
                                    Text(location)
                                }
                            }
                            if event.location != nil {
                                Text("·").opacity(0.5)
                            }
                            HStack(spacing: 3) {
                                Image(systemName: "person.2")
                                    .font(.system(size: 10))
                                Text("\(event.attendees.count)")
                            }
                        }
                        .font(.system(size: 11.5))
                        .foregroundColor(Color.mbText2(scheme))
                        .lineLimit(1)
                    }

                    if showNotes, let notes = event.notes, !notes.isEmpty, density == .spacious {
                        Text(notes)
                            .font(.system(size: 11))
                            .foregroundColor(Color.mbText3(scheme))
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                // Right: avatar stack + service mark
                HStack(spacing: 8) {
                    if density != .compact {
                        AvatarStackView(people: event.attendees.map(\.name), max: 3, size: 18)
                    }
                    ServiceMarkView(service: event.meetingLink?.service, size: 20)
                }
            }
            .padding(.vertical, density.rowPaddingV)
            .padding(.horizontal, 8)
            .padding(.leading, 2)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        selected
                            ? Color.accentColor.opacity(0.22)
                            : (hovered ? Color.mbHover(scheme) : .clear)
                    )
            )
            .opacity(rowOpacity)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
        .onHover { hovered = $0 }
    }
}
