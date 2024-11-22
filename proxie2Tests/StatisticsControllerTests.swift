import XCTest
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
@testable import proxie2

class StatisticsControllerTests: XCTestCase {
    var statisticsController: StatisticsController!
    var userId: String!
    
    override func setUpWithError() throws {
        // Initialize Firebase if it hasn’t been already
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // Sign in to the account and set up the StatisticsController
        let signInExpectation = expectation(description: "Sign in with test account")
        Auth.auth().signIn(withEmail: "test_user@example.com", password: "TestPassword123!") { authResult, error in
            if let error = error {
                XCTFail("Error signing in: \(error.localizedDescription)")
            } else {
                self.userId = Auth.auth().currentUser?.uid
                self.statisticsController = StatisticsController(userId: self.userId)
            }
            signInExpectation.fulfill()
        }
        
        wait(for: [signInExpectation], timeout: 5)
    }
    
    override func tearDownWithError() throws {
        statisticsController = nil
        try Auth.auth().signOut()
    }
    
    // MARK: - Test Methods
    
    func testFetchMostConnectedPerson() {
        let expectation = self.expectation(description: "Fetch most connected person")
        
        statisticsController.fetchMostConnectedPerson { username, count in
            XCTAssertNotNil(username, "Username should not be nil.")
            XCTAssertGreaterThanOrEqual(count, 0, "Count should be zero or greater.")
            print("Most connected person: \(username) with \(count) connections.")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testFetchConnectionsCountToday() {
        let expectation = self.expectation(description: "Fetch connections count today")
        
        statisticsController.fetchConnectionsCount(for: .today) { count in
            XCTAssertGreaterThanOrEqual(count, 0, "Count should be zero or greater.")
            print("Connections today: \(count)")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testFetchConnectionsCountThisWeek() {
        let expectation = self.expectation(description: "Fetch connections count this week")
        
        statisticsController.fetchConnectionsCount(for: .thisWeek) { count in
            XCTAssertGreaterThanOrEqual(count, 0, "Count should be zero or greater.")
            print("Connections this week: \(count)")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testFetchConnectionsCountThisMonth() {
        let expectation = self.expectation(description: "Fetch connections count this month")
        
        statisticsController.fetchConnectionsCount(for: .thisMonth) { count in
            XCTAssertGreaterThanOrEqual(count, 0, "Count should be zero or greater.")
            print("Connections this month: \(count)")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testFetchLongestStreakWithFriend() {
        let expectation = self.expectation(description: "Fetch longest streak with a friend")
        
        statisticsController.fetchLongestStreakWithFriend { username, streakLength in
            XCTAssertNotNil(username, "Username should not be nil.")
            XCTAssertGreaterThanOrEqual(streakLength, 0, "Streak length should be zero or greater.")
            print("Longest streak is with \(username) for \(streakLength) days.")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testFetchCurrentStreakWithFriend() {
        let expectation = self.expectation(description: "Fetch current ongoing streak with a friend")
        
        statisticsController.fetchCurrentStreakWithFriend { username, streakLength in
            XCTAssertNotNil(username, "Username should not be nil.")
            XCTAssertGreaterThanOrEqual(streakLength, 0, "Streak length should be zero or greater.")
            print("Current ongoing streak is with \(username) for \(streakLength) days.")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testFetchLeastConnectedFriend() {
        let expectation = self.expectation(description: "Fetch least connected friend")
        
        statisticsController.fetchLeastConnectedFriend { username, count in
            XCTAssertNotNil(username, "Username should not be nil.")
            XCTAssertGreaterThanOrEqual(count, 0, "Count should be zero or greater.")
            print("Least connected friend: \(username ?? "None") with \(count) connections.")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
}
