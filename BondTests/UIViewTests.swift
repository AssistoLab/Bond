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
    let observable = Observable<Bool>(false)
    let view = UIView()
    
    view.isHidden = true
    XCTAssert(view.isHidden == true, "Initial value")
    
    observable.bindTo(view.bnd_hidden)
    XCTAssert(view.isHidden == false, "Value after binding")
    
    observable.value = true
    XCTAssert(view.isHidden == true, "Value after observable change")
  }
  
  func testUIViewAlphaBond() {
    let observable = Observable<CGFloat>(0.1)
    let view = UIView()
    
    view.alpha = 0.0
    XCTAssert(abs(view.alpha - 0.0) < 0.0001, "Initial value")
    
    observable.bindTo(view.bnd_alpha)
    XCTAssert(abs(view.alpha - 0.1) < 0.0001, "Value after binding")
    
    observable.value = 0.5
    XCTAssert(abs(view.alpha - 0.5) < 0.0001, "Value after observable change")
  }
  
  func testUIViewBackgroundColorBond() {
    let observable = Observable<UIColor>(UIColor.black)
    let view = UIView()
    
    view.backgroundColor = UIColor.red
    XCTAssert(view.backgroundColor == UIColor.red, "Initial value")
    
    observable.bindTo(view.bnd_backgroundColor)
    XCTAssert(view.backgroundColor == UIColor.black, "Value after binding")
    
    observable.value = UIColor.blue
    XCTAssert(view.backgroundColor == UIColor.blue, "Value after observable change")
  }
    
  func testUIViewUserInteractionEnabledBond() {
    let observable = Observable<Bool>(false)
    let view = UIView()

    view.isUserInteractionEnabled = true
    XCTAssert(view.isUserInteractionEnabled == true, "Initial value")

    observable.bindTo(view.bnd_userInteractionEnabled)
    XCTAssert(view.isUserInteractionEnabled == false, "Value After Binding")

    observable.value = true
    XCTAssert(view.isUserInteractionEnabled == true, "Value after observable change")
  }

  func testUIViewTintColorBond() {
    let observable = Observable<UIColor>(UIColor.black)
    let view = UIView()

    view.tintColor = UIColor.red
    XCTAssert(view.tintColor == UIColor.red, "Initial value")

    observable.bindTo(view.bnd_tintColor)
    XCTAssert(view.tintColor == UIColor.black, "Value after binding")

    observable.value = UIColor.blue
    XCTAssert(view.tintColor == UIColor.blue, "Value after observable change")
  }

}
