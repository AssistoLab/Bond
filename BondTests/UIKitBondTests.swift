//
//  UIKitTests.swift
//  Bond
//
//  Created by Srđan Rašić on 11/02/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UIKitTests: XCTestCase {
  
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
  
  func testUILabelBond() {
    let observable = Observable<String>("b")
    let label = UILabel()
    
    label.text = "a"
    XCTAssert(label.text == "a", "Initial value")
    
    observable.bindTo(label.bnd_text)
    XCTAssert(label.text == "b", "Value after binding")
    
    observable.value = "c"
    XCTAssert(label.text == "c", "Value after observable change")
  }
  
  func testUILabelAttributedTextBond() {
    let observable = Observable<NSAttributedString>(NSAttributedString(string: "b"))
    let label = UILabel()
    
    label.text = "a"
    XCTAssert(label.text == "a", "Initial value")
    
    observable.bindTo(label.bnd_attributedText)
    XCTAssert(label.attributedText!.string == "b", "Value after binding")
    
    observable.value = NSAttributedString(string: "c")
    XCTAssert(label.attributedText!.string == "c", "Value after observable change")
  }

  func testUIProgressViewBond() {
    let observable = Observable<Float>(0)
    let progressView = UIProgressView()
    
    progressView.progress = 0.1
    XCTAssert(progressView.progress == 0.1, "Initial value")
    
    observable.bindTo(progressView.bnd_progress)
    XCTAssert(progressView.progress == 0.0, "Value after binding")
    
    observable.value = 0.5
    XCTAssert(progressView.progress == 0.5, "Value after observable change")
  }
  
  func testUIImageViewBond() {
    let image = UIImage()
    let observable = Observable<UIImage?>(nil)
    let imageView = UIImageView()
    
    imageView.image = image
    XCTAssert(imageView.image == image, "Initial value")
    
    observable.bindTo(imageView.bnd_image)
    XCTAssert(imageView.image == nil, "Value after binding")
    
    imageView.image = image
    XCTAssert(imageView.image == image, "Value after observable change")
  }
  
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
  
  func testUIBarItemEnabledBond() {
    let observable = Observable<Bool>(false)
    let barItem = UIBarButtonItem()
    
    barItem.isEnabled = true
    XCTAssert(barItem.isEnabled == true, "Initial value")
    
    observable.bindTo(barItem.bnd_enabled)
    XCTAssert(barItem.isEnabled == false, "Value after binding")
    
    observable.value = true
    XCTAssert(barItem.isEnabled == true, "Value after observable change")
  }
  
  func testUIBarItemTitleBond() {
    let observable = Observable<String>("b")
    let barItem = UIBarButtonItem()
    
    barItem.title = "a"
    XCTAssert(barItem.title == "a", "Initial value")
    
    observable.bindTo(barItem.bnd_title)
    XCTAssert(barItem.title == "b", "Value after binding")
    
    observable.value = "c"
    XCTAssert(barItem.title == "c", "Value after observable change")
  }
  
  func testUIBarItemImageBond() {
    let image1 = UIImage()
    let image2 = UIImage()
    let observable = Observable<UIImage?>(nil)
    let barItem = UIBarButtonItem()
    
    barItem.image = image1
    XCTAssert(barItem.image == image1, "Initial value")
    
    observable.bindTo(barItem.bnd_image)
    XCTAssert(barItem.image == nil, "Value after binding")
    
    observable.value = image2
    XCTAssert(barItem.image == image2, "Value after observable change")
  }
  
  func testUIActivityIndicatorViewHiddenBond() {
    let observable = Observable<Bool>(false)
    let view = UIActivityIndicatorView()
    
    view.startAnimating()
    XCTAssert(view.isAnimating == true, "Initial value")
    
    observable.bindTo(view.bnd_animating)
    XCTAssert(view.isAnimating == false, "Value after binding")
    
    observable.value = true
    XCTAssert(view.isAnimating == true, "Value after observable change")
  }
}
