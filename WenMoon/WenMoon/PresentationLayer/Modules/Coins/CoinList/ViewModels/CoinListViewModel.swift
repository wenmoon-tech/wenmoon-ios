//
//  CoinListViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import Foundation
import SwiftData
import SwiftUI

final class CoinListViewModel: BaseViewModel {
    // MARK: - Properties
    private let coinScannerService: CoinScannerService
    private let priceAlertService: PriceAlertService
    
    @Published var coins: [CoinData] = []
    @Published var marketData: [String: MarketData] = [:]
    
    private var cacheTimer: Timer?
    
    /// Computed properties for coins marked as pinned and not pinned.
    var pinnedCoins: [CoinData] { coins.filter { $0.isPinned } }
    var unpinnedCoins: [CoinData] { coins.filter { !$0.isPinned } }
    
    // MARK: - Initializers
    convenience init() {
        self.init(
            coinScannerService: CoinScannerServiceImpl(),
            priceAlertService: PriceAlertServiceImpl()
        )
    }
    
    init(
        coinScannerService: CoinScannerService,
        priceAlertService: PriceAlertService,
        firebaseAuthService: FirebaseAuthService? = nil,
        userDefaultsManager: UserDefaultsManager? = nil,
        swiftDataManager: SwiftDataManager? = nil
    ) {
        self.coinScannerService = coinScannerService
        self.priceAlertService = priceAlertService
        super.init(
            firebaseAuthService: firebaseAuthService,
            userDefaultsManager: userDefaultsManager,
            swiftDataManager: swiftDataManager
        )
        startCacheTimer()
    }
    
    deinit {
        cacheTimer?.invalidate()
    }
    
    // MARK: - Internal Methods
    /// Fetch coins from the persistent store, apply saved order, update market data and price alerts.
    @MainActor
    func fetchCoins() async {
        if isFirstLaunch {
            let predefinedCoins = CoinData.predefinedCoins
            coins = predefinedCoins
            for coin in predefinedCoins {
                insert(coin)
                saveCoinsOrder()
            }
        } else {
            let descriptor = FetchDescriptor<CoinData>(
                predicate: #Predicate { !$0.isArchived },
                sortBy: [SortDescriptor(\.marketCap)]
            )
            let fetchedCoins = fetch(descriptor)
            
            if let savedOrder = try? userDefaultsManager.getObject(forKey: .coinsOrder, objectType: [String].self) {
                coins = fetchedCoins.sorted { coin1, coin2 in
                    let index1 = savedOrder.firstIndex(of: coin1.id) ?? .max
                    let index2 = savedOrder.firstIndex(of: coin2.id) ?? .max
                    return index1 < index2
                }
            } else {
                coins = fetchedCoins
            }
        }
        
        await fetchMarketData()
        await fetchPriceAlerts()
        triggerImpactFeedback()
    }
    
    /// Fetch latest market data for the coins.
    @MainActor
    func fetchMarketData() async {
        let coinIDs = coins.map { $0.id }
        let existingMarketData = coinIDs.compactMap { marketData[$0] }
        
        guard existingMarketData.count != coins.count else { return }
        
        do {
            let fetchedMarketData = try await coinScannerService.getMarketData(for: coinIDs)
            for (index, coinID) in coinIDs.enumerated() {
                if let coinMarketData = fetchedMarketData[coinID] {
                    marketData[coinID] = coinMarketData
                    coins[index].updateMarketData(from: coinMarketData)
                }
            }
            save()
        } catch {
            setError(error)
        }
    }
    
    /// Fetch price alerts for the coins.
    @MainActor
    func fetchPriceAlerts() async {
        guard let userID, let deviceToken, !coins.isEmpty else {
            // If critical user info is missing, clear all price alerts.
            coins = coins.map { coin in
                let updatedCoin = coin
                updatedCoin.priceAlerts = []
                return updatedCoin
            }
            return
        }
        
        do {
            let priceAlerts = try await priceAlertService.getPriceAlerts(userID: userID, deviceToken: deviceToken)
            for (index, coin) in coins.enumerated() {
                let matchingPriceAlerts = priceAlerts.filter { $0.id.contains(coin.id) }
                coins[index].priceAlerts = matchingPriceAlerts
            }
        } catch {
            setError(error)
        }
    }
    
