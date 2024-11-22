import FirebaseFirestore
import FirebaseAuth

class FriendRequestModel {
    let db = Firestore.firestore()

    // Fetch UID for a given username
    func fetchUid(forUsername username: String, completion: @escaping (String?) -> Void) {
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            if let document = snapshot?.documents.first {
                let uid = document.documentID
                completion(uid)
            } else {
                completion(nil)
            }
        }
    }

    // Send a friend request using UIDs
    func sendFriendRequest(toUID: String, fromUID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let userRef = db.collection("users").document(toUID)
        userRef.updateData([
            "privateData.friendRequests": FieldValue.arrayUnion([fromUID])
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // Accept a friend request using UIDs
    func acceptFriendRequest(currentUID: String, friendUID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let currentUserRef = db.collection("users").document(currentUID)
        let friendUserRef = db.collection("users").document(friendUID)

        let batch = db.batch()

        // Update current user's document
        batch.updateData([
            "privateData.friends": FieldValue.arrayUnion([friendUID]),
            "privateData.friendRequests": FieldValue.arrayRemove([friendUID])
        ], forDocument: currentUserRef)

        // Update friend's document
        batch.updateData([
            "privateData.friends": FieldValue.arrayUnion([currentUID])
        ], forDocument: friendUserRef)

        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
