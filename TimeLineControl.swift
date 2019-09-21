//
//  TimeLineControl.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 6/7/17.
//  Copyright © 2017 Alan Franklin. All rights reserved.
//

import Cocoa

class TimeLineControl: NSControl
{
  
  var normalizedXPos: Double = 0.0
  var zoomCount:Int = 0
  var keyCatchDelegate : KeyStrokeCatch?
  
  var isZoomed: Bool {
    return currentZoomFactor != 1.0
  }
  
  private var debug = false
  
  private var lastMousePostion = CGFloat(0.0)
  private var oldBounds: NSRect? = nil
  private var cursorStackDepth = 1
  
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
  
  /// function to get current standard cursor name
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
  
  // Called when cursor "enters" a tracking area
  override func cursorUpdate(with event: NSEvent)
  {
    if (debug) { print("\(NSCursor.current.debugDescription)") }
    //    super.cursorUpdate(with: event)
    if (debug) { print ("saw call to "+#function+" current cursor is " + currentCursorName + " stackDepth= \(cursorStackDepth)" )}
    
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
      setCursorClosedHand()
      //      // handle unexpected calls via os
      //      if NSCursor.current == NSCursor.closedHand {
      //        // do nothing
      //        print("unexpected call to " + #function)
      //      }
      //      else {
      //        print("About to push closedHand cursor from " + #function + " stackDepth= \(cursorStackDepth)")
      //        NSCursor.closedHand.push()
      //        cursorStackDepth += 1
      //      }
    }
    else if (inControl && !mouseButtonIsDown)
    { // mouse button is up
      setCursorOpenHand()
      //      if NSCursor.current == NSCursor.openHand {
      //        // do nothing
      //      }
      //      else {
      //        print("About to push openHand cursor" + " stackDepth= \(cursorStackDepth)")
      //        NSCursor.openHand.push()
      //        cursorStackDepth += 1
      //      }
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
      setCursorClosedHand()
      NSApp.sendAction(self.action!, to: self.target, from: self)
    }
    mouseButtonIsDown = true
  }
  
  override func mouseUp(with event: NSEvent) {
    if (debug) { Swift.print("Saw "+#function) }
    if (inControl) {
      //      print("setting OpenHand")
      setCursorOpenHand()
    }
    else {
      //      print("setting Arrow")
      setCursorArrow()
    }
    if mousePostionProcessOK(from: event)
    {
      NSApp.sendAction(self.action!, to: self.target, from: self)
    }
    else {
      if (debug) { print("failed mousePositionProcessOK") }
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
    if (debug) {
      print("saw "+#function + " stackDepth= \(cursorStackDepth)")
      print("pressed Buttons = \(NSEvent.pressedMouseButtons)")
      print("button Number = \(event.buttonNumber)")
      print("Current cursor on exit is " + currentCursorName)
    }
    if (mouseButtonIsDown) {
      setCursorClosedHand()
    }
    else {
      setCursorArrow()
    }
    inControl = false
  }
  
  override func mouseDragged(with event: NSEvent) {
    if (debug) {
      Swift.print("Saw "+#function)
      print("Current cursor on entry is " + currentCursorName)
    }
    if mousePostionProcessOK(from: event)
    {
      // brute force, to deal with the fact that the player changes the cursor to an arrow when
      // the mouse moves off the control and onto the video window
      // so we force it back to being a closed hand
      setCursorClosedHand()
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
    self.needsDisplay = true
  }
  
  /// Change control bounds back to original full range
  func zoomOut()
  {
    if let bounds = oldBounds {
      self.bounds = bounds
      currentZoomFactor = 1.0
      self.scaleUnitSquare(to: NSSize(width: currentZoomFactor, height: 1.0))
      self.needsDisplay = true
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
      // FIXME: somehow getting called on detached thread
      self.bounds.origin.x = self.bounds.origin.x + originAdjustment
    }
  }
  
  // Cursor state fuctions,  can be one of arrow, closed, open by push and
  // pop.  State machine is Arrow->OpenHand-> ClosedHand -> OpenHand
  //                                                     -> Arrow
  //                                       -> Arrow
  func setCursorOpenHand() {
    if (debug) { print(#function + " stack depth =\(cursorStackDepth)") }
    if NSCursor.current == NSCursor.arrow {
      NSCursor.openHand.push()
      cursorStackDepth += 1
    }
    if (NSCursor.current == NSCursor.closedHand) {
      NSCursor.pop()
      cursorStackDepth -= 1
    }
  }
  
  func setCursorClosedHand() {
    if (debug) {
      print(#function + " stack depth =\(cursorStackDepth)")
      print("Current cursor on entry is " + currentCursorName)
    }
    if (NSCursor.current == NSCursor.arrow)
    {
      if (cursorStackDepth >= 2) {
        NSCursor.pop()
      }
      else {
        NSCursor.openHand.push()
        NSCursor.closedHand.push()
        cursorStackDepth += 2
      }
    }
    if NSCursor.current == NSCursor.openHand {
      NSCursor.closedHand.push()
      cursorStackDepth += 1
    }
  }
  
  func setCursorArrow() {
    if (debug) { print(#function + " stack depth =\(cursorStackDepth)") }
    while NSCursor.current != NSCursor.arrow {
      NSCursor.pop()
      if (debug) { print("poping cursors....") }
      cursorStackDepth -= 1
    }
  }
}
