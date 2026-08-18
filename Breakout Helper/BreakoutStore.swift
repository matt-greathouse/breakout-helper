import Foundation
import Combine
import SwiftUI

@MainActor
final class BreakoutStore: ObservableObject {
    @Published private(set) var classrooms: [Classroom] = [] {
        didSet { persistClassrooms() }
    }
    @Published private(set) var selectedClassroomID: UUID? {
        didSet { persistSelectedClassroom() }
    }

    private let defaults: UserDefaults
    private let classroomsKey = "classrooms.v2"
    private let selectedClassroomKey = "selectedClassroomID.v2"
    private let studentsKey = "students.v1"
    private let guestsKey = "guests.v1"
    private let historyKey = "pairingHistory.v1"
    private let lastResetKey = "lastResetDate.v1"
    private let minGroupSizeKey = "minGroupSize.v1"

    private var isLoading = true

    init(defaults: UserDefaults = .standard, now: Date = Date()) {
        self.defaults = defaults

        if ProcessInfo.processInfo.environment["UITEST_RESET_DATA"] == "1" {
            clearPersistedData()
        }

        let migratedLegacyData = loadFromDefaults()
        isLoading = false
        persistClassrooms()
        persistSelectedClassroom()

        if migratedLegacyData {
            clearLegacyData()
        }

        resetIfNeeded(now: now)
    }

    var selectedClassroom: Classroom {
        guard let selectedClassroomID,
              let classroom = classrooms.first(where: { $0.id == selectedClassroomID }) else {
            return classrooms[0]
        }
        return classroom
    }

    var activeClassroomName: String {
        selectedClassroom.name
    }

    var students: [Person] {
        get { selectedClassroom.students }
        set { updateSelectedClassroom { $0.students = newValue } }
    }

    var guests: [Person] {
        get { selectedClassroom.guests }
        set { updateSelectedClassroom { $0.guests = newValue } }
    }

    var groups: [[Person]] {
        get { selectedClassroom.groups }
        set { updateSelectedClassroom { $0.groups = newValue } }
    }

    var minGroupSize: Int {
        get { selectedClassroom.minGroupSize }
        set { updateSelectedClassroom { $0.minGroupSize = min(max(newValue, 2), 12) } }
    }

    var activeParticipants: [Person] {
        (students + guests).filter { $0.isEnabled }
    }

    @discardableResult
    func addClassroom(name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let classroom = Classroom(name: trimmed, lastResetDate: Date())
        classrooms.append(classroom)
        selectedClassroomID = classroom.id
        return true
    }

    @discardableResult
    func renameSelectedClassroom(to name: String) -> Bool {
        renameClassroom(id: selectedClassroom.id, to: name)
    }

    @discardableResult
    func renameClassroom(id: UUID, to name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = classrooms.firstIndex(where: { $0.id == id }) else { return false }
        var classroom = classrooms[index]
        classroom.name = trimmed
        classrooms[index] = classroom
        return true
    }

    @discardableResult
    func deleteClassroom(id: UUID) -> Bool {
        guard classrooms.count > 1,
              let index = classrooms.firstIndex(where: { $0.id == id }) else {
            return false
        }

        let wasSelected = id == selectedClassroomID
        classrooms.remove(at: index)
        if wasSelected {
            selectedClassroomID = classrooms[min(index, classrooms.count - 1)].id
        }
        return true
    }

    func selectClassroom(id: UUID) {
        guard classrooms.contains(where: { $0.id == id }) else { return }
        selectedClassroomID = id
    }

    func addStudent(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        updateSelectedClassroom {
            $0.students.append(Person(id: UUID(), name: trimmed, isEnabled: true))
        }
    }

    func addGuest(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        updateSelectedClassroom {
            $0.guests.append(Person(id: UUID(), name: trimmed, isEnabled: true))
        }
    }

    func removeStudents(at offsets: IndexSet) {
        updateSelectedClassroom { $0.students.remove(atOffsets: offsets) }
    }

    func removeGuests(at offsets: IndexSet) {
        updateSelectedClassroom { $0.guests.remove(atOffsets: offsets) }
    }

    func setStudentEnabled(id: UUID, isEnabled: Bool) {
        updateSelectedClassroom {
            guard let index = $0.students.firstIndex(where: { $0.id == id }) else { return }
            $0.students[index].isEnabled = isEnabled
        }
    }

    func setGuestEnabled(id: UUID, isEnabled: Bool) {
        updateSelectedClassroom {
            guard let index = $0.guests.firstIndex(where: { $0.id == id }) else { return }
            $0.guests[index].isEnabled = isEnabled
        }
    }

    func breakout() {
        resetIfNeeded()
        let classroom = selectedClassroom
        let createdGroups = GroupingAlgorithm.makeGroups(
            people: classroom.activeParticipants,
            minGroupSize: classroom.minGroupSize,
            history: classroom.pairingHistory
        )

        updateSelectedClassroom { classroom in
            classroom.groups = createdGroups
            updateHistory(for: &classroom)
        }
    }

