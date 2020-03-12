//
//  DesignCanvas.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import Foundation
import UIKit
import Photos


extension DesignViewController{
    @objc func maximiseDrawingArea(displayView: UIImageView){
        
        
        if let selectedIndex = carousel.collectionView.indexPathsForVisibleItems.first?.item{
            aspectRatio = displayView.frame.height / displayView.frame.width
            let viewY = displayView.frame.origin.y
            let width = view.frame.width
            let height = view.frame.width * aspectRatio
            let difference = (height - canvas.frame.height).magnitude
            garbageBtn.center.y -= difference
            self.titleView.isUserInteractionEnabled = false
            self.canvasDisplayView.isHidden = false
            self.canvasDisplayView.frame.size = displayView.frame.size
            self.canvasDisplayView.frame.origin.y = viewY
            displayView.isHidden = true
            nextBtn.isEnabled = false
            self.carousel.displayImage = self.canvasDisplayView.image
            selectedView = displayView
            DispatchQueue.main.async {
                self.scrollview.setContentOffset(.zero, animated: true)
                self.scrollview.isScrollEnabled = false
                self.canvas.backgroundColor = UIColor(named: self.tees[selectedIndex].templateID)
                self.canvasDisplayView.backgroundColor = UIColor(named: self.tees[selectedIndex].templateID)
                self.garbageBtn.isHidden = true
                self.textStyleBtn.superview?.isHidden = true
                self.fontSlider.isHidden = true
                self.textCoverView.isHidden = true
                self.bottomBar.isHidden = false
                self.bottomSafeAreaView.isHidden = false
                let y = self.displayView.frame.origin.y
                var bottomBarY = y + height + self.view.safeAreaInsets.top
                if bottomBarY >= self.view.frame.maxY - self.bottomBar.frame.height{
                    bottomBarY = self.view.frame.maxY - self.bottomBar.frame.height
                }
                self.bottomBar.frame.origin.y = bottomBarY
                self.bottomSafeAreaView.frame.origin.y = self.bottomBar.frame.maxY
                self.bottomSafeAreaView.frame.size.height = self.view.frame.maxY - self.bottomSafeAreaView.frame.origin.y
                
                UIView.animate(withDuration: 0.2, animations: {
                    self.descriptionView.alpha = 0.0
                    self.canvasDisplayView.frame = CGRect(x: 0, y: y, width: width, height: height)
                    self.canvasDisplayView.center.x = self.view.center.x
                    self.canvas.frame = CGRect(x: 0, y: y + self.view.safeAreaInsets.top, width: width, height: height)
                    self.canvas.center.x = self.view.center.x
                    
                }, completion: { finished in
                    if finished{
                        //self.displayView.image = nil
                        self.garbageBtn.center.y = self.bottomBar.frame.minY - (self.garbageBtn.frame.height / 2) - self.view.safeAreaInsets.top
                        self.lineTypeView.isHidden = true
                         self.descriptionView.isHidden = true
                        self.canvas.isHidden = false
                        self.drawCanvas.isHidden = false
                    }
                })
            }
        }
    }
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func minimizeDrawingArea(_ sender: UIButton){
        canvasDisplayView.image = nil
        garbageBtn.isHidden = true
        textCoverView.isHidden = true
        textStyleBtn.superview?.isHidden = true
        fontSlider.isHidden = true
        midXLine.isHidden = true
        midYLine.isHidden = true
        angleLine.isHidden = true
        angleLocked = false
        viewCenteredX = false
        viewCenteredY = false
        if canvas.subviews.contains(where: {$0.isKind(of: UIImageView.self) || ($0.isKind(of: UITextView.self))}) || drawCanvas.lines.contains(where: {$0.brush.blendMode != .clear}){
            canvasDisplayView.image = canvas.makeSnapshot(clear: true, subviewsToIgnore: [])
            nextBtn.isEnabled = true
        }
        if !cameraRollCollectionView.isHidden{
            configurePhotos(photosBtn)
        }
        let x = selectedView.frame.origin.x
        let y = selectedView.frame.origin.y
        let width = selectedView.frame.width
        let height = selectedView.frame.height
        DispatchQueue.main.async {
            self.scrollview.isScrollEnabled = true
            self.titleView.isUserInteractionEnabled = true
            self.bottomBar.isHidden = true
            self.bottomSafeAreaView.isHidden = true
            self.descriptionView.isHidden = false
            self.drawCanvas.isEnabled = false
            self.drawBtn.isSelected = false
            self.drawBtn.tintColor = UIColor(named: "LoadingColor")
            self.drawCanvas.isHidden = true
            self.canvas.isHidden = true
            UIView.animate(withDuration: 0.2, animations: {
                self.descriptionView.alpha = 1.0
                self.canvasDisplayView.frame = CGRect(x: x, y: y, width: width, height: height)
                self.canvasDisplayView.center.x = self.displayView.center.x
            }, completion: { finished in
                if finished{
                    UIView.animate(withDuration: 0.1, animations: {
                        self.carousel.displayImage = self.canvasDisplayView.image
                        self.carousel.collectionView.reloadData()
                        self.selectedView.isHidden = false
                        self.selectedView = nil
                        self.canvasDisplayView.isHidden = true
                    })
                }
            })
        }
    }
    
    @objc func closeDrawCanvas(_ sender: UIButton){
        for label in canvas.subviews.filter({$0.isKind(of: UITextView.self)}){
            label.isUserInteractionEnabled = true
        }
        drawToolBar.isHidden = true
        canvas.gestureRecognizers?.first?.isEnabled = true
        drawToolBar.isHidden = true
        drawCanvas.isUserInteractionEnabled = false
        drawBtn.superview?.isHidden = false
        drawCanvas.isEnabled = false
        drawBtn.isSelected = false
    }

