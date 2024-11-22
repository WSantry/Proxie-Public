import SwiftUI
import Combine
import MapKit
import CoreLocation
import FirebaseFirestore
import FirebaseAuth

let placeholderEndTime = Timestamp(date: Date(timeIntervalSince1970: 4102444800))

extension CLLocationCoordinate2D {
    /// Calculates the distance (in meters) to another `CLLocationCoordinate2D`.
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2)
    }
}

@MainActor
class MapController: ObservableObject {
    @Published var region: MKCoordinateRegion
    @Published var isLoading: Bool = true
    @Published var friendLocations: [String: CLLocationCoordinate2D] = [:]
    @Published var isLockedToUserLocation = true // New property
    internal var locationModel: LocationModel
    internal let firestore: Firestore
    internal var notificationController: NotificationControllerProtocol

    var friendLocationsList: [FriendLocation] {
        guard let userLocation = locationModel.userLocation else { return [] }
        return friendLocations.compactMap { (key, value) in
            let distance = userLocation.distance(to: value)
            return distance <= preciseProximityRadius ? FriendLocation(id: key, coordinate: value, username: key) : nil
        }
    }

    internal var userMovedMap = false
    internal let broadProximityRadius: CLLocationDistance = 1609.34
    internal let preciseProximityRadius: CLLocationDistance = 750.0

    init(locationModel: LocationModel, firestore: Firestore = Firestore.firestore(), notificationController: NotificationControllerProtocol = NotificationController.shared) {
        self.locationModel = locationModel
        self.firestore = firestore
        self.notificationController = notificationController
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        setupLocationListener()
        startListeningToFriendLocations()
    }

    func setupLocationListener() {
        Task {
            await locationModel.requestLocationPermission()
        }

        locationModel.$userLocation
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] location in
                guard let self = self else { return }

                if self.isLockedToUserLocation {
                    self.smoothlyUpdateRegion(to: location) // Smoothly update region
                }

