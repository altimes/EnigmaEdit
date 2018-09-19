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
          ("All",#selector(PopUpWithStatusFilter.showAll))
      ])
    }
    
    typealias MatchStatus = (_ arrayIndex: Int)->Bool
    private func setVisibilty(isHidden hideTest: MatchStatus)
    {
      for index in 0..<self.itemArray.count
      {
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
      if let textColour = attributes[NSAttributedStringKey.foregroundColor]
      {
        hide =  (textColour as! NSColor) != colourCode
      }
    }
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
    
  }
