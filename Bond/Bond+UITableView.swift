//
//  Bond+UITableView.swift
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

extension IndexSet {
  init(array: [Int]) {
    let set = NSMutableIndexSet()
    for index in array {
      set.add(index)
    }
    self.init(set as IndexSet)
  }
}

@objc class TableViewDynamicArrayDataSource: NSObject, UITableViewDataSource {
  weak var dynamic: DynamicArray<DynamicArray<UITableViewCell>>?
  @objc weak var nextDataSource: UITableViewDataSource?
  
  init(dynamic: DynamicArray<DynamicArray<UITableViewCell>>) {
    self.dynamic = dynamic
    super.init()
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return self.dynamic?.count ?? 0
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.dynamic?[section].count ?? 0
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return self.dynamic?[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).item] ?? UITableViewCell()
  }
  
  // Forwards
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if let ds = self.nextDataSource {
      return ds.tableView?(tableView, titleForHeaderInSection: section)
    } else {
      return nil
    }
  }
  
  func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    if let ds = self.nextDataSource {
      return ds.tableView?(tableView, titleForFooterInSection: section)
    } else {
      return nil
    }
  }
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    if let ds = self.nextDataSource {
      return ds.tableView?(tableView, canEditRowAt: indexPath) ?? false
    } else {
      return false
    }
  }
  
  func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    if let ds = self.nextDataSource {
      return ds.tableView?(tableView, canMoveRowAt: indexPath) ?? false
    } else {
      return false
    }
  }
  
  func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    if let ds = self.nextDataSource {
      return ds.sectionIndexTitles?(for: tableView) ?? []
    } else {
      return []
    }
  }
  
  func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
    if let ds = self.nextDataSource {
      return ds.tableView?(tableView, sectionForSectionIndexTitle: title, at: index) ?? index
    } else {
      return index
    }
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if let ds = self.nextDataSource {
      ds.tableView?(tableView, commit: editingStyle, forRowAt: indexPath)
    }
  }
  
  func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    if let ds = self.nextDataSource {
      ds.tableView?(tableView, moveRowAt: sourceIndexPath, to: destinationIndexPath)
    }
  }
}

private class UITableViewDataSourceSectionBond<T>: ArrayBond<UITableViewCell> {
  weak var tableView: UITableView?
  var section: Int
  init(tableView: UITableView?, section: Int, disableAnimation: Bool = false) {
    self.tableView = tableView
    self.section = section
    super.init()
    
    self.didInsertListener = { [unowned self] a, i in
      if let tableView: UITableView = self.tableView {
        perform(animated: !disableAnimation) {
          tableView.beginUpdates()
          tableView.insertRows(at: i.map { IndexPath(item: $0, section: section) }, with: UITableViewRowAnimation.automatic)
          tableView.endUpdates()
        }
      }
    }
    
    self.didRemoveListener = { [unowned self] a, i in
      if let tableView = self.tableView {
        perform(animated: !disableAnimation) {
          tableView.beginUpdates()
          tableView.deleteRows(at: i.map { IndexPath(item: $0, section: section) }, with: UITableViewRowAnimation.automatic)
          tableView.endUpdates()
        }
      }
    }
    
    self.didUpdateListener = { [unowned self] a, i in
      if let tableView = self.tableView {
        perform(animated: !disableAnimation) {
          tableView.beginUpdates()
          tableView.reloadRows(at: i.map { IndexPath(item: $0, section: section) }, with: UITableViewRowAnimation.automatic)
          tableView.endUpdates()
        }
      }
    }
    
    self.didResetListener = { [weak self] array in
      if let tableView = self?.tableView {
        tableView.reloadData()
      }
    }
  }
  
  deinit {
    self.unbindAll()
  }
}

open class UITableViewDataSourceBond<T>: ArrayBond<DynamicArray<UITableViewCell>> {
  weak var tableView: UITableView?
  fileprivate var dataSource: TableViewDynamicArrayDataSource?
  fileprivate var sectionBonds: [UITableViewDataSourceSectionBond<Void>] = []
  open let disableAnimation: Bool
  open weak var nextDataSource: UITableViewDataSource? {
    didSet(newValue) {
      dataSource?.nextDataSource = newValue
    }
  }
  
