import SwiftUI
struct ActivityView: View {
    @Environment(\.presentationMode) var presentationMode
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
    
    @State private var rectangleWidth: CGFloat = 402
      @State private var rectangleHeight: CGFloat = 393
      @State private var rectanglePosition = CGPoint(x: 238, y: 393) // Initial position
    @State private var connectionHistories: [ConnectionHistory] = [] // Store fetched connection histories
    
    private var statisticsController: StatisticsController
    
    init(userId: String) {
        self.statisticsController = StatisticsController(userId: userId)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Group {
                    Text("Activity")
                        .font(Font.custom("Inter", size: 40))
                        .foregroundColor(.black)
                        .offset(x: 3, y: -370)
                    
                    // Rest of your UI elements...
                }
                Group {
                    Text("Activity")
                        .font(Font.custom("Inter", size: 40))
                        .foregroundColor(.black)
                        .offset(x: 3, y: -370)
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 439, height: 23)
                        .background(.white)
                        .overlay(
                            Rectangle()
                                .inset(by: 0.50)
                                .stroke(.black, lineWidth: 0.50)
                        )
                        .offset(x: 3.50, y: 195.50)
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 447, height: 25)
                        .background(.white)
                        .overlay(
                            Rectangle()
                                .inset(by: 0.50)
                                .stroke(.black, lineWidth: 0.50)
                        )
                        .offset(x: -0.50, y: 217.50)
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 452, height: 27)
                        .background(.white)
                        .overlay(
                            Rectangle()
                                .inset(by: 0.50)
                                .stroke(.black, lineWidth: 0.50)
                        )
                        .offset(x: -3, y: 261.50)
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 436, height: 22)
                        .background(.white)
                        .overlay(
                            Rectangle()
                                .inset(by: 0.50)
                                .stroke(.black, lineWidth: 0.50)
                        )
                        .offset(x: 1, y: 239)
                }
                Group {
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 436, height: 22)
                        .background(.white)
                        .overlay(
                            Rectangle()
                                .inset(by: 0.50)
                                .stroke(.black, lineWidth: 0.50)
                        )
                        .offset(x: 1, y: 282)
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 445, height: 25)
                        .background(.white)
                        .overlay(
                            Rectangle()
                                .inset(by: 0.50)
                                .stroke(.black, lineWidth: 0.50)
                        )
                        .offset(x: 0.50, y: 303.50)
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 476, height: 23)
                        .background(.white)
                        .overlay(
                            Rectangle()
                                .inset(by: 0.50)
                                .stroke(.black, lineWidth: 0.50)
                        )
                        .offset(x: 0.50, y: 320.50)
                    Text("Connections log")
                        .font(Font.custom("Inter", size: 40))
                        .foregroundColor(.black)
                        .offset(x: -55, y: -302)
                    Text("Random Statistics ")
                        .font(Font.custom("Inter", size: 40))
                        .foregroundColor(.black)
                        .offset(x: -6.50, y: 151)
                    ZStack() {
                    }
                    .frame(width: 41, height: 40)
                    .offset(x: 195.50, y: -251)
                }
                Group {
                    Text("Person You Have Connected With the Most: \(mostConnectedPerson)")
                        .font(Font.custom("Inter", size: 14))
                        .foregroundColor(.black)
                        .offset(x: -35, y: 195)
                    Text("Number of Connections Today: \(connectionsToday)")
                        .font(Font.custom("Inter", size: 14))
                        .foregroundColor(.black)
                        .offset(x: -82.5, y: 216.50)
                    Text("Number of Connections This week: \(connectionsThisWeek)")
                        .font(Font.custom("Inter", size: 14))
                        .foregroundColor(.black)
                        .offset(x: -70.50, y: 238.50)
                    Text("Number of connections This Month: \(connectionsThisMonth)")
                        .font(Font.custom("Inter", size: 14))
                        .foregroundColor(.black)
                        .offset(x: -68.50, y: 258.50)
                    Text("Least often connected friend: \(leastConnectedFriend)")
                        .font(Font.custom("Inter", size: 14))
                        .foregroundColor(.black)
                        .offset(x: -80.50, y: 301.50)
                    Text("Longest Consecutive Proximity Streak: \(longestStreakLength) WITH \(longestStreakPerson)")
                        .font(Font.custom("Inter", size: 14))
                        .foregroundColor(.black)
                        .offset(x: -23, y: 280)
                    Text("Current Longest Streak: \(currentStreakLength) WITH \(currentStreakPerson)")
                        .font(Font.custom("Inter", size: 14))
                        .foregroundColor(.black)
                        .offset(x: -70, y: 322)
                    ZStack() {
                    }
                    .frame(width: 65, height: 68)
                    .offset(x: -183.50, y: 427)
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 430, height: 131)
                        .overlay(
                            Rectangle()
                                .inset(by: 0.50)
                                .stroke(.black, lineWidth: 0.50)
                        )
                        .offset(x: 0, y: -400.50)
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 430, height: 66)
                        .overlay(
                            Rectangle()
                                .inset(by: 0.50)
                                .stroke(.black, lineWidth: 0.50)
                        )
                        .offset(x: 0, y: -302)
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 432, height: 63)
                        .overlay(
                            Rectangle()
                                .inset(by: 0.50)
                                .stroke(.black, lineWidth: 0.50)
                        )
                        .offset(x: 0, y: 153.50)
                }
                
               
                // Map button in the bottom left corner
                VStack {
                    Spacer() // Pushes the button to the bottom
                    HStack {
                        NavigationLink(destination: MapView()) {
                            Image(systemName: "map")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                                .foregroundColor(.black)
                        }
                        Spacer() // Pushes the button to the left
                    }
                    .padding(.bottom, 50) // Adjusts the bottom padding for placement
                    .padding(.leading, 60) // Adjusts the left padding for placement
                }
            }
            .frame(width: 430, height: 932)
            .background(Color(red: 0.53, green: 0.81, blue: 0.92))
            .onAppear(perform: loadStatistics)
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
    
    private func formattedDate(_ date: Date) -> String {
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
          return dateFormatter.string(from: date)
      }
}
struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView(userId: "ktranxswhuWAuMiHnuSId5SPS762")
    }
}


