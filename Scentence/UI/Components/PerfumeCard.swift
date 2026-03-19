import SwiftUI

struct PerfumeCard: View {
    let perfume: PerfumeWithRelevance

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(perfume.brand.uppercased())
                    .font(AppFont.caption(10))
                    .foregroundColor(AppColor.gold)
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
                                colors: [AppColor.gold.opacity(0.6), AppColor.gold],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(perfume.relevanceScore), height: 3)
                }
            }
            .frame(height: 3)
        }
        .padding(16)
        .cardStyle()
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .foregroundColor(AppColor.gold)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(AppColor.gold.opacity(0.1))
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
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(AppColor.cardBorder.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
