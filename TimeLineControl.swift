//
//  TimeLineControl.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 6/7/17.
//  Copyright © 2017 Alan Franklin. All rights reserved.
//

import Cocoa

class TimeLineControl: NSControl {
  
  var normalizedXPos: Double = 0.0
  var zoomCount:Int = 0
  var keyCatchDelegate : KeyStrokeCatch?
  
  var isZoomed: Bool {
    return currentZoomFactor != 1.0
  }
  
  private var debug = false
  
  private var lastMousePostion = CGFloat(0.0)
  private var oldBounds: NSRect? = nil
  
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    
    // Drawing code here.
  }
  
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    self.action = nil
    self.target = nil
    
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    self.action = nil
    self.target = nil
  }
  
  override var acceptsFirstResponder: Bool
  {
    return true
  }
  
  /// Common code for handling the new mouse postion
  func mousePostionProcessOK(from event:NSEvent) -> Bool
  {
    let mouseScreenPosition = event.locationInWindow
    let mouseViewPosition = self.convert(mouseScreenPosition, from: nil)
    let oldNormalizedPosition = normalizedXPos
    
    let modifier = event.modifierFlags
    if (modifier.contains( NSEvent.ModifierFlags.option))
    {
      //      use scaled adjustment to generate small, frame grade, movement
      //      let mouseDelta = lastMousePostion - mouseViewPosition.x
      //      let deltaMove = Double(mouseDelta) * 0.1
      //      normalizedXPos = (Double(lastMousePostion) + deltaMove)/Double(self.bounds.width)
      //      lastMousePostion = mouseViewPosition.x
      //      Swift.print("click count = \(zoomCount)")
      switch event.type
      {
      case .leftMouseDown:
        zoomCount += 1
        if (zoomCount % 2 == 1)
        { zoomIn() }
        else
        { zoomOut() }
      default: break
        // do nothing
      }
    }
    else {
      let unZoomedWidth = CGFloat(oldBounds != nil ? (oldBounds!.width) : bounds.width )
      normalizedXPos = Double((mouseViewPosition.x)/unZoomedWidth)
    }
    
    // ensure 0.0 .. 1.0 boundaries are hounoured
    normalizedXPos = min(normalizedXPos, 1.0)
    normalizedXPos = max(0.0, normalizedXPos)
    if (debug) {
    Swift.print("Screen pos = \(mouseScreenPosition)")
    Swift.print("View   pos = \(mouseViewPosition)")
    Swift.print("norm'd pos = \(normalizedXPos)")
    }
    return oldNormalizedPosition != normalizedXPos
  }
  
  override func mouseDown(with event: NSEvent) {
    if (debug) {Swift.print("Saw "+#function) }
    if mousePostionProcessOK(from: event)
    {
      NSApp.sendAction(self.action!, to: self.target, from: self)
    }
  }
  
  override func mouseUp(with event: NSEvent) {
    if (debug) { Swift.print("Saw "+#function) }
    if mousePostionProcessOK(from: event)
    {
      NSApp.sendAction(self.action!, to: self.target, from: self)
    }
  }
  
  override func mouseDragged(with event: NSEvent) {
    if (debug) {Swift.print("Saw "+#function) }
    if mousePostionProcessOK(from: event)
    {
      NSApp.sendAction(self.action!, to: self.target, from: self)
    }
  }
  
  var zoomFactor = 0.1   // percentage of current width
  var currentZoomFactor = 1.0
  let zoomDuration = 5.0 // seconds == 125 frames; centre + 62 either side
  
  func zoomIn()
  {
    // save basic bounds
    oldBounds = self.bounds
//    var newBounds = self.bounds
    let fullWidth = Double(self.bounds.width)
    let newSpan = zoomFactor * fullWidth
    let newXCentre = normalizedXPos * fullWidth
//    Swift.print("zoomed bounds after origin change -> \(newBounds)")
    currentZoomFactor = zoomFactor
    self.scaleUnitSquare(to: NSSize(width: 1.0/currentZoomFactor, height: 1.0))
    // now we need to adjust the origin such that:
    // - origin min and max limits are honours (ie no under or over run)
    // - the current frame marker is under the mouse click position
    var lhXOriginPos = newXCentre - newSpan/2.0
    lhXOriginPos = max(lhXOriginPos, 0.0)
    if lhXOriginPos + newSpan > fullWidth {
      // shift origin left to ensure upper limit is in bounds
      let leftShift = lhXOriginPos + newSpan - fullWidth
      lhXOriginPos -= leftShift
    }
    self.bounds.origin.x = CGFloat(lhXOriginPos)
//    Swift.print("zoomed bounds after unit square change -> \(self.bounds)")
    self.setNeedsDisplay()
  }
  
  /// Change control bounds back to original full range
  func zoomOut()
  {
    if let bounds = oldBounds {
      self.bounds = bounds
      currentZoomFactor = 1.0
      self.scaleUnitSquare(to: NSSize(width: currentZoomFactor, height: 1.0))
      self.setNeedsDisplay()
      oldBounds = nil
    }
  }
  
  override func keyUp(with event: NSEvent)
  {
    switch event.keyCode
    {
    case leftArrowKey:
      self.keyCatchDelegate?.didPressLeftArrow()
    case rightArrowKey:
      self.keyCatchDelegate?.didPressRightArrow()
    default:
      super.keyUp(with: event)
    }
  }
  
  /// change view bounds in response to superview changes
  func moveBounds(normalizeStep: Double)
  {
    if let originalWidth = oldBounds?.width
    {
      let originAdjustment = CGFloat(normalizeStep) * originalWidth
      if (debug) { Swift.print("moving bounds by \(originAdjustment)") }
      self.bounds.origin.x = self.bounds.origin.x + originAdjustment
    }
  }
  
}
