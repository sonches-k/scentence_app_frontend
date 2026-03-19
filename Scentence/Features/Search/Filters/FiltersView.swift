import SwiftUI

struct FiltersView: View {
    @ObservedObject var viewModel: FiltersViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var familySearch = ""
    @State private var brandSearch = ""
    @State private var noteSearch = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 0) {
                        filterSection("Пол", options: viewModel.availableGenders, selected: $viewModel.selectedGenders)
                        GoldDivider().padding(.horizontal)

                        searchableFilterSection(
                            "Семейство",
                            info: "Широкая группа ароматов со схожим характером: Цветочные, Древесные, Восточные, Свежие.",
                            options: viewModel.availableFamilies,
                            selected: $viewModel.selectedFamilies,
                            searchText: $familySearch
                        )
                        GoldDivider().padding(.horizontal)

                        filterSection(
                            "Тип",
                            info: "Концентрация парфюма: Parfum — самая стойкая, EDP — насыщенная, EDT — лёгкая и свежая.",
                            options: viewModel.availableProductTypes,
                            selected: $viewModel.selectedProductTypes
                        )
                        GoldDivider().padding(.horizontal)

                        searchableFilterSection("Бренд", options: viewModel.availableBrands, selected: $viewModel.selectedBrands, searchText: $brandSearch)
                        GoldDivider().padding(.horizontal)

                        searchableFilterSection(
                            "Ноты",
                            info: "Ингредиенты аромата. Верхние — первое впечатление, сердечные — основа, базовые — шлейф.",
                            options: viewModel.availableNotes,
                            selected: $viewModel.selectedNotes,
                            searchText: $noteSearch
                        )
                        GoldDivider().padding(.horizontal)

                        yearSection
                    }
                    .padding(.bottom, 120)
                }

                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Button("Сбросить") { viewModel.reset() }
                            .buttonStyle(OutlineButtonStyle())

                        Button("Применить") { dismiss() }
                            .buttonStyle(GoldButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .background(
                        LinearGradient(
                            colors: [AppColor.background.opacity(0), AppColor.background],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: 100)
                        .offset(y: -8)
                    )
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
            .tint(AppColor.gold)
        }
    }

    // MARK: - Simple filter section (short lists)

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

    // MARK: - Searchable filter section (long lists)

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
            HStack(spacing: 6) {
                Text(title)
                    .font(AppFont.caption(12))
                    .foregroundColor(AppColor.textSecondary)
                    .tracking(2)
                    .textCase(.uppercase)

                if let info {
                    InfoButton(text: info)
                }

                if !selected.wrappedValue.isEmpty {
                    Text("\(selected.wrappedValue.count)")
                        .font(AppFont.caption(10))
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(AppColor.gold)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)

            if options.isEmpty {
                Text("Загрузка...")
                    .font(AppFont.caption(13))
                    .foregroundColor(AppColor.textMuted)
                    .padding(.horizontal, 24)
            } else {
                // Search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundColor(AppColor.textMuted)
                    TextField("Поиск...", text: searchText)
                        .font(AppFont.body(14))
                        .foregroundColor(AppColor.textPrimary)
                    if !searchText.wrappedValue.isEmpty {
                        Button {
                            searchText.wrappedValue = ""
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

                // Selected items (always visible)
                if !selectedItems.isEmpty && !searchText.wrappedValue.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedItems, id: \.self) { option in
                                FilterChip(title: option, isSelected: true) {
                                    selected.wrappedValue.remove(option)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }

                // Filtered options
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filtered, id: \.self) { option in
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
                .background(isSelected ? AppColor.gold : Color.clear)
                .background(AppColor.gold.opacity(isSelected ? 0 : 0.05))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(AppColor.gold.opacity(isSelected ? 0 : 0.45), lineWidth: 1.0)
                )
                .shadow(color: AppColor.gold.opacity(isSelected ? 0.35 : 0.15), radius: 6, x: 0, y: 2)
        }
    }
}
