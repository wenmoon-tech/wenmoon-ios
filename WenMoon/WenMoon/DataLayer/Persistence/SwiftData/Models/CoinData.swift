//
//  CoinData.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 11.10.24.
//

import UIKit
import SwiftData

@Model
final class CoinData {
    @Attribute(.unique)
    var id: String
    var symbol: String
    var name: String
    var image: URL?
    var currentPrice: Double?
    var marketCap: Double?
    var priceChangePercentage24H: Double?
    var imageData: Data?
    var priceAlerts: [PriceAlert]
    var isPinned: Bool
    var isArchived: Bool
    
    convenience init(
        from coin: Coin,
        imageData: Data? = nil,
        priceAlerts: [PriceAlert] = []
    ) {
        self.init(
            id: coin.id,
            symbol: coin.symbol.uppercased(),
            name: coin.name,
            image: coin.image,
            currentPrice: coin.currentPrice,
            marketCap: coin.marketCap,
            priceChangePercentage24H: coin.priceChangePercentage24H,
            imageData: imageData,
            priceAlerts: priceAlerts,
            isPinned: false,
            isArchived: false
        )
    }
    
    init(
        id: String = "",
        symbol: String = "",
        name: String = "",
        image: URL? = nil,
        currentPrice: Double? = nil,
        marketCap: Double? = nil,
        priceChangePercentage24H: Double? = nil,
        imageData: Data? = nil,
        priceAlerts: [PriceAlert] = [],
        isPinned: Bool = false,
        isArchived: Bool = false
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.image = image
        self.currentPrice = currentPrice
        self.marketCap = marketCap
        self.priceChangePercentage24H = priceChangePercentage24H
        self.imageData = imageData
        self.priceAlerts = priceAlerts
        self.isPinned = isPinned
        self.isArchived = isArchived
    }
    
    func updateMarketData(from marketData: MarketData) {
        currentPrice = marketData.currentPrice
        marketCap = marketData.marketCap
        priceChangePercentage24H = marketData.priceChange24H
    }
}

extension CoinData: CoinProtocol {}

// MARK: - Predefined Coins
extension CoinData {
    static let predefinedCoins: [CoinData] = [
        CoinData(
            id: "bitcoin",
            symbol: "BTC",
            name: "Bitcoin",
            image: URL(string: "https://coin-images.coingecko.com/coins/images/1/large/bitcoin.png?1696501400"),
            imageData: UIImage(named: "bitcoin.logo")?.pngData(),
            isPinned: true
        ),
        CoinData(
            id: "ethereum",
            symbol: "ETH",
            name: "Ethereum",
            image: URL(string: "https://coin-images.coingecko.com/coins/images/279/large/ethereum.png?1696501628"),
            imageData: UIImage(named: "ethereum.logo")?.pngData(),
            isPinned: true
        ),
        CoinData(
            id: "ripple",
            symbol: "XRP",
            name: "XRP",
            image: URL(string: "https://coin-images.coingecko.com/coins/images/44/large/xrp-symbol-white-128.png?1696501442"),
            imageData: UIImage(named: "xrp.logo")?.pngData()
        ),
        CoinData(
            id: "binancecoin",
            symbol: "BNB",
            name: "BNB",
            image: URL(string: "https://coin-images.coingecko.com/coins/images/825/large/bnb-icon2_2x.png?1696501970"),
            imageData: UIImage(named: "bnb.logo")?.pngData()
        ),
        CoinData(
            id: "solana",
            symbol: "SOL",
            name: "Solana",
            image: URL(string: "https://coin-images.coingecko.com/coins/images/4128/large/solana.png?1718769756"),
            imageData: UIImage(named: "solana.logo")?.pngData()
        ),
        CoinData(
            id: "dogecoin",
            symbol: "DOGE",
            name: "Dogecoin",
            image: URL(string: "https://coin-images.coingecko.com/coins/images/5/large/dogecoin.png?1696501409"),
            imageData: UIImage(named: "dogecoin.logo")?.pngData()
        )
    ]
}