  public init(tableView: UITableView, disableAnimation: Bool = false) {
    self.disableAnimation = disableAnimation
    self.tableView = tableView
    super.init()
    
    self.didInsertListener = { [weak self] array, i in
      if let s = self {
        if let tableView: UITableView = self?.tableView {
          perform(animated: !disableAnimation) {
            tableView.beginUpdates()
            tableView.insertSections(IndexSet(array: i), with: UITableViewRowAnimation.automatic)
            
            for section in i.sorted(by: <) {
              let sectionBond = UITableViewDataSourceSectionBond<Void>(tableView: tableView, section: section, disableAnimation: disableAnimation)
              let sectionDynamic = array[section]
              sectionDynamic.bindTo(sectionBond)
              s.sectionBonds.insert(sectionBond, at: section)
              
              for idx in section + 1 ..< s.sectionBonds.count {
                s.sectionBonds[idx].section += 1
              }
            }
            
            tableView.endUpdates()
          }
        }
      }
    }
    
    self.didRemoveListener = { [weak self] array, i in
      if let s = self {
        if let tableView = s.tableView {
          perform(animated: !disableAnimation) {
            tableView.beginUpdates()
            tableView.deleteSections(IndexSet(array: i), with: UITableViewRowAnimation.automatic)
            for section in i.sorted(by: >) {
              s.sectionBonds[section].unbindAll()
              s.sectionBonds.remove(at: section)
              
              for idx in section ..< s.sectionBonds.count {
                s.sectionBonds[idx].section -= 1
              }
            }
            
            tableView.endUpdates()
          }
        }
      }
    }
  
    self.didUpdateListener = { [weak self] array, i in
      if let s = self {
        if let tableView = s.tableView {
          perform(animated: !disableAnimation) {
            tableView.beginUpdates()
            tableView.reloadSections(IndexSet(array: i), with: UITableViewRowAnimation.automatic)

            for section in i {
              let sectionBond = UITableViewDataSourceSectionBond<Void>(tableView: tableView, section: section, disableAnimation: disableAnimation)
              let sectionDynamic = array[section]
              sectionDynamic.bindTo(sectionBond)
              
              self?.sectionBonds[section].unbindAll()
              self?.sectionBonds[section] = sectionBond
            }
            
            tableView.endUpdates()
          }
        }
      }
    }
    
    self.didResetListener = { [weak self] array in
      if let tableView = self?.tableView {
        tableView.reloadData()
      }
    }
  }
  
  open func bind(_ dynamic: DynamicArray<UITableViewCell>) {
    bind(DynamicArray([dynamic]))
  }
  
  open override func bind(_ dynamic: Dynamic<Array<DynamicArray<UITableViewCell>>>, fire: Bool, strongly: Bool) {
    super.bind(dynamic, fire: false, strongly: strongly)
    if let dynamic = dynamic as? DynamicArray<DynamicArray<UITableViewCell>> {
      
      for section in 0..<dynamic.count {
        let sectionBond = UITableViewDataSourceSectionBond<Void>(tableView: self.tableView, section: section, disableAnimation: disableAnimation)
        let sectionDynamic = dynamic[section]
        sectionDynamic.bindTo(sectionBond)
        sectionBonds.append(sectionBond)
      }
      
      dataSource = TableViewDynamicArrayDataSource(dynamic: dynamic)
      dataSource?.nextDataSource = self.nextDataSource
      tableView?.dataSource = dataSource
      tableView?.reloadData()
    }
  }
  
  deinit {
    self.unbindAll()
    tableView?.dataSource = nil
    self.dataSource = nil
  }
}

private func perform(animated: Bool, block: () -> Void) {
  if !animated {
    UIView.performWithoutAnimation(block)
  } else {
    block()
  }
}

public func ->> <T>(left: DynamicArray<UITableViewCell>, right: UITableViewDataSourceBond<T>) {
  right.bind(left)
}
