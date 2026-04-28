import SwiftUI
import Translation

struct SearchView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = SearchViewModel()
    @State private var showResults = false
    @State private var searchTask: Task<Void, Never>?
    @State private var showQueryTranslation = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 28) {
                        Text("Scentence")
                            .font(AppFont.display(32))
                            .foregroundColor(AppColor.textPrimary)
                            .tracking(5)
                            .padding(.top, 24)

                        searchInputSection

                        controlsRow

                        if let error = viewModel.errorMessage {
                            ErrorLabel(text: error)
                                .padding(.horizontal, 24)
                        }

                        if let aiError = viewModel.aiError {
                            ErrorLabel(text: aiError)
                                .padding(.horizontal, 24)
                        }

                        if viewModel.isLoading {
                            BreathingSearchLoader()
                                .padding(.top, 16)
                        } else if let response = viewModel.searchResponse {
                            resultsPreview(response)
                        } else {
                            suggestionChips
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showFilters) {
                FiltersView(viewModel: viewModel.filtersVM)
            }
            .navigationDestination(isPresented: $showResults) {
                if let response = viewModel.searchResponse {
                    ResultsView(
                        response: response,
                        query: viewModel.queryText,
                        activeProvider: viewModel.activeProvider,
                        filterChips: viewModel.filtersVM.activeFilterChips
                    )
                }
            }
            .onChange(of: appState.selectedTab) { _, tab in
                // Возврат на вкладку Поиск всегда открывает главный экран, а не результаты.
                if tab == .search { showResults = false }
            }
            .onChange(of: appState.pendingSearchQuery) { _, query in
                guard let query, !query.isEmpty else { return }
                showResults = false

                // Применяем фильтры ДО запуска поиска — pendingFilters и pendingSearchQuery
                // всегда устанавливаются вместе в repeatSearch(), поэтому читаем здесь.
                viewModel.filtersVM.apply(from: appState.pendingFilters)
                appState.pendingFilters = nil

                viewModel.queryText = query
                appState.pendingSearchQuery = nil

                // Автоматически запускаем поиск — результат придёт из URLCache мгновенно.
                searchTask?.cancel()
                searchTask = Task {
                    await viewModel.search(token: authState.token, llmProvider: appState.llmProvider)
                    if viewModel.searchResponse != nil {
                        showResults = true
                    }
                }
            }
        }
    }

    // MARK: - Search Input

    private var queryPlaceholder: String {
        appState.llmProvider == .appleIntelligence
            ? "Describe the desired fragrance in English..."
            : "Опишите желаемый аромат..."
    }

    private var searchInputSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .trailing) {
                TextEditor(text: $viewModel.queryText)
                    .font(AppFont.body(16))
                    .foregroundColor(AppColor.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 56, maxHeight: 120)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .padding(.trailing, 44)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Готово") { hideKeyboard() }
                                .font(AppFont.body(16))
                                .foregroundColor(AppColor.accent)
                        }
                    }
                    .overlay(
                        Group {
                            if viewModel.queryText.isEmpty {
                                Text(queryPlaceholder)
                                    .font(AppFont.body(16))
                                    .foregroundColor(AppColor.textMuted)
                                    // Компенсируем внутренний отступ UITextView (~5pt гориз, ~8pt верт)
                                    .padding(.horizontal, 21)
                                    .padding(.top, 20)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    .allowsHitTesting(false)
                            }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [AppColor.accent.opacity(0.55), AppColor.accent.opacity(0.18)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    )
                    .shadow(color: AppColor.accent.opacity(0.18), radius: 10, x: 0, y: 3)

                if !viewModel.queryText.isEmpty {
                    Button { viewModel.clear() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColor.textMuted)
                            .font(.system(size: 18))
                    }
                    .padding(.trailing, 14)
                    .padding(.bottom, 2)
                }
            }

            if appState.llmProvider == .appleIntelligence {
                HStack(alignment: .top, spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text("Apple Intelligence лучше работает с запросами на английском.")
                            .font(AppFont.caption(12))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundColor(AppColor.textMuted)

                    Spacer(minLength: 0)

                    if #available(iOS 17.4, *) {
                        Button {
                            showQueryTranslation = true
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "translate")
                                    .font(.system(size: 11))
                                Text("Перевести")
                                    .font(AppFont.caption(12))
                            }
                            .foregroundColor(AppColor.accent)
                        }
                    }
                }
                .applyTranslationIfAvailable(
                    isPresented: $showQueryTranslation,
                    text: viewModel.queryText
                ) { translated in
                    viewModel.queryText = translated
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Button {
                hideKeyboard()
                searchTask = Task {
                    await viewModel.search(token: authState.token, llmProvider: appState.llmProvider)
                    if viewModel.searchResponse != nil {
                        showResults = true
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("Найти ароматы")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isLoading || viewModel.queryText.trimmingCharacters(in: .whitespaces).count < 3)
            .opacity(viewModel.isLoading ? 0.5 : 1.0)

            if viewModel.isLoading {
                Button {
                    searchTask?.cancel()
                    viewModel.cancelSearch()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 14))
                        Text("Отменить")
                            .font(AppFont.caption(14))
                    }
                    .foregroundColor(AppColor.textSecondary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: viewModel.isLoading)
        .animation(.easeInOut(duration: 0.2), value: appState.llmProvider)
        .padding(.horizontal, 24)
    }

    // MARK: - Controls row

    private var controlsRow: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.showFilters = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14))
                    Text("Фильтры")
                        .font(AppFont.caption(14))
                    if viewModel.filtersVM.activeCount > 0 {
                        Text("\(viewModel.filtersVM.activeCount)")
                            .font(AppFont.caption(11))
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(AppColor.surface)
                            .clipShape(Circle())
                    }
                }
                .foregroundColor(viewModel.filtersVM.activeCount > 0 ? AppColor.accent : AppColor.textSecondary)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .glassCapsule(active: viewModel.filtersVM.activeCount > 0)
            }

            Spacer()

            HStack(spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                        .foregroundColor(AppColor.textMuted)
                    TextField("5", text: $viewModel.limitText)
                        .keyboardType(.numberPad)
                        .font(AppFont.mono(14))
                        .fontWeight(.medium)
                        .foregroundColor(AppColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .frame(width: 28)
                        .onChange(of: viewModel.limitText) { _, val in
                            let filtered = val.filter { $0.isNumber }
                            if filtered != val { viewModel.limitText = filtered }
                            if let n = Int(filtered), n > 50 { viewModel.limitText = "50" }
                        }
                    Text("ароматов")
                        .font(AppFont.caption(13))
                        .foregroundColor(AppColor.textSecondary)
                }
                .padding(.horizontal, 12)
                .frame(height: 36)
                .glassCapsule()

                InfoButton(text: "Сколько ароматов показать в результатах. Больше — дольше ожидание.")
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Suggestion chips

    private var suggestionChips: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Попробуйте")
                .font(AppFont.caption(12))
                .foregroundColor(AppColor.textMuted)
                .tracking(2)
                .textCase(.uppercase)
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SearchSuggestion.examples, id: \.self) { suggestion in
                        Button {
                            viewModel.queryText = suggestion
                        } label: {
                            Text(suggestion)
                                .font(AppFont.caption(13))
                                .foregroundColor(AppColor.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .glassCapsule()
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Results preview

    @ViewBuilder
    private func resultsPreview(_ response: SearchResponse) -> some View {
        VStack(spacing: 16) {
            Button {
                showResults = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Найдено \(response.totalFound) аромат(ов)")
                            .font(AppFont.body(15))
                            .foregroundColor(AppColor.textPrimary)

                        let chips = viewModel.filtersVM.activeFilterChips
                        if !chips.isEmpty {
                            Text(chips.joined(separator: " · "))
                                .font(AppFont.caption(11))
                                .foregroundColor(AppColor.accent.opacity(0.8))
                                .lineLimit(1)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: viewModel.activeProvider == .appleIntelligence ? "apple.intelligence" : "sparkle")
                                .font(.system(size: 10))
                            Text(viewModel.activeProvider == .appleIntelligence ? "Apple Intelligence" : "DeepSeek")
                                .font(AppFont.caption(11))
                        }
                        .foregroundColor(AppColor.textMuted)
                        Text("Нажмите, чтобы открыть")
                            .font(AppFont.caption(12))
                            .foregroundColor(AppColor.textMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColor.accent)
                }
                .padding(16)
                .cardStyle()
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - SearchSuggestion

enum SearchSuggestion {
    static let examples = [
        "тёплый уютный аромат для зимних вечеров",
        "свежий и лёгкий на лето",
        "аромат для офиса, не навязчивый",
        "восточный с ванилью и мускусом",
        "цветочный весенний женский",
        "древесный мужской вечерний",
    ]
}
