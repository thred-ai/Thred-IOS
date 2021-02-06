//
//  StoryFlowLayout.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-09-09.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

//
//  StoryFlowLayout.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class StoryFlowLayout: UICollectionViewFlowLayout {

    let innerSpace: CGFloat = 22.5
    let numberOfCellsOnRow: CGFloat = 2
    override init() {
        super.init()
        self.minimumLineSpacing = innerSpace
        self.minimumInteritemSpacing = innerSpace
        self.scrollDirection = .vertical
    }
    required init?(coder aDecoder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)
    }
    func itemWidth() -> CGFloat {
        return (collectionView!.frame.size.width/self.numberOfCellsOnRow)-self.innerSpace
    }
    
    let ratio = all.tees.first(where: {$0.productCode == "ATC1000"})?.supportedSides.first(where: {$0.name == "Front"})?.aspectRatio ?? 0

    override var itemSize: CGSize {
        set {
            
            self.itemSize = CGSize(width:itemWidth(), height:itemWidth() * ratio)
        }
        get {
            return CGSize(width:itemWidth(),height:itemWidth() * ratio)
        }
    }
}

