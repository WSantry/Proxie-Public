import Foundation
import FirebaseFirestore

struct MessageModel: Codable, Identifiable {
    var id: String? // Firestore document ID
    var content: String
    var senderId: String
    var recipientId: String
    var timestamp: Date
    var isRead: Bool
}
