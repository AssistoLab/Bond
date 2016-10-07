//
//  UIButtonTests.swift
//  Bond
//
//  Created by Anthony Egerton on 11/03/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UIButtonTests: XCTestCase {

  func testUIButtonEnabledBond() {
    let dynamicDriver = Dynamic<Bool>(false)
    let button = UIButton()
    
    button.isEnabled = true
    XCTAssert(button.isEnabled == true, "Initial value")
    
    dynamicDriver ->> button.designatedBond
    XCTAssert(button.isEnabled == false, "Value after binding")
    
    dynamicDriver.value = true
    XCTAssert(button.isEnabled == true, "Value after dynamic change")
  }
  
  func testUIButtonTitleBond() {
    let dynamicDriver = Dynamic<String>("b")
    let button = UIButton()
    
    button.titleLabel?.text = "a"
    XCTAssert(button.titleLabel?.text == "a", "Initial value")
    
    dynamicDriver ->> button.dynTitle
    XCTAssert(button.titleLabel?.text == "b", "Value after binding")
    
    dynamicDriver.value = "c"
    XCTAssert(button.titleLabel?.text == "c", "Value after dynamic change")
  }
  
  func testUIButtonImageBond() {
    let image1 = UIImage()
    let image2 = UIImage()
    let dynamicDriver = Dynamic<UIImage?>(nil)
    let button = UIButton()
    
    button.setImage(image1, for: [])
    XCTAssert(button.image(for: []) == image1, "Initial value")
    
    dynamicDriver ->> button.dynImageForNormalState
    XCTAssert(button.image(for: []) == nil, "Value after binding")
    
    dynamicDriver.value = image2
    XCTAssert(button.image(for: []) == image2, "Value after dynamic change")
  }
  
  func testUIButtonDynamic() {
    let button = UIButton()
    
    var observedValue = UIControlEvents.allEvents
    let bond = Bond<UIControlEvents>() { v in observedValue = v }
    
    XCTAssert(button.dynEvent.valid == false, "Should be faulty initially")
    
    button.dynEvent.filter(==, .touchUpInside) ->> bond
    XCTAssert(observedValue == UIControlEvents.allEvents, "Value after binding should not be changed")
    
    button.sendActions(for: .touchDragInside)
    XCTAssert(observedValue == UIControlEvents.allEvents, "Dynamic change does not pass test - should not update observedValue")
    
    button.sendActions(for: .touchUpInside)
    XCTAssert(observedValue == UIControlEvents.touchUpInside, "Dynamic change passes test - should update observedValue")
  }
}
