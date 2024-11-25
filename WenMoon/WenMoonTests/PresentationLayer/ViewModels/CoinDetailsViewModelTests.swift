//
//  CoinDetailsViewModelTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 11.11.24.
//

import XCTest
@testable import WenMoon

class CoinDetailsViewModelTests: XCTestCase {
    // MARK: - Properties
    var viewModel: CoinDetailsViewModel!
    var coinScannerService: CoinScannerServiceMock!
    var priceAlertService: PriceAlertServiceMock!
    var userDefaultsManager: UserDefaultsManagerMock!
    var deviceToken: String!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        coinScannerService = CoinScannerServiceMock()
        priceAlertService = PriceAlertServiceMock()
        userDefaultsManager = UserDefaultsManagerMock()
        viewModel = CoinDetailsViewModel(
            coin: CoinData(),
            chartData: [:],
            coinScannerService: coinScannerService,
            priceAlertService: priceAlertService,
            userDefaultsManager: userDefaultsManager
        )
        deviceToken = "someDeviceToken"
    }
    
    override func tearDown() {
        viewModel = nil
        coinScannerService = nil
        priceAlertService = nil
        deviceToken = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testFetchChartData_success() async throws {
        // Setup
        let chartData = ChartDataFactoryMock.makeChartDataForTimeframes()
        coinScannerService.getChartDataResult = .success(chartData)
        
        // Action
        await viewModel.fetchChartData()
        
        // Assertions
        assertChartDataEqual(viewModel.chartData, chartData[Timeframe.oneHour.rawValue]!)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testFetchChartData_usesCache() async throws {
        // Setup
        let cachedChartData = ChartDataFactoryMock.makeChartDataForTimeframes()
        viewModel.chartDataCache = cachedChartData
        
        // Action
        await viewModel.fetchChartData()
        
        // Assertions
        assertChartDataEqual(viewModel.chartData, cachedChartData[Timeframe.oneHour.rawValue]!)
    }
    
    func testFetchChartData_invalidParameterError() async throws {
        // Setup
        let error = ErrorFactoryMock.makeInvalidParameterError()
        coinScannerService.getChartDataResult = .failure(error)
        
        // Action
        await viewModel.fetchChartData()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
    }
    
    func testSetPriceAlert_success() async throws {
        // Setup
        userDefaultsManager.getObjectReturnValue = ["deviceToken": deviceToken!]
        let coin = CoinFactoryMock.makeCoinData()
        let targetPrice: Double = 70000
        viewModel.coin = coin
        let priceAlert = PriceAlertFactoryMock.makePriceAlert()
        priceAlertService.setPriceAlertResult = .success(priceAlert)
        
        // Action - Set the price alert
        await viewModel.setPriceAlert(for: coin, targetPrice: targetPrice)
        
        // Assertions after setting the price alert
        assertCoinHasAlert(viewModel.coin, targetPrice)
        XCTAssertNil(viewModel.errorMessage)
        
        // Action - Delete Price Alert
        priceAlertService.deletePriceAlertResult = .success(priceAlert)
        await viewModel.setPriceAlert(for: coin, targetPrice: nil)
        
        // Assertions after deleting the price alert
        assertCoinHasNoAlert(viewModel.coin)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSetPriceAlert_encodingError() async throws {
        // Setup
        userDefaultsManager.getObjectReturnValue = ["deviceToken": deviceToken!]
        let coin = CoinFactoryMock.makeCoinData()
        viewModel.coin = coin
        let error = ErrorFactoryMock.makeFailedToEncodeBodyError()
        priceAlertService.setPriceAlertResult = .failure(error)
        
        // Action
        await viewModel.setPriceAlert(for: coin, targetPrice: 70000)
        
        // Assertions
        assertCoinHasNoAlert(coin)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
    }
}
