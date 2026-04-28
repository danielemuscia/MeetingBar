// MenuPanelController.swift — Manages the NSPanel that hosts the custom SwiftUI menu
import Cocoa
import SwiftUI
import Combine

@MainActor
final class MenuPanelController {
    private var panel: NSPanel?
    private(set) var viewModel: MenuViewModel
    private var globalMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    // Base width: menu (380) + 8 padding each side
    private let menuWidth: CGFloat = 396
    // Extra width when detail is open: detail (320) + gap (10)
    private let detailExtraWidth: CGFloat = 330
    private let panelHeight: CGFloat = 680

    init() {
        viewModel = MenuViewModel()

        // Reposition when detail opens/closes (panel width changes)
        viewModel.$selectedEventId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.repositionPanel() }
            .store(in: &cancellables)
    }

    // MARK: - Public API

    var isVisible: Bool { panel?.isVisible ?? false }

    func toggle(relativeTo button: NSStatusBarButton) {
        if isVisible { hide() } else { show(relativeTo: button) }
    }

    func show(relativeTo button: NSStatusBarButton) {
        if panel == nil { buildPanel() }
        guard let panel else { return }
        positionPanel(panel, relativeTo: button)
        panel.orderFront(nil)
        installGlobalDismiss()
    }

    func hide() {
        panel?.orderOut(nil)
        viewModel.selectedEventId = nil
        removeGlobalDismiss()
    }

    // MARK: - Panel construction

    private func buildPanel() {
        let root = MenuPanelView(viewModel: viewModel)
        let hosting = NSHostingView(rootView: root)

        let newPanel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        newPanel.level = .popUpMenu
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = false  // SwiftUI draws its own shadows
        newPanel.isMovable = false
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        newPanel.contentView = hosting
        self.panel = newPanel
    }

    // MARK: - Positioning

    private func positionPanel(_ panel: NSPanel, relativeTo button: NSStatusBarButton) {
        guard let buttonWindow = button.window else { return }
        let buttonRect = buttonWindow.convertToScreen(button.frame)
        let width = currentPanelWidth
        let x = buttonRect.maxX - width
        let y = buttonRect.minY - panelHeight
        panel.setFrame(NSRect(x: x, y: y, width: width, height: panelHeight), display: true)
    }

    private func repositionPanel() {
        guard let panel, panel.isVisible else { return }
        let newWidth = currentPanelWidth
        let newFrame = NSRect(
            x: panel.frame.maxX - newWidth,
            y: panel.frame.origin.y,
            width: newWidth,
            height: panel.frame.height
        )
        panel.animator().setFrame(newFrame, display: true)
    }

    private var currentPanelWidth: CGFloat {
        viewModel.selectedEventId != nil ? menuWidth + detailExtraWidth : menuWidth
    }

    // MARK: - Global dismiss on outside click

    private func installGlobalDismiss() {
        removeGlobalDismiss()
        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { _ in
            Task { @MainActor [weak self] in
                guard let self, let panel = self.panel else { return }
                if !panel.frame.contains(NSEvent.mouseLocation) {
                    self.hide()
                }
            }
        }
    }

    private func removeGlobalDismiss() {
        if let m = globalMonitor {
            NSEvent.removeMonitor(m)
            globalMonitor = nil
        }
    }
}
