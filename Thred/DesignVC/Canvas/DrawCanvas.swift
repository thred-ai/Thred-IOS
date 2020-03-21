//
//  DrawCanvas.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import Foundation
import UIKit
import SwiftyDraw
import AudioToolbox
import ColorSlider

extension DesignViewController{
    
    @objc func openDrawCanvas(_ sender: UIButton){
        
        drawToolBar.isHidden = false
        sender.superview?.isHidden = true
        drawTopToolBar.isHidden = false
        if !cameraRollCollectionView.isHidden{
            configurePhotos(photosBtn)
        }
        for label in canvas.subviews.filter({$0.isKind(of: UITextView.self)}){
            label.isUserInteractionEnabled = false
        }
        drawCanvas.isEnabled = true
        canvas.gestureRecognizers?.first?.isEnabled = false
        drawCanvas.isUserInteractionEnabled = true
        sender.isSelected = true
        
    }
    
    @objc func closeDrawCanvas(_ sender: UIButton){
        for label in canvas.subviews.filter({$0.isKind(of: UITextView.self)}){
            label.isUserInteractionEnabled = true
        }
        drawToolBar.isHidden = true
        canvas.gestureRecognizers?.first?.isEnabled = true
        drawTopToolBar.isHidden = true
        drawCanvas.isUserInteractionEnabled = false
        drawBtn.superview?.isHidden = false
        drawCanvas.isEnabled = false
        drawBtn.isSelected = false
    }
    
    
    func swiftyDraw(shouldBeginDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) -> Bool {
        if (!drawingView.isHidden && !drawingView.isEnabled) || (drawingView.brush.blendMode == .clear && drawingView.lines.isEmpty){
            return false
        }
        drawingView.brush.adjustWidth(for: touch)
        return true
    }
    
    @objc func colorChanged(_ sender: ColorSlider){
        if sender == slider{
            drawCanvas.brush.color = Color(sender.color)
        }
        else if sender == textSlider{
            activeLbl?.color = sender.color
        }
    }
    
    @objc func undoColors(_ sender: UIButton){
        drawCanvas.undo()
    }
    
    @objc func switchBrush(_ sender: UIButton){
        
        if drawCanvas.brush.blendMode == .clear{
            brushBtn.setImage(UIImage(nameOrSystemName: "pencil.circle", systemPointSize: 25, iconSize: 9), for: .normal)
            drawCanvas.brush.blendMode = .normal
            drawCanvas.brush.color = Color(slider.color)
        }
        else{
            brushBtn.setImage(UIImage(nameOrSystemName: "wand.and.rays.inverse", systemPointSize: 23, iconSize: 9), for: .normal)
            drawCanvas.brush.blendMode = .clear
        }
    }
    
    @objc func activateStraightLine(_ sender: UIButton){
        if let lineImageView = lineTypeView.subviews.first(where: {$0.isKind(of: UIImageView.self)}) as? UIImageView{
            lineTypeView.center = drawCanvas.center
            lineTypeView.center.y = drawCanvas.center.y - self.view.safeAreaInsets.top
            lineImageView.frame.origin = CGPoint.zero
            lineTypeView.tintColor = slider.color
            lineTypeView.isHidden = false
            AudioServicesPlaySystemSound(1519)
            if drawCanvas.shouldDrawStraight{
                drawCanvas.shouldDrawStraight = false
                lineImageView.image = UIImage(named: "scribble.mode")
                sender.setTitle("Scribble", for: .normal)
            }
            else{
                drawCanvas.shouldDrawStraight = true
                lineImageView.image = UIImage(named: "straight.mode")
                sender.setTitle("Straight", for: .normal)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                UIView.animate(withDuration: 0.2, animations: {
                    self.lineTypeView.alpha = 0.0
                }, completion: { finished in
                    if finished{
                        self.lineTypeView.alpha = 1.0
                        self.lineTypeView.isHidden = true
                    }
                })
            }
        }
    }
    
    func swiftyDraw(didBeginDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) {
        hideTopBar()
    }
    
    func swiftyDraw(isDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) {
        
    }
    
    func swiftyDraw(didFinishDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) {
        showTopBar()
    }
    
    func hideTopBar(){
        drawTopToolBar.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.2, animations: {
            self.drawTopToolBar.alpha = 0.0
        }, completion: { finished in
            if finished{
                self.drawTopToolBar.isHidden = true
            }
        })
    }
    
    func showTopBar(){
        self.drawTopToolBar.isHidden = false
        drawTopToolBar.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.2, animations: {
            self.drawTopToolBar.alpha = 1.0
        }, completion: { finished in
            if finished{
                
            }
        })
    }
    
    func swiftyDraw(didCancelDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) {
    }
    
    @objc func changeBrushSize(_ sender: UIPinchGestureRecognizer){
        switch sender.state {
        case .began:
            drawCanvas.undo()
        case .changed:
            if drawCanvas.brush.blendMode == .clear{
                brushCircle.backgroundColor = UIColor.white.withAlphaComponent(0.45)
            }
            else{
                brushCircle.backgroundColor = slider.color
            }
            switch drawCanvas.brush.width{
            case 100...:
                if sender.scale >= 1{
                    drawCanvas.brush.width = 100
                }
                else{
                    fallthrough
                }
            default:
                if drawCanvas.brush.blendMode == .clear{
                    drawCanvas.brush = Brush.init(color: slider.color, width: drawCanvas.brush.originalWidth * sender.scale, opacity: drawCanvas.brush.opacity, adjustedWidthFactor: drawCanvas.brush.adjustedWidthFactor, blendMode: .clear)

                }
                else{
                    drawCanvas.brush = Brush.init(color: slider.color, width: drawCanvas.brush.originalWidth * sender.scale, opacity: drawCanvas.brush.opacity, adjustedWidthFactor: drawCanvas.brush.adjustedWidthFactor, blendMode: .normal)
                }
                brushCircle.transform = brushCircle.transform.scaledBy(x: sender.scale, y: sender.scale)
            }
            if sender.numberOfTouches == 2{
                brushCircle.center = sender.location(in: canvas)
                brushCircle.isHidden = false

            }
            sender.scale = 1
            
        case .ended:
            brushCircle.isHidden = true
            drawCanvas.isEnabled = true
            showTopBar()
        default:
            brushCircle.isHidden = true
            drawCanvas.isEnabled = true
            showTopBar()
            return
        }
    }
    
    
}
