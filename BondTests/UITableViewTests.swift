
import UIKit
import Bond
import XCTest

enum TableOperation {
  case insertRows([IndexPath])
  case deleteRows([IndexPath])
  case reloadRows([IndexPath])
  case insertSections(IndexSet)
  case deleteSections(IndexSet)
  case reloadSections(IndexSet)
  case reloadData
}

func ==(op0: TableOperation, op1: TableOperation) -> Bool {
  switch (op0, op1) {
  case let (.insertRows(paths0), .insertRows(paths1)):
    return paths0 == paths1
  case let (.deleteRows(paths0), .deleteRows(paths1)):
    return paths0 == paths1
  case let (.reloadRows(paths0), .reloadRows(paths1)):
    return paths0 == paths1
  case let (.insertSections(i0), .insertSections(i1)):
    return (i0 == i1)
  case let (.deleteSections(i0), .deleteSections(i1)):
    return (i0 == i1)
  case let (.reloadSections(i0), .reloadSections(i1)):
    return (i0 == i1)
  case (.reloadData, .reloadData):
    return true
  default:
    return false
  }
}

extension TableOperation: Equatable, CustomStringConvertible {
  var description: String {
    switch self {
    case let .insertRows(indexPaths):
      return "InsertRows(\(indexPaths)"
    case let .deleteRows(indexPaths):
      return "DeleteRows(\(indexPaths)"
    case let .reloadRows(indexPaths):
      return "ReloadRows(\(indexPaths)"
    case let .insertSections(indices):
      return "InsertSections(\(indices)"
    case let .deleteSections(indices):
      return "DeleteSections(\(indices)"
    case let .reloadSections(indices):
      return "ReloadSections(\(indices)"
    case .reloadData:
      return "ReloadData"
    }
  }
}

class TestTableView: UITableView {
  var operations = [TableOperation]()
  override func insertRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
    operations.append(.insertRows(indexPaths))
    super.insertRows(at: indexPaths, with: animation)
  }
  
  override func deleteRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
    operations.append(.deleteRows(indexPaths))
    super.deleteRows(at: indexPaths, with: animation)
  }
  
  override func reloadRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
    operations.append(.reloadRows(indexPaths))
    super.reloadRows(at: indexPaths, with: animation)
  }
  
  override func insertSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
    operations.append(.insertSections(sections))
    super.insertSections(sections, with: animation)
  }
  
  override func deleteSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
    operations.append(.deleteSections(sections))
    super.deleteSections(sections, with: animation)
  }
  
  override func reloadSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
    operations.append(.reloadSections(sections))
    super.reloadSections(sections, with: animation)
  }
  
  override func reloadData() {
    operations.append(.reloadData)
    super.reloadData()
  }
}

class UITableViewDataSourceTests: XCTestCase {
  var tableView: TestTableView!
  var array: ObservableArray<ObservableArray<Int>>!
  var expectedOperations: [TableOperation]!
  
  override func setUp() {
    self.array = ObservableArray([ObservableArray([1, 2]), ObservableArray([3, 4])])
    self.tableView = TestTableView()
    
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellID")
    
    expectedOperations = []
    
    array.bindTo(tableView) { (indexPath, array, tableView) -> UITableViewCell in
      let cell = tableView.dequeueReusableCell(withIdentifier: "cellID", for: indexPath)
      return cell
    }
    
    expectedOperations.append(.reloadData) // `tableView` will get a `reloadData` when the bond is attached
  }
  
//  func testReload() {
//    array.setArray([])
//    expectedOperations.append(.ReloadData)
//    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
//  }
  
  func testInsertARow() {
    array[1].append(5)
    expectedOperations.append(.insertRows([IndexPath(row: 2, section: 1)]))
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
  
  func testDeleteARow() {
    array[1].removeLast()
    expectedOperations.append(.deleteRows([IndexPath(row: 1, section: 1)]))
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
  
  func testReloadARow() {
    array[1][1] = 5
    expectedOperations.append(.reloadRows([IndexPath(row: 1, section: 1)]))
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
  
  func testInsertASection() {
    array.insert(ObservableArray([7, 8, 9]), atIndex: 1)
    expectedOperations.append(.insertSections(IndexSet(integer: 1)))
    XCTAssertEqual(tableView.numberOfRows(inSection: 1), 3, "wrong number of rows in new section")
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
  
  func testDeleteASection() {
    array.removeAtIndex(0)
    expectedOperations.append(.deleteSections(IndexSet(integer: 0)))
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
  
  func testReloadASection() {
    array[1] = ObservableArray([5, 6, 7])
    expectedOperations.append(.reloadSections(IndexSet(integer: 1)))
    XCTAssertEqual(tableView.numberOfRows(inSection: 1), 3, "wrong number of rows in reloaded section")
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
}
