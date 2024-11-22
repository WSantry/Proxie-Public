import XCTest
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import CoreLocation
@testable import proxie2

final class ProxieMapViewProximityTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false

        // Initialize Firebase directly in the test environment
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("Firebase configured in test setup")
        }
        
        let app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
    }

    override func tearDownWithError() throws {
        // Sign out after test if needed
        try Auth.auth().signOut()
    }

    @MainActor
    func testMapViewShowsUserAndFriendWithinProximity() throws {
        let app = XCUIApplication()
        app.launch()

        // Step 1: Authenticate as user1@fakemail.com
        signInTestAccount()

        // Step 2: Manually set locations for fake1 and fake2 within 400 feet
        let Fake1Location = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let e2Location = CLLocationCoordinate2D(latitude: 37.7752, longitude: -122.4188) // 400 feet away

        // Wait for authentication and map loading
        XCTAssertTrue(app.maps.element.waitForExistence(timeout: 10), "Map view should load after authentication.")
        
        // Step 3: Use the MapController's method to set mock locations
        let mapController = MapController(
            locationModel: LocationModel(),
            firestore: Firestore.firestore(),
            notificationController: NotificationController.shared
        )
        
        // Setting locations for the test
        mapController.locationModel.setManualLocation(latitude: Fake1Location.latitude, longitude: Fake1Location.longitude)
       // mapController.updateFriendsLocation(for: "fake2", to: fakee2Location)

        // Step 4: Verify that both user and friend annotations appear on the map
        let userAnnotation = app.maps.otherElements["UserLocation"]
        let friendAnnotation = app.maps.otherElements["fake2"]

        XCTAssertTrue(userAnnotation.exists, "User location should be visible on the map.")
        XCTAssertTrue(friendAnnotation.exists, "Friend fake2 should be visible on the map within proximity.")
    }
    
    // Helper method to sign in as user1@fakemail.com for testing
    private func signInTestAccount() {
        let expectation = self.expectation(description: "Sign in with user1@fakemail.com")
        
        Auth.auth().signIn(withEmail: "user1@fakemail.com", password: "<PASSWORD>") { authResult, error in
            if let error = error {
                XCTFail("Failed to sign in: \(error.localizedDescription)")
                expectation.fulfill()
                return
            }
            XCTAssertNotNil(authResult, "Authentication should succeed for user1@fakemail.com")
            print("Authenticated with Firebase as user1@fakemail.com")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
}
