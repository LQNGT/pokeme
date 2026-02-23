import SwiftUI

struct AvatarView: View {
    let base64Picture: String?
    let displayName: String
    var size: CGFloat = 50
    var borderSize: CGFloat = 3

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [UCDavisPalette.deepBlue, UCDavisPalette.navy, UCDavisPalette.gold],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size + borderSize * 2, height: size + borderSize * 2)

            if let img = decodedImage {
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(UCDavisPalette.surface)
                    .frame(width: size, height: size)
                    .overlay(
                        Text(displayName.prefix(1).uppercased())
                            .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                            .foregroundStyle(.linearGradient(
                                colors: [UCDavisPalette.gold, UCDavisPalette.deepBlue],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
            }
        }
        .accessibilityLabel("\(displayName)'s profile picture")
    }

    private var decodedImage: UIImage? {
        guard let data = base64Picture else { return nil }
        let stripped = data.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
        guard let imageData = Data(base64Encoded: stripped) else { return nil }
        return UIImage(data: imageData)
    }
}
