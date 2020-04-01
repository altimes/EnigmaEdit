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
    
  func deletingLastPathComponent() -> String {
    let thisString = NSString(string: self)
    return thisString.deletingLastPathComponent
  }
}
