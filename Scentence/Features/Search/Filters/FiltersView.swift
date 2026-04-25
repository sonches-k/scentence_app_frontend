import SwiftUI

struct FiltersView: View {
    @ObservedObject var viewModel: FiltersViewModel
    @Environment(\.dismiss) private var dismiss

    // familySearch — локальная, т.к. семейства — короткий статичный список
    @State private var familySearch = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 0) {
                        filterSection("Пол", options: viewModel.availableGenders, selected: $viewModel.selectedGenders)
                        AccentDivider().padding(.horizontal)

                        searchableFilterSection(
                            "Семейство",
                            info: "Широкая группа ароматов со схожим характером: Цветочные, Древесные, Восточные, Свежие.",
                            options: viewModel.availableFamilies,
                            selected: $viewModel.selectedFamilies,
                            searchText: $familySearch
                        )
                        AccentDivider().padding(.horizontal)

                        filterSection(
                            "Тип",
                            info: "Концентрация парфюма: Parfum — самая стойкая, EDP — насыщенная, EDT — лёгкая и свежая.",
                            options: viewModel.availableProductTypes,
                            selected: $viewModel.selectedProductTypes
                        )
                        AccentDivider().padding(.horizontal)

                        suggestFilterSection(
                            "Бренд",
                            suggestions: viewModel.brandSuggestions,
                            isLoading: viewModel.isBrandLoading,
                            selected: $viewModel.selectedBrands,
                            searchQuery: $viewModel.brandSearchQuery
                        )
                        AccentDivider().padding(.horizontal)

                        suggestFilterSection(
                            "Ноты",
                            info: "Ингредиенты аромата. Верхние — первое впечатление, сердечные — основа, базовые — шлейф.",
                            suggestions: viewModel.noteSuggestions,
                            isLoading: viewModel.isNoteLoading,
                            selected: $viewModel.selectedNotes,
                            searchQuery: $viewModel.noteSearchQuery
                        )
                        AccentDivider().padding(.horizontal)

                        yearSection
                    }
                    .padding(.bottom, 120)
                }

                VStack(spacing: 0) {
                    Spacer()

                    LinearGradient(
                        colors: [.clear, AppColor.background],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 56)
                    .allowsHitTesting(false)

                    HStack(spacing: 12) {
                        Button("Сбросить") { viewModel.reset() }
                            .buttonStyle(OutlineButtonStyle())

                        Button("Применить") { dismiss() }
                            .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                    .frame(maxWidth: .infinity)
                    .background(AppColor.background)
                }
            }
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") { dismiss() }
                        .foregroundColor(AppColor.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.activeCount > 0 {
                        Text("\(viewModel.activeCount)")
                            .font(AppFont.caption(12))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(AppColor.surface)
                            .clipShape(Circle())
                    }
                }
            }
            .glassNavBar()
            .tint(AppColor.accent)
        }
    }

    // MARK: - Simple filter section (short static lists)

    private func filterSection(
        _ title: String,
        info: String? = nil,
        options: [String],
        selected: Binding<Set<String>>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text(title)
                    .font(AppFont.caption(12))
                    .foregroundColor(AppColor.textSecondary)
                    .tracking(2)
                    .textCase(.uppercase)
                if let info {
                    InfoButton(text: info)
                }
            }
            .padding(.horizontal, 24)

            if options.isEmpty {
                Text("Загрузка...")
                    .font(AppFont.caption(13))
                    .foregroundColor(AppColor.textMuted)
                    .padding(.horizontal, 24)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(options, id: \.self) { option in
                            FilterChip(
                                title: option,
                                isSelected: selected.wrappedValue.contains(option)
                            ) {
                                if selected.wrappedValue.contains(option) {
                                    selected.wrappedValue.remove(option)
                                } else {
                                    selected.wrappedValue.insert(option)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Searchable filter section (local filtering for short static lists)

    private func searchableFilterSection(
        _ title: String,
        info: String? = nil,
        options: [String],
        selected: Binding<Set<String>>,
        searchText: Binding<String>
    ) -> some View {
        let filtered = searchText.wrappedValue.isEmpty
            ? options
            : options.filter { $0.localizedCaseInsensitiveContains(searchText.wrappedValue) }

        let selectedItems = options.filter { selected.wrappedValue.contains($0) }

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title, info: info, selectedCount: selected.wrappedValue.count)

            if options.isEmpty {
                Text("Загрузка...")
                    .font(AppFont.caption(13))
                    .foregroundColor(AppColor.textMuted)
                    .padding(.horizontal, 24)
            } else {
                searchField(text: searchText)

                if !selectedItems.isEmpty && !searchText.wrappedValue.isEmpty {
                    chipsRow(items: selectedItems, selected: selected)
                }

                chipsRow(items: filtered, selected: selected)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Suggest filter section (server-side, debounced)

    private func suggestFilterSection(
        _ title: String,
        info: String? = nil,
        suggestions: [String],
        isLoading: Bool,
        selected: Binding<Set<String>>,
        searchQuery: Binding<String>
    ) -> some View {
        // Выбранные элементы, которых нет в текущих подсказках (всегда видны)
        let orphanSelected = Array(selected.wrappedValue)
            .filter { !suggestions.contains($0) }
            .sorted()

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title, info: info, selectedCount: selected.wrappedValue.count)

            searchField(text: searchQuery)

            if !orphanSelected.isEmpty {
                chipsRow(items: orphanSelected, selected: selected)
            }

            if isLoading {
                HStack(spacing: 6) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.7)
                    Text("Поиск...")
                        .font(AppFont.caption(13))
                        .foregroundColor(AppColor.textMuted)
                }
                .padding(.horizontal, 24)
            } else if suggestions.isEmpty {
                Text(searchQuery.wrappedValue.isEmpty ? "Загрузка..." : "Ничего не найдено")
                    .font(AppFont.caption(13))
                    .foregroundColor(AppColor.textMuted)
                    .padding(.horizontal, 24)
            } else {
                chipsRow(items: suggestions, selected: selected)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Reusable sub-views

    private func sectionHeader(_ title: String, info: String?, selectedCount: Int) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(AppFont.caption(12))
                .foregroundColor(AppColor.textSecondary)
                .tracking(2)
                .textCase(.uppercase)
            if let info {
                InfoButton(text: info)
            }
            if selectedCount > 0 {
                Text("\(selectedCount)")
                    .font(AppFont.caption(10))
                    .foregroundColor(.white)
                    .frame(width: 16, height: 16)
                    .background(AppColor.accent)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
    }

    private func searchField(text: Binding<String>) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundColor(AppColor.textMuted)
            TextField("Поиск...", text: text)
                .font(AppFont.body(14))
                .foregroundColor(AppColor.textPrimary)
            if !text.wrappedValue.isEmpty {
                Button {
                    text.wrappedValue = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColor.textMuted)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassInputField(cornerRadius: 10)
        .padding(.horizontal, 24)
    }

    private func chipsRow(items: [String], selected: Binding<Set<String>>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { option in
                    FilterChip(
                        title: option,
                        isSelected: selected.wrappedValue.contains(option)
                    ) {
                        if selected.wrappedValue.contains(option) {
                            selected.wrappedValue.remove(option)
                        } else {
                            selected.wrappedValue.insert(option)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Year Section

    private var yearSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Год выпуска")
                .font(AppFont.caption(12))
                .foregroundColor(AppColor.textSecondary)
                .tracking(2)
                .textCase(.uppercase)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("от").font(AppFont.caption(12)).foregroundColor(AppColor.textMuted)
                    TextField("1990", text: $viewModel.yearFrom)
                        .font(AppFont.body(16))
                        .foregroundColor(AppColor.textPrimary)
                        .keyboardType(.numberPad)
                        .padding(12)
                        .glassInputField(cornerRadius: 10)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("до").font(AppFont.caption(12)).foregroundColor(AppColor.textMuted)
                    TextField("2024", text: $viewModel.yearTo)
                        .font(AppFont.body(16))
                        .foregroundColor(AppColor.textPrimary)
                        .keyboardType(.numberPad)
                        .padding(12)
                        .glassInputField(cornerRadius: 10)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

// MARK: - FilterChip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.caption(13))
                .foregroundColor(isSelected ? .white : AppColor.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Material.ultraThinMaterial)
                .background(isSelected ? AppColor.accent : Color.clear)
                .background(AppColor.accent.opacity(isSelected ? 0 : 0.05))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(AppColor.accent.opacity(isSelected ? 0 : 0.45), lineWidth: 1.0)
                )
                .shadow(color: AppColor.accent.opacity(isSelected ? 0.35 : 0.15), radius: 6, x: 0, y: 2)
        }
    }
}
