import SwiftUI
#if os(macOS)
import AppKit
#endif

enum AppTheme {
    static let canvasTop = Color(red: 0.07, green: 0.09, blue: 0.14)
    static let canvasBottom = Color(red: 0.02, green: 0.03, blue: 0.06)
    static let sidebarTop = Color(red: 0.08, green: 0.10, blue: 0.15)
    static let sidebarBottom = Color(red: 0.04, green: 0.05, blue: 0.09)
    static let highlight = Color(red: 0.40, green: 0.78, blue: 0.96)
    static let highlightSecondary = Color(red: 0.20, green: 0.82, blue: 0.66)
    static let cardFill = Color.white.opacity(0.14)
    static let cardStroke = Color.white.opacity(0.18)
}

struct CardRowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowSeparator(.hidden)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                    )
                    .padding(.vertical, 4)
            )
    }
}

extension View {
    func cardRow() -> some View {
        modifier(CardRowStyle())
    }

    func darkCanvas() -> some View {
        background {
            ZStack {
                LinearGradient(
                    colors: [AppTheme.canvasTop, AppTheme.canvasBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(AppTheme.highlight.opacity(0.16))
                    .frame(width: 280)
                    .offset(x: -140, y: -260)

                Circle()
                    .fill(AppTheme.highlightSecondary.opacity(0.12))
                    .frame(width: 320)
                    .offset(x: 180, y: 300)
            }
            .ignoresSafeArea()
        }
    }

    func sidebarCanvas() -> some View {
        background {
            LinearGradient(
                colors: [AppTheme.sidebarTop, AppTheme.sidebarBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    func hoverPointer() -> some View {
#if os(macOS)
        onHover { isHovering in
            if isHovering {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
#else
        self
#endif
    }
}

extension DocumentCategory {
    var symbolName: String {
        switch self {
        case .invoices:
            return "doc.text"
        case .receipts:
            return "tray.full"
        case .bankReport:
            return "building.columns"
        }
    }
}
