import Foundation

class StatisticsController {
    private let statisticsModel: StatisticsModel
    private var userId: String
    
    init(userId: String) {
        self.userId = userId
        self.statisticsModel = StatisticsModel(userId: userId)
    }

    // MARK: - Fetch Most Connected Person
    func fetchMostConnectedPerson(completion: @escaping (String, Int) -> Void) {
        statisticsModel.fetchMostConnectedPerson { username, count in
            if let username = username {
                completion(username, count)
            } else {
                completion("No data", 0)
            }
        }
    }

    // MARK: - Fetch Connections Count by Date Range
    func fetchConnectionsCount(for range: DateRange, completion: @escaping (Int) -> Void) {
        statisticsModel.fetchConnectionsCount(dateRange: range) { count in
            completion(count)
        }
    }

    // MARK: - Fetch Longest Streak with a Friend
    func fetchLongestStreakWithFriend(completion: @escaping (String, Int) -> Void) {
        statisticsModel.fetchLongestStreakWithFriend { username, streakLength in
            if let username = username {
                completion(username, streakLength)
            } else {
                completion("No data", 0)
            }
        }
    }

    // MARK: - Fetch Current Longest Streak with a Friend
    func fetchCurrentStreakWithFriend(completion: @escaping (String, Int) -> Void) {
        statisticsModel.fetchCurrentStreakWithFriend { username, streakLength in
            if let username = username {
                completion(username, streakLength)
            } else {
                completion("No data", 0)
            }
        }
    }

    // MARK: - Fetch Least Connected Friend
    func fetchLeastConnectedFriend(completion: @escaping (String, Int) -> Void) {
        statisticsModel.fetchLeastConnectedFriend { username, count in
            if let username = username {
                completion(username, count)
            } else {
                completion("No data", 0)
            }
        }
    }
}
