import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ScannerViewModel
    @State private var showingCleanupAlert = false
    @State private var showingFullDiskAccessAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Divider()
            
            mainContent
            
            Divider()
            
            footerView
        }
        .frame(minWidth: 900, minHeight: 650)
        .alert("Confirm Cleanup", isPresented: $showingCleanupAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Move to Trash", role: .destructive) {
                Task {
                    await viewModel.cleanSelected()
                }
            }
        } message: {
            Text("Selected files will be moved to Trash. You can restore them if needed.")
        }
        .alert("Full Disk Access Required", isPresented: $showingFullDiskAccessAlert) {
            Button("Open Settings", action: {
                viewModel.requestFullDiskAccess()
            })
            Button("Later", role: .cancel) { }
        } message: {
            Text("Full Disk Access is required to scan system caches. Please grant permission in System Preferences.")
        }
        .onAppear {
            checkPermissions()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("MacCleaner Pro")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Safe macOS cache cleaner")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private var statusColor: Color {
        if viewModel.isScanning { return .blue }
        if viewModel.requiresFullDiskAccess { return .orange }
        if viewModel.currentResult != nil { return .green }
        return .gray
    }
    
    private var statusText: String {
        if viewModel.isScanning { return "Scanning..." }
        if viewModel.requiresFullDiskAccess { return "Access Required" }
        if viewModel.currentResult != nil { return "Ready" }
        return "Idle"
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.scanStatus {
        case .idle:
            emptyStateView
            
        case .scanning(let progress, let currentPath):
            scanningView(progress: progress, currentPath: currentPath)
            
        case .completed(let result):
            resultsView(result: result)
            
        case .error(let message):
            errorView(message: message)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "externaldrive.connected.to.line.below")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 8) {
                Text("Ready to Scan")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Click Start Scan to analyze cache")
                    .foregroundColor(.secondary)
            }
            
            Button(action: { viewModel.startScan() }) {
                Label("Start Scan", systemImage: "play.fill")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            
            if viewModel.requiresFullDiskAccess {
                fullDiskAccessWarning
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var fullDiskAccessWarning: some View {
        HStack {
            Image(systemName: "lock.shield")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading) {
                Text("Full Disk Access Required")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("Grant permission in System Preferences to access system caches")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Open Settings") {
                showingFullDiskAccessAlert = true
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 450)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func scanningView(progress: Double, currentPath: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(width: 400)
            
            Text("\(Int(progress * 100))%")
                .font(.title2)
                .monospacedDigit()
            
            Text("Scanning: \(currentPath)")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 400)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func resultsView(result: ScanResult) -> some View {
        HSplitView {
            VStack(spacing: 16) {
                summaryCard(result: result)
                
                ChartView(chartData: result.chartData.map { item in
                    CategoryChartData(
                        category: item.category,
                        size: item.size,
                        percentage: Double(item.size) / Double(result.totalSize)
                    )
                })
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                SafetyWarningView(
                    itemCount: viewModel.selectedItems.count,
                    totalSize: viewModel.totalSelectedSize,
                    hasUnsafeItems: false
                )
            }
            .padding()
            .frame(minWidth: 350)
            
            ScanResultsView(
                items: result.items,
                selectedItems: viewModel.selectedItems,
                onToggleSelection: viewModel.toggleSelection,
                onSelectAll: viewModel.selectAllSafe,
                onDeselectAll: viewModel.deselectAll
            )
        }
    }
    
    private func summaryCard(result: ScanResult) -> some View {
        HStack(spacing: 24) {
            StatCard(
                title: "Files Found",
                value: result.totalFiles.formatted(),
                icon: "doc.fill",
                color: .blue
            )
            
            StatCard(
                title: "Total Size",
                value: result.formattedTotalSize,
                icon: "externaldrive.fill",
                color: .green
            )
            
            StatCard(
                title: "Scan Time",
                value: String(format: "%.1f s", result.duration),
                icon: "clock.fill",
                color: .orange
            )
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Scan Error")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { viewModel.startScan() }) {
                Text("Retry")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var footerView: some View {
        HStack {
            if let result = viewModel.currentResult {
                Text("Total: \(result.formattedTotalSize)")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            
            Spacer()
            
            if !viewModel.selectedItems.isEmpty {
                Text("Selected: \(viewModel.formattedSelectedSize)")
                    .foregroundColor(.accentColor)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(6)
            }
            
            if viewModel.currentResult == nil {
                Button(action: { viewModel.startScan() }) {
                    Label("Scan", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isScanning)
            }
            
            Button(action: { showingCleanupAlert = true }) {
                Label("Clean Selected", systemImage: "trash.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(!viewModel.canClean)
        }
        .padding()
    }
    
    private func checkPermissions() {
        if viewModel.requiresFullDiskAccess {
            showingFullDiskAccessAlert = true
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct HSplitView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 1) {
            content
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ScannerViewModel())
}
