import SwiftUI

struct MessageField: View {
    var receiverId: String
    @EnvironmentObject var messagesManager: MessagesController
    @State private var message = ""
    
    var body: some View {
        HStack {
            CustomTextField(placeholder: Text("Enter your message here"), text: $message)
                .frame(height: 52)
                .disableAutocorrection(true)
            
            Button {
                if !message.isEmpty {
                    messagesManager.sendMessage(text: message, receiverId: receiverId)
                    message = ""
                }
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.blue)
                    .cornerRadius(50)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(50)
        .padding()
    }
    
    
    
    // CustomTextField view for reusable placeholder text
    struct CustomTextField: View {
        var placeholder: Text
        @Binding var text: String
        var editingChanged: (Bool) -> Void = { _ in }
        var commit: () -> Void = { }
        
        var body: some View {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    placeholder
                        .opacity(0.5)
                }
                TextField("", text: $text, onEditingChanged: editingChanged, onCommit: commit)
            }
        }
    }
    
}
