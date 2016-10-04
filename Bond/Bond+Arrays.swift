//
//  Bond+Arrays.swift
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

// MARK: - Vector Dynamic

// MARK: Array Bond

open class ArrayBond<T>: Bond<Array<T>> {
  open var willInsertListener: ((DynamicArray<T>, [Int]) -> Void)?
  open var didInsertListener: ((DynamicArray<T>, [Int]) -> Void)?
  
  open var willRemoveListener: ((DynamicArray<T>, [Int]) -> Void)?
  open var didRemoveListener: ((DynamicArray<T>, [Int]) -> Void)?
  
  open var willUpdateListener: ((DynamicArray<T>, [Int]) -> Void)?
  open var didUpdateListener: ((DynamicArray<T>, [Int]) -> Void)?

  open var willResetListener: ((DynamicArray<T>) -> Void)?
  open var didResetListener: ((DynamicArray<T>) -> Void)?
  
  override public init() {
    super.init()
  }
  
  override open func bind(_ dynamic: Dynamic<Array<T>>) {
    bind(dynamic, fire: true, strongly: true)
  }
  
  override open func bind(_ dynamic: Dynamic<Array<T>>, fire: Bool) {
    bind(dynamic, fire: fire, strongly: true)
  }
  
  override open func bind(_ dynamic: Dynamic<Array<T>>, fire: Bool, strongly: Bool) {
    super.bind(dynamic, fire: fire, strongly: strongly)
  }
}

// MARK: Dynamic array

/**
Note: Directly setting `DynamicArray.value` is not recommended. The array's count will not be updated and no array change notification will be emitted. Call `setArray:` instead.
*/
open class DynamicArray<T>: Dynamic<Array<T>>, Sequence {
  
  public typealias Element = T
  public typealias Iterator = DynamicArrayGenerator<T>
  
  open let dynCount: Dynamic<Int>
  
  public override init(_ v: Array<T>) {
    dynCount = Dynamic(0)
    super.init(v)
    dynCount.value = self.count
  }
  
  open override func bindTo(_ bond: Bond<Array<T>>) {
    bond.bind(self, fire: true, strongly: true)
  }
  
  open override func bindTo(_ bond: Bond<Array<T>>, fire: Bool) {
    bond.bind(self, fire: fire, strongly: true)
  }
  
  open override func bindTo(_ bond: Bond<Array<T>>, fire: Bool, strongly: Bool) {
    bond.bind(self, fire: fire, strongly: strongly)
  }
  
  open func setArray(_ newValue: [T]) {
    dispatchWillReset()
    value = newValue
    dispatchDidReset()
  }
  
  open var count: Int {
    return value.count
  }
  
  open var capacity: Int {
    return value.capacity
  }
  
  open var isEmpty: Bool {
    return value.isEmpty
  }
  
  open var first: T? {
    return value.first
  }
  
  open var last: T? {
    return value.last
  }
  
  open func append(_ newElement: T) {
    dispatchWillInsert([value.count])
    value.append(newElement)
    dispatchDidInsert([value.count-1])
  }
  
  open func append(_ array: Array<T>) {
	splice(array, atIndex: value.count)
  }
  
  open func removeLast() -> T {
    if self.count > 0 {
      dispatchWillRemove([value.count-1])
      let last = value.removeLast()
      dispatchDidRemove([value.count])
      return last
    }
    
    fatalError("Cannot removeLast() as there are no elements in the array!")
  }
  
  open func insert(_ newElement: T, atIndex i: Int) {
    dispatchWillInsert([i])
    value.insert(newElement, at: i)
    dispatchDidInsert([i])
  }
  
  open func splice(_ array: Array<T>, atIndex i: Int) {
    if array.count > 0 {
      let indices = Array(i..<i+array.count)
      dispatchWillInsert(indices)
      value.insert(contentsOf: array, at: i)
      dispatchDidInsert(indices)
    }
  }
  
  open func removeAtIndex(_ index: Int) -> T {
    dispatchWillRemove([index])
    let object = value.remove(at: index)
    dispatchDidRemove([index])
    return object
  }
  
  open func removeAll(_ keepCapacity: Bool) {
    let count = value.count
    let indices = Array(0..<count)
    dispatchWillRemove(indices)
    value.removeAll(keepingCapacity: keepCapacity)
    dispatchDidRemove(indices)
  }
  
  open subscript(index: Int) -> T {
    get {
      return value[index]
    }
    set(newObject) {
      if index == value.count {
        dispatchWillInsert([index])
        value[index] = newObject
        dispatchDidInsert([index])
      } else {
        dispatchWillUpdate([index])
        value[index] = newObject
        dispatchDidUpdate([index])
      }
    }
  }
  
  open func makeIterator() -> DynamicArrayGenerator<T> {
    return DynamicArrayGenerator<T>(array: self)
  }
  
