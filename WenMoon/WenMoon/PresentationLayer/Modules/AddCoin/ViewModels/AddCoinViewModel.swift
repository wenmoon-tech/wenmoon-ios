//
//  AddCoinViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import Foundation
import Combine
import SwiftData

final class AddCoinViewModel: BaseViewModel {
    // MARK: - Properties
    @Published private(set) var coins: [Coin] = []
    
    var coinsCache: [Int: [Coin]] = [:]
    var searchCoinsCache: [String: [Coin]] = [:]
    var isInSearchMode = false
    
    private(set) var currentPage = 1
    private(set) var savedCoinIDs: Set<String> = []
    
    private let coinScannerService: CoinScannerService
    
    private var searchQuerySubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializers
    convenience init() {
        self.init(coinScannerService: CoinScannerServiceImpl())
    }
    
    init(coinScannerService: CoinScannerService, swiftDataManager: SwiftDataManager? = nil) {
        self.coinScannerService = coinScannerService
        super.init(swiftDataManager: swiftDataManager)
        
        searchQuerySubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                Task {
                    await self?.handleQueryChange(query)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Internal Methods
    @MainActor
    func fetchCoins(at page: Int = 1) async {
        if !isInSearchMode, let cachedCoins = coinsCache[page] {
            coins = page > 1 ? coins + cachedCoins : cachedCoins
            currentPage = page
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetchedCoins = try await coinScannerService.getCoins(at: page)
            if !isInSearchMode {
                coinsCache[page] = fetchedCoins
            }
            coins = page > 1 ? coins + fetchedCoins : fetchedCoins
            currentPage = page
        } catch {
            setErrorMessage(error)
        }
    }
    
    func fetchCoinsOnNextPageIfNeeded(_ coin: Coin) async {
        if coin.id == coins.last?.id && !isInSearchMode {
            await fetchCoins(at: currentPage + 1)
        }
    }
    
    func handleSearchInput(_ query: String) async {
        searchQuerySubject.send(query)
    }
    
    @MainActor
    func searchCoins(for query: String) async {
        if isInSearchMode, let cachedCoins = searchCoinsCache[query] {
            coins = cachedCoins
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetchedCoins = try await coinScannerService.searchCoins(by: query)
            searchCoinsCache[query] = fetchedCoins
            self.coins = fetchedCoins
        } catch {
            setErrorMessage(error)
        }
    }
    
    func fetchSavedCoins() {
        let descriptor = FetchDescriptor<CoinData>()
        savedCoinIDs = Set(fetch(descriptor).compactMap(\.id))
    }
    
    func toggleSaveState(for coin: Coin) {
        if !savedCoinIDs.insert(coin.id).inserted {
            savedCoinIDs.remove(coin.id)
        }
    }
    
    func isCoinSaved(_ coin: Coin) -> Bool {
        savedCoinIDs.contains(coin.id)
    }
    
    // MARK: - Private Methods
    @MainActor
    private func handleQueryChange(_ query: String) async {
        if query.isEmpty {
            isInSearchMode = false
            currentPage = 1
            coins = []
            await fetchCoins(at: currentPage)
        } else {
            isInSearchMode = true
            await searchCoins(for: query)
        }
    }
}
