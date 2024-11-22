import XCTest
import CoreLocation
@testable import proxie2

@MainActor
final class LocationModelTests: XCTestCase {
    
    var locationModel: LocationModel!

    override func setUp() async throws {
        print("Debug: Setting up LocationModel instance for testing.")
        locationModel = LocationModel()
        print("Debug: LocationModel instance created.")
    }
    
    override func tearDown() {
        print("Debug: Tearing down LocationModel instance.")
        locationModel = nil
    }

    func testManualLocationUpdate() async throws {
        let initialLatitude = 37.7749
        let initialLongitude = -122.4194
        locationModel.setManualLocation(latitude: initialLatitude, longitude: initialLongitude)
        XCTAssertNotNil(locationModel.userLocation, "User location should not be nil after manual location update.")
        
        let updatedLatitude = 37.7849
        let updatedLongitude = -122.4094
        locationModel.setManualLocation(latitude: updatedLatitude, longitude: updatedLongitude)
        
        XCTAssertNotEqual(locationModel.userLocation?.latitude, initialLatitude, "Latitude should update after manual location change.")
        XCTAssertNotEqual(locationModel.userLocation?.longitude, initialLongitude, "Longitude should update after manual location change.")
    }

    func testAccuracyAdjustmentWithProximityZones() {
        print("Debug: Starting testAccuracyAdjustmentWithProximityZones.")
        
        // Broad zone (> 1 mile)
        locationModel.adjustAccuracyIfNeeded(for: 2000) // Distance in meters
        XCTAssertEqual(locationModel.getDesiredAccuracy(), kCLLocationAccuracyThreeKilometers, "Accuracy should be set to 3 kilometers for broad zone.")
        
        // Moderate zone (1 mile to 750 feet)
        locationModel.adjustAccuracyIfNeeded(for: 1000)
        XCTAssertEqual(locationModel.getDesiredAccuracy(), kCLLocationAccuracyHundredMeters, "Accuracy should be set to 100 meters for moderate zone.")
        
        // Precise zone (< 750 feet)
        locationModel.adjustAccuracyIfNeeded(for: 500)
        XCTAssertEqual(locationModel.getDesiredAccuracy(), kCLLocationAccuracyNearestTenMeters, "Accuracy should be set to 10 meters for precise zone.")
    }

    func testNilUserLocationBeforeSetting() {
        XCTAssertNil(locationModel.userLocation, "User location should be nil before being set.")
    }

    func testMultipleLocationUpdates() {
        let locations = [
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
            CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.3994)
        ]
        
        for (index, location) in locations.enumerated() {
            locationModel.setManualLocation(latitude: location.latitude, longitude: location.longitude)
            XCTAssertEqual(locationModel.userLocation, location, "User location should match the set manual location at index \(index).")
        }
    }

    func testProximityDetectionMock() {
        let userLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        locationModel.setManualLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)

        let nearbyFriendLocation = CLLocationCoordinate2D(latitude: 37.7752, longitude: -122.4192) // Within 750 feet
        let distantFriendLocation = CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294) // Outside 750 feet
        
        // Mocking the completion handler for fetching friends' locations
        let friendLocations = ["friend1": nearbyFriendLocation, "friend2": distantFriendLocation]
        
        locationModel.fetchFriendsLocations { fetchedLocations in
            XCTAssertEqual(fetchedLocations["friend1"], nearbyFriendLocation, "Nearby friend location should match.")
            XCTAssertEqual(fetchedLocations["friend2"], distantFriendLocation, "Distant friend location should match.")
        }
    }

    func testVeryDistantLocation() {
        let distantLatitude = 50.1109
        let distantLongitude = 8.6821
        locationModel.setManualLocation(latitude: distantLatitude, longitude: distantLongitude)
        
        XCTAssertNotNil(locationModel.userLocation, "User location should not be nil even for distant coordinates.")
        XCTAssertEqual(locationModel.userLocation?.latitude, distantLatitude, "Latitude should match the set distant latitude.")
        XCTAssertEqual(locationModel.userLocation?.longitude, distantLongitude, "Longitude should match the set distant longitude.")
    }

    func testPermissionRequest() async throws {
        await locationModel.requestLocationPermission()
        print("Debug: Location permission requested.")
        
        XCTAssertNotNil(locationModel.locationManager.delegate, "Location manager should have a delegate after requesting permission.")
    }

    func testRapidLocationPermissionToggle() async {
        for _ in 1...5 {
            await locationModel.requestLocationPermission()
            locationModel.stopUpdatingLocation()
        }
        
        XCTAssertNotNil(locationModel.locationManager.delegate, "Location manager delegate should be set after multiple enable/disable calls.")
    }
}
