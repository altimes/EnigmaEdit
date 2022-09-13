//
//  PopUpWithStatusFilter.swift
//  EnigmaEdit
//
//  Pop up to provide subjective filter of long popup list
//
//  Created by Alan Franklin on 10/8/18.
//  Copyright © 2018 Alan Franklin. All rights reserved.
//

import Cocoa

class PopUpWithStatusFilter: PopUpWithContextFilter {
  
  struct eitSummary: Equatable {
//    let channel: String
    let programTitle: String
    let episodeTitle: String
  }

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
        ("Raw",#selector(PopUpWithStatusFilter.showRaw),"R",NSEvent.ModifierFlags.option),
        ("Partial",#selector(PopUpWithStatusFilter.showPartial),"P",NSEvent.ModifierFlags.option),
        ("Ready",#selector(PopUpWithStatusFilter.showReady),"r",[NSEvent.ModifierFlags.control,NSEvent.ModifierFlags.option]),
        ("Cut",#selector(PopUpWithStatusFilter.showCut),"c",NSEvent.ModifierFlags.option),
        ("All",#selector(PopUpWithStatusFilter.showAll),"a",NSEvent.ModifierFlags.option),
        ("Named",#selector(PopUpWithStatusFilter.showNamed),"n",NSEvent.ModifierFlags.option),
        ("Duplicated",#selector(PopUpWithStatusFilter.showDuplicated),"D", NSEvent.ModifierFlags.option),
        ("Matches",#selector(PopUpWithStatusFilter.showMatchingCurrent),"m", NSEvent.ModifierFlags.option),
        ("Next Duplicate",#selector(PopUpWithStatusFilter.showDuplicatedMatch),"N",NSEvent.ModifierFlags.option),
        ("Next Different Duplicate",#selector(PopUpWithStatusFilter.showNextDifferentDuplicatedMatch),"D",[NSEvent.ModifierFlags.command]),
        ("All Duplicates",#selector(PopUpWithStatusFilter.showAllDuplicated),"A",NSEvent.ModifierFlags.option),
        ("Titled",#selector(PopUpWithStatusFilter.showTitled),"t",NSEvent.ModifierFlags.option),
        ("Reload",#selector(PopUpWithStatusFilter.reloadCache),"r",NSEvent.ModifierFlags.option),
        ("Delete",#selector(PopUpWithStatusFilter.deleteSelection),"x",NSEvent.ModifierFlags.option),
        ("Delete and Next Duplicate", #selector(PopUpWithStatusFilter.deleteSelectionAndFindNextDuplicate),"X",NSEvent.ModifierFlags.option)
    ])
    self.autoenablesItems = false
    self.isEnabled = false
  }
  
  private var firstDeletedIndex: Int? = nil
  
  typealias MatchStatus = (_ arrayIndex: Int)->Bool
  private func setVisibilty(isHidden hideTest: MatchStatus)
  {
    for index in 0..<self.itemArray.count
    {
//      print("hide test result for \(self.itemArray[index].attributedTitle!.string) is \(hideTest(index))")
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
  
  // Hide everthing that does not match entered string case insensitively
  private func doesEpisodeTitleContainString(_ index:Int, target:String) -> Bool {
    var display: Bool = false
    // make case insensitive
    let matchTo = target.uppercased()
    if let summary = summaryOf(index) {
      let itemEpisodeTitleString = summary.episodeTitle.uppercased()
      display = itemEpisodeTitleString.contains(matchTo)
    }
    return !display
  }
  
  /// remove (nnn) tail from string - (nnn) marks full time/date/station duplication
  private func removeCountField(from: String) -> String
  {
    // extract duplication count from name
    if let tailString = from.components(separatedBy: "(").last
    {
      // should now be "nnnn)"
      let numericPart = tailString.dropLast()
      
      // if we got a valid number, remove the appendage
      if let _ = Int(numericPart)
      {
        if let regex = try? NSRegularExpression(pattern: " \\([1-9]*\\)$", options: .caseInsensitive) {
          let stringRange = NSRange.init(location: 0, length: from.count)
          let modString = regex.stringByReplacingMatches(in: from, options: [], range: stringRange, withTemplate: "")
          print("made " + modString + " from " + from)
          return modString
        }
      }
    }
    return from
  }
  
  /// Create a limited summary of the recording
  
  private func summaryOf(_ index: Int, target:String = "") -> eitSummary?
  {
    guard index >= 0 && index < self.itemArray.count else { return nil }
    // make case insensitive
    let matchTo = target.uppercased()
    let itemString = removeCountField(from: self.itemArray[index].attributedTitle!.string.uppercased())
    if itemString.contains(matchTo) || target == "" {
      // extract details from attributed title
      let nameFields = itemString.split(separator: "-", maxSplits: 3, omittingEmptySubsequences: false)
      if nameFields.count >= 3 {
//        let channel = String(nameFields[1]).trimmingCharacters(in: .whitespaces)
        let programName = String(nameFields[2]).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ConstsCuts.CUTS_SUFFIX.uppercased(), with: "")
        // extract episode title from eit
        // load the eit file
        if let baseNameURL = parentViewController?.filelist[index].replacingOccurrences(of: ConstsCuts.CUTS_SUFFIX, with: "")
        {
          let movieName = baseNameURL.replacingOccurrences(of: "file://", with: "").removingPercentEncoding
          
          var eit = EITInfo()
          if let EITData = Recording.loadRawDataFrom(file: movieName!+ConstsCuts.EIT_SUFFIX) {
            if let eitInfo=EITInfo(data: EITData) {
              eit = eitInfo
            }
            return( eitSummary(/* channel: channel,  */ programTitle: programName, episodeTitle: eit.episodeText.lowercased()) )
          }
        }
      }
    }
    return nil
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
  
  /// Hide everything except those which are duplicate recordings.
  /// Duplicates are defined as those on same channel, same program title and same episode title
//  @objc private func showDuplicated()
//  {
//    setVisibilty(isHidden: {index in return isRecordingDuplicated(index, target: text)})
//  }

  /// For selected movie, trigger a reload of cached data (typically needed due to external change that cannot be observed)
  @objc private func reloadCache()
  {
    if let parent = self.parentViewController {
      parent.reloadCache(self.selectedItem!)
    }
  }
  
  /// filter by name contents
  @objc private func showNamed()
  {
    var subItem: String?
    let textField = NSTextField(frame: NSRect(x: 0.0, y: 0.0, width: 80.0, height: 24.0))
    let alert = NSAlert()
    alert.window.title = "Filter by Name"
    alert.messageText = "Enter string to filter list (case insensitive)"
    let currentItemText = self.selectedItem?.attributedTitle?.string
    if let items = currentItemText?.split(separator: "-", maxSplits: 3, omittingEmptySubsequences: false) {
      if items.count == 3 {
        subItem = String(items.last!)
      }
      else if items.count == 4 {
        subItem = String(items[items.count-2]) // second last
      }
      else { // not enough item to guess
        subItem = currentItemText
      }
    }
//    if let defaultItem = currentItemText?.split(separator: "-", maxSplits: 2, omittingEmptySubsequences: false).last ?? nil
    if let defaultItem = subItem
    {
      var defaultText = String(defaultItem.replacingOccurrences(of: ConstsCuts.CUTS_SUFFIX, with: ""))
      defaultText = defaultText.trimmingCharacters(in: .whitespaces)
      textField.stringValue = alert.messageText
      textField.sizeToFit()
      textField.stringValue = defaultText
    }
    //    alert.informativeText = "Enter string to match"
    alert.alertStyle = NSAlert.Style.informational
    alert.accessoryView = textField
    alert.runModal()
    setVisibilty(isHidden: {index in  return doesTitleContainString(index, target: textField.stringValue)})
  }
  
  /// filter by single name, contents and is same episode title
  @objc private func showMatchingCurrent()
  {
    var programName:String?
    let currentItemText = self.selectedItem?.attributedTitle?.string
    if let defaultItem = currentItemText?.split(separator: "-", maxSplits: 3, omittingEmptySubsequences: false).last ?? nil
    {
      programName = String(defaultItem.replacingOccurrences(of: ConstsCuts.CUTS_SUFFIX, with: ""))
      programName = programName!.trimmingCharacters(in: .whitespaces)
    }
    
    guard programName != nil else { return }
    
    var summaries = [eitSummary]()
    var summaryDictionary = [Int:eitSummary]()
    var duplicated = [eitSummary]()
    
    let programSummary = summaryOf(self.indexOfSelectedItem, target: programName!)
    
    guard programSummary != nil else { return }
    
    // Build three tables.  First a matchable summary of all movies that have
    // sufficient data to summarise.  Second a array of all those matched to the
    // full summary table (duplicated).  Thirdly a dictionary keyed on the array
    // index to eventually get a list of all indices with a matching summary
    // all duplicates
    if let movieCount = parentViewController?.filelist.count {
      for movieIndex in 0 ..< movieCount {
        if let summary = summaryOf(movieIndex, target: programName!) {
          if !duplicated.contains(summary) && summaries.contains(summary) {
            duplicated.append(summary)
          }
          summaries.append(summary)
          summaryDictionary[movieIndex] = summary
        }
      }
    }
    setVisibilty(isHidden: {index in  return !doesEntryMatch(index, summary: summaryDictionary[index] ?? nil, target: programSummary!)})
    filter!.selectFirst()

  }
  
  /// filter by all name contents and is same episode title
  @objc private func showDuplicated()
  {

    let textField = NSTextField(frame: NSRect(x: 0.0, y: 0.0, width: 80.0, height: 24.0))
    textField.stringValue = ""
    let alert = NSAlert()
//    alert.window.title = "Filter by Name and Dupicate Episode on same channel"
    alert.messageText = "Enter string to filter list (case insensitive)"
    let currentItemText = self.selectedItem?.attributedTitle?.string
    if let defaultItem = currentItemText?.split(separator: "-", maxSplits: 3, omittingEmptySubsequences: false).last ?? nil
    {
      var defaultText = String(defaultItem.replacingOccurrences(of: ConstsCuts.CUTS_SUFFIX, with: ""))
      defaultText = defaultText.trimmingCharacters(in: .whitespaces)
      textField.stringValue = alert.messageText
      textField.sizeToFit()
      textField.stringValue = defaultText
    }
//    alert.alertStyle = NSAlert.Style.informational
//    alert.accessoryView = textField
//    alert.runModal()
/*
    var summaries = [eitSummary]()
    var summaryDictionary = [Int:eitSummary]()
    var duplicated = [eitSummary]()
    
    // Build three tables.  First a matchable summary of all movies that have
    // sufficient data to summarise.  Second a array of all those matched to the
    // full summary table (duplicated).  Thirdly a dictionary keyed on the array
    // index to eventually get a list of all indices with a matching summary
    // all duplicates
    if let movieCount = parentViewController?.filelist.count {
      for movieIndex in 0 ..< movieCount {
        if let summary = summaryOf(movieIndex, target: textField.stringValue) {
          if !duplicated.contains(summary) && summaries.contains(summary) {
            duplicated.append(summary)
          }
          summaries.append(summary)
          summaryDictionary[movieIndex] = summary
        }
      }
    }
 */
    let (summaryDictionary,duplicated) = getDuplicatedSummariesFor(textField.stringValue)
    setVisibilty(isHidden: {index in  return !isEntryInDuplicates(index, summary: summaryDictionary[index] ?? nil, duplicates: duplicated)})
  }
  
  /// Utility to assist finding duplicate recordings.  It creates a summary of the EIT data for each recording.
  /// It then checks if a matching summary exists.  If it does, then it add the current summary to the
  /// duplicated array.  It always add the summary to the summary array and creates a dictionary
  /// entry with the index of the recording as the key.  The caller can use the duplicated table entry to get the
  /// keys (indices of the recording that match)
  /// - Parameter name: the name of the program to look for, which is the recording file name with all
  /// the date, station id, etc removed.  Eg "The Orville"
  /// - Returns: tuple of the summary dictionary and the array of duplicated recordings.
  private func getDuplicatedSummariesFor(_ name:String) -> (summaryDictionary:[Int:eitSummary],duplicated:[eitSummary])
  {
    var summaries = [eitSummary]()
    var summaryDictionary = [Int:eitSummary]()
    var duplicated = [eitSummary]()
    
    // Build three tables.  First a matchable summary of all movies that have
    // sufficient data to summarise.  Second a array of all those matched to the
    // full summary table (duplicated).  Thirdly a dictionary keyed on the array
    // index to eventually get a list of all indices with a matching summary
    // all duplicates
    if let movieCount = parentViewController?.filelist.count {
      for movieIndex in 0 ..< movieCount {
        if let summary = summaryOf(movieIndex, target: name) {
          if !duplicated.contains(summary) && summaries.contains(summary) {
            duplicated.append(summary)
          }
          summaries.append(summary)
          summaryDictionary[movieIndex] = summary
        }
      }
    }
    return (summaryDictionary,duplicated)
  }
  
  private func getListOfNames() -> [String] {
    var listOfRecordingNames = [String]()
    if let movieCount = parentViewController?.filelist.count {
      guard let list = self as NSPopUpButton? else { return listOfRecordingNames }
      for movieIndex in 0 ..< movieCount {
        let menuName = list.item(at: movieIndex)!.title
        var recordingName = menuName
        if (menuName.contains( " - ")) {
          let components = menuName.split(separator: "-", maxSplits: 3, omittingEmptySubsequences: false)
          if components.count >= 3 {
            recordingName = String(components[2])
          }
          else {
            recordingName = String(components[0])
          }
        }
        recordingName = recordingName.trimmingCharacters(in: .whitespaces)
        recordingName = recordingName.replacingOccurrences(of: ConstsCuts.CUTS_SUFFIX, with: "")
        if !listOfRecordingNames.contains(recordingName) {
          listOfRecordingNames.append(recordingName)
        }
      }
    }
    return listOfRecordingNames.sorted()
  }
  
  /// filter by all name contents and is same episode title
  @objc private func showAllDuplicated()
  {
    let namesList = getListOfNames()
    guard !namesList.isEmpty else { return }
    var summaryDictionaryAll = [Int:eitSummary]()
    var duplicatedAll = [eitSummary]()
    for name in namesList {
      let (dictionary, duplicates) = getDuplicatedSummariesFor(name)
      if !dictionary.isEmpty {
        summaryDictionaryAll.merge(dictionary, uniquingKeysWith: { (v1, _) in v1})
        duplicatedAll += duplicates
      }
    }
    setVisibilty(isHidden: {index in  return !isEntryInDuplicates(index, summary: summaryDictionaryAll[index] ?? nil, duplicates: duplicatedAll)})
  }

  /// filter by all name contents and is same episode title
  @objc private func showDuplicatedMatch()
  {
      showDuplicated()
      showMatchingCurrent()
  }
 
  /// Select first different visible item in popUp start at "from" Index
  /// - parameter from: index into item array
  /// - returns: success of finding at item to select
  private func selectFirstDifferentVisible(from current: Int) -> Bool
  {
    guard current >= 0 else { return false }
    guard let list = self as NSPopUpButton? else { return false }
    
    let currentSummary = summaryOf(current)
    var success = false
    for itemIndex in current ..< list.itemArray.count {
      if list.itemArray[itemIndex].isHidden {
        continue
      }
      else {
        list.selectItem(at: itemIndex)
        let nextSummary = summaryOf(itemIndex)
        if (nextSummary != currentSummary)
        {
          NotificationCenter.default.post(name: Notification.Name.PopUpHasChanged, object: nil)
          success = true
          break
        }
      }
    }
    return success
  }

  /// delete current selected recording
  @objc private func deleteSelection()
  {
    if let vc = parentViewController {
      if firstDeletedIndex == nil {
        firstDeletedIndex = vc.currentFile.indexOfSelectedItem
      }
      vc.selectFile(self)
      vc.deleteRecording(vc.deleteRecordingButton)
    }
  }
  
  @objc private func deleteSelectionAndFindNextDuplicate()
  {
    deleteSelection()
    showDuplicatedMatch()
  }
  
  /// filter:
  /// set list to all duplicated retaining current selection
  /// if possible, step forward until the selection does not match the
  /// current highlighted selection.
  /// The purpose is to skip forward stepping over duplicates when the duplicates
  /// are, typically, an SD and HD recording of the same program
  @objc private func showNextDifferentDuplicatedMatch()
  {
    let vc = parentViewController!
    if let oldestDeletedIndex = firstDeletedIndex {
      vc.currentFile.selectItem(at: oldestDeletedIndex)
    }
    firstDeletedIndex = nil
    showDuplicated()
    if (vc.nextButton.isEnabled) {
      if !selectFirstDifferentVisible(from: vc.currentFile.indexOfSelectedItem)
      {
        NSSound.beep()
      }
    }
    else {
      NSSound.beep()
    }
    showMatchingCurrent()
  }
  
  /// Check if given index entry is in the duplicates table
  private func isEntryInDuplicates(_ index: Int, summary: eitSummary?, duplicates: [eitSummary]) -> Bool {
    guard (summary != nil) else {return false}
    let duplicate = duplicates.contains(summary!)
    // print("Returning \(duplicate) for \(summary!)")
    return duplicate
  }
  
  /// Check if given index entry is in the duplicates table
  private func doesEntryMatch(_ index: Int, summary: eitSummary?, target: eitSummary) -> Bool {
    guard (summary != nil) else {return false}
    let isDuplicated = summary == target
    // print("Returning \(isDuplicated) for \(summary!)")
    return isDuplicated
  }
  
  /// Check if program title matches query text
  @objc private func showTitled() {
    let textField = NSTextField(frame: NSRect(x: 0.0, y: 0.0, width: 80.0, height: 24.0))
    let alert = NSAlert()
    alert.window.title = "Filter by Episode Title"
    alert.messageText = "Enter string to filter list (case insensitive)"
//    let currentItemText = self.selectedItem?.attributedTitle?.string
    if let currentItemText = summaryOf(self.indexOfSelectedItem, target: "")?.episodeTitle
    {
      textField.stringValue = alert.messageText
      textField.sizeToFit()
      textField.stringValue = currentItemText.trimmingCharacters(in: .whitespaces)
    }
    else {
      textField.stringValue = "No title"
    }
    //    alert.informativeText = "Enter string to match"
    alert.alertStyle = NSAlert.Style.informational
    alert.accessoryView = textField
    alert.runModal()
    
    setVisibilty(isHidden: {index in  return doesEpisodeTitleContainString(index, target: textField.stringValue)})

  }
  
  // Determine if menu item should be enabled or not
  @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    //    print("In function "+#file+"/"+#function)
    return filter?.filterMenuEnabled ?? false
  }
}
