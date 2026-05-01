// MenuPanelView.swift
// Layout contract:
//   • .frame(height: 640) on the HStack is the ONLY height constraint.
//   • .frame(width: 380) on the main ScrollView is the ONLY width for that column.
//   • DetailPanelView sizes itself to width 320 internally.
//   • NO animations, NO .transition(), NO withAnimation anywhere in this file.
import SwiftUI

struct MenuPanelView: View {
    @ObservedObject var viewModel: MenuViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if let event = viewModel.selectedEvent {
                DetailPanelView(
                    event: event,
                    onClose: { viewModel.selectedEventId = nil }
                )
                Divider()
            }

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
        }
        .frame(height: 640)
    }
}
