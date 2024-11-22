//
//  ProfileView.swift
//  proxie2
//
//  Created by Willem Santry on 11/8/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode

    @AppStorage("isLoggedIn") private var isLoggedIn = true // Tracks authentication state

    @State private var username: String = ""
    @State private var showEditUsername: Bool = false
    @State private var newUsername: String = ""

    @State private var selectedStatus: String = ""
    @State private var joinDate: String = ""

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    let statuses = ["Willing to talk", "Open to possibilities", "Currently unavailable", "Incognito"]

    var body: some View {
        VStack {
            // Profile Picture Placeholder
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 100)
                Text("Photo")
                    .foregroundColor(.gray)
            }
            .padding(.top, 50)

            // Username and Edit Button
            HStack {
                Text(username)
                    .font(.title)
                    .fontWeight(.bold)
                Button(action: {
                    self.newUsername = self.username
                    self.showEditUsername = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
            }
            .padding(.top, 20)

            // Statuses
            VStack(alignment: .leading) {
                Text("Status")
                    .font(.headline)
                    .padding(.top, 30)
                ForEach(statuses, id: \.self) { status in
                    Button(action: {
                        self.updateStatus(status)
                    }) {
                        HStack {
                            Image(systemName: self.selectedStatus == status ? "checkmark.square" : "square")
                                .foregroundColor(.blue)
                            Text(status)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .padding(.horizontal, 30)

            // Explanations of statuses
            VStack(alignment: .leading, spacing: 10) {
                Text("Status Explanations:")
                    .font(.headline)
                Text("• Willing to talk: Open to conversations.")
                Text("• Open to possibilities: Interested in opportunities.")
                Text("• Currently unavailable: Not available right now.")
                Text("• Incognito: Appear offline to others.")
            }
            .padding(.top, 20)
            .padding(.horizontal, 30)

            // Join Date
            if !joinDate.isEmpty {
                Text("Date Joined: \(joinDate)")
                    .padding(.top, 20)
            }

            Spacer()

            // Logout Button
            Button(action: {
                self.logout()
            }) {
                Text("Logout")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                    .padding(.horizontal, 30)
            }
            .padding(.bottom, 20)
        }
        .navigationBarTitle("Profile", displayMode: .inline)
        .navigationBarItems(leading:
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(.blue)
            }
        )
        .onAppear {
            self.fetchUserData()
        }
        .sheet(isPresented: $showEditUsername) {
            EditUsernameView(username: self.$newUsername, onSave: {
                self.updateUsername()
            })
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(self.alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    // Fetch user data from Firestore
    private func fetchUserData() {
        guard let user = Auth.auth().currentUser else {
            self.alertMessage = "No user is logged in."
            self.showAlert = true
            return
        }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)

        userRef.getDocument { (document, error) in
            if let error = error {
                self.alertMessage = "Error fetching user data: \(error.localizedDescription)"
                self.showAlert = true
            } else if let document = document, document.exists {
                let data = document.data()
                self.username = data?["username"] as? String ?? "Unknown"
                self.selectedStatus = data?["status"] as? String ?? ""

                // Fetching the JoinDate field, ensuring correct field name and type
                if let timestamp = data?["joinDate"] as? Timestamp {
                    let date = timestamp.dateValue()
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MM/dd/yyyy"
                    self.joinDate = dateFormatter.string(from: date)
                } else if let joinDateString = data?["joinDate"] as? String {
                    self.joinDate = joinDateString
                } else {
                    self.joinDate = "Unknown"
                }
            } else {
                self.alertMessage = "User document does not exist."
                self.showAlert = true
            }
        }
    }

    // Update username in Firestore
    private func updateUsername() {
        guard let user = Auth.auth().currentUser else {
            self.alertMessage = "No user is logged in."
            self.showAlert = true
            return
        }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)

        userRef.updateData([
            "username": self.newUsername
        ]) { error in
            if let error = error {
                self.alertMessage = "Error updating username: \(error.localizedDescription)"
                self.showAlert = true
            } else {
                self.username = self.newUsername
                self.showEditUsername = false
            }
        }
    }

    // Update status in Firestore
    private func updateStatus(_ status: String) {
        guard let user = Auth.auth().currentUser else {
            self.alertMessage = "No user is logged in."
            self.showAlert = true
            return
        }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)

        userRef.updateData([
            "status": status
        ]) { error in
            if let error = error {
                self.alertMessage = "Error updating status: \(error.localizedDescription)"
                self.showAlert = true
            } else {
                self.selectedStatus = status
            }
        }
    }

    // Logout user
    private func logout() {
        do {
            try Auth.auth().signOut()
            // No need to manually navigate back; ContentView will handle it
        } catch let signOutError as NSError {
            self.alertMessage = "Error signing out: \(signOutError.localizedDescription)"
            self.showAlert = true
        }
    }
}

struct EditUsernameView: View {
    @Binding var username: String
    var onSave: () -> Void

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                TextField("Username", text: $username)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Spacer()
            }
            .navigationBarTitle("Edit Username", displayMode: .inline)
            .navigationBarItems(leading:
                Button("Cancel") {
                    self.presentationMode.wrappedValue.dismiss()
                },
                trailing:
                Button("Save") {
                    self.onSave()
                    self.presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
        }
    }
}
