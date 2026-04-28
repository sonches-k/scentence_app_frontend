import SwiftUI
import Translation

struct ResultsView: View {
    let response: SearchResponse
    let query: String
    let activeProvider: LLMProvider
    var filterChips: [String] = []

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showTranslation = false
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var isRendering = false

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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await renderShareCard() }
                } label: {
                    if isRendering {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                            .tint(AppColor.accent)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .tint(AppColor.accent)
                .disabled(isRendering)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage {
                ActivitySheet(image: img).ignoresSafeArea()
            }
        }
    }

    // MARK: - Share

    @MainActor
    private func renderShareCard() async {
        guard !isRendering else { return }
        isRendering = true
        defer { isRendering = false }

        // Даём UI обновиться (показать ProgressView) перед тяжёлым рендером
        await Task.yield()

        let card = ShareCardView(
            query: query,
            filterChips: filterChips,
            pyramid: response.notePyramid,
            perfumes: response.perfumes,
            totalFound: response.totalFound
        )
        .environment(\.colorScheme, colorScheme)

        let renderer = ImageRenderer(content: card)
        renderer.scale = 2.5
        if let img = renderer.uiImage {
            shareImage = img
            showShareSheet = true
        }
    }

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
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

                if !filterChips.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(filterChips, id: \.self) { chip in
                                Text(chip)
                                    .font(AppFont.caption(11))
                                    .foregroundColor(AppColor.accent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AppColor.accent.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            ExpandableMarkdownText(text: response.explanation)

            HStack(alignment: .center) {
                Text("Найдено \(response.totalFound) ароматов")
                    .font(AppFont.caption(12))
                    .foregroundColor(AppColor.textMuted)

                if activeProvider == .appleIntelligence {
                    Spacer()
                    if #available(iOS 17.4, *) {
                        Button {
                            showTranslation = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "translate")
                                    .font(.system(size: 11))
                                Text("Перевести")
                                    .font(AppFont.caption(12))
                            }
                            .foregroundColor(AppColor.accent)
                        }
                        .translationPresentation(isPresented: $showTranslation, text: response.explanation)
                    }
                }
            }
        }
    }
}

// MARK: - ActivitySheet

private struct ActivitySheet: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

