// MenuPanelView.swift — Root SwiftUI view rendered inside the NSPanel
// Layout: [DetailPanelView?] [MenuDropdownView] side by side, detail on left
import SwiftUI

struct MenuPanelView: View {
    @ObservedObject var viewModel: MenuViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Detail panel slides in from the right when an event is selected
            if let event = viewModel.selectedEvent {
                DetailPanelView(event: event) {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                        viewModel.selectedEventId = nil
                    }
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    )
                )
            }

            // Main menu — always visible
            menuPanel
        }
        .animation(.spring(response: 0.24, dampingFraction: 0.82), value: viewModel.selectedEventId)
        .padding(8) // room for shadows to breathe
    }

    // MARK: - Menu panel

    @ViewBuilder
    private var menuPanel: some View {
        let content = MenuDropdownView(
            events: viewModel.events,
            density: viewModel.density,
            showNotes: viewModel.showNotes,
            selectedEventId: $viewModel.selectedEventId,
            onJoinNext: { viewModel.joinNextMeeting() },
            onCreateMeeting: { viewModel.createMeeting() },
            onPreferences: { viewModel.openPreferences() },
            onQuit: { NSApp.terminate(nil) }
        )

        if #available(macOS 13.0, *) {
            ScrollView {
                content
            }
            .scrollContentBackground(.hidden)
            .frame(width: 380)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
            .shadow(color: .black.opacity(0.22), radius: 35, x: 0, y: 20)
        } else {
            ScrollView {
                content
            }
            .frame(width: 380)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
            .shadow(color: .black.opacity(0.22), radius: 35, x: 0, y: 20)
        }
    }
}
