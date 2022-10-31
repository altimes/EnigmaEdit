//
//  ButtonGrid.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 15/10/2022.
//  Copyright © 2022 Alan Franklin. All rights reserved.
//

import SwiftUI

struct ButtonGrid: View {
  var list: [List<ButtonParameters>]
  var longestList: Int {
    var longest = 0
    for entry in list {
      longest = max(longest, entry.count())
    }
    return longest
  }
  var body: some View {
    VStack {
      gridView(list: list)
    }
  }
  
  func gridView(list: [List<ButtonParameters>]) -> some View
  {
    VStack(alignment: .leading, spacing:3) {
      ForEach((0..<list.count), id: \.self) { rowNumber in
        rowView(list: list[rowNumber])
      }
    }
    .frame(maxWidth: 200)
  }
  
  func rowView (list: List<ButtonParameters>) -> some View
  {
    //    let myColor = Color.init(red: 0, green: 200, blue: 240)
    return HStack(spacing: 3) {
      ForEach(arrayFromList(list: list), id:\.self)  { entry in
        Button(action: entry.action,
               label: {
          HStack {
            if let name = entry.symbol { Image(systemName: name) }
            Text(entry.title)
          }
          .frame(minWidth: 50)
          //                  .background(Color.yellow.opacity(0.5))
          //                  .foregroundColor(Color.black)
        }
        )
      }
      .buttonStyle(CustomizedStyle())
      if list.count() < longestList {
        Spacer()
      }
    }
  }
  
  func arrayFromList(list: List<ButtonParameters>) -> [ButtonParameters]
  {
    var array = [ButtonParameters]()
    list.forEach { button in
      array.append(button)
    }
    return array
  }
  
}

struct ButtonGrid_Previews: PreviewProvider {
  static var title = "A button"
  static func printme() {
    print(title)
  }
  static let columns = 2
  static var previews: some View {
    ButtonGrid(list: buttonList())
  }
  
  //  static func buttonList() -> [ButtonRow]
  //  {
  //    let rowCount = 5
  //    let columnCount = 2
  //    var columns = [ButtonRow]()
  //    var rows = ButtonRow(row: [ButtonParameters]())
  //    for i in 0..<rowCount {
  //      for j in 0..<columnCount {
  //        let entry = ButtonParameters(title: "\(i):\(j)", action: {print("index = \(j*columnCount+i)")})
  //        rows.row.append(entry)
  //      }
  //      columns.append(rows)
  //      rows.row.removeAll()
  //    }
  //    return columns
  //  }
  
  static func directionSymbolForIndex(_ index: Int) -> String {
    return (index<=0) ? "arrowtriangle.backward" : "arrowtriangle.forward"
  }
  
  static func buttonList() -> [List<ButtonParameters>]
  {
    let rowCount = 5
    let columnCount = 2
    var arrayOfLists = [List<ButtonParameters>]()
    var list = List<ButtonParameters>()
    for i in 0..<rowCount {
      for j in 0..<columnCount {
        let entry = ButtonParameters(title: "\(i):\(j)", symbol: directionSymbolForIndex(j)  ,action: {print("index = \(j*columnCount+i)")})
        list.append(entry)
      }
      arrayOfLists.append(list)
      list = List<ButtonParameters>()
    }
//    list.append(ButtonParameters(title: "hello", action: {}))
//    list.append(ButtonParameters(title: "world a very long button that will wrap", action: {}))
//    list.append(ButtonParameters(title: "wonderfull life", action: {}))
    arrayOfLists.append(list)
//    list = List<ButtonParameters>()
//    list.append(ButtonParameters(title: "single", action: {}))
    arrayOfLists.append(list)
    return arrayOfLists
  }
}

struct ButtonRow {
  var row: [ButtonParameters]
}

struct ButtonParameters: Hashable {
  static func == (lhs: ButtonParameters, rhs: ButtonParameters) -> Bool {
    lhs.title == rhs.title
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(title)
  }
  
  var title: String
  var symbol: String?
  var action: () -> Void
}

// from: https://www.swiftbysundell.com/articles/picking-the-right-data-structure-in-swift/

struct List<Value> {
  private(set) var head: Node?
  private(set) var tail: Node?
}

extension List {
  class Node {
    var value: Value
    fileprivate(set) weak var prev: Node?
    fileprivate(set) var next: Node?
    
    init(value: Value, prev: Node? = nil, next: Node? = nil) {
      self.value = value
      self.prev = prev
      self.next = next
    }
  }
}

extension List: Sequence {
  func makeIterator() -> AnyIterator<Value> {
    var node = head
    
    return AnyIterator {
      let value = node?.value
      node = node?.next
      return value
    }
  }
}

extension List {
  @discardableResult
  mutating func append( _ newNodeValue: Value) -> Node
  {
    let newNode = Node(value: newNodeValue)
    newNode.prev = tail
    tail?.next = newNode
    tail = newNode
    if head == nil {
      head = newNode
    }
    return newNode
  }
}

extension List {
  mutating func removeNode(_ node: Node)
  {
    node.prev?.next = node.next
    node.next?.prev = node.prev
    
    /// use triple = to compare classes on identity not content
    if node === head {
      head = node.next
    }
    
    if node === tail {
      tail = node.prev
    }
    
    // disconnect and allow to fade away
    node.next = nil
    node.prev = nil
  }
}

extension List {
  func count() -> Int{
    var nodeCount = 0
    guard head != nil else { return nodeCount }
    self.forEach { _ in
      nodeCount += 1
    }
    return nodeCount
  }
}

struct FixedButtonStyle: ButtonStyle {
  typealias Body = Button
  
  func makeBody(configuration: Self.Configuration) -> some View {
    return configuration
      .label
      .background(Color.buttonBackgroundColor)
  }
}

struct CustomizedStyle: ButtonStyle {
  typealias Body = Button
  func makeBody(configuration: Configuration) -> some View {
    print(configuration.label)
    return configuration
      .label
      .foregroundColor(Color.white)
      .background(Color.buttonBackgroundColor.cornerRadius(5))
    //          .background(content: {
    //            RoundedRectangle(cornerRadius: 5)
    //              .stroke(lineWidth: 2.0)
    //              .foregroundColor(Color.buttonForegroundColor)
    //              .background(content: {Color.buttonBackgroundColor})
    //          })
    
    //          .cornerRadius(5.0)
    //          .clipShape(RoundedRectangle(cornerRadius: 5))
  }
}

extension ShapeStyle where Self == Color {
  static var buttonBackgroundColor:Color { Color("TestColor") }
  static var buttonForegroundColor:Color { Color(red: 0.6, green: 0.5, blue: 0.9) }
}

extension ShapeStyle where Self == Color {
  static var vinceBackground: Color { Color( red: 0.74, green: 0.01, blue: 0.98) }
}


