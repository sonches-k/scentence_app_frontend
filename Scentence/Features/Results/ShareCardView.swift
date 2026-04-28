import SwiftUI

// MARK: - ShareCardView

/// Карточка для рендера через ImageRenderer — адаптируется к текущей теме приложения.
struct ShareCardView: View {
    let query: String
    let filterChips: [String]
    let pyramid: NotePyramid
    let perfumes: [PerfumeWithRelevance]
    let totalFound: Int

    @Environment(\.colorScheme) private var scheme

    private let W: CGFloat = 360

    private var bg: Color     { scheme == .dark ? Color(hex: "#1A1F2E") : Color(hex: "#F5EFEB") }
    private var accent: Color { Color(hex: "#A0707E") }
    private var navy: Color   { scheme == .dark ? Color(hex: "#E8DDD5") : Color(hex: "#2F4156") }
    private var sub: Color    { scheme == .dark ? Color(hex: "#9AABB8") : Color(hex: "#4A5E6E") }
    private var muted: Color  { scheme == .dark ? Color(hex: "#6B7D8D") : Color(hex: "#6B7D8D") }
    private var card: Color   { scheme == .dark ? Color(hex: "#252B3B") : Color(hex: "#FFFFFF") }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow

            VStack(alignment: .leading, spacing: 14) {
                queryBlock
                if !pyramid.isEmpty { pyramidBlock }
                perfumesBlock
                footerRow
            }
            .padding(20)
        }
        .frame(width: W)
        .background(bg)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            HStack(spacing: 5) {
                Text("✦")
                    .font(.system(size: 13))
                    .foregroundColor(accent)
                Text("SCENTENCE")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundColor(navy)
                    .tracking(1.5)
            }
            Spacer()
            Text("Твой помощник в подборе\nидеального аромата")
                .font(.system(size: 10))
                .foregroundColor(muted)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
        .background(accent.opacity(0.08))
    }

    // MARK: - Query + filters

    private var queryBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundColor(accent)
                Text(query)
                    .font(.system(size: 13))
                    .foregroundColor(sub)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if !filterChips.isEmpty {
                Text(filterChips.joined(separator: "  ·  "))
                    .font(.system(size: 11))
                    .foregroundColor(accent.opacity(0.85))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Note pyramid

    private var pyramidBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ПИРАМИДА НОТ")
                .font(.system(size: 10))
                .foregroundColor(sub)
                .tracking(2)

            VStack(spacing: 5) {
                if !pyramid.top.isEmpty    { pyramidRow("Верхние", pyramid.top, accent) }
                if !pyramid.middle.isEmpty { pyramidRow("Средние", pyramid.middle, sub) }
                if !pyramid.base.isEmpty   { pyramidRow("Базовые", pyramid.base, muted) }
            }
        }
    }

    private func pyramidRow(_ label: String, _ notes: [String], _ color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 52, alignment: .leading)
            Text(notes.joined(separator: " · "))
                .font(.system(size: 12))
                .foregroundColor(navy)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Perfumes (top 3)

    private var perfumesBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(accent.opacity(0.25))
                .frame(height: 1)

            Text("ПОДБОРКА")
                .font(.system(size: 10))
                .foregroundColor(sub)
                .tracking(2)

            VStack(spacing: 5) {
                ForEach(Array(perfumes.prefix(3).enumerated()), id: \.offset) { idx, p in
                    HStack(spacing: 10) {
                        Text("\(idx + 1)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(accent)
                            .frame(width: 14)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.brand.uppercased())
                                .font(.system(size: 9))
                                .foregroundColor(accent)
                                .tracking(1)
                            Text(p.name)
                                .font(.system(size: 13, weight: .light, design: .serif))
                                .foregroundColor(navy)
                                .lineLimit(1)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            if let family = p.family {
                                Text(family)
                                    .font(.system(size: 9))
                                    .foregroundColor(muted)
                            }
                            Text("\(p.relevancePercent)%")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(accent)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(card.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            if totalFound > 3 {
                let shown = min(perfumes.count, 3)
                Text("+ ещё \(totalFound - shown) в приложении")
                    .font(.system(size: 10))
                    .foregroundColor(muted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack {
            Text("Найдено \(totalFound) ароматов")
                .font(.system(size: 10))
                .foregroundColor(muted)
            Spacer()
            Text("scentence.app")
                .font(.system(size: 10))
                .foregroundColor(accent)
        }
    }
}
