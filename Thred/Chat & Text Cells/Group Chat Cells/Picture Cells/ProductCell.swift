//
//  ProductCell.swift
//  Pictomap
//
//  Created by Artak on 2018-12-17.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import FirebaseUI
import ColorCompatibility


class ProductCell: UITableViewCell {

    @IBOutlet weak var quickLikeproductBtn: UIButton!
    
    @IBOutlet var dpMaskingViews: [UIView]!
    
    @IBOutlet var nameMaskingViews: [UIView]!
    
    
    @IBOutlet weak var timestampLbl: UILabel!
    
    @IBOutlet weak var dpSkeletonView: SkeletonView!
    
    @IBOutlet weak var nameSkeletonView: SkeletonView!
    
    @IBOutlet weak var joinProductBtn: UIButton!
    
    
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var productPicture: UIImageView!
    @IBOutlet weak var imageStackBar: UIStackView!
    
    @IBOutlet weak var likeBtn: UIButton!
    
    @IBOutlet weak var productDescription: UITextView!
    
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var title: UILabel!
    
    
    var product: Product!
    
    let circularProgress = CircularProgress(frame: CGRect(x: 0, y: 0, width: 80, height: 80))

    var imageCenter: CGPoint!
    
    let selectedColor = UIColor(red: 1, green: 0, blue: 0.3137, alpha: 0.9) /* #ff0050 */
    
    let likedImage = UIImage(named: "liked")
    let unlikedImage = UIImage(named: "like")

