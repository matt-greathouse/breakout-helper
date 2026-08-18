//
//  AppTheme.swift
//  Breakout Helper
//

import SwiftUI

enum AppTheme {
    static let accent = Color.indigo
    static let pageBackground = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let subtleSurface = Color.indigo.opacity(0.08)
    static let cardCornerRadius: CGFloat = 20
    static let contentWidth: CGFloat = 680
}

private struct AppCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .fill(AppTheme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                            .stroke(AppTheme.accent.opacity(0.14), lineWidth: 1)
                    }
            }
    }
}

extension View {
    func appCard() -> some View {
        modifier(AppCardModifier())
    }
}

struct InitialBadge: View {
    let name: String
    let size: CGFloat

    init(_ name: String, size: CGFloat = 28) {
        self.name = name
        self.size = size
    }

    var body: some View {
        Text(String(name.prefix(1)).uppercased())
            .font(.caption.weight(.bold))
            .foregroundStyle(AppTheme.accent)
            .frame(width: size, height: size)
            .background(AppTheme.subtleSurface, in: Circle())
            .accessibilityHidden(true)
    }
}
