//
//  CutsUndoRedo.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 4/1/17.
//  Copyright © 2017 Alan Franklin. All rights reserved.
//

import Foundation

class CutsEditCommnands {
  var commandStack = [CutsFile]()
  var undoRedoPointer: Int = -1
  
  init(_ initialCuts: CutsFile) {
    commandStack.append(initialCuts.copy() as! CutsFile)
    undoRedoPointer = 0
//    print("init:Appended, pointer is \(undoRedoPointer)")
  }
  
  /// record cuts before every change
  func add(state: CutsFile) {
    // don't push duplicate on statck (initial condition)
    guard (!state.isEqual(commandStack.last)) else { return }
    if undoRedoPointer+1 == commandStack.count
    {
      // top of stack, append a new entry
      commandStack.append(state.copy() as! CutsFile)
      undoRedoPointer += 1
//      print("add:Appended, pointer is \(undoRedoPointer):\(state):\(commandStack.last)")
    }
    else  // change after an undo, so replace pointed to entry and prune
    {
      undoRedoPointer += 1
      commandStack[undoRedoPointer] = state.copy() as! CutsFile
      // remove any entries after this
      let subArray = commandStack[0...undoRedoPointer]
      commandStack = Array(subArray)
//      print("add:replaced and pruned, pointer is \(undoRedoPointer):\(state):\(commandStack.last)")
    }
  }
  
  /// get previous record cuts (Undo)
  func getPrevious() -> CutsFile? {
    var prevCuts: CutsFile?
    guard (undoRedoPointer > 0) else { return nil }
//    print(#function+", pointer before is \(undoRedoPointer):sent\(currentState)")
    undoRedoPointer -= 1
    prevCuts = commandStack[undoRedoPointer].copy() as? CutsFile
//    print(#function+", pointer after is \(undoRedoPointer):returned \(prevCuts)")
    return prevCuts
  }
  
  
//  func cuts(at index: Int) -> CutsFile? {
//    var cuts: CutsFile?
//    if index >= 0 && index <= undoRedoPointer {
//      cuts = commandStack[index]
//    }
//    else {
//      cuts  = nil
//    }
//    return cuts
//  }
  
  /// Support for Redo functionality. Retrieve "up" from
  /// current state if it exists.  Stack pointer is at
  /// previous valid state
  func next() -> CutsFile? {
    var cuts : CutsFile?
    if undoRedoPointer < commandStack.count-1
    {
      undoRedoPointer += 1
      cuts = commandStack[undoRedoPointer]
    }
    else {
      cuts = nil
    }
//    print(#function+", pointer is \(undoRedoPointer):returned \(cuts)")
    return cuts
  }
  
  /// Is redo possible
  var isRedoPossible: Bool
  {
    get {
      guard (commandStack.count > 1 ) else { return false }
      // gap between pointer and top of stack needs to be greater than 0
      let oneBasedPointer = undoRedoPointer+1
      let gap = commandStack.count - oneBasedPointer
      return gap > 0
    }
  }
  
  // check if we are at the sentinel state
  var undoEmpty: Bool {
    get {
      return commandStack.count > 1 && undoRedoPointer > 0
    }
  }
  
}
