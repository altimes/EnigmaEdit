//
//  EServiceRefViewController.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 15/2/17.
//  Copyright © 2017 Alan Franklin. All rights reserved.
//

// Support the editing of the eServiceReference field of the metadata file

import Cocoa

class EServiceRefViewController: NSViewController {

  var eserviceRef: EServiceReference?
  var controllerPresentationOrigin: NSPoint?
  
  @IBOutlet weak var referenceType: NSPopUpButton!
  
  @IBOutlet weak var flag_IsADirectory: NSButton!
  @IBOutlet weak var flag_CannotBePlayed: NSButton!
  @IBOutlet weak var flag_MustChangeToDirectory: NSButton!
  @IBOutlet weak var flag_NeedsSorting: NSButton!
  @IBOutlet weak var flag_ServiceHasSortKey: NSButton!
  @IBOutlet weak var flag_SortKeyIs1: NSButton!
  @IBOutlet weak var flag_IsAMarker: NSButton!
  @IBOutlet weak var flag_ServiceIsNotPlayable: NSButton!
  
  @IBOutlet weak var serviceRefType: NSPopUpButton!
  @IBOutlet weak var ServiceID: NSTextField!
  @IBOutlet weak var TransportID: NSTextField!
  @IBOutlet weak var OriginalNetworkID: NSTextField!
  @IBOutlet weak var namespace: NSTextField!
  @IBOutlet weak var ParentServiceID: NSTextField!
  @IBOutlet weak var ParentTranSportID: NSTextField!
  @IBOutlet weak var unused: NSTextField!
  @IBOutlet weak var path: NSTextField!
  @IBOutlet weak var name: NSTextField!
  
  
  
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
      if let serviceRef = eserviceRef
      {
        referenceType.removeAllItems()
        referenceType.addItems(withTitles: ENIGMA2_SERVICEREFERENCE_REFTYPE.allValues())
        referenceType.selectItem(withTitle: (serviceRef.referenceType?.description)!)
        
        let flags = serviceRef.flags!
        flag_IsADirectory.state = (flags.contains(ENIGMA2_SERVICEREFERENCE_FLAGS.ISADIRECTORY) ? .on : .off)
        flag_CannotBePlayed.state = (flags.contains(ENIGMA2_SERVICEREFERENCE_FLAGS.CANNOT_BE_PLAYED) ? .on : .off)
        flag_MustChangeToDirectory.state = flags.contains(ENIGMA2_SERVICEREFERENCE_FLAGS.MUST_CHANGE_TO_DIRECTORY) ? .on : .off
        flag_NeedsSorting.state = flags.contains(ENIGMA2_SERVICEREFERENCE_FLAGS.NEEDS_SORTING) ? .on : .off
        flag_ServiceHasSortKey.state = flags.contains(ENIGMA2_SERVICEREFERENCE_FLAGS.SERVICE_HAS_SORT_KEY) ? .on : .off
        flag_SortKeyIs1.state = flags.contains(ENIGMA2_SERVICEREFERENCE_FLAGS.SORT_KEY_IS_1) ? .on : .off
        flag_IsAMarker.state = flags.contains(ENIGMA2_SERVICEREFERENCE_FLAGS.ISAMARKER) ? .on : .off
        flag_ServiceIsNotPlayable.state = flags.contains(ENIGMA2_SERVICEREFERENCE_FLAGS.SERVICE_IS_NOT_PLAYABLE) ? .on : .off
        
        serviceRefType.removeAllItems()
        serviceRefType.addItems(withTitles: ENIGMA2_SERVICEREFERENCE_TYPE.allDescriptions)
//        serviceRefType.selectItem(withTitle: (serviceRef.serviceType?.description)!)
        serviceRefType.selectItem(withTitle: ("\(serviceRef.serviceType ?? ENIGMA2_SERVICEREFERENCE_TYPE.unknown)"))

        ServiceID.stringValue = String(format:"0X%4.4X",serviceRef.service_id!)
        TransportID.stringValue = String(format:"0X%4.4X",serviceRef.transport_stream_id!)
        OriginalNetworkID.stringValue = String(format:"0X%4.4X",serviceRef.original_network_id!)
        namespace.stringValue = String(format:"0X%8.8X",serviceRef.namespace!)
        ParentServiceID.stringValue = String(format:"0X%8.8X",serviceRef.parent_service_id!)
        ParentTranSportID.stringValue = String(format:"0X%8.8X",serviceRef.parent_transport_stream_id!)
        unused.stringValue = serviceRef.unused!
        path.stringValue = serviceRef.path!
        name.stringValue = serviceRef.name ?? ""
      }
      if let controllerWindow = self.view.window {
          controllerWindow.setFrameOrigin(controllerPresentationOrigin!)
      }
    }
  
  // place window top left at button position
  override func viewWillAppear() {
    if let controllerWindow = self.view.window {
      controllerWindow.setFrameTopLeftPoint(controllerPresentationOrigin!)
    }
  }
  
  // reset disclosure button to "closed"
  override func viewWillDisappear() {
    if let parentVC = self.presentingViewController as? metaDataViewController
    {
      parentVC.eServiceDisclosureButton.state = .off
    }
    
  }
  // MARK: Utility fuctions
  
}
