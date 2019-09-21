//
//  ShortEventDescriptorViewController.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 14/12/16.
//  Copyright © 2016 Alan Franklin. All rights reserved.
//

import Cocoa

extension NSTextView {
  var isEnabled : Bool {
    set {
      if !newValue {
      self.isEditable = false
      self.isSelectable = false
      self.textColor = NSColor.disabledControlTextColor
      }
      else {
        self.isEditable = true
        self.isSelectable = true
        self.textColor = NSColor.controlTextColor
      }
    }
    get {
      return self.isEditable
    }
  }
}

struct eitStringConsts {
  static let inputValueFieldIdentifier = "inputValueFieldIdentifier"
  static let inputStringFieldIdentifier = "inputStringFieldIdentifier"
}

class ShortEventDescriptorViewController: NSViewController, NSTextFieldDelegate
{
  var preferences = NSApplication.shared.delegate as! AppPreferences
  var movie: Recording?
  var index : Int = 0
  var numberFieldValue = 0
  var numberFieldEntryIsValid = false
  var isModified = false
  
  @IBOutlet weak var languageField: NSTextField!
  @IBOutlet weak var tagField: NSTextField!
  @IBOutlet weak var descriptorLength: NSTextField!
  @IBOutlet weak var eventNameLength: NSTextField!
  @IBOutlet weak var eventNameText: NSTextField!
  @IBOutlet weak var eventNameCode: NSTextField!
  @IBOutlet weak var eventTextLength: NSTextField!
  @IBOutlet weak var eventText: NSTextView!
  @IBOutlet weak var eventTextScrollView: NSScrollView!
  @IBOutlet weak var eventTextCode: NSTextField!
  
  @IBOutlet weak var nextButton: NSButton!
  @IBOutlet weak var previousButton: NSButton!
  
