//
//  TemplateCarousel.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-07.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility

class TemplateCarousel: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    
    public var displayImage: UIImage?
    
    var slides = [TemplateCarouselSlide]()
     
    deinit {
        print("")
        
    }
    
    func setCarouselTemplates(templates: [Template]){
        for (index, template) in templates.enumerated(){
            guard let templateImage = UIImage(named: template.templateID) else{
                
                continue}
            let slide = TemplateCarouselSlide(image: templateImage, canvasColor: UIColor(named: templates[index].templateID)?.withAlphaComponent(0.25), canvasName: template.templateID)
            slides.append(slide)
            self.collectionView.performBatchUpdates({
                self.collectionView.insertItems(at: [IndexPath(item: index, section: 0)])
            }, completion: nil)
        }
    }
    
    
    public lazy var collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.isPagingEnabled = true
        cv.isPrefetchingEnabled = false
        cv.register(UINib(nibName: "carouselCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "slideCell")
        cv.clipsToBounds = true
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.bounces = true
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupCarousel()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setupCarousel() {
        self.backgroundColor = .clear
        
        self.addSubview(collectionView)
        NSLayoutConstraint(item: collectionView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: collectionView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: collectionView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: collectionView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0).isActive = true

    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "slideCell", for: indexPath) as? carouselCollectionViewCell
        
        cell?.canvasDisplayView.image = nil
        cell?.backgroundImageView.image = nil
        let slide = slides[indexPath.item]

        
        if displayImage != nil{
            cell?.canvasDisplayView.image = displayImage
            cell?.canvasDisplayView.layer.borderWidth = 0
            cell?.touchHereLabel.isHidden = true
        }
        else{
            cell?.canvasDisplayView.layer.borderWidth = 1
            cell?.touchHereLabel.isHidden = false
            
            if slide.canvasColorName == "white"{
                cell?.canvasDisplayView.layer.borderColor = UIColor.lightGray.cgColor
                cell?.touchHereLabel.textColor = .lightGray
            }
            else{
                cell?.canvasDisplayView.layer.borderColor = UIColor.white.cgColor
                cell?.touchHereLabel.textColor = .white
            }
            
        }
        cell?.parseData(forSlide: slide)
        return cell!
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.slides.count
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        
        return size
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
    
}






