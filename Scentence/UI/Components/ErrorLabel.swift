import SwiftUI

struct ErrorLabel: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 13))
            Text(text)
                .font(AppFont.caption(13))
        }
        .foregroundColor(AppColor.error)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