  fileprivate func dispatchWillInsert(_ indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.willInsertListener?(self, indices)
      }
    }
  }
  
  fileprivate func dispatchDidInsert(_ indices: [Int]) {
    if !indices.isEmpty {
      dynCount.value = count
    }
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.didInsertListener?(self, indices)
      }
    }
  }
  
  fileprivate func dispatchWillRemove(_ indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.willRemoveListener?(self, indices)
      }
    }
  }

  fileprivate func dispatchDidRemove(_ indices: [Int]) {
    if !indices.isEmpty {
      dynCount.value = count
    }
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.didRemoveListener?(self, indices)
      }
    }
  }
  
  fileprivate func dispatchWillUpdate(_ indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.willUpdateListener?(self, indices)
      }
    }
  }
  
  fileprivate func dispatchDidUpdate(_ indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.didUpdateListener?(self, indices)
      }
    }
  }
  
  fileprivate func dispatchWillReset() {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.willResetListener?(self)
      }
    }
  }
  
  fileprivate func dispatchDidReset() {
    dynCount.value = self.count
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.didResetListener?(self)
      }
    }
  }
}

public struct DynamicArrayGenerator<T>: IteratorProtocol {
  fileprivate var index = -1
  fileprivate let array: DynamicArray<T>
  
  init(array: DynamicArray<T>) {
    self.array = array
  }
  
  public typealias Element = T
  
  public mutating func next() -> T? {
    index += 1
    return index < array.count ? array[index] : nil
  }
}

// MARK: Dynamic Array Map Proxy

private class DynamicArrayMapProxy<T, U>: DynamicArray<U> {
  fileprivate unowned var sourceArray: DynamicArray<T>
  fileprivate var mapf: (T, Int) -> U
  fileprivate let bond: ArrayBond<T>
  
  fileprivate init(sourceArray: DynamicArray<T>, mapf: @escaping (T, Int) -> U) {
    self.sourceArray = sourceArray
    self.mapf = mapf
    self.bond = ArrayBond<T>()
    self.bond.bind(sourceArray, fire: false)
    super.init([])
    
    bond.willInsertListener = { [unowned self] array, i in
      self.dispatchWillInsert(i)
    }
    
    bond.didInsertListener = { [unowned self] array, i in
      self.dispatchDidInsert(i)
    }
    
    bond.willRemoveListener = { [unowned self] array, i in
      self.dispatchWillRemove(i)
    }
    
    bond.didRemoveListener = { [unowned self] array, i in
      self.dispatchDidRemove(i)
    }
    
    bond.willUpdateListener = { [unowned self] array, i in
      self.dispatchWillUpdate(i)
    }
    
    bond.didUpdateListener = { [unowned self] array, i in
      self.dispatchDidUpdate(i)
    }
    
    bond.willResetListener = { [unowned self] array in
      self.dispatchWillReset()
    }
    
    bond.didResetListener = { [unowned self] array in
      self.dispatchDidReset()
    }
  }
  
  override var value: [U] {
    set(newValue) {
      fatalError("Modifying proxy array is not supported!")
    }
    get {
      fatalError("Getting proxy array value is not supported!")
    }
  }
  
  override var count: Int {
    return sourceArray.count
  }
  
  override var capacity: Int {
    return sourceArray.capacity
  }
  
  override var isEmpty: Bool {
    return sourceArray.isEmpty
  }
  
  override var first: U? {
    if let first = sourceArray.first {
      return mapf(first, 0)
    } else {
      return nil
    }
  }
  
  override var last: U? {
    if let last = sourceArray.last {
      return mapf(last, sourceArray.count - 1)
    } else {
      return nil
    }
  }
  
