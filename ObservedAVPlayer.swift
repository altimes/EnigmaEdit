//
//  ObservedAVPlayer.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 29/8/17.
//  Copyright © 2017 Alan Franklin. All rights reserved.
//

import Cocoa
import AVFoundation

class ObservedAVPlayer: AVPlayer {

  public var playCommandFromUser: Bool = false
  public var fullScreenTransition: Bool = false
  
  override var rate: Float {
    get {
      return super.rate
    }
    set {
      if playCommandFromUser || !fullScreenTransition {
       super.rate = newValue
      }
      else {
        super.rate = 0.0
      }
    }
  }
  
  override func play() {
    super.play()
  }
}
