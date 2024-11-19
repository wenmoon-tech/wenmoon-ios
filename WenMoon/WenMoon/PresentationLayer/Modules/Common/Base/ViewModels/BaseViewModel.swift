//
//  BaseViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 20.06.23.
//

import Foundation
import SwiftData

class BaseViewModel: ObservableObject {
    // MARK: - Properties
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private(set) var swiftDataManager: SwiftDataManager?
    private(set) var userDefaultsManager: UserDefaultsManager?
    
    var deviceToken: String? {
        guard isUserDefaultsManagerAvailable() else { return nil }
        let deviceToken = try? userDefaultsManager!.getObject(forKey: "deviceToken", objectType: String.self)
        return deviceToken
    }
    
    var isFirstLaunch: Bool {
        guard isUserDefaultsManagerAvailable() else { return false }
        do {
            let isFirstLaunch = try userDefaultsManager!.getObject(forKey: "isFirstLaunch", objectType: Bool.self) ?? true
            if isFirstLaunch {
                try userDefaultsManager!.setObject(false, forKey: "isFirstLaunch")
            }
            return isFirstLaunch
        } catch {
            errorMessage = error.localizedDescription
        }
        return false
    }
    
    // MARK: - Initializers
    init(swiftDataManager: SwiftDataManager? = nil, userDefaultsManager: UserDefaultsManager? = nil) {
        self.swiftDataManager = swiftDataManager
        self.userDefaultsManager = userDefaultsManager
    }
    
    // MARK: - Methods
    func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) -> [T] {
        guard isSwiftDataManagerAvailable() else { return [] }
        do {
            let models = try swiftDataManager!.fetch(descriptor)
            return models
        } catch {
            setErrorMessage(error)
            return []
        }
    }
    
    func insert<T: PersistentModel>(_ model: T) {
        guard isSwiftDataManagerAvailable() else { return }
        do {
            try swiftDataManager!.insert(model)
        } catch {
            setErrorMessage(error)
        }
    }
    
    func delete<T: PersistentModel>(_ model: T) {
        guard isSwiftDataManagerAvailable() else { return }
        do {
            try swiftDataManager!.delete(model)
        } catch {
            setErrorMessage(error)
        }
    }
    
    func save() {
        guard isSwiftDataManagerAvailable() else { return }
        do {
            try swiftDataManager!.save()
        } catch {
            setErrorMessage(error)
        }
    }
    
    @MainActor
    func loadImage(from url: URL) async -> Data? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            errorMessage = "Error downloading image: \(error.localizedDescription)"
            return nil
        }
    }

    func setErrorMessage(_ error: Error) {
        if let descriptiveError = error as? DescriptiveError {
            errorMessage = descriptiveError.errorDescription
        } else {
            errorMessage = "An unknown error occurred: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private
    private func isUserDefaultsManagerAvailable() -> Bool {
        guard userDefaultsManager != nil else {
            print("UserDefaultsManager is not initialized")
            return false
        }
        return true
    }
    
    private func isSwiftDataManagerAvailable() -> Bool {
        guard swiftDataManager != nil else {
            print("SwiftDataManager is not initialized")
            return false
        }
        return true
    }
}
