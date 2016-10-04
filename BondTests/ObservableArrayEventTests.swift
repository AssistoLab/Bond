//
//  ObservableArrayOperationTests.swift
//  Bond
//
//  Created by Srđan Rašić on 06/08/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

import XCTest
@testable import Bond

enum Letters {
  case a
  case b
  case c
  case d
  case x
  case y
  case z
}

func ==(lsh: [ObservableArrayEventChangeSet], rhs: [ObservableArrayEventChangeSet]) -> Bool {
  if lsh.count != rhs.count {
    return false
  } else {
    for (l, r) in zip(lsh, rhs) {
      if !(l == r) {
        return false
      }
    }
    return true
  }
}

class ObservableArrayEventTests: XCTestCase {
  
  // Expected order: .Deletes, .Inserts, .Updates
  
  // Deletes are always indexed in the index-space of the original array
  //  -> Deletes are shifted by preceding inserts and deletes at lower indices
  // Deletes of updated items are substracted from updates set
  // Deletes of inserted items are substracted from inserts set
  // Deletes shift preceding inserts at higher indices

  // Inserts are always indexed in the index-space of the final array
  // -> Inserts shift preceding inserts at higher indices
  
  // Updates are always indexed in the index-space of the original array
  //  -> Updates are shifted by preceding inserts and deletes at lower indices
  // Updates of inserted items are annihilated

  
  // Single
  
  func testChangeSetInsert() {
    // 0 1 2 3 4
    // 0 A B C 1 2 3 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .insert(elements: [.a, .b, .c], fromIndex: 1)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.inserts([1, 2, 3])])
  }
  
  func testChangeSetDelete() {
    // 0 1 2 3 4
    // 0 - - - 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .remove(range: 1..<4)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.deletes([1, 2, 3])])
  }
  
  func testChangeSetUpdate() {
    // 0 1 2 3 4
    // 0 A B C 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .update(elements: [.a, .b, .c], fromIndex: 1)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.updates([1, 2, 3])])
  }
  
  
  // Insert followed by Insert
  
