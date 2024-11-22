import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChatListView: View {
    @State private var friends: [User] = []  // Holds friend data locally
    @State private var chatStatuses: [String: ChatStatus] = [:]  // Stores chat statuses for each friend
    let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack {
                List(friends) { friend in
                    NavigationLink(destination: ChatView(userId: friend.id, username: friend.username)) {
                        HStack {
                            Text(friend.username)
                                .font(.headline)

                            Spacer()

                            // Display the correct icon based on the chat status
                            if let status = chatStatuses[friend.id] {
                                switch status {
                                case .sentUnread:
                                    Image(systemName: "paperplane.fill").foregroundColor(.blue)
                                case .sentRead:
                                    Image(systemName: "paperplane")
                                case .receivedUnread:
                                    Image(systemName: "envelope.fill").foregroundColor(.green)
                                case .receivedRead:
                                    Image(systemName: "envelope")
                                case .noMessage:
                                    Text("Say hello to your new friend")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("Chats")
                .onAppear {
                    fetchFriends()
                }

                Spacer()

                // Map button in the bottom right corner
                HStack {
                    Spacer()
                    NavigationLink(destination: MapView()) {
                        Image(systemName: "map")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .padding()
                    }
                }
            }
        }
    }

    // Fetch friends based on UIDs stored in privateData.friends, and retrieve their usernames
    private func fetchFriends() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("Error: No current user ID found.")
            return
        }
        print("Fetching friends for user ID: \(currentUserId)")

        db.collection("users").document(currentUserId).getDocument { document, error in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists,
               let privateData = document.data()?["privateData"] as? [String: Any],
               var friendUIDs = privateData["friends"] as? [String] {
                friendUIDs.reverse()
                print("Friend UIDs found in document (reversed): \(friendUIDs)")

                let group = DispatchGroup()
                var fetchedFriends: [User] = []

                for uid in friendUIDs {
                    print("Attempting to fetch user with UID: \(uid)")
                    group.enter()

                    db.collection("users").document(uid).getDocument { friendDoc, error in
                        defer { group.leave() }
                        if let error = error {
                            print("Error fetching friend with UID \(uid): \(error.localizedDescription)")
                            return
                        }
                        if let friendDoc = friendDoc, friendDoc.exists {
                            let friendData = friendDoc.data()
                            let friend = User(id: uid, username: friendData?["username"] as? String ?? "")
                            fetchedFriends.append(friend)

                            self.fetchChatStatus(friendId: uid, currentUserId: currentUserId)
                        } else {
                            print("No document found for UID \(uid)")
                        }
                    }
                }

                group.notify(queue: .main) {
                    self.friends = fetchedFriends
                    print("Final friends list: \(self.friends.map { $0.username })")
                }
            } else {
                print("Error: Friends array not found or is empty in user's privateData.")
            }
        }
    }

    // Updated fetchChatStatus method to work with conversations collection
    private func fetchChatStatus(friendId: String, currentUserId: String) {
        let participants = [currentUserId, friendId].sorted()

        db.collection("conversations")
            .whereField("participants", arrayContains: currentUserId)
            .whereField("participants", arrayContains: friendId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching conversation: \(error.localizedDescription)")
                    return
                }

                guard let conversationDoc = snapshot?.documents.first else {
                    self.chatStatuses[friendId] = .noMessage
                    print("No previous conversation with friend ID \(friendId); set status to noMessage.")
                    return
                }

                let conversationData = conversationDoc.data()
                if let lastMessage = conversationData["lastMessage"] as? String {

                    // Fetch the last message to determine its status
                    db.collection("conversations")
                        .document(conversationDoc.documentID)
                        .collection("messages")
                        .order(by: "timestamp", descending: true)
                        .limit(to: 1)
                        .getDocuments { messageSnapshot, error in
                            if let error = error {
                                print("Error fetching last message: \(error.localizedDescription)")
                                return
                            }

                            guard let messageDoc = messageSnapshot?.documents.first else {
                                self.chatStatuses[friendId] = .noMessage
                                return
                            }

                            let messageData = messageDoc.data()
                            if let senderId = messageData["senderId"] as? String,
                               let recipientId = messageData["recipientId"] as? String,
                               let isRead = messageData["isRead"] as? Bool {

                                if senderId == currentUserId && !isRead {
                                    self.chatStatuses[friendId] = .sentUnread
                                    print("Message sent by user to \(friendId) is unread; set status to sentUnread.")
                                } else if senderId == currentUserId && isRead {
                                    self.chatStatuses[friendId] = .sentRead
                                    print("Message sent by user to \(friendId) is read; set status to sentRead.")
                                } else if recipientId == currentUserId && !isRead {
                                    self.chatStatuses[friendId] = .receivedUnread
                                    print("Message received from \(friendId) is unread; set status to receivedUnread.")
                                } else {
                                    self.chatStatuses[friendId] = .receivedRead
                                    print("Message received from \(friendId) is read; set status to receivedRead.")
                                }
                            } else {
                                print("Error parsing message data for friend ID \(friendId).")
                            }
                        }
                }
            }
    }
}

// User struct: `id` is the UID for each friend
struct User: Identifiable {
    var id: String
    var username: String
}

// Enum for Chat Status
enum ChatStatus {
    case sentUnread      // Message sent by user, not yet read by friend
    case sentRead        // Message sent by user, read by friend but no reply
    case receivedUnread  // Message received from friend, not yet read by user
    case receivedRead    // Message received from friend, read by user but no reply
    case noMessage       // No message history, new friend
}

struct ChatListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatListView()
    }
}
