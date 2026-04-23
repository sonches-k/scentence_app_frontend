import SwiftUI

struct ResultsView: View {
    let response: SearchResponse
    let query: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 0) {
                    explanationSection
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 24)

                    AccentDivider().padding(.horizontal, 24)

                    if !response.notePyramid.isEmpty {
                        NotePyramidSection(pyramid: response.notePyramid)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)

                        AccentDivider().padding(.horizontal, 24)
                    }

                    VStack(spacing: 12) {
                        ForEach(response.perfumes) { perfume in
                            NavigationLink {
                                PerfumeDetailView(perfumeId: perfume.id)
                            } label: {
                                PerfumeCard(perfume: perfume)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Результаты")
        .navigationBarTitleDisplayMode(.inline)
        .glassNavBar()
        .tint(AppColor.accent)
    }

    // MARK: - Explanation Section

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundColor(AppColor.accent)
                Text(query)
                    .font(AppFont.caption(13))
                    .foregroundColor(AppColor.textSecondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppColor.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            ExpandableMarkdownText(text: response.explanation)

            Text("Найдено \(response.totalFound) ароматов")
                .font(AppFont.caption(12))
                .foregroundColor(AppColor.textMuted)
        }
    }
}

// MARK: - NotePyramidSection (block-style note layers)

struct NotePyramidSection: View {
    let pyramid: NotePyramid

    private struct TierStyle {
        let label: String
        let hint: String
        let bg: Color
        let pillBg: Color
        let pillBorder: Color
        let pillText: Color
        let accent: Color
    }

    private static let styles: [TierStyle] = [
        TierStyle(
            label: "Верхние", hint: "Первое впечатление",
            bg: AppColor.accent.opacity(0.12),
            pillBg: AppColor.accent.opacity(0.08),
            pillBorder: AppColor.accent.opacity(0.55),
            pillText: AppColor.accent,
            accent: AppColor.accent
        ),
        TierStyle(
            label: "Сердце", hint: "Раскрывается за 15 мин",
            bg: AppColor.textSecondary.opacity(0.10),
            pillBg: AppColor.textSecondary.opacity(0.08),
            pillBorder: AppColor.textSecondary.opacity(0.50),
            pillText: AppColor.textPrimary,
            accent: AppColor.textSecondary
        ),
        TierStyle(
            label: "База", hint: "Звучит часами",
            bg: AppColor.textMuted.opacity(0.10),
            pillBg: AppColor.textMuted.opacity(0.08),
            pillBorder: AppColor.textMuted.opacity(0.50),
            pillText: AppColor.textPrimary,
            accent: AppColor.textMuted
        ),
    ]

    private var tiers: [(notes: [String], style: TierStyle)] {
        var result: [(notes: [String], style: TierStyle)] = []
        if !pyramid.top.isEmpty    { result.append((pyramid.top,    Self.styles[0])) }
        if !pyramid.middle.isEmpty { result.append((pyramid.middle, Self.styles[1])) }
        if !pyramid.base.isEmpty   { result.append((pyramid.base,   Self.styles[2])) }
        return result
    }

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 14) {
            Text("ПИРАМИДА НОТ")
                .font(AppFont.caption(11))
                .foregroundColor(AppColor.textSecondary)
                .tracking(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 10) {
                ForEach(Array(tiers.enumerated()), id: \.offset) { tierIdx, tier in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text(tier.style.label)
                                .font(.system(size: 12, weight: .semibold, design: .default))
                                .foregroundColor(tier.style.accent)

                            Text("·")
                                .foregroundColor(tier.style.accent.opacity(0.4))

                            Text(tier.style.hint)
                                .font(.system(size: 11, weight: .regular, design: .default))
                                .foregroundColor(tier.style.accent.opacity(0.6))
                        }

                        FlowLayout(spacing: 6) {
                            ForEach(Array(tier.notes.enumerated()), id: \.offset) { noteIdx, note in
                                Text(note)
                                    .font(.system(size: 13, weight: .medium, design: .default))
                                    .foregroundColor(tier.style.pillText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .background(tier.style.pillBg)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(tier.style.pillBorder, lineWidth: 1.0)
                                    )
                                    .shadow(color: tier.style.accent.opacity(0.18), radius: 5, x: 0, y: 1)
                                    .opacity(appeared ? 1 : 0)
                                    .scaleEffect(appeared ? 1 : 0.70)
                                    .animation(
                                        .spring(response: 0.38, dampingFraction: 0.62)
                                            .delay(Double(tierIdx) * 0.16 + Double(noteIdx) * 0.055),
                                        value: appeared
                                    )
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .background(tier.style.bg)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(tier.style.pillBorder.opacity(0.8), lineWidth: 1.0)
                    )
                    .shadow(color: tier.style.accent.opacity(0.20), radius: 10, x: 0, y: 3)
                    .shadow(color: tier.style.accent.opacity(0.08), radius: 24, x: 0, y: 0)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 22)
                    .animation(
                        .spring(response: 0.52, dampingFraction: 0.74)
                            .delay(Double(tierIdx) * 0.14),
                        value: appeared
                    )
                }
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let result = layout(proposal: ProposedViewSize(bounds.size), subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: ProposedViewSize(frame.size))
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let containerWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > containerWidth && currentX > 0 {
                currentY += rowHeight + spacing
                currentX = 0
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalHeight = currentY + rowHeight
        }

        return (CGSize(width: containerWidth, height: totalHeight), frames)
    }
}
