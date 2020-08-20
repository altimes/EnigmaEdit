//
//  TimelineView.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 30/4/17.
//  Copyright © 2017 Alan Franklin. All rights reserved.
//
//  Class to support display of bookmarks overlayed on video as timeline
//
extension NSView {
  
  var bookMarkBackgroundColor: NSColor? {
    
    get {
      if let colorRef = self.layer?.backgroundColor {
        return NSColor(cgColor: colorRef)
      } else {
        return nil
      }
    }
    
    set {
      self.wantsLayer = true
      self.layer?.backgroundColor = newValue?.cgColor
    }
  }
}

import Cocoa

// TODO: listen for changes in cuts file
// TODO: listen for changes in parent frame settings

class TimeLineView: TimeLineControl {
  
  var numberOfBookmarks = 3
  var bookMarkPositions : [Double] = [0.0,0.5,1.0]
  var inPositions =  [Double]()
  var outPositions = [Double]()
  var cutBoxPositions = [Double]()
  var gapPositions = [Double]()
  var pcrPositions = [Double]()
  var bookMarkColour  = NSColor.yellow
  var inMarkColour = NSColor.green
  var outMarkColour = NSColor.red
  var cutoutColour =  NSColor.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.3)
  var currentPositionColour = NSColor.init(red: 75.0, green:0.75, blue:0.75, alpha: 0.8)
  var gapPositionColour = NSColor.cyan.withAlphaComponent(0.75)
  var pcrPositionColour = NSColor.yellow.withAlphaComponent(0.75)
  var markWidth = CGFloat(3.0)
  var currentPosition = [Double]()
  {
    didSet {
      // needs a dispatch_main.async for this
      DispatchQueue.main.async { [weak weakSelf = self ]  in
        weakSelf?.needsDisplay = true
      }
    }
  }
  var timeRangeSeconds: Double = 0.0
  let fontSize:CGFloat = 10
  let backgroundTextColour = NSColor(calibratedWhite: 0.5, alpha: 0.75)
  let textFontName = "Helvetica-Bold"
  var unZoomedBoundsWidth: CGFloat = 0.0
  
  var debug = false
  
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
        
    // Drawing code here.
    let context = NSGraphicsContext.current?.cgContext
    drawGapsPosition(inContext: context)
    drawPCRPosition(inContext: context)
    drawInOutMarks(inContext: context)
    drawBookMarks(inContext: context)
    drawCurrentPosition(inContext: context)
    self.normalizedXPos = currentPosition[0]
