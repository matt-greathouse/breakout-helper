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

    @State private var isShowingNewClassAlert = false
    @State private var isShowingRenameAlert = false
    @State private var className = ""
    @State private var classroomToRename: Classroom?
    @State private var classroomToDelete: Classroom?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.classrooms) { classroom in
                        ClassroomListRow(
                            classroom: classroom,
                            name: $className,
                            classroomToRename: $classroomToRename,
                            classroomToDelete: $classroomToDelete,
                            isShowingRenameAlert: $isShowingRenameAlert
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
                        isShowingNewClassAlert = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("addClassroom")
                    .accessibilityLabel("Add class")
                }
            }
            .alert("New Class", isPresented: $isShowingNewClassAlert) {
                TextField("Class name", text: $className)
                    .accessibilityIdentifier("newClassNameField")
                Button("Cancel", role: .cancel) {}
                Button("Add") {
                    if store.addClassroom(name: className) {
                        className = ""
                    }
                }
            } message: {
                Text("Give this class a name.")
            }
            .alert("Rename Class", isPresented: $isShowingRenameAlert) {
                TextField("Class name", text: $className)
                Button("Cancel", role: .cancel) {
                    classroomToRename = nil
                }
                Button("Save") {
                    if let classroomToRename {
                        _ = store.renameClassroom(id: classroomToRename.id, to: className)
                    }
                    classroomToRename = nil
                }
            }
            .alert("Delete Class?", isPresented: isShowingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    classroomToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let classroomToDelete {
                        _ = store.deleteClassroom(id: classroomToDelete.id)
                    }
                    classroomToDelete = nil
                }
            } message: {
                Text("This permanently removes \(classroomToDelete?.name ?? "this class") and its people and history.")
            }
        }
    }

    private var isShowingDeleteConfirmation: Binding<Bool> {
        Binding(
            get: { classroomToDelete != nil },
            set: { if !$0 { classroomToDelete = nil } }
        )
    }

}

private struct ClassroomListRow: View {
    @EnvironmentObject private var store: BreakoutStore
    @Environment(\.dismiss) private var dismiss

    let classroom: Classroom
    @Binding var name: String
    @Binding var classroomToRename: Classroom?
    @Binding var classroomToDelete: Classroom?
    @Binding var isShowingRenameAlert: Bool

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
                classroomToRename = classroom
                name = classroom.name
                isShowingRenameAlert = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            .tint(AppTheme.accent)

            if store.classrooms.count > 1 {
                Button(role: .destructive) {
                    classroomToDelete = classroom
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}
