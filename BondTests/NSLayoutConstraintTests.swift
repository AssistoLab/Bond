//
//  NSLayoutConstraintTests.swift
//  Bond
//
//  Created by Tony Xiao on 6/29/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

#if os(iOS)
  import UIKit
  typealias View = UIView
  #else
  import AppKit
  typealias View = NSView
#endif

import XCTest
import Bond

class NSLayoutConstraintTests : XCTestCase {
  
  func testNSLayoutConstraintActiveBond() {
    let driver = Observable<Bool>(true)
    let view = View()
    let constraint = NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100)
    
    XCTAssert(constraint.isActive == false, "Initial value")
    
    driver.bindTo(constraint.bnd_active)
    XCTAssert(constraint.isActive == true, "Value after binding")
    
    driver.value = false
    XCTAssert(constraint.isActive == false, "Value after dynamic change")
  }
}
