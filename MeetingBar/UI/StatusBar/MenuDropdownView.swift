// MenuDropdownView.swift
// NO animations, NO withAnimation. State changes are instant.
import SwiftUI
import Defaults

struct MenuDropdownView: View {
    let events: [MBEvent]
    var density: DensityPreset = .comfortable
    var showNotes: Bool = true
    @Binding var selectedEventId: String?

    var onJoinNext:      () -> Void
    var onCreateMeeting: () -> Void
    var onPreferences:   () -> Void
    var onQuit:          () -> Void
    var onReload:        () -> Void

    @Environment(\.colorScheme) private var scheme

    // MARK: - Derived lists

    private var nowEvents: [MBEvent] {
        let now = Date()
        return events.filter { $0.startDate <= now && $0.endDate > now }
                     .sorted { $0.startDate < $1.startDate }
    }

    private var upcomingEvents: [MBEvent] {
        let now = Date()
        return events.filter { $0.startDate > now && visible($0) }
                     .sorted { $0.startDate < $1.startDate }
    }

    private var pastEvents: [MBEvent] {
        let now = Date()
        return events.filter { $0.endDate <= now && visible($0) }
                     .sorted { $0.startDate < $1.startDate }
    }

    private func visible(_ e: MBEvent) -> Bool {
        if (e.participationStatus == .declined || e.status == .canceled),
           Defaults[.declinedEventsAppereance] == .hide { return false }
        if e.endDate < Date(), Defaults[.pastEventsAppereance] == .hide { return false }
        if e.attendees.isEmpty, Defaults[.personalEventsAppereance] == .hide { return false }
        return true
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            eventsSection
            if !Defaults[.bookmarks].isEmpty {
                MenuSeparator()
                bookmarksSection
            }
            MenuSeparator()
            ActionRowView(icon: "video",  label: "Join next event meeting", kbd: "⌘K", action: onJoinNext)
            ActionRowView(icon: "plus",   label: "Create meeting",           kbd: "⌘L", action: onCreateMeeting)
            MenuSeparator()
            ActionRowView(icon: "gear",   label: "Preferences…",             kbd: "⌘,", action: onPreferences)
            ActionRowView(icon: "power",  label: "Quit MeetingBar",          kbd: "⌘Q", action: onQuit)
            Spacer(minLength: 6)
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text(Date().formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.mbText1(scheme))
            Spacer()
            IconButtonView(systemName: "arrow.clockwise", action: onReload)
        }
        .padding(.horizontal, 10)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    // MARK: - Events

    @ViewBuilder
    private var eventsSection: some View {
        if Defaults[.selectedCalendarIDs].isEmpty {
            EmptyStateView(kind: .noCalendarConnected, primaryAction: ("Open Preferences", onPreferences))
        } else {
            if nowEvents.count >= 2 {
                ConflictHeroView(
                    events: nowEvents,
                    density: density,
                    selectedEventId: selectedEventId,
                    onSelect: { toggle($0) }
                )
            } else if let now = nowEvents.first {
                HeroCardView(
                    event: now,
                    density: density,
                    selected: selectedEventId == now.id,
                    onSelect: { toggle(now.id) }
                )
            }

            if !upcomingEvents.isEmpty {
                SectionHeaderView(
                    title: "Up next",
                    sub: "\(upcomingEvents.count) \(upcomingEvents.count == 1 ? "event" : "events")"
                )
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

            if nowEvents.isEmpty && upcomingEvents.isEmpty && pastEvents.isEmpty {
                EmptyStateView(kind: .allClear)
            }
        }
    }

    // MARK: - Bookmarks

    private var bookmarksSection: some View {
        Group {
            SectionHeaderView(title: "Bookmarks")
            ForEach(Defaults[.bookmarks], id: \.name) { bookmark in
                ActionRowView(icon: "bookmark", label: bookmark.name) {
                    openMeetingURL(bookmark.service, bookmark.url, nil)
                }
            }
        }
    }

    // MARK: - Toggle

    private func toggle(_ id: String) {
        // No withAnimation — animating the HStack layout change (window resize)
        // causes the main menu content to shake. The detail panel animates its
        // own content via .onAppear instead.
        selectedEventId = (selectedEventId == id) ? nil : id
    }
}
