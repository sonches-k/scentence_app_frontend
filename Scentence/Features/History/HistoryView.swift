import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                if viewModel.isLoading {
                    LoadingView(message: "Загружаем историю...")
                } else if viewModel.history.isEmpty {
                    EmptyStateView(
                        icon: "clock",
                        title: "Нет истории",
                        subtitle: "Начните поиск, чтобы сохранить запросы"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.history) { entry in
                                Button {
                                    appState.repeatSearch(query: entry.query)
                                } label: {
                                    HistoryRow(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("История")
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

// MARK: - HistoryViewModel

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var history: [SearchHistoryEntry] = []
    @Published var isLoading = false

    private let api: APIServiceProtocol

    init(api: APIServiceProtocol = APIService.shared) {
        self.api = api
    }

    func load(token: String) async {
        isLoading = true
        defer { isLoading = false }
        history = (try? await api.getHistory(token: token)) ?? []
    }
}

// MARK: - HistoryRow

struct HistoryRow: View {
    let entry: SearchHistoryEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 13))
                .foregroundColor(AppColor.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.query)
                    .font(AppFont.body(14))
                    .foregroundColor(AppColor.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let date = entry.createdAt {
                    Text(date.prefix(10))
                        .font(AppFont.caption(11))
                        .foregroundColor(AppColor.textMuted)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .cardStyle()
    }
}
