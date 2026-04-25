import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HistoryViewModel()

    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                if viewModel.isLoading {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(0..<5, id: \.self) { _ in SkeletonHistoryRow() }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
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
                                HistoryRow(entry: entry) {
                                    appState.repeatSearch(query: entry.query)
                                } onDelete: {
                                    guard let token = authState.token else { return }
                                    Task { await viewModel.deleteEntry(id: entry.id, token: token) }
                                }
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.history.isEmpty {
                        Button("Очистить всё") {
                            showClearConfirmation = true
                        }
                        .font(AppFont.caption(14))
                        .foregroundColor(AppColor.textSecondary)
                    }
                }
            }
            .alert("Очистить историю?", isPresented: $showClearConfirmation) {
                Button("Очистить", role: .destructive) {
                    guard let token = authState.token else { return }
                    Task { await viewModel.clearAll(token: token) }
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Все записи будут удалены без возможности восстановления.")
            }
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

    func deleteEntry(id: Int, token: String) async {
        _ = try? await api.deleteHistoryEntry(entryId: id, token: token)
        history.removeAll { $0.id == id }
    }

    func clearAll(token: String) async {
        _ = try? await api.clearHistory(token: token)
        history = []
    }
}

// MARK: - HistoryRow

struct HistoryRow: View {
    let entry: SearchHistoryEntry
    let onRepeat: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onRepeat) {
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
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(AppColor.textMuted)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .cardStyle()
    }
}
