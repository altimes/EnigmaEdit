//
//  EITEditController.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 14/12/16.
//  Copyright © 2016 Alan Franklin. All rights reserved.
//

import Cocoa

class EITEditController: NSViewController, NSWindowDelegate {

  @IBOutlet weak var eventIDField: NSTextField!
  @IBOutlet weak var whenField: NSTextField!
  @IBOutlet weak var startTimeField: NSTextField!
  @IBOutlet weak var startDateField: NSTextField!
  @IBOutlet weak var durationField: NSTextField!
  @IBOutlet weak var isEncryptedField: NSTextField!
  @IBOutlet weak var shortDescriptorCountField: NSTextField!
  @IBOutlet weak var longDescriptorCountField: NSTextField!
  @IBOutlet weak var shortDescriptorButton: NSButton!
  @IBOutlet weak var extendedDescriptorButton: NSButton!
  
  var preferences = NSApplication.shared.delegate as! AppPreferences
  var movie: Recording?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do view setup here.
    setupFromMovie()
    NotificationCenter.default.addObserver(self, selector: #selector(movieChanged(_:)), name: NSNotification.Name(rawValue: movieDidChange), object: nil )
//    NotificationCenter.default.addObserver(self, selector: #selector(didDeminiturize(_:)), name: NSWindowDidDeminiaturize, object: nil)
  }
  
  override func viewDidAppear() {
    // set window delegate
    self.view.window?.delegate = self
  }
  
  func windowWillMiniaturize(_ notification: Notification) {
//    print(#file+" "+#function)
  }
  
  func windowDidMiniaturize(_ notification: Notification) {
//    print(#file+" "+#function)
  }
  
  func windowDidDeminiaturize(_ notification: Notification) {
//    print(#file+" "+#function)
  }
  
  
  func setupFromMovie()
  {
    movie = preferences.movie()
    extendedDescriptorButton.isEnabled = false
    shortDescriptorButton.isEnabled = false
    
    longDescriptorCountField.integerValue = 0
    shortDescriptorCountField.integerValue = 0
    eventIDField.stringValue = ""
    whenField.stringValue = ""
    startTimeField.stringValue = ""
    startDateField.stringValue = ""
    startDateField.stringValue = ""
    durationField.stringValue = ""
    isEncryptedField.stringValue = ""
    
    if let extendedDescriptorCount = movie?.eit.eit.extendedDescriptors?.count {
      longDescriptorCountField.integerValue = extendedDescriptorCount
      extendedDescriptorButton.isEnabled = true
    }
    if let shortDescriptorCount = movie?.eit.eit.shortDescriptors?.count {
      shortDescriptorCountField.integerValue = shortDescriptorCount
      shortDescriptorButton.isEnabled = true
    }
    if let EIT = movie?.eit.eit {
      eventIDField.stringValue = EIT.EventID
      whenField.stringValue = EIT.When
      startTimeField.stringValue = EIT.StartTime
      startDateField.stringValue = EIT.StartDate
      durationField.stringValue = EIT.Duration
      isEncryptedField.stringValue = EIT.Encrypted
    }
  }
  
  @objc func movieChanged(_ notification: NSNotification)
  {
    setupFromMovie()
  }
  @IBAction func showShortDescriptors(_ sender: NSButton)
  {
    let _ = ShortEventDescriptorViewController()
  }
  
  @IBAction func showExtendedDescriptors(_ sender: NSButton)
  {
    let _ = ExtendedEventDescriptorController()
  }
  @IBAction func done(_ sender: NSButton) {
    // close the window
    self.view.window?.close()
  }
  
  
}
