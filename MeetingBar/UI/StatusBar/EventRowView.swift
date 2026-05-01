// EventRowView.swift
// NO animations. Hover is a plain fill swap, no withAnimation.
import SwiftUI
import Defaults

struct EventRowView: View {
    let event: MBEvent
    var density: DensityPreset = .comfortable
    var showNotes: Bool = true
    var selected: Bool = false
    var onSelect: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var hovered = false

    private var isPast:     Bool   { event.endDate < Date() }
    private var isDeclined: Bool   { event.participationStatus == .declined || event.status == .canceled }
    private var rowOpacity: Double { isPast ? 0.42 : isDeclined ? 0.55 : 1.0 }
    private var calColor:   Color  { Color(nsColor: event.calendar.color) }

    private var timeString: String {
        let f = DateFormatter()
        f.locale = I18N.instance.locale
        f.dateFormat = Defaults[.timeFormat] == .am_pm ? "h:mm a" : "HH:mm"
        return f.string(from: event.startDate)
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 10) {
                Text(timeString)
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundColor(isPast ? Color.mbText3(scheme) : Color.mbText2(scheme))
                    .strikethrough(isDeclined)
                    .frame(width: 42, alignment: .leading)
                    .padding(.top, 1)

                Circle()
                    .fill(calColor)
                    .frame(width: 8, height: 8)
                    .padding(.top, 5)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.system(size: density.titleFontSize, weight: .medium))
                        .foregroundColor(Color.mbText1(scheme))
                        .strikethrough(isDeclined)
                        .lineLimit(1)

                    if density != .compact {
                        HStack(spacing: 6) {
                            if let loc = event.location {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin").font(.system(size: 10))
                                    Text(loc)
                                }
                            }
                            if event.location != nil { Text("·").opacity(0.5) }
                            HStack(spacing: 3) {
                                Image(systemName: "person.2").font(.system(size: 10))
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

                HStack(spacing: 8) {
                    if density != .compact {
                        AvatarStackView(people: event.attendees.map(\.name), max: 3, size: 18)
                    }
                    if event.meetingLink != nil {
                        ServiceMarkView(service: event.meetingLink?.service, size: 20)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, density.rowPaddingV)
            .padding(.horizontal, 8)
            .padding(.leading, 2)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selected ? Color.accentColor.opacity(0.15) : .clear)
            )
            .opacity(rowOpacity)
        }
        .buttonStyle(MenuItemStyle(isHovered: hovered && !selected, cornerRadius: 8))
        .padding(.horizontal, 6)
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
    }
}
