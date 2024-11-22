import SwiftUI
import FirebaseAuth
import MapKit
import FirebaseFirestore

// Struct to represent a friend's location
struct FriendLocation: Identifiable {
    let id: String // Use the friend's ID as the unique identifier
    let coordinate: CLLocationCoordinate2D
    let username: String
}

struct MapView: View {
    @StateObject private var mapController = MapController(
        locationModel: LocationModel(),
        firestore: Firestore.firestore(),
        notificationController: NotificationController.shared
    )

    @State private var userIsInteracting = false
    @State private var showingFriendsScreen = false
    @State private var showingMessagesScreen = false
    @State private var showingActivityScreen = false
    @State private var showingProfileScreen = false // Added state variable
    @State private var isLockedToUserLocation = true // New state variable

    var body: some View {
        ZStack {
            if mapController.isLoading {
                ProgressView("Finding your location...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .padding()
            } else {
                // Map with user location and friend annotations
                Map(coordinateRegion: $mapController.region, showsUserLocation: true, annotationItems: mapController.friendLocationsList) { friend in
                    MapAnnotation(coordinate: friend.coordinate) {
                        VStack {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 15, height: 15)
                            Text(friend.username)
                                .font(.caption)
                                .foregroundColor(.black)
                                .background(Color.white.opacity(0.7))
                                .cornerRadius(4)
                        }
                    }
                }
                .ignoresSafeArea(edges: .all)
                .onAppear {
                    mapController.setupLocationListener()
                    mapController.startListeningToFriendLocations()
                }
                .gesture(
                    DragGesture().onChanged { _ in
                        userIsInteracting = true
                        isLockedToUserLocation = false // Unlock from user's location when the user moves the map
                        mapController.setUserMovedMap()
                    }
                )
            }

            // Top Buttons (Profile and Friends)
            VStack {
                HStack {
                    // Profile Button on the left
                    Button(action: {
                        showingProfileScreen = true
                    }) {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }
                    .padding(.leading)
                    
                    Spacer()
                    
                    // Friends Button on the right
                    Button(action: {
                        showingFriendsScreen = true
                    }) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }
                    .padding(.trailing)
                }
                .padding(.top, 20) // Adjust as needed for top padding
                Spacer()
            }

            // Location Button (Bottom Right)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        mapController.snapToUserLocation()
                        isLockedToUserLocation = true // Lock to user's location
                    }) {
                        Image(systemName: "location.north.fill") // Triangle icon
                            .foregroundColor(.white)
                            .padding()
                            .background(isLockedToUserLocation ? Color.black : Color.gray) // Indicate locked/unlocked state
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }
                    .padding()
                            .offset(x: -60, y: -2) // Adjust position slightly above and to the left
                }
            }

            // Bottom Buttons (Messages and Activity)
            VStack {
                Spacer()
                HStack {
                    // Messages Button (Bottom Left)
                    Button(action: {
                        showingMessagesScreen = true
                    }) {
                        Image(systemName: "message.fill")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }
                    .padding(.leading)
                    
                    Spacer()
                    
                    // Activity Button (Bottom Right)
                    Button(action: {
                        showingActivityScreen = true
                    }) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }
                    .padding(.trailing)
                }
                .padding(.bottom, 20) // Adjust as needed for bottom padding
            }
        }
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $showingFriendsScreen) {
            FriendsManagementView()
        }
        .fullScreenCover(isPresented: $showingMessagesScreen) {
            ChatListView()
        }
        .fullScreenCover(isPresented: $showingActivityScreen) {
            ActView(userId: Auth.auth().currentUser?.uid ?? "defaultUserId")
        }
        .fullScreenCover(isPresented: $showingProfileScreen) {
            NavigationView {
                ProfileView()
            }
        }
    }
}
