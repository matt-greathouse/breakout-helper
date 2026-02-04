import SwiftUI

struct MainView: View {
    @EnvironmentObject private var store: BreakoutStore
    @AppStorage("minGroupSize.v1") private var minGroupSize = 3

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
                Button(action: { store.breakout(minGroupSize: minGroupSize) }) {
                    Text(store.groups.isEmpty ? "BREAKOUT" : "BREAKOUT AGAIN")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(store.activeParticipants.isEmpty)
            }

            Section("Groups") {
                if store.groups.isEmpty {
                    Text("No groups yet. Tap BREAKOUT to create them.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(store.groups.enumerated()), id: \.offset) { index, group in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Group \(index + 1)")
                                .font(.headline)
                            ForEach(group) { member in
                                Text(member.name)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Breakout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.resetIfNeeded() }
    }
}

#Preview {
    MainView()
        .environmentObject(BreakoutStore())
}
