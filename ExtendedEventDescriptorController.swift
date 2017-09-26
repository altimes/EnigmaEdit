//
//  ExtendedEventDescriptorController.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 19/12/16.
//  Copyright © 2016 Alan Franklin. All rights reserved.
//

import Cocoa

class ExtendedEventDescriptorController: NSViewController, NSTableViewDelegate, NSTableViewDataSource
{

  var preferences = NSApplication.shared.delegate as! AppPreferences
  var movie: Recording?
  @IBOutlet weak var languageField: NSTextField!
  @IBOutlet weak var tagField: NSTextField!
  @IBOutlet weak var descriptorLength: NSTextField!
  @IBOutlet weak var eventDescriptionLength: NSTextField!
  @IBOutlet weak var eventDescriptionText: NSTextView!
  @IBOutlet weak var eventDescriptionCodeTable: NSTextField!
  
  @IBOutlet weak var eventItemLength: NSTextField!
  @IBOutlet weak var eventItemText: NSTextField!
  @IBOutlet weak var sequenceNumber: NSTextField!
  @IBOutlet weak var highestSequenceNumber: NSTextField!
  @IBOutlet weak var itemsTable: NSTableView!
  
  @IBOutlet weak var previousButton: NSButton!
  @IBOutlet weak var nextButton: NSButton!
  
  var index = 0
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do view setup here.
    setupFromMovie()
    NotificationCenter.default.addObserver(self, selector: #selector(movieChanged(_:)), name: NSNotification.Name(rawValue: movieDidChange), object: nil )
  }
  
  func setupFromMovie()
  {
    movie = preferences.movie()
    index = 0
    let extendedDescriptors = movie?.eit.eit.extendedDescriptors
    previousButton.isEnabled = false
    nextButton.isEnabled = false
    if let descriptor = extendedDescriptors?[index] {
      setFields(extendedEventDescriptor: descriptor)
      if (extendedDescriptors?.count)! > 1 {
        nextButton.isEnabled = true
      }
    }
    else {
      setFields(extendedEventDescriptor: nil)
    }
  }
  
  @objc func movieChanged(_ notification: NSNotification)
  {
    setupFromMovie()
  }
  
  func setFields(extendedEventDescriptor: Extended_Event_Descriptor?)
  {
    var extendedDescriptor = Extended_Event_Descriptor()
    if extendedEventDescriptor != nil {
      extendedDescriptor = extendedEventDescriptor!
    }
    tagField.stringValue = extendedDescriptor.tag.asHexString()
    sequenceNumber.integerValue = extendedDescriptor.descriptorNumber
    highestSequenceNumber.integerValue = extendedDescriptor.highestDescriptorNuber
    languageField.stringValue = (extendedDescriptor.languageCode!)
    descriptorLength.stringValue = "\(extendedDescriptor.descriptorLength)"
    let eventItems = extendedDescriptor.itemDescription
    for j in 0..<(extendedDescriptor.itemCount)
    {
      print(eventItems?[j].asString ?? "missing item")
    }
    print(extendedDescriptor.descriptionText ?? "missing decription")
    if let descriptionText = extendedDescriptor.descriptionText?.contentText {
      eventDescriptionText.string = descriptionText
      eventDescriptionCodeTable.stringValue = extendedDescriptor.descriptionText?.characterTable.asHexString() ?? "0x00"
    }
    
  }
  
  ///
  @IBAction func nextExtendedDescriptor(_ sender: NSButton) {
    index += 1
    setFields(extendedEventDescriptor: (movie?.eit.eit.extendedDescriptors?[index])!)
    previousButton.isEnabled = true
    nextButton.isEnabled = (index+1) < (movie?.eit.eit.extendedDescriptors?.count)!
  }
  
  @IBAction func previousExtendedDescriptor(_ sender: NSButton) {
    index -= 1
    setFields(extendedEventDescriptor: (movie?.eit.eit.extendedDescriptors?[index])!)
    nextButton.isEnabled = true
    previousButton.isEnabled = index > 0
  }
  @IBAction func done(_ sender: NSButton) {
    // close the window
    self.view.window?.close()
  }
  
  
}
