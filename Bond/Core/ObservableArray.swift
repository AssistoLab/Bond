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

/// Abstraction over a type that can be used to encapsulate an array and observe its (incremental) changes.
public protocol ObservableArrayType {
  associatedtype ElementType
  var array: [ElementType] { get }
}

/// A type that can be used to encapsulate an array and observe its (incremental) changes.
public final class ObservableArray<ElementType>: EventProducer<ObservableArrayEvent<Array<ElementType>>>, ObservableArrayType {
  
  /// Batched array operations.
  fileprivate var batchedOperations: [ObservableArrayOperation<ElementType>]! = nil
  
  /// Temporary array to work with while batch is in progress.
  fileprivate var workingBatchArray: [ElementType]! = nil
  
  /// Returns `true` if batch update is in progress at the moment.
  fileprivate var isBatchUpdateInProgress: Bool {
    return batchedOperations != nil
  }
  
  /// The underlying array.
  public var array: [ElementType] {
    get {
      if let workingBatchArray = workingBatchArray {
        return workingBatchArray
      } else {
        return replayBuffer!.last!.sequence
      }
    }
    set {
      next(ObservableArrayEvent(sequence: newValue, operation: ObservableArrayOperation.reset(array: newValue)))
    }
  }
  
  /// Creates a new array with the given initial value.
  public init(_ array: [ElementType]) {
    super.init(replayLength: 1)
    next(ObservableArrayEvent(sequence: array, operation: ObservableArrayOperation.reset(array: array)))
  }
  
  /// Performs batch updates on the array.
  /// Updates must be performed from within the given closure. The closure will receive
  /// an instance of this array for easier manipulation. You should perform updates on received object.
  ///
  /// No event will be generated during the updates. When updates are over, a single .Batch operation
  /// event that contains all operations made to the array will be generated.
  ///
  ///   numbers.performBatchUpdates { numbers in
  ///     numbers.append(1)
  ///     numbers.append(2)
  ///     ...
  ///   }
  public func performBatchUpdates(_ update: (ObservableArray<ElementType>) -> ()) {
    batchedOperations = []
    workingBatchArray = array
    update(self)
    let operationToSend = ObservableArrayOperation.batch(batchedOperations!)
    let arrayToSend = workingBatchArray!
    workingBatchArray = nil
    batchedOperations = nil
    next(ObservableArrayEvent(sequence: arrayToSend, operation: operationToSend))
  }
  
  public func applyOperation(_ operation: ObservableArrayOperation<ElementType>) {
    if isBatchUpdateInProgress {
      ObservableArray.performOperation(operation, onArray: &workingBatchArray!)
      batchedOperations!.append(operation)
    } else {
      var arrayCopy = array
      ObservableArray.performOperation(operation, onArray: &arrayCopy)
      next(ObservableArrayEvent(sequence: arrayCopy, operation: operation))
    }
  }
  
  fileprivate static func performOperation(_ operation: ObservableArrayOperation<ElementType>, onArray array: inout [ElementType]) {
    switch operation {
    case .reset(let newArray):
      array = newArray
    case .insert(let elements, let fromIndex):
      array.insert(contentsOf: elements, at: fromIndex)
    case .update(let elements, let fromIndex):
      for (index, element) in elements.enumerated() {
        array[fromIndex + index] = element
      }
    case .remove(let range):
      array.removeSubrange(range)
    case .batch(let operations):
      for operation in operations {
        ObservableArray.performOperation(operation, onArray: &array)
      }
    }
  }
}

public extension ObservableArray {
  
  /// Appends `newElement` to the ObservableArray and sends .Insert event.
  public func append(_ newElement: ElementType) {
    applyOperation(ObservableArrayOperation.insert(elements: [newElement], fromIndex: count))
  }
  
  public func insert(_ newElement: ElementType, atIndex: Int) {
    applyOperation(ObservableArrayOperation.insert(elements: [newElement], fromIndex: atIndex))
  }
  
  /// Remove an element from the end of the ObservableArray and sends .Remove event.
  public func removeLast() -> ElementType {
    let last = array.last
    if let last = last {
      applyOperation(ObservableArrayOperation.remove(range: count-1..<count))
      return last
    } else {
      fatalError("Dear Sir/Madam, removing an element from the empty array is not possible. Sorry if I caused (you) any trouble.")
    }
  }
  
  /// Removes and returns the element at index `i` and sends .Remove event.
  public func removeAtIndex(_ index: Int) -> ElementType {
    let element = array[index]
    applyOperation(ObservableArrayOperation.remove(range: index..<index+1))
    return element
  }
  
  /// Removes elements in the give range.
  public func removeRange(_ range: Range<Int>) {
    applyOperation(ObservableArrayOperation.remove(range: CountableRange(range)))
  }
  
  /// Remove all elements and sends .Remove event.
  public func removeAll() {
    applyOperation(ObservableArrayOperation.remove(range: 0..<count))
  }
  
  /// Append the elements of `newElements` to `self` and sends .Insert event.
  public func extend(_ newElements: [ElementType]) {
    applyOperation(ObservableArrayOperation.insert(elements: newElements, fromIndex: count))
  }
  
  /// Insertes the array at the given index.
  public func insertContentsOf(_ newElements: [ElementType], atIndex i: Int) {
    applyOperation(ObservableArrayOperation.insert(elements: newElements, fromIndex:i))
  }
  
