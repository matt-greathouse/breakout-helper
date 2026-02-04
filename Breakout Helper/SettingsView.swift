import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: BreakoutStore
    @State private var newStudentName = ""
    @State private var newGuestName = ""

    var body: some View {
        Form {
            Section("Students") {
                addRow(
                    placeholder: "Add student",
                    text: $newStudentName,
                    action: {
                        store.addStudent(name: newStudentName)
                        newStudentName = ""
                    }
                )

                ForEach($store.students) { $student in
                    Toggle(student.name, isOn: $student.isEnabled)
                }
                .onDelete(perform: store.removeStudents)
            }

            Section("Guests (clears daily)") {
                addRow(
                    placeholder: "Add guest",
                    text: $newGuestName,
                    action: {
                        store.addGuest(name: newGuestName)
                        newGuestName = ""
                    }
                )

                ForEach($store.guests) { $guest in
                    Toggle(guest.name, isOn: $guest.isEnabled)
                }
                .onDelete(perform: store.removeGuests)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.resetIfNeeded() }
    }

    private func addRow(
        placeholder: String,
        text: Binding<String>,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

            Button("Add") {
                action()
            }
            .buttonStyle(.bordered)
            .disabled(text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(BreakoutStore())
    }
}
