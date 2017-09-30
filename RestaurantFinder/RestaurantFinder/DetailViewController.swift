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
    @IBOutlet weak var pageControl: UIPageControl!
    
    var photoUrls :[URL]?

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            if let label = detailDescriptionLabel {
                label.isHidden = true
            }
            navigationItem.title = detail.name
            nameLabel.text = nil
            nameLabel.isHidden = false
            addressLabel.text = detail.address
            addressLabel.isHidden = false
            commentLabel.isHidden = false
            commentView.isHidden = false
            pageControl.isHidden = true
        } else {
            if let label = detailDescriptionLabel {
                label.isHidden = false
            }
            navigationItem.title = "Detail"
            nameLabel.text = nil
            nameLabel.isHidden = true
            addressLabel.text = nil
            addressLabel.isHidden = true
            commentLabel.isHidden = true
            commentView.isHidden = true
            pageControl.isHidden = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureView()
        
        imageView.isUserInteractionEnabled = true
        let leftSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe))
        leftSwipeRecognizer.direction = .left
        let rightSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe))
        rightSwipeRecognizer.direction = .right
        imageView.addGestureRecognizer(leftSwipeRecognizer)
        imageView.addGestureRecognizer(rightSwipeRecognizer)

        loadReview()
        loadPhotos()
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
    
    func loadPhotos() {
        guard  let restaurant = detailItem  else {
            print("No detailItem")
            return
        }
        YelpRestaurantFinder.sharedInstance.queryRestaurantPhotos(restaurant: restaurant) { (urls, error) in
            if let photoUrls = urls {
                self.photoUrls = photoUrls
                self.pageControl.isHidden = photoUrls.count <= 1
                self.pageControl.numberOfPages = photoUrls.count
                self.pageControl.currentPage = 0
                self.loadImage()
            }
        }
    }

    func loadImage() {
        if let photoUrl = photoUrls?[pageControl.currentPage] {
            _ = self.imageView.asyncFetchImageFromServerURL(urlString: photoUrl.absoluteString, complete: { (_, _) in })
        }
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
    
    @objc func onSwipe(swipe: UISwipeGestureRecognizer) {
        if (swipe.direction == .left) {
//            print("Left Swipe")
            if pageControl.currentPage < pageControl.numberOfPages {
                pageControl.currentPage = pageControl.currentPage + 1
                loadImage()
            }
        }
        if (swipe.direction == .right) {
//            print("Right Swipe")
            if pageControl.currentPage > 0 {
                pageControl.currentPage = pageControl.currentPage - 1
                loadImage()
            }
        }
    }
}
