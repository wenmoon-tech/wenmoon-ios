//
//  AddPriceAlertViewModelTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 22.04.23.
//

import XCTest
import Combine
@testable import WenMoon

class AddPriceAlertViewModelTests: XCTestCase {

    // MARK: - Properties

    var viewModel: AddPriceAlertViewModel!
    var service: CoinScannerServiceMock!
    var cancellables: Set<AnyCancellable>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        service = CoinScannerServiceMock()
        viewModel = AddPriceAlertViewModel(service: service)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        viewModel = nil
        service = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testFetchCoinsAtFirstPageSuccess() {
        let response = Coin.Page.first.mock
        service.getCoinsAtPageResult = .success(response)

        let expectation = XCTestExpectation(description: "Fetch an array of coins on page 1")
        viewModel.$coins
            .dropFirst()
            .sink { coins in
                XCTAssert(!coins.isEmpty)
                XCTAssertEqual(coins.count, 2)
                XCTAssertEqual(coins.first?.id, response.first?.id)
                XCTAssertEqual(coins.first?.symbol, response.first?.symbol)
                XCTAssertEqual(coins.first?.name, response.first?.name)
                XCTAssertEqual(coins.first?.image, response.first?.image)
                XCTAssertEqual(coins.last?.id, response.last?.id)
                XCTAssertEqual(coins.last?.symbol, response.last?.symbol)
                XCTAssertEqual(coins.last?.name, response.last?.name)
                XCTAssertEqual(coins.last?.image, response.last?.image)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.fetchCoins()

        wait(for: [expectation], timeout: 1)

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showErrorAlert)
    }

    func testFetchCoinsOnNextPageSuccess() {
        let response = Coin.Page.second.mock
        service.getCoinsAtPageResult = .success(response)

        let expectation = XCTestExpectation(description: "Fetch an array of coins on page 2")
        viewModel.$coins
            .dropFirst()
            .sink { coins in
                XCTAssert(!coins.isEmpty)
                XCTAssertEqual(coins.count, 2)
                XCTAssertEqual(coins.first?.id, response.first?.id)
                XCTAssertEqual(coins.first?.symbol, response.first?.symbol)
                XCTAssertEqual(coins.first?.name, response.first?.name)
                XCTAssertEqual(coins.first?.image, response.first?.image)
                XCTAssertEqual(coins.last?.id, response.last?.id)
                XCTAssertEqual(coins.last?.symbol, response.last?.symbol)
                XCTAssertEqual(coins.last?.name, response.last?.name)
                XCTAssertEqual(coins.last?.image, response.last?.image)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.fetchCoinsOnNextPage()

        wait(for: [expectation], timeout: 1)

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showErrorAlert)
    }

    func testSearchCoinByQuerySuccess() {
        let response = CoinSearchResult.mock
        service.searchCoinsByQueryResult = .success(response)

        let expectation = XCTestExpectation(description: "Search for a specific coins by query")
        viewModel.$coins
            .dropFirst()
            .sink { coins in
                XCTAssertFalse(coins.isEmpty)
                XCTAssertEqual(coins.count, 2)
                XCTAssertEqual(coins.first?.id, response.coins.first?.id)
                XCTAssertEqual(coins.first?.symbol, response.coins.first?.symbol)
                XCTAssertEqual(coins.first?.name, response.coins.first?.name)
                XCTAssertEqual(coins.first?.image, response.coins.first?.image)
                XCTAssertEqual(coins.last?.id, response.coins.last?.id)
                XCTAssertEqual(coins.last?.symbol, response.coins.last?.symbol)
                XCTAssertEqual(coins.last?.name, response.coins.last?.name)
                XCTAssertEqual(coins.last?.image, response.coins.last?.image)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.searchCoins(by: "bit")

        wait(for: [expectation], timeout: 1)

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showErrorAlert)
    }

    func testSearchCoinsByQueryEmptyResult() {
        let response = CoinSearchResult.mock
        service.searchCoinsByQueryResult = .success(response)

        let expectation = XCTestExpectation(description: "Search for a specific coins by invalid query")
        viewModel.$coins
            .sink { coins in
                XCTAssert(coins.isEmpty)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.searchCoins(by: "sdfghjkl")

        wait(for: [expectation], timeout: 1)

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showErrorAlert)
    }

    func testFetchCoinsAtFirstPageFailure() {
        let apiError: APIError = .apiError(error: .init(.badServerResponse), description: "Mocked server error")
        service.getCoinsAtPageResult = .failure(apiError)

        let expectation = XCTestExpectation(description: "Get a failure with API error")
        viewModel.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage)
                XCTAssertEqual(errorMessage, apiError.errorDescription)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.fetchCoins()

        wait(for: [expectation], timeout: 1)

        XCTAssertFalse(viewModel.isLoading)
        XCTAssert(viewModel.showErrorAlert)
    }

    func testSearchCoinsByQueryFailure() {
        let apiError: APIError = .invalidEndpoint(endpoint: "https://test.com")
        service.searchCoinsByQueryResult = .failure(apiError)

        let expectation = XCTestExpectation(description: "Get a failure with invalid endpoint error")
        viewModel.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage)
                XCTAssertEqual(errorMessage, apiError.errorDescription)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.searchCoins(by: "bit")

        wait(for: [expectation], timeout: 1)

        XCTAssertFalse(viewModel.isLoading)
        XCTAssert(viewModel.showErrorAlert)
    }
}