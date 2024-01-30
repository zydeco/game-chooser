import SwiftUI

struct InputView: View {
    static let userIsEmpty: ((id: UUID, name: String)) -> Bool = { user in user.name.isEmpty }
    @State private var collections: [(id: UUID, name: String)] = []
    @FocusState private var focused: UUID?
    @State var history: [HistoryItem] = [] {
        didSet {
            saveHistory(history)
        }
    }

    var body: some View {
        Form {
            Section {
                List($collections, id: \.id, editActions: .delete)  {
                    user in
                    TextField("BGG Username", text: user.name).onSubmit() {
                        compactCollections()
                    }
                    .autocorrectionDisabled()
                    .focused($focused, equals: user.id.wrappedValue)
                }.deleteDisabled(collections.count == 1)
            } header: {
                Text("Collections")
            } footer: {
                HStack {
                    Spacer()
                    Link(destination: URL(string:"https://boardgamegeek.com")!, label: {
                        Image(uiImage: #imageLiteral(resourceName: "bgg")).resizable().scaledToFit().frame(height: 42)
                    })
                    Spacer()
                }
            }

            if !history.isEmpty {
                Section("History") {
                    List($history, id: \.id, editActions: .delete) { $item in
                        NavigationLink {
                            GamesView(collections: Binding(get: {item.asCollections()}, set: { _ in }))
                        } label: {
                            Text(item.names, format: .list(type: .and))
                        }
                    }
                }
            }
        }
        .navigationTitle("Game Chooser")
        .toolbar {
            NavigationLink("Next") {
                GamesView(collections: $collections)
            }.disabled(collections.filter({ !$0.name.isEmpty }).isEmpty)
        }.onAppear() {
            history = loadHistory()
            compactCollections()
        }
    }

    private func compactCollections() {
        // remove all empty
        collections.removeAll(where: { $0.name.isEmpty })
        // but last should be empty
        collections.append((UUID(), ""))
        // and focused
        focused = collections.last?.id
    }
}

#Preview {
    NavigationStack {
        InputView(history: [HistoryItem(id: UUID(), names: ["Volgar"])])
    }
}
