import SwiftUI

struct ScanResultsView: View {
    let items: [ScanItem]
    let selectedItems: Set<ScanItem>
    let onToggleSelection: (ScanItem) -> Void
    let onSelectAll: () -> Void
    let onDeselectAll: () -> Void
    
    @State private var searchText = ""
    @State private var selectedCategory: CacheCategory?
    
    private var filteredItems: [ScanItem] {
        items.filter { item in
            let matchesSearch = searchText.isEmpty || 
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.path.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == nil || item.category == selectedCategory
            
            return matchesSearch && matchesCategory
        }
    }
    
    private var groupedItems: [CacheCategory: [ScanItem]] {
        Dictionary(grouping: filteredItems, by: { $0.category })
    }
    
    private var categories: [CacheCategory] {
        Array(groupedItems.keys).sorted { 
            groupedItems[$0]?.reduce(0) { $0 + $1.size } ?? 0 >
            groupedItems[$1]?.reduce(0) { $0 + $1.size } ?? 0
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            resultsToolbar
            
            Divider()
            
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                scrollView
            }
        }
    }
    
    private var resultsToolbar: some View {
        HStack {
            TextField("Search...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
            
            Menu {
                Button("All Categories") { selectedCategory = nil }
                Divider()
                ForEach(CacheCategory.allCases) { category in
                    Button(category.rawValue) { selectedCategory = category }
                }
            } label: {
                Label(selectedCategory?.rawValue ?? "Category", systemImage: "line.3.horizontal.decrease.circle")
            }
            
            Spacer()
            
            Button("Select All") { onSelectAll() }
                .disabled(selectedCategory != nil)
            
            Button("Deselect All") { onDeselectAll() }
            
            Text("\(selectedItems.count) selected")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "Nothing found" : "No results")
                .font(.headline)
            
            Text("Try changing search parameters")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var scrollView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(categories, id: \.self) { category in
                    categorySection(category: category, items: groupedItems[category] ?? [])
                }
            }
            .padding()
        }
    }
    
    private func categorySection(category: CacheCategory, items: [ScanItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: category.systemImage)
                    .foregroundColor(Color(category.color))
                
                Text(category.rawValue)
                    .font(.headline)
                
                Spacer()
                
                Text(items.count.formatted())
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text(totalSizeForItems(items))
                    .foregroundColor(.secondary)
            }
            
            Text(category.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 0) {
                ForEach(items) { item in
                    itemRow(item: item)
                    
                    if item != items.last {
                        Divider()
                    }
                }
            }
            .background(Color.background.opacity(0.5))
            .cornerRadius(8)
        }
    }
    
    private func itemRow(item: ScanItem) -> some View {
        HStack {
            Button {
                onToggleSelection(item)
            } label: {
                Image(systemName: selectedItems.contains(item) ? "checkmark.square.fill" : "square")
                    .foregroundColor(selectedItems.contains(item) ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            
            Image(systemName: item.isDirectory ? "folder" : "doc")
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Text(item.path)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            Text(item.formattedSize)
                .monospacedDigit()
                .foregroundColor(.secondary)
            
            if !item.isSafeToDelete {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .help(SafetyCheck.shared.getBlockReason(path: item.path) ?? "Unsafe item")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(selectedItems.contains(item) ? Color.accentColor.opacity(0.1) : Color.clear)
    }
    
    private func totalSizeForItems(_ items: [ScanItem]) -> String {
        let total = items.reduce(0) { $0 + $1.size }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }
}

#Preview {
    ScanResultsView(
        items: PreviewData.sampleItems,
        selectedItems: [],
        onToggleSelection: { _ in },
        onSelectAll: {},
        onDeselectAll: {}
    )
    .frame(width: 800, height: 600)
}
