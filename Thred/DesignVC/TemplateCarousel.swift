//
//  TemplateCarousel.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-07.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility
import SwiftyDraw


class TemplateCarousel: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    var vc: DesignViewController!

    var slides: [TemplateCarouselSlide]! = [TemplateCarouselSlide]()
     
    override class func awakeFromNib() {
        
    }
    
    override func awakeFromNib() {
        isUserInteractionEnabled = true
    }
    
    func setCarouselTemplates(templates: [Template]){
        slides.removeAll()

        for template in templates{
            for color in template.colors{
                let slide = TemplateCarouselSlide(color: color)
                slide.type = template.templateID
                slides.append(slide)
            }
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
        cv.backgroundColor = UIColor(named: "ProductColor")
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
        
        for view in cell?.canvasDisplayViews ?? []{
            view.imageView?.image = nil
            view.setImage(nil, for: .normal)
            view.isHidden = false
        }
        
        cell?.backgroundImageView.image = nil
        cell?.vc = nil
        cell?.unavailableLabel.isHidden = true
        vc?.zoomBtn.isHidden = false
        cell?.vc = vc

        
        let slides = self.slides!
        
        let slide = slides[indexPath.item]
        
        if let template = all.tees.first(where: {$0.templateID == slide.type}){
            //cell?.rightArmCanvasDisplayView.isHidden = !template.supportedSides.contains("Side")
            //cell?.leftArmCanvasDisplayView.isHidden = !template.supportedSides.contains("Side")
            cell?.addConstraints(template: template)
        }

        setCell(cell: cell, slide: slide)

        //showUnavailableView(cell: cell)

        
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    func showUnavailableView(cell: CarouselCollectionViewCell?){
        
        //cell?.canvasDisplayView.isHidden = true
        cell?.unavailableLabel.isHidden = false
        vc?.zoomBtn.isHidden = true
    }
    
    func currentImage() -> UIImage?{
        guard let images = vc?.canvasDesigns, !images.isEmpty, let selectedSide = vc?.selectedSide else{return nil}
        
        if let displayImgData = images.first(where: {$0.name == selectedSide.name})?.currentImage, let displayImage = UIImage(data: displayImgData){
            return displayImage
        }
        return nil
    }
    
    func replaceImageSide(side: TemplateSide, with image: UIImage?, onlyReplaceImage: Bool = false){
        if let sameDisplay = vc?.canvasDesigns.first(where: {$0.name == side.name}){
            sameDisplay.currentImage = image?.pngData()
            
            if onlyReplaceImage{return}
            var drawItems = [SwiftyDraw.SwiftyDrawView.DrawItem]()
            var subviews = [UIView]()
            for item in vc?.drawCanvas.drawItems ?? []{
                drawItems.append(item.copy())
            }
            for item in vc?.canvas.subviews.filter({$0.isKind(of: UIImageView.self) || ($0.isKind(of: UITextView.self))}) ?? []{
                subviews.append(item)
            }
            sameDisplay.drawItems.removeAll()
            sameDisplay.subviews.removeAll()
            sameDisplay.drawItems.append(contentsOf: drawItems)
            sameDisplay.subviews.append(contentsOf: subviews)
        }
        else{
            let design = CanvasDesign(drawItems: [], subviews: [], name: side.name ?? "", currentImage: image?.pngData())
            vc?.canvasDesigns.append(design)
            design.currentImage = image?.pngData()
            if onlyReplaceImage{return}

            var drawItems = [SwiftyDraw.SwiftyDrawView.DrawItem]()
            var subviews = [UIView]()
            
            for item in vc?.drawCanvas.drawItems ?? []{
                drawItems.append(item.copy())
            }
            for item in vc?.canvas.subviews.filter({$0.isKind(of: UIImageView.self) || ($0.isKind(of: UITextView.self))}) ?? []{
                subviews.append(item)
            }
            design.drawItems.removeAll()
            design.subviews.removeAll()
            design.drawItems.append(contentsOf: drawItems)
            design.subviews.append(contentsOf: subviews)
        }
    }
    
    func setCell(cell: CarouselCollectionViewCell?, slide: TemplateCarouselSlide){
        
        guard let selectedSide = vc?.selectedSide else{return}

        switch vc?.canvasDesigns{
        case .some:
            
            guard let images = vc?.canvasDesigns.filter({$0.currentImage != nil}), !(images.isEmpty) else{fallthrough}
            print(images.count)
            
            for view in cell?.canvasDisplayViews ?? []{
                if let displayImgData = vc?.canvasDesigns.first(where: {$0.name == selectedSide.name})?.currentImage, let displayImage = UIImage(data: displayImgData){
                    view.imageView?.image = displayImage
                    view.setImage(displayImage, for: .normal)
                    view.layer.borderWidth = 0
                    for view in cell?.touchHereLbls ?? []{
                        view.isHidden = true
                    }
                }
                else{
                    fallthrough
                }
            }
        default:
            
            
            for view in cell?.canvasDisplayViews ?? []{
                view.layer.borderWidth = 2
            }
            
            for view in cell?.touchHereLbls ?? []{
                view.isHidden = false
            }
            vc?.rotateBtn.superview?.superview?.backgroundColor = UIColor(named: "LoadingColor")
            vc?.rotateBtn.setTitleColor(.white, for: .normal)

            //vc?.rotateBtn.superview?.layer.borderWidth = 2
            //vc?.rotateBtn.superview?.removeShadow()
            //vc?.rotateBtn.superview?.setRadiusWithShadow()
            if slide.color?.code == "white"{
                for view in cell?.canvasDisplayViews ?? []{
                    view.layer.borderWidth = 2
                    view.layer.borderColor = UIColor.lightGray.cgColor
                }
                
                //cell?.leftArmCanvasDisplayView.layer.sublayers?.removeAll(where: {$0.backgroundColor == UIColor.white.cgColor})
                //cell?.rightArmCanvasDisplayView.layer.sublayers?.removeAll(where: {$0.backgroundColor == UIColor.white.cgColor})

                //cell?.leftArmCanvasDisplayView.addBorders(to: [.top, .bottom, .right], color: .lightGray, width: 1)
                //cell?.rightArmCanvasDisplayView.addBorders(to: [.top, .bottom, .left], color: .lightGray, width: 1)
                
                for view in cell?.touchHereLbls ?? []{
                    view.textColor = .lightGray
                }
                
                //vc?.rotateBtn.setTitleColor(.gray, for: .normal)
                //vc?.rotateBtn.superview?.layer.borderColor = UIColor.gray.cgColor

            }
            else{
                //cell?.canvasDisplayView.layer.borderColor = UIColor.white.cgColor
                //cell?.leftArmCanvasDisplayView.layer.sublayers?.removeAll(where: {$0.backgroundColor == UIColor.lightGray.cgColor})
                //cell?.rightArmCanvasDisplayView.layer.sublayers?.removeAll(where: {$0.backgroundColor == UIColor.lightGray.cgColor})

                //cell?.leftArmCanvasDisplayView.addBorders(to: [.top, .bottom, .right], color: .white, width: 1)
                //cell?.rightArmCanvasDisplayView.addBorders(to: [.top, .bottom, .left], color: .white, width: 1)

                for view in cell?.touchHereLbls ?? []{
                    view.textColor = .white
                }
                //vc?.rotateBtn.superview?.layer.borderColor = UIColor.white.cgColor
            }
        }
        vc?.colorDisplayLbl.text = slide.color.display
        vc?.colorDisplayLbl.superview?.isHidden = false
        guard let rgb = slide.color.rgb else{return}
        vc?.barView.backgroundColor = UIColor(red: CGFloat(rgb[0]), green: CGFloat(rgb[1]), blue: CGFloat(rgb[2]), alpha: 1)

        cell?.parseData(forSlide: slide)
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
        if all.tees.first(where: {$0.templateID == vc?.selectedProductType.templateID})?.colors.indices.contains(currentPage) ?? false{
            colorCollectionView.selectItem(at: IndexPath(item: currentPage, section: 0), animated: true, scrollPosition: .centeredHorizontally)
            DispatchQueue.main.async {
                if let item = colorCollectionView.indexPathsForSelectedItems?.first(where: {$0.item != currentPage}){
                    colorCollectionView.deselectItem(at: item, animated: false)
                }
                if let index = colorCollectionView.indexPathsForSelectedItems?.first(where: {$0.item == currentPage}), let cell = self.collectionView.cellForItem(at: index) as? CarouselCollectionViewCell, self.slides.indices.contains(index.item){
                    let slide = self.slides[index.item]
                    self.setCell(cell: cell, slide: slide)
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
        if all.tees.first(where: {$0.templateID == vc?.selectedProductType.templateID})?.colors.indices.contains(currentPage) ?? false{
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






