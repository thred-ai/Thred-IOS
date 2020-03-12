//
//  ExplorePageFlowLayout.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-27.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class ExplorePageFlowLayout: UICollectionViewFlowLayout {

    var canvasInfo = CanvasInfo()

    let innerSpace: CGFloat = 0.5
    let numberOfCellsOnRow: CGFloat = 3.5
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
            self.itemSize = CGSize(width:itemWidth(), height:itemWidth() * canvasInfo.aspectRatio
)
        }
        get {
            return CGSize(width:itemWidth(),height:itemWidth() * canvasInfo.aspectRatio
)
        }
    }
}
