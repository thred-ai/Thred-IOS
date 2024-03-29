//
//  ExplorePageFlowLayout.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-27.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class ExplorePageFlowLayout: UICollectionViewFlowLayout {

    let innerSpace: CGFloat = 2
    override init() {
        super.init()
        self.minimumLineSpacing = innerSpace
        self.minimumInteritemSpacing = innerSpace
        self.scrollDirection = .horizontal
    }
    required init?(coder aDecoder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)
    }
    
    let aspectRatio = 1.0
    
    func itemWidth() -> CGFloat {
        let width = collectionView!.frame.size.height / CGFloat((aspectRatio)) - innerSpace
        return (width)
    }
    override var itemSize: CGSize {
        set {
            self.itemSize = CGSize(width:itemWidth(), height: collectionView!.frame.size.height)
        }
        get {
            return CGSize(width:itemWidth(), height: collectionView!.frame.size.height)
        }
    }
}
