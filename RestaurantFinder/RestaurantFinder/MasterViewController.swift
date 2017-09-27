//
//  MasterViewController.swift
//  RestaurantFinder
//
//  Created by Matthew Li on 2017-09-26.
//  Copyright © 2017 Matthew Li. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController, UISearchBarDelegate {

    var detailViewController: DetailViewController? = nil
    var objects = [IRestaurant]()
    var searchLatencyTimer: Timer?
    var orderAscending = true

    @IBOutlet weak var sortingButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.width, height: 44))
        searchBar.showsCancelButton = true
        searchBar.delegate = self
        tableView.tableHeaderView = searchBar
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        sortingButton.title = orderAscending ? "ASC":"DSD"

        refreshRestaurantList(keyword: nil)
    }
    
    func refreshRestaurantList(keyword: String!) {
        YelpRestaurantFinder.sharedInstance.queryRestaurants(keyword: keyword) { (restaurants, error) in
            if let e = error {
                var alertMsg = e.localizedDescription
                if let underlyingErr = e.userInfo[NSUnderlyingErrorKey] as? Error {
                    alertMsg = alertMsg + "\n " + underlyingErr.localizedDescription
                }
                let alert = UIAlertController(title: "Failed to Load Restaurant List",
                                              message: alertMsg,
                                              preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) in
                    self.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
                DispatchQueue.main.async {
                    self.objects = [IRestaurant]()
                    self.tableView.reloadData()
                }
            } else {
                if let restaurantArray = restaurants {
                    DispatchQueue.main.async {
                        self.objects = restaurantArray
                        self.objects.sort(by: { (restaurant1, restaurant2) -> Bool in
                            if self.orderAscending {
                                return restaurant1.name < restaurant2.name
                            } else {
                                return restaurant2.name < restaurant1.name
                            }
                        })
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onSortingButton() {
        orderAscending = !orderAscending
        objects.sort(by: { (restaurant1, restaurant2) -> Bool in
            if orderAscending {
                return restaurant1.name < restaurant2.name
            } else {
                return restaurant2.name < restaurant1.name
            }
        })
        tableView.reloadData()
        sortingButton.title = orderAscending ? "ASC":"DSD"
    }
    
    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantCell", for: indexPath)
        if let imageView = cell.contentView.viewWithTag(100) as? UIImageView {
            imageView.image = nil
        }
        
        let object = objects[indexPath.row]
        if let nameLabel = cell.contentView.viewWithTag(101) as? UILabel {
            nameLabel.text = object.name
        }
        if let addressLabel = cell.contentView.viewWithTag(102) as? UILabel {
            addressLabel.text = object.address
        }
        if let imageUrlStr = object.imageUrlStr {
            if let imageView = cell.contentView.viewWithTag(100) as? UIImageView {
                _ = imageView.asyncFetchImageFromServerURL(urlString: imageUrlStr, complete: { (_, _) in })
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    // MARK: - Search Bar
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchLatencyTimer?.invalidate()
        searchLatencyTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { _ in
            self.refreshRestaurantList(keyword: searchText)
        })
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        searchLatencyTimer?.invalidate()
        self.refreshRestaurantList(keyword: nil)
    }
}

