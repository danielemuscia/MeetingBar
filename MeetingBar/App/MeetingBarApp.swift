// MeetingBarApp.swift — SwiftUI App entry point.
// Uses MenuBarExtra(.window) which gives native vibrancy, shadow, and rounded
// corners for free — exactly what NSPopover / Control Center panels use.
// The complex status-bar attributed title is rendered via StatusBarLabelView.
import SwiftUI

@main
struct MeetingBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuPanelView(viewModel: appDelegate.menuModel)
        } label: {
            StatusBarLabelView(model: appDelegate.menuModel)
        }
        .menuBarExtraStyle(.window)
    }
}
