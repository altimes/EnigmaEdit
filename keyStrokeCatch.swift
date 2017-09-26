//
//  KeyStrokeCatch.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 30/7/17.
//  Copyright © 2017 Alan Franklin. All rights reserved.
//

import Foundation

let leftArrowKey:UInt16 = 123
let rightArrowKey:UInt16 = 124

protocol KeyStrokeCatch {
  func didPressLeftArrow()
  func didPressRightArrow()
}
