//
//  UIControlTests.swift
//  Bond
//
//  Created by Srđan Rašić on 20/07/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

import UIKit
import XCTest
@testable import Bond

class UIControlTests: XCTestCase {
  
  func test_bnd_eventObservable() {
    let control = UIControl()
    var observedEvent: UIControlEvents = UIControlEvents.allEvents
    
    control.bnd_controlEvent.observe { event  in
      observedEvent = event
    }
    
    XCTAssert(observedEvent == UIControlEvents.allEvents)
    
    control.sendActions(for: .touchDown)
    XCTAssert(observedEvent == UIControlEvents.touchDown)
  }
}
