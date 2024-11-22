import SwiftUI

struct TitleRow: View {
    var name: String

    var body: some View {
        HStack(spacing: 20) {
            Text(name)
                .font(.title).bold()

            Text("Online")
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()
        }
        .padding()
    }
}

struct TitleRow_Previews: PreviewProvider {
    static var previews: some View {
        TitleRow(name: "Sarah Smith")
    }
}
