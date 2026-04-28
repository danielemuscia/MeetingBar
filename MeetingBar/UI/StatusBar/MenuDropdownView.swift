// MenuDropdownView.swift — Main menu dropdown content view
import SwiftUI
import Defaults

struct MenuDropdownView: View {
    let events: [MBEvent]
    var density: DensityPreset = .comfortable
    var showNotes: Bool = true
    @Binding var selectedEventId: String?

    // Callbacks for actions that need to cross the SwiftUI/AppKit boundary
    var onJoinNext: () -> Void
    var onCreateMeeting: () -> Void
    var onPreferences: () -> Void
    var onQuit: () -> Void

    @Environment(\.colorScheme) private var scheme

    // MARK: - Derived event lists

    private var nowEvent: MBEvent? {
        let now = Date()
        return events.first { $0.startDate <= now && $0.endDate > now }
    }

    private var upcomingEvents: [MBEvent] {
        let now = Date()
        return events
            .filter { $0.startDate > now && visibleByPrefs($0) }
            .sorted { $0.startDate < $1.startDate }
    }

    private var pastEvents: [MBEvent] {
        let now = Date()
        return events
            .filter { $0.endDate <= now && visibleByPrefs($0) }
            .sorted { $0.startDate < $1.startDate }
    }

    private func visibleByPrefs(_ event: MBEvent) -> Bool {
        if (event.participationStatus == .declined || event.status == .canceled),
           Defaults[.declinedEventsAppereance] == .hide { return false }
        if event.endDate < Date(), Defaults[.pastEventsAppereance] == .hide { return false }
        if event.attendees.isEmpty, Defaults[.personalEventsAppereance] == .hide { return false }
        return true
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            if let now = nowEvent {
                HeroCardView(
                    event: now,
                    density: density,
                    selected: selectedEventId == now.id,
                    onSelect: { toggle(now.id) }
                )
            }
            if !upcomingEvents.isEmpty {
                SectionHeaderView(title: "Up next", sub: "\(upcomingEvents.count) events")
                ForEach(upcomingEvents) { event in
                    EventRowView(
                        event: event,
                        density: density,
                        showNotes: showNotes,
                        selected: selectedEventId == event.id,
                        onSelect: { toggle(event.id) }
                    )
                }
            }
            if !pastEvents.isEmpty {
                Spacer().frame(height: 6)
                SectionHeaderView(title: "Earlier today")
                ForEach(pastEvents) { event in
                    EventRowView(
                        event: event,
                        density: density,
                        showNotes: showNotes,
                        selected: selectedEventId == event.id,
                        onSelect: { toggle(event.id) }
                    )
                }
            }
            MenuSeparator()
            bookmarksSection
            MenuSeparator()
            ActionRowView(icon: "video", label: "Join next event meeting", kbd: "⌘K",
                          action: onJoinNext)
            ActionRowView(icon: "plus", label: "Create meeting", kbd: "⌘L",
                          action: onCreateMeeting)
            MenuSeparator()
            ActionRowView(icon: "gear", label: "Preferences…", kbd: "⌘,",
                          action: onPreferences)
            ActionRowView(icon: "power", label: "Quit MeetingBar", kbd: "⌘Q", danger: true,
                          action: onQuit)
            Spacer(minLength: 6)
        }
    }

    // MARK: - Sub-sections

    private var headerRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Today")
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(-0.4)
                    .foregroundColor(Color.mbText1(scheme))
                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.system(size: 12))
                    .foregroundColor(Color.mbText2(scheme))
            }
            Spacer()
            HStack(spacing: 4) {
                IconButtonView(systemName: "magnifyingglass") {}
                IconButtonView(systemName: "calendar") {}
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private var bookmarksSection: some View {
        let bookmarks = Defaults[.bookmarks]
        return Group {
            SectionHeaderView(title: "Bookmarks")
            if bookmarks.isEmpty {
                Text("No bookmarks")
                    .font(.system(size: 12))
                    .foregroundColor(Color.mbText3(scheme))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
            } else {
                ForEach(bookmarks, id: \.name) { bookmark in
                    ActionRowView(icon: "bookmark", label: bookmark.name) {
                        openMeetingURL(bookmark.service, bookmark.url, nil)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func toggle(_ id: String) {
        selectedEventId = (selectedEventId == id) ? nil : id
    }
}
