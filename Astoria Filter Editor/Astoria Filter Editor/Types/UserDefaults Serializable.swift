//
//  UserDefaults Serializable.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/26/25.
//

import Foundation


protocol UserDefaultsSerializable {
    associatedtype StoredValue
    
    var storedValue: StoredValue { get }
    init?(storedValue: StoredValue)
}


// MARK: - Types

extension Bool: UserDefaultsSerializable {
    var storedValue: Self { self }
    init(storedValue: Self) {
        self = storedValue
    }
}


extension Int: UserDefaultsSerializable {
    var storedValue: Self { self }
    init(storedValue: Self) {
        self = storedValue
    }
}


extension UInt8: UserDefaultsSerializable {
    var storedValue: Self { self }
    init(storedValue: Self) {
        self = storedValue
    }
}


extension Float: UserDefaultsSerializable {
    var storedValue: Self { self }
    init(storedValue: Self) {
        self = storedValue
    }
}


extension Double: UserDefaultsSerializable {
    var storedValue: Self { self }
    init(storedValue: Self) {
        self = storedValue
    }
}


extension String: UserDefaultsSerializable {
    var storedValue: Self { self }
    init(storedValue: Self) {
        self = storedValue
    }
}


extension Date: UserDefaultsSerializable {
    var storedValue: Self { self }
    init(storedValue: Self) {
        self = storedValue
    }
}


extension URL: UserDefaultsSerializable {
    var storedValue: Self { self }
    init(storedValue: Self) {
        self = storedValue
    }
}


// MARK: - Collections

extension Array: UserDefaultsSerializable where Element: UserDefaultsSerializable {
    var storedValue: [Element.StoredValue] {
        self.compactMap(\.storedValue)
    }
    
    init(storedValue: [Element.StoredValue]) {
        self = storedValue.compactMap { Element(storedValue: $0)}
    }
}


extension Set: UserDefaultsSerializable where Element: UserDefaultsSerializable {
    var storedValue: [Element.StoredValue] {
        self.map(\.storedValue)
    }
    
    
    init(storedValue: [Element.StoredValue]) {
        self = Set(storedValue.compactMap { Element(storedValue: $0) })
    }
}


extension Dictionary: UserDefaultsSerializable where Key == String, Value: UserDefaultsSerializable {
    var storedValue: [String: Value.StoredValue] {
        self.compactMapValues { $0.storedValue }
    }
    
    
    init(storedValue: [String: Value.StoredValue]) {
        self = storedValue.compactMapValues { Value(storedValue: $0)}
    }
}


// MARK: - Enums

extension UserDefaultsSerializable where Self: RawRepresentable, Self.RawValue: UserDefaultsSerializable {
    var storedValue: RawValue.StoredValue {
        self.rawValue.storedValue
    }
    
    
    init?(storedValue: RawValue.StoredValue) {
        guard
            let rawValue = Self.RawValue(storedValue: storedValue),
            let value = Self(rawValue: rawValue)
        else {
            assertionFailure("RawRepresentable Error:  bad stored Value: \(storedValue)")
            return nil
        }
        
        self = value
    }
}


// MARK: - Codable

extension UserDefaultsSerializable where Self: Codable {
    var storedValue: Data? {
        do {
            return try JSONEncoder().encode(self)
        }
        catch {
            assertionFailure("Encoding Error:  \(error)")
            return nil
        }
    }
    
    
    init?(storedValue: Data?) {
        do {
            self = try JSONDecoder().decode(Self.self, from: storedValue ?? Data())
        }
        catch {
            assertionFailure("Decoding Error:  \(error)")
            return nil
        }
    }
    
}
