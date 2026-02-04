import Foundation

struct GroupingAlgorithm {
    static func makeGroups(people: [Person], minGroupSize: Int, history: [String: Int]) -> [[Person]] {
        guard !people.isEmpty else { return [] }

        let safeMin = max(minGroupSize, 1)
        let groupCount = max(1, people.count / safeMin)
        let baseSize = people.count / groupCount
        let remainder = people.count % groupCount
        let targetSizes = (0..<groupCount).map { index in
            baseSize + (index < remainder ? 1 : 0)
        }

        let attempts = min(20, max(3, people.count / 2))
        var bestGroups: [[Person]] = []
        var bestScore = Int.max

        for _ in 0..<attempts {
            let shuffled = people.shuffled()
            let candidate = buildGroups(
                people: shuffled,
                targetSizes: targetSizes,
                history: history
            )
            let score = totalScore(for: candidate, history: history)
            if score < bestScore {
                bestScore = score
                bestGroups = candidate
            }
        }

        return bestGroups
    }

    static func pairKey(_ a: UUID, _ b: UUID) -> String {
        let ids = [a.uuidString, b.uuidString].sorted()
        return "\(ids[0])|\(ids[1])"
    }

    private static func buildGroups(
        people: [Person],
        targetSizes: [Int],
        history: [String: Int]
    ) -> [[Person]] {
        var groups = Array(repeating: [Person](), count: targetSizes.count)

        for person in people {
            let candidateIndices = groups.indices.filter { groups[$0].count < targetSizes[$0] }
            var bestIndices: [Int] = []
            var bestCost = Int.max

            for index in candidateIndices {
                let cost = incrementalCost(for: person, in: groups[index], history: history)
                if cost < bestCost {
                    bestCost = cost
                    bestIndices = [index]
                } else if cost == bestCost {
                    bestIndices.append(index)
                }
            }

            let chosenIndex = bestIndices.randomElement() ?? candidateIndices.randomElement() ?? 0
            groups[chosenIndex].append(person)
        }

        return groups
    }

    private static func incrementalCost(
        for person: Person,
        in group: [Person],
        history: [String: Int]
    ) -> Int {
        group.reduce(0) { total, member in
            let key = pairKey(person.id, member.id)
            return total + (history[key] ?? 0)
        }
    }

    private static func totalScore(for groups: [[Person]], history: [String: Int]) -> Int {
        var total = 0
        for group in groups {
            guard group.count > 1 else { continue }
            for i in 0..<(group.count - 1) {
                for j in (i + 1)..<group.count {
                    let key = pairKey(group[i].id, group[j].id)
                    total += history[key] ?? 0
                }
            }
        }
        return total
    }
}
