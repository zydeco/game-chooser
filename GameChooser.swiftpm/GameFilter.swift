import Foundation

struct GameFilter: CustomStringConvertible, Equatable {
    static let maxPlayers = 8
    var description: String { "{players=\(String(describing:players)),time=\(String(describing: time))}"}
    var players: Int?
    var time: ClosedRange<Int>?

    func matches(_ game: BoardGameGeek.Item) -> Bool {
        guard game.status?.own == 1 else {
            return false
        }
        let minPlayers = game.stats?.minplayers ?? 0
        let maxPlayers = game.stats?.maxplayers ?? Int.max
        let minTime = game.stats?.minplaytime ?? time?.lowerBound ?? 0
        let maxTime = game.stats?.maxplaytime ?? time?.upperBound ?? Int.max
        let matchesPlayers = players == nil || players! >= minPlayers && players! <= maxPlayers || players == GameFilter.maxPlayers && minPlayers > players!
        let matchesTime = time == nil || time!.lowerBound <= minTime && maxTime <= time!.upperBound
        return matchesPlayers && matchesTime
    }
}
