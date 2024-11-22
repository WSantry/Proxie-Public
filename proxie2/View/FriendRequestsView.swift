import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FriendRequestsView: View {
    @State private var friendRequests: [String] = []  // Array of UIDs who sent friend requests
    @State private var friendRequestUsernames: [String: String] = [:]  // Mapping from UID to username
    @State private var currentUserUID: String = ""

    var body: some View {
        VStack {
            Text("Friend Requests")
                .font(Font.custom("Montserrat", size: 40).weight(.bold))
                .foregroundColor(.black)
                .padding()

            List(friendRequests, id: \.self) { uid in
                HStack {
                    Text(friendRequestUsernames[uid] ?? "Unknown")
                        .font(Font.custom("Montserrat", size: 20).weight(.bold))

                    Spacer()

                    // Accept button (checkmark)
                    Button(action: {
                        acceptFriendRequest(fromUID: uid)
                    }) {
                        Rectangle()
                            .foregroundColor(.green)
                            .frame(width: 40, height: 40)
                            .cornerRadius(5)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Deny button (cross)
                    Button(action: {
                        denyFriendRequest(fromUID: uid)
                    }) {
                        Rectangle()
                            .foregroundColor(.red)
                            .frame(width: 40, height: 40)
                            .cornerRadius(5)
                            .overlay(
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
            }
            .onAppear {
                fetchCurrentUserUID()
                fetchFriendRequests()
            }
        }
        .navigationBarBackButtonHidden(false)
    }

    func fetchCurrentUserUID() {
        if let user = Auth.auth().currentUser {
            self.currentUserUID = user.uid
        }
    }

    func fetchFriendRequests() {
        let db = Firestore.firestore()
        if let user = Auth.auth().currentUser {
            let userRef = db.collection("users").document(user.uid)

            userRef.getDocument { document, error in
                if let document = document, document.exists {
                    if let privateData = document.data()?["privateData"] as? [String: Any],
                       let requests = privateData["friendRequests"] as? [String] {
                        self.friendRequests = requests
                        fetchUsernames(forUIDs: requests)
                    }
                } else {
                    print("Error fetching friend requests: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }

    func fetchUsernames(forUIDs uids: [String]) {
        let db = Firestore.firestore()
        let dispatchGroup = DispatchGroup()
        for uid in uids {
            dispatchGroup.enter()
            db.collection("users").document(uid).getDocument { document, error in
                if let document = document, document.exists {
                    let username = document.data()?["username"] as? String ?? "Unknown"
                    self.friendRequestUsernames[uid] = username
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            // Update UI if needed
        }
    }

    func acceptFriendRequest(fromUID: String) {
        let friendRequestModel = FriendRequestModel()
        friendRequestModel.acceptFriendRequest(currentUID: currentUserUID, friendUID: fromUID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Friend request accepted.")
                    self.friendRequests.removeAll { $0 == fromUID }
                    self.friendRequestUsernames.removeValue(forKey: fromUID)
                case .failure(let error):
                    print("Error accepting friend request: \(error.localizedDescription)")
                }
            }
        }
    }

    func denyFriendRequest(fromUID: String) {
        let db = Firestore.firestore()
        let currentUserRef = db.collection("users").document(currentUserUID)

        currentUserRef.updateData([
            "privateData.friendRequests": FieldValue.arrayRemove([fromUID])
        ]) { error in
            if let error = error {
                print("Error removing friend request: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.friendRequests.removeAll { $0 == fromUID }
                    self.friendRequestUsernames.removeValue(forKey: fromUID)
                }
            }
        }
    }
}
