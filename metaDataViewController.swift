//
//  metaDataViewController.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 2/2/17.
//  Copyright © 2017 Alan Franklin. All rights reserved.
//

import Cocoa

class metaDataViewController: NSViewController {

  @IBOutlet weak var serviceRefTextField: NSTextField!
  @IBOutlet weak var nameTextField: NSTextField!
  @IBOutlet weak var recordingDescription: NSTextField!
  @IBOutlet weak var recordingTime: NSTextField!
  @IBOutlet weak var tags: NSTextField!
  @IBOutlet weak var duration: NSTextField!
  @IBOutlet weak var filesize: NSTextField!
  @IBOutlet weak var serviceData: NSTextField!
  @IBOutlet weak var packetSize: NSTextField!
  @IBOutlet weak var scrambled: NSTextField!
  @IBOutlet weak var scrambledPopup: NSPopUpButton!
  @IBOutlet weak var scrambledCheckBox: NSButton!
  
  @IBOutlet weak var eServiceDisclosureButton: NSButton!

  
  var preferences = NSApplication.shared.delegate as! AppPreferences
  var movie: Recording?
  @objc var scrambledCheckBoxState = NSControl.StateValue.off {
    didSet {
      print("Saw checkBox state change")
      sourceData.meta.scrambled = scrambledCheckBoxState == .off ? "0" : "1"
    }
  }
  
  var sourceData: metaDataObject = metaDataObject(MetaData()) {
    didSet {
      print("Saw source state change")
      updateUI()
    }
  }
  
    override func viewDidLoad() {
      super.viewDidLoad()
        // Do view setup here.
      setupFromMovie()
//      if (sourceData != nil) {
//        meta1.update(with:(sourceData?.meta)!)
//      }
      NotificationCenter.default.addObserver(self, selector: #selector(movieChanged(_:)), name: NSNotification.Name(rawValue: movieDidChange), object: nil )
      if movie != nil {
        updateUI()
      }
    }
  
  func setupFromMovie()
  {
    movie = preferences.movie()
    sourceData.update(with: (movie?.meta)!)
//    if (sourceData != nil) {
//     self.meta1.update(with: sourceData!.meta)
//    }
    updateUI()
    print("sourceData = <\(sourceData.meta.decodeServiceDataAsString(sourceData.meta.serviceData))>")
  }
  
  func updateUI() {
//    if (sourceData == nil) { // clear all fields
//      serviceRefTextField.stringValue = ""
//      nameTextField.stringValue = ""
//      recordingDescription.stringValue = ""
//      recordingTime.stringValue = ""
//      recordingTime.toolTip = ""
//      tags.stringValue = ""
//      duration.stringValue = ""
//      duration.toolTip = ""
//      filesize.stringValue = ""
//      serviceData.stringValue = ""
//      packetSize.stringValue = ""
//      scrambled.stringValue = ""
//      scrambledCheckBox.isEnabled = false
//      scrambledPopup.selectItem(at: 0)
//    }
//    else { // set corresponding fields
      serviceRefTextField.stringValue = sourceData.meta.serviceReference
      nameTextField.stringValue = sourceData.meta.programName
      recordingDescription.stringValue = sourceData.meta.programDescription
      let recordingTimeString = sourceData.meta.recordingTime
      if let recordingTimeDouble = Double(recordingTimeString) {
        recordingTime.stringValue = recordingTimeString
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MMM-dd HH:mm:ss zzz"
        recordingTime.toolTip = formatter.string(from: Date(timeIntervalSince1970:recordingTimeDouble))
      }
      tags.stringValue = sourceData.meta.tags
      duration.stringValue = sourceData.meta.duration
      if let metaDuration = PtsType(duration.stringValue) {
        duration.toolTip = metaDuration.hhMMss
      }
      else {
        duration.toolTip = "Metadata Absent"
      }
      filesize.stringValue = sourceData.meta.programFileSize
      let serviceDataValue = sourceData.meta.serviceData
        serviceData.stringValue = serviceDataValue
        serviceData.toolTip = sourceData.meta.decodeServiceData(sourceData.meta.serviceData).description
      packetSize.stringValue = sourceData.meta.packetSize
      scrambled.stringValue = sourceData.meta.scrambled
      if let scrambledInt = Int(scrambled.stringValue) {
//        scrambledCheckBox.state = scrambledInt == 1 ? NSOnState : NSOffState
        scrambledPopup.selectItem(at: scrambledInt)
      }
//    }
  }
  
  @objc func movieChanged(_ notification: NSNotification)
  {
    setupFromMovie()
  }
  
  override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
    if let disclosureButton = sender as? NSButton
    {
      if ((segue.identifier!).rawValue == "eServiceRef" && disclosureButton.state == .on) {
        if let srvc = segue.destinationController as? EServiceRefViewController
        {
          srvc.eserviceRef = sourceData.meta.decodeServiceReference(sourceData.meta.serviceReference)
          let mousePoint = NSEvent.mouseLocation
          print("\(mousePoint)")
          srvc.controllerPresentationOrigin = mousePoint
        }
      }
    }
  }
  
//  func junk () {
//    let dateCreator = DateFormatter()
//    dateCreator.timeZone = TimeZone(abbreviation: "UTC")
//    dateCreator.dateFormat = "yyyy-MM-dd HH:mm:ss"
//    let startDateTime = dateCreator.date(from: datetimeString)
//    let dateFormatter = DateFormatter()
//    dateFormatter.dateStyle = DateFormatter.Style.medium
//    dateFormatter.timeStyle = DateFormatter.Style.medium
//    dateFormatter.timeZone = TimeZone.ReferenceType.local
//    //        let localDateTime = dateFormatter.stringFromDate(startDateTime!)
//    //        print("Even start local: \(localDateTime)")
//    dateFormatter.dateFormat = "dd MMM yyyy"
//    eit.StartDate = dateFormatter.string(from: startDateTime!)
//    dateFormatter.dateFormat = "h:mm:ss a zzz"
//    eit.StartTime = dateFormatter.string(from: startDateTime!)

//  }
}
