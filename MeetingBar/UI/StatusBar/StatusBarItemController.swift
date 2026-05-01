//
//  StatusBarItemController.swift
//  MeetingBar
//
//  Created by Andrii Leitsius on 12.06.2020.
//  Copyright © 2020 Andrii Leitsius. All rights reserved.
//
//  Refactored: NSStatusItem and NSPanel removed. The status bar item and its
//  native panel are now owned by MenuBarExtra in MeetingBarApp. This class
//  retains all non-UI responsibilities: event storage, title-state computation,
//  keyboard shortcuts, and action dispatch.
//

import Cocoa
import Combine
import Defaults
import KeyboardShortcuts
import SwiftUI

enum MenuStyleConstants {
    static let defaultFontSize: CGFloat = 13
    static let runningIconName = "running_icon"
    static let appIconName = "AppIcon"
    static let calendarCheckmarkIconName = "iconCalendarCheckmark"
    static let calendarIconName = "iconCalendar"
    static let iconSize: NSSize = .init(width: 16, height: 16)
}

@MainActor
final class StatusBarItemController {
    var events: [MBEvent] = [] {
        didSet { menuModel.events = events }
    }

    private let menuModel: MenuViewModel
    private var cancellables = Set<AnyCancellable>()

    let installationDate = getInstallationDate()
    weak var appdelegate: AppDelegate!

    init(menuModel: MenuViewModel) {
        self.menuModel = menuModel
        setupDefaultsObservers()
        setupKeyboardShortcuts()
    }

    private func setupDefaultsObservers() {
        Defaults.publisher(
            keys: .statusbarEventTitleLength, .eventTimeFormat,
            .eventTitleIconFormat, .showEventMaxTimeUntilEventThreshold,
            .showEventMaxTimeUntilEventEnabled, .showEventDetails,
            .shortenEventTitle, .menuEventTitleLength,
            .showEventEndTime, .showMeetingServiceIcon,
            .timeFormat, .bookmarks, .eventTitleFormat,
            .personalEventsAppereance, .pastEventsAppereance,
            .declinedEventsAppereance, .ongoingEventVisibility,
            .showTimelineInMenu,
            options: []
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in self?.updateTitle() }
        .store(in: &cancellables)

        Defaults.publisher(.hideMeetingTitle, options: [])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateTitle()
                removePendingNotificationRequests(withID: notificationIDs.event_starts)
                removePendingNotificationRequests(withID: notificationIDs.event_ends)
                if let nextEvent = self?.events.nextEvent() {
                    Task { await scheduleEventNotification(nextEvent) }
                }
            }
            .store(in: &cancellables)

