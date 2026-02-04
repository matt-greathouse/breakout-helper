import Foundation
import Combine

@MainActor
final class BreakoutStore: ObservableObject {
    @Published var students: [Person] = [] {
        didSet { persistStudents() }
    }
    @Published var guests: [Person] = [] {
        didSet { persistGuests() }
    }
    @Published var groups: [[Person]] = []

    private var pairingHistory: [String: Int] = [:] {
        didSet { persistHistory() }
    }
    private var lastResetDate: Date? {
        didSet { persistLastResetDate() }
    }

    private let studentsKey = "students.v1"
    private let guestsKey = "guests.v1"
    private let historyKey = "pairingHistory.v1"
    private let lastResetKey = "lastResetDate.v1"

    private var isLoading = true

    init() {
        loadFromDefaults()
        isLoading = false
        resetIfNeeded()
    }

    var activeParticipants: [Person] {
        (students + guests).filter { $0.isEnabled }
    }

    func addStudent(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        students.append(Person(id: UUID(), name: trimmed, isEnabled: true))
    }

    func addGuest(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guests.append(Person(id: UUID(), name: trimmed, isEnabled: true))
    }

    func removeStudents(at offsets: IndexSet) {
        for offset in offsets.sorted(by: >) {
            if students.indices.contains(offset) {
                students.remove(at: offset)
            }
        }
    }

    func removeGuests(at offsets: IndexSet) {
        for offset in offsets.sorted(by: >) {
            if guests.indices.contains(offset) {
                guests.remove(at: offset)
            }
        }
    }

    func breakout(minGroupSize: Int) {
        resetIfNeeded()
        let participants = activeParticipants
        groups = GroupingAlgorithm.makeGroups(
            people: participants,
            minGroupSize: minGroupSize,
            history: pairingHistory
        )
        updateHistory(with: groups)
    }

    func resetIfNeeded(now: Date = Date()) {
        let calendar = Calendar.current
        guard let last = lastResetDate else {
            pairingHistory = [:]
            guests = []
            groups = []
            lastResetDate = now
            return
        }

        if !calendar.isDate(last, inSameDayAs: now) {
            pairingHistory = [:]
            guests = []
            groups = []
            lastResetDate = now
        }
    }

    private func updateHistory(with groups: [[Person]]) {
        guard !groups.isEmpty else { return }
        var updated = pairingHistory
        for group in groups {
            guard group.count > 1 else { continue }
            for i in 0..<(group.count - 1) {
                for j in (i + 1)..<group.count {
                    let key = GroupingAlgorithm.pairKey(group[i].id, group[j].id)
                    updated[key, default: 0] += 1
                }
            }
        }
        pairingHistory = updated
    }

    private func loadFromDefaults() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: studentsKey),
           let decoded = try? JSONDecoder().decode([Person].self, from: data) {
            students = decoded
        }

        if let data = defaults.data(forKey: guestsKey),
           let decoded = try? JSONDecoder().decode([Person].self, from: data) {
            guests = decoded
        }

        if let data = defaults.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            pairingHistory = decoded
        }

        let lastResetInterval = defaults.double(forKey: lastResetKey)
        if lastResetInterval > 0 {
            lastResetDate = Date(timeIntervalSince1970: lastResetInterval)
        }
    }

    private func persistStudents() {
        guard !isLoading else { return }
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(students) {
            defaults.set(data, forKey: studentsKey)
        }
    }

    private func persistGuests() {
        guard !isLoading else { return }
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(guests) {
            defaults.set(data, forKey: guestsKey)
        }
    }

    private func persistHistory() {
        guard !isLoading else { return }
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(pairingHistory) {
            defaults.set(data, forKey: historyKey)
        }
    }

    private func persistLastResetDate() {
        guard !isLoading else { return }
        let defaults = UserDefaults.standard
        if let lastResetDate {
            defaults.set(lastResetDate.timeIntervalSince1970, forKey: lastResetKey)
        }
    }
}

struct Person: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var isEnabled: Bool
}
