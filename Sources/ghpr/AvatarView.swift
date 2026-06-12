import Foundation
import SwiftUI

/// A circular user avatar with a neutral placeholder.
struct AvatarView: View {
    let urlString: String?
    var size: CGFloat = 22

    var body: some View {
        AsyncImage(url: urlString.flatMap(URL.init(string:))) { image in
            image.resizable()
        } placeholder: {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .foregroundStyle(.tertiary)
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
    }
}
