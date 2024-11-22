import XCTest
import CoreLocation
import Firebase
@testable import proxie2
import FirebaseAuth

class PopupMapControllerTests: XCTestCase {
    var popupMapController: PopupMapController!

    override func setUp() {
        super.setUp()
        popupMapController = PopupMapController()
        
        // Configure Firebase if not already configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Sign in with the test account
        let expectation = self.expectation(description: "Sign in")
        Auth.auth().signIn(withEmail: "user1@fakemail.com", password: "A<PASSWORD>") { authResult, error in
            if let error = error {
                XCTFail("Sign-in failed: \(error.localizedDescription)")
            } else {
                XCTAssertNotNil(authResult, "Auth result should not be nil after sign-in")
                print("Signed in successfully")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    override func tearDown() {
        do {
            try Auth.auth().signOut()
            print("Signed out successfully")
        } catch {
            print("Sign-out failed: \(error.localizedDescription)")
        }
        popupMapController = nil
        super.tearDown()
    }

    func testFetchStartAndEndLocations() {
        let expectation = self.expectation(description: "Fetch start and end locations")
        let testDocumentId = "DkgxCWTJyIaNjmIorC4g" // Provided document ID
        let testUserId = Auth.auth().currentUser?.uid ?? "UnknownUserID"

        popupMapController.fetchStartAndEndLocations(for: testDocumentId, userId: testUserId) { startLocation, endLocation in
            XCTAssertNotNil(startLocation, "Start location should not be nil")
            XCTAssertNotNil(endLocation, "End location should not be nil")

            if let start = startLocation, let end = endLocation {
                print("Test Start Location: \(start), Test End Location: \(end)")
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testCalculateDistance() {
        let start = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060) // Example: New York City
        let end = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)  // Example: Los Angeles

        let distance = popupMapController.calculateDistance(from: start, to: end)
        print("Test calculated distance: \(distance) km")

        XCTAssert(distance > 0, "Distance should be greater than 0")
    }
}
