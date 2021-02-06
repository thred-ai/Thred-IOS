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

extension UIImage {
    func rotate(radians: CGFloat) -> UIImage {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
            .integral.size
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            let origin = CGPoint(x: rotatedSize.width / 2.0,
                                 y: rotatedSize.height / 2.0)
            context.translateBy(x: origin.x, y: origin.y)
            context.rotate(by: radians)
            draw(in: CGRect(x: -origin.y, y: -origin.x,
                            width: size.width, height: size.height))
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return rotatedImage ?? self
        }

        return self
    }
}


extension DesignViewController{
    @objc func maximiseDrawingArea(displayView: UIButton){
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        if let selectedIndex = carousel.collectionView.indexPathsForVisibleItems.first?.item, let _ = carousel.collectionView.cellForItem(at: IndexPath(item: selectedIndex, section: 0)) as? CarouselCollectionViewCell{
            
            hideList()
            
            aspectRatio = selectedSide.aspectRatio
            
            let colorInfo: Colors? = selectedProductType?.colors[selectedIndex]

            let color = colorInfo?.getColor()
            
            
            productTypeBtn.isEnabled = false
            var viewY = CGFloat.zero
                
            let width = view.frame.width
            var height = view.frame.width * aspectRatio
            let y = self.displayView.frame.origin.y
            var bottomBarY = y + height + view.safeAreaInsets.top
            if bottomBarY >= view.frame.maxY - bottomBar.frame.height{
                bottomBarY = view.frame.maxY - bottomBar.frame.height
                height = bottomBarY - view.safeAreaInsets.top
            }
            garbageBtn.center.y = bottomBarY - (garbageBtn.frame.height / 2) - view.safeAreaInsets.top
            //titleView.isUserInteractionEnabled = false
            canvasDisplayView.frame.size = displayView.bounds.size

            if let currentDesign = canvasDesigns.first(where: {$0.name == selectedSide.name}){
                let subviews = currentDesign.subviews
                let drawItems = currentDesign.drawItems
                print(canvasDesigns.compactMap({$0.subviews}))
                print(canvasDesigns.compactMap({$0.name}))

                print(subviews)
                
                drawCanvas.drawItems.append(contentsOf: drawItems)
                
                for view in subviews{
                    canvas.addSubview(view)
                }
                drawCanvas.setNeedsDisplay()
            }
            else{
                print(canvasDesigns.compactMap({$0.name}))
                print(canvasDesigns.compactMap({$0.subviews}))
                
            }
            
            switch selectedSide.name{
            
            case "Front":
                print("")
                viewY = displayView.frame.origin.y
                canvasDisplayView.frame.origin.y = viewY
            case "Back":
                print("")
                viewY = displayView.frame.origin.y
                canvasDisplayView.frame.origin.y = viewY
            case "Left":
                print("")
                viewY = displayView.frame.origin.y
                canvasDisplayView.frame.origin.y = viewY
                let radians = atan2(displayView.transform.b, displayView.transform.a)
                //let degrees = radians * 180 / .pi
                canvasDisplayView.transform = CGAffineTransform(rotationAngle: radians)
            case "Right":
                print("")
                viewY = displayView.frame.origin.y
                canvasDisplayView.frame.origin.y = viewY
                let radians = atan2(displayView.transform.b, displayView.transform.a)
                canvasDisplayView.transform = CGAffineTransform(rotationAngle: radians)
            default:
                return
            }
            canvasDisplayView.isHidden = false
            
            
            displayView.isHidden = true
            hideNextBtn()
            canvasDisplayView.image = carousel.currentImage()
            selectedView = displayView
            DispatchQueue.main.async {
                self.scrollview?.setContentOffset(.zero, animated: true)
                self.scrollview?.isScrollEnabled = false
                self.canvas.backgroundColor = color
                self.canvasDisplayView.backgroundColor = color
                self.garbageBtn?.isHidden = true
                self.textStyleBtn?.superview?.isHidden = true
                self.fontSlider?.isHidden = true
                self.textCoverView?.isHidden = true
                self.bottomBar.isHidden = false
                self.bottomSafeAreaView.isHidden = false
                self.bottomBar.frame.origin.y = bottomBarY
                self.bottomSafeAreaView.frame.origin.y = self.bottomBar.frame.maxY
                self.bottomSafeAreaView.frame.size.height = self.view.frame.maxY - self.bottomSafeAreaView.frame.origin.y
                UIView.animate(withDuration: 0.2, animations: {
                    if self.selectedProductType.category == "Accessories"{
                        self.canvasDisplayView.transform = CGAffineTransform(rotationAngle: -(.pi / 2))
                    }
                    //self.descriptionView?.alpha = 0.0
                    self.canvasDisplayView.frame = CGRect(x: 0, y: y, width: width, height: height)
                    self.canvasDisplayView.center.x = self.view.center.x
                    self.canvas.frame = CGRect(x: 0, y: y + self.view.safeAreaInsets.top, width: width, height: height)
                    self.canvas.center.x = self.view.center.x
                }, completion: { finished in
                    if finished{
                        //self.displayView.image = nil
                        self.canvasDisplayView.transform = .identity
                        self.lineTypeView?.isHidden = true
                        //self.descriptionView?.isHidden = true
                        self.canvas.isHidden = false
                        self.drawCanvas?.isHidden = false
                    }
                })
            }
        }
        else{
            fatalError()
        }
    }
    
    
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer is UITapGestureRecognizer || otherGestureRecognizer is UITapGestureRecognizer{
            return false
        }
        return true
    }
    
    @objc func minimizeDrawingArea(_ sender: UIButton){
        self.navigationItem.leftBarButtonItem?.isEnabled = true
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
        productTypeBtn.isEnabled = true
        if canvas.subviews.contains(where: {$0.isKind(of: UIImageView.self) || ($0.isKind(of: UITextView.self))}) || drawCanvas.drawItems.contains(where: {$0.brush.blendMode != .clear}){
            let image = canvas.makeSnapshot(clear: true, subviewsToIgnore: [])
            if selectedProductType.category == "Accessories"{
                self.canvasDisplayView.image = image?.rotate(radians: (.pi / 2))
            }
            else{
                self.canvasDisplayView.image = image
            }
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
            //self.titleView.isUserInteractionEnabled = true
            self.bottomBar.isHidden = true
            self.bottomSafeAreaView.isHidden = true
            //self.descriptionView.isHidden = false
            self.drawCanvas.isEnabled = false
            self.drawBtn.isSelected = false
            self.drawBtn.tintColor = UIColor(named: "LoadingColor")
            self.drawCanvas.isHidden = true
            self.canvas.isHidden = true
            UIView.animate(withDuration: 0.2, animations: {
                //self.descriptionView.alpha = 1.0
                self.canvasDisplayView.frame = CGRect(x: x, y: y, width: width, height: height)
                self.canvasDisplayView.center.x = self.displayView.center.x
            }, completion: { finished in
                if finished{
                    UIView.animate(withDuration: 0.1, animations: {
                        self.carousel.replaceImageSide(side: self.selectedSide, with: self.canvasDisplayView.image)
                        self.drawCanvas.clear()
                        self.drawCanvas.drawItems.removeAll()
                        for subview in self.canvas.subviews.filter({$0.isKind(of: UIImageView.self) || ($0.isKind(of: UITextView.self))}){
                            subview.removeFromSuperview()
                        }
                        self.carousel.collectionView.reloadData()
                        self.selectedView.isHidden = false
                        self.selectedView = nil
                        self.canvasDisplayView.isHidden = true
                        if self.canvasDesigns.contains(where: {$0.currentImage != nil}){
                            self.showNextBtn()
                        }
                    })
                }
            })
        }
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
            canvas.bringSubviewToFront(alignmentCanvas)
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
    
    
    @objc func showSaveView(_ sender: UIButton?){
        displayView.bringSubviewToFront(saveToPhotosLbl)
        saveToPhotosLbl.isHidden = false
    }
    
    @objc func hideSaveView(_ sender: UIButton?){
        saveToPhotosLbl.isHidden = true
    }
    
    
    @IBAction func saveToCameraRoll(_ sender: UIButton){
        
        //canvasDesigns.saveAllObjects(type: "")
        
        if let thredLabel = self.thredWatermark.arrangedSubviews.first(where: {$0.isKind(of: UILabel.self)}) as? UILabel{
            hideSaveView(nil)
            thredLabel.text = "thred"
            saveBtn.isEnabled = false
            UIView.animate(withDuration: 0.15, animations: {
                sender.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                sender.alpha = 1.0
                thredLabel.alpha = 1.0
            }, completion: { finished in
                sender.transform = CGAffineTransform.identity
                guard let image = self.displayView.makeSnapshot(clear: false, subviewsToIgnore: []) else{return}
                sender.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                image.saveToPhotos { (success) in
                    DispatchQueue.main.async {
                        if success{
                            thredLabel.text = "save"
                        }
                        else{
                            thredLabel.text = "error!"
                        }
                        self.saveBtn.isEnabled = true
                        UIView.animate(withDuration: 0.2, animations: {
                            sender.transform = CGAffineTransform.identity
                        }, completion: { finished in
                            if finished{
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75){
                                    UIView.animate(withDuration: 0.15, animations: {
                                        if thredLabel.text != "save"{
                                            thredLabel.text = "save"
                                        }
                                    }, completion: { finished in
                                        if finished{
                                        }
                                    })
                                }
                            }
                        })
                    }
                }
            })
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
            canvas.bringSubviewToFront(alignmentCanvas)
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
                canvas.bringSubviewToFront(alignmentCanvas)
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
