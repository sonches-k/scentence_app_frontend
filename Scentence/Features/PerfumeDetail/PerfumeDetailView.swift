import SwiftUI

struct PerfumeDetailView: View {
    let perfumeId: Int
    @EnvironmentObject var authState: AuthState
    @StateObject private var viewModel = PerfumeDetailViewModel()

    var body: some View {
        ZStack {
            AppBackground()

            if viewModel.isLoading {
                LoadingView(message: "Загружаем аромат...")
            } else if let perfume = viewModel.perfume {
                content(perfume)
            } else if let error = viewModel.errorMessage {
                EmptyStateView(icon: "exclamationmark.triangle", title: "Ошибка", subtitle: error)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .glassNavBar()
        .tint(AppColor.gold)
        .toolbar {
            if let perfume = viewModel.perfume, authState.isAuthenticated {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        guard let token = authState.token else { return }
                        Task { await viewModel.toggleFavorite(perfumeId: perfume.id, token: token) }
                    } label: {
                        Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(viewModel.isFavorite ? AppColor.gold : AppColor.textSecondary)
                    }
                    .disabled(viewModel.isFavoriteLoading)
                }
            }
        }
        .task {
            await viewModel.load(perfumeId: perfumeId, token: authState.token)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ perfume: Perfume) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                if let urlStr = perfume.imageUrl, let url = URL.robust(urlStr) {
                    RemoteImage(url: url)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                }

                heroSection(perfume)
                    .padding(.horizontal, 24)
                    .padding(.top, perfume.imageUrl == nil ? 16 : 0)
                    .padding(.bottom, 24)

                GoldDivider().padding(.horizontal, 24)

                let pyramid = perfume.notePyramid
                if !pyramid.isEmpty {
                    NotePyramidSection(pyramid: pyramid)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)

                    GoldDivider().padding(.horizontal, 24)
                }

                if let desc = perfume.description, !desc.isEmpty {
                    descriptionSection(desc)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)

                    GoldDivider().padding(.horizontal, 24)
                }

                if !perfume.allTagNames.isEmpty {
                    tagsSection(perfume.allTagNames)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)

                    GoldDivider().padding(.horizontal, 24)
                }

                if let urlStr = perfume.sourceUrl, let url = URL.robust(urlStr) {
                    sourceLinkSection(url: url)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)

                    GoldDivider().padding(.horizontal, 24)
                }

                if !viewModel.similarPerfumes.isEmpty {
                    similarSection
                        .padding(.top, 20)
                }

                Spacer().frame(height: 40)
            }
        }
    }

    // MARK: - Hero

    private func heroSection(_ perfume: Perfume) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(perfume.brand.uppercased())
                .font(AppFont.caption(11))
                .foregroundColor(AppColor.gold)
                .tracking(3)

            Text(perfume.name)
                .font(AppFont.display(30))
                .foregroundColor(AppColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                if let family = perfume.family  { MetaTag(text: family) }
                if let pt = perfume.productType { MetaTag(text: pt) }
                if let gender = perfume.gender  { MetaTag(text: gender) }
                if let year = perfume.year      { MetaTag(text: String(year)) }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Description

    private func descriptionSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Описание")
                .font(AppFont.caption(11))
                .foregroundColor(AppColor.textSecondary)
                .tracking(2)
                .textCase(.uppercase)

            ExpandableMarkdownText(text: text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Tags

    private func tagsSection(_ tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Теги")
                .font(AppFont.caption(11))
                .foregroundColor(AppColor.textSecondary)
                .tracking(2)
                .textCase(.uppercase)

            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(AppFont.caption(12))
                        .foregroundColor(AppColor.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColor.card)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppColor.cardBorder, lineWidth: 0.5))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Source Link

    private func sourceLinkSection(url: URL) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Хотите купить?")
                .font(AppFont.caption(11))
                .foregroundColor(AppColor.textSecondary)
                .tracking(2)
                .textCase(.uppercase)

            Button {
                UIApplication.shared.open(url)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "bag")
                        .font(.system(size: 16))
                        .foregroundColor(AppColor.gold)

                    Text("Перейти на сайт")
                        .font(AppFont.body(15))
                        .foregroundColor(AppColor.textPrimary)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.textMuted)
                }
                .padding(14)
                .background(AppColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColor.cardBorder, lineWidth: 0.5)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Similar

    private var similarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Похожие ароматы")
                .font(AppFont.caption(11))
                .foregroundColor(AppColor.textSecondary)
                .tracking(2)
                .textCase(.uppercase)
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.similarPerfumes) { similar in
                        NavigationLink {
                            PerfumeDetailView(perfumeId: similar.id)
                        } label: {
                            SimilarCard(perfume: similar)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - SimilarCard

struct SimilarCard: View {
    let perfume: PerfumeWithRelevance

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(perfume.brand.uppercased())
                .font(AppFont.caption(9))
                .foregroundColor(AppColor.gold)
                .tracking(1.5)
                .lineLimit(1)

            Text(perfume.name)
                .font(AppFont.body(14))
                .foregroundColor(AppColor.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if let family = perfume.family {
                Text(family)
                    .font(AppFont.caption(11))
                    .foregroundColor(AppColor.textMuted)
            }

            Spacer()

            RelevanceBadge(score: perfume.relevanceScore)
        }
        .padding(14)
        .frame(width: 140, height: 130)
        .cardStyle()
    }
}