                self.isLoading = false
                self.updateUserLocationInDatabase(location: location)
                self.checkFriendProximity(for: location)
            }
            .store(in: &locationModel.cancellables)
    }

    func smoothlyUpdateRegion(to location: CLLocationCoordinate2D) {
        let currentSpan = region.span
        let newRegion = MKCoordinateRegion(center: location, span: currentSpan)
        withAnimation(.easeInOut(duration: 0.3)) { // Smooth animation
            self.region = newRegion
        }
    }

    func snapToUserLocation() {
        if let userLocation = locationModel.userLocation {
            smoothlyUpdateRegion(to: userLocation) // Smoothly snap to location
            self.isLockedToUserLocation = true
            self.userMovedMap = false
        }
    }

    func setUserMovedMap() {
        self.userMovedMap = true
        self.isLockedToUserLocation = false // Unlock dynamic lock
    }

    
    static func createInstance() async -> MapController {
        let locationModel = await LocationModel.createInstance()
        return MapController(locationModel: locationModel)
    }
    
   
    
    func startListeningToFriendLocations() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        firestore.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            guard let document = document, document.exists else { return }
            
            self.firestore.collection("users")
                .whereField("privateData.friends", arrayContains: userId)
                .getDocuments { snapshot, error in
                    guard let snapshot = snapshot else {
                        print("Error fetching friends' locations: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    var locations: [String: CLLocationCoordinate2D] = [:]
                    
                    for document in snapshot.documents {
                        if let locationData = document.get("locationData") as? [String: Any],
                           let geoPoint = locationData["currentLocation"] as? GeoPoint,
                           let username = document.get("username") as? String { // Fetch username
                            locations[username] = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude) // Use username as key
                        }
                    }
                    self.friendLocations = locations
                }
        }
    }
    
    func updateUserLocationInDatabase(location: CLLocationCoordinate2D) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let locationData: [String: Any] = [
            "currentLocation": GeoPoint(latitude: location.latitude, longitude: location.longitude),
            "lastUpdated": Timestamp(date: Date())
        ]
        
        firestore.collection("users").document(userId).updateData([
            "locationData": locationData
        ]) { error in
            if let error = error {
                print("Error updating user location: \(error.localizedDescription)")
            } else {
                print("User location updated successfully.")
            }
        }
    }
    
    func checkFriendProximity(for userLocation: CLLocationCoordinate2D) {
        for (friendId, friendLocation) in friendLocations {
            let distance = userLocation.distance(to: friendLocation)
            print("Checking proximity for friendId \(friendId): Distance \(distance)")
            self.updateAccuracyBasedOnProximity(to: friendLocation)
            
            switch distance {
            case ...preciseProximityRadius:
                self.notifyAndRecordProxie(with: friendId, at: friendLocation)
            case preciseProximityRadius..<broadProximityRadius:
                continue
            case broadProximityRadius...:
                self.endProxie(for: friendId)
            default:
                break
            }
        }
    }
    
 internal func notifyAndRecordProxie(with friendId: String, at location: CLLocationCoordinate2D) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Debug: User is not signed in.")
            return
        }
        let startTime = Date()
        // Check for ongoing events in the user's proxieEvents subcollection
        firestore.collection("users").document(userId).collection("proxieEvents")
            .whereField("friendId", isEqualTo: friendId)
            .whereField("endTime", isEqualTo: placeholderEndTime) // Check for ongoing event
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Debug: Error fetching existing proxie events: \(error.localizedDescription)")
                    return
                }
                if let documents = snapshot?.documents, !documents.isEmpty {
                    print("Debug: Ongoing proxie event found, not creating a new event.")
                    return
                }
                // No ongoing event, create a new one with placeholder end time
                let data: [String: Any] = [
                    "friendId": friendId,
                    "userId": userId,
                    "startLocation": GeoPoint(latitude: location.latitude, longitude: location.longitude),
                    "startTime": Timestamp(date: startTime),
                    "endTime": placeholderEndTime
                ]
                // Save to the signed-in user's proxieEvents subcollection
                self.firestore.collection("users").document(userId).collection("proxieEvents").addDocument(data: data) { error in
                    if error == nil {
                        print("Debug: Proxie event created in user’s subcollection with startTime \(startTime) for friendId \(friendId).")
                        self.notificationController.sendProximityNotification(for: friendId) { success in
                            print("Debug: Notification \(success ? "sent" : "failed") for friendId: \(friendId)")
                        }
                    } else {
                        print("Debug: Error creating proxie event in user’s subcollection for friendId \(friendId): \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
                // Also add the same event to the friend's proxieEvents subcollection, but flip userId and friendId
                let flippedData: [String: Any] = [
                    "friendId": userId, // Flip IDs
                    "userId": friendId,
                    "startLocation": GeoPoint(latitude: location.latitude, longitude: location.longitude),
                    "startTime": Timestamp(date: startTime),
                    "endTime": placeholderEndTime
                ]
                // Retrieve the friend's user document and save to their proxieEvents subcollection
                self.firestore.collection("users").document(friendId).collection("proxieEvents").addDocument(data: flippedData) { error in
                    if error == nil {
                        print("Debug: Flipped proxie event created in friend’s subcollection with startTime \(startTime) for userId \(userId).")
                    } else {
                        print("Debug: Error creating flipped proxie event in friend’s subcollection for userId \(userId): \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
    }


    internal func endProxie(for friendId: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Debug: User is not signed in.")
            return
        }
        let endTime = Date()
        let endLocation = GeoPoint(latitude: self.region.center.latitude, longitude: self.region.center.longitude)
        // Access the signed-in user's proxieEvents sub-collection to update the end time
        firestore.collection("users").document(userId).collection("proxieEvents")
            .whereField("friendId", isEqualTo: friendId)
            .whereField("endTime", isEqualTo: placeholderEndTime) // Look for events with placeholder end time
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("Debug: No ongoing proxie event found to end for friendId \(friendId).")
                    return
                }
                for document in documents {
                    document.reference.updateData([
                        "endTime": Timestamp(date: endTime),
                        "endLocation": endLocation
                    ]) { error in
                        if let error = error {
                            print("Error updating end time/location for proxie event in user's subcollection: \(error.localizedDescription)")
                        } else {
                            print("Debug: Successfully ended proxie event for friendId: \(friendId) with endTime \(endTime) in user's subcollection.")
                        }
                    }
                }
            }
        // Access the friend's proxieEvents sub-collection to update the end time
        firestore.collection("users").document(friendId).collection("proxieEvents")
            .whereField("friendId", isEqualTo: userId) // Flip the friendId to match the friend’s view
            .whereField("endTime", isEqualTo: placeholderEndTime) // Look for events with placeholder end time
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("Debug: No ongoing proxie event found to end for userId \(userId) in friend's subcollection.")
                    return
                }
                for document in documents {
                    document.reference.updateData([
                        "endTime": Timestamp(date: endTime),
                        "endLocation": endLocation
                    ]) { error in
                        if let error = error {
                            print("Error updating end time/location for proxie event in friend's subcollection: \(error.localizedDescription)")
                        } else {
                            print("Debug: Successfully ended proxie event for userId \(userId) with endTime \(endTime) in friend's subcollection.")
                        }
                    }
                }
            }
    }


    
 
    
    func updateAccuracyBasedOnProximity(to friendLocation: CLLocationCoordinate2D) {
        let userLocation = locationModel.userLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let distance = userLocation.distance(to: friendLocation)
        
        switch distance {
        case let d where d > 16093.4:
            locationModel.updateDesiredAccuracy(kCLLocationAccuracyThreeKilometers)
            locationModel.stopUpdatingLocation()
        case 1609.34...16093.4:
            locationModel.updateDesiredAccuracy(kCLLocationAccuracyKilometer)
        case 100...1609.34:
            locationModel.updateDesiredAccuracy(kCLLocationAccuracyHundredMeters)
        default:
            locationModel.updateDesiredAccuracy(kCLLocationAccuracyNearestTenMeters)
        }
    }
}

