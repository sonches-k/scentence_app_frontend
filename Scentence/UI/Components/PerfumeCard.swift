import SwiftUI

struct PerfumeCard: View {
    let perfume: PerfumeWithRelevance
    @State private var summaryExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(perfume.brand.uppercased())
                    .font(AppFont.caption(10))
                    .foregroundColor(AppColor.accent)
                    .tracking(2)

                Spacer()

                RelevanceBadge(score: perfume.relevanceScore)
            }

            Text(perfume.name)
                .font(AppFont.title(18))
                .foregroundColor(AppColor.textPrimary)
                .lineLimit(2)

            HStack(spacing: 10) {
                if let family = perfume.family {
                    MetaTag(text: family)
                }
                if let gender = perfume.gender {
                    MetaTag(text: gender)
                }
            }

            let allNotes = perfume.notePyramid.allNotes
            if !allNotes.isEmpty {
                Text(allNotes.prefix(5).joined(separator: " · "))
                    .font(AppFont.caption(12))
                    .foregroundColor(AppColor.textMuted)
                    .lineLimit(1)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColor.cardBorder.opacity(0.3))
                        .frame(height: 3)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppColor.accent.opacity(0.6), AppColor.accent],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(perfume.relevanceScore), height: 3)
                }
            }
            .frame(height: 3)

            if let summary = perfume.reviewSummary, !summary.isEmpty {
                Divider().overlay(AppColor.cardBorder.opacity(0.4))

                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        summaryExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(summaryExpanded ? "Скрыть" : "Подробнее")
                            .font(AppFont.caption(11))
                            .foregroundColor(AppColor.accent)
                        Spacer()
                        Image(systemName: summaryExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppColor.accent)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if summaryExpanded {
                    Text(summary)
                        .font(AppFont.caption(12))
                        .foregroundColor(AppColor.textSecondary)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(16)
        .cardStyle()
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.22), value: summaryExpanded)
    }
}

// MARK: - RelevanceBadge

struct RelevanceBadge: View {
    let score: Double

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "sparkle")
                .font(.system(size: 8))
            Text("\(Int((score * 100).rounded()))%")
                .font(AppFont.mono(11))
                .fontWeight(.semibold)
            Text("match")
                .font(.system(size: 9, weight: .regular, design: .default))
        }
        .foregroundColor(AppColor.accent)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(AppColor.accent.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - MetaTag

struct MetaTag: View {
    let text: String
    var body: some View {
        Text(text)
            .font(AppFont.caption(11))
            .foregroundColor(AppColor.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(AppColor.accent.opacity(0.08))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(AppColor.accent.opacity(0.25), lineWidth: 0.75))
    }
}
