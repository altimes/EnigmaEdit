//
//  DisplayEditor.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 25/10/21.
//  Copyright © 2021 Alan Franklin. All rights reserved.
//

import Foundation

func displayEditor(for name: String, type suffix:String, vc: ViewController) {
  var app:String = ""
  let editor = Process()
  if suffix == ConstsCuts.META_SUFFIX
  {
    app = "/Applications/MetaEdit_20.app/Contents/MacOS/MetaEdit_20"
  }
  else if suffix == ConstsCuts.EIT_SUFFIX {
    app = "/Applications/EITEdit_24.app/Contents/MacOS/EITEdit_24"
  }
  guard app != "" else { return }
  editor.launchPath = app
  editor.arguments = [name+suffix]
  //use pipe to get the execution program's output
  let pipe = Pipe()
  editor.standardOutput = pipe

  try! editor.run()
  editor.waitUntilExit()
  
  let debugData = pipe.fileHandleForReading.readDataToEndOfFile()
  print(">>>")
  print(String(data: debugData, encoding: .utf8)!)
  print("<<<")
  vc.reloadCache()
}
