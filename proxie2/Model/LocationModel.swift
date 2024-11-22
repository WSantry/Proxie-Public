import Combine
import CoreLocation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class LocationModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userLocation: CLLocationCoordinate2D?
    internal let locationManager = CLLocationManager()
    private let firestore = Firestore.firestore()
    var cancellables = Set<AnyCancellable>()
    private var locationUpdateTimer: Timer?
    
    private var currentProximityZone: ProximityZone = .broad
    
    enum ProximityZone {
        case broad
        case moderate
        case precise
    }
    
    internal override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        Task {
            await requestLocationPermission() // Ensure permission is requested during initialization
        }
        startLocationUpdateListener()
    }

    
    static func createInstance() async -> LocationModel {
        let model = LocationModel()
        await model.requestLocationPermission()
        return model
    }
    
    func requestLocationPermission() async {
        await MainActor.run {
            let status = CLLocationManager.authorizationStatus()

            switch status {
            case .notDetermined:
                // First-time permission request
                locationManager.requestWhenInUseAuthorization()

            case .authorizedWhenInUse:
                // Upgrade to Always Allow
                locationManager.requestAlwaysAuthorization()

            case .authorizedAlways:
                // Already has full permission
                print("Location permissions already granted: Always")

            case .denied, .restricted:
                // Handle denied/restricted state
                print("Location permissions denied or restricted.")
                return

            @unknown default:
                print("Unknown location authorization status.")
            }
        }
    }


    func setUserLocation(_ location: CLLocationCoordinate2D) {
        self.userLocation = location
        updateUserLocationInDatabase(location: location)
    }
    
    private var lastUpdateTimestamp: Date = Date()

    private func updateUserLocationInDatabase(location: CLLocationCoordinate2D) {
        let currentTime = Date()
        let elapsed = currentTime.timeIntervalSince(lastUpdateTimestamp)

        // Rate-limit updates to Firestore (e.g., once every 30 seconds)
        guard elapsed > 30 else { return }

        guard let userId = Auth.auth().currentUser?.uid else { return }
        let locationData: [String: Any] = [
            "currentLocation": GeoPoint(latitude: location.latitude, longitude: location.longitude),
            "lastUpdated": Timestamp(date: currentTime)
        ]

        firestore.collection("users").document(userId).updateData([
            "locationData": locationData
        ]) { error in
            if let error = error {
                print("Error updating user location: \(error.localizedDescription)")
            } else {
                print("User location updated successfully.")
                self.lastUpdateTimestamp = currentTime
            }
        }
    }

    
    internal func updateDesiredAccuracy(_ accuracy: CLLocationAccuracy) {
        locationManager.desiredAccuracy = accuracy
    }
    
    func adjustAccuracyIfNeeded(for distance: CLLocationDistance) {
        let newZone: ProximityZone
        if distance > 1609.34 {
            newZone = .broad
        } else if distance > 750.0 {
            newZone = .moderate
        } else {
            newZone = .precise
        }
        
        if newZone != currentProximityZone {
            switch newZone {
            case .broad:
                updateDesiredAccuracy(kCLLocationAccuracyThreeKilometers)
                locationManager.startMonitoringSignificantLocationChanges()
            case .moderate:
                updateDesiredAccuracy(kCLLocationAccuracyHundredMeters)
                locationManager.startUpdatingLocation()
            case .precise:
                updateDesiredAccuracy(kCLLocationAccuracyNearestTenMeters)
            }
            currentProximityZone = newZone
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        let coordinate = newLocation.coordinate
        self.userLocation = coordinate
        updateUserLocationInDatabase(location: coordinate)
    }
    
    func fetchFriendsLocations(completion: @escaping ([String: CLLocationCoordinate2D]) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion([:])
            return
        }
        
        firestore.collection("users")
            .whereField("privateData.friends", arrayContains: userId)
            .getDocuments { snapshot, error in
                var locations: [String: CLLocationCoordinate2D] = [:]
                if let documents = snapshot?.documents {
                    for document in documents {
                        if let locationData = document.get("locationData") as? [String: Any],
                           let geoPoint = locationData["currentLocation"] as? GeoPoint {
                            let friendId = document.documentID
                            locations[friendId] = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                        }
                    }
                }
                completion(locations)
            }
    }
    
    func setManualLocation(latitude: Double, longitude: Double) {
        self.userLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        updateUserLocationInDatabase(location: self.userLocation!)
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        locationUpdateTimer?.invalidate()
    }
    
    func getDesiredAccuracy() -> CLLocationAccuracy {
        return locationManager.desiredAccuracy
    }
    
    private func startLocationUpdateListener() {
        guard CLLocationManager.authorizationStatus() == .authorizedAlways ||
              CLLocationManager.authorizationStatus() == .authorizedWhenInUse else {
            print("Location permissions not granted.")
            return
        }

        // Start updating location
        locationManager.startUpdatingLocation()

        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            guard let self = self, let location = self.locationManager.location?.coordinate else {
                print("No location available yet.")
                return
            }
            self.updateUserLocationInDatabase(location: location)
        }
    }


    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            print("Authorization not determined yet.")
        case .authorizedWhenInUse:
            print("Authorized When In Use. Requesting Always Authorization...")
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            print("Authorized Always. Location services fully enabled.")
        case .denied:
            print("Authorization denied.")
        case .restricted:
            print("Authorization restricted.")
        @unknown default:
            print("Unknown authorization status.")
        }
    }

}
