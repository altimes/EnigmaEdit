//
//  RecordingManagementVCExtn.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 19/1/17.
//  Copyright © 2017 Alan Franklin. All rights reserved.
//

//  File to extract Recording Management code out of the ViewController

import Foundation
import AppKit

typealias resultAndMessage = (status: Bool, message:String)


extension ViewController
{
  /// Create a move target that does not already exist
  ///  - parameter sourceMoviePath: path of the source recording
  ///  - parameter trashDirectory: path of the trash directory
  ///  - returns: target path name for moving to trash
  func safeMoveTarget(sourceMoviePath: String, to trashDirectory:String ) -> String
  {
    var duplicate: Int = 0
    let targetComponents = sourceMoviePath.components(separatedBy: "/")
    var targetName = targetComponents[targetComponents.count-1]
    var targetPath = trashDirectory+"/"+targetName
    while (FileManager().fileExists(atPath: targetPath)) {
      duplicate += 1
      var nameComponents = targetName.components(separatedBy: ".")
      let lastIndex = nameComponents.count - 1
      if (nameComponents[lastIndex] == "ts" || nameComponents[lastIndex] == "eit")
      {
        nameComponents[lastIndex-1] = nameComponents[lastIndex-1]+"(\(duplicate))"
        targetName = nameComponents.joined(separator: ".")
      }
      else {
        nameComponents[lastIndex-2] = nameComponents[lastIndex-2]+"(\(duplicate))"
        targetName = nameComponents.joined(separator: ".")
      }
      targetPath = trashDirectory+"/"+targetName
    }
    return targetPath
  }
  
  /// Locally move recording to trash folder
  /// If it fails on any element, attempt to unwind what has
  /// been done.
  /// - parameter recording: the recording to be trashed
  /// - returns: status and message touple
  func localMoveToTrash(recording: Recording) -> resultAndMessage
  {
    var resultURL = NSURL(string: "")
    var doneURL : [NSURL] = Array(repeating: resultURL!, count: recording.movieFiles.count)
    var result = resultAndMessage(true,"")
    let fromPaths = recording.movieFiles
    disconnectCurrentMovieFromGUI()
    for index in 0..<fromPaths.count {
      let fileURL = URL(fileURLWithPath: fromPaths[index])
      do {
        try FileManager().trashItem(at: fileURL, resultingItemURL: &resultURL )
        doneURL[index] = resultURL!
      }
      catch _ {
        // try to put back already trashed element of recording
        result.status = false
        result.message = "Move to Trash failed for \(recording.movieShortName!)"
        result.message = "\nMove to Trash Failed for component \(fromPaths[index])"
        for doneIndex in 0..<index
        {
          let fromURL = doneURL[doneIndex] as URL
          let toURL = URL(fileURLWithPath: fromPaths[doneIndex])
          do {
            try FileManager().moveItem(at: fromURL, to: toURL)
          }
          catch _ {
            // TODO: put a message, beep, pause here (modal dialog ?)
            result.message += "\nPartial restore failed for \(doneURL[doneIndex])"
          }
        }
        break
      }
    }
    return result
  }
  
  
  /// Delete from the PVR and move to its trash folder
  // TODO: implement PutBack code similar to local operation, thinking about NAS use cases
  // TODO: for Enigma boxes, implement as ssh operation (performance)
  func remoteMoveToTrash(recording: Recording) -> resultAndMessage
  {
    // FIXME: fails when non-root directory is base sourceMoviePath
    var result = resultAndMessage(true,"")
    // look for .Trash below firstdirectory below mount point
    let mountPath = generalPrefs.systemConfig.pvrSettings[pvrIndex].cutLocalMountRoot.components(separatedBy: "/")
    let pathElements = selectedDirectory.components(separatedBy: "/")
    let rootElements = pathElements[0 ... mountPath.count]
    let rootPath = rootElements.joined(separator: "/")
    let trashDirectory = rootPath + "/" + trashDirectoryName
    if FileManager().fileExists(atPath: trashDirectory) {
      let fromPaths = recording.movieFiles
      disconnectCurrentMovieFromGUI()
      //      print ("found remote PVR .Trash")
      let toPaths = fromPaths.map { self.safeMoveTarget(sourceMoviePath: $0, to: trashDirectory) }
      //      print (fromPaths)
      //      print (toPaths)
      for index in 0..<fromPaths.count {
        do {
          try FileManager().moveItem(atPath: fromPaths[index], toPath: toPaths[index])
        }
        catch _ {  // delete failed for item
          result.message = "Move to Trash Failed for \(recording.movieShortName!)"
          result.message = "\nMove to Trash Failed for \(fromPaths[index])->\(toPaths[index])"
          result.status = false
          // TODO: attempt recovery from partial failed trashing
        }
      }
    }
    else  // no such file
    {
      result.message = String(format: logMessage.noTrashFolder, trashDirectory)
      result.status = false
    }
    return result
  }
  
