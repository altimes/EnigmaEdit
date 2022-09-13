//
//  DisplayEITEditor.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 24/10/21.
//  Copyright © 2021 Alan Franklin. All rights reserved.
//

import Foundation

func displayEITEditor(for name: String, vc: ViewController) {
  let editor = Process()
  editor.launchPath = "/Applications/EITEdit_24.app/Contents/MacOS/EITEdit_24"
  editor.arguments = [name+".eit"]
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
