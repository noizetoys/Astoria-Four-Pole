//
//  UserDefaults PropWrapper.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/26/25.
//

import Foundation
import Combine


@propertyWrapper
struct GlobalSetting<T: UserDefaultsSerializable> {
    private let _userDefaults: UserDefaults
    private let _publisher: CurrentValueSubject<T, Never>
    private let _observer: ObserverTrampoline
    
    let key: String
    var wrappedValue: T {
        get { self._userDefaults.fetch(self.key) }
        set { self._userDefaults.save(newValue, for: self.key) }
    }
    
    
    var projectedValue: AnyPublisher<T, Never> {
        self._publisher.eraseToAnyPublisher()
    }
    
    
    init(wrappedValue: T, key keyName: String, userDefaults: UserDefaults = .standard) {
        self.key = keyName
        self._userDefaults = userDefaults
        
        userDefaults.register(defaults: [keyName: wrappedValue])
        
        let publisher = CurrentValueSubject<T, Never>(userDefaults.fetch(keyName))
        self._publisher = publisher
        
        self._observer = ObserverTrampoline(userDefaults: userDefaults, key: keyName) { publisher.send(userDefaults.fetch(keyName))
        }
    }
    
}


extension GlobalSetting: Equatable where T: Equatable {
    static func == (left: Self, right: Self) -> Bool {
        left.key == right.key && left.wrappedValue == right.wrappedValue
    }
}


extension GlobalSetting: Hashable where T: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.key)
        hasher.combine(self.wrappedValue)
    }
}



// MARK: - ObserverTrampoline

final class ObserverTrampoline: NSObject {
    private let userDefaults: UserDefaults
    private let key: String
    private let action: () -> Void
    
    init(userDefaults: UserDefaults, key: String, action: @escaping () -> Void) {
        assert(!key.hasPrefix("@"), "Error: key name cannot begin with '@' characeter and be observed via KVO.")
        
        assert(!key.contains("."), "Error: key name cannot contain '.' character and be observed via KVO")
        
        self.userDefaults = userDefaults
        self.key = key
        self.action = action
        
        super.init()
        
        userDefaults.addObserver(self, forKeyPath: key, context: nil)
    }
    
    
    deinit {
        self.userDefaults.removeObserver(self, forKeyPath: self.key, context: nil)
    }
    
    
    func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChange: Any?],
        context: UnsafeMutableRawPointer?) {
            self.action()
        }
    
}


// MARK: - UserDefault Extension

extension UserDefaults {
    func save<T: UserDefaultsSerializable>(_ value: T, for key: String) {
        if T.self == URL.self {
            self.set(value as? URL, forKey: key)
            return
        }
        
        self.set(value.storedValue, forKey: key)
    }
    
    
    func delete(for key: String) {
        self.removeObject(forKey: key)
    }
    
    
    func fetch<T: UserDefaultsSerializable>(_ key: String) -> T {
        self.fetchOptional(key)!
    }
    
    
    func fetchOptional<T: UserDefaultsSerializable>(_ key: String) -> T? {
        let fetched: Any?
        
        if T.self == URL.self {
            fetched = self.url(forKey: key)
        }
        else {
            fetched = self.object(forKey: key)
        }
        
        if fetched == nil {
            return nil
        }
        
        guard
            let storedValue = fetched as? T.StoredValue
        else {
            return nil
        }
        
        return T(storedValue: storedValue)
        
    }
    
}
