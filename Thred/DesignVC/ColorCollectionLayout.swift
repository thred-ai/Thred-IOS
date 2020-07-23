//
//  ColorCollectionLayout.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-08.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class ColorCollectionLayout: UICollectionViewFlowLayout {

    let innerSpace: CGFloat = 2
    let numberOfCellsOnRow: CGFloat = 10
    
    override func awakeFromNib() {
        self.minimumLineSpacing = innerSpace
        self.minimumInteritemSpacing = innerSpace
        self.scrollDirection = .horizontal
    }
    
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
    override var itemSize: CGSize {
        set {
            self.itemSize = CGSize(width:itemWidth(), height:itemWidth())
        }
        get {
            return CGSize(width:itemWidth(),height:itemWidth())
        }
    }
}

