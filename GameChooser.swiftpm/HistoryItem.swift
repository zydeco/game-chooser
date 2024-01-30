import Foundation

struct HistoryItem: Identifiable, Decodable, Encodable {
    var id: UUID
    var names: [String]

    func asCollections() -> [(id: UUID, name: String)] {
        return names.map({ (UUID(), $0) })
    }
}

private let kDefaultsHistoryKey = "history"
private let kMaxHistoryItems = 8

func loadHistory() -> [HistoryItem] {
    if let decodedHistory = try? JSONDecoder().decode(Array<HistoryItem>.self, from: UserDefaults.standard.data(forKey: kDefaultsHistoryKey) ?? Data()) {
        return decodedHistory
    }
    return []
}

func saveHistory(_ history: [HistoryItem]) {
    if let json = try? JSONEncoder().encode(history) {
        UserDefaults.standard.set(json, forKey: kDefaultsHistoryKey)
    }
}

func addToHistory(names: [String]) {
    var history = loadHistory()
    let namesSet = Set(names.map({$0.lowercased()}))
    // insert new item at top
    history.insert(HistoryItem(id: UUID(), names: names), at: 0)
    // remove occurrences
    while let index = history.lastIndex(where: { Set($0.names.map({ $0.lowercased() })) == namesSet }), index > 0 {
        history.remove(at: index)
    }
    // only save max items
    if history.count > kMaxHistoryItems {
        history.removeLast(history.count - kMaxHistoryItems)
    }
    saveHistory(history)
}
