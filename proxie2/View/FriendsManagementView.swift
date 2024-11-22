import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

// Extension to dismiss keyboard
extension UIApplication {
    func endEditing() {
        self.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct FriendsManagementView: View {
    @Environment(\.presentationMode) var presentationMode  // Allows dismissing the view
    @State private var currentUserUID: String = ""  // Signed-in user's UID
    @State private var currentUsername: String = ""  // Signed-in user's username
    @State private var keyboardHeight: CGFloat = 0  // To adjust the view based on keyboard height
    @State private var friendRequestsCount: Int = 0  // Number of friend requests
    @State private var inputText: String = ""  // Input text for adding a friend
    @State private var message: String? = nil  // Success/error message
    @State private var friendsUIDs: [String] = []  // Array to store friends' UIDs
    @State private var friendsUsernames: [String: String] = [:]  // Mapping from UID to username
    @State private var showRemovePopup: Bool = false  // Show/hide remove popup
    @State private var selectedFriendUID: String? = nil  // UID of friend selected for removal
    @State private var timer: Timer?  // Timer to check for friend requests

    private var keyboardPublisher: AnyPublisher<CGFloat, Never> {
        Publishers.Merge(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                .compactMap { notification -> CGFloat? in
                    (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height
                },
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in CGFloat(0) }
        ).eraseToAnyPublisher()
    }

    var body: some View {
        NavigationView {
            ZStack {
                Group {
                    Text("Friends")
                        .font(Font.custom("Montserrat", size: 40).weight(.bold))
                        .foregroundColor(.white)
                        .offset(x: -0.50, y: -335)

                    // Back arrow to go back to Map View
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .offset(x: -170, y: -370)
                }

                Group {
                    Divider()
                        .frame(height: 2)
                        .frame(width: 500)
                        .background(Color.black)
                        .position(x: 200, y: 162)

                    Divider()
                        .frame(height: 2)
                        .frame(width: 500)
                        .background(Color.black)
                        .position(x: 200, y: 655)

                    Divider()
                        .frame(height: 2)
                        .frame(width: 500)
                        .background(Color.black)
                        .position(x: 200, y: 720)
                }

                Group {
                    HStack {
                        // Editable text input field
                        TextField("Enter username", text: $inputText)
                            .padding()
                            .background(Color(red: 0.85, green: 0.85, blue: 0.85))
                            .frame(width: 220, height: 44)
                            .cornerRadius(12)
                            .offset(x: -20, y: 335)

                        // Green clickable button with "Add" text overlay
                        Button(action: {
                            addFriendRequest()
                        }) {
                            Rectangle()
                                .foregroundColor(Color(red: 0.30, green: 0.98, blue: 0.38))
                                .frame(width: 60, height: 44)
                                .cornerRadius(12)
                                .overlay(
                                    Text("Add")
                                        .font(Font.custom("Montserrat", size: 16).weight(.bold))
                                        .foregroundColor(.black)
                                )
                        }
                        .offset(x: -10, y: 335)
                    }

                    // Display the success or error message below the input field
                    if let message = message {
                        Text(message)
                            .font(Font.custom("Montserrat", size: 14).weight(.medium))
                            .foregroundColor(.black)
                            .offset(x: 0, y: 370)
                    }

                    Text("Add a Friend!")
                        .font(Font.custom("Montserrat", size: 40).weight(.bold))
                        .foregroundColor(.white)
                        .offset(x: 0, y: 284.50)

                    // Friend Requests Bell Icon and Text in HStack
                    HStack {
                        Image(systemName: "bell.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                            .offset(x: 260, y: 0)

                        // Friend Requests Navigation Link
                        NavigationLink(destination: FriendRequestsView()) {
                            Text("Friend Requests")
                                .font(Font.custom("Montserrat", size: 30))
                                .foregroundColor(.white)
                        }

                        // Notification badge for friend requests count
                        if friendRequestsCount > 0 {
                            Text("\(friendRequestsCount)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(5)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                    }
                    .position(x: 200, y: 685)
                }

                // Transparent section for the Friends Display with black border and names in rows
                Group {
                    Rectangle()
                        .foregroundColor(.clear)  // Transparent background
                        .frame(width: 410, height: 497)  // Original size
                        .overlay(
                            VStack(spacing: 0) {
                                ForEach(friendsUIDs, id: \.self) { friendUID in
                                    Button(action: {
                                        self.selectedFriendUID = friendUID
                                        self.showRemovePopup = true
                                    }) {
                                        Text(friendsUsernames[friendUID] ?? "Unknown")
                                            .font(.body)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal)
                                            .padding(.vertical, 8)
                                            .background(Color.clear)  // Transparent row background
                                            .border(Color.black, width: 1)  // Black border between rows
                                    }
                                }
                            }
                            .frame(maxHeight: .infinity, alignment: .top)  // Align names from top downward
                        )
                        .border(Color.clear, width: 2)  // Outer border
                        .position(x: 215, y: 409)  // Original position
                }

                // Popup for removing a friend
                if showRemovePopup {
                    VStack {
                        Text("Remove \(friendsUsernames[selectedFriendUID ?? ""] ?? "")?")
                            .font(.headline)
                            .padding()

                        Button(action: {
                            if let friendUID = selectedFriendUID {
                                removeFriend(friendUID: friendUID)
                            }
                        }) {
                            Text("Remove")
                                .font(.title2)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }

                        Button(action: {
                            self.showRemovePopup = false  // Close popup
                        }) {
                            Text("Cancel")
                                .font(.title2)
                                .padding()
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .frame(width: 200, height: 150)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .position(x: 215, y: 500)
                }
            }
            .frame(width: 430, height: 932)
            .background(Color(red: 0.53, green: 0.81, blue: 0.92))
            .offset(y: -keyboardHeight / 2)
            .onReceive(keyboardPublisher) { newHeight in
                self.keyboardHeight = newHeight
            }
            .onAppear {
                fetchSignedInUser()
                fetchFriendsList()  // Fetch friends list on load
                fetchFriendRequestsCount()
                startFriendRequestTimer()
            }
            .onDisappear {
                timer?.invalidate()
            }
            // Dismiss the keyboard when tapping outside
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
        }
    }

    // MARK: - Fetch Signed-In User's UID and Username
    func fetchSignedInUser() {
        if let user = Auth.auth().currentUser {
            self.currentUserUID = user.uid
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).getDocument { document, error in
                if let document = document, document.exists {
                    if let username = document.data()?["username"] as? String {
                        self.currentUsername = username
                    }
                }
            }
        }
    }

    // MARK: - Fetch Friends List
    func fetchFriendsList() {
        let db = Firestore.firestore()
        if let user = Auth.auth().currentUser {
            let userRef = db.collection("users").document(user.uid)
            userRef.getDocument { document, error in
                if let document = document, document.exists {
                    if let privateData = document.data()?["privateData"] as? [String: Any],
                       let friendsArray = privateData["friends"] as? [String] {
                        self.friendsUIDs = friendsArray  // Update the local friends UID list
                        fetchUsernames(forUIDs: friendsArray)
                    }
                }
            }
        }
    }

    // Fetch usernames for given UIDs
    func fetchUsernames(forUIDs uids: [String]) {
        let db = Firestore.firestore()
        let dispatchGroup = DispatchGroup()
        for uid in uids {
            dispatchGroup.enter()
            db.collection("users").document(uid).getDocument { document, error in
                if let document = document, document.exists {
                    let username = document.data()?["username"] as? String ?? "Unknown"
                    self.friendsUsernames[uid] = username
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            // Update UI if needed
        }
    }

    // MARK: - Removing Friend from Both Lists
    func removeFriend(friendUID: String) {
        let db = Firestore.firestore()
        if let user = Auth.auth().currentUser {
            let currentUserRef = db.collection("users").document(user.uid)
            // Remove the friend UID from the current user's friends array
            currentUserRef.updateData([
                "privateData.friends": FieldValue.arrayRemove([friendUID])
            ]) { error in
                if let error = error {
                    print("Error removing friend: \(error.localizedDescription)")
                    return
                }
                // Also remove the current user's UID from the friend's friends array
                let friendRef = db.collection("users").document(friendUID)
                friendRef.updateData([
                    "privateData.friends": FieldValue.arrayRemove([self.currentUserUID])
                ]) { error in
                    if let error = error {
                        print("Error removing current user from friend's friend list: \(error.localizedDescription)")
                    }
                }
                // Remove the friend from the local state after removal
                DispatchQueue.main.async {
                    self.friendsUIDs.removeAll { $0 == friendUID }
                    self.friendsUsernames.removeValue(forKey: friendUID)
                    self.showRemovePopup = false  // Hide the popup
                }
            }
        }
    }

    // MARK: - Adding Friend Request
    func addFriendRequest() {
        guard !currentUserUID.isEmpty else { return }  // Ensure the current UID is loaded
        let db = Firestore.firestore()
        // Check if the input username exists
        db.collection("users").whereField("username", isEqualTo: inputText).getDocuments { snapshot, error in
            if let error = error {
                print("Error checking for username: \(error)")
                return
            }
            if let document = snapshot?.documents.first {
                let friendUID = document.documentID
                let ref = db.collection("users").document(friendUID)
                // Add current user's UID to the `privateData.friendRequests` array of the found user
                ref.updateData([
                    "privateData.friendRequests": FieldValue.arrayUnion([self.currentUserUID])
                ]) { error in
                    if let error = error {
                        print("Error updating friend requests: \(error)")
                        self.message = "Error sending friend request."
                    } else {
                        self.message = "Friend request sent to \(self.inputText)."
                    }
                    // Clear the message after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.message = nil
                    }
                }
            } else {
                self.message = "No account found with username \(self.inputText)."
                // Clear the message after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.message = nil
                }
            }
            // Clear the input field
            DispatchQueue.main.async {
                self.inputText = ""
            }
        }
    }

    // MARK: - Fetching Friend Request Count
    func fetchFriendRequestsCount() {
        let db = Firestore.firestore()
        // Get the current user's friend request count
        if let user = Auth.auth().currentUser {
            let uid = user.uid
            let userRef = db.collection("users").document(uid)

            userRef.getDocument { document, error in
                if let document = document, document.exists {
                    if let privateData = document.data()?["privateData"] as? [String: Any],
                       let requests = privateData["friendRequests"] as? [String] {
                        DispatchQueue.main.async {
                            self.friendRequestsCount = requests.count
                        }
                    }
                }
            }
        }
    }

    // MARK: - Timer to check for friend requests every 10 seconds
    func startFriendRequestTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            fetchFriendRequestsCount()
        }
    }
}

// MARK: - PreviewProvider
struct FriendsManagementView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsManagementView()
    }
}
