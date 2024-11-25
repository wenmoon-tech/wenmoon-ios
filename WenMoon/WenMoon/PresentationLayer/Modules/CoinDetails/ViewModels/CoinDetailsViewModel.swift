//
//  CoinDetailsViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 07.11.24.
//

import Foundation

final class CoinDetailsViewModel: BaseViewModel {
    // MARK: - Properties
    @Published var coin: CoinData
    @Published private(set) var chartData: [ChartData] = []
    
    var chartDataCache: [String: [ChartData]] = [:]
    
    private let coinScannerService: CoinScannerService
    private let priceAlertService: PriceAlertService
    
    // MARK: - Initializers
    convenience init(coin: CoinData, chartData: [String: [ChartData]]) {
        self.init(
            coin: coin,
            chartData: chartData,
            coinScannerService: CoinScannerServiceImpl(),
            priceAlertService: PriceAlertServiceImpl()
        )
    }
    
    init(
        coin: CoinData,
        chartData: [String: [ChartData]],
        coinScannerService: CoinScannerService,
        priceAlertService: PriceAlertService
    ) {
        self.coin = coin
        self.coinScannerService = coinScannerService
        self.priceAlertService = priceAlertService
        
        if !chartData.isEmpty {
            self.chartDataCache = chartData
            self.chartData = chartData[Timeframe.oneHour.rawValue] ?? []
        }
        
        super.init()
    }
    
    // MARK: - Internal Methods
    @MainActor
    func fetchChartData(on timeframe: Timeframe = .oneHour) async {
        isLoading = true
        defer { isLoading = false }
        
        if let cachedData = chartDataCache[timeframe.rawValue] {
            chartData = cachedData
            return
        }
        
        do {
            let fetchedData = try await coinScannerService.getChartData(for: coin.symbol, currency: .usd)
            for timeframe in Timeframe.allCases {
                if let data = fetchedData[timeframe.rawValue] {
                    chartDataCache[timeframe.rawValue] = data
                }
            }
            chartData = chartDataCache[timeframe.rawValue] ?? []
        } catch {
            setErrorMessage(error)
        }
    }
    
    func setPriceAlert(for coin: CoinData, targetPrice: Double?) async {
        if let targetPrice {
            await setPriceAlert(targetPrice, for: coin)
        } else {
            await deletePriceAlert(for: coin)
        }
        save()
    }
    
    // MARK: - Private Methods
    @MainActor
    private func setPriceAlert(_ targetPrice: Double, for coin: CoinData) async {
        guard let deviceToken else {
            print("Device token is nil")
            return
        }
        do {
            let _ = try await priceAlertService.setPriceAlert(targetPrice, for: coin, deviceToken: deviceToken)
            coin.targetPrice = targetPrice
            coin.isActive = true
        } catch {
            coin.targetPrice = nil
            coin.isActive = false
            setErrorMessage(error)
        }
    }
    
    @MainActor
    private func deletePriceAlert(for coin: CoinData) async {
        guard let deviceToken else {
            print("Device token is nil")
            return
        }
        do {
            let _ = try await priceAlertService.deletePriceAlert(for: coin.id, deviceToken: deviceToken)
            coin.targetPrice = nil
            coin.isActive = false
        } catch {
            setErrorMessage(error)
        }
    }
}
