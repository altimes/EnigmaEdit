//
//  AdHunterVCExtn.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 11/1/17.
//  Copyright © 2017 Alan Franklin. All rights reserved.
//

import Cocoa
import Foundation

// adapted from https://stackoverflow.com/questions/33768066/get-pixel-data-as-array-from-uiimage-cgimage-in-swift
// with thanks
extension CGImage {
  // technique to extract byte level info into a data array using the context "draw" function
  // this "draws" into the allocated array rather than a display device context.
  // note this is used as is and does not check that CGImage for colour range, bytes etc.
  // (was adapted from UIImage where that may be fixed and predictable)
  // but for my debugging, I don't really care
  func pixelData() -> [UInt8]? {
    let size = CGSize(width: self.width, height: self.height)
    let dataSize = size.width * size.height * 4
    var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(data: &pixelData,
                            width: Int(size.width),
                            height: Int(size.height),
                            bitsPerComponent: 8,
                            bytesPerRow: 4 * Int(size.width),
                            space: colorSpace,
                            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
    context?.draw(self, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    return pixelData
  }
}

extension ViewController
{
  
  /// programatic boundaryHunt completed - remove hunter and reset butttons
  func boundaryHuntReset()
  {
    boundaryAdHunter?.done()
    huntButtonsReset()
  }
  
  /// Reset buttons and remove hunter
  func huntButtonsReset() {
    forwardHuntButton.layer?.backgroundColor = view.layer?.backgroundColor
    backwardHuntButton.layer?.backgroundColor = view.layer?.backgroundColor
    boundaryAdHunter = nil
    lastHuntButton = nil
  }
  
  /// Sets the colour surrounding the advert hunting buttons according to
  /// how close the step is to the defined minima threshold
  
  func setHunterBackgroundColourByStep(_ button: NSButton, step: Double?)
  {
    guard (step != nil) else { return }
    if abs(step!) < BoundaryHunter.nearEnough {
      button.layer?.backgroundColor = NSColor.green.cgColor
    }
    else {
      button.layer?.backgroundColor = view.layer?.backgroundColor
    }
    if forwardHuntButton.layer?.backgroundColor == NSColor.green.cgColor &&
      backwardHuntButton.layer?.backgroundColor == NSColor.green.cgColor {
      addMatchingCutMark(toMark: prevCut)
    }
  }
  
  /// Enable, disable the advertisement hunting buttons.
  /// Should reflect state of there being an active loaded media item
  func enableAdHuntingButtons(_ state:Bool) {
    forwardHuntButton.isEnabled = state
    backwardHuntButton.isEnabled = state
    resetHuntButton.isEnabled = state
    doneHuntButton.isEnabled = state
  }
  
  /// Function to wrap the code for doing a jump into a common function
  /// - parameter button:  initiating Button
  /// - parameter direction: direction to skip
  func doBinaryJump(button: NSButton, direction: huntDirection) {
    var jumpResult: String?
    
    if boundaryAdHunter == nil {
      var step: Double
      step = (direction == .forward) ? initialStep : -initialStep
      boundaryAdHunter = BoundaryHunter(firstJump: step, firstButton: button, player: self.monitorView.player!, seekCompletionFlag: &seekCompleted, completionHander: seekCompletedOK, seekHandler: self.seekHandler)
      // inject prefs
      boundaryAdHunter?.setFromPreferences(prefs: self.adHunterPrefs)
      lastHuntButton = nil
    }
    lastHuntButton = button
    switch direction
    {
    case .forward:
      jumpResult = boundaryAdHunter?.jumpForward(using: button)
    case .backward:
      jumpResult = boundaryAdHunter?.jumpBackward(using: button)
    default:
      jumpResult = "Unexpectedly found direction " + direction.description
    }
    let message = jumpResult ?? "jump failed"
    if var gap = boundaryAdHunter?.jumpDistance {
      gap = fabs(gap)
      if gap < BoundaryHunter.reportGapValue {
        var messageString = String(format:"%.2f",gap)
        let firstpoint = messageString.index(of: ".")
//        messageString = messageString.substring(from: firstpoint!)
        messageString = String(messageString[firstpoint!...])
        if BoundaryHunter.voiceReporting { voice.startSpeaking(messageString ) }
        if BoundaryHunter.visualReporting { updateVideoOverlay(updateText: message) }
      }
    }
    setStatusFieldStringValue(isLoggable: false, message: message)
    setHunterBackgroundColourByStep(button, step: boundaryAdHunter?.jumpDistance)
  }
  

}
