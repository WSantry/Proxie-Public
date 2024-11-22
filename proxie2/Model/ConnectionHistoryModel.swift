import Foundation

struct ConnectionHistory: Identifiable {
    var id: String
    var friendUsername: String
    var startTime: Date
    var startLocation: (latitude: Double, longitude: Double)
    var formattedAddress: String
}
