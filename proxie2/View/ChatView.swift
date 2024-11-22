import SwiftUI

struct ChatView: View {
    var userId: String    // Friend's user ID
    var username: String  // Friend's username

    @StateObject private var messagesManager = MessagesController()

    var body: some View {
        VStack {
            // Custom title bar with the friend's name
            TitleRow(name: username)

            // Scroll view to display messages
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(messagesManager.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .onChange(of: messagesManager.lastMessageId) { id in
                    withAnimation {
                        proxy.scrollTo(id, anchor: .bottom)
                    }
                }
            }

            // Message input field
            MessageField(receiverId: userId)
                .environmentObject(messagesManager)
        }
        .onAppear {
            messagesManager.getMessages(with: userId)  // Start listening to messages
        }
        .onDisappear {
            messagesManager.removeListener()  // Stop listening to messages
        }
    }
}