  /// Replaces elements in the given range with the given array.
  public func replaceRange(_ subRange: Range<Int>, with newElements: [ElementType]) {
    applyOperation(ObservableArrayOperation.remove(range: CountableRange(subRange)))
    applyOperation(ObservableArrayOperation.insert(elements: newElements, fromIndex: subRange.lowerBound))
  }
}

extension ObservableArray: Collection {
  
  /// Returns the position immediately after the given index.
  ///
  /// - Parameter i: A valid index of the collection. `i` must be less than
  ///   `endIndex`.
  /// - Returns: The index value immediately after `i`.
  public func index(after i: Int) -> Int {
    return i + 1
  }
  
  public func makeIterator() -> ObservableArrayGenerator<ElementType> {
    return ObservableArrayGenerator(array: self)
  }
  
  public func underestimateCount() -> Int {
    return array.underestimatedCount
  }
  
  public var startIndex: Int {
    return array.startIndex
  }
  
  public var endIndex: Int {
    return array.endIndex
  }
  
  public var isEmpty: Bool {
    return array.isEmpty
  }
  
  public var count: Int {
    return array.count
  }
  
  public subscript(index: Int) -> ElementType {
    get {
      return array[index]
    }
    set(newElement) {
      if index == self.count {
        applyOperation(ObservableArrayOperation.insert(elements: [newElement], fromIndex: index))
      } else {
        applyOperation(ObservableArrayOperation.update(elements: [newElement], fromIndex: index))
      }
    }
  }
  
  public subscript (subRange: Range<Int>) -> ArraySlice<ElementType> {
    return array[subRange]
  }
}

public struct ObservableArrayGenerator<ElementType>: IteratorProtocol {
  fileprivate var index = -1
  fileprivate let array: ObservableArray<ElementType>
  
  public init(array: ObservableArray<ElementType>) {
    self.array = array
  }
  
  public mutating func next() -> ElementType? {
    index += 1
    return index < array.count ? array[index] : nil
  }
}

public extension EventProducerType where EventType: ObservableArrayEventType {
  
  fileprivate typealias ElementType = EventType.ObservableArrayEventSequenceType.Iterator.Element
  
  /// Wraps the receiver into another array. This basically creates a array of arrays
  /// with with a single element - the receiver array.
  public func lift() -> ObservableArray<Self> {
    return ObservableArray([self])
  }
  
  /// Map overload that simplifies mapping of observables that generate ObservableArray events.
  /// Instead of mapping ObservableArray events, it maps the array elements from those events.
  public func map<T>(_ transform: @escaping (ElementType) -> T) -> EventProducer<ObservableArrayEvent<LazyMapSequence<Self.EventType.ObservableArrayEventSequenceType, T>>> {
    return EventProducer(replayLength: replayLength) { sink in
      return self.observe { arrayEvent in
        let sequence = arrayEvent.sequence.lazy.map(transform)
        let operation = arrayEvent.operation.map(transform)
        sink(ObservableArrayEvent(sequence: sequence, operation: operation))
      }
    }
  }
  
  /// Filter overload that filters array elements instead of its events.
  public func filter(_ includeElement: @escaping (ElementType) -> Bool) -> EventProducer<ObservableArrayEvent<LazyFilterSequence<Self.EventType.ObservableArrayEventSequenceType>>> {
    
    var pointers: [Int]? = nil
    
    return EventProducer(replayLength: replayLength) { sink in
      return self.observe { arrayEvent in
        
        if pointers == nil {
          pointers = pointersFromSequence(arrayEvent.sequence, includeElement: includeElement)
        }
        
        let sequence = arrayEvent.sequence.lazy.filter(includeElement)
        if let operation = arrayEvent.operation.filter(includeElement, pointers: &pointers!) {
          sink(ObservableArrayEvent(sequence: sequence, operation: operation))
        }
      }
    }
  }
  
  /// Creates a array from the observable.
  /// If the observable is already a array, returns that array.
  public func crystallize() -> ObservableArray<ElementType> {
    if let array = self as? ObservableArray<ElementType> {
      return array
    }
    
    var capturedArray: [ElementType] = []
    observe{ capturedArray = Array($0.sequence) }.dispose()
    
    let array = ObservableArray<ElementType>(capturedArray)
    array.deinitDisposable += skip(replayLength).observe { event in
      array.applyOperation(event.operation)
      return
    }
    return array
  }
}

public extension EventProducerType where EventType: ObservableArrayEventType, EventType.ObservableArrayEventSequenceType: Collection {
  
  fileprivate typealias _ElementType = EventType.ObservableArrayEventSequenceType.Iterator.Element
  
  /// Map overload that simplifies mapping of observables that generate ObservableArray events.
  /// Instead of mapping ObservableArray events, it maps the array elements from those events.
  public func map<T>(_ transform: @escaping (_ElementType) -> T) -> EventProducer<ObservableArrayEvent<LazyMapCollection<Self.EventType.ObservableArrayEventSequenceType, T>>> {
    return EventProducer(replayLength: replayLength) { sink in
      return self.observe { arrayEvent in
        let sequence = arrayEvent.sequence.lazy.map(transform)
        let operation = arrayEvent.operation.map(transform)
        sink(ObservableArrayEvent(sequence: sequence, operation: operation))
      }
    }
  }
}