  /// delete a recording (local or remote) - really move to trash directory
  func deleteRecording(recording movie:Recording, with docController:NSDocumentController) -> resultAndMessage
  {
    var result  = resultAndMessage(false, "")
    
    let cutsNamePath = movie.movieName!+ConstsCuts.CUTS_SUFFIX
    let fileURL = URL(fileURLWithPath: cutsNamePath)
    if  let doc = try? TxDocument(contentsOf: fileURL, ofType: ConstsCuts.CUTS_SUFFIX)
    {
      docController.removeDocument(doc)
    }
    
    if (isRemote) {
      result = remoteMoveToTrash(recording: movie)
    }
    else {
      result = localMoveToTrash(recording: movie)
    }
    
    if (result.status) {
      // remove from filelist and rebuild gui elements selecting either next (or previous if no next)
      // FIXME: what to do when removing the only file
      var nextIndexToSelect = filelistIndex
      mouseDownPopUpIndex = filelistIndex
      filelist.remove(at: filelistIndex)
      namelist.remove(at: filelistIndex)
      currentFile.removeItem(at: filelistIndex)
      
      // bring index into sync with model (reducing by 1 if we are removing the tail of the list
      nextIndexToSelect = (nextIndexToSelect < filelist.count) ? nextIndexToSelect : nextIndexToSelect-1
      if (nextIndexToSelect >= 0) {
        // simulate mouse down
        // to ensure that select file perceives a "change" when we have reduced the array and are reselecting the same index
        if (mouseDownPopUpIndex! == nextIndexToSelect) { mouseDownPopUpIndex! += 1 }
        currentFile.selectItem(at: nextIndexToSelect)
        selectFile(currentFile)
        currentFile.isEnabled = true
        setPrevNextButtonState(filelistIndex)
      }
    }
    return result
  }
  
  /// Query the PVR (or directory) for a recursive count of the files with xxx extension.
  /// Written to do a external shell query and then process the resulting message
  /// eg. countFilesWithSuffix(".ts", "/hdd/media/movie")
  /// Used to support sizing of progress bar for background tasks.
  /// If remote query fails for any reason, function returns default value of 100
  /// - parameter fileSuffix: tail of file name, eg .ts, .ts.cuts, etc
  /// - parameter belowPath: root of path to recursively search
  
  func countFilesWithSuffix(_ fileSuffix: String, belowPath: String) -> Int?
  {
    let defaultCount: Int? = nil
    var searchPath: String
    // use a task to get a count of the files in the directory
    // this does pick up current recordings, but we only later look for "*.cuts" of finished recordings
    // so no big deal, this is just the quickest sizing that I can think of for setting up a progress bar
    // CLI specifics are for BeyonWiz Enigma2 BusyBox 4.4
    let fileCountTask = Process()
    let outPipe = Pipe()
    let errPipe = Pipe()
    let localMountRoot = isRemote ? generalPrefs.systemConfig.pvrSettings[pvrIndex].cutLocalMountRoot : mcutConsts.localMount
    if (belowPath.contains(localMountRoot) && isRemote) {
      searchPath = belowPath.replacingOccurrences(of: generalPrefs.systemConfig.pvrSettings[pvrIndex].cutLocalMountRoot, with: generalPrefs.systemConfig.pvrSettings[pvrIndex].cutRemoteExport)
      fileCountTask.launchPath = systemSetup.pvrSettings[pvrIndex].sshPath
      fileCountTask.arguments = [systemSetup.pvrSettings[pvrIndex].remoteMachineAndLogin, "/usr/bin/find \"\(searchPath)\" -regex \"^.*\\\(fileSuffix)$\" | wc -l"]
    }
    else {
      // TODO: look at putting this where the user can change it
      fileCountTask.launchPath = mcutConsts.shPath
      fileCountTask.arguments = ["-c", "/usr/bin/find \"\(belowPath)\" -regex \"^.*\\\(fileSuffix)$\" | wc -l"]
      searchPath = belowPath
    }
    fileCountTask.standardOutput = outPipe
    fileCountTask.standardError = errPipe
    fileCountTask.launch()
    let handle = outPipe.fileHandleForReading
    let data = handle.readDataToEndOfFile()
    let errHandle = errPipe.fileHandleForReading
    let errData = errHandle.readDataToEndOfFile()
    if (errData.count > 0), let resultString = String(data: errData, encoding: String.Encoding.utf8) {
        self.statusField.stringValue = resultString
        NSSound.beep()
    }
    if let resultString = String(data: data, encoding: String.Encoding.utf8)
    {
      // trim to just the text and try converting to a number
      let digitString = resultString.trimmingCharacters(in: CharacterSet(charactersIn: " \n"))
      if let fileCount = Int(digitString) {
        return fileCount
      }
      else {
        let message = String.localizedStringWithFormat(StringsCuts.FAILED_COUNTING_FILES, digitString)
        self.statusField.stringValue = message
      }
    }
    return defaultCount
  }
}
