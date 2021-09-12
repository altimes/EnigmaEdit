//
//  Cache.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 31/3/20.
//  Copyright © 2020 Alan Franklin. All rights reserved.
//


import Foundation

// based on cache demo code in swiftbysundell.com
final class Cache<Key: Hashable, Value> {
  private let wrapped = NSCache<WrappedKey, Entry>()
  private var keyTable = [WrappedKey]()
  private var debug = false
  
  func insert(_ value: Value, forKey key: Key) {
    let entry = Entry(value: value)
    let thisKey = WrappedKey(key)
    wrapped.setObject(entry, forKey: WrappedKey(key))
    keyTable.append(thisKey)
  }
  
  func update(_ value: Value, forKey key: Key) {
    removeValue(forKey: key)
    insert(value, forKey: key)
  }
  
  func value(forKey key: Key) -> Value? {
    let entry = wrapped.object(forKey: WrappedKey(key))
    return entry?.value
  }
  
  // FIXME: will crash when cache is being populated....
  // eg foolishly run markNCut whilst background process is setting up
  // colouring AND populating cache
  func removeValue(forKey key: Key)
  {
    if (debug) { print(#function+" Cache removing key: \(key)")}
    let thisKey = WrappedKey(key)
    wrapped.removeObject(forKey: WrappedKey(key))
    keyTable.removeAll(where: {$0 == thisKey})
  }
  
  func removeAll() {
    wrapped.removeAllObjects()
    keyTable.removeAll()
  }
  
  var countLimit : Int
  {
    get { return wrapped.countLimit }
  }
  
  var keys: [Key] {
    get {
      var keys = [Key]()
      for keyItem in keyTable {
        keys.append(keyItem.key)
      }
      return keys
    }
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
