//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Tony Arnold (@tonyarnold)
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

import QuartzCore

var backgroundColorDynamicHandleCALayer: UInt8 = 0;
var contentsDynamicHandleCALayer: UInt8 = 0;
var opacityDynamicHandleCALayer: UInt8 = 0;

extension CALayer: Bondable, Dynamical {

    public var designatedDynamic: Dynamic<Any?> {
        return self.dynContents
    }

    public var designatedBond: Bond<Any?> {
        return self.designatedDynamic.valueBond
    }

    public var dynBackgroundColor: Dynamic<CGColor?> {
        if let d: AnyObject = objc_getAssociatedObject(self, &backgroundColorDynamicHandleCALayer) as AnyObject? {
            return (d as? Dynamic<CGColor?>)!
        } else {
            let d = InternalDynamic<CGColor?>(self.backgroundColor)
            let bond = Bond<CGColor?>() { [weak self] v in
                if let s = self {
                    s.backgroundColor = v
                }
            }

            d.bindTo(bond, fire: false, strongly: false)
            d.retain(bond)
            objc_setAssociatedObject(self, &backgroundColorDynamicHandleCALayer, d, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return d
        }
    }

    public var dynContents: Dynamic<Any?> {
        if let d: Any = objc_getAssociatedObject(self, &contentsDynamicHandleCALayer) as Any? {
            return (d as? Dynamic<Any?>)!
        } else {
            let d = InternalDynamic<Any?>(self.contents)
            let bond = Bond<Any?>() { [weak self] v in
                if let s = self {
                    s.contents = v
                }
            }

            d.bindTo(bond, fire: false, strongly: false)
            d.retain(bond)
            objc_setAssociatedObject(self, &contentsDynamicHandleCALayer, d, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return d
        }
    }

    public var dynOpacity: Dynamic<Float> {
        if let d: AnyObject = objc_getAssociatedObject(self, &opacityDynamicHandleCALayer) as AnyObject? {
            return (d as? Dynamic<Float>)!
        } else {
            let d = InternalDynamic<Float>(self.opacity)
            let bond = Bond<Float>() { [weak self] v in
                if let s = self {
                    s.opacity = v
                }
            }

            d.bindTo(bond, fire: false, strongly: false)
            d.retain(bond)
            objc_setAssociatedObject(self, &opacityDynamicHandleCALayer, d, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return d
        }
    }
    
}
