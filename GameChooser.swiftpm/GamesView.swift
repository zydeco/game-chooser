import SwiftUI
import UIKit

struct GamesView: View {
    // default max age for cached data
    private static let defaultMaxAge: TimeInterval = 86400

    @Binding var collections: [(id: UUID, name: String)]
    @State var games: [BoardGameGeek.Collection] = []
    @State var playerOptions: ClosedRange<Int> = 1...GameFilter.maxPlayers
    @State var timeOptions = [15, 30, 60, 120, 240]
    @State var filteredGames: [BoardGameGeek.Item] = []
    @State var showingSort = false
    @State var showingPlayers = false
    @State var showingTime = false
    @State var filter = GameFilter()
    @State var toLoad = 0
    @State var sorters: [GameSorter] = [
        GameSorter(name: "Name") { $0.name.compare($1.name) },
        GameSorter(name: "BGG Rating", order: .reverse, enabled: true) { compare($0.stats?.rating?.average, $1.stats?.rating?.average, default:.zero) },
        GameSorter(name: "Year Published", order: .reverse) { compare($0.yearpublished, $1.yearpublished, default:.zero) }
        // TODO: best with this number of players
        // TODO: complexity
        // TODO: last played
        // TODO: played often
        ]
    @State var totalGames = 0
    var currentSorter: GameSorter { sorters.first(where: { $0.enabled }) ?? sorters[0] }

    var body: some View {
        // MARK: List
        List {
            Section {
                ForEach(filteredGames) { game in
                    GameView(game: game)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Hide") {
                                filteredGames.removeAll(where: { $0.id == game.id })
                            }.tint(.red)
                        }
                }
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
                    Text("\(filteredGames.count) of \(totalGames) games \(filter.displayDescription ?? "")")
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
        }
        .onChange(of: filter, { oldValue, newValue in
            filteredGames = filterGames(games, with: filter, sortedBy: currentSorter)
        })
        .navigationTitle("Games")
        .toolbar(content: {
            // MARK: Sort
            Button(action: {
                showingSort = !showingSort
            }, label: {
                Image(systemName: "arrowtriangle.\(currentSorter.order == .forward ? "up" : "down").circle")
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

            // MARK: Players
            Button(action: {
                showingPlayers = !showingPlayers
            }, label: {
                Image(systemName: "person.3")
            }).popover(isPresented: $showingPlayers, arrowEdge: .top) {
                VStack(alignment: .leading, spacing: 8.0) {
                    Label {
                        Text("Any")
                    } icon: {
                        Image(systemName: filter.players == nil ? "checkmark.circle" : "circle")
                    }.onTapGesture {
                        filter.players = nil
                        showingPlayers = false
                    }
                    ForEach(playerOptions.filter({ $0 < GameFilter.maxPlayers }).map({ $0 }), id: \.self) { option in
                        Label {
                            Text(option, format: .number.grouping(.never))
                        } icon: {
                            Image(systemName: filter.players == option ? "checkmark.circle" : "circle")
                        }.onTapGesture {
                            filter.players = option
                            showingPlayers = false
                        }
                    }
                    if playerOptions.contains(where: { $0 > GameFilter.maxPlayers }) {
                        Label {
                            Text("\(GameFilter.maxPlayers)+")
                        } icon: {
                            Image(systemName: filter.players == GameFilter.maxPlayers ? "checkmark.circle" : "circle")
                        }.onTapGesture {
                            filter.players = GameFilter.maxPlayers
                            showingPlayers = false
                        }
                    }
                }.padding()
                .presentationCompactAdaptation(.popover)
            }

            // MARK: Time
            Button(action: {
                showingTime = !showingTime
            }, label: {
                Image(systemName: "clock")
            }).popover(isPresented: $showingTime, arrowEdge: .top) {
                TimeFilterChooser(filter: $filter, showingTime: $showingTime, timeOptions: timeOptions)
                    .padding()
                    .presentationCompactAdaptation(.popover)
            }
        })
        .task {
            await loadCollections(maxAge: GamesView.defaultMaxAge)
        }
        .refreshable {
            await loadCollections(maxAge: 0)
        }
        .onAppear {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                scene.screenshotService?.delegate = ScreenshotAdapter.shared
                ScreenshotAdapter.shared.generator = { screenshot($0) }
            }
        }
    }

    private func loadImages(games: [BoardGameGeek.Item]) async -> [Int: CGImage] {
        var images: [Int: CGImage] = [:]
        games.forEach { game in
            if let imageUrl = game.image,
               let data = try? Data(contentsOf: imageUrl)
            {
                if let image = UIImage(data: data) {
                    images[game.id] = image.cgImage
                }
            }
        }
        return images
    }

    func screenshot(_ completionHandler: @escaping (Data?, Int, CGRect) -> Void) {
        Task.detached {
            let images = await loadImages(games: filteredGames)
            DispatchQueue.main.async {
                let result = takeScreenshot(images: images)
                completionHandler(result.0, result.1, result.2)
            }
        }
    }

    @MainActor func takeScreenshot(images: [Int: CGImage]) -> (pdf: Data, page: Int, visibleRect: CGRect) {
        let renderer = ImageRenderer(content: VStack {
            Text("\(filteredGames.count) of \(totalGames) games \(filter.displayDescription ?? "")")

            ForEach(filteredGames) {
                Text("⎯").foregroundStyle(.tertiary)
                GameView(game: $0, image: images[$0.id])
            }

            Image(uiImage: #imageLiteral(resourceName: "bgg")).resizable().scaledToFit().frame(height: 42)
        }
            .frame(width: 430.0)
            .padding()
        )
        let data = CFDataCreateMutable(kCFAllocatorDefault, 0)!
        var pdfRect: CGRect?
        renderer.render { size, context in
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            guard let pdf = CGContext(consumer: CGDataConsumer(data: data)!, mediaBox: &box, nil) else {
                return
            }
            pdfRect = CGRect(x: 0, y: size.height - 2*size.width, width: size.width, height: 2*size.width)
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }

        return (data as Data, 0, pdfRect ?? .zero)
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

    private func loadCollections(maxAge: TimeInterval) async {
        games = []
        toLoad = collections.count
        let names = collections.map({$0.name}).filter({ !$0.isEmpty })
        for name in names {
            if let collection = await BoardGameGeek.fetchGameCollection(username: name, maxAge: maxAge) {
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
