import XCTest
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import CoreLocation
@testable import proxie2

class FirestoreCommunicationTests: XCTestCase {
    var mapController: MapController!
    var db: Firestore!
    
    override func setUp() async throws {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("Firebase initialized for Firestore communication testing.")
        }
        
        db = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = false
        db.settings = settings
        print("Firestore persistence disabled for this test.")
        
        
        mapController = await createMapControllerWithMocks()
    }
    
    override func tearDown() async throws {
        mapController = nil
        db = nil
        print("Tear down completed: Firestore and MapController deinitialized.")
    }
    
    // Factory method to create a MapController with MockLocationModel and MockNotificationController
    func createMapControllerWithMocks() async -> MapController {
        let mockLocationModel = await MockLocationModel()
        let mockNotificationController = MockNotificationController()
        return await MapController(locationModel: mockLocationModel, notificationController: mockNotificationController)
    }
    
    // Mock subclass of LocationModel to override fetchFriendsLocations
    class MockLocationModel: LocationModel {
        var mockFriendId: String?
        var mockFriendLocation: CLLocationCoordinate2D?
        
        override init() {
            super.init()
        }
        
        func configureMock(friendId: String, friendLocation: CLLocationCoordinate2D) async {
            self.mockFriendId = friendId
            self.mockFriendLocation = friendLocation
        }
        
        override func fetchFriendsLocations(completion: @escaping ([String: CLLocationCoordinate2D]) -> Void) {
            guard let friendId = mockFriendId, let location = mockFriendLocation else {
                completion([:])
                return
            }
            completion([friendId: location])
            print("Debug: Mocked friend location set for proximity test.")
        }
    }
    
    // Mock subclass of NotificationController to override notification behavior
    class MockNotificationController: NotificationControllerProtocol {
        var notificationSent = false
        var sentFriendId: String?
        
        func sendProximityNotification(for friendId: String, completion: @escaping (Bool) -> Void) {
            notificationSent = true
            sentFriendId = friendId
            completion(true)
        }
    }
    
    // MARK: - Firestore Communication Tests
    
    func testFirestoreWriteAndRead() async throws {
        try await Auth.auth().signIn(withEmail: "user1@fakemail.com", password: "<PASSWORD>")
        print("Authenticated with Firebase as user1@fakemail.com for testing Firestore communication.")
        
        let testDocID = "testDoc_\(UUID().uuidString)"
        let testData: [String: Any] = [
            "username": "TestUser",
            "email": "testuser@example.com",
            "profilePictureMonster": "monster_1",
            "JoinDate": Timestamp(date: Date())
        ]
        
        let writeExpectation = expectation(description: "Write test document to Firestore")
        Firestore.firestore().collection("users").document(testDocID).setData(testData) { error in
            if let error = error {
                XCTFail("Error writing test document: \(error)")
                print("Debug: Firestore write error - \(error)")
            } else {
                print("Debug: Successfully wrote test document with ID \(testDocID)")
            }
            writeExpectation.fulfill()
        }
        
        wait(for: [writeExpectation], timeout: 5)
        
        let readExpectation = expectation(description: "Read back test document from Firestore")
        Firestore.firestore().collection("users").document(testDocID).getDocument { document, error in
            if let error = error {
                XCTFail("Error reading test document: \(error)")
                print("Debug: Firestore read error - \(error)")
            } else if let document = document, document.exists {
                let data = document.data()
                print("Debug: Read back document data: \(data ?? [:])")
                XCTAssertEqual(data?["username"] as? String, "TestUser", "Username should match 'TestUser'")
            } else {
                XCTFail("Document not found after writing")
            }
            readExpectation.fulfill()
        }
        
        wait(for: [readExpectation], timeout: 5)
    }
    
    func testListCollections() async throws {
        // Ensure the user is signed in for Firestore access
        try await Auth.auth().signIn(withEmail: "user1@fakemail.com", password: "<PASSWORD>")
        print("Authenticated with Firebase as user1@fakemail.com for listing collections.")
        // Define known collections to check
        let collectionsToCheck = ["users", "messages", "proxieEvents"]  // Add any other known collection names here
        for collectionName in collectionsToCheck {
            let collectionReference = Firestore.firestore().collection(collectionName)
            let fetchExpectation = expectation(description: "Fetch documents in \(collectionName) collection")
            collectionReference.getDocuments { snapshot, error in
                if let error = error {
                    XCTFail("Error fetching documents from \(collectionName): \(error)")
                    print("Debug: Error fetching \(collectionName) - \(error)")
                } else {
                    print("Documents in \(collectionName):")
                    for document in snapshot?.documents ?? [] {
                        print(" - \(document.documentID): \(document.data())")
                    }
                    if snapshot?.documents.isEmpty == true {
                        print("No documents found in \(collectionName) collection.")
                    }
                }
                fetchExpectation.fulfill()
            }
            
            // Wait for fetch operation to complete for each collection
            wait(for: [fetchExpectation], timeout: 5)
        }
    }
    
    func testFetchUsersCollectionDocuments() async throws {
        // Sign in with the provided credentials
        try await Auth.auth().signIn(withEmail: "user1@fakemail.com", password: "<PASSWORD>")
        print("Authenticated with Firebase as user1@fakemail.com for accessing the 'users' collection.")
        // Reference the 'users' collection
        let usersCollectionRef = Firestore.firestore().collection("users")
        let fetchExpectation = expectation(description: "Fetch documents in 'users' collection")
        // Fetch and print documents in 'users' collection
        usersCollectionRef.getDocuments { snapshot, error in
            if let error = error {
                XCTFail("Error fetching documents from 'users': \(error)")
                print("Debug: Error fetching 'users' collection - \(error)")
            } else {
                print("Documents in 'users' collection:")
                for document in snapshot?.documents ?? [] {
                    print(" - \(document.documentID): \(document.data())")
                }
                if snapshot?.documents.isEmpty == true {
                    print("No documents found in 'users' collection.")
                }
            }
            fetchExpectation.fulfill()
        }
        // Wait for fetch operation to complete
        wait(for: [fetchExpectation], timeout: 5)
    }
    
    func testCreateProxieEvent() async throws {
        // Sign in as fake
        try await Auth.auth().signIn(withEmail: "user1@fakemail.com", password: "<PASSWORD>")
        print("Authenticated with Firebase as user1@fakemail.com to create a Proxie Event.")
        
        // Fetch fake's document ID from the 'users' collection
        let fetchExpectation = expectation(description: "Fetch fake's document ID")
        var friendId: String?
        
        Firestore.firestore().collection("users").whereField("username", isEqualTo: "fakeUser").getDocuments { snapshot, error in
            if let error = error {
                XCTFail("Error fetching fake's document ID: \(error)")
                print("Debug: Firestore query error - \(error)")
            } else if let document = snapshot?.documents.first {
                friendId = document.documentID
                print("Debug: Found fake's document ID: \(friendId ?? "None")")
            } else {
                XCTFail("No document found for user1@fakemail.com")
                print("Debug: No document found for user1@fakemail.com")
            }
            fetchExpectation.fulfill()
        }
        
        // Wait for the fetch operation to complete
        wait(for: [fetchExpectation], timeout: 5)
        
        // Ensure we have a valid friendId for fake
        guard let actualFriendId = friendId else {
            XCTFail("Failed to retrieve fake's document ID")
            return
        }
        
        // Define the test data for the proxie event
        let startLocation = GeoPoint(latitude: 37.7749, longitude: -122.4194)
        let endLocation = startLocation
        let startTime = Timestamp(date: Date())
        let endTime = Timestamp(date: Date().addingTimeInterval(60)) // 1 minute later
        let userId = Auth.auth().currentUser?.uid ?? ""
        
        let proxieData: [String: Any] = [
            "startLocation": startLocation,
            "endLocation": endLocation,
            "startTime": startTime,
            "endTime": endTime,
            "friendId": actualFriendId,
            "userId": userId
        ]
        
        // Write to proxieEvents subcollection within the user's document
        let writeExpectation = expectation(description: "Write new Proxie Event document to Firestore")
        Firestore.firestore().collection("users").document(userId).collection("proxieEvents").addDocument(data: proxieData) { error in
            if let error = error {
                XCTFail("Failed to create Proxie Event: \(error)")
                print("Debug: Firestore write error - \(error)")
            } else {
                print("Debug: Successfully created Proxie Event in 'proxieEvents' subcollection.")
            }
            writeExpectation.fulfill()
        }
        
        // Wait for the write operation to complete
        wait(for: [writeExpectation], timeout: 5)
    }

    
    func testProximityEventLifecycle() async throws {
        // Arrange: Configure mock location model and authenticate
        let mockLocationModel = await mapController.locationModel as! MockLocationModel
        let mockNotificationController = await mapController.notificationController as! MockNotificationController
        try await Auth.auth().signIn(withEmail: "user1@fakemail.com", password: "<PASSWORD>")
        print("Authenticated with Firebase as user1@fakemail.com for testing proximity event lifecycle.")

        let friendId = "FeQvomW1kvgu9r7nzYTVx3p0CyT2"
        let initialLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let proximateLocation = CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195) // Within 750 feet

        // Step 1: Set initial locations outside proximity range (2 miles apart)
        await mockLocationModel.configureMock(friendId: friendId, friendLocation: initialLocation)
        await mapController.locationModel.setManualLocation(latitude: 37.7587, longitude: -122.4376) // User's location 2 miles away

        // Step 2: Move friend to within proximity range
        await mockLocationModel.configureMock(friendId: friendId, friendLocation: proximateLocation)
        await mapController.locationModel.setManualLocation(latitude: 37.7750, longitude: -122.4195) // User moves closer

        // Step 3: Wait for 20 seconds to simulate time in proximity
        try await Task.sleep(nanoseconds: 20_000_000_000) // 20 seconds

        // Assert: Verify notification was sent for entering proximity the first time
        XCTAssertTrue(mockNotificationController.notificationSent, "Notification should have been sent upon entering proximity.")
        XCTAssertEqual(mockNotificationController.sentFriendId, friendId, "Notification should be for the specified friend ID.")
        mockNotificationController.notificationSent = false // Reset for next proximity check

        // Step 4: Move user back outside proximity range
        await mapController.locationModel.setManualLocation(latitude: 37.7587, longitude: -122.4376)

        // Step 5: Wait for 20 seconds to simulate time out of proximity
        try await Task.sleep(nanoseconds: 20_000_000_000) // 20 seconds

        // Step 6: Move back into proximity range again
        await mockLocationModel.configureMock(friendId: friendId, friendLocation: proximateLocation)
        await mapController.locationModel.setManualLocation(latitude: 37.7750, longitude: -122.4195)

        // Step 7: Wait for 20 seconds to simulate time in proximity again
        try await Task.sleep(nanoseconds: 20_000_000_000) // 20 seconds

        // Assert: Verify notification was sent again for the second proximity event
        XCTAssertTrue(mockNotificationController.notificationSent, "Notification should have been sent upon entering proximity the second time.")
        XCTAssertEqual(mockNotificationController.sentFriendId, friendId, "Notification should be for the specified friend ID.")
        mockNotificationController.notificationSent = false // Reset for future tests if needed

        // Step 8: Move user outside proximity range again to end the second event
        await mapController.locationModel.setManualLocation(latitude: 37.7587, longitude: -122.4376)

        // Wait briefly to allow the final event to record the end time
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second to ensure Firestore write

        // Assert: Verify that two complete proxie events are recorded in Firestore
        let proxieEventsRef = db.collection("proxieEvents")
        
        // Query for documents with the specified friendId and completed lifecycle (2 events)
        let querySnapshot = try await proxieEventsRef
            .whereField("friendId", isEqualTo: friendId)
            .whereField("userId", isEqualTo: Auth.auth().currentUser?.uid ?? "")
            .whereField("endTime", isNotEqualTo: placeholderEndTime) // Filter for completed events
            .getDocuments()
        
        XCTAssertEqual(querySnapshot.documents.count, 2, "There should be two proxie events created and ended correctly.")
        
        // Optional: Additional assertions to check the timings if needed
        for document in querySnapshot.documents {
            let data = document.data()
            if let startTime = data["startTime"] as? Timestamp, let endTime = data["endTime"] as? Timestamp {
                print("Proxie Event - Start: \(startTime.dateValue()), End: \(endTime.dateValue())")
                XCTAssertTrue(endTime.dateValue() > startTime.dateValue(), "End time should be after start time.")
            }
        }
    }
    
    func testLocationAccuracyBasedOnVariousDistances() async throws {
        // Arrange: Configure mock location model and authenticate
        let mockLocationModel = await mapController.locationModel as! MockLocationModel
        try await Auth.auth().signIn(withEmail: "user1@fakemail.com", password: "<PASSWORD>")
        print("Authenticated with Firebase as user1@fakemail.com for testing location accuracy based on various distances.")

        let userLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        await mapController.locationModel.setManualLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)

        // Define test cases with different distances and expected accuracies
        let testCases: [(friendLocation: CLLocationCoordinate2D, expectedAccuracy: CLLocationAccuracy, description: String)] = [
            (
                friendLocation: CLLocationCoordinate2D(latitude: userLocation.latitude + (80.4672 / 111.32), longitude: userLocation.longitude),
                expectedAccuracy: kCLLocationAccuracyThreeKilometers,
                description: "Friend is 50 miles away"
            ),
            (
                friendLocation: CLLocationCoordinate2D(latitude: userLocation.latitude + (8.04672 / 111.32), longitude: userLocation.longitude),
                expectedAccuracy: kCLLocationAccuracyKilometer,
                description: "Friend is 5 miles away"
            ),
            (
                friendLocation: CLLocationCoordinate2D(latitude: userLocation.latitude + (0.540 / 111.32), longitude: userLocation.longitude),
                expectedAccuracy: kCLLocationAccuracyHundredMeters,
                description: "Friend is 600 meters away"
            ),
            (
                friendLocation: userLocation,
                expectedAccuracy: kCLLocationAccuracyNearestTenMeters,
                description: "Friend is at the same location as the user"
            )
        ]
        
        for testCase in testCases {
            // Act: Set the friend's mock location and update proximity accuracy
            await mockLocationModel.configureMock(friendId: "testFriendId", friendLocation: testCase.friendLocation)
            await mapController.checkFriendProximity(for: userLocation)
            
            // Assert: Check that the desired accuracy matches the expected value
            let actualAccuracy = await mapController.locationModel.getDesiredAccuracy()
            XCTAssertEqual(
                actualAccuracy,
                testCase.expectedAccuracy,
                "Expected accuracy \(testCase.expectedAccuracy) for distance scenario '\(testCase.description)', but got \(actualAccuracy)."
            )
        }
    }

}
