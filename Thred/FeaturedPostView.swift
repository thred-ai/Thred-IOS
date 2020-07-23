//
//  FeaturedPostView.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-04-09.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility

class FeaturedPostView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var collectionView: UICollectionView!
    var featuredProducts = [Product]()
    var order = Order()
    @IBOutlet weak var trendingLbl: UILabel!
    var vc: UIViewController! {
        didSet{
            if vc is ExploreViewController{
                trendingLbl.text = "Featured Five"
            }
            else if vc is FullOrderVC, let orderID = order.orderID{
                trendingLbl.text = "Order #: \(orderID)"
                unboldTitle(label: trendingLbl, orderNumber: orderID)
            }
        }
    }
    
    func unboldTitle(label: UILabel, orderNumber: String){
        let linkWords = "Order #:"
        label.text = nil
        let guideLineText = "Order #: \(orderNumber)"
        
        label.text = guideLineText
        
        let attrString = NSMutableAttributedString()
        if let text = label.attributedText{
            attrString.setAttributedString(text)
        }
        
        let nsText = NSString(string: guideLineText)
        let matchRange:NSRange = nsText.range(of: linkWords)
        let orderRange:NSRange = nsText.range(of: orderNumber)

        
        guard let font = UIFont(name: "NexaW01-Heavy", size: 12) else{return}
        
        let attributes = [
            NSAttributedString.Key.font : font,
            NSAttributedString.Key.foregroundColor : UIColor.tertiaryLabel
        ] as [NSAttributedString.Key : Any]
        
        guard let orderFont = UIFont(name: "NexaW01-Heavy", size: 12) else{return}
        
        let orderAttributes = [
            NSAttributedString.Key.font : orderFont,
            NSAttributedString.Key.foregroundColor : UIColor.label
        ] as [NSAttributedString.Key : Any]
        
        attrString.addAttributes(attributes, range: matchRange)
        attrString.addAttributes(orderAttributes, range: orderRange)

        label.attributedText = attrString
    }
    
    var numberOfItems: Int? {
        didSet{
            pageControl.numberOfPages = numberOfItems ?? 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if vc is ExploreViewController{
            return featuredProducts.count
        }
        return order.products?.count ?? 0
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeaturedCell", for: indexPath) as? FeaturedCell
        cell?.imageView.image = nil
        cell?.canvasDisplayView.image = nil
        cell?.nameLbl.text = nil
        cell?.priceLbl.text = nil
        cell?.likesLbl.text = "0"
        cell?.imageView.alpha = 1.0
        cell?.isUserInteractionEnabled = false
        cell?.productRemovedView.isHidden = true
        cell?.isRemoved = false
        var product: Product!
        if vc is ExploreViewController{
            cell?.dotLabel.isHidden = false
            cell?.thredIcon.isHidden = false
            guard featuredProducts.indices.contains(indexPath.item) else{return cell!}
            product = featuredProducts[indexPath.item]
            cell?.nameLbl.text = product.name
            cell?.priceLbl.text = product.price?.formatPrice()
            cell?.likesLbl.text = "\(product.likes)"
        }
        else if vc is FullOrderVC{
            cell?.dotLabel.isHidden = true
            cell?.thredIcon.isHidden = true
            
            guard let orderProducts = order.products, orderProducts.indices.contains(indexPath.item), let price = orderProducts[indexPath.item].product?.price, let quantity = orderProducts[indexPath.item].quantity, let size = orderProducts[indexPath.item].size else{return cell!}
            cell?.isRemoved = orderProducts[indexPath.item].isDeleted
            
            product = orderProducts[indexPath.item].product
            cell?.nameLbl.text = product.name
            cell?.priceLbl.text = "\(quantity) x \(price.formatPrice())"
            cell?.likesLbl.text = "Size: \(size)"
        }
        

        DispatchQueue(label: "cache").async {
            if let img = cache.imageFromCache(forKey: product.productID){
                guard let productType = product.productType?.productType() else{return}
                let bundlePath = Bundle.main.path(forResource: "\(productType)_\(product.templateColor ?? "")", ofType: "png")
                let image = UIImage(contentsOfFile: bundlePath!)
                DispatchQueue.main.async {
                    cell?.isUserInteractionEnabled = true
                    cell?.circularProgress.isHidden = true
                    cell?.canvasDisplayView.image = img
                    cell?.imageView.image = image
                    if !(product.isAvailable ?? false){
                        cell?.imageView.alpha = 0.5
                    }
                    cell?.imageView.addShadowToImageNotLayer()
                }
            }
            else{
                DispatchQueue.main.async {
                    collectionView.downloadExploreProductImage(circularProgress: cell?.circularProgress, followingUID: product.userInfo.uid ?? "", picID: product.productID, index: indexPath.item, product: product, isThumbnail: false, completed: { image in
                        collectionView.reloadData()
                    })
                }
            }
        }
        
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        var products: [Product]?
        if vc is ExploreViewController{
            products = featuredProducts
        }
        else if vc is FullOrderVC{
            products = order.products.compactMap({$0.product})
        }
        if products?.indices.contains(indexPath.item) ?? false{
            if indexPath.item == 0, products?[indexPath.item] == products?.last{
                cell.roundCorners([.bottomLeft, .bottomRight], radius: cell.frame.height / 40)
            }
            else{
                if indexPath.item == 0{
                    cell.roundCorners([.bottomLeft], radius: cell.frame.height / 40)
                }
                else if products?[indexPath.item] == products?.last{
                    cell.roundCorners([.bottomRight], radius: cell.frame.height / 40)
                }
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let x = scrollView.contentOffset.x
        let w = scrollView.bounds.size.width
        let currentPage = Int(ceil(x/w))
        pageControl.currentPage = currentPage
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        return size
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        
        DispatchQueue.main.async {
            
            if let exploreVC = self.vc as? ExploreViewController{
                let product = self.featuredProducts[indexPath.item]
                exploreVC.productToOpen = product
            }
            else if let orderVC = self.vc as? FullOrderVC{
                let product = self.order.products?[indexPath.item].product
                orderVC.productToOpen = product
            }
            self.vc.performSegue(withIdentifier: "toFull", sender: nil)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.register(UINib(nibName: "FeaturedCell", bundle: nil), forCellWithReuseIdentifier: "FeaturedCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        collectionView.setCollectionViewLayout(layout, animated: false)
    }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.superview?.roundCorners([.bottomLeft, .bottomRight], radius: collectionView.frame.height / 40)
        if let trendingBack = trendingLbl.superview{
            trendingBack.roundCorners([.bottomLeft, .bottomRight], radius: trendingBack.frame.height / 3)
            trendingBack.clipsToBounds = true
        }
    }
    
}
