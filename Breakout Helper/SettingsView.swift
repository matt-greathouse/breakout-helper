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
        List {
            Section {
                addRow(
                    placeholder: "Add student",
                    text: $newStudentName,
                    field: .student,
                    action: {
                        store.addStudent(name: newStudentName)
                        newStudentName = ""
                    }
                )

                ForEach(store.students) { student in
                    ParticipantToggleRow(
                        person: student,
                        isOn: bindingForStudent(id: student.id)
                    )
                }
                .onDelete(perform: store.removeStudents)
            } header: {
                sectionHeader("Students", count: store.students.count, detail: "Ready for every session")
            }

            Section {
                addRow(
                    placeholder: "Add guest",
                    text: $newGuestName,
                    field: .guest,
                    action: {
                        store.addGuest(name: newGuestName)
                        newGuestName = ""
                    }
                )

                ForEach(store.guests) { guest in
                    ParticipantToggleRow(
                        person: guest,
                        isOn: bindingForGuest(id: guest.id)
                    )
                }
                .onDelete(perform: store.removeGuests)
            } header: {
                sectionHeader("Guests", count: store.guests.count, detail: "Clears daily")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.pageBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                ClassroomSelector()
            }
        }
        .onAppear { store.resetIfNeeded() }
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(TapGesture().onEnded {
            focusedField = nil
        })
    }

    private func sectionHeader(_ title: String, count: Int, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title)
                Spacer()
                Text("\(count)")
                    .foregroundStyle(AppTheme.accent)
            }
            Text(detail)
                .font(.caption)
                .textCase(nil)
                .foregroundStyle(.secondary)
        }
        .textCase(nil)
        .font(.subheadline.weight(.semibold))
        .padding(.top, 8)
    }

    private func addRow(
        placeholder: String,
        text: Binding<String>,
        field: Field,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "plus")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28, height: 28)
                .background(AppTheme.subtleSurface, in: Circle())

            TextField(placeholder, text: text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($focusedField, equals: field)
                .accessibilityIdentifier(field == .student ? "studentNameField" : "guestNameField")
                .onSubmit { commit(text: text, field: field, action: action) }

            Button("Add") {
                commit(text: text, field: field, action: action)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .disabled(text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityIdentifier(field == .student ? "addStudent" : "addGuest")
        }
        .padding(.vertical, 4)
    }

    private func commit(text: Binding<String>, field: Field, action: @escaping () -> Void) {
        guard !text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        action()
        focusedField = field
    }

    private func bindingForStudent(id: UUID) -> Binding<Bool> {
        Binding(
            get: { store.students.first(where: { $0.id == id })?.isEnabled ?? false },
            set: { store.setStudentEnabled(id: id, isEnabled: $0) }
        )
    }

    private func bindingForGuest(id: UUID) -> Binding<Bool> {
        Binding(
            get: { store.guests.first(where: { $0.id == id })?.isEnabled ?? false },
            set: { store.setGuestEnabled(id: id, isEnabled: $0) }
        )
    }
}

private struct ParticipantToggleRow: View {
    let person: Person
    let isOn: Binding<Bool>

    var body: some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 10) {
                InitialBadge(person.name, size: 30)
                Text(person.name)
            }
        }
        .tint(AppTheme.accent)
        .padding(.vertical, 2)
    }
}

#Preview {
    let store = BreakoutStore()
    store.students = [
        Person(id: UUID(), name: "Avery", isEnabled: true),
        Person(id: UUID(), name: "Jordan", isEnabled: false)
    ]
    store.guests = [Person(id: UUID(), name: "Casey", isEnabled: true)]
    return NavigationStack {
        SettingsView()
            .environmentObject(store)
    }
}

#Preview("Empty settings") {
    NavigationStack {
        SettingsView()
            .environmentObject(BreakoutStore())
    }
}
