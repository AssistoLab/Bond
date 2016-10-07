//
//  Bond+UISwitch.swift
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

class SwitchDynamicHelper: NSObject
{
  weak var control: UISwitch?
  var listener: ((Bool) -> Void)?
  
  init(control: UISwitch) {
    self.control = control
    super.init()
    control.addTarget(self, action: #selector(SwitchDynamicHelper.valueChanged(_:)), for: .valueChanged)
  }
  
  func valueChanged(_ control: UISwitch) {
    self.listener?(control.isOn)
  }
  
  deinit {
    control?.removeTarget(self, action: nil, for: .valueChanged)
  }
}

class SwitchDynamic<T>: InternalDynamic<Bool>
{
  let helper: SwitchDynamicHelper
  
  init(control: UISwitch) {
    self.helper = SwitchDynamicHelper(control: control)
    super.init(control.isOn)
    self.helper.listener =  { [unowned self] in
      self.updatingFromSelf = true
      self.value = $0
      self.updatingFromSelf = false
    }
  }
}

private var onDynamicHandleUISwitch: UInt8 = 0;

extension UISwitch /*: Dynamical, Bondable */ {
  public var dynOn: Dynamic<Bool> {
    if let d = objc_getAssociatedObject(self, &onDynamicHandleUISwitch) as Any? {
      return d as! Dynamic<Bool>
    } else {
      let d = SwitchDynamic<Bool>(control: self)
      
      let bond = Bond<Bool>() { [weak self, weak d] v in
        if let s = self, let d = d , !d.updatingFromSelf {
          s.isOn = v
        }
      }
      
      d.bindTo(bond, fire: false, strongly: false)
      d.retain(bond)
      objc_setAssociatedObject(self, &onDynamicHandleUISwitch, d, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return d
    }
  }
  
  public var designatedDynamic: Dynamic<Bool> {
    return self.dynOn
  }
  
  public var designatedBond: Bond<Bool> {
    return self.dynOn.valueBond
  }
}

public func ->> (left: UISwitch, right: Bond<Bool>) {
  left.designatedDynamic ->> right
}

public func ->> <U: Bondable>(left: UISwitch, right: U) where U.BondType == Bool {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: UISwitch, right: UIButton) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: UISwitch, right: UISwitch) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> <T: Dynamical>(left: T, right: UISwitch) where T.DynamicType == Bool {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: Dynamic<Bool>, right: UISwitch) {
  left ->> right.designatedBond
}

public func <->> (left: UISwitch, right: UISwitch) {
  left.designatedDynamic <->> right.designatedDynamic
}

public func <->> (left: Dynamic<Bool>, right: UISwitch) {
  left <->> right.designatedDynamic
}

public func <->> (left: UISwitch, right: Dynamic<Bool>) {
  left.designatedDynamic <->> right
}

