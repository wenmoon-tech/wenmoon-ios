//
//  PriceAlert.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 23.05.23.
//

import SwiftUI

struct PriceAlert: Codable, Hashable {
    enum TargetDirection: String, Codable {
        case above = "ABOVE"
        case below = "BELOW"
        
        var iconName: String {
            switch self {
            case .above: return "arrow.increase"
            case .below: return "arrow.decrease"
            }
        }
        
        var color: Color {
            switch self {
            case .above: return .wmGreen
            case .below: return .wmRed
            }
        }
    }
    
    let id: String
    let symbol: String
    let targetPrice: Double
    let targetDirection: TargetDirection
}
