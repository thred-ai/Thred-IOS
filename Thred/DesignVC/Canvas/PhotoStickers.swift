//
//  PhotoStickers.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import Foundation
import UIKit

extension DesignViewController{
    
    @objc func openCamera(_ sender: UIButton) {
        //self.animateOptionMenuCameraRollButton(didOpen: false)
        cameraView.isHidden = true
        doneBtn.isEnabled = true
        cameraRollCollectionView.hidePhotosCollectionView {
            photosBtn.tintColor = UIColor(named: "LoadingColor")
            cameraView.isHidden = false
            let cameraBtnMaxY = bottomBar.frame.maxY
            drawBtn.isSelected = true
            closeDrawCanvas(drawBtn)
            cameraView.openCameraAnimate(backgroundView: view, viewToCarry: bottomBar, viewMaxY: cameraBtnMaxY){
                self.titleView.isHidden = true
                self.bottomBar.isHidden = true
            }
        }
    }
    
    func showCamRoll(sender: UIButton?){
        let y = view.frame.midY
        let btnMaxY = bottomBar.frame.maxY
        bottomBar.transform = CGAffineTransform(translationX: 0, y: (y - btnMaxY))
        cameraRollCollectionView.showCameraRollAnimate(completed: { openedRoll in
            if !openedRoll{
                self.cameraRollCollectionView.animatehideCameraRoll(viewToCarry: self.bottomBar, backgroundView: self.view, tableView: nil){
                }
            }
        })
    }
    
    @objc func configurePhotos(_ sender: UIButton) {
        if self.cameraRollCollectionView.isHidden{
            sender.tintColor = .cyan
            drawBtn.isSelected = true
            closeDrawCanvas(drawBtn)
            exitTapper.isEnabled = true
            doneBtn.isEnabled = false
            showCamRoll(sender: sender)
            canvas.gestureRecognizers?.first?.isEnabled = false
        }
        else{
            exitTapper.isEnabled = false
            doneBtn.isEnabled = true
            sender.tintColor = UIColor(named: "LoadingColor")
            cameraRollCollectionView.animatehideCameraRoll(viewToCarry: self.bottomBar, backgroundView: view, tableView: nil){
                self.canvas.gestureRecognizers?.first?.isEnabled = true
            }
        }
    }
    
    @objc func closeCamera(_ sender: UIButton?){
        titleView.isHidden = false
        bottomBar.isHidden = false
        canvas.gestureRecognizers?.first?.isEnabled = true
        cameraView.hideCameraAnimate(viewToCarry: bottomBar) {
            self.cameraView.resetDisplayImage()
        }
    }
    
    @objc func exitPhotosTap(_ sender: UITapGestureRecognizer){
        if !self.cameraRollCollectionView.isHidden{
            self.configurePhotos(photosBtn)
        }
    }
    
    @objc func usePhoto(_ sender: UIButton?){
        
        var selectedImage: UIImage!
        
        if !cameraView.isHidden{
            selectedImage = cameraView.selectedImage
            closeCamera(cameraBtn)
        }
        else if !cameraRollCollectionView.isHidden{
            selectedImage = cameraRollCollectionView.selectedImage
            configurePhotos(photosBtn)
        }
        
        doneBtn.isHidden = false
        let aspectRatio = selectedImage.size.height / selectedImage.size.width
        
        let width = canvas.frame.width / 2

        let imageView = UIImageView.init(frame: CGRect(x: canvas.frame.width / 2, y: canvas.frame.height / 2, width: width, height: width * aspectRatio))
        imageView.contentMode = .scaleAspectFit
        imageView.center.y = canvas.bounds.midY
        imageView.center.x = canvas.center.x
        imageView.image = selectedImage
        let tapper = UILongPressGestureRecognizer(target: self, action: #selector(configureAsBackground(_:)))
        imageView.addGestureRecognizer(tapper)
        
        makeMovable(view: imageView)
        canvas.insertSubview(imageView, belowSubview: drawCanvas)
    }
    
    @objc func configureAsBackground(_ sender: UILongPressGestureRecognizer){
        
        if sender.state == .began{
            if let heldView = sender.view as? UIImageView{
                if backgroundView == heldView{
                    backgroundView = nil
                    canvas.bringSubviewToFront(heldView)
                    heldView.alpha = 0.0
                    UIView.animate(withDuration: 0.25, animations: {
                        heldView.alpha = 1.0
                    })
                }
                else{
                    backgroundView = heldView
                    canvas.sendSubviewToBack(heldView)
                    heldView.alpha = 0.0
                    UIView.animate(withDuration: 0.25, animations: {
                        heldView.alpha = 1.0
                    })
                }
            }
        }
    }
    
    func configureOtherStickersGestures(ignoredView: UIView, disable: Bool){
        if disable{
            for view in canvas.subviews.filter({$0.isKind(of: UITextView.self) || $0.isKind(of: UIImageView.self)}){
                if view != ignoredView{
                    view.isUserInteractionEnabled = false
                }
            }
        }
        else{
            for view in canvas.subviews.filter({$0.isKind(of: UITextView.self) || $0.isKind(of: UIImageView.self)}){
                if view != ignoredView{
                    view.isUserInteractionEnabled = true
                }
            }
        }
    }
}
