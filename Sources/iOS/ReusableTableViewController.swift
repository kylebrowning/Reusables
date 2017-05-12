import Foundation
import UIKit

// Define our Cell Definition
// This allows us to create Generic cells that our
// Generic tableview controller can act upon.

struct CellDefinition {
    let cellClass: UITableViewCell.Type
    let reuseIdentifier: String
    let configure: (UITableViewCell) -> ()

    init<Cell: UITableViewCell>(reuseIdentifier: String, configure: @escaping (Cell) -> ()) {
        self.cellClass = Cell.self
        self.reuseIdentifier = reuseIdentifier
        self.configure = { cell in
            configure(cell as! Cell)
        }
    }
}


// A class to manage TableViews for the move WIth app.
// This adds all the functionality most tableviews need,
// while allowing us to pass generics that this tble
// can act upon.
class CommonTableViewController<Item>: UITableViewController, UISearchResultsUpdating {

    var sectionedData: [[Item]] = [[]]

    let cellDefinition: (Item) -> CellDefinition
    var didSelect: (Item) -> () = { _ in }
    var didSelectSelectedRow: (UITableViewController) -> () = { _ in }
    var didSearch: (_ searchText: String) -> ([Item]) = { _ in return []}
    var reuseIdentifiers: Set<String> = []

    var titleInHeaderForSection: (Int) -> String = {_ in return ""}
    var sectionIndexTitles: () -> [String]? = {return nil}

    let searchController = UISearchController(searchResultsController: nil)

    var cellHeight: Double = 44.0
    var cellSelectedHeight: Double?

    internal var selectedIndexPath: IndexPath?

    var filtered:[Item] = []

    init(items: [[Item]], cellDefinition: @escaping (Item) -> CellDefinition, cellHeight: Double, cellSelectedHeight: Double? = nil) {
        self.cellDefinition = cellDefinition
        super.init(style: .plain)
        self.sectionedData = items
        self.cellHeight = cellHeight
        if (cellSelectedHeight != nil) {
            self.cellSelectedHeight = cellSelectedHeight
        }
        tableView.sectionIndexBackgroundColor = UIColor.clear
        tableView.sectionIndexTrackingBackgroundColor = .clear
        tableView.sectionIndexBackgroundColor = .clear
        self.tableView.layoutMargins = .zero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    override func viewDidLoad() {

        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        tableView.tableHeaderView = searchController.searchBar
        tableView.sectionIndexBackgroundColor = UIColor.clear
        tableView.sectionIndexTrackingBackgroundColor = .clear
        tableView.sectionIndexBackgroundColor = .clear
        self.tableView.layoutMargins = .zero
    }

    // Handle what happens when we search.
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text
        // remove all of our previous searches.
        filtered.removeAll(keepingCapacity: false)
        if self.searchController.isActive {
            // double check the string isnt empty.
            // If it is empty, lets build our default search results
            // of all of our generic items.
            guard let myString = searchText, !myString.isEmpty else {
                return
            }
            // Search was not empty, so lets build a search on our
            // ViewControllers didSearch method.
            filtered = didSearch(searchText!)
            self.tableView.reloadData()
        }

        // Since search may no longer be active, lets clear any selections
        // and reload the data.
        if self.selectedIndexPath != nil {
            self.tableView.deselectRow(at: self.selectedIndexPath!, animated: true)
            self.selectedIndexPath = nil
        }
        self.tableView.reloadData()

    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // If were on a selected row, lets make the height our selected height.
        // Otherwise return the cellHeight.
        if indexPath == self.selectedIndexPath {
            return CGFloat(self.cellSelectedHeight!)
        } else {
            return CGFloat(cellHeight)
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // If we selected a row that is already selected
        if indexPath == self.selectedIndexPath {
            didSelectSelectedRow(self)
        } else {
            // Otherwise lets run our didSelect call which can be passed in
            // by anyone who creates this class.
            self.selectedIndexPath = indexPath
            let item = sectionedData[indexPath.section][indexPath.row]
            tableView.beginUpdates()
            didSelect(item)
            tableView.endUpdates()
        }
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // if Search is active lets return our filtered search, otherwise
        // return our items.
        if self.searchController.isActive {
            return filtered.count
        }
        return sectionedData[section].count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if self.searchController.isActive {
            return 1
        }
        return sectionedData.count
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionIndexTitles()
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var item:Item

        // If our search is active we need to build
        // the row from the filtered items array.
        // Otherwise we use our default Items array.
        if self.searchController.isActive {
            // User may scroll during search, before actually having searched
            // This prevents an app crash incase that happens.
            if (filtered.count >= 1) {
                item = filtered[indexPath.row]
            } else {
                item = sectionedData[indexPath.section][indexPath.row]
            }
        } else {
            item = sectionedData[indexPath.section][indexPath.row]
        }

        let definition = cellDefinition(item)

        // Cache our cell.
        if !reuseIdentifiers.contains(definition.reuseIdentifier) {
            tableView.register(definition.cellClass, forCellReuseIdentifier: definition.reuseIdentifier)
            reuseIdentifiers.insert(definition.reuseIdentifier)
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: definition.reuseIdentifier, for: indexPath)
        // Run our configuration defined for our custom generic cell.
        // See line 60 of Contact.swift or line 36 of Instructor.swift
        definition.configure(cell)
        return cell
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.searchController.isActive {
            return nil
        }
        return titleInHeaderForSection(section)
    }

    override func viewWillDisappear(_ animated: Bool) {
        // Disable search forecfully incase user was searching when they hit back.
        searchController.searchBar.isHidden = true
        searchController.isActive = false
    }

}
