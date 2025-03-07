//
//  CoinListViewModelTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 22.04.23.
//

import XCTest
@testable import WenMoon

class CoinListViewModelTests: XCTestCase {
    // MARK: - Properties
    var viewModel: CoinListViewModel!
    var priceAlertsViewModel: PriceAlertsViewModel!
    
    var coinScannerService: CoinScannerServiceMock!
    var priceAlertService: PriceAlertServiceMock!
    var firebaseAuthService: FirebaseAuthServiceMock!
    var appLaunchProvider: AppLaunchProviderMock!
    var userDefaultsManager: UserDefaultsManagerMock!
    var swiftDataManager: SwiftDataManagerMock!
    
    var deviceToken: String!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        priceAlertService = PriceAlertServiceMock()
        firebaseAuthService = FirebaseAuthServiceMock()
        userDefaultsManager = UserDefaultsManagerMock()
        
        priceAlertsViewModel = PriceAlertsViewModel(
            priceAlertService: priceAlertService,
            firebaseAuthService: firebaseAuthService,
            userDefaultsManager: userDefaultsManager
        )
        
        coinScannerService = CoinScannerServiceMock()
        appLaunchProvider = AppLaunchProviderMock()
        swiftDataManager = SwiftDataManagerMock()
        
        viewModel = CoinListViewModel(
            priceAlertsViewModel: priceAlertsViewModel,
            coinScannerService: coinScannerService,
            appLaunchProvider: appLaunchProvider,
            userDefaultsManager: userDefaultsManager,
            swiftDataManager: swiftDataManager
        )
        
