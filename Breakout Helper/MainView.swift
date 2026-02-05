import SwiftUI

struct MainView: View {
    @EnvironmentObject private var store: BreakoutStore
    @AppStorage("minGroupSize.v1") private var minGroupSize = 3
    @GestureState private var isPressingBreakout = false
    @State private var revealID = UUID()

    var body: some View {
        Form {
            Section {
                Text("Active participants: \(store.activeParticipants.count) of \(store.students.count + store.guests.count)")
                    .foregroundStyle(.secondary)
            }

            Section("Minimum group size") {
                Stepper(value: $minGroupSize, in: 2...12) {
                    Text("\(minGroupSize) people")
                }
            }

            Section {
                Button(action: breakout) {
                    Text(store.groups.isEmpty ? "BREAKOUT" : "BREAKOUT AGAIN")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(store.activeParticipants.isEmpty)
                .scaleEffect(isPressingBreakout ? 0.98 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressingBreakout)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0).updating($isPressingBreakout) { _, state, _ in
                        state = true
                    }
                )
            }

            Section("Groups") {
                if store.groups.isEmpty {
                    Text("No groups yet. Tap BREAKOUT to create them.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(store.groups.enumerated()), id: \.offset) { index, group in
                        GroupRowView(
                            index: index,
                            group: group,
                            revealID: revealID
                        )
                    }
                }
            }
        }
        .navigationTitle("Breakout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.resetIfNeeded() }
    }

    private func breakout() {
        withAnimation(.easeOut(duration: 0.25)) {
            store.breakout(minGroupSize: minGroupSize)
            revealID = UUID()
        }
    }
}

#Preview {
    MainView()
        .environmentObject(BreakoutStore())
}

private struct GroupRowView: View {
    let index: Int
    let group: [Person]
    let revealID: UUID
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Group \(index + 1)")
                .font(.headline)
            ForEach(group) { member in
                Text(member.name)
            }
        }
        .padding(.vertical, 4)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 12)
        .task(id: revealID) {
            isVisible = false
            let delay = UInt64(80_000_000 * index)
            try? await Task.sleep(nanoseconds: delay)
            withAnimation(.easeOut(duration: 0.3)) {
                isVisible = true
            }
        }
    }
}
