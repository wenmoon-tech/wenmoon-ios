//
//  CoinDetailsView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 07.11.24.
//

import SwiftUI
import Charts

struct CoinDetailsView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: CoinDetailsViewModel
    
    @State private var selectedPrice: String
    @State private var selectedDate = String()
    @State private var selectedTimeframe: Timeframe = .oneDay
    @State private var selectedXPosition: CGFloat?
    
    @State private var showMarketsView = false
    @State private var showPriceAlertsView = false
    @State private var showAuthAlert = false
    
    private var coin: CoinData { viewModel.coin }
    private var coinDetails: CoinDetails { viewModel.coinDetails }
    private var marketData: CoinDetails.MarketData { viewModel.coinDetails.marketData }
    private var chartData: [ChartData] { viewModel.chartData }
    private var isLoading: Bool { viewModel.isLoading }
    
    // MARK: - Initializers
    init(coin: CoinData) {
        _viewModel = StateObject(wrappedValue: CoinDetailsViewModel(coin: coin))
        selectedPrice = coin.currentPrice.formattedAsCurrency()
    }
    
    // MARK: - Body
    var body: some View {
        BaseView(errorMessage: $viewModel.errorMessage) {
            VStack(spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    CoinImageView(
                        imageData: coin.imageData,
                        placeholderText: coin.symbol,
                        size: 36
                    )
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text(coin.symbol)
                                .font(.headline).bold()
                            
                            Text("#\(marketData.marketCapRank.formattedOrNone())")
                                .font(.caption).bold()
                        }
                        
                        HStack {
                            Text(selectedPrice)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text(selectedDate)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 24) {
                        Button(action: {
                            guard viewModel.userID != nil else {
                                showAuthAlert = true
                                return
                            }
                            showPriceAlertsView = true
                        }) {
                            Image(systemName: "bell.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundColor(coin.priceAlerts.isEmpty ? .gray : .white)
                        }
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .resizable()
                                .frame(width: 12, height: 12)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        ZStack {
                            if !chartData.isEmpty && !isLoading {
                                makeChartView(chartData)
                            }
                            
                            if chartData.isEmpty && !isLoading {
                                PlaceholderView(text: "No data available", style: .small)
                            }
                            
                            if isLoading {
                                ProgressView()
                            }
                        }
                        .frame(height: 300)
                        .padding(.top, 24)
                        
                        Picker("Select Timeframe", selection: $selectedTimeframe) {
                            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                                Text(timeframe.displayValue).tag(timeframe)
                            }
                        }
                        .pickerStyle(.segmented)
                        .scaleEffect(0.85)
                        .disabled(isLoading)
                        
                        VStack(spacing: 24) {
                            Button(action: {
                                showMarketsView = true
                                viewModel.triggerImpactFeedback()
                            }) {
                                Text("Buy")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .foregroundColor(.black)
                                    .background(.white)
                                    .cornerRadius(32)
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    makeDetailRow(label: "Market Cap", value: coin.marketCap.formattedWithAbbreviation(suffix: "$"))
                                    makeDetailRow(label: "24h Volume", value: marketData.totalVolume.formattedWithAbbreviation(suffix: "$"))
                                    makeDetailRow(label: "Max Supply", value: marketData.maxSupply.formattedWithAbbreviation(placeholder: "∞"))
                                    makeDetailRow(label: "All-Time High", value: marketData.ath.formattedAsCurrency())
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    makeDetailRow(label: "Fully Diluted Market Cap", value: marketData.fullyDilutedValuation.formattedWithAbbreviation(suffix: "$"))
                                    makeDetailRow(label: "Circulating Supply", value: marketData.circulatingSupply.formattedWithAbbreviation())
                                    makeDetailRow(label: "Total Supply", value: marketData.totalSupply.formattedWithAbbreviation())
                                    makeDetailRow(label: "All-Time Low", value: marketData.atl.formattedAsCurrency())
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            
                            if let description = coinDetails.description?.htmlStripped, !description.isEmpty {
                                makeSectionView(title: "Description") {
                                    ExpandableTextView(text: description)
                                }
                            }
                            
                            makeSectionView(title: "Links") {
                                LinksView(links: coinDetails.links)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 16)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .padding(.top, 24)
            .background(Color.black)
        }
        .onChange(of: selectedTimeframe) { _, timeframe in
            Task {
                await viewModel.fetchChartData(on: timeframe)
            }
        }
        .onChange(of: selectedPrice) {
            viewModel.triggerSelectionFeedback()
        }
        .sheet(isPresented: $showMarketsView) {
            let tickers = coinDetails.tickers
            let detents: Set<PresentationDetent> = tickers.count > 5 ? [.large] : [.medium, .large]
            CoinMarketsView(tickers: tickers)
                .presentationDetents(detents)
        }
        .sheet(isPresented: $showPriceAlertsView) {
            PriceAlertsView(coin: coin)
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(36)
        }
        .alert(isPresented: $showAuthAlert) {
            Alert(
                title: Text("Need to Sign In, Buddy!"),
                message: Text("You gotta slide over to the Account tab and log in to check out your price alerts."),
                dismissButton: .default(Text("OK"))
            )
        }
        .task {
            await viewModel.fetchChartData(on: selectedTimeframe)
            await viewModel.fetchCoinDetails()
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func makeChartView(_ data: [ChartData]) -> some View {
        let prices = data.map { $0.price }
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 1
        let priceRange = minPrice...maxPrice
        
        Chart {
            let chartColor: Color = viewModel.isPriceChangeNegative ? .wmRed : .wmGreen
            ForEach(data, id: \.date) { dataPoint in
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    yStart: .value("Min Price", minPrice),
                    yEnd: .value("Price", dataPoint.price)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            chartColor.opacity(0.5),
                            chartColor.opacity(0.25),
                            chartColor.opacity(0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            
            ForEach(data, id: \.date) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Price", dataPoint.price)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(chartColor)
            }
        }
        .chartYScale(domain: priceRange)
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
        .chartOverlay { proxy in
            makeChartOverlay(proxy: proxy, data: data)
        }
    }
    
    @ViewBuilder
    private func makeChartOverlay(proxy: ChartProxy, data: [ChartData]) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .gesture(
                    LongPressGesture(minimumDuration: .zero)
                        .sequenced(before: DragGesture(minimumDistance: .zero))
                        .onChanged { value in
                            switch value {
                            case .first(true):
                                updateSelectedData(
                                    location: geometry.frame(in: .local).origin,
                                    proxy: proxy,
                                    data: data,
                                    geometry: geometry
                                )
                            case .second(true, let drag):
                                if let location = drag?.location {
                                    updateSelectedData(
                                        location: location,
                                        proxy: proxy,
                                        data: data,
                                        geometry: geometry
                                    )
                                }
                            default:
                                break
                            }
                        }
                        .onEnded { _ in
                            selectedPrice = coin.currentPrice.formattedAsCurrency()
                            selectedDate = ""
                            selectedXPosition = nil
                        }
                )
            
            if let selectedXPosition {
                ZStack {
                    let separatorWidth: CGFloat = 1
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: separatorWidth, height: geometry.size.height + 20)
                        .position(x: selectedXPosition, y: geometry.size.height / 2)
                    
                    Rectangle()
                        .fill(.black.opacity(0.6))
                        .frame(width: geometry.size.width - selectedXPosition + separatorWidth, height: geometry.size.height + 20)
                        .position(x: selectedXPosition + separatorWidth + (geometry.size.width - selectedXPosition) / 2, y: geometry.size.height / 2)
                }
            }
        }
    }
    
    @ViewBuilder
    private func makeDetailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.caption)
        }
    }
    
    @ViewBuilder
    private func makeSectionView(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }
            content()
        }
    }
    
    // MARK: - Helper Methods
    private func updateSelectedData(
        location: CGPoint,
        proxy: ChartProxy,
        data: [ChartData],
        geometry: GeometryProxy
    ) {
        guard location.x >= .zero, location.x <= geometry.size.width else {
            selectedXPosition = nil
            return
        }
        
        if let date: Date = proxy.value(atX: location.x) {
            if let closestDataPoint = data.min(by: {
                abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
            }) {
                selectedPrice = closestDataPoint.price.formattedAsCurrency()
                selectedXPosition = location.x
                
                let formatType: Date.FormatType
                switch selectedTimeframe {
                case .oneDay:
                    formatType = .timeOnly
                case .oneWeek:
                    formatType = .dateAndTime
                default:
                    formatType = .dateOnly
                }
                selectedDate = closestDataPoint.date.formatted(as: formatType)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    CoinDetailsView(coin: CoinData())
}
