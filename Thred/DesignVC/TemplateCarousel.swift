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
    
    private var timer : Timer = Timer()
    public var interval : Double?
    public var displayImage: UIImage?
    
    public var slides : [TemplateCarouselSlide] = [] {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    func setCarouselTemplates(templates: [Template]){
        for (index, template) in templates.enumerated(){
            guard let templateImage = UIImage(data: template.templateData) else{continue}
            let slide = TemplateCarouselSlide(image: templateImage, canvasColor: UIColor(named: templates[index].templateID)?.withAlphaComponent(0.25), canvasName: template.templateID)
            slides.append(slide)
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
        cv.register(carouselCollectionViewCell.self, forCellWithReuseIdentifier: "slideCell")
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
        setupCarousel()
    }
    
    private func setupCarousel() {
        self.backgroundColor = .clear
        
        self.addSubview(collectionView)
        NSLayoutConstraint(item: collectionView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: collectionView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: collectionView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: collectionView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0).isActive = true

    }
    
    
    @objc private func tapGestureHandler(tap: UITapGestureRecognizer?) {
        var visibleRect = CGRect()
        visibleRect.origin = collectionView.contentOffset
        visibleRect.size = collectionView.bounds.size
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        let visibleIndexPath: IndexPath = collectionView.indexPathForItem(at: visiblePoint) ?? IndexPath(item: 0, section: 0)
        let index = visibleIndexPath.item

        if index == (slides.count-1) {
            let indexPathToShow = IndexPath(item: 0, section: 0)
            self.collectionView.selectItem(at: indexPathToShow, animated: true, scrollPosition: .centeredHorizontally)
        } else {
            let indexPathToShow = IndexPath(item: (index + 1), section: 0)
            self.collectionView.selectItem(at: indexPathToShow, animated: true, scrollPosition: .centeredHorizontally)
        }
    }
    
    

    
    public func start() {
        timer = Timer.scheduledTimer(timeInterval: interval ?? 1.0, target: self, selector: #selector(tapGestureHandler(tap:)), userInfo: nil, repeats: true)
        timer.fire()
    }
    
    public func stop() {
        timer.invalidate()
    }
    
    
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "slideCell", for: indexPath) as? carouselCollectionViewCell
        
        cell?.canvasDisplayView.image = nil
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
        
        print(collectionView.bounds.width)
        cell?.slide = slide
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

class carouselCollectionViewCell: UICollectionViewCell {
    
    fileprivate var slide : TemplateCarouselSlide? {
        didSet {
            guard let slide = slide else {
                print("ZKCarousel could not parse the slide you provided. \n\(String(describing: self.slide))")
                return
            }
            parseData(forSlide: slide)
        }
    }
    
    private lazy var imageView : UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .clear
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    lazy var canvasDisplayView: UIImageView = {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 1
        view.isUserInteractionEnabled = true
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var touchHereLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 10, y: 0, width: canvasDisplayView.frame.width - 20, height: 20))
        label.text = "Add a Design"
        label.textColor = ColorCompatibility.label
        label.font = UIFont(name: "NexaW01-Heavy", size: 16)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        
    }
    
    private func setup() {
        backgroundColor = .clear
        clipsToBounds = true
        addSubview(imageView)
        
        NSLayoutConstraint(item: imageView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: imageView, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: imageView, attribute: .left, relatedBy: .equal, toItem: contentView, attribute: .left, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: imageView, attribute: .right, relatedBy: .equal, toItem: contentView, attribute: .right, multiplier: 1.0, constant: 0).isActive = true
        
        addSubview(canvasDisplayView)
        
        NSLayoutConstraint(item: canvasDisplayView, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: canvasDisplayView, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1.0, constant: -20).isActive = true
        NSLayoutConstraint(item: canvasDisplayView, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .width, multiplier: 0.3, constant: 0).isActive = true
        NSLayoutConstraint(item: canvasDisplayView, attribute: .height, relatedBy: .equal, toItem: contentView, attribute: .height, multiplier: 0.475, constant: 0).isActive = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(maximiseDrawingArea(_:)))
        canvasDisplayView.addGestureRecognizer(tap)
        
        canvasDisplayView.addSubview(touchHereLabel)
        
        NSLayoutConstraint(item: touchHereLabel, attribute: .centerX, relatedBy: .equal, toItem: canvasDisplayView, attribute: .centerX, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: touchHereLabel, attribute: .centerY, relatedBy: .equal, toItem: canvasDisplayView, attribute: .centerY, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: touchHereLabel, attribute: .width, relatedBy: .equal, toItem: canvasDisplayView, attribute: .width, multiplier: 1.0, constant: -20).isActive = true
        touchHereLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
    @objc func maximiseDrawingArea(_ sender: UITapGestureRecognizer){
        
        if let designVC = self.parentViewController as? DesignViewController{
            designVC.maximiseDrawingArea(displayView: sender.view as! UIImageView)
        }
    }
    
    private func parseData(forSlide slide: TemplateCarouselSlide) {
        if let image = slide.slideImage {
            self.imageView.image = image
        }
        if let color = slide.canvasBackColor {
            self.canvasDisplayView.backgroundColor = color
        }
        
        return
    }
    
    override func layoutSubviews() {
        
    }
    
    

}

final public class TemplateCarouselSlide : NSObject {
    
    public var slideImage : UIImage?
    public var canvasBackColor: UIColor?
    public var canvasColorName: String?
    
    public init(image: UIImage?, canvasColor: UIColor?, canvasName: String?) {
        slideImage = image
        
        canvasBackColor = canvasColor
        canvasColorName = canvasName
    }
    
    override init() {
        super.init()
    }
    
}





