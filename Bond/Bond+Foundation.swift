//
//  Bond+Foundation.swift
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

import Foundation

private var XXContext = 0

@objc private class DynamicKVOHelper: NSObject {

  let listener: (Any) -> Void
  weak var object: NSObject?
  let keyPath: String
  
  init(keyPath: String, object: NSObject, listener: @escaping (Any) -> Void) {
    self.keyPath = keyPath
    self.object = object
    self.listener = listener
    super.init()
    self.object?.addObserver(self, forKeyPath: keyPath, options: .new, context: &XXContext)
  }
  
  deinit {
    object?.removeObserver(self, forKeyPath: keyPath)
  }
  
  override dynamic func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if context == &XXContext {
      if let newValue = change?[NSKeyValueChangeKey.newKey] {
        listener(newValue)
      }
    }
  }
}

@objc private class DynamicNotificationCenterHelper: NSObject {
  let listener: (Notification) -> Void
  
  init(notificationName: String, object: Any?, listener: @escaping (Notification) -> Void) {
    self.listener = listener
    super.init()
    NotificationCenter.default.addObserver(self, selector: #selector(DynamicNotificationCenterHelper.didReceiveNotification(_:)), name: NSNotification.Name(rawValue: notificationName), object: object)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc dynamic func didReceiveNotification(_ notification: Notification) {
    listener(notification)
  }
}

public func dynamicObservableFor<T>(_ object: NSObject, keyPath: String, defaultValue: T) -> Dynamic<T> {
  let keyPathValue = object.value(forKeyPath: keyPath)
  let value: T = (keyPathValue != nil) ? (keyPathValue as? T)! : defaultValue
  let dynamic = InternalDynamic(value)
  
  let helper = DynamicKVOHelper(keyPath: keyPath, object: object) {
    [unowned dynamic] (v: Any) -> Void in
    
    dynamic.updatingFromSelf = true
    if v is NSNull {
      dynamic.value = defaultValue
    } else {
      dynamic.value = (v as? T)!
    }
    dynamic.updatingFromSelf = false
  }
  
  dynamic.retain(helper)
  return dynamic
}

public func dynamicObservableFor<T>(_ object: NSObject, keyPath: String, from: @escaping (Any?) -> T, to: @escaping (T) -> Any?) -> Dynamic<T> {
  let keyPathValue = object.value(forKeyPath: keyPath)
  let dynamic = InternalDynamic(from(keyPathValue))
  
  let helper = DynamicKVOHelper(keyPath: keyPath, object: object) {
    [unowned dynamic] (v: Any?) -> Void in
    dynamic.updatingFromSelf = true
    dynamic.value = from(v)
    dynamic.updatingFromSelf = false
  }
  
  let feedbackBond = Bond<T>() { [weak object] value in
    if let object = object {
      object.setValue(to(value), forKey: keyPath)
    }
  }
  
  dynamic.bindTo(feedbackBond, fire: false, strongly: false)
  dynamic.retain(feedbackBond)
  
  dynamic.retain(helper)
  return dynamic
}

public func dynamicObservableFor<T>(_ notificationName: String, object: Any?, parser: @escaping (Notification) -> T) -> InternalDynamic<T> {
  let dynamic: InternalDynamic<T> = InternalDynamic()
  
  let helper = DynamicNotificationCenterHelper(notificationName: notificationName, object: object) {
    [unowned dynamic] notification in
    dynamic.updatingFromSelf = true
    dynamic.value = parser(notification)
    dynamic.updatingFromSelf = false
  }
  
  dynamic.retain(helper)
  return dynamic
}


public extension Dynamic {
  public class func asObservableFor(_ object: NSObject, keyPath: String, defaultValue: T) -> Dynamic<T> {
    let dynamic: Dynamic<T> = dynamicObservableFor(object, keyPath: keyPath, defaultValue: defaultValue)
    return dynamic
  }
  
  public class func asObservableFor(_ notificationName: String, object: Any?, parser: @escaping (Notification) -> T) -> Dynamic<T> {
    let dynamic: InternalDynamic<T> = dynamicObservableFor(notificationName, object: object, parser: parser)
    return dynamic
  }
}
