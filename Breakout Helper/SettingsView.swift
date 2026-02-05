import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: BreakoutStore
    @State private var newStudentName = ""
    @State private var newGuestName = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case student
        case guest
    }

    var body: some View {
        Form {
            Section("Students") {
                addRow(
                    placeholder: "Add student",
                    text: $newStudentName,
                    field: .student,
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
                    field: .guest,
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
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(TapGesture().onEnded {
            focusedField = nil
        })
    }

    private func addRow(
        placeholder: String,
        text: Binding<String>,
        field: Field,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            let commit = {
                if text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return
                }
                action()
                focusedField = field
            }

            TextField(placeholder, text: text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($focusedField, equals: field)
                .onSubmit { commit() }

            Button("Add") {
                commit()
            }
            .buttonStyle(.bordered)
            .disabled(text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let store = BreakoutStore()
    store.students = [
        Person(id: UUID(), name: "Avery", isEnabled: true),
        Person(id: UUID(), name: "Jordan", isEnabled: false)
    ]
    store.guests = [
        Person(id: UUID(), name: "Casey", isEnabled: true)
    ]
    return NavigationStack {
        SettingsView()
            .environmentObject(store)
    }
}
