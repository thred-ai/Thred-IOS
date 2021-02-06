//
//  ProductPicCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-05-25.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility

class ProductPicCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    
    let circularProgress = CircularProgress(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
    var imageCenter: CGPoint!
    weak var vc: UIViewController!
    weak var cell: ProductCell!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageCenter = imageView.center

        setUpCircularProgress()
    }
    
    var topCanvasConstraints = [NSLayoutConstraint]()
    var canvasDisplayViews = [CanvasDisplayView]()

    
    func addConstraints(template: Template!, displaySide: DisplaySide){
        
        switch topCanvasConstraints.isEmpty{
        case false:
            for constraint in topCanvasConstraints{
                constraint.isActive = false
            }
            topCanvasConstraints.removeAll()
        case true:
            break
        }
        
        for canvas in canvasDisplayViews{
            canvas.removeFromSuperview()
        }
        canvasDisplayViews.removeAll()
        
        let sideString = "\(displaySide)".capitalizingFirstLetter()
        if let side = template?.supportedSides.first(where: {$0.name == sideString}) ?? template?.supportedSides.first(where: {$0.name == "Front"}){
            
            guard let name = side.name, let canvas = canvasDisplayView(for: name) else{return}

            imageView.addSubview(canvas)
            canvasDisplayViews.append(canvas)
            setConstraints(side: side, canvasDisplayView: canvas)
        }
    }
    
    func setConstraints(side: TemplateSide, canvasDisplayView: UIButton){
        
        switch topCanvasConstraints.isEmpty{
        case false:
            fallthrough
        default:
            guard self.imageView.subviews.contains(canvasDisplayView) else{return}

            let centerX = NSLayoutConstraint(item: canvasDisplayView, attribute: .centerX, relatedBy: .equal, toItem: imageView, attribute: .centerX, multiplier: 1.0, constant: 0)
            let centerY = NSLayoutConstraint(item: canvasDisplayView, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 1.0, constant: CGFloat(side.centerYConst ?? 0))
            
            let width = NSLayoutConstraint(item: canvasDisplayView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .width, multiplier: CGFloat(side.widthMultiplier ?? 0), constant: 0)
            
            let height = NSLayoutConstraint(item: canvasDisplayView, attribute: .height, relatedBy: .equal, toItem: canvasDisplayView, attribute: .width, multiplier: side.regularAspectRatio, constant: 0)
            
            topCanvasConstraints.append(centerX)
            topCanvasConstraints.append(centerY)
            topCanvasConstraints.append(width)
            topCanvasConstraints.append(height)
            
            for constraint in topCanvasConstraints{
                constraint.isActive = true
            }
        }
    }
    
    func setUpCircularProgress(){
        
        if !self.imageView.subviews.contains(circularProgress){
            circularProgress.isHidden = true
            circularProgress.progressColor = (UIColor(named: "LoadingColor") ?? UIColor(red: 0.4235, green: 0.7863, blue: 0.9882, alpha: 1)) /* #e0e0e0 */
            circularProgress.trackColor = .systemFill
            circularProgress.translatesAutoresizingMaskIntoConstraints = false
            self.imageView.addSubview(circularProgress)
            self.bringSubviewToFront(circularProgress)
            NSLayoutConstraint.activate([
                circularProgress.heightAnchor.constraint(equalToConstant: 80),
                circularProgress.widthAnchor.constraint(equalToConstant: 80),
                circularProgress.centerXAnchor.constraint(equalTo: self.imageView.centerXAnchor),
                circularProgress.centerYAnchor.constraint(equalTo: self.imageView.centerYAnchor)
            ])
        }
    }
    
    func setGestureRecognizers(){
        imageView.gestureRecognizers?.removeAll()
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleZoom(_:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        pan.delegate = self
        pinch.delegate = self
        imageCenter = imageView.center
        imageView.addGestureRecognizer(pinch)
        imageView.addGestureRecognizer(pan)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func handleZoom(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began, .changed:
            cell?.likeBtn.isHidden = true
            cell?.viewFullProductView.isHidden = true
            cell?.likesLbl.isHidden = true
            cell?.pageControl.isHidden = true
            let tableView = (vc as? UITableViewController)?.tableView ?? (vc as? FullProductVC)?.tableView
            tableView?.isScrollEnabled = false
            if gesture.scale >= 1 {
                let scale = gesture.scale
                cell?.collectionView.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
            break;
        default:
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                self.cell?.collectionView.transform = .identity
            }) { completed in
                if completed{
                    DispatchQueue.main.async {
                        if self.cell?.product.isPublic ?? false{
                            self.cell?.likeBtn.isHidden = false
                            self.cell?.likesLbl.isHidden = false
                            self.cell?.pageControl.isHidden = false
                        }
                        if !(self.cell?.vc is FullProductVC){
                            self.cell?.viewFullProductView.isHidden = false
                        }
                    }
                }
            }
            cell?.collectionView.isScrollEnabled = true
            let tableView = (vc as? UITableViewController)?.tableView ?? (vc as? FullProductVC)?.tableView
            tableView?.isScrollEnabled = true
        }
    }
    
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        
        switch gesture.state {
        case .began, .changed:
            cell?.likeBtn.isHidden = true
            cell?.likesLbl.isHidden = true
            cell?.viewFullProductView.isHidden = true
            cell?.pageControl.isHidden = true
            cell?.collectionView.isScrollEnabled = false
            let tableView = (vc as? UITableViewController)?.tableView ?? (vc as? FullProductVC)?.tableView
            tableView?.isScrollEnabled = false
            let translation = gesture.translation(in: cell.collectionView)
            cell?.collectionView.center = CGPoint(x: cell.collectionView.center.x + translation.x, y: cell.collectionView.center.y + translation.y)
            gesture.setTranslation(.zero, in: cell.collectionView.superview!)
            break;
        default:
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                self.cell?.collectionView.center = self.imageCenter
                gesture.setTranslation(.zero, in: self.cell.collectionView.superview!)
            }) { completed in
                if completed{
                   
                }
            }
            let tableView = (vc as? UITableViewController)?.tableView  ?? (vc as? FullProductVC)?.tableView
            tableView?.isScrollEnabled = true
            cell?.collectionView.isScrollEnabled = true
            break
        }
    }
    
}
