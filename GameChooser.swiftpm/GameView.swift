import SwiftUI

struct GameView: View {
    @Environment(\.openURL) var openURL
    @ScaledMetric var iconWidth: CGFloat = 30.0

    var game: BoardGameGeek.Item
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Text(verbatim: game.name)
                    .font(.title)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                // stats
                HStack {
                    AsyncImage(url: game.image) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Color.gray.aspectRatio(1.0, contentMode: .fill)
                    }.frame(width: 140, height: 140)

                    Spacer()
                    VStack(alignment: .leading) {
                        if let rating = game.stats?.rating?.average {
                            HStack {
                                Image(systemName: "star.fill")
                                    .frame(width: iconWidth)
                                Text(rating.formatted(.number.precision(.significantDigits(2))))
                            }
                        }
                        if let year = game.yearpublished {
                            HStack {
                                Image(systemName: "calendar")
                                    .frame(width: iconWidth)
                                Text("\(year, format: .number.grouping(.never))")
                            }
                        }
                        if let min = game.stats?.minplayers, let max = game.stats?.maxplayers {
                            HStack {
                                Image(systemName: max == 1 ? "person" : max == 2 ? "person.2" : "person.3")
                                    .frame(width: iconWidth)
                                if min == max {
                                    Text("\(min)")
                                } else {
                                    Text("\(min) to \(max)")
                                }
                            }

                        }
                        if let min = game.stats?.minplaytime, let max = game.stats?.maxplaytime {
                            HStack {
                                Image(systemName: "clock")
                                    .frame(width: iconWidth)
                                if min == max {
                                    Text(formatMinutes(min))
                                } else {
                                    Text("\(formatMinutes(min))–\(formatMinutes(max))")
                                }
                            }
                        }
                    }
                    Spacer()
                }
                .font(.title3)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            }.onTapGesture {
                if let gameUrl = URL(string: "https://boardgamegeek.com/boardgame/\(game.objectid)") {
                    openURL(gameUrl)
                }
            }
            Spacer()
        }
    }
}

#Preview {
    GameView(game:
                BoardGameGeek.Item(
                    objectid: 1234,
                    subtype: "boardgame",
                    collid: 1234,
                    name: "Agricola: Animales en la Granja",
                    yearpublished: 1948,
                    image: URL(string: "https://cf.geekdo-images.com/7CafFqXeChNv225PJc7a6Q__original/img/gJUzUAe7dzNqHnFzW2ZYER2WpkQ=/0x0/filters:format(jpeg)/pic1287062.jpg")!,
                    stats: BoardGameGeek.Item.Stats(
                        minplayers: 2,
                        maxplayers: 2,
                        minplaytime: 30,
                        maxplaytime: 60,
                        rating: BoardGameGeek.Item.Stats.Rating(average: 8.5)
                        )
                    )
             )
}
