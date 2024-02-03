import Foundation

func getPlayerOptions(games: [BoardGameGeek.Item]) -> ClosedRange<Int> {
    guard !games.isEmpty else {
        return 1...8
    }
    let min = games.compactMap({ $0.stats?.minplayers }).min() ?? 1
    let max = games.compactMap({ $0.stats?.maxplayers }).max() ?? 8
    return min...max
}

func getTimeOptions(games: [BoardGameGeek.Item]) -> [Int] {
    let gameTimes = Set(games.flatMap({ [$0.stats?.minplaytime, $0.stats?.maxplaytime].compactMap({$0}) })).sorted()
    guard !gameTimes.isEmpty else {
        return [30, 45, 60, 120, 240]
    }
    var times = [30, 60]
    times.removeAll(where: { $0 < gameTimes[0] })
    if times.isEmpty {
        times.append(60)
    }
    if gameTimes[0] < times[0] {
        times.insert(gameTimes[0], at: 0)
    }
    while times.last! < gameTimes.last! {
        times.append(times.last! + 60)
    }
    return times
}

func compare(_ lhs: Decimal?, _ rhs: Decimal?, default defaultValue: Decimal) -> ComparisonResult {
    let lhs = lhs ?? defaultValue
    let rhs = rhs ?? defaultValue
    if lhs == rhs {
        return .orderedSame
    } else if lhs.isLess(than: rhs) {
        return .orderedAscending
    } else {
        return .orderedDescending
    }
}

func compare(_ lhs: Int?, _ rhs: Int?, default defaultValue: Int) -> ComparisonResult {
    let lhs = lhs ?? defaultValue
    let rhs = rhs ?? defaultValue
    if lhs == rhs {
        return .orderedSame
    } else if lhs < rhs {
        return .orderedAscending
    } else {
        return .orderedDescending
    }
}

func formatMinutes(_ minutes: Int) -> String {
    if minutes > 60 {
        let hours = minutes / 60
        let minutes = minutes % 60
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h\(minutes)"
    } else if minutes == 60 {
        return "1h"
    } else {
        return "\(minutes)'"
    }
}

func formatMinutes(_ range: ClosedRange<Int>) -> String {
    let min = range.lowerBound
    let max = range.upperBound
    if min == max {
        return formatMinutes(min)
    } else {
        return "\(formatMinutes(min))–\(formatMinutes(max))"
    }
}
