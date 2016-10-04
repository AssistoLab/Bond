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

public enum EventProducerLifecycle {
  case normal   /// Normal lifecycle (alive as long as there exists at least one strong reference to it).
  case managed  /// Normal + retained by the sink given to the producer whenever there is at least one observer.
}

/// Enables production of the events and dispatches them to the registered observers.
open class EventProducer<Event>: EventProducerType {
  
  public typealias EventType = Event
  
  fileprivate var isDispatchInProgress: Bool = false
  fileprivate var observers: [Int64:(Event) -> Void] = [:]
  fileprivate var nextToken: Int64 = 0
  fileprivate let lock = NSRecursiveLock(name: "com.swift-bond.Bond.EventProducer")
  internal fileprivate(set) var replayBuffer: Buffer<Event>? = nil
  
  /// Type of the sink used by the event producer.
  public typealias Sink = (Event) -> ()
  
  /// Number of events to replay to each new observer.
  open var replayLength: Int {
    return replayBuffer?.size ?? 0
  }
  
  /// A composite disposable that will be disposed when the event producer is deallocated.
  open let deinitDisposable = CompositeDisposable()
  
  /// Internal buffer for event replaying.
  
  /// Used to manage lifecycle of the event producer when lifetime == .Managed.
  /// Captured by the producer sink. It will hold a strong reference to self
  /// when there is at least one observer registered.
  ///
  /// When all observers are unregistered, the reference will weakify its reference to self.
  /// That means the event producer will be deallocated if no one else holds a strong reference to it.
  /// Deallocation will dispose `deinitDisposable` and thus break the connection with the source.
  fileprivate weak var selfReference: Reference<EventProducer<Event>>? = nil
  
  /// Consult `EventProducerLifecycle` for more info.
  open fileprivate(set) var lifecycle: EventProducerLifecycle
  
  /// Creates a new event producer with the given replay length and the producer that is used
  /// to generate events that will be dispatched to the registered observers.
  ///
  /// Replay length specifies how many previous events should be buffered and then replayed
  /// to each new observer. Event producer buffers only latest `replayLength` events, discarding old ones.
  ///
  /// Producer closure will be executed immediately. It will receive a sink into which
  /// events can be dispatched. If producer returns a disposable, the observable will store
  /// it and dispose upon [observable's] deallocation.
  public init(replayLength: Int = 0, lifecycle: EventProducerLifecycle = .managed, producer: @escaping (@escaping Sink) -> DisposableType?) {
    self.lifecycle = lifecycle
    
    let tmpSelfReference = Reference(self)
    tmpSelfReference.release()
    
    if replayLength > 0 {
      replayBuffer = Buffer(size: replayLength)
    }
    
    let disposable = producer { event in
      tmpSelfReference.object?.next(event)
    }
    
    if let disposable = disposable {
      deinitDisposable += disposable
    }
    
    self.selfReference = tmpSelfReference
  }
  
  public init(replayLength: Int = 0, lifecycle: EventProducerLifecycle = .normal) {
    self.lifecycle = lifecycle
    
    if replayLength > 0 {
      replayBuffer = Buffer(size: replayLength)
    }
  }
  
  /// Sends an event to the observers
  open func next(_ event: Event) {
    replayBuffer?.push(event)
    dispatchNext(event)
  }
  
  /// Registers the given observer and returns a disposable that can cancel observing.
  @discardableResult
  open func observe(_ observer: @escaping (Event) -> ()) -> DisposableType {
    
    if lifecycle == .managed {
      selfReference?.retain()
    }
    
    let eventProducerBaseDisposable = addObserver(observer)
    
    replayBuffer?.replayTo(observer)
    
    let observerDisposable = BlockDisposable { [weak self] in
      eventProducerBaseDisposable.dispose()
      
      if let unwrappedSelf = self {
        if unwrappedSelf.observers.count == 0 {
          unwrappedSelf.selfReference?.release()
        }
      }
    }
    
    deinitDisposable += observerDisposable
    return observerDisposable
  }
  
  fileprivate func dispatchNext(_ event: Event) {
    guard !isDispatchInProgress else { return }
    
    lock.lock()
    isDispatchInProgress = true
    for (_, send) in observers {
      send(event)
    }
    isDispatchInProgress = false
    lock.unlock()
  }
  
  fileprivate func addObserver(_ observer: @escaping (Event) -> Void) -> DisposableType {
    lock.lock()
    let token = nextToken
    nextToken = nextToken + 1
    lock.unlock()
    
    observers[token] = observer
    return EventProducerDisposable(eventProducer: self, token: token)
  }
  
  fileprivate func removeObserver(_ disposable: EventProducerDisposable<Event>) {
    observers.removeValue(forKey: disposable.token)
  }
  
  deinit {
    deinitDisposable.dispose()
  }
}

extension EventProducer: BindableType {
  
  /// Creates a new sink that can be used to update the receiver.
  /// Optionally accepts a disposable that will be disposed on receiver's deinit.
  public func sink(_ disconnectDisposable: DisposableType?) -> (Event) -> () {
    
    if let disconnectDisposable = disconnectDisposable {
      deinitDisposable += disconnectDisposable
    }
    
    return { [weak self] value in
      self?.next(value)
    }
  }
}

public final class EventProducerDisposable<EventType>: DisposableType {
  
  fileprivate weak var eventProducer: EventProducer<EventType>!
  fileprivate var token: Int64
  
  public var isDisposed: Bool {
    return eventProducer == nil
  }
  
  fileprivate init(eventProducer: EventProducer<EventType>, token: Int64) {
    self.eventProducer = eventProducer
    self.token = token
  }
  
  public func dispose() {
    if let eventProducer = eventProducer {
      eventProducer.removeObserver(self)
      self.eventProducer = nil
    }
  }
}
