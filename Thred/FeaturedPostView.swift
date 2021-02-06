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
                trendingLbl.text = "🔥 What's Hot 🔥"
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
        for view in cell?.canvasDisplayViews ?? []{
            view.imageView?.image = nil
            view.setImage(nil, for: .normal)
        }
        cell?.nameLbl.text = nil
        cell?.priceLbl.text = nil
        cell?.likesLbl.text = nil
        cell?.imageView.alpha = 1.0
        cell?.isUserInteractionEnabled = false
        cell?.productRemovedView.isHidden = true
        cell?.isRemoved = false
        var product: Product!
        
        if vc is ExploreViewController{
            cell?.dotLabel.isHidden = false
            guard featuredProducts.indices.contains(indexPath.item) else{return cell!}
            product = featuredProducts[indexPath.item]
            cell?.nameLbl.text = product.name
            cell?.priceLbl.text = product.price?.formatPrice()
            let display = all.tees.first(where: {$0.productCode == product.productType})?.info
            cell?.likesLbl.text = display
            cell?.likesLbl.font = UIFont(name: "NexaW01-Heavy", size: 12)
        }
        else if vc is FullOrderVC{
            cell?.dotLabel.isHidden = true
            
            guard let orderProducts = order.products, orderProducts.indices.contains(indexPath.item), let price = orderProducts[indexPath.item].product?.price, let quantity = orderProducts[indexPath.item].quantity, let size = orderProducts[indexPath.item].size else{return cell!}
            cell?.isRemoved = orderProducts[indexPath.item].isDeleted
            
            product = orderProducts[indexPath.item].product
            cell?.nameLbl.text = product.name
            cell?.priceLbl.text = "\(quantity) x \(price.formatPrice(addCurrency: order.currency?.shortenCurrency() ?? ""))"
            cell?.likesLbl.text = "Size: \(size)"
        }
        
        
        let type = all.tees.first(where: {$0.productCode == product.productType})
        cell?.product = product
        cell?.addConstraints(template: type)

        
        DispatchQueue(label: "cache").async {
            var prefix = ""
            if product.displaySide == "back" || product.displaySide == "Back"{
                prefix = "BACK_"
            }
            
            let picString = "\(prefix)\(product.productID)"
            if let img = cache.imageFromCache(forKey: picString){
                guard let color = all.tees.first(where: {$0.productCode == product.productType})?.colors?.first(where: {$0.code == product.templateColor})
                else{return}
                
                var data: Data!
                
                if product.displaySide == "back" || product.displaySide == "Back"{
                    data = color.imgBack
                }
                else{
                    data = color.img
                }
                let image = UIImage(data: data)
                DispatchQueue.main.async {
                    cell?.isUserInteractionEnabled = true
                    cell?.circularProgress.isHidden = true
                    for view in cell?.canvasDisplayViews ?? []{
                        view.imageView?.image = img
                        view.setImage(img, for: .normal)
                    }
                    cell?.imageView.image = image
                    if !(product.isAvailable ?? false){
                        cell?.imageView.alpha = 0.5
                    }
                }
            }
            else{
                DispatchQueue.main.async {
                    UIApplication.shared.downloadExploreProductImage(circularProgress: cell?.circularProgress, followingUID: product.userInfo.uid ?? "", picID: product.productID, index: indexPath.item, product: product, isThumbnail: false, completed: { image in
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
        
        
            
            if let exploreVC = self.vc as? ExploreViewController{
                guard self.featuredProducts.indices.contains(indexPath.item) else{return}
                let product = self.featuredProducts[indexPath.item]
                exploreVC.productToOpen = product
            }
            else if let orderVC = self.vc as? FullOrderVC{
                guard self.order.products?.indices.contains(indexPath.item) ?? false else{return}
                let product = self.order.products?[indexPath.item].product
                orderVC.productToOpen = product
            }
        
        self.vc?.performSegue(withIdentifier: "toFull", sender: nil)
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
        DispatchQueue.main.async {
            self.collectionView.superview?.roundCorners([.bottomLeft, .bottomRight], radius: self.collectionView.frame.height / 40)
            if let trendingBack = self.trendingLbl.superview{
                if self.numberOfItems != nil{
                    trendingBack.roundCorners([.bottomLeft, .bottomRight], radius: 4)
                    trendingBack.clipsToBounds = true
                }
            }
        }
    }
    
}
