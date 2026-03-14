import SwiftUI

struct SafetyWarningView: View {
    let itemCount: Int
    let totalSize: Int64
    let hasUnsafeItems: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: hasUnsafeItems ? "exclamationmark.triangle.fill" : "shield.check")
                    .font(.title2)
                    .foregroundColor(hasUnsafeItems ? .orange : .green)
                
                Text(hasUnsafeItems ? "Attention Required" : "All Items Safe")
                    .font(.headline)
            }
            
            Text(descriptionText)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                StatBadge(
                    title: "Items",
                    value: itemCount.formatted(),
                    icon: "list.bullet"
                )
                
                StatBadge(
                    title: "Total Size",
                    value: formattedSize,
                    icon: "externaldrive"
                )
                
                if hasUnsafeItems {
                    StatBadge(
                        title: "Unsafe",
                        value: "\u{26A0}\u{FE0F}",
                        icon: "exclamationmark.triangle"
                    )
                    .badgeColor(.orange)
                }
            }
        }
        .padding()
        .background(Color.background.opacity(0.5))
        .cornerRadius(10)
    }
    
    private var descriptionText: String {
        if hasUnsafeItems {
            return "Some items cannot be removed automatically. These are system files or files with critical extensions."
        } else {
            return "All selected items are in safe cache directories and can be removed without harming the system."
        }
    }
    
    private var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

struct StatBadge: View {
    let title: String
    let value: String
    let icon: String
    @State var badgeColor: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(badgeColor)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.headline)
        }
        .padding(8)
        .background(badgeColor.opacity(0.1))
        .cornerRadius(6)
    }
    
    func badgeColor(_ color: Color) -> StatBadge {
        var copy = self
        copy.badgeColor = color
        return copy
    }
}

#Preview {
    VStack(spacing: 20) {
        SafetyWarningView(itemCount: 150, totalSize: 2_500_000_000, hasUnsafeItems: false)
        SafetyWarningView(itemCount: 150, totalSize: 2_500_000_000, hasUnsafeItems: true)
    }
    .padding()
    .frame(width: 500)
}
