import SwiftUI
struct ForgotPasswordView: View {
    @StateObject private var controller = ForgotPasswordController()
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.62, green: 0.86, blue: 0.92), Color(red: 0.10, green: 0.43, blue: 0.50)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Spacer()
                
                VStack(spacing: 30) {
                    Text("Forgot your password? Enter your email here to reset it")
                        .font(Font.custom("Roboto", size: 20).weight(.semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    TextField("Enter your email", text: $controller.email)
                        .padding()
                        .frame(width: 307, height: 44)
                        .background(Color(red: 0.85, green: 0.85, blue: 0.85))
                        .cornerRadius(12)
                        .font(Font.custom("Poppins", size: 15).weight(.semibold))
                        .foregroundColor(Color(red: 0.38, green: 0.38, blue: 0.38))
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    Button(action: {
                        controller.sendPasswordReset()
                    }) {
                        Text("Reset Password")
                            .font(Font.custom("Roboto", size: 15).weight(.semibold))
                            .frame(width: 307, height: 44)
                            .background(Color(red: 0.85, green: 0.85, blue: 0.85))
                            .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
                            .cornerRadius(12)
                    }
                    
                    if let error = controller.error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                    
                    if let successMessage = controller.successMessage {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.footnote)
                    }
                }
                Spacer()
            }
        }
        .frame(width: 430, height: 932)
        .navigationBarBackButtonHidden(false)
    }
}

