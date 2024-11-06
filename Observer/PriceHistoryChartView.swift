import SwiftUI

struct PriceHistoryChartView: View {
    var priceHistory: [PriceHistory]
    var favoriteDate: Date?
    var maxPrice: Int
    var minPrice: Int
    var currentPrice: Int
    
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        let adjustedPriceHistory = addFavoriteDateIfNeeded(priceHistory: priceHistory, favoriteDate: favoriteDate)
        
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            let priceRange = maxPrice - minPrice
            let yScale = (height - 60) / CGFloat(priceRange)
            let leftPadding: CGFloat = 70
            let rightPadding: CGFloat = 30
            let graphWidth = width - leftPadding - rightPadding
            
            // 날짜 간격을 계산 (3개의 간격을 만들기 위해 3으로 나눔)
            let dateSpacing = graphWidth / 3
            
            ZStack {
                Rectangle()
                    .fill(Color.black)
                    .cornerRadius(8)
                    .padding(.horizontal, -10)
                
                Path { path in
                    path.move(to: CGPoint(x: leftPadding, y: 10))
                    path.addLine(to: CGPoint(x: leftPadding, y: height - 50))
                }
                .stroke(Color.white, lineWidth: 2)
                
                Path { path in
                    path.move(to: CGPoint(x: leftPadding, y: height - 50))
                    path.addLine(to: CGPoint(x: width - rightPadding, y: height - 50))
                }
                .stroke(Color.white, lineWidth: 2)
                
                // 가격 변동 그래프
                Path { path in
                    for (index, history) in adjustedPriceHistory.enumerated() {
                        if let parsedDate = history.parsedDate {
                            // 날짜에 따른 x 위치 계산
                            let position = getPositionForDate(date: parsedDate,
                                                            width: graphWidth,
                                                            leftPadding: leftPadding)
                            let yPosition = height - 50 - CGFloat(history.price - minPrice) * yScale
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: position, y: yPosition))
                            } else {
                                path.addLine(to: CGPoint(x: position, y: yPosition))
                            }
                        }
                    }
                }
                .stroke(Color.red, lineWidth: 2)
                
                // 데이터 포인트
                ForEach(adjustedPriceHistory.indices, id: \.self) { index in
                    if let currentParsedDate = adjustedPriceHistory[index].parsedDate {
                        let xPosition = getPositionForDate(date: currentParsedDate,
                                                         width: graphWidth,
                                                         leftPadding: leftPadding)
                        let yPosition = height - 50 - CGFloat(adjustedPriceHistory[index].price - minPrice) * yScale
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 4, height: 4)
                            .position(x: xPosition, y: yPosition)
                        
                        if let favoriteDate = favoriteDate,
                           Calendar.current.isDate(currentParsedDate, inSameDayAs: favoriteDate) {
                            VStack(spacing: 2) {
                                Text("찜시기")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                                Triangle()
                                    .fill(Color.yellow)
                                    .frame(width: 8, height: 8)
                            }
                            .position(x: xPosition, y: height - 70)
                        }
                    }
                }
                
                // 현재 가격 점선
                Path { path in
                    let yPosition = height - 50 - CGFloat(currentPrice - minPrice) * yScale
                    path.move(to: CGPoint(x: leftPadding, y: yPosition))
                    path.addLine(to: CGPoint(x: width - rightPadding, y: yPosition))
                }
                .stroke(Color.red, style: StrokeStyle(lineWidth: 1, dash: [5]))
                
                // X축 날짜 레이블
                ForEach(0..<4) { i in
                    let xPosition = leftPadding + dateSpacing * CGFloat(i)
                    let date = Calendar.current.date(byAdding: .month,
                                                   value: i - 3,
                                                   to: Date()) ?? Date()
                    let dateText = DateFormatter.shortDateFormatter.string(from: date)
                    
                    Text(dateText)
                        .foregroundColor(.white)
                        .font(.caption2)
                        .position(x: xPosition, y: height - 40)
                }
                
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(Int(maxPrice))원")
                    Spacer()
                    Text("\(Int(minPrice))원")
                }
                .font(.caption)
                .foregroundColor(.white)
                .frame(width: 60, height: height - 60, alignment: .trailing)
                .offset(x: -width/2 + 35, y: -15)

                Text("\(Int(currentPrice))원")
                    .foregroundColor(.red)
                    .font(.caption)
                    .position(x: 40, y: height - 50 - CGFloat(currentPrice - minPrice) * yScale)
            }
            .scaleEffect(scale)
            .gesture(MagnificationGesture()
                        .onChanged { value in
                            self.scale = value.magnitude
                        }
            )
        }
        .frame(height: 250)
        .padding(.horizontal, 16)
    }
    
    // 날짜에 따른 x축 위치 계산 함수
    private func getPositionForDate(date: Date, width: CGFloat, leftPadding: CGFloat) -> CGFloat {
        let calendar = Calendar.current
        let now = Date()
        
        // 현재 날짜와의 차이를 월 단위로 계산
        let months = calendar.dateComponents([.month], from: date, to: now).month ?? 0
        
        // 3개월을 전체 너비로 나누어 위치 계산
        let position = leftPadding + width * (CGFloat(3 - months) / 3)
        return position
    }
    
    private func addFavoriteDateIfNeeded(priceHistory: [PriceHistory], favoriteDate: Date?) -> [PriceHistory] {
        guard let favoriteDate = favoriteDate else { return priceHistory }
        
        if priceHistory.contains(where: { history in
            if let parsedDate = history.parsedDate {
                return Calendar.current.isDate(parsedDate, inSameDayAs: favoriteDate)
            }
            return false
        }) {
            return priceHistory
        }
        
        if let lastPriceBeforeFavoriteDate = priceHistory.last(where: { history in
            if let parsedDate = history.parsedDate {
                return parsedDate < favoriteDate
            }
            return false
        }) {
            let favoritePriceHistory = PriceHistory(id: lastPriceBeforeFavoriteDate.id + 1,
                                                   date: DateFormatter.shortDateFormatter.string(from: favoriteDate),
                                                   price: lastPriceBeforeFavoriteDate.price)
            var updatedPriceHistory = priceHistory
            updatedPriceHistory.append(favoritePriceHistory)
            updatedPriceHistory.sort {
                if let date1 = $0.parsedDate, let date2 = $1.parsedDate {
                    return date1 < date2
                }
                return false
            }
            return updatedPriceHistory
        }
        
        return priceHistory
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

extension DateFormatter {
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
}
