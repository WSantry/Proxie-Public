import FirebaseFirestore
import FirebaseCore
import CoreLocation




class PopupMapController {
    private let db = Firestore.firestore()

    func fetchStartAndEndLocations(for documentId: String, userId: String, completion: @escaping (CLLocationCoordinate2D?, CLLocationCoordinate2D?) -> Void) {
        print("Fetching start and end locations for document ID: \(documentId), user ID: \(userId)")

        db.collection("users").document(userId).collection("proxieEvents").document(documentId).getDocument { document, error in
            if let error = error {
                print("Error fetching document: \(error)")
                completion(nil, nil)
                return
            }

            guard let document = document, document.exists else {
                print("Document does not exist for document ID: \(documentId)")
                completion(nil, nil)
                return
            }

            print("Document fetched successfully: \(documentId)")
            if let data = document.data() {
                print("Document data: \(data)")

                if let startGeoPoint = data["startLocation"] as? GeoPoint {
                    print("Start location GeoPoint found: \(startGeoPoint)")
                } else {
                    print("Start location field is missing or not a GeoPoint for document ID: \(documentId)")
                }

                if let endGeoPoint = data["endLocation"] as? GeoPoint {
                    print("End location GeoPoint found: \(endGeoPoint)")
                } else {
                    print("End location field is missing or not a GeoPoint for document ID: \(documentId)")
                }

                guard let startGeoPoint = data["startLocation"] as? GeoPoint,
                      let endGeoPoint = data["endLocation"] as? GeoPoint else {
                    print("Document missing start or end locations for document ID: \(documentId)")
                    completion(nil, nil)
                    return
                }

                let startLocation = CLLocationCoordinate2D(latitude: startGeoPoint.latitude, longitude: startGeoPoint.longitude)
                let endLocation = CLLocationCoordinate2D(latitude: endGeoPoint.latitude, longitude: endGeoPoint.longitude)
                print("Fetched start location: \(startLocation), end location: \(endLocation)")
                completion(startLocation, endLocation)
            } else {
                print("Document data is nil for document ID: \(documentId)")
                completion(nil, nil)
            }
        }
    }
    
    func calculateDistance(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        print("Calculating distance between start: \(start) and end: \(end)")
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        let distance = startLocation.distance(from: endLocation) / 1000 // Convert distance to kilometers
        print("Calculated distance: \(distance) km")
        return distance
    }

}
