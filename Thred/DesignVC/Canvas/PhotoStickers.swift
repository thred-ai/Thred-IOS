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
        cameraRollCollectionView.hidePhotosCollectionView {
            photosBtn.tintColor = UIColor(named: "LoadingColor")
            cameraView.isHidden = false
            let cameraBtnMaxY = bottomBar.frame.maxY
            drawBtn.isSelected = true
            closeDrawCanvas(drawBtn)
            print(self.bottomBar.frame.minY)
            print(self.bottomBar.frame.maxY)
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
    
    @objc func exitPhotosTap(_ sender: UITapGestureRecognizer){
        if !self.cameraRollCollectionView.isHidden{
            self.configurePhotos(photosBtn)
        }
    }
}