  override func viewDidLoad() {
      super.viewDidLoad()
      // Do view setup here.
    setupFromMovie()
    NotificationCenter.default.addObserver(self, selector: #selector(movieChanged(_:)), name: NSNotification.Name(rawValue: movieDidChange), object: nil )
  }
  
  func setFields(shortEventDescriptor: Short_Event_Descriptor?)
  {
    var shortDescriptor = Short_Event_Descriptor()
    if shortEventDescriptor != nil {
      shortDescriptor = shortEventDescriptor!
    }
    
    if let language = shortDescriptor.languageCode {
      languageField.stringValue  = language
    }
    descriptorLength.stringValue = String(format:"%3d",shortDescriptor.itemLength)
    tagField.stringValue = shortDescriptor.tag.asHexString()
    if let nameLength = shortDescriptor.eventName?.contentText?.count {
      eventNameLength.integerValue = nameLength
      eventNameCode.stringValue = (shortDescriptor.eventName?.characterTable.asHexString())!
      eventNameLength.isEnabled = true
      eventNameText.stringValue = (shortDescriptor.eventName?.contentText) ?? "Undefined"
      eventNameText.isEnabled = true
    }
    else {
      eventNameCode.stringValue = UInt8(0).asHexString()
      eventNameText.isEnabled = false
      eventNameText.stringValue = "none"
      eventNameLength.isEnabled = false
      eventNameLength.integerValue = 0
      
    }
    if let textLength = shortDescriptor.eventText?.contentText?.count {
      eventTextLength.integerValue = textLength
      eventTextCode.stringValue = (shortDescriptor.eventText?.characterTable.asHexString())!
      eventTextLength.isEnabled = true
      eventText.isEnabled = true
      eventText.string = shortDescriptor.eventText?.contentText ?? "Undefined"
    }
    else {
      eventText.string = "none"
      eventTextCode.stringValue = UInt8(0).asHexString()
      eventText.isEnabled = false
      eventTextLength.integerValue = 0
      eventTextLength.isEnabled = false
    }
  }
  
  func setupFromMovie()
  {
    movie = preferences.movie()
    index = 0
    if let descriptors = movie?.eit.eit.shortDescriptors
    {
      let shrtDescriptor = descriptors[index]
      setFields(shortEventDescriptor: shrtDescriptor)
      previousButton.isEnabled = false
      nextButton.isEnabled = false
      if descriptors.count > 1 {
        nextButton.isEnabled = true
      }
    }
    else {
      setFields(shortEventDescriptor: nil)
      previousButton.isEnabled = false
      nextButton.isEnabled = false
    }
  }
    
  @objc func movieChanged(_ notification: Notification)
  {
    // flushChanges ?
    setupFromMovie()
  }
  
  // MARK: - Delegate functions
  
  func controlTextDidEndEditing(_ obj: Notification)
  {
    let textField = obj.object as! NSTextField
//        print (#function+":"+textField.stringValue)
    if (textField.identifier?.rawValue.contains(eitStringConsts.inputValueFieldIdentifier))!
    {
      if let newValue = Int(textField.stringValue)
      {
        numberFieldValue = newValue
        numberFieldEntryIsValid = true
        textField.backgroundColor = NSColor.white
      }
      else {
        numberFieldEntryIsValid = false
        textField.backgroundColor = NSColor.red
        NSSound.beep()
      }
    }
  }
  
  // MARK: - Button / Field Actions
  @IBAction func nextShortDescriptor(_ sender: NSButton) {
    index += 1
    setFields(shortEventDescriptor: (movie?.eit.eit.shortDescriptors?[index])!)
    previousButton.isEnabled = true
    nextButton.isEnabled = (index+1) < (movie?.eit.eit.shortDescriptors?.count)!
  }
  
  @IBAction func previousShortDescriptor(_ sender: NSButton) {
    index -= 1
    setFields(shortEventDescriptor: (movie?.eit.eit.shortDescriptors?[index])!)
    nextButton.isEnabled = true
    previousButton.isEnabled = index > 0
  }
  
  @IBAction func changeDescriptorLength(_ sender: NSTextField) {
    if (numberFieldEntryIsValid) {
      movie?.eit.eit.shortDescriptors?[index].itemLength = numberFieldValue
    }
  }
  
  @IBAction func changeEventNameLength(_ sender: NSTextField) {
    if (numberFieldEntryIsValid) {
//      movie?.eit.eit.shortDescriptors?[index].eventName = numberFieldValue
    }
  }
  
  @IBAction func changeEventTextLength(_ sender: NSTextField) {
    if (numberFieldEntryIsValid) {
//      movie?.eit.eit.shortDescriptors?[index].eventText = numberFieldValue
    }
  }
  
//  @IBAction func done(_ sender: NSButton) {
//    // close the window
//    self.view.window?.close()
//  }
  
  @IBAction func saveShortDescriptor(_ sender: NSButton) {
//    delegate.saveSortPreference(sortPreference)
    NotificationCenter.default.post(name: Notification.Name(rawValue: eitDidChange), object: nil)
    var newShortDescriptor = Short_Event_Descriptor()
    newShortDescriptor.languageCode = languageField.stringValue
    if (eventTextLength.integerValue != 0 )
    {
      if (eventTextCode.integerValue == 0 || eventTextCode.integerValue == 0x15 ) {
        newShortDescriptor.eventName = DVBTextString(characterTable: 0x00, contentText: eventNameText.stringValue)
      }
      else {
        let charTable = UInt8(eventTextCode.integerValue)
        newShortDescriptor.eventName = DVBTextString(characterTable: charTable, contentText: eventNameText.stringValue)
      }
    }
    if (eventTextLength.integerValue != 0) {
      newShortDescriptor.eventText = DVBTextString(characterTable: 0x00, contentText: eventText.string)
    }
    movie?.eit.eit.shortDescriptors?[index] = newShortDescriptor
    isModified = true
  }
  
  
  @IBAction func done(_ sender: NSButton) {
    // TODO: build a "modified" and warn on exit without save of changes
    self.presentingViewController?.dismiss(sender)
  }
  
  @IBAction func cancel(_ sender: NSButton) {
    // TODO: build a "modified" and warn on exit without save of changes
   self.presentingViewController?.dismiss(sender)
   self.view.window?.close()
  }
  
  
  // TODO: implement save/done/cancel // UNDO?
  // TODO: implement field editing
}
