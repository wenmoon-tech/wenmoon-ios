//
//  Coin.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import Foundation

protocol CoinProtocol {
    var id: String { get }
    var symbol: String { get }
    var name: String { get }
    var image: URL? { get }
    var currentPrice: Double? { get }
    var marketCap: Double? { get }
    var priceChangePercentage24H: Double? { get }
}

struct Coin: Codable {
    let id: String
    let symbol: String
    let name: String
    let image: URL?
    let currentPrice: Double?
    let marketCap: Double?
    let marketCapRank: Int64?
    let priceChangePercentage24H: Double?
    let circulatingSupply: Double?
    let ath: Double?
}

extension Coin: Hashable {}
extension Coin: CoinProtocol {}