    /// Save a new coin. If the coin exists but is archived, it is unarchived.
    @MainActor
    func saveCoin(_ coin: Coin) async {
        let descriptor = FetchDescriptor<CoinData>(predicate: #Predicate { $0.id == coin.id })
        let fetchedCoins = fetch(descriptor)
        
        if let existingCoin = fetchedCoins.first {
            if existingCoin.isArchived {
                unarchiveCoin(existingCoin)
            }
            return
        }
        
        await insertCoin(coin)
    }
    
    /// Delete a coin. If the coin is referenced in a portfolio, archive it instead.
    @MainActor
    func deleteCoin(_ coinID: String) async {
        guard let coin = coins.first(where: { $0.id == coinID }) else { return }
        
        let descriptor = FetchDescriptor<Portfolio>()
        let portfolios = fetch(descriptor)
        
        var isCoinReferenced = false
        for portfolio in portfolios {
            if portfolio.transactions.contains(where: { $0.coinID == coin.id }) {
                isCoinReferenced = true
                break
            }
        }
        
        if isCoinReferenced {
            archiveCoin(coin)
        } else {
            removeCoin(coin)
        }
    }
    
    /// Toggles off a price alert after its target is reached.
    func toggleOffPriceAlert(for id: String) {
        for index in coins.indices {
            if let alertIndex = coins[index].priceAlerts.firstIndex(where: { $0.id == id }) {
                coins[index].priceAlerts.remove(at: alertIndex)
                break
            }
        }
    }
    
    /// Pins a coin and reorders the list.
    func pinCoin(_ coin: CoinData) {
        if let index = coins.firstIndex(where: { $0.id == coin.id }) {
            withAnimation {
                coins[index].isPinned = true
                sortCoins()
                saveCoinsOrder()
            }
        }
    }
    
    /// Unpins a coin and reorders the list.
    func unpinCoin(_ coin: CoinData) {
        if let index = coins.firstIndex(where: { $0.id == coin.id }) {
            withAnimation {
                coins[index].isPinned = false
                sortCoins()
                saveCoinsOrder()
            }
        }
    }
    
    /// Move coin(s) within a pinned or unpinned group.
    func moveCoin(from source: IndexSet, to destination: Int, isPinned: Bool) {
        var filteredCoins = coins.filter { $0.isPinned == isPinned }
        filteredCoins.move(fromOffsets: source, toOffset: destination)
        
        let otherCoins = coins.filter { $0.isPinned != isPinned }
        withAnimation {
            coins = isPinned ? (filteredCoins + otherCoins) : (otherCoins + filteredCoins)
        }
        saveCoinsOrder()
    }
    
    // MARK: - Private Methods
    /// Inserts a new coin with optional image data.
    @MainActor
    private func insertCoin(_ coin: Coin) async {
        let imageData = coin.image != nil ? await loadImage(from: coin.image!) : nil
        let newCoin = CoinData(from: coin, imageData: imageData)
        withAnimation {
            coins.append(newCoin)
        }
        insert(newCoin)
        saveCoinsOrder()
    }
    
    /// Removes a coin from the list and deletes it from the persistent store.
    private func removeCoin(_ coin: CoinData) {
        withAnimation {
            if let index = coins.firstIndex(of: coin) {
                coins.remove(at: index)
            }
        }
        // Also remove related market data if present.
        marketData.removeValue(forKey: coin.id)
        delete(coin)
        saveCoinsOrder()
    }
    
    /// Archives a coin (marks as archived and removes it from the active list).
    private func archiveCoin(_ coin: CoinData) {
        withAnimation {
            coin.isPinned = false
            coin.isArchived = true
            if let index = coins.firstIndex(of: coin) {
                coins.remove(at: index)
            }
        }
        save()
        saveCoinsOrder()
    }
    
    /// Unarchives a coin (marks as not archived and adds it back to the list).
    private func unarchiveCoin(_ coin: CoinData) {
        coin.isArchived = false
        withAnimation {
            coins.append(coin)
        }
        save()
        saveCoinsOrder()
    }
    
    /// Save the current coin order to persistent storage.
    private func saveCoinsOrder() {
        let coinIDs = coins.map { $0.id }
        try? userDefaultsManager.setObject(coinIDs, forKey: .coinsOrder)
    }
    
    /// Sort coins so that pinned coins always appear at the top.
    private func sortCoins() {
        withAnimation {
            coins.sort { coin1, coin2 in
                if coin1.isPinned != coin2.isPinned {
                    return coin1.isPinned
                }
                return (coin1.marketCap ?? .zero) > (coin2.marketCap ?? .zero)
            }
        }
    }
    
    /// Starts a timer to clear cached market data periodically.
    private func startCacheTimer() {
        cacheTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.clearCacheIfNeeded()
        }
    }
    
    /// Clears the market data cache.
    private func clearCacheIfNeeded() {
        if !marketData.isEmpty {
            marketData.removeAll()
        }
    }
}
