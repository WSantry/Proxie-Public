import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @Binding var showSignUpView: Bool

    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var profileMonster: String = "default_monster"
    @State private var signUpError: String? = nil
    @State private var isSignedUp = false
    @State private var showSuccessMessage = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [
                    Color(red: 0.62, green: 0.86, blue: 0.92),
                    Color(red: 0.10, green: 0.43, blue: 0.50)
                ]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    Spacer()
                    Text("Create Your Account")
                        .font(Font.custom("Roboto", size: 20).weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.bottom, 20)

                    TextField("Username", text: $username)
                        .padding()
                        .frame(width: 362, height: 44)
                        .background(Color(red: 0.85, green: 0.85, blue: 0.85))
                        .cornerRadius(12)
                        .font(Font.custom("Poppins", size: 15).weight(.semibold))

                    TextField("Email", text: $email)
                        .padding()
                        .frame(width: 362, height: 44)
                        .background(Color(red: 0.85, green: 0.85, blue: 0.85))
                        .cornerRadius(12)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .padding()
                        .frame(width: 362, height: 44)
                        .background(Color(red: 0.85, green: 0.85, blue: 0.85))
                        .cornerRadius(12)
                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .frame(width: 362, height: 44)
                        .background(Color(red: 0.85, green: 0.85, blue: 0.85))
                        .cornerRadius(12)

                    Text("Pick your monster!")
                        .font(Font.custom("Poppins", size: 15).weight(.medium))
                        .foregroundColor(.white)
                    HStack(spacing: 18) {
                        ForEach(1...3, id: \.self) { index in
                            Ellipse()
                                .foregroundColor(profileMonster == "monster_\(index)" ? .blue : .clear)
                                .frame(width: 100, height: 100)
                                .background(Color(red: 0.85, green: 0.85, blue: 0.85))
                                .onTapGesture { profileMonster = "monster_\(index)" }
                        }
                    }

                    Button(action: {
                        signUpUser()
                    }) {
                        Text("Sign Up")
                            .font(Font.custom("Roboto", size: 15).weight(.semibold))
                            .frame(width: 362, height: 44)
                            .background(Color(red: 0.85, green: 0.85, blue: 0.85))
                            .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
                            .cornerRadius(12)
                    }

                    if let signUpError = signUpError {
                        Text(signUpError)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.top, 5)
                    }

                    if showSuccessMessage {
                        Text("Your account has been created successfully!\nYou will be redirected to the login screen in 5 seconds.")
                            .foregroundColor(.green)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.top, 5)
                    }

                    Spacer()
                }
            }
            .frame(width: 430, height: 932)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showSignUpView = false
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
    }

    func signUpUser() {
        guard password.count >= 8,
              password.range(of: "[A-Z]", options: .regularExpression) != nil,
              password.range(of: "[0-9]", options: .regularExpression) != nil,
              password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil else {
            signUpError = "Password must be at least 8 characters long, with one uppercase, one number, and one special character."
            return
        }

        guard password == confirmPassword else {
            signUpError = "Passwords do not match."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    signUpError = error.localizedDescription
                } else if let user = authResult?.user {
                    signUpError = nil
                    isSignedUp = true

                    let db = Firestore.firestore()
                    let userData: [String: Any] = [
                        "username": username,
                        "profilePictureMonster": profileMonster,
                        "joinDate": Timestamp(date: Date()),
                        "locationData": [
                            "currentLocation": NSNull(),
                            "lastUpdated": NSNull()
                        ],
                        "privateData": [
                            "email": email,
                            "friends": [],
                            "friendRequests": []
                        ]
                    ]
                    db.collection("users").document(user.uid).setData(userData) { err in
                        if let err = err {
                            print("Error adding user data: \(err)")
                            signUpError = "Error saving user data: \(err.localizedDescription)"
                        } else {
                            print("User data added to Firestore!")
                            showSuccessMessage = true
                                                   startSignOutTimer()
                        }
                    }
                }
            }
        }
    }

 

    func startSignOutTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            signOutUser()
        }
    }

    func signOutUser() {
        do {
            try Auth.auth().signOut()
            print("User signed out successfully.")
            username = ""
            email = ""
            password = ""
            confirmPassword = ""
            profileMonster = "default_monster"
            showSignUpView = false
        } catch let signOutError as NSError {
            DispatchQueue.main.async {
                signUpError = "Error signing out: \(signOutError.localizedDescription)"
                print("Error signing out: \(signOutError.localizedDescription)")
            }
        }
    }
}
