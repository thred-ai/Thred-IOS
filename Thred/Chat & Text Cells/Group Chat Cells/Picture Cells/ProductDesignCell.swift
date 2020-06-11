//
//  ProductDesignCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-05-25.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility

class ProductDesignCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    let circularProgress = CircularProgress(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
    var imageCenter: CGPoint!
    weak var vc: UIViewController!
    weak var cell: ProductCell!
    @IBOutlet weak var usernameLbl: UILabel!
    
    func setUpCircularProgress(){
        
        if !self.imageView.subviews.contains(circularProgress){
            circularProgress.isHidden = true
            circularProgress.progressColor = (UIColor(named: "loadingColor") ?? UIColor(red: 0.4235, green: 0.7863, blue: 0.9882, alpha: 1)) /* #e0e0e0 */
            circularProgress.trackColor = ColorCompatibility.systemFill
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
            cell?.likesLbl.isHidden = true
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
                        self.cell?.likeBtn.isHidden = false
                        self.cell?.likesLbl.isHidden = false
                    }
                }
            }
            cell?.collectionView.isScrollEnabled = true
            let tableView = (vc as? UITableViewController)?.tableView ?? (vc as? UserVC)?.tableView ?? (vc as? FullProductVC)?.tableView
            tableView?.isScrollEnabled = true
        }
    }
    
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        
        switch gesture.state {
        case .began, .changed:
            cell?.likeBtn.isHidden = true
            cell?.likesLbl.isHidden = true
            cell?.collectionView.isScrollEnabled = false
            let tableView = (vc as? UITableViewController)?.tableView ?? (vc as? UserVC)?.tableView ?? (vc as? FullProductVC)?.tableView
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
            let tableView = (vc as? UITableViewController)?.tableView ?? (vc as? UserVC)?.tableView ?? (vc as? FullProductVC)?.tableView
            tableView?.isScrollEnabled = true
            cell?.collectionView.isScrollEnabled = true
            break
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setUpCircularProgress()
    }

}
