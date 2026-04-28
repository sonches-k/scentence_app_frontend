import SwiftUI

// MARK: - NotePyramidSection

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
            label: "Верхние", hint: "Старт композиции",
            bg: AppColor.accent.opacity(0.12),
            pillBg: AppColor.accent.opacity(0.08),
            pillBorder: AppColor.accent.opacity(0.55),
            pillText: AppColor.accent,
            accent: AppColor.accent
        ),
        TierStyle(
            label: "Средние", hint: "Ядро аромата",
            bg: AppColor.textSecondary.opacity(0.10),
            pillBg: AppColor.textSecondary.opacity(0.08),
            pillBorder: AppColor.textSecondary.opacity(0.50),
            pillText: AppColor.textPrimary,
            accent: AppColor.textSecondary
        ),
        TierStyle(
            label: "Базовые", hint: "Шлейфовое звучание",
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
                    tierCard(tier: tier, tierIdx: tierIdx)
                }
            }
        }
        .onAppear { appeared = true }
    }

    @ViewBuilder
    private func tierCard(tier: (notes: [String], style: TierStyle), tierIdx: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            tierHeader(style: tier.style)

            FlowLayout(spacing: 6) {
                ForEach(Array(tier.notes.enumerated()), id: \.offset) { noteIdx, note in
                    notePill(note: note, style: tier.style, tierIdx: tierIdx, noteIdx: noteIdx)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .background(tier.style.bg)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(tier.style.pillBorder.opacity(0.8), lineWidth: 1.0))
        .shadow(color: tier.style.accent.opacity(0.20), radius: 10, x: 0, y: 3)
        .shadow(color: tier.style.accent.opacity(0.08), radius: 24, x: 0, y: 0)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 22)
        .animation(.spring(response: 0.52, dampingFraction: 0.74).delay(Double(tierIdx) * 0.14), value: appeared)
    }

    @ViewBuilder
    private func tierHeader(style: TierStyle) -> some View {
        HStack(spacing: 6) {
            Text(style.label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(style.accent)
            Text("·")
                .foregroundColor(style.accent.opacity(0.4))
            Text(style.hint)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(style.accent.opacity(0.6))
        }
    }

    @ViewBuilder
    private func notePill(note: String, style: TierStyle, tierIdx: Int, noteIdx: Int) -> some View {
        Text(note)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(style.pillText)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .background(style.pillBg)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(style.pillBorder, lineWidth: 1.0))
            .shadow(color: style.accent.opacity(0.18), radius: 5, x: 0, y: 1)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.70)
            .animation(
                .spring(response: 0.38, dampingFraction: 0.62)
                    .delay(Double(tierIdx) * 0.16 + Double(noteIdx) * 0.055),
                value: appeared
            )
    }
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let frames = layout(proposal: ProposedViewSize(bounds.size), subviews: subviews).frames
        for (index, frame) in frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let containerWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > containerWidth && x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalHeight = y + rowHeight
        }

        return (CGSize(width: containerWidth, height: totalHeight), frames)
    }
}
