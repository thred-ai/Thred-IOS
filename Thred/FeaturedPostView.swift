//
//  FeaturedPostView.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-04-09.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class FeaturedPostView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var featuredProducts = [Product]()
    var exploreVC: ExploreViewController!
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return featuredProducts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeaturedCell", for: indexPath) as? FeaturedCell
        cell?.imageView.image = nil
        cell?.canvasDisplayView.image = nil
        cell?.nameLbl.text = nil
        cell?.priceLbl.text = nil
        cell?.likesLbl.text = "0"
        
        print(featuredProducts.count)
        
        let product = featuredProducts[indexPath.item]
        cell?.nameLbl.text = product.name
        cell?.priceLbl.text = product.price?.formatPrice()

        cell?.likesLbl.text = "\(product.likes)"

        DispatchQueue(label: "cache").async {
            if let img = cache.imageFromCache(forKey: product.productID){
                let bundlePath = Bundle.main.path(forResource: product.templateColor, ofType: "png")
                let image = UIImage(contentsOfFile: bundlePath!)
                DispatchQueue.main.async {
                    cell?.circularProgress.isHidden = true
                    cell?.canvasDisplayView.image = img
                    cell?.imageView.image = image
                    cell?.imageView.addShadowToImageNotLayer()
                }
            }
            else{
                DispatchQueue.main.async {
                    collectionView.downloadExploreProductImage(circularProgress: cell?.circularProgress, followingUID: product.uid, picID: product.productID, index: indexPath.item, product: product, isThumbnail: false, completed: { image in
                        collectionView.performBatchUpdates({
                            collectionView.reloadItems(at: [indexPath])
                        }, completion: nil)
                    })
                }
            }
        }
        
        return cell!
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        return size
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let product = featuredProducts[indexPath.row]
        guard let cell = collectionView.cellForItem(at: indexPath) as? FeaturedCell else{return}
        guard let imageData = product.designImage ?? cell.imageView.makeSnapshot(clear: false, subviewsToIgnore: [])?.pngData() else{
            return
        }
        DispatchQueue.main.async {
            product.designImage = imageData
            self.exploreVC.productToOpen = product
            self.exploreVC.performSegue(withIdentifier: "toFull", sender: nil)
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
    }
    
}
