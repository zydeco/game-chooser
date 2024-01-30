import SwiftUI

struct GamesView: View {
    @Binding var collections: [(id: UUID, name: String)]
    @State var games: [BoardGameGeek.Collection] = []
    @State var playerOptions: ClosedRange<Int> = 1...8
    @State var timeOptions = [15, 30, 60, 120, 240]
    @State var filteredGames: [BoardGameGeek.Item] = []
    @State var showingSort = false
    @State var showingFilter = false
    @State var filter = GameFilter()
    @State var toLoad = 0
    @State var sorters: [GameSorter] = [
        GameSorter(name: "Name", enabled: true) { $0.name.compare($1.name) },
        GameSorter(name: "BGG Rating", order: .reverse) { compare($0.stats?.rating?.average, $1.stats?.rating?.average, default:.zero) },
        GameSorter(name: "Year Published", order: .reverse) { compare($0.yearpublished, $1.yearpublished, default:.zero) }
        // TODO: best with this number of players
        // TODO: complexity
        // TODO: last played
        // TODO: played often
        ]
    @State var totalGames = 0
    var currentSorter: GameSorter { sorters.first(where: { $0.enabled }) ?? sorters[0] }

    var body: some View {
        List {
            Section {
                ForEach(filteredGames) { GameView(game: $0).alignmentGuide(.listRowSeparatorLeading) { _ in return 0 } }
            } header: {
                switch (totalGames) {
                case 0:
                    if toLoad > 0 {
                        Text("Loading ...")
                    } else {
                        Text("no games")
                    }
                case filteredGames.count:
                    Text("\(totalGames) games")
                default:
                    Text("\(filteredGames.count) of \(totalGames) games")
                }
            } footer: {
                HStack {
                    Spacer()
                    Link(destination: URL(string:"https://boardgamegeek.com")!, label: {
                        Image(uiImage: #imageLiteral(resourceName: "bgg")).resizable().scaledToFit().frame(height: 42)
                    })
                    Spacer()
                }
            }
        }.onChange(of: filter, { oldValue, newValue in
            filteredGames = filterGames(games, with: filter, sortedBy: currentSorter)
        })
        .navigationTitle("Games")
        .toolbar(content: {
            Button(action: {
                showingSort = !showingSort
            }, label: {
                Text("Sort")
            }).popover(isPresented: $showingSort, arrowEdge: .top, content: {
                VStack(alignment: .leading, spacing: 8.0) {
                    ForEach(sorters) { sorter in
                        Label {
                            Text(sorter.name)
                        } icon: {
                            switch (sorter.enabled, sorter.order) {
                            case (false, _):
                                Image(systemName: "circle")
                            case (true, .forward):
                                Image(systemName: "arrowtriangle.up.circle")
                            case (true, .reverse):
                                Image(systemName: "arrowtriangle.down.circle")
                            }
                        }.onTapGesture {
                            chooseSorter(sorter.id)
                        }
                    }
                }.padding()
                .presentationCompactAdaptation(.popover)
            })
            Button(action: {
                showingFilter = !showingFilter
            }, label: {
                Text("Filter")
            }).popover(isPresented: $showingFilter, arrowEdge: .top, content: {
                FilterView(playersRange: $playerOptions, timeOptions: $timeOptions, filter: $filter)
                    .frame(minWidth: 375.0, minHeight: 360.0, maxHeight: .infinity)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.height(360.0)])
                    .presentationBackgroundInteraction(.enabled)
                    .background(Color(.systemGroupedBackground))
            })
        })
        .task {
            toLoad = collections.count
            let names = collections.map({$0.name}).filter({ !$0.isEmpty })
            for name in names {
                if let collection = await BoardGameGeek.fetchGameCollection(username: name) {
                    toLoad -= 1
                    games.append(collection)
                    totalGames = Set(games.flatMap({ $0.items }).filter({ $0.status?.own == 1 }).map({ $0.id })).count
                    filteredGames = filterGames(games, with: filter, sortedBy: currentSorter)
                    playerOptions = getPlayerOptions(games: games.flatMap({ $0.items }))
                    timeOptions = getTimeOptions(games: games.flatMap({ $0.items }))
                    if toLoad == 0 {
                        addToHistory(names: names)
                    }
                } else {
                    // error?
                    toLoad -= 1
                }
            }
        }
    }

    func chooseSorter(_ id: String) {
        for i in 0..<sorters.count {
            if sorters[i].id == id {
                if sorters[i].enabled {
                    sorters[i].order = sorters[i].order == .reverse ? .forward : .reverse
                } else {
                    sorters[i].enabled = true
                }
            } else {
                sorters[i].enabled = false
            }
        }
        showingSort = false
        filteredGames = filterGames(games, with: filter, sortedBy: currentSorter)
    }
}

private func filterGames(_ collections: [BoardGameGeek.Collection], with filter: GameFilter, sortedBy sorter: GameSorter) -> [BoardGameGeek.Item] {
    guard !collections.isEmpty else {
        return []
    }
    return collections.flatMap({ $0.items }).filter({ filter.matches($0) }).sorted(using: sorter)
}

#Preview {
    NavigationStack {
        GamesView(collections: Binding(get: {[(UUID(uuidString: "2F4A4EE9-D515-40FA-A855-21DD7BA51465")!, "volgar")]}, set: { _ in }))
    }
}
