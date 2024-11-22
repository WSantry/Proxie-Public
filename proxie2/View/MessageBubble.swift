import SwiftUI
import FirebaseAuth

struct MessageBubble: View {
    var message: MessageModel

    var body: some View {
        VStack(alignment: message.senderId == Auth.auth().currentUser?.uid ? .trailing : .leading, spacing: 4) {
            HStack {
                Text(message.content)
                    .padding()
                    .background(message.senderId == Auth.auth().currentUser?.uid ? Color.blue : Color.gray)
                    .cornerRadius(30)
            }
            .frame(maxWidth: 300, alignment: message.senderId == Auth.auth().currentUser?.uid ? .trailing : .leading)

            Text("\(message.timestamp.formatted(.dateTime.hour().minute()))")
                .font(.caption2)
                .foregroundColor(.gray)
                .padding(message.senderId == Auth.auth().currentUser?.uid ? .trailing : .leading, 25)
        }
        .frame(maxWidth: .infinity, alignment: message.senderId == Auth.auth().currentUser?.uid ? .trailing : .leading)
        .padding(message.senderId == Auth.auth().currentUser?.uid ? .trailing : .leading)
    }
}