    func resetIfNeeded(now: Date = Date()) {
        let calendar = Calendar.current
        var updatedClassrooms = classrooms
        var didReset = false

        for index in updatedClassrooms.indices {
            let lastResetDate = updatedClassrooms[index].lastResetDate
            if lastResetDate == nil || !calendar.isDate(lastResetDate!, inSameDayAs: now) {
                updatedClassrooms[index].guests = []
                updatedClassrooms[index].groups = []
                updatedClassrooms[index].pairingHistory = [:]
                updatedClassrooms[index].lastResetDate = now
                didReset = true
            }
        }

        if didReset {
            classrooms = updatedClassrooms
        }
    }

    private func updateSelectedClassroom(_ update: (inout Classroom) -> Void) {
        guard let index = classrooms.firstIndex(where: { $0.id == selectedClassroom.id }) else { return }
        var classroom = classrooms[index]
        update(&classroom)
        classrooms[index] = classroom
    }

    private func updateHistory(for classroom: inout Classroom) {
        guard !classroom.groups.isEmpty else { return }
        for group in classroom.groups where group.count > 1 {
            for i in 0..<(group.count - 1) {
                for j in (i + 1)..<group.count {
                    let key = GroupingAlgorithm.pairKey(group[i].id, group[j].id)
                    classroom.pairingHistory[key, default: 0] += 1
                }
            }
        }
    }

    private func loadFromDefaults() -> Bool {
        if let data = defaults.data(forKey: classroomsKey),
           let decoded = try? JSONDecoder().decode([Classroom].self, from: data),
           !decoded.isEmpty {
            classrooms = decoded
            selectedClassroomID = selectedIDFromDefaults(validIn: decoded) ?? decoded[0].id
            return false
        }

        let legacyStudents = decode([Person].self, forKey: studentsKey) ?? []
        let legacyGuests = decode([Person].self, forKey: guestsKey) ?? []
        let legacyHistory = decode([String: Int].self, forKey: historyKey) ?? [:]
        let lastResetDate = dateFromDefaults(forKey: lastResetKey)
        let legacyMinGroupSize = (defaults.object(forKey: minGroupSizeKey) as? Int) ?? 3

        classrooms = [
            Classroom(
                name: "My Class",
                students: legacyStudents,
                guests: legacyGuests,
                pairingHistory: legacyHistory,
                minGroupSize: legacyMinGroupSize,
                lastResetDate: lastResetDate
            )
        ]
        selectedClassroomID = classrooms[0].id
        return legacyDataExists
    }

    private var legacyDataExists: Bool {
        [studentsKey, guestsKey, historyKey, lastResetKey, minGroupSizeKey]
            .contains { defaults.object(forKey: $0) != nil }
    }

    private func selectedIDFromDefaults(validIn classrooms: [Classroom]) -> UUID? {
        guard let string = defaults.string(forKey: selectedClassroomKey),
              let id = UUID(uuidString: string),
              classrooms.contains(where: { $0.id == id }) else {
            return nil
        }
        return id
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func dateFromDefaults(forKey key: String) -> Date? {
        let interval = defaults.double(forKey: key)
        return interval > 0 ? Date(timeIntervalSince1970: interval) : nil
    }

    private func persistClassrooms() {
        guard !isLoading, let data = try? JSONEncoder().encode(classrooms) else { return }
        defaults.set(data, forKey: classroomsKey)
    }

    private func persistSelectedClassroom() {
        guard !isLoading else { return }
        defaults.set(selectedClassroomID?.uuidString, forKey: selectedClassroomKey)
    }

    private func clearPersistedData() {
        [classroomsKey, selectedClassroomKey, studentsKey, guestsKey, historyKey, lastResetKey, minGroupSizeKey]
            .forEach(defaults.removeObject(forKey:))
    }

    private func clearLegacyData() {
        [studentsKey, guestsKey, historyKey, lastResetKey, minGroupSizeKey]
            .forEach(defaults.removeObject(forKey:))
    }
}

struct Classroom: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var students: [Person]
    var guests: [Person]
    var pairingHistory: [String: Int]
    var minGroupSize: Int
    var lastResetDate: Date?
    var groups: [[Person]] = []

    init(
        id: UUID = UUID(),
        name: String,
        students: [Person] = [],
        guests: [Person] = [],
        pairingHistory: [String: Int] = [:],
        minGroupSize: Int = 3,
        lastResetDate: Date? = nil,
        groups: [[Person]] = []
    ) {
        self.id = id
        self.name = name
        self.students = students
        self.guests = guests
        self.pairingHistory = pairingHistory
        self.minGroupSize = min(max(minGroupSize, 2), 12)
        self.lastResetDate = lastResetDate
        self.groups = groups
    }

    var activeParticipants: [Person] {
        (students + guests).filter { $0.isEnabled }
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, students, guests, pairingHistory, minGroupSize, lastResetDate
    }
}

struct Person: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    var name: String
    var isEnabled: Bool
}
