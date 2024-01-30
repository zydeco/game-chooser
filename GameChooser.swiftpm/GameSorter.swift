import Foundation

struct GameSorter: Identifiable, SortComparator {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.enabled == rhs.enabled && lhs.order == rhs.order && lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
        hasher.combine(order)
        hasher.combine(name)
    }

    typealias Compared = BoardGameGeek.Item
    var name: String
    var order: SortOrder = .forward
    var enabled: Bool = false
    var comparor: (BoardGameGeek.Item, BoardGameGeek.Item) -> ComparisonResult
    var id: String { name }

    func compare(_ lhs: BoardGameGeek.Item, _ rhs: BoardGameGeek.Item) -> ComparisonResult {
        switch (order, comparor(lhs, rhs)) {
        case (_, .orderedSame):
            return .orderedSame
        case (.forward, let result):
            return result
        case (.reverse, .orderedAscending):
            return .orderedDescending
        case (.reverse, .orderedDescending):
            return .orderedAscending
        }
    }
}
