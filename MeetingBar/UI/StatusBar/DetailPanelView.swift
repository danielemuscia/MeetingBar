// DetailPanelView.swift
// Fills the full 380×640 ZStack overlay — no fixed width, no height constraint.
// Animation is driven by the parent ZStack transition (.move + .opacity).
// No @State for visibility, no withAnimation, no onAppear animation here.
import SwiftUI
import Defaults

struct DetailPanelView: View {
    let event: MBEvent
    var onClose: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var showAllAttendees = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 0) {
                    section("Status")  { statusRow }
                    section("When")    { whenRow }
                    if event.location != nil || event.meetingLink != nil {
                        section("Where") { whereRow }
                    }
                    if let org = event.organizer {
                        section("Organizer") { organizerRow(org) }
                    }
                    if !event.attendees.isEmpty {
                        section("Attendees") { attendeesRow }
                    }
                    if let notes = event.notes, !notes.isEmpty {
                        section("Notes") { notesRow(notes) }
                    }
                    section("Actions") { actionsRow }
                }
            }
            .scrollContentBackground(.hidden)
        }
        // Fill the full ZStack width; use a solid background so the main menu
        // underneath is completely hidden while the panel is visible.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.mbBackground(scheme))
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(Color(nsColor: event.calendar.color))
                    .frame(width: 10, height: 10)
                    .padding(.top, 5)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.mbText1(scheme))
                        .lineLimit(2)
                    Text(event.calendar.title)
                        .font(.system(size: 11.5))
                        .foregroundColor(Color.mbText2(scheme))
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.mbText2(scheme))
                        .frame(width: 22, height: 22)          // hit area inside label
                        .background(Color.mbHover(scheme))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .contentShape(Circle().size(CGSize(width: 22, height: 22)))
            }

            if event.meetingLink != nil {
                Button { event.openMeeting() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "video").font(.system(size: 13))
                        Text(joinLabel).font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
    }

    private var joinLabel: String {
        if let name = event.meetingLink?.service?.localizedValue, !name.isEmpty {
            return "Join \(name)"
        }
        return "Join meeting"
    }

    // MARK: - Section wrapper

    private func section<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.6)
                .foregroundColor(Color.mbText3(scheme))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .overlay(
            Rectangle()
                .fill(Color.mbStrokeSoft(scheme))
                .frame(height: 0.5),
            alignment: .top
        )
    }

    // MARK: - Status

    private var statusRow: some View {
        let color = statusColor
        return HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(statusLabel)
                .font(.system(size: 13))
                .foregroundColor(Color.mbText1(scheme))
        }
    }

    private var statusColor: Color {
        switch event.participationStatus {
        case .accepted:  return .green
        case .declined:  return Color.mbDanger
        case .tentative: return .orange
        default:         return .gray
        }
    }

    private var statusLabel: String {
        switch event.participationStatus {
        case .accepted:  return "Accepted · Going"
        case .declined:  return "Declined"
        case .tentative: return "Tentative"
        case .pending:   return "Pending"
        default:         return "Unknown"
        }
    }

    // MARK: - When

    private var whenRow: some View {
        let f = DateFormatter()
        f.locale = I18N.instance.locale
        f.dateFormat = Defaults[.timeFormat] == .am_pm ? "h:mm a" : "HH:mm"
        let timeStr = "\(f.string(from: event.startDate)) – \(f.string(from: event.endDate))"
        let mins = Int(event.endDate.timeIntervalSince(event.startDate) / 60)
        return VStack(alignment: .leading, spacing: 2) {
            Text(timeStr)
                .font(.system(size: 15, weight: .semibold).monospacedDigit())
                .foregroundColor(Color.mbText1(scheme))
            Text("\(mins) minutes · \(event.startDate.formatted(.dateTime.weekday(.wide).month().day()))")
                .font(.system(size: 12))
                .foregroundColor(Color.mbText2(scheme))
        }
    }

    // MARK: - Where

    private var whereRow: some View {
        HStack(alignment: .center, spacing: 10) {
            if event.meetingLink != nil {
                ServiceMarkView(service: event.meetingLink?.service, size: 32)
            }
            VStack(alignment: .leading, spacing: 2) {
                if let loc = event.location, !loc.isEmpty {
                    Text(loc)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.mbText1(scheme))
                        .lineLimit(1)
                }
                if let link = event.meetingLink {
                    Link(link.url.absoluteString, destination: link.url)
                        .font(.system(size: 12.5))
                        .foregroundColor(Color.mbText1(scheme))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            if let link = event.meetingLink {
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(link.url.absoluteString, forType: .string)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.mbText2(scheme))
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Color.mbChip(scheme))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Organizer

    private func organizerRow(_ org: MBEventOrganizer) -> some View {
        HStack(spacing: 8) {
            AvatarView(name: org.name, idx: 3, size: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(org.name)
                    .font(.system(size: 13))
                    .foregroundColor(Color.mbText1(scheme))
                if let raw = org.email {
                    let display = raw.hasPrefix("mailto:") ? String(raw.dropFirst(7)) : raw
                    let dest = URL(string: raw.hasPrefix("mailto:") ? raw : "mailto:\(raw)")
                    if let url = dest {
                        Link(display, destination: url)
                            .font(.system(size: 11.5))
                            .foregroundColor(Color.accentColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(display)
                            .font(.system(size: 11.5))
                            .foregroundColor(Color.mbText2(scheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    // MARK: - Attendees

    private var attendeesRow: some View {
        let shown = showAllAttendees ? event.attendees : Array(event.attendees.prefix(3))
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                AvatarStackView(people: event.attendees.map(\.name), max: 5, size: 22)
                Text("\(event.attendees.count) attendees")
                    .font(.system(size: 12))
                    .foregroundColor(Color.mbText2(scheme))
            }
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(shown.enumerated()), id: \.offset) { _, attendee in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(attendeeColor(attendee.status))
                            .frame(width: 6, height: 6)
                        Text(attendee.isCurrentUser ? "\(attendee.name) (you)" : attendee.name)
                            .font(.system(size: 12.5))
                            .foregroundColor(Color.mbText1(scheme))
                    }
                }
            }
            if event.attendees.count > 3 {
                Button(showAllAttendees ? "Show less" : "Show all \(event.attendees.count)") {
                    showAllAttendees.toggle()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(Color.mbChip(scheme))
                .clipShape(Capsule())
                .foregroundColor(Color.mbText2(scheme))
            }
        }
    }

    private func attendeeColor(_ status: MBEventAttendeeStatus) -> Color {
        switch status {
        case .accepted:  return .green
        case .tentative: return .orange
        default:         return .gray
        }
    }

    // MARK: - Notes

    private func notesRow(_ notes: String) -> some View {
        Text(notes)
            .font(.system(size: 12.5))
            .foregroundColor(Color.mbText1(scheme))
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Actions

    private var actionsRow: some View {
        // Negative horizontal padding cancels the section wrapper's 14 pt inset
        // so each row's hover highlight extends flush to the section edges.
        VStack(spacing: 0) {
            actionRow("video", "Join meeting")           { event.openMeeting() }
            actionRow("doc.on.clipboard", "Copy meeting link") {
                if let url = event.meetingLink?.url {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url.absoluteString, forType: .string)
                }
            }
            actionRow("calendar", "Open in Calendar") {
                if let url = URL(string: "ical://ekevent/\(event.id)") {
                    url.openInDefaultBrowser()
                }
            }
            actionRow("envelope", "Email attendees") { event.emailAttendees() }
        }
        .padding(.horizontal, -14)
    }

    private func actionRow(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        DetailActionRow(icon: icon, label: label, action: action)
    }
}

// MARK: - Hoverable action row

private struct DetailActionRow: View {
    let icon: String
    let label: String
    let action: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(Color.mbText2(scheme))
                .frame(width: 20, alignment: .center)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color.mbText1(scheme))
            Spacer()
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 14)   // matches section inset — text stays aligned
        .background(hovered ? Color.mbHover(scheme) : .clear)
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
        .onTapGesture { action() }
    }
}
