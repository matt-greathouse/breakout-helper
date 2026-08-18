import SwiftUI
import UIKit

struct MainView: View {
    @EnvironmentObject private var store: BreakoutStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("minGroupSize.v1") private var minGroupSize = 3

    let onOpenSettings: () -> Void

    @State private var isGenerating = false
    @State private var revealID = UUID()

    init(onOpenSettings: @escaping () -> Void = {}) {
        self.onOpenSettings = onOpenSettings
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if store.students.isEmpty && store.guests.isEmpty {
                    EmptyStateView(onOpenSettings: onOpenSettings)
                } else {
                    summaryCard
                    groupSizeCard
                    breakoutButton
                    groupsContent
                }
            }
            .frame(maxWidth: AppTheme.contentWidth)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .navigationTitle("Breakout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.resetIfNeeded() }
    }

    private var summaryCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.3.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 48, height: 48)
                .background(AppTheme.subtleSurface, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("Ready to group")
                    .font(.headline)
                Text("\(store.activeParticipants.count) active of \(store.students.count + store.guests.count) participants")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .appCard()
        .accessibilityElement(children: .combine)
    }

    private var groupSizeCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Minimum group size")
                    .font(.headline)
                Text("Keep at least \(minGroupSize) people together")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Stepper("Minimum group size", value: $minGroupSize, in: 2...12)
                .labelsHidden()
                .accessibilityValue("\(minGroupSize) people")
        }
        .padding(16)
        .appCard()
    }

    private var breakoutButton: some View {
        Button(action: breakout) {
            HStack(spacing: 10) {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                    Text("Shuffling groups…")
                } else {
                    Image(systemName: "shuffle")
                        .symbolEffect(.bounce, value: isGenerating)
                    Text(store.groups.isEmpty ? "Break Out" : "Break Out Again")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
        }
        .buttonStyle(BreakoutButtonStyle())
        .disabled(store.activeParticipants.isEmpty || isGenerating)
        .accessibilityHint("Creates new participant groups")
    }

    @ViewBuilder
    private var groupsContent: some View {
        if isGenerating {
            HStack(spacing: 12) {
                Image(systemName: "shuffle")
                    .foregroundStyle(AppTheme.accent)
                    .symbolEffect(.variableColor.iterative, options: .repeating, isActive: true)
                Text("Finding a fresh mix of people…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(16)
            .appCard()
        } else if store.groups.isEmpty {
            ContentUnavailableView(
                "No groups yet",
                systemImage: "rectangle.3.group",
                description: Text("Tap Break Out to create a new mix.")
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        } else {
            HStack {
                Text("Your groups")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text("\(store.groups.count)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.subtleSurface, in: Capsule())
            }
            .padding(.top, 8)

            ForEach(Array(store.groups.enumerated()), id: \.offset) { index, group in
                GroupCardView(index: index, group: group, revealID: revealID)
            }
        }
    }

    private func breakout() {
        guard !isGenerating, !store.activeParticipants.isEmpty else { return }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if reduceMotion {
            store.breakout(minGroupSize: minGroupSize)
            revealID = UUID()
            return
        }

        withAnimation(.snappy(duration: 0.2)) {
            isGenerating = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(360))
            guard !Task.isCancelled else { return }
            store.breakout(minGroupSize: minGroupSize)
            revealID = UUID()
            withAnimation(.snappy(duration: 0.25)) {
                isGenerating = false
            }
        }
    }
}

private struct EmptyStateView: View {
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 84, height: 84)
                .background(AppTheme.subtleSurface, in: Circle())

            VStack(spacing: 6) {
                Text("Build your room")
                    .font(.title3.weight(.semibold))
                Text("Add students or guests, then we’ll make thoughtful groups in a tap.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Add people in Settings", action: onOpenSettings)
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .appCard()
    }
}

private struct BreakoutButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

private struct GroupCardView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let index: Int
    let group: [Person]
    let revealID: UUID

    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("GROUP \(index + 1)")
                    .font(.caption.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.subtleSurface, in: Capsule())

                Spacer()

                Text("\(group.count) \(group.count == 1 ? "person" : "people")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                ForEach(group) { member in
                    HStack(spacing: 10) {
                        Text(member.name.prefix(1).uppercased())
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 28, height: 28)
                            .background(AppTheme.subtleSurface, in: Circle())
                        Text(member.name)
                            .font(.body)
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .appCard()
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible || reduceMotion ? 1 : 0.96)
        .offset(y: isVisible || reduceMotion ? 0 : 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Group \(index + 1): \(group.map(\.name).joined(separator: ", "))")
        .accessibilityIdentifier("groupCard-\(index + 1)")
        .task(id: revealID) {
            isVisible = false
            if !reduceMotion {
                try? await Task.sleep(for: .milliseconds(70 * index))
            }
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.35, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}

#Preview("With groups") {
    let store = BreakoutStore()
    store.students = [
        Person(id: UUID(), name: "Avery", isEnabled: true),
        Person(id: UUID(), name: "Jordan", isEnabled: true),
        Person(id: UUID(), name: "Sam", isEnabled: true),
        Person(id: UUID(), name: "Riley", isEnabled: false)
    ]
    store.guests = [Person(id: UUID(), name: "Casey", isEnabled: true)]
    store.groups = [[store.students[0], store.students[1]], [store.students[2], store.guests[0]]]
    return NavigationStack {
        MainView()
            .environmentObject(store)
    }
}

#Preview("Empty") {
    NavigationStack {
        MainView()
            .environmentObject(BreakoutStore())
    }
}
