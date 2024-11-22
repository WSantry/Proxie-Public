import Foundation
import UserNotifications

protocol NotificationControllerProtocol {
    func sendProximityNotification(for friendId: String, completion: @escaping (Bool) -> Void)
}

class NotificationController: NotificationControllerProtocol {
    static let shared = NotificationController()
    
    private init() {
        requestNotificationPermission()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else if granted {
                print("Notification permission granted.")
                self.checkNotificationSettings()
            } else {
                print("Notification permission denied.")
            }
        }
    }
    
    private func checkNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Debug: Current notification settings - Authorization status: \(settings.authorizationStatus.rawValue)")
        }
    }
    
    func sendProximityNotification(for friendId: String, completion: @escaping (Bool) -> Void) {
        print("Debug: Entering sendProximityNotification for friendId \(friendId)")
        
        // Check current notification settings before sending
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Debug: Notification settings authorization status: \(settings.authorizationStatus.rawValue)")
            guard settings.authorizationStatus == .authorized else {
                print("Debug: Notifications not authorized; skipping notification for \(friendId)")
                completion(false)
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Proximity Alert"
            content.body = "You are within proximity of \(friendId)"
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Debug: Proximity notification successfully scheduled for friendId \(friendId)")
                    completion(true)
                }
            }
        }
    }

}
