//
//  UIViewTests.swift
//  Bond
//
//  Created by Anthony Egerton on 11/03/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UIViewTests: XCTestCase {

  func testUIViewHiddenBond() {
    let dynamicDriver = Dynamic<Bool>(false)
    let view = UIView()
    
    view.isHidden = true
    XCTAssert(view.isHidden == true, "Initial value")
    
    dynamicDriver ->> view.dynHidden
    XCTAssert(view.isHidden == false, "Value after binding")
    
    dynamicDriver.value = true
    XCTAssert(view.isHidden == true, "Value after dynamic change")
  }
  
  func testUIViewAlphaBond() {
    let dynamicDriver = Dynamic<CGFloat>(0.1)
    let view = UIView()
    
    view.alpha = 0.0
    XCTAssert(abs(view.alpha - 0.0) < 0.0001, "Initial value")
    
    dynamicDriver ->> view.dynAlpha
    XCTAssert(abs(view.alpha - 0.1) < 0.0001, "Value after binding")
    
    dynamicDriver.value = 0.5
    XCTAssert(abs(view.alpha - 0.5) < 0.0001, "Value after dynamic change")
  }
  
  func testUIViewBackgroundColorBond() {
    let dynamicDriver = Dynamic<UIColor>(UIColor.black)
    let view = UIView()
    
    view.backgroundColor = UIColor.red
    XCTAssert(view.backgroundColor == UIColor.red, "Initial value")
    
    dynamicDriver ->> view.dynBackgroundColor
    XCTAssert(view.backgroundColor == UIColor.black, "Value after binding")
    
    dynamicDriver.value = UIColor.blue
    XCTAssert(view.backgroundColor == UIColor.blue, "Value after dynamic change")
  }
}
