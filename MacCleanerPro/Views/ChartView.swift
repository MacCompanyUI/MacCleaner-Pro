import SwiftUI
import Charts

struct CategoryChartData: Identifiable {
    let id = UUID()
    let category: CacheCategory
    let size: Int64
    let percentage: Double
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var color: Color {
        Color(category.color)
    }
}

struct ChartView: View {
    let chartData: [CategoryChartData]
    
    var body: some View {
        Group {
            if #available(macOS 13.0, *) {
                modernChart
            } else {
                legacyChart
            }
        }
        .frame(height: 250)
        .padding()
    }
    
    @available(macOS 13.0, *)
    private var modernChart: some View {
        Chart(chartData) { item in
            SectorMark(
                angle: .value("Size", item.size),
                innerRadius: .ratio(0.5),
                angularInset: 3
            )
            .cornerRadius(3)
            .annotation(position: .overlay) {
                if item.percentage > 0.05 {
                    Text(item.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .foregroundStyle(by: .value("Category", item.category.rawValue))
        }
        .chartLegend(position: .bottom)
        .chartForegroundStyleScale([
            "Application Cache": .blue,
            "System Logs": .orange,
            "User Logs": .yellow,
            "Browser Cache": .green,
            "Developer Cache": .purple,
            "Font Cache": .pink,
            "Other": .gray
        ])
    }
    
    private var legacyChart: some View {
        GeometryReader { geometry in
            let totalAngle = Angle.degrees(360)
            var startAngle = Angle.degrees(0)
            
            ForEach(chartData) { item in
                let percentage = Double(item.size) / Double(chartData.reduce(0) { $0 + $1.size })
                let angle = Angle(degrees: 360 * percentage)
                
                WedgeShape(
                    startAngle: startAngle,
                    endAngle: startAngle + angle,
                    innerRadius: 0.5
                )
                .fill(item.color)
                .frame(width: geometry.size.width, height: geometry.size.height)
                
                startAngle = startAngle + angle
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(
            VStack {
                Text("By Category")
                    .font(.headline)
                Text(totalFormattedSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        )
        .overlay(
            VStack {
                Spacer()
                legendView
                Spacer()
            },
            alignment: .trailing
        )
    }
    
    private var totalFormattedSize: String {
        let total = chartData.reduce(0) { $0 + $1.size }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }
    
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(chartData) { item in
                HStack {
                    Circle()
                        .fill(item.color)
                        .frame(width: 10, height: 10)
                    Text(item.category.rawValue)
                        .font(.caption)
                    Text("(\(item.formattedSize))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color.background.opacity(0.8))
        .cornerRadius(8)
    }
}

struct WedgeShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var innerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle - .degrees(90),
            endAngle: endAngle - .degrees(90),
            clockwise: false
        )
        path.closeSubpath()
        
        if innerRadius > 0 {
            let innerPath = Path()
            innerPath.addArc(
                center: center,
                radius: radius * innerRadius,
                startAngle: endAngle - .degrees(90),
                endAngle: startAngle - .degrees(90),
                clockwise: true
            )
            path.addPath(innerPath)
        }
        
        return path
    }
}

#Preview {
    ChartView(chartData: [
        CategoryChartData(category: .applicationCache, size: 1_500_000_000, percentage: 0.45),
        CategoryChartData(category: .developerCache, size: 800_000_000, percentage: 0.24),
        CategoryChartData(category: .browserCache, size: 500_000_000, percentage: 0.15),
        CategoryChartData(category: .systemLogs, size: 300_000_000, percentage: 0.09),
        CategoryChartData(category: .other, size: 233_000_000, percentage: 0.07)
    ])
    .frame(width: 600, height: 400)
}
