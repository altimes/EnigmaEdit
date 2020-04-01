//
//  Cache.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 31/3/20.
//  Copyright © 2020 Alan Franklin. All rights reserved.
//

import Foundation

// from swiftbysundell.com
final class Cache<Key: Hashable, Value> {
  private let wrapped = NSCache<WrappedKey, Entry>()
  
  func insert(_ value: Value, forKey key: Key) {
    let entry = Entry(value: value)
    wrapped.setObject(entry, forKey: WrappedKey(key))
  }
  
  func value(forKey key: Key) -> Value? {
    let entry = wrapped.object(forKey: WrappedKey(key))
    return entry?.value
  }
  
  func removeValue(forKey key: Key)
  {
    wrapped.removeObject(forKey: WrappedKey(key))
  }
  
  var countLimit : Int
  {
    get { return wrapped.countLimit }
  }
}

private extension Cache {
  final class WrappedKey: NSObject {
    let key: Key
    init(_ key: Key) {
      self.key = key
    }
    
    override var hash: Int { return key.hashValue }
    
    override func isEqual(_ object: Any?) -> Bool {
      guard let value = object as? WrappedKey else {
        return false
      }
      return value.key == key
    }
  }
}

private extension Cache {
  final class Entry {
    let value: Value
    init(value: Value) {
      self.value = value
    }
  }
}
