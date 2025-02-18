//
//  CoinDetails+Ticker.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 14.02.25.
//

import SwiftUI

extension CoinDetails {
    struct Ticker: Codable, Hashable {
        // MARK: - Nested Types
        struct Market: Codable, Hashable {
            var name: String? = nil
            var identifier: String? = nil
            var hasTradingIncentive: Bool? = nil
        }
        
        enum TrustScore: String, Codable, Hashable {
            case green, yellow, red
            
            var color: Color {
                switch self {
                case .green: return .wmGreen
                case .yellow: return .wmYellow
                case .red: return .wmRed
                }
            }
        }
        
        // MARK: - Properties
        let base: String
        let target: String
        let market: Market
        let convertedLast: Double?
        let convertedVolume: Double?
        let trustScore: TrustScore?
        let tradeUrl: URL?
        
        // MARK: - Initializers
        init(
            base: String,
            target: String,
            market: Market,
            convertedLast: Double?,
            convertedVolume: Double?,
            trustScore: TrustScore?,
            tradeUrl: URL?
        ) {
            self.base = base
            self.target = target
            self.market = market
            self.convertedLast = convertedLast
            self.convertedVolume = convertedVolume
            self.trustScore = trustScore
            self.tradeUrl = tradeUrl
        }
        
        // MARK: - Codable
        private enum CodingKeys: String, CodingKey {
            case base, target, market, convertedLast, convertedVolume, trustScore, tradeUrl
        }
        enum CurrencyKeys: String, CodingKey { case usd }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            base = try container.decode(String.self, forKey: .base)
            target = try container.decode(String.self, forKey: .target)
            market = try container.decode(Market.self, forKey: .market)
            
            let convertedLast = try container.decodeIfPresent([String: Double].self, forKey: .convertedLast)
            self.convertedLast = convertedLast?["usd"]
            
            let convertedVolume = try container.decodeIfPresent([String: Double].self, forKey: .convertedVolume)
            self.convertedVolume = convertedVolume?["usd"]
            
            trustScore = try container.decodeIfPresent(TrustScore.self, forKey: .trustScore)
            tradeUrl = try container.decodeIfPresent(URL.self, forKey: .tradeUrl)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(base, forKey: .base)
            try container.encode(target, forKey: .target)
            try container.encode(market, forKey: .market)
            
            if let convertedLast = convertedLast {
                try container.encode(["usd": convertedLast], forKey: .convertedLast)
            }
            
            if let convertedVolume = convertedVolume {
                try container.encode(["usd": convertedVolume], forKey: .convertedVolume)
            }
            
            try container.encodeIfPresent(trustScore, forKey: .trustScore)
            try container.encodeIfPresent(tradeUrl, forKey: .tradeUrl)
        }
    }
}
