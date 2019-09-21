//
//  PopUpWithStatusFilter.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 10/8/18.
//  Copyright © 2018 Alan Franklin. All rights reserved.
//

import Cocoa

class PopUpWithStatusFilter: PopUpWithContextFilter {

    override func draw(_ dirtyRect: NSRect) {
      super.draw(dirtyRect)
      
      // Drawing code here.
    }
    
    override init(frame frameRect: NSRect) {
      super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
      super.init(coder: coder)
    }
    
    override func commonInit() {
      super.commonInit()
      self.filter = PopUpFilter(popUpButton: self as NSPopUpButton)
      self.filter?.createMenu(entries:
        [
          ("Raw",#selector(PopUpWithStatusFilter.showRaw)),
          ("Partial",#selector(PopUpWithStatusFilter.showPartial)),
          ("Ready",#selector(PopUpWithStatusFilter.showReady)),
          ("Cut",#selector(PopUpWithStatusFilter.showCut)),
          ("All",#selector(PopUpWithStatusFilter.showAll)),
          ("Named",#selector(PopUpWithStatusFilter.showNamed))
      ])
      self.autoenablesItems = false
      self.isEnabled = false
    }
    
    typealias MatchStatus = (_ arrayIndex: Int)->Bool
    private func setVisibilty(isHidden hideTest: MatchStatus)
    {
      for index in 0..<self.itemArray.count
      {
        print("hide test for \(self.itemArray[index].attributedTitle!.string) is \(hideTest(index))")
        self.itemArray[index].isHidden = hideTest(index)
      }
      self.filter?.updatePopUp()
    }
  
  /// Determine if menu entry should be hidden or not
  /// Decision based on colour of first char of attributedTitle.
  /// Colour is used to track status of recording
  private func isTitleAtIndex(_ index:Int, matching colourCode: NSColor) -> Bool{
    var hide = true
    let firstCharRange = NSMakeRange(0, 1)
    if let attributes = self.itemArray[index].attributedTitle?.fontAttributes(in:firstCharRange) {
      if let textColour = attributes[NSAttributedString.Key.foregroundColor]
      {
        hide =  (textColour as! NSColor) != colourCode
      }
    }
    return hide
  }
  
  // Hide everthing that does not match entered string case insensitively
  private func doesTitleContainString(_ index:Int, target:String) -> Bool {
    var hide: Bool = true
    // make case insensitive
    let matchTo = target.uppercased()
    let itemString = self.itemArray[index].attributedTitle!.string.uppercased()
    hide = !itemString.contains(matchTo)
    return hide
  }
  
  /// Nothing is hidden
  @objc private func showAll()
  {
    setVisibilty(isHidden: {_ in return false})
  }
  
  /// Hide everthing that is editted to some degree
  @objc private func showRaw()
  {
    setVisibilty(isHidden: {index in
      return isTitleAtIndex(index, matching: colourLookup[.noBookmarksColour]!)
    })
  }
  
  /// Hide everything that has not been fully processed
  @objc private func showCut()
  {
    setVisibilty(isHidden: {index in  return isTitleAtIndex(index, matching: colourLookup[.allDoneColour]!)})
  }
  
  /// Hide everything except the recordings that partially setup for cutting
  @objc private func showPartial()
  {
    setVisibilty(isHidden: {index in  return isTitleAtIndex(index, matching: colourLookup[.partiallyReadyToCutColour]!)})
  }

  /// Hide everything except those that look ready to be cut
  @objc private func showReady()
  {
    setVisibilty(isHidden: {index in  return isTitleAtIndex(index, matching: colourLookup[.readyToCutColour]!)})
  }
  
  /// filter by name contents
  @objc private func showNamed()
  {
    var textField = NSTextField(frame: NSRect(x: 0.0, y: 0.0, width: 80.0, height: 24.0))
    let alert = NSAlert()
    alert.window.title = "Filter by Name"
    alert.messageText = "Enter string to filter list (case insensitive)"
//    alert.informativeText = "Enter string to match"
    alert.alertStyle = NSAlert.Style.informational
    alert.accessoryView = textField
    alert.runModal()
    setVisibilty(isHidden: {index in  return doesTitleContainString(index, target: textField.stringValue)})
  }
  
  // Determine if menu item should be enabled or not
  @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
//    print("In function "+#file+"/"+#function)
    return filter?.filterMenuEnabled ?? false
  }
  

  }
