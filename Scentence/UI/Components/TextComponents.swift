import SwiftUI

// MARK: - ExpandableMarkdownText

struct ExpandableMarkdownText: View {
    let text: String
    var font: Font = AppFont.body(15)
    var color: Color = AppColor.textPrimary
    var lineSpacing: CGFloat = 5
    var collapsedLineLimit: Int = 5
    var charThreshold: Int = 200

    @State private var isExpanded = false

    private var needsTruncation: Bool { text.count > charThreshold }

    private var attributed: AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(attributed)
                .font(font)
                .foregroundColor(color)
                .lineSpacing(lineSpacing)
                .lineLimit(isExpanded || !needsTruncation ? nil : collapsedLineLimit)
                .fixedSize(horizontal: false, vertical: !needsTruncation || isExpanded)

            if needsTruncation {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
                } label: {
                    Text(isExpanded ? "Свернуть" : "Показать полностью")
                        .font(AppFont.caption(13))
                        .foregroundColor(AppColor.accent)
                }
            }
        }
    }
}

// MARK: - MarkdownText

struct MarkdownText: View {
    let text: String
    var font: Font = AppFont.body(15)
    var color: Color = AppColor.textPrimary
    var lineSpacing: CGFloat = 4

    private var attributed: AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }

    var body: some View {
        Text(attributed)
            .font(font)
            .foregroundColor(color)
            .lineSpacing(lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - InfoButton

struct InfoButton: View {
    let text: String
    @State private var isPresented = false

    var body: some View {
        Button { isPresented.toggle() } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 14))
                .foregroundColor(AppColor.textMuted)
        }
        .popover(isPresented: $isPresented, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
            ScrollView {
                Text(text)
                    .font(AppFont.body(14))
                    .foregroundColor(AppColor.textPrimary)
                    .lineSpacing(6)
                    .padding(18)
                    .frame(maxWidth: 280, alignment: .leading)
            }
            .frame(maxWidth: 280, maxHeight: 220)
            .background(.ultraThinMaterial)
            .background(AppColor.accent.opacity(0.06))
            .presentationCompactAdaptation(.popover)
        }
    }
}
