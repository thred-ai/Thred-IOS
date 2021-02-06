//
//  PhotoChooserLayout.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-08-04.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class PhotoChooserLayout: UICollectionViewFlowLayout {

    let innerSpace: CGFloat = 0
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
        return (collectionView!.frame.size.height)
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


