//
//  SwitchControl.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 6/7/17.
//  Adopted from http://www.filtercode.com/swift/uiswitch-osx
//

import Cocoa
import Foundation
import QuartzCore

@IBDesignable
open class SwitchControl: NSButton {
  
  let kDefaultTintColor = NSColor.blue
  let kBorderWidth : CGFloat = 1.0
  let kGoldenRatio : CGFloat = 1.61803398875
  let kDecreasedGoldenRatio : CGFloat = 1.38
  let knobBackgroundColor = NSColor(calibratedWhite: 1, alpha: 1)
  let kDisabledBorderColor = NSColor(calibratedWhite: 0, alpha: 0.2)
  let kDisabledBackgroundColor = NSColor.clear
  let kAnimationDuration = 0.4
  let kEnabledOpacity: CFloat = 0.8
  let kDisabledOpacity: CFloat = 0.5
  let kOnText = "on"
  let kOffText = "off"
  let kIsFixedWidth = true
  let kFixedWidth: CGFloat = 50.0
  
  @IBInspectable var isOn : Bool {
    didSet{
      self.refreshLayer()
    }
  }
  // switch background color when "ON"
  @IBInspectable dynamic var tintColor : NSColor {
    didSet {
      self.refreshLayer()
    }
  }
  
  // switch associated text when "ON"
  @IBInspectable var onText : String? {
    didSet {
      self.refreshLayer()
    }
  }
  
  // switch associated text when "OFF"
  @IBInspectable var offText : String? {
    didSet {
      self.refreshLayer()
    }
  }
  
  // switch part to be fixed size or proportion of control width
  @IBInspectable var isFixedWith: Bool = true {
    didSet {
      self.setupLayers()
    }
  }
  
  // when fixed width, horizontal size of control
  @IBInspectable var fixedWidth: CGFloat = 50.0 {
    didSet {
      self.setupLayers()
    }
  }
  
  // when proportional, proportion of switch element
  @IBInspectable var proportionToSwitch :CGFloat = 0.25
  
  var isActive: Bool = false
  var hasDragged: Bool = false
  var isDragginToOn: Bool = false
  var rootLayer: CALayer = CALayer()
  var switchLayer: CALayer = CALayer()
  var knobLayer: CALayer = CALayer()
  var knobInsideLayer: CALayer = CALayer()
  var textLayer: CATextLayer = CATextLayer()
  
  override open var frame: NSRect {
    get {
      return super.frame
    }
    set {
      super.frame = newValue
      self.refreshLayerSize()
    }
  }
  
  override open var acceptsFirstResponder: Bool { get { return true } }
  
  override open var isEnabled: Bool {
    get { return super.isEnabled }
    set{
      //      Swift.print("setting enabled to \(newValue)")
      super.isEnabled = newValue
      self.refreshLayer()
    }
  }
  
  // MARK: - Initializers
  init(isOn: Bool, frame: NSRect, textOn: String?, textOff: String?, tintColor: NSColor?) {
    
    self.isOn = isOn
    if let optionalTintColor = tintColor {
      self.tintColor = optionalTintColor
    } else {
      self.tintColor = kDefaultTintColor
    }
    if let setOnText = textOn {
      self.onText = setOnText
    } else {
      self.onText = kOnText
    }
    if let setOffText = textOff
    {
      self.offText = setOffText
    } else {
      self.offText = kOffText
    }
    self.isFixedWith = kIsFixedWidth
    self.fixedWidth = kFixedWidth
    
    super.init(frame: frame)
    self.setupLayers()
    self.isEnabled = true
  }
  
  convenience init(isOn: Bool, frameRect: NSRect, textOn: String?, textOff: String?, tintColor: NSColor?, _isFixedWidth: Bool = true, _fixedWidth: CGFloat = 50.0)
  {
    self.init(isOn: false, frame: frameRect, textOn: nil, textOff: nil, tintColor: nil)
    self.isFixedWith = _isFixedWidth
    self.fixedWidth = _fixedWidth
    setupLayers()
  }
  
  required  public init?(coder: NSCoder) {
    self.isOn = false;
    self.tintColor = kDefaultTintColor
    self.onText = kOnText
    self.offText = kOffText
    super.init(coder: coder)
    self.setupLayers()
    self.isEnabled = true
  }
  
