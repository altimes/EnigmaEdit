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

  public var playCommandFromUser: PlayerCommand = .pause
  public var playingState: Bool = false
  public var fullScreenTransition: Bool = false
  
  override var rate: Float {
    get {
      return super.rate
    }
    set {
       print("Saw a rate change to \(newValue)")
     playingState = (newValue != 0.0)
     if (!fullScreenTransition) {
        super.rate = newValue
      }
      else {
        switch playCommandFromUser {
        case .play:
          super.rate = newValue
        case .pause:
          break
          // do nothing
        }
      }
    }
  }
  
  override func play() {
    super.play()
  }
}
