import SwiftUI

struct ClassroomSelector: View {
    @EnvironmentObject private var store: BreakoutStore
    @State private var isShowingManager = false

    var body: some View {
        Button {
            isShowingManager = true
        } label: {
            HStack(spacing: 5) {
                Text(store.activeClassroomName)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
        }
        .accessibilityIdentifier("classroomSelector")
        .accessibilityLabel("Current class: \(store.activeClassroomName)")
        .sheet(isPresented: $isShowingManager) {
            ClassroomManagerView()
                .environmentObject(store)
        }
    }
}

private struct ClassroomManagerView: View {
    @EnvironmentObject private var store: BreakoutStore
    @Environment(\.dismiss) private var dismiss

    @State private var className = ""
    @State private var pendingAction: PendingAction?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.classrooms) { classroom in
                        ClassroomListRow(
                            classroom: classroom,
                            onRename: {
                                className = classroom.name
                                pendingAction = .rename(classroom)
                            },
                            onDelete: {
                                pendingAction = .delete(classroom)
                            }
                        )
                    }
                } header: {
                    Text("Classes")
                } footer: {
                    Text("Each class has its own people, group size, and pairing history.")
                }
            }
            .navigationTitle("Classes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        className = ""
                        pendingAction = .new
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("addClassroom")
                    .accessibilityLabel("Add class")
                }
            }
            .alert("New Class", isPresented: isShowingNewClassAlert) {
                TextField("Class name", text: $className)
                    .accessibilityIdentifier("newClassNameField")
                Button("Cancel", role: .cancel) {}
                Button("Add") {
                    if store.addClassroom(name: className) {
                        className = ""
                        pendingAction = nil
                    }
                }
            } message: {
                Text("Choose a new name for this class.")
            }
            .alert("Rename Class", isPresented: isShowingRenameAlert) {
                TextField("Class name", text: $className)
                Button("Cancel", role: .cancel) {
                    pendingAction = nil
                }
                Button("Save") {
                    if case let .rename(classroom)? = pendingAction {
                        _ = store.renameClassroom(id: classroom.id, to: className)
                    }
                    pendingAction = nil
                }
            } message: {
                Text("Give this class a name.")
            }
            .alert("Delete Class?", isPresented: isShowingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    pendingAction = nil
                }
                Button("Delete", role: .destructive) {
                    if case let .delete(classroom)? = pendingAction {
                        _ = store.deleteClassroom(id: classroom.id)
                    }
                    pendingAction = nil
                }
            } message: {
                Text("This permanently removes \(pendingClassroomName) and its people and history.")
            }
        }
    }

    private var isShowingNewClassAlert: Binding<Bool> {
        Binding(
            get: {
                if case .new? = pendingAction { return true }
                return false
            },
            set: { if !$0 { pendingAction = nil } }
        )
    }

    private var isShowingRenameAlert: Binding<Bool> {
        Binding(
            get: {
                if case .rename = pendingAction { return true }
                return false
            },
            set: { if !$0 { pendingAction = nil } }
        )
    }

    private var isShowingDeleteConfirmation: Binding<Bool> {
        Binding(
            get: {
                if case .delete = pendingAction { return true }
                return false
            },
            set: { if !$0 { pendingAction = nil } }
        )
    }

    private var pendingClassroomName: String {
        guard case let .delete(classroom)? = pendingAction else { return "this class" }
        return classroom.name
    }
}

private struct ClassroomListRow: View {
    @EnvironmentObject private var store: BreakoutStore
    @Environment(\.dismiss) private var dismiss

    let classroom: Classroom
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button {
            store.selectClassroom(id: classroom.id)
            dismiss()
        } label: {
            HStack {
                Text(classroom.name)
                    .foregroundStyle(.primary)
                Spacer()
                if classroom.id == store.selectedClassroomID {
                    Image(systemName: "checkmark")
                        .foregroundStyle(AppTheme.accent)
                        .accessibilityLabel("Selected")
                }
            }
        }
        .accessibilityIdentifier("classroomRow-\(classroom.id.uuidString)")
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                onRename()
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            .tint(AppTheme.accent)

            if store.classrooms.count > 1 {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

private enum PendingAction {
    case new
    case rename(Classroom)
    case delete(Classroom)
}
