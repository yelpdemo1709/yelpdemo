//
//  DetailViewController.swift
//  RestaurantFinder
//
//  Created by Matthew Li on 2017-09-26.
//  Copyright © 2017 Matthew Li. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var commentView: UITextView!
    @IBOutlet weak var imageView: UIImageView!

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            if let label = detailDescriptionLabel {
                label.isHidden = true
            }
            nameLabel.text = detail.name
            nameLabel.isHidden = false
            addressLabel.text = detail.address
            addressLabel.isHidden = false
            commentLabel.isHidden = false
            commentView.isHidden = false
        } else {
            if let label = detailDescriptionLabel {
                label.isHidden = false
            }
            nameLabel.text = nil
            nameLabel.isHidden = true
            addressLabel.text = nil
            addressLabel.isHidden = true
            commentLabel.isHidden = true
            commentView.isHidden = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureView()
        
        loadImage()
        loadReview()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var detailItem: IRestaurant? {
        didSet {
            // Update the view.
//            configureView()
        }
    }

    func loadImage() {
        guard  let restaurant = detailItem  else {
            print("No detailItem")
            return
        }
        guard  let imageUrlStr = restaurant.imageUrlStr  else {
            print("No imageUrlStr")
            return
        }
        _ = imageView.asyncFetchImageFromServerURL(urlString: imageUrlStr, complete: { (_, _) in })
    }
    
    func loadReview() {
        guard  let restaurant = detailItem  else {
            print("No detailItem")
            return
        }
        YelpRestaurantFinder.sharedInstance.queryRestaurantReview(restaurant: restaurant) { (reviews, error) in
            if let e = error {
                var alertMsg = e.localizedDescription
                if let underlyingErr = e.userInfo[NSUnderlyingErrorKey] as? Error {
                    alertMsg = alertMsg + "\n " + underlyingErr.localizedDescription
                }
                let alert = UIAlertController(title: "Failed to Load Review",
                                              message: alertMsg,
                                              preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) in
                    self.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            } else {
                if let reviewsArray = reviews {
                    let sorted = reviewsArray.sorted(by: { (review1, review2) -> Bool in
                        return review1.timeCreated > review2.timeCreated
                    })
                    if sorted.count > 0 {
                        DispatchQueue.main.async {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "MMM dd, yyyy HH:mm"
                            self.commentLabel.text = sorted[0].username + "   at   " + dateFormatter.string(from: sorted[0].timeCreated)
                            self.commentView.text = sorted[0].text
                        }
                    }
                }
            }
        }
    }
}