  convenience override init(frame frameRect: NSRect) {
    self.init(isOn: false, frame: frameRect, textOn: nil, textOff: nil, tintColor: nil)
  }
  
  // MARK: -  Setup
  func setupLayers() {
    layer = rootLayer
    wantsLayer = true
    
    // split button text 25 / 75 of width
    var switchControlBounds = rootLayer.bounds
    if isFixedWith {
      switchControlBounds.size.width = fixedWidth
    }
    else {
      switchControlBounds.size.width = proportionToSwitch * switchControlBounds.size.width
    }
    switchLayer.bounds = switchControlBounds
    switchLayer.anchorPoint = CGPoint(x: 0, y: 0)
    switchLayer.borderWidth = kBorderWidth as CGFloat
    switchLayer.frame = rectForSwitchLayer()
    Swift.print("switchLayer: frame:\(switchLayer.frame), bound:\(switchLayer.bounds)")
    rootLayer.addSublayer(switchLayer)
    
    // the layer that knob slides around in
    knobLayer.frame = rectForKnob()
    //    knobLayer.anchorPoint = CGPoint(x: 0.0, y: (switchLayer.bounds.height-knobLayer.bounds.height)/2.0)
    knobLayer.anchorPoint = CGPoint(x: 0.0, y: 0.0)
    Swift.print("knob layer: frame:\(knobLayer.frame), bound:\(knobLayer.bounds)")
    //    knobLayer.autoresizingMask = CAAutoresizingMask.layerHeightSizable
    knobLayer.backgroundColor = knobBackgroundColor.cgColor
    knobLayer.shadowColor = NSColor.black.cgColor
    knobLayer.shadowOffset = CGSize(width: 0, height: -2)
    knobLayer.shadowRadius = 1
    knobLayer.shadowOpacity = 0.3
    
    rootLayer.addSublayer(knobLayer)
    
    // the knob that moves
    knobInsideLayer.frame = knobLayer.bounds
    Swift.print("knobInsideLayer : frame:\(knobInsideLayer.frame), bound:\(knobInsideLayer.bounds)")
    knobInsideLayer.backgroundColor = NSColor.yellow.cgColor
    knobInsideLayer.anchorPoint = CGPoint(x: 0.0, y: 0.0)
    knobInsideLayer.shadowColor = NSColor.black.cgColor
    knobInsideLayer.shadowOffset = CGSize(width: 0, height: 0)
    knobInsideLayer.shadowRadius = 1
    knobInsideLayer.shadowOpacity = 0.35
    
    knobLayer.addSublayer(knobInsideLayer)
    
    var textFrame = rootLayer.frame
    if isFixedWith {
      textFrame.origin.x = fixedWidth
      textFrame.size.width = rootLayer.frame.width - fixedWidth
    } else {
      textFrame.origin.x = proportionToSwitch * rootLayer.frame.width
      textFrame.size.width = (1.0-proportionToSwitch) * rootLayer.frame.width
    }
    textFrame.origin.y = 0.0
    textLayer.backgroundColor = NSColor.red.cgColor
    textLayer.frame = textFrame
    textLayer.string = self.isOn ? self.onText : self.offText
    textLayer.fontSize = 14.0
    textLayer.contentsScale = (NSScreen.main?.backingScaleFactor)!
    Swift.print("\(textLayer.string as! String)")
    
    rootLayer.addSublayer(textLayer)
    
    refreshLayerSize()
    refreshLayer()
  }
  
  func rectForSwitchLayer() -> CGRect
  {
    let height = knobHeightForSize(size: switchLayer.bounds.size)
    return CGRect(x: switchLayer.frame.origin.x, y: kBorderWidth, width: switchLayer.frame.width, height: height)
  }
  
  
  func rectForKnob() -> CGRect {
    let height = knobHeightForSize(size: switchLayer.bounds.size)
    var width : CGFloat
    if (!self.isActive) {
      let value = (NSWidth(switchLayer.bounds) - 2 * kBorderWidth) * 1 / kGoldenRatio
      width = value
    } else {
      let value = (NSWidth(switchLayer.bounds) - 2 * kBorderWidth) * 1 / kDecreasedGoldenRatio
      width = value
    }
    //let width = (!self.isActive) ? (NSWidth(backgroundLayer.bounds) - 2 * kBorderWidth) * 1 / kGoldenRatio : (NSWidth(backgroundLayer.bounds) - 2 * kBorderWidth) * 1 / kDecreasedGoldenRatio
    
    let x = ((!hasDragged && !isOn) || (hasDragged && !isDragginToOn)) ? kBorderWidth : NSWidth(switchLayer.bounds) - width - kBorderWidth
    //    let knobRect = CGRect(x: x, y: kBorderWidth, width: width, height: height)
    let knobRect = CGRect(x: x, y: 2*kBorderWidth, width: width, height: height)
    Swift.print("rectForKnob: \(knobRect)")
    return  knobRect
  }
  
