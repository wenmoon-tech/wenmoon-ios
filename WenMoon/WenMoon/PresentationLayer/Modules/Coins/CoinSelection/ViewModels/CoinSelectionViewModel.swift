//
//  CoinSelectionViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import Foundation
import Combine
import SwiftData

final class CoinSelectionViewModel: BaseViewModel {
    // MARK: - Properties
    private let coinScannerService: CoinScannerService

    @Published private(set) var coins: [Coin] = []
    @Published private(set) var isLoadingMoreItems = false
    
    @Published var searchText: String = ""
    @Published var isInSearchMode = false

    var coinsCache: [Int: [Coin]] = [:]
    var searchCoinsCache: [String: [Coin]] = [:]

    private(set) var currentPage = 1
    private(set) var savedCoinIDs: Set<String> = []

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializers
    convenience init() {
        self.init(coinScannerService: CoinScannerServiceImpl())
    }
    
    init(coinScannerService: CoinScannerService, swiftDataManager: SwiftDataManager? = nil) {
        self.coinScannerService = coinScannerService
        super.init(swiftDataManager: swiftDataManager)
        
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                Task { await self?.handleQueryChange(query) }
            }
            .store(in: &cancellables)
    }

    // MARK: - Internal Methods
    @MainActor
    func fetchCoins(at page: Int = 1) async {
        isLoading = true
        defer { isLoading = false }
        
        if !isInSearchMode, let cachedCoins = coinsCache[page] {
            coins = page > 1 ? coins + cachedCoins : cachedCoins
            currentPage = page
            return
        }
        
        do {
            let fetchedCoins = try await coinScannerService.getCoins(at: page)
            if !isInSearchMode {
                coinsCache[page] = fetchedCoins
            }
            coins = page > 1 ? coins + fetchedCoins : fetchedCoins
            currentPage = page
        } catch {
            setError(error)
        }
    }
    
    @MainActor
    func fetchCoinsOnNextPageIfNeeded(_ coin: Coin) async {
        if coin.id == coins.last?.id && !isInSearchMode {
            isLoadingMoreItems = true
            defer { isLoadingMoreItems = false }
            await fetchCoins(at: currentPage + 1)
        }
    }

    func fetchSavedCoins() {
        let descriptor = FetchDescriptor<CoinData>(predicate: #Predicate { !$0.isArchived })
        let fetchedCoinIDs = fetch(descriptor).compactMap(\.id)
        savedCoinIDs = Set(fetchedCoinIDs)
    }

    func toggleSaveState(for coin: Coin) {
        if !savedCoinIDs.insert(coin.id).inserted {
            savedCoinIDs.remove(coin.id)
        }
    }

    func isCoinSaved(_ coin: Coin) -> Bool {
        savedCoinIDs.contains(coin.id)
    }
    
    // Search
    @MainActor
    func handleQueryChange(_ query: String) async {
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
            setError(error)
        }
    }
    
    func clearInputFields() {
        searchText = ""
    }
}