        Defaults.publisher(.preferredLanguage, options: [.initial])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                if I18N.instance.changeLanguage(to: change.newValue) {
                    self?.updateTitle()
                }
            }
            .store(in: &cancellables)

        Defaults.publisher(.joinEventNotification, options: [])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                if change.newValue == true {
                    if let nextEvent = self?.events.nextEvent() {
                        Task { await scheduleEventNotification(nextEvent) }
                    }
                } else {
                    removePendingNotificationRequests(withID: notificationIDs.event_starts)
                }
            }
            .store(in: &cancellables)
    }

    private func setupKeyboardShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .createMeetingShortcut, action: createMeeting)
        KeyboardShortcuts.onKeyUp(for: .joinEventShortcut) {
            Task { @MainActor in self.joinNextMeeting() }
        }
        KeyboardShortcuts.onKeyUp(for: .openClipboardShortcut, action: openLinkFromClipboard)
        KeyboardShortcuts.onKeyUp(for: .toggleMeetingTitleVisibilityShortcut) {
            Defaults[.hideMeetingTitle].toggle()
        }
    }

    func setAppDelegate(appdelegate: AppDelegate) {
        self.appdelegate = appdelegate
        menuModel.onJoinNext = { [weak self] in self?.joinNextMeeting() }
        menuModel.onCreateMeeting = { createMeeting() }
        menuModel.onOpenPreferences = { [weak appdelegate] in
            Task { @MainActor in appdelegate?.openPreferencesWindow(nil) }
        }
        menuModel.onReload = { [weak appdelegate] in
            Task { try await appdelegate?.eventManager.refreshSources() }
        }
    }

    // MARK: - Title state

    // Computes the status bar label state from `events` + Defaults and writes
    // it to menuModel.statusBarLabel. StatusBarLabelView observes that and redraws.
    func updateTitle() {
        var label = StatusBarLabel()

        guard !Defaults[.selectedCalendarIDs].isEmpty else {
            label.icon = NSImage(named: MenuStyleConstants.appIconName)
            menuModel.statusBarLabel = label
            return
        }

        let nextEvent = events.nextEvent()
        let nextEventState: NextEventState = {
            guard let nextEvent else { return .none }
            guard Defaults[.showEventMaxTimeUntilEventEnabled] else { return .nextEvent(nextEvent) }
            let timeUntilStart = nextEvent.startDate.timeIntervalSinceNow
            let threshold = TimeInterval(Defaults[.showEventMaxTimeUntilEventThreshold] * 60)
            return timeUntilStart < threshold ? .nextEvent(nextEvent) : .afterThreshold(nextEvent)
        }()

        switch nextEventState {
        case .none:
            switch Defaults[.eventTitleIconFormat] {
            case .appicon:
                label.icon = NSImage(named: Defaults[.eventTitleIconFormat].rawValue)
            default:
                label.icon = NSImage(named: MenuStyleConstants.calendarCheckmarkIconName)
            }

        case .afterThreshold:
            switch Defaults[.eventTitleIconFormat] {
            case .appicon:
                label.icon = NSImage(named: Defaults[.eventTitleIconFormat].rawValue)
            default:
                label.icon = NSImage(named: MenuStyleConstants.calendarIconName)
            }

        case let .nextEvent(event):
            let (title, time) = createEventStatusString(
                title: event.title,
                startDate: event.startDate,
                endDate: event.endDate
            )

            if Defaults[.eventTitleIconFormat] != .none {
                let image: NSImage
                if Defaults[.eventTitleIconFormat] == .eventtype {
                    image = getIconForMeetingService(event.meetingLink?.service)
                } else {
                    image = NSImage(named: Defaults[.eventTitleIconFormat].rawValue) ?? NSImage()
                }
                if image.name() != "no_online_session" {
                    label.icon = image
                }
            }

            label.title = Defaults[.hideMeetingTitle]
                ? "general_meeting".loco()
                : title

            switch Defaults[.eventTimeFormat] {
            case .show:
                label.time = time
                label.timeUnderTitle = false
            case .show_under_title:
                label.time = time
                label.timeUnderTitle = true
            default:
                break
            }
        }

        menuModel.statusBarLabel = label
    }

    // Kept for compatibility — SwiftUI menu is reactive, so this is a no-op.
    func updateMenu() {}

    // MARK: - Actions

    @objc func joinNextMeeting() {
        if let nextEvent = events.nextEvent() {
            nextEvent.openMeeting()
        } else {
            sendNotification("next_meeting_empty_title".loco(), "next_meeting_empty_message".loco())
        }
    }

    @objc func createMeetingAction() { createMeeting() }

    @objc func dismissNextMeetingAction() {
        if let nextEvent = events.nextEvent() {
            let dismissedEvent = ProcessedEvent(
                id: nextEvent.id,
                lastModifiedDate: nextEvent.lastModifiedDate,
                eventEndDate: nextEvent.endDate
            )
            Defaults[.dismissedEvents].append(dismissedEvent)
            sendNotification(
                "notification_next_meeting_dismissed_title".loco(nextEvent.title),
                "notification_next_meeting_dismissed_message".loco()
            )
            updateTitle()
        }
    }

    @objc func undismissMeetingsActions() {
        Defaults[.dismissedEvents] = []
        sendNotification(
            "notification_all_dismissals_removed_title".loco(),
            "notification_all_dismissals_removed_message".loco()
        )
        updateTitle()
    }

    @objc func openLinkFromClipboardAction() { openLinkFromClipboard() }

    @objc func toggleMeetingTitleVisibility() { Defaults[.hideMeetingTitle].toggle() }

    @objc func rateApp() { Links.rateAppInAppStore.openInDefaultBrowser() }

    @objc func joinBookmark(sender: NSMenuItem) {
        if let bookmark = sender.representedObject as? Bookmark {
            openMeetingURL(bookmark.service, bookmark.url, nil)
        }
    }

    @objc func clickOnEvent(sender: NSMenuItem) {
        if let event = sender.representedObject as? MBEvent { event.openMeeting() }
    }

    @objc func openEventInCalendar(sender: NSMenuItem) {
        if let identifier = sender.representedObject as? String,
           let url = URL(string: "ical://ekevent/\(identifier)") {
            url.openInDefaultBrowser()
        }
    }

    @objc func handleManualRefresh() {
        Task {
            do { try await appdelegate.eventManager.refreshSources() }
            catch { NSLog("Refresh failed: \(error)") }
        }
    }

    @objc func dismissEvent(sender: NSMenuItem) {
        if let event = sender.representedObject as? MBEvent { dismiss(event: event) }
    }

    func dismiss(event: MBEvent) {
        let dismissedEvent = ProcessedEvent(
            id: event.id,
            lastModifiedDate: event.lastModifiedDate,
            eventEndDate: event.endDate
        )
        Defaults[.dismissedEvents].append(dismissedEvent)
        updateTitle()
    }

    @objc func undismissEvent(sender: NSMenuItem) {
        if let event = sender.representedObject as? MBEvent {
            Defaults[.dismissedEvents] = Defaults[.dismissedEvents].filter { $0.id != event.id }
            updateTitle()
        }
    }

    @objc func copyEventMeetingLink(sender: NSMenuItem) {
        if let event = sender.representedObject as? MBEvent {
            if let meetingLink = event.meetingLink {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(meetingLink.url.absoluteString, forType: .string)
            } else {
                sendNotification(
                    "status_bar_error_link_missed_title".loco(event.title),
                    "status_bar_error_link_missed_message".loco()
                )
            }
        }
    }

    @objc func emailAttendees(sender: NSMenuItem) {
        if let event = sender.representedObject as? MBEvent { event.emailAttendees() }
    }

    @objc func openEventInFantastical(sender: NSMenuItem) {
        if let event = sender.representedObject as? MBEvent {
            openInFantastical(startDate: event.startDate, title: event.title)
        }
    }
}

