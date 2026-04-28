import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var viewModel = FavoritesViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                if viewModel.isLoading {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(0..<4, id: \.self) { _ in SkeletonFavoriteRow() }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                } else if viewModel.favorites.isEmpty {
                    EmptyStateView(
                        icon: "heart",
                        title: "Нет избранных",
                        subtitle: "Добавляйте ароматы из поиска"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.favorites) { perfume in
                                NavigationLink {
                                    PerfumeDetailView(perfumeId: perfume.id)
                                } label: {
                                    FavoritePerfumeRow(perfume: perfume) {
                                        guard let token = authState.token else { return }
                                        Task { await viewModel.removeFavorite(perfumeId: perfume.id, token: token) }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Избранное")
            .navigationBarTitleDisplayMode(.inline)
            .glassNavBar()
            .tint(AppColor.accent)
            .task {
                guard let token = authState.token else { return }
                await viewModel.load(token: token)
            }
            .refreshable {
                guard let token = authState.token else { return }
                await viewModel.load(token: token)
            }
        }
    }
}

// MARK: - FavoritePerfumeRow

struct FavoritePerfumeRow: View {
    let perfume: FavoritePerfume
    let onRemove: () -> Void
    @State private var summaryExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                if let urlStr = perfume.imageUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        default:
                            RoundedRectangle(cornerRadius: 8).fill(AppColor.cardBorder.opacity(0.4))
                        }
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(perfume.brand.uppercased())
                        .font(AppFont.caption(9))
                        .foregroundColor(AppColor.accent)
                        .tracking(2)
                    Text(perfume.name)
                        .font(AppFont.body(16))
                        .foregroundColor(AppColor.textPrimary)
                        .lineLimit(1)

                    if let family = perfume.family {
                        Text(family)
                            .font(AppFont.caption(12))
                            .foregroundColor(AppColor.textMuted)
                    }
                }
                Spacer()
                Button { onRemove() } label: {
                    Image(systemName: "heart.slash")
                        .foregroundColor(AppColor.textMuted)
                        .font(.system(size: 16))
                }
            }

            if let summary = perfume.reviewSummary, !summary.isEmpty {
                Divider()
                    .overlay(AppColor.cardBorder.opacity(0.4))
                    .padding(.top, 10)

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
                .padding(.top, 2)

                if summaryExpanded {
                    Text(summary)
                        .font(AppFont.caption(12))
                        .foregroundColor(AppColor.textSecondary)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(14)
        .cardStyle()
        .animation(.easeInOut(duration: 0.22), value: summaryExpanded)
    }
}