        deviceToken = "expectedDeviceToken"
    }
    
    override func tearDown() {
        viewModel = nil
        priceAlertsViewModel = nil
        coinScannerService = nil
        appLaunchProvider = nil
        userDefaultsManager = nil
        swiftDataManager = nil
        deviceToken = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    // Fetch Coins
    func testFetchCoins_isFirstLaunch() async {
        // Setup
        let coins = CoinData.predefinedCoins
        let marketData = MarketDataFactoryMock.makeMarketData(for: coins)
        coinScannerService.getMarketDataResult = .success(marketData)
        
        // Action
        await viewModel.fetchCoins()
        
        // Assertions
        assertCoinsEqual(viewModel.coins, coins, marketData: marketData)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testFetchCoins_success() async {
        // Setup
        appLaunchProvider.isFirstLaunch = false
        let coins = CoinFactoryMock.makeCoins()
        swiftDataManager.fetchResult = coins.map { CoinFactoryMock.makeCoinData(from: $0) }
        let marketData = MarketDataFactoryMock.makeMarketData(for: coins)
        coinScannerService.getMarketDataResult = .success(marketData)
        
        // Action
        await viewModel.fetchCoins()
        
        // Assertions
        XCTAssertTrue(swiftDataManager.fetchMethodCalled)
        assertCoinsEqual(viewModel.coins, coins, marketData: marketData)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testFetchCoins_fetchError() async {
        // Setup
        appLaunchProvider.isFirstLaunch = false
        let error: SwiftDataError = .failedToFetchModels
        swiftDataManager.swiftDataError = error
        
        // Action
        await viewModel.fetchCoins()
        
        // Assertions
        XCTAssertTrue(swiftDataManager.fetchMethodCalled)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
    }
    
    func testFetchCoins_emptyResult() async {
        // Setup
        appLaunchProvider.isFirstLaunch = false
        
        // Action
        await viewModel.fetchCoins()
        
        // Assertions
        XCTAssertTrue(viewModel.coins.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testFetchCoins_savedOrder() async {
        // Setup
        let coins = CoinFactoryMock.makeCoins().shuffled()
        let savedOrder = coins.map(\.id)
        appLaunchProvider.isFirstLaunch = false
        userDefaultsManager.getObjectReturnValue = [.coinsOrder: savedOrder]
        swiftDataManager.fetchResult = coins.map { CoinFactoryMock.makeCoinData(from: $0) }
        let marketData = MarketDataFactoryMock.makeMarketData(for: coins)
        coinScannerService.getMarketDataResult = .success(marketData)
        
        // Action
        await viewModel.fetchCoins()
        
        // Assertions
        XCTAssertTrue(swiftDataManager.fetchMethodCalled)
        XCTAssertEqual(viewModel.coins.map(\.id), savedOrder)
        assertCoinsEqual(viewModel.coins, coins, marketData: marketData)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // Save Coin/Order
    func testSaveCoin_success() async {
        // Setup
        let coin = CoinFactoryMock.makeCoin()
        
        // Action
        await viewModel.saveCoin(coin)
        
        // Assertions
        XCTAssertEqual(viewModel.coins.count, 1)
        assertCoinsEqual(viewModel.coins, [coin])
        assertInsertAndSaveMethodsCalled()
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSaveCoin_saveError() async {
        // Setup
        let error: SwiftDataError = .failedToSaveModel
        swiftDataManager.swiftDataError = error
        
        // Action
        let coin = CoinFactoryMock.makeCoin()
        await viewModel.saveCoin(coin)
        
        // Assertions
        assertInsertAndSaveMethodsCalled()
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
    }
    
    func testUnarchiveCoin() async {
        // Setup
        let coin = CoinFactoryMock.makeCoin()
        let archivedCoin = CoinFactoryMock.makeCoinData(from: coin, isArchived: true)
        swiftDataManager.fetchResult = [archivedCoin]
        
        // Action
        await viewModel.saveCoin(coin)
        
        // Assertions
        XCTAssertEqual(viewModel.coins.count, 1)
        assertCoinsEqual(viewModel.coins, [coin])
        XCTAssertFalse(archivedCoin.isArchived)
        XCTAssertTrue(swiftDataManager.saveMethodCalled)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // Delete Coin
    func testDeleteCoin_success() async {
        // Setup
        let coin = CoinFactoryMock.makeCoin()
        await viewModel.saveCoin(coin)
        
        // Action
        await viewModel.deleteCoin(coin.id)
        
        // Assertions
        assertDeleteAndSaveMethodsCalled()
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testDeleteCoin_saveError() async {
        // Setup
        let coin = CoinFactoryMock.makeCoin()
        await viewModel.saveCoin(coin)
        let error: SwiftDataError = .failedToSaveModel
        swiftDataManager.swiftDataError = error
        
        // Action
        await viewModel.deleteCoin(coin.id)
        
        // Assertions
        assertDeleteAndSaveMethodsCalled()
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
    }
    
    func testArchiveCoin() async {
        // Setup
        let coin = CoinFactoryMock.makeCoin()
        await viewModel.saveCoin(coin)
        let unarchivedCoin = CoinFactoryMock.makeCoinData(from: coin)
        let portfolio = PortfolioFactoryMock.makePortfolio(
            transactions: [
                PortfolioFactoryMock.makeTransaction(coinID: unarchivedCoin.id)
            ]
        )
        swiftDataManager.fetchResult = [portfolio]
        
        // Action
        await viewModel.deleteCoin(coin.id)
        
        // Assertions
        XCTAssertFalse(unarchivedCoin.isArchived)
        XCTAssertTrue(swiftDataManager.saveMethodCalled)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // Market Data
    func testFetchMarketData_success() async {
        // Setup
        let marketData = MarketDataFactoryMock.makeMarketData()
        coinScannerService.getMarketDataResult = .success(marketData)
        let coins = CoinFactoryMock.makeCoinsData()
        viewModel.coins.append(contentsOf: coins)
        
        // Action
        await viewModel.fetchMarketData()
        
        // Assertions
        assertMarketDataEqual(for: viewModel.coins, with: marketData)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testFetchMarketData_usesCache() async {
        // Setup
        let marketData = MarketDataFactoryMock.makeMarketData()
        viewModel.marketData = marketData
        let coins = CoinFactoryMock.makeCoinsData()
        viewModel.coins.append(contentsOf: coins)
        
        // Action
        await viewModel.fetchMarketData()
        
        // Assertions
        assertMarketDataEqual(viewModel.marketData, marketData, for: coins.map(\.id))
    }
    
    func testFetchMarketData_apiError() async {
        // Setup
        let error = ErrorFactoryMock.makeAPIError()
        coinScannerService.getMarketDataResult = .failure(error)
        let coin = CoinFactoryMock.makeCoinData()
        viewModel.coins.append(coin)
        
        // Action
        await viewModel.fetchMarketData()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
    }
    
    // Price Alerts
    func testFetchPriceAlerts_success() async {
        // Setup
        userDefaultsManager.getObjectReturnValue = [.deviceToken: deviceToken!]
        firebaseAuthService.idTokenResult = .success("test-id-token")
        
        let coin = CoinFactoryMock.makeCoinData()
        viewModel.coins.append(coin)
        
        let priceAlerts = PriceAlertFactoryMock.makePriceAlerts()
        priceAlertService.getPriceAlertsResult = .success(priceAlerts)
        
        // Action
        await viewModel.fetchPriceAlerts()
        
        // Assertions
        let priceAlert = priceAlerts.first(where: { $0.id == coin.id })!
        assertCoinHasActiveAlert(viewModel.coins.first!, priceAlert)
        XCTAssertNil(viewModel.errorMessage)
        
        // Test after alerts are cleared
        priceAlertService.getPriceAlertsResult = .success([])
        await viewModel.fetchPriceAlerts()
        
        assertCoinHasNoAlert(viewModel.coins.first!)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testDeactivatePriceAlert() {
        // Setup
        let coin = CoinFactoryMock.makeCoinData()
        let priceAlert = PriceAlertFactoryMock.makePriceAlert()
        coin.priceAlerts.append(priceAlert)
        viewModel.coins.append(coin)
        
        // Assertions after setting the price alert
        assertCoinHasActiveAlert(coin, priceAlert)
        
        // Action
        viewModel.deactivatePriceAlert(priceAlert.id)
        
        // Assertions after deleting the price alert
        assertCoinHasNoActiveAlert(coin)
    }
    
    // Pin & Unpin
    func testPinCoin() {
        // Setup
        let coin1 = CoinFactoryMock.makeCoinData(id: "coin-1", isPinned: false)
        let coin2 = CoinFactoryMock.makeCoinData(id: "coin-2", isPinned: false)
        viewModel.coins = [coin1, coin2]
        
        // Action
        viewModel.pinCoin(coin2)
        
        // Assertions
        XCTAssertTrue(coin2.isPinned)
        XCTAssertFalse(coin1.isPinned)
        XCTAssertEqual(viewModel.coins.first?.id, coin2.id)
    }
    
    func testUnpinCoin() {
        // Setup
        let coin1 = CoinFactoryMock.makeCoinData(id: "coin-1", isPinned: true)
        let coin2 = CoinFactoryMock.makeCoinData(id: "coin-2", isPinned: true)
        viewModel.coins = [coin1, coin2]
        
        // Action
        viewModel.unpinCoin(coin1)
        
        // Assertions
        XCTAssertFalse(coin1.isPinned)
        XCTAssertTrue(coin2.isPinned)
        
        let pinnedCoins = viewModel.coins.filter { $0.isPinned }
        XCTAssertFalse(pinnedCoins.contains(where: { $0.id == coin1.id }))
    }
    
    func testMoveCoinPinnedGroup() {
        // Setup
        let coin1 = CoinFactoryMock.makeCoinData(id: "coin-1", isPinned: true)
        let coin2 = CoinFactoryMock.makeCoinData(id: "coin-2", isPinned: true)
        let coin3 = CoinFactoryMock.makeCoinData(id: "coin-3", isPinned: true)
        viewModel.coins = [coin1, coin2, coin3]
        
        // Action
        let source = IndexSet(integer: 2)
        viewModel.moveCoin(from: source, to: .zero, isPinned: true)
        
        // Assertions
        let pinnedCoins = viewModel.coins.filter { $0.isPinned }
        XCTAssertEqual(pinnedCoins.map { $0.id }, ["coin-3", "coin-1", "coin-2"])
    }
    
    func testMoveCoinUnpinnedGroup() {
        // Setup
        let coin1 = CoinFactoryMock.makeCoinData(id: "coin-1", isPinned: false)
        let coin2 = CoinFactoryMock.makeCoinData(id: "coin-2", isPinned: false)
        let coin3 = CoinFactoryMock.makeCoinData(id: "coin-3", isPinned: false)
        viewModel.coins = [coin1, coin2, coin3]
        
        // Action
        let source = IndexSet(integer: .zero)
        viewModel.moveCoin(from: source, to: 2, isPinned: false)
        
        // Assertions
        let unpinnedCoins = viewModel.coins.filter { !$0.isPinned }
        XCTAssertEqual(unpinnedCoins.map { $0.id }, ["coin-2", "coin-1", "coin-3"])
    }
    
    // MARK: - Helpers
    private func assertInsertAndSaveMethodsCalled() {
        XCTAssertTrue(swiftDataManager.insertMethodCalled)
        XCTAssertTrue(swiftDataManager.saveMethodCalled)
    }
    
    private func assertDeleteAndSaveMethodsCalled() {
        XCTAssertTrue(swiftDataManager.deleteMethodCalled)
        XCTAssertTrue(swiftDataManager.saveMethodCalled)
    }
}
