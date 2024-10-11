//
//  UserDefaultsManager.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 23.05.23.
//

import Foundation

protocol UserDefaultsManager {
    func setObject<T: Encodable>(_ object: T, forKey key: String) throws
    func getObject<T: Decodable>(forKey key: String, objectType: T.Type) throws -> T?
    func removeObject(forKey key: String)
}

final class UserDefaultsManagerImpl: UserDefaultsManager {

    private let userDefaults = UserDefaults.standard

    func setObject<T: Encodable>(_ object: T, forKey key: String) throws {
        do {
            let data = try JSONEncoder().encode(object)
            userDefaults.set(data, forKey: key)
        } catch {
            throw UserDefaultsError.failedToEncodeObject(error: error)
        }
    }

    func getObject<T: Decodable>(forKey key: String, objectType: T.Type) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }

        do {
            let object = try JSONDecoder().decode(objectType, from: data)
            return object
        } catch {
            throw UserDefaultsError.failedToDecodeObject(error: error)
        }
    }

    func removeObject(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
}