// MARK: - Helpers (module-level, used by updateTitle and AppDelegate)

func shortenTitle(title: String?, offset: Int) -> String {
    var eventTitle = String(title ?? "status_bar_no_title".loco())
        .trimmingCharacters(in: TitleTruncationRules.excludeAtEnds)
    if eventTitle.count > offset {
        let index = eventTitle.index(eventTitle.startIndex, offsetBy: offset - 1)
        eventTitle = String(eventTitle[...index])
            .trimmingCharacters(in: TitleTruncationRules.excludeAtEnds) + "..."
    }
    return eventTitle
}

func createEventStatusString(title: String, startDate: Date, endDate: Date) -> (String, String) {
    var eventTitle: String
    switch Defaults[.eventTitleFormat] {
    case .show:
        eventTitle = Defaults[.hideMeetingTitle]
            ? "general_meeting".loco()
            : shortenTitle(title: title, offset: Defaults[.statusbarEventTitleLength])
                .replacingOccurrences(of: "\n", with: " ")
    case .dot:  eventTitle = "•"
    case .none: eventTitle = ""
    }

    var calendar = Calendar.current
    calendar.locale = I18N.instance.locale
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .abbreviated
    formatter.allowedUnits = [.minute, .hour, .day]
    formatter.calendar = calendar

    let now = Date()
    let isActive = startDate <= now && endDate > now
    let eventDate = isActive ? endDate : startDate
    let formattedTimeLeft = formatter.string(from: Date().addingTimeInterval(-60), to: eventDate) ?? ""
    let eventTime = isActive
        ? "status_bar_event_status_now".loco(formattedTimeLeft)
        : "status_bar_event_status_in".loco(formattedTimeLeft)

    return (eventTitle, eventTime)
}

enum NextEventState {
    case none
    case afterThreshold(MBEvent)
    case nextEvent(MBEvent)
}
