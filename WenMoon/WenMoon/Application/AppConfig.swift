//
//  Configuration.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 18.11.24.
//

import Foundation

enum AppConfig {
    enum Error: Swift.Error {
        case missingKey, invalidValue
    }
    
    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
            throw Error.missingKey
        }
        
        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else { fallthrough }
            return value
        default:
            throw Error.invalidValue
        }
    }
}

enum API {
    static var baseURL: URL {
        try! URL(string: "http://" + AppConfig.value(for: "BASE_URL"))!
    }
    
    static var key: String {
        try! AppConfig.value(for: "API_KEY")
    }
}

enum Constants {
    static let appVersion: String = try! AppConfig.value(for: "APP_VERSION")
    static let buildNumber: String = try! AppConfig.value(for: "BUILD_NUMBER")
}
