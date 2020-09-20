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
        ("Raw",#selector(PopUpWithStatusFilter.showRaw)),
        ("Partial",#selector(PopUpWithStatusFilter.showPartial)),
        ("Ready",#selector(PopUpWithStatusFilter.showReady)),
        ("Cut",#selector(PopUpWithStatusFilter.showCut)),
        ("All",#selector(PopUpWithStatusFilter.showAll)),
        ("Named",#selector(PopUpWithStatusFilter.showNamed)),
        ("Duplicated",#selector(PopUpWithStatusFilter.showDuplicated)),
        ("Matches",#selector(PopUpWithStatusFilter.showMatchingCurrent)),
        ("Next Duplicate",#selector(PopUpWithStatusFilter.showDuplicatedMatch)),
        ("Titled",#selector(PopUpWithStatusFilter.showTitled)),
        ("Reload",#selector(PopUpWithStatusFilter.reloadCache))
    ])
    self.autoenablesItems = false
    self.isEnabled = false
  }
  
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
  

  /// Create a limited summary of the recording
  
  private func summaryOf(_ index: Int, target:String = "") -> eitSummary?
  {
    guard index >= 0 && index < self.itemArray.count else { return nil }
    // make case insensitive
    let matchTo = target.uppercased()
    let itemString = self.itemArray[index].attributedTitle!.string.uppercased()
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
            return( eitSummary(/* channel: channel, */ programTitle: programName, episodeTitle: eit.episodeText) )
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
    let textField = NSTextField(frame: NSRect(x: 0.0, y: 0.0, width: 80.0, height: 24.0))
    let alert = NSAlert()
    alert.window.title = "Filter by Name"
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
    setVisibilty(isHidden: {index in  return !isEntryInDuplicates(index, summary: summaryDictionary[index] ?? nil, duplicates: duplicated)})
  }
  
    /// filter by all name contents and is same episode title
    @objc private func showDuplicatedMatch()
    {
        showDuplicated()
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