  func knobHeightForSize(size: NSSize) -> CGFloat {
    // try goldenratio of width to height
    var height = size.width / kGoldenRatio
    height = min(height, size.height)
    Swift.print("base height \(size.height), adjusted height \(height)")
    return height - kBorderWidth * 2
  }
  
  func knobLayerHeightForSize(size: NSSize) -> CGFloat {
    // try goldenratio of width to height
    var height = size.width / kGoldenRatio
    height = min(height, size.height)
    Swift.print("base height \(size.height), adjusted height \(height)")
    return height - kBorderWidth * 2
  }
  
  func refreshLayerSize() {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    
    knobLayer.frame = rectForKnob()
    knobInsideLayer.frame = knobLayer.bounds
    
    switchLayer.cornerRadius = switchLayer.bounds.size.height / 2
    knobLayer.cornerRadius = knobLayer.bounds.size.height / 2
    knobInsideLayer.cornerRadius = knobLayer.bounds.size.height / 2
    textLayer.string = self.isOn ? self.onText : self.offText
    Swift.print("\(textLayer.string as! String)")
    
    CATransaction.commit()
  }
  
  func refreshLayer () {
    CATransaction.begin()
    CATransaction.setAnimationDuration(kAnimationDuration)
    
    if (hasDragged && isDragginToOn) || (!hasDragged && isOn) {
      switchLayer.borderColor = tintColor.cgColor
      switchLayer.backgroundColor = tintColor.cgColor
    } else {
      switchLayer.borderColor = kDisabledBorderColor.cgColor
      switchLayer.backgroundColor = kDisabledBackgroundColor.cgColor
    }
    
    if !isActive {
      rootLayer.opacity = kEnabledOpacity as Float
    } else {
      rootLayer.opacity = kDisabledOpacity as Float
    }
    
    if !hasDragged {
      CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.25, 1.5, 0.5, 1.0))
    }
    
    knobLayer.frame = rectForKnob()
    knobInsideLayer.frame = knobLayer.bounds
    textLayer.string = self.isOn ? self.onText : self.offText
    Swift.print("\(textLayer.string as! String)")
    
    CATransaction.commit()
  }
  
  // MARK: - NSView
  override open func acceptsFirstMouse(for event: NSEvent?) -> Bool {
    return true
  }
  
  // MARK: - NSResponder
  override open func mouseDown(with event: NSEvent) {
    Swift.print("Mouse DOWN enabled is \(super.isEnabled)")
    if !super.isEnabled {
      isActive = true
      refreshLayer()
    }
  }
  
  open override func mouseDragged(with event: NSEvent) {
    Swift.print("Mouse DRAGGED enabled is \(super.isEnabled) at \(event.locationInWindow)")
    if super.isEnabled {
      hasDragged = true
      
      let dragDelta = event.deltaX
      isDragginToOn = dragDelta > 0.0
      //      let dragginPoint: NSPoint = convert(event.locationInWindow, from: nil)
      //      isDragginToOn = dragginPoint.x >= NSWidth(bounds) / 2.0
      
      refreshLayer()
    }
    
  }
  
  override open func mouseUp(with event: NSEvent)  {
    Swift.print("Mouse UP enabled is \(super.isEnabled)")
    if super.isEnabled {
      isActive = false
      
      let isOn: Bool = (!hasDragged) ? !self.isOn : isDragginToOn
      let invokeTargetAction: Bool = isOn != self.isOn
      
      self.isOn = isOn
      
      hasDragged = false
      isDragginToOn = false
      
      refreshLayer()
      if invokeTargetAction {
        cell?.performClick(self)
      }
    }
  }
}
