//
//  Utility.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 28/1/20.
//  Copyright © 2020 Alan Franklin. All rights reserved.
//

import Foundation

// stolen with thanks from https://www.hackingwithswift.com/example-code/strings/how-to-remove-a-prefix-from-a-string
extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
  
  /// using NSString to remove the last path of a string URL
  /// - Returns: modified string
  func deletingLastPathComponent() -> String {
    let thisString = NSString(string: self)
    return thisString.deletingLastPathComponent
  }
}

extension UInt32 {
  var bigEndianEncodedData: Data {
    var value: UInt32 = self
    value = value.bigEndian
    return withUnsafeBytes(of: &value) { Data($0) }
  }
  
  init(bigEndianData data: Data) {
    guard data.count >= MemoryLayout<UInt32>.size else {
      fatalError("Wrong size for UInt32 - got \(data.count), expected \(MemoryLayout<UInt32>.size)")
    }
    var value: UInt32 = 0
    value = data.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) -> UInt32 in
      return rawBufferPointer.baseAddress!.assumingMemoryBound(to: UInt32.self).pointee
    }
    self = value.bigEndian
  }
}

extension UInt64 {
  var bigEndianEncodedData: Data {
    var value: UInt64 = self
    value = value.bigEndian
    return withUnsafeBytes(of: &value) { Data($0) }
  }
  
  init(bigEndianData data: Data) {
    guard data.count >= MemoryLayout<UInt32>.size else {
      fatalError("Wrong size for UInt64 - got \(data.count), expected \(MemoryLayout<UInt64>.size)")
    }
    var value: UInt64 = 0
    value = data.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) -> UInt64 in
      return rawBufferPointer.baseAddress!.assumingMemoryBound(to: UInt64.self).pointee
    }
    self = value.bigEndian
  }
}

extension String {
  /// Intened to triim the file:// url header from a string
  /// remove "file://" and return trimmed string
  func removeFileColonDoubleSlash() -> String {
    let target = /file:\/\//.ignoresCase()
    return self.replacing(target, with: "", maxReplacements: 1)
  }
}

