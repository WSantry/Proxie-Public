import Foundation
import CoreLocation

struct ProxieEvent {
    let friendId: String
    let startTime: Date
    var endTime: Date?
    let startLocation: CLLocationCoordinate2D
    var endLocation: CLLocationCoordinate2D?
}

class ProxieModel {
    static let shared = ProxieModel()
    
    private(set) var proxieHistory: [ProxieEvent] = []
    
    func saveProxie(_ proxie: ProxieEvent) {
        proxieHistory.append(proxie)
    }
}
