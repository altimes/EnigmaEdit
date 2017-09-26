//
//  metaDataObject.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 7/3/17.
//  Copyright © 2017 Alan Franklin. All rights reserved.
//

//  Wrapper class to provide capacity to use cocoa bindings for structure updates

import Cocoa

class metaDataObject: NSObject {
  
  var debug = false
  /// base structure of information
  
  var meta: MetaData {
    didSet {
      if (debug) { print("metaObject Changed") }
    }
  }
  
  // popup support eugh
  let popupStrings = ["True", "False"]
//  let popupArray: NSArrayController = []
  
  // TODO: limit to 0 or 1 entry
  var scrambled: String = "" {
    didSet {
      if (debug) { print("meta object scrambled was set") }
      self.meta.scrambled = scrambled
    }
  }
  var scrambledCheckBox: Int = NSControl.StateValue.off.rawValue {
    didSet {
      if (debug) { print("Saw change to check box field") }
      self.meta.scrambled = (scrambledCheckBox == NSControl.StateValue.off.rawValue) ? "0" : "1"
    }
  }
  var scrambledPopup: Int {
    didSet {
      if (debug) { print("Saw popup change") }
      self.meta.scrambled = (scrambledCheckBox == NSControl.StateValue.off.rawValue) ? "0" : "1"
    }
  }
  
  init(_ meta:MetaData)
  {
    self.meta = meta
    scrambled = self.meta.scrambled
    scrambledPopup = self.meta.scrambled == "0" ? 0 : 1
  }
  
  func update(with newMeta: MetaData)
  {
    self.meta = newMeta
  }
  
  deinit {
    if (debug) { print("who is calling me ") }
  }
}
