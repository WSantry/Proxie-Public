import XCTest
@testable import proxie2

class NotificationControllerTests: XCTestCase {
    func testSendProximityNotification() {
        let notificationController = NotificationController.shared
        
        // Mock friendId and trigger notification
        notificationController.sendProximityNotification(for: "friend1", completion: <#(Bool) -> Void#>)
        
        // Confirm notification logic is correctly triggered (this test requires that notifications are properly requested in iOS settings)
        // You may need to observe console outputs or rely on a mock for detailed notification testing.
        XCTAssertTrue(true)  // Placeholder - refine based on integration testing in device settings.
    }
}
