// DetailPanelView.swift — Detail panel showing full meeting info (slides in left of menu)
import SwiftUI

struct DetailPanelView: View {
    let event: MBEvent
    var onClose: () -> Void

    @Environment(\.colorScheme) private var scheme

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return "\(f.string(from: event.startDate)) – \(f.string(from: event.endDate))"
    }

    private var durationMinutes: Int {
        Int(event.endDate.timeIntervalSince(event.startDate) / 60)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                headerSection
                ScrollView {
                    VStack(spacing: 0) {
                        DetailSection(label: "Status") { statusContent }
                        DetailSection(label: "When") { whenContent }
                        if event.location != nil || event.meetingLink != nil {
                            DetailSection(label: "Where") { whereContent }
                        }
                        if let organizer = event.organizer {
                            DetailSection(label: "Organizer") { organizerContent(organizer) }
                        }
                        if !event.attendees.isEmpty {
                            DetailSection(label: "Attendees") { attendeesContent }
                        }
                        if let notes = event.notes, !notes.isEmpty {
                            DetailSection(label: "Notes") { notesContent(notes) }
                        }
                        DetailSection(label: "Actions") { actionsContent }
                    }
                }
            }

            // Arrow tail pointing right toward the menu
            tailArrow
        }
        .frame(width: 320)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.mbStroke(scheme), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(scheme == .dark ? 0.5 : 0.18), radius: 14, x: 0, y: 8)
        .shadow(color: .black.opacity(scheme == .dark ? 0.55 : 0.22), radius: 35, x: 0, y: 20)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(Color(nsColor: event.calendar.color))
                    .frame(width: 10, height: 10)
                    .shadow(color: Color(nsColor: event.calendar.color).opacity(0.22), radius: 3)
                    .padding(.top, 5)

                VStack(alignment: .leading, spacing: 1) {
                    Text(event.title)
                        .font(.system(size: 16, weight: .semibold))
                        .tracking(-0.4)
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
                }
                .buttonStyle(.plain)
                .frame(width: 22, height: 22)
                .background(Color.mbHover(scheme))
                .clipShape(Circle())
            }

            Button { event.openMeeting() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "video.fill").font(.system(size: 13))
                    Text("Join \(event.meetingLink?.service.rawValue ?? "") meeting")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.accentColor)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    // MARK: - Arrow tail

    private var tailArrow: some View {
        GeometryReader { _ in
            Rectangle()
                .fill(.ultraThinMaterial)
                .frame(width: 12, height: 12)
                .overlay(
                    Rectangle().stroke(Color.mbStroke(scheme), lineWidth: 0.5)
                )
                .rotationEffect(.degrees(45))
                .offset(x: 320 - 6, y: 22)
        }
    }

    // MARK: - Section contents

    private var statusContent: some View {
        HStack(spacing: 8) {
            let statusColor: Color = {
                switch event.participationStatus {
                case .accepted: return .green
                case .declined: return Color.mbDanger
                case .tentative: return .orange
                default: return .gray
                }
            }()
            Circle().fill(statusColor).frame(width: 8, height: 8)
                .shadow(color: statusColor.opacity(0.3), radius: 3)
            let label: String = {
                switch event.participationStatus {
                case .accepted: return "Accepted · Going"
                case .declined: return "Declined"
                case .tentative: return "Tentative"
                case .pending: return "Pending"
                default: return "Unknown"
                }
            }()
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color.mbText1(scheme))
        }
    }

    private var whenContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(timeString)
                .font(.system(size: 15, weight: .semibold).monospacedDigit())
                .tracking(-0.4)
                .foregroundColor(Color.mbText1(scheme))
            Text("\(durationMinutes) minutes · \(event.startDate.formatted(.dateTime.weekday(.wide).month().day()))")
                .font(.system(size: 12))
                .foregroundColor(Color.mbText2(scheme))
        }
    }

    private var whereContent: some View {
        HStack(alignment: .top, spacing: 8) {
            ServiceMarkView(service: event.meetingLink?.service, size: 26)
            VStack(alignment: .leading, spacing: 1) {
                if let location = event.location {
                    Text(location)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.mbText1(scheme))
                }
                if let link = event.meetingLink {
                    Text(link.url.host ?? link.url.absoluteString)
                        .font(.system(size: 11.5))
                        .foregroundColor(Color.mbText2(scheme))
                        .lineLimit(1)
                }
            }
            Spacer()
            Button("Copy") {
                if let link = event.meetingLink {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(link.url.absoluteString, forType: .string)
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 9).padding(.vertical, 3)
            .background(Color.mbChip(scheme))
            .clipShape(Capsule())
        }
    }

    private func organizerContent(_ organizer: MBEventOrganizer) -> some View {
        HStack(spacing: 8) {
            AvatarView(name: organizer.name, idx: 3, size: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(organizer.name)
                    .font(.system(size: 13))
                    .foregroundColor(Color.mbText1(scheme))
                if let email = organizer.email {
                    Text("\(email) · Organizer")
                        .font(.system(size: 11.5))
                        .foregroundColor(Color.mbText2(scheme))
                }
            }
        }
    }

    private var attendeesContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                AvatarStackView(people: event.attendees.map(\.name), max: 5, size: 22)
                Text("\(event.attendees.count) attendees")
                    .font(.system(size: 12))
                    .foregroundColor(Color.mbText2(scheme))
            }
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(event.attendees.prefix(3).enumerated()), id: \.offset) { _, attendee in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(statusColor(for: attendee.status))
                            .frame(width: 6, height: 6)
                        Text(attendee.isCurrentUser ? "\(attendee.name) (you)" : attendee.name)
                            .font(.system(size: 12.5))
                            .foregroundColor(Color.mbText1(scheme))
                    }
                }
            }
            if event.attendees.count > 3 {
                Text("Show all \(event.attendees.count)")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 9).padding(.vertical, 3)
                    .background(Color.mbChip(scheme))
                    .clipShape(Capsule())
                    .foregroundColor(Color.mbText2(scheme))
            }
        }
    }

    private func statusColor(for status: MBEventAttendeeStatus) -> Color {
        switch status {
        case .accepted: return .green
        case .tentative: return .orange
        default: return .gray
        }
    }

    private func notesContent(_ notes: String) -> some View {
        Text(notes)
            .font(.system(size: 12.5))
            .foregroundColor(Color.mbText1(scheme))
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionsContent: some View {
        VStack(spacing: 1) {
            DetailActionRow(icon: "video.fill", label: "Join meeting") { event.openMeeting() }
            DetailActionRow(icon: "doc.on.clipboard", label: "Copy meeting link") {
                if let link = event.meetingLink {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(link.url.absoluteString, forType: .string)
                }
            }
            DetailActionRow(icon: "calendar", label: "Open in Calendar") {
                if let url = URL(string: "ical://ekevent/\(event.id)") {
                    url.openInDefaultBrowser()
                }
            }
            DetailActionRow(icon: "envelope", label: "Email attendees") { event.emailAttendees() }
        }
    }
}

// MARK: - Detail section wrapper

private struct DetailSection<Content: View>: View {
    let label: String
    let content: Content
    @Environment(\.colorScheme) private var scheme

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.6)
                .foregroundColor(Color.mbText3(scheme))
            content
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
}

// MARK: - Detail action row

private struct DetailActionRow: View {
    let icon: String
    let label: String
    var action: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color.mbText2(scheme))
                .frame(width: 16)
            Text(label)
                .font(.system(size: 12.5))
                .foregroundColor(Color.mbText1(scheme))
            Spacer()
        }
        .padding(.vertical, 6).padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(hovered ? Color.mbHover(scheme) : .clear)
        )
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
        .onTapGesture { action?() }
    }
}