  func testChangeSetInsertInsertAtFront() {
    // 0 1 2 3 4
    // 0 A B C 1 2 3 4
    // 0 X Y A B C 1 2 3 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .insert(elements: [.a, .b, .c], fromIndex: 1),
      .insert(elements: [.x, .y], fromIndex: 1),
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.inserts([1, 2, 3, 4, 5])])
  }
  
  func testChangeSetInsertInsertAtMiddle() {
    // 0 1 2 3 4
    // 0 A B C 1 2 3 4
    // 0 A X Y B C 1 2 3 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .insert(elements: [.a, .b, .c], fromIndex: 1),
      .insert(elements: [.x, .y], fromIndex: 2),
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.inserts([1, 2, 3, 4, 5])])
  }
  
  func testChangeSetInsertInsertAtBack() {
    // 0 1 2 3 4
    // 0 A B C 1 2 3 4
    // 0 A B C X Y 1 2 3 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .insert(elements: [.a, .b, .c], fromIndex: 1),
      .insert(elements: [.x, .y], fromIndex: 4),
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.inserts([1, 2, 3, 4, 5])])
  }
  
  
  // Insert followed by Delete
  
  func testChangeSetInsertDeleteOverlapping() {
    // 0 1 2 3 4
    // 0 A B C 1 2 3 4
    // 0 - - C 1 2 3 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .insert(elements: [.a, .b, .c], fromIndex: 1),
      .remove(range: 1...2)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.inserts([1])])
  }
  
  func testChangeSetInsertDeleteOverlappingPartiallyFront() {
    // 0 1 2 3 4
    // 0 A B C 1 2 3 4
    // - - B C 1 2 3 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .insert(elements: [.a, .b, .c], fromIndex: 1),
      .remove(range: 0...1)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.deletes([0]), .inserts([0, 1])])
  }
  
  func testChangeSetInsertDeleteOverlappingPartiallyBack() {
    // 0 1 2 3 4
    // 0 A B C 1 2 3 4
    // 0 A B - - 2 3 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .insert(elements: [.a, .b, .c], fromIndex: 1),
      .remove(range: 3...4)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.deletes([1]), .inserts([1, 2])])
  }
  
  func testChangeSetInsertDeleteNoOverlappingFront() {
    // 0 1 2 3 4
    // 0 A B C 1 2 3 4
    // - A B C 1 2 3 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .insert(elements: [.a, .b, .c], fromIndex: 1),
      .remove(range: 0..<1)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.deletes([0]), .inserts([0, 1, 2])])
  }
  
  func testChangeSetInsertDeleteNoOverlappingBack() {
    // 0 1 2 3 4
    // 0 A B C 1 2 3 4
    // 0 A B C 1 - - 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .insert(elements: [.a, .b, .c], fromIndex: 1),
      .remove(range: 5...6)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.deletes([2, 3]), .inserts([1, 2, 3])])
  }
  
  
  // Insert followed by Update
  
  func testChangeSetInsertUpdateAtFront() {
    // 0 1 2 3 4
    // 0 A B C 1 2 3 4
    // X Y B C 1 2 3 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .insert(elements: [.a, .b, .c], fromIndex: 1),
      .update(elements: [.x, .y], fromIndex: 0),
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.inserts([1, 2, 3]), .updates([0])])
  }
  
  func testChangeSetInsertUpdateOverlapping() {
    // 0 1 2 3 4
    // 0 A B C 1 2 3 4
    // 0 X Y C 1 2 3 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .insert(elements: [.a, .b, .c], fromIndex: 1),
      .update(elements: [.x, .y], fromIndex: 1),
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.inserts([1, 2, 3])])
  }
  
  func testChangeSetInsertUpdateAtBack() {
    // 0 1 2 3 4
    // 0 A B C 1 2 3 4
    // 0 A B X Y 2 3 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .insert(elements: [.a, .b, .c], fromIndex: 1),
      .update(elements: [.x, .y], fromIndex: 3),
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.inserts([1, 2, 3]), .updates([1])])
  }
  
  
  // Update followed by Insert
  
  func testChangeSetUpdateInsertAtFront() {
    // 0 1 2 3 4
    // 0 A B C 4
    // X Y 0 A B C 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .update(elements: [.a, .b, .c], fromIndex: 1),
      .insert(elements: [.x, .y], fromIndex: 0),
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.inserts([0, 1]), .updates([1, 2, 3])])
  }
  
  func testChangeSetUpdateInsertInMiddle() {
    // 0 1 2 3 4
    // 0 A B C 4
    // 0 A X Y B C 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .update(elements: [.a, .b, .c], fromIndex: 1),
      .insert(elements: [.x, .y], fromIndex: 2),
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.inserts([2, 3]), .updates([1, 2, 3])])
  }
  
  func testChangeSetUpdateInsertAtBack() {
    // 0 1 2 3 4
    // 0 A B C 4
    // 0 A B C X Y 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .update(elements: [.a, .b, .c], fromIndex: 1),
      .insert(elements: [.x, .y], fromIndex: 4),
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.inserts([4, 5]), .updates([1, 2, 3])])
  }
  
  
  // Update followed by Delete
  
  func testChangeSetUpdateDeleteOverlappingPartiallyFront() {
    // 0 1 2 3 4
    // 0 A B C 4
    // - - B C 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .update(elements: [.a, .b, .c], fromIndex: 1),
      .remove(range: 0...1)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.deletes([0, 1]), .updates([2, 3])])
  }
  
  func testChangeSetUpdateDeleteOverlappingPartiallyBack() {
    // 0 1 2 3 4
    // 0 A B C 4
    // 0 A B - -
    let operations: [ObservableArrayOperation<Letters>] = [
      .update(elements: [.a, .b, .c], fromIndex: 1),
      .remove(range: 3...4)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.deletes([3, 4]), .updates([1, 2])])
  }
  
  func testChangeSetUpdateDeleteNoOverlappingFront() {
    // 0 1 2 3 4
    // 0 A B C 4
    // - A B C 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .update(elements: [.a, .b, .c], fromIndex: 1),
      .remove(range: 0..<1)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.deletes([0]), .updates([1, 2, 3])])
  }
  
  func testChangeSetUpdateDeleteNoOverlappingBack() {
    // 0 1 2 3 4
    // 0 A B C 4
    // 0 A B C -
    let operations: [ObservableArrayOperation<Letters>] = [
      .update(elements: [.a, .b, .c], fromIndex: 1),
      .remove(range: 4..<5)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.deletes([4]), .updates([1, 2, 3])])
  }
  
  
  // Delete followed by Insert
  
  func testChangeSetDeleteInsertAtFront() {
    // 0 1 2 3 4
    // 0 1 2 - -
    // A B C 0 1 2 - -
    let operations: [ObservableArrayOperation<Letters>] = [
      .remove(range: 3...4),
      .insert(elements: [.a, .b, .c], fromIndex: 0)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.deletes([3, 4]), .inserts([0, 1, 2])])
  }
  
  func testChangeSetDeleteInsertAtFrontOverlapping() {
    // 0 1 2 3 4
    // - - - 3 4
    // - - - 3 A B C 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .remove(range: 0...2),
      .insert(elements: [.a, .b, .c], fromIndex: 1)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.deletes([0, 1, 2]), .inserts([1, 2, 3])])
  }

  func testChangeSetDeleteInsertAtBack() {
    // 0 1 2 3 4
    // - - 2 3 4
    // - - 2 3 A B C 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .remove(range: 0...1),
      .insert(elements: [.a, .b, .c], fromIndex: 2)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.deletes([0, 1]), .inserts([2, 3, 4])])
  }
  
  // Delete followed by Delete
  
  func testChangeSetDeleteDeleteAtBack() {
    // 0 1 2 3 4
    // - 1 2 3 4
    // - 1 - 3 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .remove(range: 0..<1),
      .remove(range: 1..<2),
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.deletes([0, 2])])
  }
  
  func testChangeSetDeleteDeleteAtFront() {
    // 0 1 2 3 4
    // 0 1 - 3 4
    // - 1 - 3 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .remove(range: 2..<3),
      .remove(range: 0..<1),
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.deletes([0, 2])])
  }
  
  // Delete followed by Update
  
  func testChangeSetDeleteUpdateAtBack() {
    // 0 1 2 3 4
    // - 1 2 3 4
    // - 1 2 A B
    let operations: [ObservableArrayOperation<Letters>] = [
      .remove(range: 0..<1),
      .update(elements: [.a, .b], fromIndex: 2)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.deletes([0]), .updates([3, 4])])
  }
  
  func testChangeSetDeleteUpdateAtFront() {
    // 0 1 2 3 4
    // 0 1 - 3 4
    // A B - C 4
    let operations: [ObservableArrayOperation<Letters>] = [
      .remove(range: 2..<3),
      .update(elements: [.a, .b, .c], fromIndex: 0)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.deletes([2]), .updates([0, 1, 3])])
  }
}
