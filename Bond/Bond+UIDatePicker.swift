//
//  Bond+UIDatePicker.swift
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

class DatePickerDynamicHelper: NSObject
{
  weak var control: UIDatePicker?
  var listener: ((Date) -> Void)?
  
  init(control: UIDatePicker) {
    self.control = control
    super.init()
    control.addTarget(self, action: #selector(DatePickerDynamicHelper.valueChanged(_:)), for: .valueChanged)
  }
  
  @objc func valueChanged(_ control: UIDatePicker) {
    self.listener?(control.date)
  }
  
  deinit {
    control?.removeTarget(self, action: nil, for: .valueChanged)
  }
}

class DatePickerDynamic<T>: InternalDynamic<Date>
{
  let helper: DatePickerDynamicHelper
  
  init(control: UIDatePicker) {
    self.helper = DatePickerDynamicHelper(control: control)
    super.init(control.date)
    self.helper.listener =  { [unowned self] in
      self.updatingFromSelf = true
      self.value = $0
      self.updatingFromSelf = false
    }
  }
}

private var dateDynamicHandleUIDatePicker: UInt8 = 0;

extension UIDatePicker /*: Dynamical, Bondable */ {
  public var dynDate: Dynamic<Date> {
    if let d = objc_getAssociatedObject(self, &dateDynamicHandleUIDatePicker) as Any? {
      return d as! Dynamic<Date>
    } else {
      let d = DatePickerDynamic<Date>(control: self)
      
      let bond = Bond<Date>() { [weak self, weak d] v in
        if let s = self, let d = d , !d.updatingFromSelf {
          s.date = v
        }
      }
      
      d.bindTo(bond, fire: false, strongly: false)
      d.retain(bond)
      objc_setAssociatedObject(self, &dateDynamicHandleUIDatePicker, d, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return d
    }
  }
  
  public var designatedDynamic: Dynamic<Date> {
    return self.dynDate
  }
  
  public var designatedBond: Bond<Date> {
    return self.dynDate.valueBond
  }
}

public func ->> (left: UIDatePicker, right: Bond<Date>) {
  left.designatedDynamic ->> right
}

public func ->> <U: Bondable>(left: UIDatePicker, right: U) where U.BondType == Date {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: UIDatePicker, right: UIDatePicker) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: Dynamic<Date>, right: UIDatePicker) {
  left ->> right.designatedBond
}

public func <->> (left: UIDatePicker, right: UIDatePicker) {
  left.designatedDynamic <->> right.designatedDynamic
}

public func <->> (left: Dynamic<Date>, right: UIDatePicker) {
  left <->> right.designatedDynamic
}

public func <->> (left: UIDatePicker, right: Dynamic<Date>) {
  left.designatedDynamic <->> right
}
