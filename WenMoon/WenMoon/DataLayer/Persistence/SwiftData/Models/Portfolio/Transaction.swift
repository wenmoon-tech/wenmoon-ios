//
//  Transaction.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 26.12.24.
//

import Foundation
import SwiftData

@Model
final class Transaction: Identifiable {
    enum TransactionType: String, Codable, CaseIterable {
        case buy = "Buy"
        case sell = "Sell"
        case transferIn = "Transfer In"
        case transferOut = "Transfer Out"
    }
    
    @Attribute(.unique)
    var id: String
    var coinID: String?
    var quantity: Double?
    var pricePerCoin: Double?
    var date: Date
    var type: TransactionType
    
    init(
        id: String = UUID().uuidString,
        coinID: String? = nil,
        quantity: Double? = nil,
        pricePerCoin: Double? = nil,
        date: Date = .now,
        type: TransactionType = .buy
    ) {
        self.id = id
        self.coinID = coinID
        self.quantity = quantity
        self.pricePerCoin = pricePerCoin
        self.date = date
        self.type = type
    }
    
    var totalCost: Double {
        guard
            let quantity,
            let pricePerCoin,
            (type == .buy) || (type == .sell)
        else {
            return .zero
        }
        return quantity * pricePerCoin
    }
    
    func update(from transaction: Transaction) {
        quantity = transaction.quantity
        pricePerCoin = transaction.pricePerCoin
        date = transaction.date
        type = transaction.type
    }
}

extension Transaction {
    func copy() -> Transaction {
        Transaction(
            id: id,
            coinID: coinID,
            quantity: quantity,
            pricePerCoin: pricePerCoin,
            date: date,
            type: type
        )
    }
}

// MARK: - Predefined Transactions
extension Transaction {
    static let predefinedTransactions: [Transaction] = [
        // Bitcoin
        Transaction(
            coinID: "bitcoin",
            quantity: 1,
            pricePerCoin: 16_500,
            date: Date(timeIntervalSince1970: 1669852800), // Dec 1, 2022
            type: .buy
        ),
        Transaction(
            coinID: "bitcoin",
            quantity: 0.5,
            pricePerCoin: 22_000,
            date: Date(timeIntervalSince1970: 1678060800), // Mar 6, 2023
            type: .buy
        ),
        Transaction(
            coinID: "bitcoin",
            quantity: 0.3,
            pricePerCoin: 30_000,
            date: Date(timeIntervalSince1970: 1692230400), // Aug 17, 2023
            type: .sell
        ),

        // Ethereum
        Transaction(
            coinID: "ethereum",
            quantity: 2,
            pricePerCoin: 1250,
            date: Date(timeIntervalSince1970: 1670448000), // Dec 7, 2022
            type: .buy
        ),
        Transaction(
            coinID: "ethereum",
            quantity: 1.5,
            pricePerCoin: 1500,
            date: Date(timeIntervalSince1970: 1678665600), // Mar 13, 2023
            type: .buy
        ),
        Transaction(
            coinID: "ethereum",
            quantity: 1,
            pricePerCoin: 1650,
            date: Date(timeIntervalSince1970: 1692835200), // Aug 24, 2023
            type: .sell
        ),

        // Dogecoin
        Transaction(
            coinID: "dogecoin",
            quantity: 10_000,
            pricePerCoin: 0.075,
            date: Date(timeIntervalSince1970: 1671148800), // Dec 16, 2022
            type: .buy
        ),
        Transaction(
            coinID: "dogecoin",
            quantity: 15_000,
            pricePerCoin: 0.075,
            date: Date(timeIntervalSince1970: 1679280000), // Mar 20, 2023
            type: .buy
        ),
        Transaction(
            coinID: "dogecoin",
            quantity: 8_000,
            pricePerCoin: 0.06,
            date: Date(timeIntervalSince1970: 1693440000), // Aug 31, 2023
            type: .sell
        )
    ]
}
