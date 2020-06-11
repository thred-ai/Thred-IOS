//
//  DrawToolsLayout.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-08.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class DrawToolsLayout: UICollectionViewFlowLayout {

    let innerSpace: CGFloat = 0
    let numberOfCellsOnRow: CGFloat = 4
    
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
    func itemWidth() -> CGFloat {
        return (collectionView!.frame.size.width/self.numberOfCellsOnRow)-self.innerSpace
    }
    func itemHeight() -> CGFloat {
        return collectionView!.contentSize.height
    }
    override var itemSize: CGSize {
        set {
            self.itemSize = CGSize(width:itemWidth(), height:itemHeight())
        }
        get {
            return CGSize(width:itemWidth(),height:itemHeight())
        }
    }
}


