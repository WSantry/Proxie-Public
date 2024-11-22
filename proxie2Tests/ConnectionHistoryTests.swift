import XCTest
import FirebaseAuth
import FirebaseFirestore
@testable import proxie2

class ConnectionHistoryControllerTests: XCTestCase {
    var controller: ConnectionHistoryController!

    override func setUp() {
        super.setUp()
        controller = ConnectionHistoryController()
        print("Setting up test environment")
        signInTestUser()
    }

    override func tearDown() {
        print("Tearing down test environment")
        signOutTestUser()
        controller = nil
        super.tearDown()
    }

    func signInTestUser() {
        print("Attempting to sign in with test user")
        let expectation = self.expectation(description: "Sign in")
        Auth.auth().signIn(withEmail: "user1@fakemail.com", password: "<PASSWORD>") { authResult, error in
            if let error = error {
                XCTFail("Failed to sign in: \(error.localizedDescription)")
                print("Sign in failed: \(error.localizedDescription)")
            } else {
                print("Sign in successful. User ID: \(authResult?.user.uid ?? "No UID")")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func signOutTestUser() {
        print("Attempting to sign out")
        do {
            try Auth.auth().signOut()
            print("Sign out successful")
        } catch let signOutError as NSError {
            XCTFail("Error signing out: \(signOutError.localizedDescription)")
            print("Sign out failed: \(signOutError.localizedDescription)")
        }
    }

    func testFetchConnectionHistory() {
        print("Starting test for fetching connection history")
        let expectation = self.expectation(description: "Fetch connection history")
        controller.fetchConnectionHistory { connectionHistories in
            if connectionHistories.isEmpty {
                print("No connection histories found.")
            } else {
                print("Connection histories fetched successfully. Count: \(connectionHistories.count)")
            }
            XCTAssertFalse(connectionHistories.isEmpty, "Connection histories should not be empty.")
            for history in connectionHistories {
                print("Fetched connection: \(history.friendUsername) at \(history.startTime) with address \(history.formattedAddress)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 300, handler: nil)
    }
}
