//
//  PriceAlertService.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 23.05.23.
//

import Foundation

protocol PriceAlertService {
    func getPriceAlerts(deviceToken: String) async throws -> [PriceAlert]
    func setPriceAlert(_ targetPrice: Double, for coin: CoinData, deviceToken: String) async throws -> PriceAlert
    func deletePriceAlert(for id: String, deviceToken: String) async throws -> PriceAlert
}

final class PriceAlertServiceImpl: BaseBackendService, PriceAlertService {
    // MARK: - PriceAlertService
    func getPriceAlerts(deviceToken: String) async throws -> [PriceAlert] {
        do {
            let data = try await httpClient.get(path: "price-alerts", headers: ["X-Device-ID": deviceToken])
            let priceAlerts = try decoder.decode([PriceAlert].self, from: data)
            print("Price Alerts: \(priceAlerts)")
            return priceAlerts
        } catch {
            throw mapToAPIError(error)
        }
    }
    
    func setPriceAlert(_ targetPrice: Double, for coin: CoinData, deviceToken: String) async throws -> PriceAlert {
        let request = PriceAlert(
            id: coin.id,
            name: coin.name,
            targetPrice: targetPrice,
            targetDirection: (coin.currentPrice ?? .zero) < targetPrice ? .above : .below
        )
        do {
            let body = try encoder.encode(request)
            let data = try await httpClient.post(path: "price-alert", headers: ["X-Device-ID": deviceToken], body: body)
            let priceAlert = try decoder.decode(PriceAlert.self, from: data)
            print("Successfully set price alert for \(priceAlert.name) with target price \(priceAlert.targetPrice)")
            return priceAlert
        } catch {
            throw mapToAPIError(error)
        }
    }
    
    func deletePriceAlert(for id: String, deviceToken: String) async throws -> PriceAlert {
        do {
            let data = try await httpClient.delete(path: "price-alert/\(id)", headers: ["X-Device-ID": deviceToken])
            let priceAlert = try decoder.decode(PriceAlert.self, from: data)
            print("Successfully deleted price alert for \(priceAlert.name)")
            return priceAlert
        } catch {
            throw mapToAPIError(error)
        }
    }
}
