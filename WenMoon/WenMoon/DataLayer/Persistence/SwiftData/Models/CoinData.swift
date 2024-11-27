//
//  CoinData.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 11.10.24.
//

import Foundation
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
    var marketCapRank: Int64?
    var fullyDilutedValuation: Double?
    var totalVolume: Double?
    var high24H: Double?
    var low24H: Double?
    var priceChange24H: Double?
    var priceChangePercentage24H: Double?
    var marketCapChange24H: Double?
    var marketCapChangePercentage24H: Double?
    var circulatingSupply: Double?
    var totalSupply: Double?
    var maxSupply: Double?
    var ath: Double?
    var athChangePercentage: Double?
    var athDate: String?
    var atl: Double?
    var atlChangePercentage: Double?
    var atlDate: String?
    var imageData: Data?
    var priceAlerts: [PriceAlert]
    
    convenience init(from coin: Coin, imageData: Data? = nil, priceAlerts: [PriceAlert] = []) {
        self.init(
            id: coin.id,
            symbol: coin.symbol,
            name: coin.name,
            image: coin.image,
            currentPrice: coin.currentPrice,
            marketCap: coin.marketCap,
            marketCapRank: coin.marketCapRank,
            fullyDilutedValuation: coin.fullyDilutedValuation,
            totalVolume: coin.totalVolume,
            high24H: coin.high24H,
            low24H: coin.low24H,
            priceChange24H: coin.priceChange24H,
            priceChangePercentage24H: coin.priceChangePercentage24H,
            marketCapChange24H: coin.marketCapChange24H,
            marketCapChangePercentage24H: coin.marketCapChangePercentage24H,
            circulatingSupply: coin.circulatingSupply,
            totalSupply: coin.totalSupply,
            maxSupply: coin.maxSupply,
            ath: coin.ath,
            athChangePercentage: coin.athChangePercentage,
            athDate: coin.athDate,
            atl: coin.atl,
            atlChangePercentage: coin.atlChangePercentage,
            atlDate: coin.atlDate,
            imageData: imageData,
            priceAlerts: priceAlerts
        )
    }
    
    init(
        id: String = "",
        symbol: String = "",
        name: String = "",
        image: URL? = nil,
        currentPrice: Double? = nil,
        marketCap: Double? = nil,
        marketCapRank: Int64? = nil,
        fullyDilutedValuation: Double? = nil,
        totalVolume: Double? = nil,
        high24H: Double? = nil,
        low24H: Double? = nil,
        priceChange24H: Double? = nil,
        priceChangePercentage24H: Double? = nil,
        marketCapChange24H: Double? = nil,
        marketCapChangePercentage24H: Double? = nil,
        circulatingSupply: Double? = nil,
        totalSupply: Double? = nil,
        maxSupply: Double? = nil,
        ath: Double? = nil,
        athChangePercentage: Double? = nil,
        athDate: String? = nil,
        atl: Double? = nil,
        atlChangePercentage: Double? = nil,
        atlDate: String? = nil,
        imageData: Data? = nil,
        priceAlerts: [PriceAlert] = []
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.image = image
        self.currentPrice = currentPrice
        self.marketCap = marketCap
        self.marketCapRank = marketCapRank
        self.fullyDilutedValuation = fullyDilutedValuation
        self.totalVolume = totalVolume
        self.high24H = high24H
        self.low24H = low24H
        self.priceChange24H = priceChange24H
        self.priceChangePercentage24H = priceChangePercentage24H
        self.marketCapChange24H = marketCapChange24H
        self.marketCapChangePercentage24H = marketCapChangePercentage24H
        self.circulatingSupply = circulatingSupply
        self.totalSupply = totalSupply
        self.maxSupply = maxSupply
        self.ath = ath
        self.athChangePercentage = athChangePercentage
        self.athDate = athDate
        self.atl = atl
        self.atlChangePercentage = atlChangePercentage
        self.atlDate = atlDate
        self.imageData = imageData
        self.priceAlerts = priceAlerts
    }
}

extension CoinData: CoinProtocol {}

// MARK: - Predefined Coins
extension CoinData {
    static let predefinedCoins =
    [
        CoinData(id: "bitcoin"),
        CoinData(id: "ethereum"),
        CoinData(id: "solana"),
        CoinData(id: "sui"),
        CoinData(id: "bittensor"),
        CoinData(id: "lukso-token-2")
    ]
}
