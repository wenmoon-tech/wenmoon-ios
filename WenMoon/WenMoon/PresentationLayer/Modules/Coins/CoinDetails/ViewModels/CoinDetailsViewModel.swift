//
//  CoinDetailsViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 07.11.24.
//

import Foundation

final class CoinDetailsViewModel: BaseViewModel {
    // MARK: - Properties
    private let coinScannerService: CoinScannerService
    
    @Published private(set) var coin: CoinData
    @Published private(set) var coinDetails = CoinDetails()
    @Published private(set) var chartData: [ChartData] = []
    
    var chartDataCache: [Timeframe: [ChartData]] = [:]
    
    var isPriceChangeNegative: Bool {
        guard let firstPrice = chartData.first?.price,
              let lastPrice = chartData.last?.price else {
            return false
        }
        return lastPrice < firstPrice
    }
    
    // MARK: - Initializers
    convenience init(coin: CoinData) {
        self.init(coin: coin, coinScannerService: CoinScannerServiceImpl())
    }
    
    init(coin: CoinData, coinScannerService: CoinScannerService) {
        self.coin = coin
        self.coinScannerService = coinScannerService
        super.init()
    }
    
    // MARK: - Internal Methods
    @MainActor
    func fetchChartData(on timeframe: Timeframe = .oneDay, currency: Currency = .usd) async {
        isLoading = true
        defer { isLoading = false }
        
        if let cachedChartData = chartDataCache[timeframe], !cachedChartData.isEmpty {
            chartData = cachedChartData
            return
        }
        
        do {
            chartData = try await coinScannerService.getChartData(for: coin.id, on: timeframe.value, currency: currency.rawValue)
            chartDataCache[timeframe] = chartData
        } catch {
            setError(error)
        }
    }
    
    @MainActor
    func fetchCoinDetails() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            coinDetails = try await coinScannerService.getCoinDetails(for: coin.id)
        } catch {
            setError(error)
        }
    }
}
