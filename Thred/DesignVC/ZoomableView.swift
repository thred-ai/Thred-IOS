//
//  ZoomableView.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import Foundation
import UIKit

extension DesignViewController{
    @objc func showZoomableView(_ sender: UIButton){
        if let indexPath = carousel.collectionView.indexPathsForVisibleItems.first{
            zoomableView.isHidden = false
            let imageView = zoomableView.subviews.first as? UIImageView
            imageView?.image = nil
            //if cell.canvasDisplayView.image(for: .normal) == nil{
             //   cell.canvasDisplayView.isHidden = true
           // }
            imageView?.image = displayView?.makeSnapshot(clear: true, subviewsToIgnore: [])
            //cell.canvasDisplayView.isHidden = false

            zoomableView.alpha = 0.0
            UIView.animate(withDuration: 0.2, animations: {
                self.zoomableView.alpha = 1.0
            }, completion: { finished in
                if finished{
                    self.navigationController?.setNavigationBarHidden(true, animated: true)
                }
            })
        }
    }
    
    @objc func hideZoomableView(_ sender: Any){
        zoomableView.alpha = 1.0
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        UIView.animate(withDuration: 0.2, animations: {
            self.zoomableView.alpha = 0.0
        }, completion: { finished in
            if finished{
                self.zoomableView.isHidden = true
            }
        })
    }
    
    
    @objc func handleZoom(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began, .changed:
            if gesture.scale >= 1 {
                let scale = gesture.scale
                gesture.view!.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
            break;
        default:
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
              gesture.view!.transform = .identity
            }) { _ in}
        }
    }
    
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        
        switch gesture.state {
        case .began, .changed:
            let translation = gesture.translation(in: self.zoomableView)
            gesture.view?.center = CGPoint(x: gesture.view!.center.x + translation.x, y: gesture.view!.center.y + translation.y)
            gesture.setTranslation(.zero, in: self.zoomableView)
            break;
        default:
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                gesture.view?.center = self.zoomableView.center
                gesture.setTranslation(.zero, in: self.zoomableView)
            }) { _ in}
            break
        }
    }
}
