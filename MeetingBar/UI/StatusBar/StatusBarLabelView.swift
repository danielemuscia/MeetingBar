// StatusBarLabelView.swift — SwiftUI view for the MenuBarExtra status bar label.
// Mirrors the visual output of the old StatusBarItemController.updateTitle()
// which set an attributed string on NSStatusItem.button directly.
import SwiftUI

struct StatusBarLabelView: View {
    @ObservedObject var model: MenuViewModel

    var body: some View {
        HStack(spacing: 4) {
            if let icon = model.statusBarLabel.icon {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }
            if !model.statusBarLabel.title.isEmpty {
                if model.statusBarLabel.timeUnderTitle {
                    VStack(alignment: .leading, spacing: -1) {
                        Text(model.statusBarLabel.title)
                            .font(.system(size: 12))
                            .lineLimit(1)
                        Text(model.statusBarLabel.time)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                } else {
                    let full = model.statusBarLabel.time.isEmpty
                        ? model.statusBarLabel.title
                        : model.statusBarLabel.title + " " + model.statusBarLabel.time
                    Text(full)
                        .font(.system(size: 13))
                        .lineLimit(1)
                }
            }
        }
    }
}
