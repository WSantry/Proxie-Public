import Foundation
import FirebaseFirestore
import FirebaseAuth

class ConnectionHistoryController {
    private let db = Firestore.firestore()
    private var apiKey: String {
           guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
                 let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
                 let key = dict["LocationIQAPIKey"] as? String else {
               fatalError("API Key not found in Secrets.plist")
           }
           return key
       }

    func fetchConnectionHistory(completion: @escaping ([ConnectionHistory]) -> Void) {
        print("DEBUG: Starting fetchConnectionHistory method.")

        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: User not logged in.")
            completion([])
            return
        }

        print("DEBUG: User is logged in with ID: \(userId). Fetching proxieEvents.")

        db.collection("users").document(userId).collection("proxieEvents")
            .order(by: "startTime", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("DEBUG: Error fetching proxieEvents: \(error)")
                    completion([])
                    return
                }

                print("DEBUG: Successfully fetched proxieEvents. Processing documents.")

                var connectionHistories: [ConnectionHistory] = []
                let group = DispatchGroup()

                for document in snapshot?.documents ?? [] {
                    print("DEBUG: Processing document with ID: \(document.documentID)")
                    let data = document.data()

                    guard
                        let friendId = data["friendId"] as? String,
                        let startTime = (data["startTime"] as? Timestamp)?.dateValue(),
                        let startLocation = data["startLocation"] as? GeoPoint
                    else {
                        print("DEBUG: Document \(document.documentID) is missing required fields.")
                        continue
                    }

                    print("DEBUG: Document \(document.documentID) contains valid data. Friend ID: \(friendId)")

                    group.enter()

                    // Fetch the friend's username
                    self.db.collection("users").document(friendId).getDocument { friendDoc, friendError in
                        if let friendError = friendError {
                            print("DEBUG: Error fetching friend's username for ID \(friendId): \(friendError)")
                            group.leave()
                            return
                        }

                        let friendUsername = friendDoc?.data()?["username"] as? String ?? "Unknown"
                        print("DEBUG: Fetched friend's username: \(friendUsername)")

                        // Convert location to formatted address using LocationIQ API
                        self.getFormattedAddress(latitude: startLocation.latitude, longitude: startLocation.longitude) { formattedAddress in
                            print("DEBUG: Fetched formatted address: \(formattedAddress)")

                            // Format startTime to string for the output
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            let dateString = dateFormatter.string(from: startTime)

                            dateFormatter.dateFormat = "HH:mm"
                            let timeString = dateFormatter.string(from: startTime)

                            let connectionMessage = "You connected with \(friendUsername) on \(dateString) at \(timeString) near \(formattedAddress)"
                            print("DEBUG: Connection message: \(connectionMessage)")

                            let connection = ConnectionHistory(
                                id: document.documentID,
                                friendUsername: friendUsername,
                                startTime: startTime,  // Keep the original Date type
                                startLocation: (latitude: startLocation.latitude, longitude: startLocation.longitude),
                                formattedAddress: formattedAddress
                            )

                            connectionHistories.append(connection)
                            print("DEBUG: Appended connection: \(connectionMessage)")
                            group.leave()
                        }
                    }
                }

                group.notify(queue: .main) {
                    print("DEBUG: Completed processing all documents. Returning connection histories.")
                    completion(connectionHistories)
                }
            }
    }

    private func getFormattedAddress(latitude: Double, longitude: Double, completion: @escaping (String) -> Void) {
        print("DEBUG: Starting getFormattedAddress for coordinates (\(latitude), \(longitude))")

        let urlString = "https://us1.locationiq.com/v1/reverse?key=\(apiKey)&lat=\(latitude)&lon=\(longitude)&format=json"
        guard let url = URL(string: urlString) else {
            print("DEBUG: Invalid URL for reverse geocoding.")
            completion("Unknown Address")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("DEBUG: Reverse geocoding failed with error: \(error)")
                completion("Unknown Address")
                return
            }

            guard let data = data else {
                print("DEBUG: No data received from reverse geocoding.")
                completion("Unknown Address")
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let displayName = json["display_name"] as? String {
                    print("DEBUG: Reverse geocoding successful. Address: \(displayName)")
                    completion(displayName)
                } else {
                    print("DEBUG: Unexpected JSON format for reverse geocoding response.")
                    completion("Unknown Address")
                }
            } catch {
                print("DEBUG: JSON parsing failed: \(error)")
                completion("Unknown Address")
            }
        }

        task.resume()
    }
}
