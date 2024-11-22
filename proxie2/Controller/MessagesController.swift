import Foundation
import FirebaseAuth
import FirebaseCore
import Firebase
import FirebaseFirestore



class MessagesController: ObservableObject {
    @Published private(set) var messages: [MessageModel] = []
    @Published private(set) var lastMessageId: String = ""
    private var conversationId: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // Fetch messages between the current user and a specific friend
    func getMessages(with friendId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("Error: No current user ID found.")
            return
        }

        // Remove any existing listener to prevent multiple listeners for the same chat
        listener?.remove()

        // First, find or create the conversation document between the two users
        let participants = [currentUserId, friendId].sorted()
        let participantsSet = Set(participants)

        db.collection("conversations")
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching conversations: \(error)")
                    return
                }

                if let documents = snapshot?.documents {
                    // Try to find an existing conversation with these participants
                    for document in documents {
                        let data = document.data()
                        if let participantsArray = data["participants"] as? [String], Set(participantsArray) == participantsSet {
                            // Found the conversation
                            self.conversationId = document.documentID
                            self.listenForMessages()
                            return
                        }
                    }
                }

                // No existing conversation found, create a new one
                let conversationData: [String: Any] = [
                    "participants": participants,
                    "lastMessage": "",
                    "lastUpdated": Timestamp()
                ]

                var ref: DocumentReference? = nil
                ref = self.db.collection("conversations").addDocument(data: conversationData) { error in
                    if let error = error {
                        print("Error creating conversation: \(error)")
                        return
                    }
                    self.conversationId = ref?.documentID
                    self.listenForMessages()
                }
            }
    }

    private func listenForMessages() {
        guard let conversationId = self.conversationId else { return }

        listener = db.collection("conversations").document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching messages: \(error)")
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    print("No messages found.")
                    return
                }

                let messages = documents.compactMap { document -> MessageModel? in
                    do {
                        var message = try document.data(as: MessageModel.self)
                        message.id = document.documentID

                        // Mark message as read if necessary
                        if message.recipientId == Auth.auth().currentUser?.uid && !message.isRead {
                            self.markMessageAsRead(document.documentID)
                            message.isRead = true
                        }

                        return message
                    } catch {
                        print("Error decoding message: \(error)")
                        return nil
                    }
                }

                DispatchQueue.main.async {
                    self.messages = messages
                    if let id = self.messages.last?.id {
                        self.lastMessageId = id
                    }
                }
            }
    }

    // Send a message with isRead set to false
    func sendMessage(text: String, receiverId: String) {
        guard let senderId = Auth.auth().currentUser?.uid else {
            print("Error: No current user ID found.")
            return
        }

        // Ensure that conversationId is set
        if self.conversationId == nil {
            // Need to create or fetch the conversation first
            self.getMessages(with: receiverId)
            // Wait for conversationId to be set
            return
        }

        guard let conversationId = self.conversationId else {
            print("Error: No conversation ID found.")
            return
        }

        let newMessage = MessageModel(
            id: nil, // Firestore will generate the ID
            content: text,
            senderId: senderId,
            recipientId: receiverId,
            timestamp: Date(),
            isRead: false
        )

        do {
            let ref = db.collection("conversations").document(conversationId)
                .collection("messages").document()

            try ref.setData(from: newMessage) { error in
                if let error = error {
                    print("Error sending message: \(error)")
                } else {
                    // Update the conversation's lastMessage and lastUpdated fields
                    self.db.collection("conversations").document(conversationId).updateData([
                        "lastMessage": text,
                        "lastUpdated": Timestamp(date: Date())
                    ])
                    print("Message sent successfully")
                }
            }
        } catch {
            print("Error adding message to Firestore: \(error)")
        }
    }

    // Update the isRead status for a specific message in Firestore
    private func markMessageAsRead(_ messageId: String) {
        guard let conversationId = self.conversationId else { return }

        db.collection("conversations").document(conversationId)
            .collection("messages").document(messageId)
            .updateData(["isRead": true]) { error in
                if let error = error {
                    print("Error marking message as read: \(error)")
                } else {
                    print("Message marked as read")
                }
            }
    }

    // Remove the Firestore listener
    func removeListener() {
        listener?.remove()
        listener = nil
    }
}