//          Swift.print("Called draw for Timeline")
  }
  
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    self.itemPropertiesToDefault()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    self.itemPropertiesToDefault()
  }
  
  convenience init(frame frameRect:NSRect, seconds: Double)
  {
    self.init(frame: frameRect)
    if (debug) { Swift.print("Initial bounds = \(self.bounds)") }
    self.timeRangeSeconds = seconds
    self.scaleUnitSquare(to: NSSize(width: 1.0, height: 1.0))
    self.unZoomedBoundsWidth = self.bounds.width
  }
  
  func itemPropertiesToDefault()
  {
    bookMarkPositions = []
    outPositions = []
    inPositions = []
    currentPosition = [0.0]
    self.bookMarkBackgroundColor = NSColor.blue
    self.scaleUnitSquare(to: NSSize(width: 1.0, height: 1.0))
    self.unZoomedBoundsWidth = self.bounds.width
  }
  
  /// Create an attributed string for the time determined by the relative position
  /// on the timeline.  Remove leading zeros
  func attributedStringFromPosition(_ position: Double, atZoomFactor zoomFactor:Double) -> NSMutableAttributedString
  {
    let timeStamp = position * self.timeRangeSeconds
    let timeText = NSMutableString(string: CutEntry.hhMMssFromSeconds(timeStamp))
    var fullRange = NSRange(location:0,length:timeText.length)
    let leadingZeroRegex = try! NSRegularExpression(pattern: "^0*", options: [])
    leadingZeroRegex.replaceMatches(in: timeText, options: [], range: fullRange, withTemplate: "")
    fullRange = NSRange(location:0,length:timeText.length)
    let resultString = timeText.substring(to: timeText.length)
    
    // create font that also looks correct if bounds are asymmetric (ie when zoomed in for fine control)
    // Postscript six-element matrix
    let widthFactor = fontSize * CGFloat(zoomFactor)
    let heightFactor = fontSize
    let zeroFactor = CGFloat(0.0)
    let fontMatrix = [widthFactor, zeroFactor, zeroFactor, heightFactor, zeroFactor, zeroFactor]
    let labelText = NSMutableAttributedString(string: resultString, attributes: [NSAttributedString.Key.font:NSFont(name: textFontName, matrix: fontMatrix)!])
    fullRange = NSRange(location:0,length:labelText.length)
    
    labelText.addAttributes([NSAttributedString.Key.backgroundColor:backgroundTextColour], range: fullRange)
    labelText.addAttributes([NSAttributedString.Key.foregroundColor:NSColor.white], range: fullRange)
    return labelText
  }
  
    func drawInOutMarks(inContext context: CGContext?)
  {
    guard (cutBoxPositions.count != 0) else { return }
    if cutBoxPositions.count % 2 != 0 {
      cutBoxPositions.append(1.0)
    }
    //    Swift.print("\(cutBoxPositions)")
    var index = 0
    while ( index+1 < cutBoxPositions.count) {
      drawCutBox(normalizedStart: cutBoxPositions[index], normalizedEnd: cutBoxPositions[index+1], inContext: context)
      index += 2
    }
    drawMarks(normalizedMarks: inPositions, withColour: inMarkColour.cgColor, inContext: context, isDashed: false)
    drawMarks(normalizedMarks: outPositions, withColour: outMarkColour.cgColor, inContext: context, isDashed: false)
  }
  
  func drawBookMarks(inContext context: CGContext?)
  {
    drawMarksReducedHeight(byPerecentage: 0.6, normalizedMarks: bookMarkPositions, withColour: bookMarkColour.cgColor, with: .round, isDashed: false, inContext: context)
    drawTimes(normalizedMarks: bookMarkPositions, withColour: NSColor.white.cgColor, inContext: context)
  }
  
  func drawCurrentPosition(inContext context: CGContext?)
  {
    drawMarks(normalizedMarks: currentPosition, withColour: currentPositionColour.cgColor, inContext: context, isDashed: false)
  }
  
  func drawGapsPosition(inContext context: CGContext?)
  {
    drawMarks(normalizedMarks: gapPositions, withColour: gapPositionColour.cgColor, inContext: context, isDashed: false)
  }
  
  func drawPCRPosition(inContext context: CGContext?)
  {
    drawMarksReducedHeight(byPerecentage: 0.0, normalizedMarks: pcrPositions, withColour: pcrPositionColour.cgColor, with: .butt, isDashed: true, inContext: context)
  }
  
  func drawMarksReducedHeight(byPerecentage: Double, normalizedMarks: [Double], withColour markColor: CGColor, with capStyle: NSBezierPath.LineCapStyle, isDashed: Bool, inContext context: CGContext?)
  {
    guard normalizedMarks.count > 0 else { return }
    
    context?.saveGState()
    if (isDashed) {
      let pointsHigh = self.bounds.height
      // create a 3 dash = 2 gap line at 5/4: 3*5+2*3 == 21 units
      let dash = 5 * pointsHigh / 21.0
      let space = 3 * pointsHigh / 21.0
      context?.saveGState()
      context?.setLineDash(phase: 0.0, lengths: [dash,space])
    }
    context?.setStrokeColor(markColor)
    //    let end = self.bounds.width
    let end = unZoomedBoundsWidth
    // reduce vertical to create 'rounded' box shape
    var bottom = CGFloat(0.0)
    var top = self.bounds.height
    if (capStyle == .square || capStyle == .round) {
       bottom = CGFloat(0.0) + markWidth*0.5
       top = self.bounds.height - markWidth*0.5 - CGFloat(byPerecentage) * self.bounds.height
   }
    for position in normalizedMarks
    {
      let xpos = CGFloat(position) * end
      NSBezierPath.defaultLineWidth = markWidth * CGFloat(currentZoomFactor)
      NSBezierPath.defaultLineCapStyle = capStyle//(NSLineCapStyle.roundLineCapStyle)
      NSBezierPath.strokeLine(from: NSPoint(x:xpos,y:top),to: NSPoint(x:xpos,y:bottom))
    }
    context?.restoreGState()
  }
  
  func drawMarks(normalizedMarks: [Double], withColour markColor: CGColor, inContext context: CGContext?, isDashed dashed: Bool)
  {
    drawMarksReducedHeight(byPerecentage: 0.0, normalizedMarks: normalizedMarks, withColour: markColor, with: .round, isDashed: dashed, inContext: context)
  }
  
  func drawTimes(normalizedMarks: [Double], withColour markColor: CGColor, inContext context: CGContext?)
  {
    context?.saveGState()
    context?.setStrokeColor(markColor)
    //    let end = self.bounds.width
    let end = unZoomedBoundsWidth
    for position in normalizedMarks
    {
      let timeText = attributedStringFromPosition(position, atZoomFactor: currentZoomFactor)
      let textWidth = timeText.size().width // * CGFloat(currentZoomFactor)
      let textHeight = timeText.size().height
      let xpos = CGFloat(position) * end - 0.5 * textWidth
      let ypos = self.bounds.height -  textHeight
      let tackPoint = CGPoint(x: xpos, y: ypos )
      timeText.draw(at: tackPoint)
    }
    context?.restoreGState()
  }
  
  /// Draw a shaded box of the section to remove
  func drawCutBox(normalizedStart: Double, normalizedEnd:Double, inContext context:CGContext?)
  {
    guard (fabs(normalizedEnd - normalizedStart) > 0.001 ) else { return }
//    Swift.print("Drawing Cutbox from \(normalizedStart) to \(normalizedEnd)")
    context?.saveGState()
    context?.setFillColor(cutoutColour.cgColor)
    //    let end = self.frame.width
    let end = unZoomedBoundsWidth
    let bottom = CGFloat(0.0)
    let llxpos = CGFloat(normalizedStart) * end
    let llypos = bottom
    let box = NSRect(x: llxpos, y: llypos, width: CGFloat(normalizedEnd-normalizedStart)*end, height: self.frame.height)
    let path = NSBezierPath(rect: box)
    path.fill()
    context?.restoreGState()
  }
  
  func setBookmarkPositions(normalizedPositions:[Double])
  {
    bookMarkPositions = normalizedPositions
    self.setNeedsDisplay(self.bounds)
  }
  
  func setInPositions(normalizedPositions:[Double])
  {
    inPositions = normalizedPositions
    self.setNeedsDisplay(self.bounds)
  }
  
  func setOutPositions(normalizedPositions:[Double])
  {
    outPositions = normalizedPositions
    self.setNeedsDisplay(self.bounds)
  }
  
  func setCutBoxPositions(normalizedPositions:[Double])
  {
    cutBoxPositions = normalizedPositions
    self.setNeedsDisplay(self.bounds)
  }
  
  func setGapPositions(normalizedPositions:[Double]) {
    gapPositions = normalizedPositions
    self.needsDisplay = true
  }
  
  func setPCRPositions(normalizedPositions:[Double]) {
    pcrPositions = normalizedPositions
    self.needsDisplay = true
  }
 
  /// Send the delta (normalized) of the new and old current position to cause the 
  /// timeline boundaries to be adjusted to keep the current postion marker on
  /// screen when zoomed in
  func updateBoundary(newCurrentPosition: Double)
  {
    guard (self.isZoomed) else { return }
    let previousCurrentPositionNormalized = currentPosition[0]
    let normalizedBoundaryDelta = newCurrentPosition - previousCurrentPositionNormalized
    if(debug) {Swift.print("normed delta = \(normalizedBoundaryDelta)") }
    super.moveBounds(normalizeStep: normalizedBoundaryDelta)
  }

}
