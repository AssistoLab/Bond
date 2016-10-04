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
    let observable = Observable<Bool>(false)
    let button = UIButton()
    
    button.isEnabled = true
    XCTAssert(button.isEnabled == true, "Initial value")
    
    observable.bindTo(button.bnd_enabled)
    XCTAssert(button.isEnabled == false, "Value after binding")
    
    observable.value = true
    XCTAssert(button.isEnabled == true, "Value after observable change")
  }
  
  func testUIButtonTitleBond() {
    let observable = Observable<String>("b")
    let button = UIButton()
    
    button.titleLabel?.text = "a"
    XCTAssert(button.titleLabel?.text == "a", "Initial value")
    
    observable.bindTo(button.bnd_title)
    XCTAssert(button.titleLabel?.text == "b", "Value after binding")
    
    observable.value = "c"
    XCTAssert(button.titleLabel?.text == "c", "Value after observable change")
  }
  
  func testUIButtonObservable() {
    let button = UIButton()
    
    var observedValue = UIControlEvents.allEvents
    
    button.bnd_tap.observe {
      observedValue = .touchUpInside
    }
    
    XCTAssert(observedValue == UIControlEvents.allEvents, "Value after binding should not be changed")
    
    button.sendActions(for: .touchDragInside)
    XCTAssert(observedValue == UIControlEvents.allEvents, "Observable change does not pass test - should not update observedValue")
    
    button.sendActions(for: .touchUpInside)
    XCTAssert(observedValue == UIControlEvents.touchUpInside, "Observable change passes test - should update observedValue")
  }
}
