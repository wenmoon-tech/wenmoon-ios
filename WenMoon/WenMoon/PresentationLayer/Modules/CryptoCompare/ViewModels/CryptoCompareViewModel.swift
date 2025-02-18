//
//  CryptoCompareViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 05.12.24.
//

import Foundation

final class CryptoCompareViewModel: BaseViewModel {
    // MARK: - Internal Methods
    func calculatePrice(for coinA: Coin?, coinB: Coin?, option: PriceOption) -> Double? {
        guard let coinA, let coinB else { return nil }
        
        switch option {
        case .now:
            guard let marketCap = coinB.marketCap, let supply = coinA.circulatingSupply else { return nil }
            return marketCap / supply
        case .ath:
            guard
                let bATH = coinB.ath,
                let bSupply = coinB.circulatingSupply,
                let aSupply = coinA.circulatingSupply
            else {
                return nil
            }
            
            return (bATH * bSupply) / aSupply
        }
    }
    
    func calculateMultiplier(for coinA: Coin?, coinB: Coin?, option: PriceOption) -> Double? {
        let hypotheticalPrice = calculatePrice(
            for: coinA,
            coinB: coinB,
            option: option
        )
        
        guard
            let coinA,
            let coinB,
            let hypotheticalPrice,
            let currentPrice = coinA.currentPrice
        else {
            return nil
        }
        
        return hypotheticalPrice / currentPrice
    }
    
    func isPositiveMultiplier(_ multiplier: Double) -> Bool? {
        guard !multiplier.isZero else { return nil }
        return multiplier >= 1
    }
}

enum PriceOption: String, CaseIterable {
    case now = "NOW"
    case ath = "ATH"
}
