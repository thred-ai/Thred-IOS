//
//  ColorSectionFlowLayout.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class ColorSectionFlowLayout: UICollectionViewFlowLayout {

    let innerSpace: CGFloat = 15
    let numberOfCellsOnRow: CGFloat = 2
    override init() {
        super.init()
        self.minimumLineSpacing = innerSpace
        self.minimumInteritemSpacing = innerSpace
        self.scrollDirection = .vertical
        
        minimumInteritemSpacing = 2.5
        minimumLineSpacing = 10
        
        sectionInset.left = 10
        sectionInset.right = 10
        sectionInset.top = 10
        sectionInset.bottom = 10
        
        headerReferenceSize.height = 436
        footerReferenceSize.height = 120
    }
    required init?(coder aDecoder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)
    }
    func itemWidth() -> CGFloat {
        return (collectionView!.frame.size.width/self.numberOfCellsOnRow)-self.innerSpace
    }
    
    let ratio = 1.0

    override var itemSize: CGSize {
        set {
            self.itemSize = CGSize(width:itemWidth(), height:itemWidth() * CGFloat(ratio))
        }
        get {
            return CGSize(width:itemWidth(),height:itemWidth() * CGFloat(ratio))
        }
    }
    
}
