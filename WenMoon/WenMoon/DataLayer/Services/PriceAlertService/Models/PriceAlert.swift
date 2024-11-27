//
//  PriceAlert.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 23.05.23.
//

import Foundation

struct PriceAlert: Codable, Hashable {
    enum TargetDirection: String, Codable {
        case above = "ABOVE"
        case below = "BELOW"
    }
    
    let id: String
    let name: String
    let targetPrice: Double
    let targetDirection: TargetDirection
}
