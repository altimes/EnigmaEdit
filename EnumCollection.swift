//
//  EnumCollection.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 5/11/17.
//  Copyright © 2017 Alan Franklin. All rights reserved.
//
// from https://theswiftdev.com/2017/10/12/swift-enum-all-values/

import Foundation

public protocol EnumCollection: Hashable {
  static func cases() -> AnySequence<Self>
  static var allValues :[Self] { get }
  static var allDescriptions:[String] { get }
}

public extension EnumCollection {
  static func cases() -> AnySequence<Self> {
    return AnySequence { () -> AnyIterator<Self> in
      var raw = 0
      return AnyIterator {
        let current: Self =  withUnsafePointer(to: &raw) { $0.withMemoryRebound(to:self, capacity:1) {$0.pointee} }
        guard current.hashValue == raw else  { return nil }
        raw += 1
        return current
      }
    }
  }
  
  static var allValues: [Self] {
    return Array(self.cases())
  }
  
  static var allDescriptions: [String] {
    return Array(self.allValues.map {String(describing:$0)})
  }

}
