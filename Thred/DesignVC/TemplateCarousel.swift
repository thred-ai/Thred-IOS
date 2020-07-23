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
    var vc: DesignViewController!

    var slides: [TemplateCarouselSlide]! = [TemplateCarouselSlide]()
     
    override class func awakeFromNib() {
        
    }
    
    func setCarouselTemplates(templates: [Template]){
        slides.removeAll()
        for (index, template) in templates.enumerated(){
            let slide = TemplateCarouselSlide(canvasColor: UIColor(named: templates[index].templateID)?.withAlphaComponent(0.25), canvasName: template.templateDisplayName, canvasID: template.templateID, isFemale: template.hasFemale)
            slides.append(slide)
        }
        self.vc = getViewController() as? DesignViewController
        self.collectionView.reloadData()
    }
    
    
    public lazy var collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.isPagingEnabled = true
        cv.isPrefetchingEnabled = false
        cv.register(CarouselCollectionViewCell.self, forCellWithReuseIdentifier: "slideCell")
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
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "slideCell", for: indexPath) as? CarouselCollectionViewCell
        
        cell?.canvasDisplayView.image = nil
        cell?.canvasDisplayView.isHidden = false
        cell?.backgroundImageView.image = nil
        cell?.vc = nil
        cell?.unavailableLabel.isHidden = true
        cell?.colorDisplayLabel.text = nil
        cell?.colorDisplayLabel.isHidden = false
        vc?.thredWatermark.isHidden = false
        vc?.zoomBtn.isHidden = false
        
        let slide = slides[indexPath.item]

        cell?.colorDisplayLabel.isHidden = vc?.isEditingProduct ?? false
        
        switch slide.hasFemale ?? false{
            
        case false:
            if vc?.selectedProductType == .f_c{
                cell?.canvasDisplayView.isHidden = true
                cell?.unavailableLabel.isHidden = false
                cell?.colorDisplayLabel.isHidden = true
                vc?.thredWatermark.isHidden = true
                vc?.zoomBtn.isHidden = true
            }
            else{
                fallthrough
            }
        default:
            if displayImage != nil{
                cell?.canvasDisplayView.image = displayImage
                cell?.canvasDisplayView.layer.borderWidth = 0
                cell?.touchHereLabel.isHidden = true
            }
            else{
                cell?.canvasDisplayView.layer.borderWidth = 1
                cell?.touchHereLabel.isHidden = false
                if slide.canvasColorID == "white"{
                    cell?.canvasDisplayView.layer.borderColor = UIColor.lightGray.cgColor
                    cell?.touchHereLabel.textColor = .lightGray
                }
                else{
                    cell?.canvasDisplayView.layer.borderColor = UIColor.white.cgColor
                    cell?.touchHereLabel.textColor = .white
                }
            }
            cell?.vc = vc
            cell?.parseData(forSlide: slide)
        }
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        
        

    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let x = scrollView.contentOffset.x
        let w = scrollView.bounds.size.width
        let currentPage = Int(ceil(x/w))
        let vc = (getViewController() as? DesignViewController)
        guard let colorCollectionView = vc?.colorCollectionView else{return}
        if vc?.tees.indices.contains(currentPage) ?? false{
            colorCollectionView.selectItem(at: IndexPath(item: currentPage, section: 0), animated: true, scrollPosition: .centeredHorizontally)
            DispatchQueue.main.async {
                if let item = colorCollectionView.indexPathsForSelectedItems?.first(where: {$0.item != currentPage}){
                    colorCollectionView.deselectItem(at: item, animated: false)
                }
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let x = scrollView.contentOffset.x
        let w = scrollView.bounds.size.width
        let currentPage = Int(ceil(x/w))
        let vc = (getViewController() as? DesignViewController)
        guard let colorCollectionView = vc?.colorCollectionView else{return}
        if vc?.tees.indices.contains(currentPage) ?? false{
            colorCollectionView.selectItem(at: IndexPath(item: currentPage, section: 0), animated: true, scrollPosition: .centeredHorizontally)

            DispatchQueue.main.async {
                if let item = colorCollectionView.indexPathsForSelectedItems?.first(where: {$0.item != currentPage}){
                    colorCollectionView.deselectItem(at: item, animated: false)
                }
            }
        }
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
    
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
    
}






