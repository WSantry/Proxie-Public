import SwiftUI
import CoreLocation
import FirebaseAuth

// Define LocationPair struct
struct LocationPair: Identifiable {
    let id = UUID()
    let start: CLLocationCoordinate2D
    let end: CLLocationCoordinate2D
}

struct ActView: View {
    @State private var mostConnectedPerson: String = "Loading..."
    @State private var mostConnectionsCount: Int = 0
    @State private var connectionsToday: Int = 0
    @State private var connectionsThisWeek: Int = 0
    @State private var connectionsThisMonth: Int = 0
    @State private var leastConnectedFriend: String = "Loading..."
    @State private var leastConnectionsCount: Int = 0
    @State private var longestStreakPerson: String = "Loading..."
    @State private var longestStreakLength: Int = 0
    @State private var currentStreakPerson: String = "Loading..."
    @State private var currentStreakLength: Int = 0
    @State private var connectionHistories: [ConnectionHistory] = []

    // Use LocationPair to control the sheet presentation
    @State private var locationPair: LocationPair?

    private var statisticsController: StatisticsController
    private var connectionHistoryController: ConnectionHistoryController
    private let popupMapController = PopupMapController()

    init(userId: String) {
        self.statisticsController = StatisticsController(userId: userId)
        self.connectionHistoryController = ConnectionHistoryController()
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Activity")
                    .font(.largeTitle)
                    .padding(.top)
                    .padding(.bottom, 5)
                    .padding(.leading, 140)

                Text("Log History")
                    .font(.title2)
                    .padding(.top)
                    .padding(.bottom, 5)
                    .padding(.leading, 10)

                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(connectionHistories) { connection in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("You proxied with \(connection.friendUsername) on \(formattedDate(connection.startTime)) near \(connection.formattedAddress)")
                                                .font(.body)
                                                .padding(.vertical, 5)
                                                .foregroundColor(.blue)
                                        }
                                        Rectangle()
                                            .frame(width: 1)
                                            .foregroundColor(Color.gray.opacity(0.5))
                                            .frame(maxHeight: .infinity)
                                        VStack {
                                            Text("Map")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Button(action: {
                                                if let userId = Auth.auth().currentUser?.uid {
                                                    print("User ID before fetching locations: \(userId)")
                                                    popupMapController.fetchStartAndEndLocations(for: connection.id, userId: userId) { start, end in
                                                        DispatchQueue.main.async {
                                                            if let start = start, let end = end {
                                                                print("Fetched start location: \(start), end location: \(end)")
                                                                self.locationPair = LocationPair(start: start, end: end)
                                                            } else {
                                                                print("Error fetching locations for connection: \(connection.id). Start or end is nil.")
                                                            }
                                                        }
                                                    }
                                                } else {
                                                    print("Error: No authenticated user.")
                                                }
                                            }) {
                                                Image(systemName: "map.fill")
                                                    .resizable()
                                                    .frame(width: 24, height: 24)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(radius: 2)
                                }
                            }
                            .padding()
                        }
                    )
                    .frame(height: 300)
                    .padding(.horizontal)

                Text("Fun Statistics")
                    .font(.title2)
                    .padding(.top, 0)
                    .padding(.leading, 10)

                Rectangle()
                    .fill(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    .frame(alignment: .top)
                    .frame(minHeight: .none, maxHeight: 160)
                    .overlay(
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Person You Have Connected With the Most: \(mostConnectedPerson)")
                            Text("Number of Connections Today: \(connectionsToday)")
                            Text("Number of Connections This Week: \(connectionsThisWeek)")
                            Text("Number of Connections This Month: \(connectionsThisMonth)")
                            Text("Least often connected friend: \(leastConnectedFriend)")
                            Text("Longest Consecutive Proximity Streak: \(longestStreakLength) WITH \(longestStreakPerson)")
                            Text("Current Longest Streak: \(currentStreakLength) WITH \(currentStreakPerson)")
                            Spacer()
                        }
                        .font(Font.custom("Inter", size: 14))
                        .foregroundColor(.black)
                    )
                    .padding(.horizontal)

                Spacer()

                HStack {
                    NavigationLink(destination: MapView()) {
                        Image(systemName: "map")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    Spacer()
                }
                .padding(.bottom, 20)
                .padding(.leading, 20)
            }
            // Present the PopupMapView using a sheet
            .sheet(item: $locationPair) { locations in
                PopupMapView(startLocation: locations.start, endLocation: locations.end)
                    .frame(width: 300, height: 400)
            }
            .onAppear {
                loadStatistics()
                fetchConnectionHistory()
            }
        }
    }

    private func loadStatistics() {
        statisticsController.fetchMostConnectedPerson { username, count in
            self.mostConnectedPerson = username
            self.mostConnectionsCount = count
        }

        statisticsController.fetchConnectionsCount(for: .today) { count in
            self.connectionsToday = count
        }

        statisticsController.fetchConnectionsCount(for: .thisWeek) { count in
            self.connectionsThisWeek = count
        }

        statisticsController.fetchConnectionsCount(for: .thisMonth) { count in
            self.connectionsThisMonth = count
        }

        statisticsController.fetchLeastConnectedFriend { username, count in
            self.leastConnectedFriend = username
            self.leastConnectionsCount = count
        }

        statisticsController.fetchLongestStreakWithFriend { username, streakLength in
            self.longestStreakPerson = username
            self.longestStreakLength = streakLength
        }

        statisticsController.fetchCurrentStreakWithFriend { username, streakLength in
            self.currentStreakPerson = username
            self.currentStreakLength = streakLength
        }
    }

    private func fetchConnectionHistory() {
        connectionHistoryController.fetchConnectionHistory { histories in
            self.connectionHistories = histories
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter.string(from: date)
    }
}
