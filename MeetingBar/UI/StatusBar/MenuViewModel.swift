// MenuViewModel.swift — Observable state that bridges AppKit → SwiftUI for the menu panel
import SwiftUI
import Defaults

// Status bar label state — computed by StatusBarItemController.updateTitle()
// and rendered by StatusBarLabelView in the MenuBarExtra label closure.
struct StatusBarLabel {
    var icon: NSImage? = nil
    var title: String = ""
    var time: String = ""
    var timeUnderTitle: Bool = false
}

@MainActor
final class MenuViewModel: ObservableObject {
    @Published var events: [MBEvent] = []
    @Published var selectedEventId: String? = nil
    @Published var statusBarLabel = StatusBarLabel()

    // Density and notes-preview come from Defaults; observe them for live updates.
    var density: DensityPreset {
        switch Defaults[.menuDensity] {
        case .compact: return .compact
        case .comfortable: return .comfortable
        case .spacious: return .spacious
        }
    }
    var showNotes: Bool { Defaults[.showNotesInMenu] }

    // Callbacks set by StatusBarItemController so the SwiftUI layer can trigger AppKit actions.
    var onJoinNext: (() -> Void)?
    var onCreateMeeting: (() -> Void)?
    var onOpenPreferences: (() -> Void)?
    var onReload: (() -> Void)?

    var selectedEvent: MBEvent? {
        guard let id = selectedEventId else { return nil }
        return events.first { $0.id == id }
    }

    func joinNextMeeting() { onJoinNext?() }
    func createMeeting() { onCreateMeeting?() }
    func openPreferences() { onOpenPreferences?() }
    func reload() { onReload?() }
}

// MARK: - Defaults keys for new preferences

extension Defaults.Keys {
    // Density
    static let menuDensity = Key<MenuDensityOption>("menuDensity", default: .comfortable)
    // Show notes preview in menu rows
    static let showNotesInMenu = Key<Bool>("showNotesInMenu", default: true)
}

enum MenuDensityOption: String, Defaults.Serializable {
    case compact, comfortable, spacious
}
