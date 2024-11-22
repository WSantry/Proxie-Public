import SwiftUI

struct LoginView: View {
    @StateObject private var controller = LoginController()
    @Binding var showSignUpView: Bool // Added binding for showSignUpView

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(gradient: Gradient(colors: [
                    Color(red: 0.62, green: 0.86, blue: 0.92),
                    Color(red: 0.10, green: 0.43, blue: 0.50)
                ]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    // Title
                    Text("Login to connect")
                        .font(Font.custom("Roboto", size: 20).weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.bottom, 30)

                    // Email field
                    TextField("Email", text: $controller.email)
                        .padding()
                        .frame(width: 362, height: 44)
                        .background(Color(red: 0.85, green: 0.85, blue: 0.85))
                        .cornerRadius(12)
                        .font(Font.custom("Poppins", size: 15).weight(.semibold))
                        .foregroundColor(Color(red: 0.38, green: 0.38, blue: 0.38))
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    // Password field
                    SecureField("Password", text: $controller.password)
                        .padding()
                        .frame(width: 362, height: 44)
                        .background(Color(red: 0.85, green: 0.85, blue: 0.85))
                        .cornerRadius(12)
                        .font(Font.custom("Poppins", size: 15).weight(.semibold))
                        .foregroundColor(Color(red: 0.38, green: 0.38, blue: 0.38))

                    // Forgot password button with NavigationLink
                    NavigationLink(destination: ForgotPasswordView()) {
                        Text("Forgot password?")
                            .font(Font.custom("Poppins", size: 12).weight(.medium))
                            .foregroundColor(Color(red: 1, green: 0.10, blue: 0.12))
                            .padding(.top, -10)
                            .frame(alignment: .trailing)
                    }

                    // Sign in button
                    Button(action: {
                        controller.signIn()
                    }) {
                        Text("Sign In")
                            .font(Font.custom("Roboto", size: 15).weight(.semibold))
                            .frame(width: 362, height: 44)
                            .background(Color(red: 0.85, green: 0.85, blue: 0.85))
                            .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
                            .cornerRadius(12)
                    }

                    // Display login error message if any
                    if let loginError = controller.error {
                        Text(loginError)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.top, 5)
                    }

                    // Create Account Button
                    Button(action: {
                        showSignUpView = true // Set showSignUpView to true to present SignUpView
                    }) {
                        Text("Don't have an account? Sign up")
                            .font(Font.custom("Poppins", size: 12).weight(.medium))
                            .foregroundColor(Color(red: 1, green: 0.10, blue: 0.10))
                    }
                }
                .offset(y: -110) // Move everything up by 1/4 of the screen
            }
            .frame(width: 430, height: 932)
        }
    }
}
