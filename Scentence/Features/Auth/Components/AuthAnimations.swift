import SwiftUI

// MARK: - BloomPetal

struct BloomPetal: View {
    let index: Int

    private static let xPositions: [CGFloat] = [-90, -65, -40, -15, 10, 35, 60, 85, -52, 22]
    private var xStart: CGFloat { Self.xPositions[index % Self.xPositions.count] }
    private var xDrift: CGFloat { xStart / 90 * 38 }
    private var delay: Double { 0.65 + Double(index) * 0.09 }
    private var rotation: Double { Double(index) * 36 }

    @State private var opacity: Double = 0
    @State private var risen = false

    var body: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [AppColor.accent.opacity(0.95), AppColor.accentLight.opacity(0.60)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: 12, height: 20)
            .rotationEffect(.degrees(rotation))
            .offset(
                x: xStart + (risen ? xDrift : 0),
                y: risen ? -75 : 0
            )
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.25).delay(delay)) { opacity = 1.0 }
                withAnimation(.easeOut(duration: 1.4).delay(delay + 0.15)) { risen = true }
                withAnimation(.easeIn(duration: 0.7).delay(delay + 0.8)) { opacity = 0 }
            }
    }
}

// MARK: - SparkleOverlay

struct SparkleOverlay: View {
    private let count = 16
    @State private var expanded = false

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = Double(i) / Double(count) * 2 * .pi
                let distance: CGFloat = expanded ? 72 : 0
                Circle()
                    .fill(i % 2 == 0 ? AppColor.accent : AppColor.accentLight)
                    .frame(width: expanded ? 4 : 7, height: expanded ? 4 : 7)
                    .offset(x: cos(angle) * distance, y: sin(angle) * distance)
                    .opacity(expanded ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) { expanded = true }
        }
    }
}
