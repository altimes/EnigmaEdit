//
//  PopUpWithContextFilter.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 10/8/18.
//  Copyright © 2018 Alan Franklin. All rights reserved.
//


import Cocoa

class PopUpWithContextFilter: NSPopUpButton {
  
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    
    // Drawing code here.
  }
  
  var filter: PopUpFilter?
  weak var parentViewController: ViewController?
  
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    commonInit()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }
  
  /// For subclass to implement
  open func commonInit() {
  }
  
  override func rightMouseDown(with event: NSEvent)
  {
    guard let listFilter = filter else {
      super.rightMouseDown(with: event)
      return
    }
    
    guard let contextMenu = listFilter.menu else {
      super.rightMouseDown(with: event)
      return
    }
    NSMenu.popUpContextMenu(contextMenu, with: event, for: self)
    super.rightMouseDown(with: event)
  }

}
