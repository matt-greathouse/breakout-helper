import Foundation
import Testing
@testable import Breakout_Helper

@MainActor
struct Breakout_HelperTests {
    @Test func migratesLegacyDataIntoMyClass() throws {
        let defaults = makeDefaults()
        defer { removeDefaults(defaults) }

        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let student = Person(id: UUID(), name: "Avery", isEnabled: true)
        let guest = Person(id: UUID(), name: "Casey", isEnabled: false)
        let pairKey = GroupingAlgorithm.pairKey(student.id, guest.id)
        defaults.set(try JSONEncoder().encode([student]), forKey: "students.v1")
        defaults.set(try JSONEncoder().encode([guest]), forKey: "guests.v1")
        defaults.set(try JSONEncoder().encode([pairKey: 4]), forKey: "pairingHistory.v1")
        defaults.set(now.timeIntervalSince1970, forKey: "lastResetDate.v1")
        defaults.set(5, forKey: "minGroupSize.v1")

        let store = BreakoutStore(defaults: defaults, now: now)

        #expect(store.classrooms.count == 1)
        #expect(store.selectedClassroom.name == "My Class")
        #expect(store.students == [student])
        #expect(store.guests == [guest])
        #expect(store.minGroupSize == 5)
        #expect(store.selectedClassroom.pairingHistory[pairKey] == 4)
        #expect(defaults.data(forKey: "classrooms.v2") != nil)
        #expect(defaults.data(forKey: "students.v1") == nil)
        #expect(defaults.object(forKey: "minGroupSize.v1") == nil)
    }

    @Test func classroomsKeepRosterSettingsAndGroupsIsolated() {
        let defaults = makeDefaults()
        defer { removeDefaults(defaults) }

        let store = BreakoutStore(defaults: defaults)
        _ = store.renameSelectedClassroom(to: "Algebra")
        store.addStudent(name: "Avery")
        store.addStudent(name: "Jordan")
        store.minGroupSize = 2
        store.breakout()
        let algebraID = store.selectedClassroom.id
        let algebraGroups = store.groups

        #expect(store.addClassroom(name: "Science"))
        let scienceID = store.selectedClassroom.id
        store.addStudent(name: "Casey")
        store.minGroupSize = 4

        #expect(store.students.map(\.name) == ["Casey"])
        #expect(store.groups.isEmpty)
        #expect(store.minGroupSize == 4)

        store.selectClassroom(id: algebraID)
        #expect(store.students.map(\.name) == ["Avery", "Jordan"])
        #expect(store.minGroupSize == 2)
        #expect(store.groups == algebraGroups)

        store.selectClassroom(id: scienceID)
        #expect(store.students.map(\.name) == ["Casey"])
    }

    @Test func selectionAndGeneratedGroupsPersist() {
        let defaults = makeDefaults()
        defer { removeDefaults(defaults) }

        let store = BreakoutStore(defaults: defaults)
        store.addStudent(name: "Avery")
        store.addStudent(name: "Jordan")
        store.minGroupSize = 2
        store.breakout()
        #expect(!store.groups.isEmpty)
        #expect(store.addClassroom(name: "Science"))
        let selectedID = store.selectedClassroom.id

        let restoredStore = BreakoutStore(defaults: defaults)
        #expect(restoredStore.selectedClassroom.id == selectedID)
        restoredStore.selectClassroom(id: store.classrooms[0].id)
        #expect(restoredStore.groups == store.classrooms[0].groups)
    }

    @Test func restoresClassroomsSavedBeforeGroupsWerePersisted() throws {
        let defaults = makeDefaults()
        defer { removeDefaults(defaults) }

        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let student = Person(id: UUID(), name: "Avery", isEnabled: true)
        let classroom = Classroom(
            name: "Algebra",
            students: [student],
            lastResetDate: now
        )
        defaults.set(
            try JSONEncoder().encode([ClassroomWithoutSavedGroups(classroom)]),
            forKey: "classrooms.v2"
        )

        let restoredStore = BreakoutStore(defaults: defaults, now: now)

        #expect(restoredStore.selectedClassroom.name == "Algebra")
        #expect(restoredStore.students == [student])
        #expect(restoredStore.groups.isEmpty)
    }

    @Test func deletingClassesKeepsAtLeastOneAndSelectsANeighbor() {
        let defaults = makeDefaults()
        defer { removeDefaults(defaults) }

        let store = BreakoutStore(defaults: defaults)
        let firstID = store.selectedClassroom.id
        #expect(!store.deleteClassroom(id: firstID))
        #expect(store.addClassroom(name: "Science"))
        let scienceID = store.selectedClassroom.id

        #expect(store.deleteClassroom(id: scienceID))
        #expect(store.classrooms.count == 1)
        #expect(store.selectedClassroom.id == firstID)
        #expect(!store.deleteClassroom(id: firstID))
    }

    @Test func dailyResetClearsTransientDataInEveryClass() {
        let defaults = makeDefaults()
        defer { removeDefaults(defaults) }

        let start = Date()
        let store = BreakoutStore(defaults: defaults, now: start)
        store.addStudent(name: "Avery")
        store.addGuest(name: "Casey")
        store.minGroupSize = 2
        store.breakout()
        let firstID = store.selectedClassroom.id

        #expect(store.selectedClassroom.pairingHistory.isEmpty == false)
        #expect(store.addClassroom(name: "Science"))
        store.addStudent(name: "Jordan")
        store.addGuest(name: "Riley")
        store.minGroupSize = 2
        store.breakout()
        let secondID = store.selectedClassroom.id

        store.resetIfNeeded(now: start.addingTimeInterval(86_400))

        store.selectClassroom(id: firstID)
        #expect(store.students.map(\.name) == ["Avery"])
        #expect(store.guests.isEmpty)
        #expect(store.groups.isEmpty)
        #expect(store.selectedClassroom.pairingHistory.isEmpty)

        store.selectClassroom(id: secondID)
        #expect(store.students.map(\.name) == ["Jordan"])
        #expect(store.guests.isEmpty)
        #expect(store.groups.isEmpty)
        #expect(store.selectedClassroom.pairingHistory.isEmpty)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "BreakoutHelperTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(suiteName, forKey: "testSuiteName")
        return defaults
    }

    private func removeDefaults(_ defaults: UserDefaults) {
        guard let suiteName = defaults.string(forKey: "testSuiteName") else {
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
    }
}

private struct ClassroomWithoutSavedGroups: Encodable {
    let id: UUID
    let name: String
    let students: [Person]
    let guests: [Person]
    let pairingHistory: [String: Int]
    let minGroupSize: Int
    let lastResetDate: Date?

    init(_ classroom: Classroom) {
        id = classroom.id
        name = classroom.name
        students = classroom.students
        guests = classroom.guests
        pairingHistory = classroom.pairingHistory
        minGroupSize = classroom.minGroupSize
        lastResetDate = classroom.lastResetDate
    }
}
