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
    let tint: Color

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .fill(AppTheme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                            .stroke(tint.opacity(0.14), lineWidth: 1)
                    }
            }
    }
}

extension View {
    func appCard(tint: Color = AppTheme.accent) -> some View {
        modifier(AppCardModifier(tint: tint))
    }
}
