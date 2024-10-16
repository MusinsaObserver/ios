//
//  PriceHistoryChartView.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI

struct PriceHistoryChartView: View {
    var priceHistory: [PriceHistory]
    var favoriteDate: Date?
    
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        let adjustedPriceHistory = addFavoriteDateIfNeeded(priceHistory: priceHistory, favoriteDate: favoriteDate)
        let currentPrice = adjustedPriceHistory.last?.price ?? 0
        
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let maxPrice = adjustedPriceHistory.map { $0.price }.max() ?? 0
            let minPrice = adjustedPriceHistory.map { $0.price }.min() ?? 0
            
            let priceRange = maxPrice - minPrice
            let yScale = (height - 60) / CGFloat(priceRange)
            let xScale = (width - 100) / CGFloat(90) * scale
            
            ZStack {
                Rectangle()
                    .fill(Color.black)
                    .cornerRadius(8)
                    .padding(.horizontal, -10)
                
                Path { path in
                    path.move(to: CGPoint(x: 70, y: 10))
                    path.addLine(to: CGPoint(x: 70, y: height - 50))
                }
                .stroke(Color.white, lineWidth: 2)
                
                Path { path in
                    path.move(to: CGPoint(x: 70, y: height - 50))
                    path.addLine(to: CGPoint(x: width - 30, y: height - 50))
                }
                .stroke(Color.white, lineWidth: 2)
                
                Path { path in
                    for (index, history) in adjustedPriceHistory.enumerated() {
                        if let parsedDate = history.parsedDate, let firstParsedDate = adjustedPriceHistory.first?.parsedDate {
                            let daysSinceStart = Calendar.current.dateComponents([.day], from: firstParsedDate, to: parsedDate).day ?? 0
                            let xPosition = 70 + CGFloat(daysSinceStart) * xScale
                            let yPosition = height - 50 - CGFloat(history.price - minPrice) * yScale
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: xPosition, y: yPosition))
                            } else {
                                path.addLine(to: CGPoint(x: xPosition, y: path.currentPoint!.y))
                                path.addLine(to: CGPoint(x: xPosition, y: yPosition))
                            }
                        }
                    }
                }

                .stroke(Color.red, lineWidth: 2)
                
                ForEach(adjustedPriceHistory.indices, id: \.self) { index in
                    if let firstParsedDate = adjustedPriceHistory.first?.parsedDate,
                       let currentParsedDate = adjustedPriceHistory[index].parsedDate {
                        // 첫 번째 기록과 현재 기록의 날짜를 비교하여 일 수 계산
                        let daysSinceStart = Calendar.current.dateComponents([.day], from: firstParsedDate, to: currentParsedDate).day ?? 0
                        let xPosition = 70 + CGFloat(daysSinceStart) * xScale
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
                
                Path { path in
                    let yPosition = height - 50 - CGFloat(Double(currentPrice) - minPrice) * yScale
                    path.move(to: CGPoint(x: 70, y: yPosition))
                    path.addLine(to: CGPoint(x: width - 30, y: yPosition))
                }
                .stroke(Color.red, style: StrokeStyle(lineWidth: 1, dash: [5]))
                
                ForEach(0..<4) { i in
                    // 첫 번째 기록의 날짜를 Date 타입으로 변환하여 사용
                    if let firstParsedDate = adjustedPriceHistory.first?.parsedDate {
                        // i * 30일을 더한 날짜 계산
                        if let date = Calendar.current.date(byAdding: .day, value: i * 30, to: firstParsedDate) {
                            // 날짜를 문자열로 변환
                            let dateText = DateFormatter.shortDateFormatter.string(from: date)
                            
                            // 날짜를 표시하는 텍스트 뷰
                            Text(dateText)
                                .foregroundColor(.white)
                                .font(.caption2)
                                .position(x: 70 + CGFloat(i * 30) * xScale, y: height - 40)
                        }
                    }
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
                    .position(x: 40, y: height - 50 - CGFloat(Double(currentPrice) - minPrice) * yScale) // y축 왼쪽에 위치
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
    
    private func addFavoriteDateIfNeeded(priceHistory: [PriceHistory], favoriteDate: Date?) -> [PriceHistory] {
        guard let favoriteDate = favoriteDate else { return priceHistory }
        
        // 날짜 비교는 parsedDate로 수행
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
            let favoritePriceHistory = PriceHistory(id: lastPriceBeforeFavoriteDate.id + 1, date: DateFormatter.shortDateFormatter.string(from: favoriteDate), price: lastPriceBeforeFavoriteDate.price)
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
