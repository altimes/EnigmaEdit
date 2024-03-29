//
//  PopUpFilter.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 10/8/18.
//  Copyright © 2018 Alan Franklin. All rights reserved.
//

//  Create a Menu with associate methods and actions for filtering an NSPopupButton

import Cocoa

// TODO: add control to validate/respond to colouring being complete and filtering being possible

// TODO: add dynamic name filter to filter by recording name

struct PopUpFilter {
  var menu: NSMenu?
  var popUp: NSPopUpButton?
  public var filterMenuEnabled = false

  init(popUpButton: NSPopUpButton) {
    menu = NSMenu(title: "")
    popUp = popUpButton
  }
  
  /// Function to populate the menu with description and action to take
  /// - parameter entries: array of touples of title and selector
  func createMenu(entries:[(title:String,action:Selector, keyEquiv:String?, keyEquivMaskSet: NSEvent.ModifierFlags?)])
  {
    for item in entries {
      if item.keyEquiv == nil {
        self.menuAddItem(title: item.title, itemAction: item.action)
      }
      else {
        self.menuAddItem(title: item.title, itemAction: item.action, keyEquivalentCharacter: item.keyEquiv!, keyEquivalentMaskSet: item.keyEquivMaskSet)
      }
    }
    
  }
  
  /// Add an item to the menu with the associated action
  /// - parameter title: menu text
  /// - parameter itemAction: void function to call when selected
  private func menuAddItem(title itemTitle: String, itemAction:Selector)
  {
    guard let filterMenu = menu else {
      return
    }
    let menuItem = NSMenuItem(title: itemTitle, action: itemAction, keyEquivalent: "")
    
    menuItem.isEnabled = false
    filterMenu.addItem(menuItem)
  }
  
  
  /// Add an item to the menu with the associated action
  /// - parameter title: menu text
  /// - parameter itemAction: void function to call when selected

  private func menuAddItem(title itemTitle: String, itemAction:Selector, keyEquivalentCharacter: String = "", keyEquivalentMaskSet: NSEvent.ModifierFlags? = nil)
  {
    guard let filterMenu = menu else {
      return
    }
    let menuItem = NSMenuItem(title: itemTitle, action: itemAction, keyEquivalent: keyEquivalentCharacter)
    
    menuItem.isEnabled = false
    if keyEquivalentMaskSet != nil { menuItem.keyEquivalentModifierMask = keyEquivalentMaskSet!}
    
    filterMenu.addItem(menuItem)
    
  }

  /// Update the popUp menu changing current selection if necessary
  func updatePopUp()
  {
    // is there a selected item ?
    if let currentSelected = popUp?.selectedItem
    {
      // is it now Hidden ? If so, deselect and find next visible if any
      if currentSelected.isHidden {
        NotificationCenter.default.post(name: Notification.Name.PopUpWillChange, object: nil)
        let currentIndex = (popUp?.itemArray.firstIndex(of: currentSelected))!
        popUp?.select(nil)
        selectNextVisible(from: currentIndex)
      }
    }
    else {
      _ = selectFirstVisible(from: 0)
    }
  }
  
  func selectFirst() {
    _ = selectFirstVisible(from: 0)
  }
  
  /// Select first visible item in popUp start at "from" Index
  /// - parameter from: index into item array
  /// - returns: success of finding at item to select
  private func selectFirstVisible(from: Int) -> Bool
  {
    guard from >= 0 else { return false }
    guard let list = popUp else { return false }
    
    var success = false
    for itemIndex in from..<list.itemArray.count {
      if list.itemArray[itemIndex].isHidden {
        continue
      }
      else {
        list.selectItem(at: itemIndex)
        NotificationCenter.default.post(name: Notification.Name.PopUpHasChanged, object: nil)
        success = true
        break
      }
    }
    return success
  }
 
    

  
  /// Select next visible item in popUp starting at "from" Index
  /// If it runs of the end of the array, try starting from the begining
  /// - parameter from: index into item array
  func selectNextVisible(from index: Int)
  {
    let done =  selectFirstVisible(from: index)
    if !done {
      _ = selectFirstVisible(from: 0)
    }
  }
  
}
