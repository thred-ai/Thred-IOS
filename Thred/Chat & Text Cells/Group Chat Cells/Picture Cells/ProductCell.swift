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
import FirebaseFunctions


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
    @IBOutlet weak var likesLbl: UILabel!
    
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
        
        sender.isEnabled = false
        if likeBtn.currentImage == unlikedImage{
        likesLbl.text = "\(product.likes + 1)"
        updateProductLiking(isLiking: true)
        updateLiking(isLiking: true)
        likeBtn.setImage(likedImage?.imageWithColor(selectedColor), for: .normal)
            likeBtn.alpha = 0.0
            likeBtn.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            UIView.animate(withDuration: 0.2, animations: {
                self.likeBtn.transform = CGAffineTransform.identity
                self.likeBtn.alpha = 1.0
            }, completion: { finished in
                if finished{
                    sender.isEnabled = true
                    self.likeBtn.imageView!.startAnimating()
                }
            })
        }
        else{
            likesLbl.text = "\(product.likes - 1)"
            updateProductLiking(isLiking: false)
            updateLiking(isLiking: false)
            likeBtn.setImage(unlikedImage, for: .normal)
            likeBtn.alpha = 0.0
            likeBtn.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            UIView.animate(withDuration: 0.2, animations: {
                self.likeBtn.transform = CGAffineTransform.identity
                self.likeBtn.alpha = 1.0
            }, completion: { finished in
                sender.isEnabled = true
            })
        }
    }
    
    func updateLiking(isLiking: Bool){
        
        let data = [
            "product_id" : product.productID,
            "creator_uid" : product.uid,
            "uid" : userInfo.uid,
            "is_liking" : isLiking
            ] as [String : Any]
        Functions.functions().httpsCallable("updateLiking").call(data, completion: { result, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                if isLiking{
                    userInfo.userLiked?.append(self.product.productID)
                }
                else{
                    userInfo.userLiked?.removeAll(where: {$0 == self.product.productID})
                }
                UserDefaults.standard.set(userInfo.userLiked, forKey: "LikedPosts")
            }
        })
    }
    
    func updateProductLiking(isLiking: Bool){
        var updateNum = -1
        if isLiking{
            updateNum = 1
        }
        switch self.getViewController(){
        case let feed as FeedVC:
            feed.loadedProducts.first(where: {$0.productID == self.product.productID})?.likes += updateNum
            feed.loadedProducts.saveAllObjects(type: "FeedProducts")
        case let user as UserVC:
            user.loadedProducts.first(where: {$0.productID == self.product.productID})?.likes += updateNum
            user.loadedProducts.saveAllObjects(type: "Products")
        case let friend as FriendVC:
            friend.loadedProducts.first(where: {$0.productID == self.product.productID})?.likes += updateNum
        default:
            break
        }
    }
    
    lazy var canvasDisplayView: UIImageView = {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        view.isUserInteractionEnabled = true
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
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
        
        //let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleZoom(_:)))
        //let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        
        // Use 2 thingers to move the view
        //pan.minimumNumberOfTouches = 2
        //pan.maximumNumberOfTouches = 2
        
        // We delegate gestures so we can
        // perform both at the same time
       // pan.delegate = self
        //pinch.delegate = self
        
        // Add the gestures to our target (imageView)
        //productPicture.addGestureRecognizer(pinch)
        //productPicture.addGestureRecognizer(pan)
        
        // Here some basic setup
        //view.addSubView(overlay)
        //view.bringSubViewToFront(imageView)
        addSubview(canvasDisplayView)

        NSLayoutConstraint(item: canvasDisplayView, attribute: .centerX, relatedBy: .equal, toItem: productPicture, attribute: .centerX, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: canvasDisplayView, attribute: .centerY, relatedBy: .equal, toItem: productPicture, attribute: .centerY, multiplier: 1.0, constant: -20).isActive = true
        NSLayoutConstraint(item: canvasDisplayView, attribute: .width, relatedBy: .equal, toItem: productPicture, attribute: .width, multiplier: 0.3, constant: 0).isActive = true
        NSLayoutConstraint(item: canvasDisplayView, attribute: .height, relatedBy: .equal, toItem: productPicture, attribute: .height, multiplier: 0.475, constant: 0).isActive = true

        
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
