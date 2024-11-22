import FirebaseFirestore
import FirebaseAuth

class UserModel {
    private let db = Firestore.firestore()

    func fetchUserData(uid: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let userRef = db.collection("users").document(uid)
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                completion(.success(document.data() ?? [:]))
            } else {
                completion(.failure(error ?? NSError(domain: "", code: -1, userInfo: nil)))
            }
        }
    }

    func fetchUid(forUsername username: String, completion: @escaping (String?) -> Void) {
        let userRef = db.collection("users").whereField("username", isEqualTo: username)
        userRef.getDocuments { snapshot, error in
            if let document = snapshot?.documents.first {
                completion(document.documentID)
            } else {
                completion(nil)
            }
        }
    }

    func sendFriendRequest(toUsername: String, fromUID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        fetchUid(forUsername: toUsername) { friendUID in
            guard let friendUID = friendUID else {
                completion(.failure(NSError(domain: "NoUserFound", code: 404, userInfo: nil)))
                return
            }
            
            let userRef = self.db.collection("users").document(friendUID)
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
    }

    func acceptFriendRequest(currentUID: String, friendUID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let currentUserRef = db.collection("users").document(currentUID)
        let friendUserRef = db.collection("users").document(friendUID)

        let batch = db.batch()

        batch.updateData([
            "privateData.friends": FieldValue.arrayUnion([friendUID]),
            "privateData.friendRequests": FieldValue.arrayRemove([friendUID])
        ], forDocument: currentUserRef)

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

    func fetchUsername(for uid: String, completion: @escaping (String?) -> Void) {
        let userRef = db.collection("users").document(uid)
        userRef.getDocument { document, error in
            guard let document = document, document.exists, let username = document.data()?["username"] as? String else {
                completion(nil)
                return
            }
            completion(username)
        }
    }

    func fetchFriends(for uid: String, completion: @escaping ([String]?) -> Void) {
        let userRef = db.collection("users").document(uid)
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                if let privateData = document.data()?["privateData"] as? [String: Any],
                   let friends = privateData["friends"] as? [String] {
                    completion(friends)
                } else {
                    completion([])
                }
            } else {
                completion(nil)
            }
        }
    }

    func fetchFriendRequests(for uid: String, completion: @escaping ([String]?) -> Void) {
        let userRef = db.collection("users").document(uid)
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                if let privateData = document.data()?["privateData"] as? [String: Any],
                   let friendRequests = privateData["friendRequests"] as? [String] {
                    completion(friendRequests)
                } else {
                    completion([])
                }
            } else {
                completion(nil)
            }
        }
    }
}
