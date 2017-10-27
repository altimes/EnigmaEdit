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
    self.setup()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    self.setup()
  }
  
  private func setup()
  {
    self.action = nil
    self.target = nil
    let trackingArea = NSTrackingArea(rect: self.bounds, options: [.mouseEnteredAndExited,.activeAlways,.cursorUpdate], owner: self, userInfo: nil)
    self.addTrackingArea(trackingArea)
    if (debug) { print("tracking area setup complete")}
  }
  
  override var acceptsFirstResponder: Bool
  {
    return true
  }
  
  var currentCursorName: String
  {
    return cursorName(cursor: NSCursor.current)
  }
  
  func cursorName(cursor: NSCursor) -> String {
    var cursorLookup = [NSCursor:String]()
    cursorLookup = [.arrow:"arrow",
                 .openHand:"openHand",
                 .closedHand:"closedHand",
                 .contextualMenu:"contextualMenu",
                 .crosshair:"crosshair",
                 .disappearingItem:"disappearingItem",
                 .dragCopy:"dragCopy",
                 .dragLink:"dragLink",
                 .iBeam:"iBeam",
                 .iBeamCursorForVerticalLayout:"iBeamCursorForVerticalLayout",
                 .operationNotAllowed:"operationNotAllowed",
                 .resizeUp:"resizeUp",
                 .resizeDown:"resizeDown",
                 .resizeLeft:"resizeLeft",
                 .resizeRight:"resizeRight",
                 .resizeLeftRight:"resizeLeftRight",
                 .pointingHand:"pointingHand",
                 .resizeUpDown:"resizeUpDown"]
    return cursorLookup[cursor] ?? "unknown"
  }
  
  override func cursorUpdate(with event: NSEvent)
  {
    if (debug) { print("\(NSCursor.current.debugDescription)") }
    super.cursorUpdate(with: event)
    if (debug) { print ("saw call to "+#function+" current cursor is " + currentCursorName) }
    
    if let trackingArea = event.trackingArea
    {
      let rect = trackingArea.rect
      if (debug) { print("was really a tracking area ? \(rect)")}
    }
    else {
      if (debug) { print("no tracking area - transition or setup ?")}
    }
    if (debug) {
      print ("tracking number = \(event.trackingNumber)")
      print ("tracking event no. =  \(event.eventNumber)")
    }
    if (inControl && mouseButtonIsDown) {
      // handle unexpected calls via os
      if NSCursor.current == NSCursor.closedHand {
        // do nothing
        print("unexpected call to " + #function)
      }
      else {
        NSCursor.closedHand.push()
      }
    }
    else if (inControl && !mouseButtonIsDown)
    { // mouse button is up
      if NSCursor.current == NSCursor.openHand {
        // do nothing
      }
      else {
        NSCursor.openHand.push()
      }
    }
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
          if (zoomCount % 2 == 1) { zoomIn() }
          else { zoomOut() }
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
      NSCursor.closedHand.push()
      NSApp.sendAction(self.action!, to: self.target, from: self)
    }
    mouseButtonIsDown = true
  }
  
  override func mouseUp(with event: NSEvent) {
    if (debug) { Swift.print("Saw "+#function) }
    if mousePostionProcessOK(from: event)
    {
      NSCursor.pop()
      NSApp.sendAction(self.action!, to: self.target, from: self)
    }
    mouseButtonIsDown = false
  }
  
  var inControl = false
  var mouseButtonIsDown = false
  
  override func mouseEntered(with event: NSEvent) {
    if (debug) { print("saw "+#function)}
    inControl = true
  }
  
  override func mouseExited(with event: NSEvent) {
    if (debug) { print("saw "+#function)}
    inControl = false
  }
  
  override func mouseDragged(with event: NSEvent) {
    if (debug) {Swift.print("Saw "+#function) }
    if mousePostionProcessOK(from: event)
    {
      NSApp.sendAction(self.action!, to: self.target, from: self)
    }
  }
  
  override func rightMouseDown(with event: NSEvent) {
    if (debug) {print("saw " + #function)}
    mouseButtonIsDown = true
  }
  
  override func rightMouseUp(with event: NSEvent) {
    if (debug) {print("saw " + #function)}
    mouseButtonIsDown = false
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
