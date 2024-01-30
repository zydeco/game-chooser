import Foundation
import XMLCoder

struct BoardGameGeek {
    struct Item: Decodable, Identifiable {
        var objectid: Int
        var id: Int { return 1000000 * self.objectid + self.collid }
        var subtype: String
        var collid: Int
        var name: String
        var yearpublished: Int?
        var image: URL?
        var thumbnail: URL?
        var stats: Stats?
        var status: Status?
        var numplays: Int = 0

        struct Stats: Decodable {
            var minplayers: Int?
            var maxplayers: Int?
            var minplaytime: Int?
            var maxplaytime: Int?
            var playingtime: Int?
            var numowned: Int?

            var rating: Rating?

            struct Rating: Decodable {
                var value: Decimal?
                var usersRated: Int?
                var average: Decimal?
                var bayesAverage: Decimal?
                var stdDev: Decimal?
                var median: Decimal?
                var ranks: [Rank] = []

                private struct Value<T>: Decodable where T:Decodable {
                    var value: T?
                }

                enum CodingKeys: String, CodingKey {
                    case value = "value"
                    case average = "average"
                    case usersRated = "usersrated"
                    case bayesAverage = "bayesaverage"
                    case stdDev = "stddev"
                    case median = "median"
                    case ranks = "ranks"
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.value = try? container.decodeIfPresent(Decimal.self, forKey: .value)
                    self.usersRated = try? container.decodeIfPresent(Value<Int>.self, forKey: .usersRated).flatMap({$0.value})
                    self.average = try? container.decodeIfPresent(Value<Decimal>.self, forKey: .average).flatMap({$0.value})
                    self.bayesAverage = try? container.decodeIfPresent(Value<Decimal>.self, forKey: .bayesAverage).flatMap({$0.value})
                    self.stdDev = try? container.decodeIfPresent(Value<Decimal>.self, forKey: .stdDev).flatMap({$0.value})
                    self.median = try? container.decodeIfPresent(Value<Decimal>.self, forKey: .median).flatMap({$0.value})
                    if let ranks = try? container.decodeIfPresent(Ranks.self, forKey: .ranks) {
                        self.ranks = ranks.ranks
                    }
                }

                init(value: Decimal? = nil, average: Decimal? = nil) {
                    self.value = value
                    self.average = average
                }

                private func maybeDecimalValue(_ container: KeyedDecodingContainer<CodingKeys>) -> Decimal? {
                    guard let stringValue = try? container.decodeIfPresent(String.self, forKey: CodingKeys.value) else {
                        return nil
                    }
                    return Decimal(string: stringValue, locale: Locale(identifier: "en_US"))
                }

                struct Rank: Decodable {
                    var type: String?
                    var id: String?
                    var name: String?
                    var friendlyName: String?
                    var value: Double?
                    var bayesAverage: Double?

                    enum CodingKeys: String, CodingKey {
                        case type = "type"
                        case id = "id"
                        case name = "name"
                        case friendlyName = "friendlyname"
                        case value = "value"
                        case bayesAverage = "bayesaverage"
                    }

                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.type = try container.decodeIfPresent(String.self, forKey: .type)
                        self.id = try container.decodeIfPresent(String.self, forKey: .id)
                        self.name = try container.decodeIfPresent(String.self, forKey: .name)
                        self.friendlyName = try container.decodeIfPresent(String.self, forKey: .friendlyName)
                        self.value = try? container.decodeIfPresent(Double.self, forKey: .value)
                        self.bayesAverage = try? container.decodeIfPresent(Double.self, forKey: .bayesAverage)
                    }
                }

                private struct Ranks: Decodable {
                    var ranks: [Rank] = []
                    enum CodingKeys: String, CodingKey {
                        case ranks = "rank"
                    }
                }
            }
        }

        struct Status: Codable {
            var own: Int = 0
            var prevowned: Int = 0
            var fortrade: Int = 0
            var want: Int = 0
            var wanttoplay: Int = 0
            var wanttobuy: Int = 0
            var wishlist: Int = 0
            var preordered: Int = 0
            var lastmodified: String?
        }
    }

    struct Collection: Decodable {
        var items: [Item] = []

        enum CodingKeys: String, CodingKey {
            case items = "item"
        }
    }

    static func fetchGameCollection(username: String, withBackoff backoff: Duration = .seconds(0.5)) async -> BoardGameGeek.Collection? {
        guard let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), !username.isEmpty else {
            return nil
        }
        let url = URL(string: "https://boardgamegeek.com/xmlapi2/collection?username=\(encodedUsername)&excludesubtype=boardgameexpansion&stats=1")!
        let session = URLSession.shared
        let request = URLRequest(url: url)
        do {
            let (data, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 202:
                    try! await Task.sleep(for: backoff)
                    return await fetchGameCollection(username: username, withBackoff: backoff*2)
                case 200:
                    if let collection = try? XMLDecoder().decode(Collection.self, from: data) {
                        return collection
                    } else {
                        return nil
                    }
                default:
                    return nil
                }
            } else {
                fatalError("response was not http")
            }
        } catch {
            return nil
        }
    }
}
