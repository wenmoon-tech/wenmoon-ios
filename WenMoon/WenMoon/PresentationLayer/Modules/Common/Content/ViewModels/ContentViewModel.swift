//
//  ContentViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 15.01.25.
//

import Foundation

final class ContentViewModel: BaseViewModel {
    // MARK: - Properties
    private let coinScannerService: CoinScannerService
    
    @Published var startScreenIndex: Int = .zero
    @Published private(set) var globalMarketItems: [GlobalMarketItem] = []
    
    // MARK: - Initializers
    convenience init() {
        self.init(coinScannerService: CoinScannerServiceImpl())
    }
    
    init(coinScannerService: CoinScannerService) {
        self.coinScannerService = coinScannerService
        super.init()
    }
    
    // MARK: - Internal Methods
    func fetchStartScreen() {
        startScreenIndex = (try? userDefaultsManager.getObject(forKey: .setting(ofType: .startScreen), objectType: Int.self)) ?? .zero
    }
    
    @MainActor
    func fetchGlobalCryptoMarketData() async {
        do {
            let globalCryptoMarketData = try await coinScannerService.getGlobalCryptoMarketData()
            let btcDominance = globalCryptoMarketData.marketCapPercentage["btc"] ?? .zero
            let ethDominance = globalCryptoMarketData.marketCapPercentage["eth"] ?? .zero
            let othersDominance = 100 - (btcDominance + ethDominance)
            
            let items = [
                GlobalMarketItem(
                    type: .btcDominance,
                    value: btcDominance.formattedAsPercentage(includePlusSign: false)
                ),
                GlobalMarketItem(
                    type: .ethDominance,
                    value: ethDominance.formattedAsPercentage(includePlusSign: false)
                ),
                GlobalMarketItem(
                    type: .othersDominance,
                    value: othersDominance.formattedAsPercentage(includePlusSign: false)
                )
            ]
            let newItems = items.filter { !globalMarketItems.contains($0) }
            globalMarketItems.append(contentsOf: newItems)
        } catch {
            setErrorMessage(error)
        }
    }
    
    @MainActor
    func fetchGlobalMarketData() async {
        do {
            let globalMarketData = try await coinScannerService.getGlobalMarketData()
            let items = [
                GlobalMarketItem(
                    type: .cpi,
                    value: globalMarketData.cpiPercentage.formattedAsPercentage(includePlusSign: false)
                ),
                GlobalMarketItem(
                    type: .nextCPI,
                    value: globalMarketData.nextCPIDate.formatted(as: .dateOnly)
                ),
                GlobalMarketItem(
                    type: .interestRate,
                    value: globalMarketData.interestRatePercentage.formattedAsPercentage(includePlusSign: false)
                ),
                GlobalMarketItem(
                    type: .nextFOMCMeeting,
                    value: globalMarketData.nextFOMCMeetingDate.formatted(as: .dateOnly)
                )
            ]
            let newItems = items.filter { !globalMarketItems.contains($0) }
            globalMarketItems.append(contentsOf: newItems)
        } catch {
            setErrorMessage(error)
        }
    }
}
