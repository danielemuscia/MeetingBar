// MenuPanelView.swift
// Layout contract:
//   • Window is always 380×640 — it never resizes. No blink from compositor.
//   • The detail panel slides in as a ZStack overlay — no layout change.
//   • ONE .animation(value:) on the ZStack drives the transition.
//   • NO withAnimation at call sites, NO competing animation modifiers.
import SwiftUI

struct MenuPanelView: View {
    @ObservedObject var viewModel: MenuViewModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Main menu — always rendered at full size, never moves.
            ScrollView {
                MenuDropdownView(
                    events:          viewModel.events,
                    density:         viewModel.density,
                    showNotes:       viewModel.showNotes,
                    selectedEventId: $viewModel.selectedEventId,
                    onJoinNext:      { viewModel.joinNextMeeting() },
                    onCreateMeeting: { viewModel.createMeeting() },
                    onPreferences:   { viewModel.openPreferences() },
                    onQuit:          { NSApp.terminate(nil) },
                    onReload:        { viewModel.reload() }
                )
            }
            .frame(width: 380)
            .scrollContentBackground(.hidden)

            // Detail panel — overlays the main menu; slides in/out from the left.
            if let event = viewModel.selectedEvent {
                DetailPanelView(
                    event: event,
                    onClose: { viewModel.selectedEventId = nil }
                )
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .frame(width: 380, height: 640)
        .animation(.easeOut(duration: 0.22), value: viewModel.selectedEventId != nil)
        // Reset the detail selection whenever the panel is dismissed so the next
        // open always starts at the main menu view.
        .onDisappear { viewModel.selectedEventId = nil }
    }
}