  override func setArray(_ newValue: [U]) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func append(_ newElement: U) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func append(_ array: Array<U>) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func removeLast() -> U {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func insert(_ newElement: U, atIndex i: Int) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func splice(_ array: Array<U>, atIndex i: Int) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func removeAtIndex(_ index: Int) -> U {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func removeAll(_ keepCapacity: Bool) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override subscript(index: Int) -> U {
    get {
        return mapf(sourceArray[index], index)
    }
    set(newObject) {
      fatalError("Modifying proxy array is not supported!")
    }
  }
}

func indexOfFirstEqualOrLargerThan(_ x: Int, array: [Int]) -> Int {
  var idx: Int = -1
  for (index, element) in array.enumerated() {
    if element < x {
      idx = index
    } else {
      break
    }
  }
  return idx + 1
}

// MARK: Dynamic Array Filter Proxy

private class DynamicArrayFilterProxy<T>: DynamicArray<T> {
  fileprivate unowned var sourceArray: DynamicArray<T>
  fileprivate var pointers: [Int]
  fileprivate var filterf: (T) -> Bool
  fileprivate let bond: ArrayBond<T>
  
  fileprivate init(sourceArray: DynamicArray<T>, filterf: @escaping (T) -> Bool) {
    self.sourceArray = sourceArray
    self.filterf = filterf
    self.bond = ArrayBond<T>()
    self.bond.bind(sourceArray, fire: false)
    
    self.pointers = DynamicArrayFilterProxy.pointersFromSource(sourceArray, filterf: filterf)
    
    super.init([])

    bond.didInsertListener = { [unowned self] array, indices in
      var insertedIndices: [Int] = []
      var pointers = self.pointers
      
      for idx in indices {

        for (index, element) in pointers.enumerated() {
          if element >= idx {
            pointers[index] = element + 1
          }
        }
        
        let element = array[idx]
        if filterf(element) {
          let position = indexOfFirstEqualOrLargerThan(idx, array: pointers)
          pointers.insert(idx, at: position)
          insertedIndices.append(position)
        }
      }
      
      if insertedIndices.count > 0 {
       self.dispatchWillInsert(insertedIndices)
      }
      
      self.pointers = pointers
      
      if insertedIndices.count > 0 {
        self.dispatchDidInsert(insertedIndices)
      }
    }
    
    bond.willRemoveListener = { [unowned self] array, indices in
      var removedIndices: [Int] = []
      var pointers = self.pointers
      
      for idx in Array(indices.reversed()) {
        
        if let idx = pointers.index(of: idx) {
          pointers.remove(at: idx)
          removedIndices.append(idx)
        }
        
        for (index, element) in pointers.enumerated() {
          if element >= idx {
            pointers[index] = element - 1
          }
        }
      }
      
      if removedIndices.count > 0 {
        self.dispatchWillRemove(Array(removedIndices.reversed()))
      }
      
      self.pointers = pointers
      
      if removedIndices.count > 0 {
        self.dispatchDidRemove(Array(removedIndices.reversed()))
      }
    }
    
    bond.didUpdateListener = { [unowned self] array, indices in
      
      let idx = indices[0]
      let element = array[idx]

      var insertedIndices: [Int] = []
      var removedIndices: [Int] = []
      var updatedIndices: [Int] = []
      var pointers = self.pointers
      
      if let idx = pointers.index(of: idx) {
        if filterf(element) {
          // update
          updatedIndices.append(idx)
        } else {
          // remove
          pointers.remove(at: idx)
          removedIndices.append(idx)
        }
      } else {
        if filterf(element) {
          let position = indexOfFirstEqualOrLargerThan(idx, array: pointers)
          pointers.insert(idx, at: position)
          insertedIndices.append(position)
        } else {
          // nothing
        }
      }

      if insertedIndices.count > 0 {
        self.dispatchWillInsert(insertedIndices)
      }
      
      if removedIndices.count > 0 {
        self.dispatchWillRemove(removedIndices)
      }
      
      if updatedIndices.count > 0 {
        self.dispatchWillUpdate(updatedIndices)
      }
      
      self.pointers = pointers
      
      if updatedIndices.count > 0 {
        self.dispatchDidUpdate(updatedIndices)
      }
      
      if removedIndices.count > 0 {
        self.dispatchDidRemove(removedIndices)
      }
      
      if insertedIndices.count > 0 {
        self.dispatchDidInsert(insertedIndices)
      }
    }

    bond.willResetListener = { [unowned self] array in
      self.dispatchWillReset()
    }
    
    bond.didResetListener = { [unowned self] array in
      self.pointers = DynamicArrayFilterProxy.pointersFromSource(array, filterf: filterf)
      self.dispatchDidReset()
    }
  }
  
  class func pointersFromSource(_ sourceArray: DynamicArray<T>, filterf: (T) -> Bool) -> [Int] {
    var pointers = [Int]()
    for (index, element) in sourceArray.enumerated() {
      if filterf(element) {
        pointers.append(index)
      }
    }
    return pointers
  }
  
  override var value: [T] {
    set(newValue) {
      fatalError("Modifying proxy array is not supported!")
    }
    get {
      fatalError("Getting proxy array value is not supported!")
    }
  }
  
  fileprivate override var count: Int {
    return pointers.count
  }
  
  fileprivate override var capacity: Int {
    return pointers.capacity
  }
  
  fileprivate override var isEmpty: Bool {
    return pointers.isEmpty
  }
  
  fileprivate override var first: T? {
    if let first = pointers.first {
      return sourceArray[first]
    } else {
      return nil
    }
  }
  
  fileprivate override var last: T? {
    if let last = pointers.last {
      return sourceArray[last]
    } else {
      return nil
    }
  }
  
  override fileprivate func setArray(_ newValue: [T]) {
    fatalError("Modifying proxy array is not supported!")
  }

  override fileprivate func append(_ newElement: T) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  fileprivate override func append(_ array: Array<T>) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override fileprivate func removeLast() -> T {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override fileprivate func insert(_ newElement: T, atIndex i: Int) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  fileprivate override func splice(_ array: Array<T>, atIndex i: Int) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override fileprivate func removeAtIndex(_ index: Int) -> T {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override fileprivate func removeAll(_ keepCapacity: Bool) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override fileprivate subscript(index: Int) -> T {
    get {
      return sourceArray[pointers[index]]
    }
    set {
      fatalError("Modifying proxy array is not supported!")
    }
  }
}

// MARK: Dynamic Array DeliverOn Proxy

private class DynamicArrayDeliverOnProxy<T>: DynamicArray<T> {
  fileprivate unowned var sourceArray: DynamicArray<T>
  fileprivate var queue: DispatchQueue
  fileprivate let bond: ArrayBond<T>
  
  fileprivate init(sourceArray: DynamicArray<T>, queue: DispatchQueue) {
    self.sourceArray = sourceArray
    self.queue = queue
    self.bond = ArrayBond<T>()
    self.bond.bind(sourceArray, fire: false)
    super.init([])
    
    bond.willInsertListener = { [unowned self] array, i in
      queue.async {
        self.dispatchWillInsert(i)
      }
    }
    
    bond.didInsertListener = { [unowned self] array, i in
      queue.async {
        self.dispatchDidInsert(i)
      }
    }
    
    bond.willRemoveListener = { [unowned self] array, i in
      queue.async {
        self.dispatchWillRemove(i)
      }
    }
    
    bond.didRemoveListener = { [unowned self] array, i in
      queue.async {
        self.dispatchDidRemove(i)
      }
    }
    
    bond.willUpdateListener = { [unowned self] array, i in
      queue.async {
        self.dispatchWillUpdate(i)
      }
    }
    
    bond.didUpdateListener = { [unowned self] array, i in
      queue.async {
        self.dispatchDidUpdate(i)
      }
    }
    
    bond.willResetListener = { [unowned self] array in
      queue.async {
        self.dispatchWillReset()
      }
    }
    
    bond.didResetListener = { [unowned self] array in
      queue.async {
        self.dispatchDidReset()
      }
    }
  }
  
  override var value: [T] {
    set(newValue) {
      fatalError("Modifying proxy array is not supported!")
    }
    get {
      fatalError("Getting proxy array value is not supported!")
    }
  }
  
  override var count: Int {
    return sourceArray.count
  }
  
  override var capacity: Int {
    return sourceArray.capacity
  }
  
  override var isEmpty: Bool {
    return sourceArray.isEmpty
  }
  
  override var first: T? {
    if let first = sourceArray.first {
      return first
    } else {
      return nil
    }
  }
  
  override var last: T? {
    if let last = sourceArray.last {
      return last
    } else {
      return nil
    }
  }
  
  override func setArray(_ newValue: [T]) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func append(_ newElement: T) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func append(_ array: Array<T>) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func removeLast() -> T {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func insert(_ newElement: T, atIndex i: Int) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func splice(_ array: Array<T>, atIndex i: Int) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func removeAtIndex(_ index: Int) -> T {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func removeAll(_ keepCapacity: Bool) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override subscript(index: Int) -> T {
    get {
      return sourceArray[index]
    }
    set(newObject) {
      fatalError("Modifying proxy array is not supported!")
    }
  }
}

// MARK: Dynamic Array additions

public extension DynamicArray
{
  public func map<U>(_ f: @escaping (T, Int) -> U) -> DynamicArray<U> {
    return _map(self, f: f)
  }
  
  public func map<U>(_ f: @escaping (T) -> U) -> DynamicArray<U> {
    let mapf = { (o: T, i: Int) -> U in f(o) }
    return _map(self, f: mapf)
  }
  
  public func filter(_ f: @escaping (T) -> Bool) -> DynamicArray<T> {
    return _filter(self, f: f)
  }
}

// MARK: Map

private func _map<T, U>(_ dynamicArray: DynamicArray<T>, f: @escaping (T, Int) -> U) -> DynamicArrayMapProxy<T, U> {
  return DynamicArrayMapProxy(sourceArray: dynamicArray, mapf: f)
}

// MARK: Filter

private func _filter<T>(_ dynamicArray: DynamicArray<T>, f: @escaping (T) -> Bool) -> DynamicArray<T> {
  return DynamicArrayFilterProxy(sourceArray: dynamicArray, filterf: f)
}

// MARK: DeliverOn

public func deliver<T>(_ dynamicArray: DynamicArray<T>, on queue: DispatchQueue) -> DynamicArray<T> {
  return DynamicArrayDeliverOnProxy(sourceArray: dynamicArray, queue: queue)
}