    @IBAction func likeDesign(_ sender: UIButton) {
        
        if likeBtn.currentImage == unlikedImage{
        likeBtn.setImage(likedImage?.imageWithColor(selectedColor), for: .normal)
            likeBtn.alpha = 0.0
            likeBtn.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            UIView.animate(withDuration: 0.2, animations: {
                self.likeBtn.transform = CGAffineTransform.identity
                self.likeBtn.alpha = 1.0
            }, completion: { finished in
                if finished{
                    self.likeBtn.imageView!.startAnimating()
                    //Like the post in database
                }
            })
        }
        else{
            likeBtn.setImage(unlikedImage, for: .normal)
            likeBtn.alpha = 0.0
            likeBtn.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            UIView.animate(withDuration: 0.2, animations: {
                self.likeBtn.transform = CGAffineTransform.identity
                self.likeBtn.alpha = 1.0
            }, completion: { finished in
                //Unlike the post in database
            })
        }
    
        
        //like the design

    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        imageCenter = productPicture.center
        likeBtn.imageView?.animationImages = [
            (likedImage?.imageWithColor(selectedColor))!,
            (UIImage(named: "flap1")?.imageWithColor(selectedColor))!,
            (UIImage(named: "flap2")?.imageWithColor(selectedColor))!,
            (UIImage(named: "flap3")?.imageWithColor(selectedColor))!,
            (UIImage(named: "flap4")?.imageWithColor(selectedColor))!,
            (UIImage(named: "flap3")?.imageWithColor(selectedColor))!,
            (UIImage(named: "flap2")?.imageWithColor(selectedColor))!,
            (UIImage(named: "flap1")?.imageWithColor(selectedColor))!,
            (likedImage?.imageWithColor(selectedColor))!
        ]
        
        likeBtn.imageView?.animationDuration = 0.5
        likeBtn.imageView?.animationRepeatCount = 1
        likeBtn.setRadiusWithShadow()
        
        likeBtn.setImage(unlikedImage, for: .normal)
        likeBtn.tintColor = UIColor.darkGray
        
        if let dpMask = self.dpMaskingViews.first{
            dpMask.layer.cornerRadius = dpMask.frame.height / 2
            dpMask.clipsToBounds = true
        }
        setUpCircularProgress()
        
        productPicture.isUserInteractionEnabled = true
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleZoom(_:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        
        // Use 2 thingers to move the view
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        
        // We delegate gestures so we can
        // perform both at the same time
        pan.delegate = self
        pinch.delegate = self
        
        // Add the gestures to our target (imageView)
        productPicture.addGestureRecognizer(pinch)
        productPicture.addGestureRecognizer(pan)
        
        // Here some basic setup
        //view.addSubView(overlay)
        //view.bringSubViewToFront(imageView)

    }
    
    func setUpCircularProgress(){
        
        if !self.productPicture.subviews.contains(circularProgress){
            circularProgress.isHidden = true
            circularProgress.progressColor = (UIColor(named: "loadingColor") ?? UIColor(red: 0.4235, green: 0.7863, blue: 0.9882, alpha: 1)) /* #e0e0e0 */
            circularProgress.trackColor = ColorCompatibility.systemFill
            circularProgress.translatesAutoresizingMaskIntoConstraints = false
            self.productPicture.addSubview(circularProgress)
            self.bringSubviewToFront(circularProgress)
            NSLayoutConstraint.activate([
                circularProgress.heightAnchor.constraint(equalToConstant: 80),
                circularProgress.widthAnchor.constraint(equalToConstant: 80),
                circularProgress.centerXAnchor.constraint(equalTo: self.productPicture.centerXAnchor),
                circularProgress.centerYAnchor.constraint(equalTo: self.productPicture.centerYAnchor)
            ])
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
         userImage.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        self.userImage.layer.cornerRadius = self.userImage.frame.height / 2
        self.userImage.clipsToBounds = true
        self.userImage.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        self.userImage.layer.borderWidth = self.userImage.frame.height / 17.75

        //self.circularProgress.center.y = self.productPicture.center.y
        //self.circularProgress.center.x = self.productPicture.center.x

        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        productPicture.image = nil
        //Stop or reset anything else that is needed here
    }

}

extension ProductCell{
    // that method make it works
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func hideCells(tabBar: UITabBar?, visibleCells: [UITableViewCell]?, newPostBtn: UIButton?){
        
        if tabBar?.alpha == 1.0{
            self.timestampLbl.isHidden = true
            UIView.animate(withDuration: 0.2, animations: {[unowned self] in
                tabBar?.alpha = 0.0
                newPostBtn?.alpha = 0.0
                self.fullName.alpha = 0.0
                self.username.alpha = 0.0
                self.userImage.alpha = 0.0
                self.productDescription.alpha = 0.0
                self.price.alpha = 0.0
                self.timestampLbl.alpha = 0.0
                self.title.alpha = 0.0
                self.imageStackBar.alpha = 0.0

                for cell in visibleCells ?? []{
                    if cell != self{
                        cell.alpha = 0.0
                    }
                }
            }, completion: {[unowned self] completed in
                if completed{
                    self.imageStackBar.isHidden = true

                    //self.animateName()
                }
            })
        }
    }
    
    func showCells(tabBar: UITabBar?, visibleCells: [UITableViewCell]?, newPostBtn: UIButton?){
        if tabBar?.alpha == 0.0{
            self.timestampLbl.isHidden = false
            self.imageStackBar.isHidden = false

            UIView.animate(withDuration: 0.2, animations: {[unowned self] in
                tabBar?.alpha = 1.0
                newPostBtn?.alpha = 1.0
                self.fullName.alpha = 1.0
                self.username.alpha = 1.0
                self.userImage.alpha = 1.0
                self.productDescription.alpha = 1.0
                self.price.alpha = 1.0
                self.timestampLbl.alpha = 1.0
                self.title.alpha = 1.0
                self.imageStackBar.alpha = 1.0
                for cell in visibleCells ?? []{
                    if cell != self{
                        cell.alpha = 1.0
                    }
                }
            }, completion: {[unowned self] completed in
                if completed{
                    
                }
            })
        }
    }
    
    func createStackView() -> UIStackView{
        
        let stackView = UIStackView()
        
        let label1 = title.copy() as! UILabel
        let label2 = title.copy() as! UILabel
        let label3 = title.copy() as! UILabel
        
        label1.alpha = 1.0
        label1.text = "Thred \(self.username.text ?? "null")"

        label2.alpha = 1.0
        label2.text = "Thred \(self.username.text ?? "null")"
        
        label3.alpha = 1.0
        label3.text = "Thred \(self.username.text ?? "null")"
        
        stackView.addArrangedSubview(label1)
        stackView.addArrangedSubview(label2)
        stackView.addArrangedSubview(label3)
        
        stackView.spacing = 2.0
        
        return stackView

    }
    
    func animateName(){
        
        //let stackView = createStackView()
        //self.productPicture.addSubview(stackView)
        
        UIView.animate(withDuration: 10, animations: {[unowned self] in
            self.title.transform = CGAffineTransform(translationX: self.frame.width - 10, y: 0)
        }, completion: {[unowned self] completed in
            if completed{
                
                if self.productDescription.alpha == 0.0{
                    
                    self.title.transform = CGAffineTransform(translationX: -(self.frame.width - 10), y: 0)
                    self.animateName()
                }
            }
        })
    }
    
    @objc func handleZoom(_ gesture: UIPinchGestureRecognizer) {
        if let tableController = self.parentViewController as? UITableViewController{
            switch gesture.state {
            case .began, .changed:
                // Only zoom in, not out
                if gesture.scale >= 1 {
                  
                    // Get the scale from the gesture passed in the function
                    let scale = gesture.scale
                  
                    // use CGAffineTransform to transform the imageView
                    gesture.view!.transform = CGAffineTransform(scaleX: scale, y: scale)
                }
              

                // Show the overlay
                self.hideCells(tabBar: tableController.tabBarController?.tabBar, visibleCells: tableController.tableView.visibleCells, newPostBtn: (tableController.tabBarController as? MainTabBarViewController)?.button)
                break;
            default:
                // If the gesture has cancelled/terminated/failed or everything else that's not performing
                // Smoothly restore the transform to the "original"
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                  gesture.view!.transform = .identity
                }) { _ in
                  // Hide the overlay
                  self.showCells(tabBar: tableController.tabBarController?.tabBar, visibleCells: tableController.tableView.visibleCells, newPostBtn: (tableController.tabBarController as? MainTabBarViewController)?.button)

                }
            }
        }
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        if let tableController = self.parentViewController as? UITableViewController{
            switch gesture.state {
            case .began, .changed:
                // Get the touch position
                tableController.tableView.isScrollEnabled = false
                let translation = gesture.translation(in: self.contentView)
                    
                // Edit the center of the target by adding the gesture position
                gesture.view?.center = CGPoint(x: productPicture.center.x + translation.x, y: productPicture.center.y + translation.y)
                gesture.setTranslation(.zero, in: self.contentView)

                // Show the overlay
                self.hideCells(tabBar: tableController.tabBarController?.tabBar, visibleCells: tableController.tableView.visibleCells, newPostBtn: (tableController.tabBarController as? MainTabBarViewController)?.button)

                break;
            default:
                // If the gesture has cancelled/terminated/failed or everything else that's not performing
                // Smoothly restore the transform to the "original"
                tableController.tableView.isScrollEnabled = true
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                    gesture.view?.center = self.imageCenter
                    gesture.setTranslation(.zero, in: self.contentView)
                    
                }) { _ in
                  // Hide the overaly
                  self.showCells(tabBar: tableController.tabBarController?.tabBar, visibleCells: tableController.tableView.visibleCells, newPostBtn: (tableController.tabBarController as? MainTabBarViewController)?.button)

                }
                break
            }
        }
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

extension UIImage {
    func imageWithColor(_ color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale);
        guard let context = UIGraphicsGetCurrentContext(), let cgImage = self.cgImage else { return nil }

        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0);
        context.setBlendMode(.normal)
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context.clip(to: rect, mask: cgImage)
        color.setFill()
        context.fill(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();

        return newImage
    }
}