    @objc func openDrawCanvas(_ sender: UIButton){
        
        drawToolBar.isHidden = false
        sender.superview?.isHidden = true
        if !cameraRollCollectionView.isHidden{
            configurePhotos(photosBtn)
        }
        for label in canvas.subviews.filter({$0.isKind(of: UITextView.self)}){
            label.isUserInteractionEnabled = false
            canvas.bringSubviewToFront(label)
        }
        drawCanvas.isEnabled = true
        canvas.gestureRecognizers?.first?.isEnabled = false
        drawCanvas.isUserInteractionEnabled = true
        sender.isSelected = true
        
    }
    
    
    @objc func handleObjectPan(_ sender: UIPanGestureRecognizer){
        let viewDrag = sender.view!
        switch sender.state {
        case .began, .changed:
            canvas.gestureRecognizers?.first?.isEnabled = false
            if viewDrag != backgroundView{
                canvas.bringSubviewToFront(viewDrag)
            }
            canvas.bringSubviewToFront(drawCanvas)
            angleLine.isHidden = true
            configureOtherStickersGestures(ignoredView: viewDrag, disable: true)
            let translation = sender.translation(in: view)
            viewDrag.center = CGPoint(x: viewDrag.center.x + translation.x, y: viewDrag.center.y + translation.y)
            checkInGarbage(sender: sender, completed: { inGarbage in
                self.canvas.bringSubviewToFront(self.garbageBtn)

                if !inGarbage{
                    if translation.x <= 5 && translation.y <= 5{
                        self.checkCentering(viewDrag: viewDrag)
                    }
                }
                else{
                    self.midYLine.isHidden = true
                    self.midXLine.isHidden = true
                    self.viewCenteredY = false
                    self.viewCenteredX = false
                }
            })
            sender.setTranslation(CGPoint.zero, in: view)
        default:
            canvas.gestureRecognizers?.first?.isEnabled = true
            if viewCenteredY{
                viewDrag.center.y = canvas.center.y - view.safeAreaInsets.top
            }
            if viewCenteredX{
                viewDrag.center.x = canvas.center.x
            }
            midYLine.isHidden = true
            midXLine.isHidden = true
            viewCenteredY = false
            viewCenteredX = false
            configureOtherStickersGestures(ignoredView: viewDrag, disable: false)
            if viewDrag.isOutOfBounds(){
                viewDrag.removeFromSuperview()
                if viewDrag == backgroundView{
                    backgroundView = nil
                }
                hideGarbageBtn()
                break
            }
            checkInGarbage(sender: sender, completed: { inGarbage in
                if inGarbage{
                    viewDrag.removeFromSuperview()
                    if viewDrag == self.backgroundView{
                        self.backgroundView = nil
                    }
                    self.eatGarbageAnimation{
                        self.hideGarbageBtn()
                    }
                }
                else{
                    self.hideGarbageBtn()
                }
            })
            break
        }
    }
    
    @objc func saveToCameraRoll(_ sender: UIButton){
        guard let image = displayView.makeSnapshot(clear: false, subviewsToIgnore: [zoomBtn, saveBtn]) else{return}
        image.saveToPhotos { (success) in
            if success {
                // image saved to photos
            }
            else {
                // image not saved
            }
        }
    }
    
    @objc func handleObjectPinch(_ sender: UIPinchGestureRecognizer){
        switch sender.state {
        case .began, .changed:
            canvas.gestureRecognizers?.first?.isEnabled = false
            let viewDrag = sender.view!
            if viewDrag != backgroundView{
                canvas.bringSubviewToFront(viewDrag)
            }
            canvas.bringSubviewToFront(drawCanvas)
            let scale = sender.scale
            sender.view!.transform = sender.view!.transform.scaledBy(x: scale, y: scale)
            sender.scale = 1
            break
        default:
            canvas.gestureRecognizers?.first?.isEnabled = true
            break
        }
    }
    
    @objc func handleObjectRotation(_ sender: UIRotationGestureRecognizer){
        switch sender.state{
        case .began, .changed:
            if sender.numberOfTouches == 2{
                canvas.gestureRecognizers?.first?.isEnabled = false
                let viewDrag = sender.view!
                if viewDrag != backgroundView{
                    canvas.bringSubviewToFront(viewDrag)
                }
                canvas.bringSubviewToFront(drawCanvas)
                sender.view!.transform = sender.view!.transform.rotated(by: sender.rotation)
                checkRotation(viewDrag: viewDrag)
                sender.rotation = 0
            }
            break
        default:
            canvas.gestureRecognizers?.first?.isEnabled = true
            angleLine.isHidden = true
            angleLocked = false
            break
        }
    }
}

extension UIView{
    func isOutOfBounds() -> Bool {
        guard let superview = self.superview else {
            return true
        }
        if self.frame.origin.y <= 0 - self.frame.height{
            return true
        }
        if self.frame.origin.y >= superview.frame.height{
            return true
        }
        if self.frame.origin.x <= 0 - self.frame.width{
            return true
        }
        if self.frame.origin.x >= superview.frame.width{
            return true
        }
        return false
    }
}

extension UIImage {

    func saveToPhotos(completion: @escaping (_ success:Bool) -> ()) {
        if let pngData = self.pngData() {
            PHPhotoLibrary.shared().performChanges({ () -> Void in
                let creationRequest = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                creationRequest.addResource(with: PHAssetResourceType.photo, data: pngData, options: options)
            }, completionHandler: { (success, error) -> Void in
                if success == false {
                    if let errorString = error?.localizedDescription  {
                        print("Photo could not be saved: \(errorString))")
                    }
                    completion(false)
                }
                else {
                    print("Photo saved!")
                    completion(true)
                }
            })
        }
        else {
            completion(false)
        }

    }
}
