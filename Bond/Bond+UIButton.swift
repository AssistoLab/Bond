//
//  Bond+UIButton.swift
//  Bond
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Srdan Rasic (@srdanrasic)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

class ButtonDynamicHelper: NSObject
{
  weak var control: UIButton?
  var listener: ((UIControlEvents) -> Void)?
  
  init(control: UIButton) {
    self.control = control
    super.init()
    control.addTarget(self, action: #selector(ButtonDynamicHelper.touchDown(_:)), for: .touchDown)
    control.addTarget(self, action: #selector(ButtonDynamicHelper.touchUpInside(_:)), for: .touchUpInside)
    control.addTarget(self, action: #selector(ButtonDynamicHelper.touchUpOutside(_:)), for: .touchUpOutside)
    control.addTarget(self, action: #selector(ButtonDynamicHelper.touchCancel(_:)), for: .touchCancel)
  }
  
  func touchDown(_ control: UIButton) {
    self.listener?(.touchDown)
  }
  
  func touchUpInside(_ control: UIButton) {
    self.listener?(.touchUpInside)
  }
  
  func touchUpOutside(_ control: UIButton) {
    self.listener?(.touchUpOutside)
  }
  
  func touchCancel(_ control: UIButton) {
    self.listener?(.touchCancel)
  }
  
  deinit {
    control?.removeTarget(self, action: nil, for: .allEvents)
  }
}

class ButtonDynamic<T>: InternalDynamic<UIControlEvents>
{
  let helper: ButtonDynamicHelper
  
  init(control: UIButton) {
    self.helper = ButtonDynamicHelper(control: control)
    super.init()
    self.helper.listener =  { [unowned self] in
      self.value = $0
    }
  }
}

private var eventDynamicHandleUIButton: UInt8 = 0;
private var enabledDynamicHandleUIButton: UInt8 = 0;
private var titleDynamicHandleUIButton: UInt8 = 0;
private var imageForNormalStateDynamicHandleUIButton: UInt8 = 0;

extension UIButton /*: Dynamical, Bondable */ {

  public var dynEvent: Dynamic<UIControlEvents> {
    if let d: AnyObject = objc_getAssociatedObject(self, &eventDynamicHandleUIButton) as AnyObject? {
      return (d as? Dynamic<UIControlEvents>)!
    } else {
      let d = ButtonDynamic<UIControlEvents>(control: self)
      objc_setAssociatedObject(self, &eventDynamicHandleUIButton, d, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return d
    }
  }
  
  public var dynEnabled: Dynamic<Bool> {
    if let d: AnyObject = objc_getAssociatedObject(self, &enabledDynamicHandleUIButton) as AnyObject? {
      return (d as? Dynamic<Bool>)!
    } else {
      let d = InternalDynamic<Bool>(self.isEnabled)
      let bond = Bond<Bool>() { [weak self] v in if let s = self { s.isEnabled = v } }
      d.bindTo(bond, fire: false, strongly: false)
      d.retain(bond)
      objc_setAssociatedObject(self, &enabledDynamicHandleUIButton, d, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return d
    }
  }
  
  public var dynTitle: Dynamic<String> {
    if let d: AnyObject = objc_getAssociatedObject(self, &titleDynamicHandleUIButton) as AnyObject? {
      return (d as? Dynamic<String>)!
    } else {
      let d = InternalDynamic<String>(self.titleLabel?.text ?? "")
      let bond = Bond<String>() { [weak self] v in if let s = self { s.setTitle(v, for: UIControlState()) } }
      d.bindTo(bond, fire: false, strongly: false)
      d.retain(bond)
      objc_setAssociatedObject(self, &titleDynamicHandleUIButton, d, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return d
    }
  }
  
  public var dynImageForNormalState: Dynamic<UIImage?> {
    if let d: AnyObject = objc_getAssociatedObject(self, &imageForNormalStateDynamicHandleUIButton) as AnyObject? {
      return (d as? Dynamic<UIImage?>)!
    } else {
      let d = InternalDynamic<UIImage?>(self.image(for: UIControlState()))
      let bond = Bond<UIImage?>() { [weak self] img in if let s = self { s.setImage(img, for: UIControlState()) } }
      d.bindTo(bond, fire: false, strongly: false)
      d.retain(bond)
      objc_setAssociatedObject(self, &imageForNormalStateDynamicHandleUIButton, d, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return d
    }
  }
  
  public var designatedDynamic: Dynamic<UIControlEvents> {
    return self.dynEvent
  }
  
  public var designatedBond: Bond<Bool> {
    return self.dynEnabled.valueBond
  }
}

public func ->> (left: UIButton, right: Bond<UIControlEvents>) {
  left.designatedDynamic ->> right
}

public func ->> <U: Bondable>(left: UIButton, right: U) where U.BondType == UIControlEvents {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> <T: Dynamical>(left: T, right: UIButton) where T.DynamicType == Bool {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: Dynamic<Bool>, right: UIButton) {
  left ->> right.designatedBond
}


