import FirebaseFirestore
import FirebaseAuth

class StatisticsModel {
    private let firestore = Firestore.firestore()
    private let userId: String

    init(userId: String) {
        self.userId = userId
    }

    // Method to get the most connected person
    func fetchMostConnectedPerson(completion: @escaping (String?, Int) -> Void) {
        let userSubCollection = firestore.collection("users").document(userId).collection("proxieEvents")

        userSubCollection.getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                completion(nil, 0)
                return
            }

            // Count events by friendId
            var connectionCounts: [String: Int] = [:]
            for doc in documents {
                if let friendId = doc.data()["friendId"] as? String, !friendId.isEmpty {
                    connectionCounts[friendId, default: 0] += 1
                }
            }

            // Check if there is any data
            if connectionCounts.isEmpty {
                completion(nil, 0)
                return
            }

            // Find the friendId with the maximum connections
            if let (mostConnectedFriendId, count) = connectionCounts.max(by: { $0.value < $1.value }) {
                // Fetch friend's username
                self.fetchUsername(for: mostConnectedFriendId) { username in
                    completion(username, count)
                }
            } else {
                completion(nil, 0)
            }
        }
    }

    // Method to get connections count for a date range
    func fetchConnectionsCount(dateRange: DateRange, completion: @escaping (Int) -> Void) {
        let userSubCollection = firestore.collection("users").document(userId).collection("proxieEvents")
        let endDate = Date()
        let startDate: Date

        switch dateRange {
        case .today:
            startDate = Calendar.current.startOfDay(for: endDate)
        case .thisWeek:
            startDate = Calendar.current.date(byAdding: .day, value: -6, to: endDate)!
        case .thisMonth:
            startDate = Calendar.current.date(byAdding: .day, value: -29, to: endDate)!
        }

        userSubCollection
            .whereField("startTime", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("startTime", isLessThanOrEqualTo: Timestamp(date: endDate))
            .getDocuments { snapshot, error in
                completion(snapshot?.documents.count ?? 0)
            }
    }

    // Method to find the longest ever streak with a friend
    func fetchLongestStreakWithFriend(completion: @escaping (String?, Int) -> Void) {
        let userSubCollection = firestore.collection("users").document(userId).collection("proxieEvents")

        userSubCollection.order(by: "startTime").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                completion(nil, 0)
                return
            }

            var streaks: [String: Int] = [:] // friendId: longest streak
            var lastEventDates: [String: Date] = [:] // friendId: last event date
            var overallLongestStreak = 0
            var friendWithLongestStreak: String?

            for doc in documents {
                guard let friendId = doc.data()["friendId"] as? String, !friendId.isEmpty,
                      let eventDate = (doc.data()["startTime"] as? Timestamp)?.dateValue() else {
                    continue
                }

                if let lastDate = lastEventDates[friendId] {
                    let daysDifference = Calendar.current.dateComponents([.day], from: lastDate, to: eventDate).day ?? 0
                    if daysDifference == 1 {
                        // Continue streak
                        streaks[friendId] = (streaks[friendId] ?? 1) + 1
                    } else if daysDifference > 1 {
                        // Reset streak
                        streaks[friendId] = 1
                    }
                } else {
                    // First occurrence
                    streaks[friendId] = 1
                }

                lastEventDates[friendId] = eventDate

                // Check for overall longest streak
                if let currentStreak = streaks[friendId], currentStreak > overallLongestStreak {
                    overallLongestStreak = currentStreak
                    friendWithLongestStreak = friendId
                }
            }

            if let friendId = friendWithLongestStreak {
                self.fetchUsername(for: friendId) { username in
                    completion(username, overallLongestStreak)
                }
            } else {
                completion(nil, 0)
            }
        }
    }

    // Method to find the current ongoing streak with a friend
    func fetchCurrentStreakWithFriend(completion: @escaping (String?, Int) -> Void) {
        let userSubCollection = firestore.collection("users").document(userId).collection("proxieEvents")

        userSubCollection.order(by: "startTime").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                completion(nil, 0)
                return
            }

            var currentStreaks: [String: Int] = [:] // friendId: current streak
            var lastEventDates: [String: Date] = [:] // friendId: last event date
            let today = Calendar.current.startOfDay(for: Date())
            var longestCurrentStreak = 0
            var friendWithLongestCurrentStreak: String?

            for doc in documents {
                guard let friendId = doc.data()["friendId"] as? String, !friendId.isEmpty,
                      let eventDate = (doc.data()["startTime"] as? Timestamp)?.dateValue() else {
                    continue
                }

                if let lastDate = lastEventDates[friendId] {
                    let daysDifference = Calendar.current.dateComponents([.day], from: lastDate, to: eventDate).day ?? 0
                    if daysDifference == 1 {
                        // Continue streak
                        currentStreaks[friendId] = (currentStreaks[friendId] ?? 1) + 1
                    } else if daysDifference > 1 {
                        // Reset streak
                        currentStreaks[friendId] = 1
                    }
                } else {
                    // First occurrence
                    currentStreaks[friendId] = 1
                }

                lastEventDates[friendId] = eventDate

                // Check if the streak is ongoing up to today
                let daysToToday = Calendar.current.dateComponents([.day], from: eventDate, to: today).day ?? 0
                if daysToToday == 0 {
                    // Event happened today, streak is ongoing
                    if let currentStreak = currentStreaks[friendId], currentStreak > longestCurrentStreak {
                        longestCurrentStreak = currentStreak
                        friendWithLongestCurrentStreak = friendId
                    }
                } else if daysToToday > 0 {
                    // Streak ended before today
                    currentStreaks[friendId] = 0
                }
            }

            if let friendId = friendWithLongestCurrentStreak {
                self.fetchUsername(for: friendId) { username in
                    completion(username, longestCurrentStreak)
                }
            } else {
                completion(nil, 0)
            }
        }
    }

    // Method to get the least connected friend
    func fetchLeastConnectedFriend(completion: @escaping (String?, Int) -> Void) {
        let userSubCollection = firestore.collection("users").document(userId).collection("proxieEvents")

        userSubCollection.order(by: "startTime").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                completion(nil, 0)
                return
            }

            // Count events by friendId
            var connectionCounts: [String: Int] = [:]
            var firstEventTimestamps: [String: Date] = [:] // To store the first event date for each friend

            for doc in documents {
                if let friendId = doc.data()["friendId"] as? String, !friendId.isEmpty,
                   let startTime = (doc.data()["startTime"] as? Timestamp)?.dateValue() {
                    connectionCounts[friendId, default: 0] += 1

                    // Record the first appearance timestamp if not already recorded
                    if firstEventTimestamps[friendId] == nil {
                        firstEventTimestamps[friendId] = startTime
                    }
                }
            }

            // Handle the case where only one friendId exists
            if connectionCounts.count == 1, let (singleFriendId, count) = connectionCounts.first {
                self.fetchUsername(for: singleFriendId) { username in
                    completion(username, count)
                }
                return
            }

            // Find the friendId with the minimum connections and resolve ties by earliest first event
            let minCount = connectionCounts.values.min() ?? 0
            let leastConnectedFriends = connectionCounts.filter { $0.value == minCount }

            if !leastConnectedFriends.isEmpty {
                let friendWithEarliestEvent = leastConnectedFriends.min {
                    guard let firstDate = firstEventTimestamps[$0.key],
                          let secondDate = firstEventTimestamps[$1.key] else { return false }
                    return firstDate < secondDate
                }

                if let (leastConnectedFriendId, count) = friendWithEarliestEvent {
                    self.fetchUsername(for: leastConnectedFriendId) { username in
                        completion(username, count)
                    }
                } else {
                    completion(nil, 0)
                }
            } else {
                completion(nil, 0)
            }
        }
    }

    // Helper method to fetch username for a given userId
    private func fetchUsername(for userId: String, completion: @escaping (String?) -> Void) {
        guard !userId.isEmpty else {
            completion(nil)
            return
        }

        firestore.collection("users").document(userId).getDocument { document, error in
            if let data = document?.data(), let username = data["username"] as? String {
                completion(username)
            } else {
                completion(nil)
            }
        }
    }
}

// Date range options
enum DateRange {
    case today
    case thisWeek
    case thisMonth
}
