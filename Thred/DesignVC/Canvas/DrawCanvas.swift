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
        if slider.isHidden{
            showOrHideSlider(nil)
        }
        if !cameraRollCollectionView.isHidden{
            configurePhotos(photosBtn)
        }
        for label in canvas.subviews.filter({$0.isKind(of: UITextView.self)}){
            label.isUserInteractionEnabled = false
        }
        drawCanvas.isEnabled = true
        drawCanvas.isUserInteractionEnabled = true
        sender.isSelected = true
    }
    
    
    
    @objc func closeDrawCanvas(_ sender: UIButton){
        for label in canvas.subviews.filter({$0.isKind(of: UITextView.self)}){
            label.isUserInteractionEnabled = true
        }
        drawToolBar.isHidden = true
        if !slider.isHidden{
            showOrHideSlider(nil)
        }
        drawCanvas.isUserInteractionEnabled = false
        drawBtn.superview?.isHidden = false
        drawCanvas.isEnabled = false
        drawBtn.isSelected = false

    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UITapGestureRecognizer.self){
            if !drawCanvas.isEnabled{
                return true
            }
            return false
        }
        return true
    }
    
    func pixel(in image: UIImage, at point: CGPoint) -> (UInt8, UInt8, UInt8, UInt8)? {
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let x = Int(point.x)
        let y = Int(point.y)
        guard x < width && y < height else {
            return nil
        }
        guard let cfData:CFData = image.cgImage?.dataProvider?.data, let pointer = CFDataGetBytePtr(cfData) else {
            return nil
        }
        let bytesPerPixel = 4
        let offset = (x + y * width) * bytesPerPixel
        return (pointer[offset], pointer[offset + 1], pointer[offset + 2], pointer[offset + 3])
    }
    
    func getDropper(_ sender: UIButton?){
        
        if canvasImageView.isHidden{
            let image = canvas.makeSnapshot(clear: false, subviewsToIgnore: [])!
            self.canvasImageView.frame = self.canvas.frame
            self.canvasImageView.image = image
            self.canvasImageView.isHidden = false
            sender?.tintColor = sender?.tintColor?.withAlphaComponent(0.5)
            activateDropper(image: image)
        }
        else{
            
        }
    }
    
    func calculateDropper(){
        
    }
    

    func activateDropper(image: UIImage){
        if let (r,g,b,a) = pixel(in: image, at: CGPoint(x: 10, y:10)) {
            print ("Red: \(r), Green: \(g), Blue: \(b), Alpha: \(a)")
        }
    }
    
    func swiftyDraw(shouldBeginDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) -> Bool {
        if !drawingView.isHidden && !drawingView.isEnabled{
            return false
        }
        if drawingView.drawItems.isEmpty && drawingView.brush.blendMode == .clear{
            return false
        }
        
        drawingView.brush.adjustWidth(for: touch)
        return true
    }
    
    @objc func colorChanged(_ sender: ColorSlider){
        if sender == slider{
            slider.gradientView.layer.borderColor = sender.color.cgColor
            drawCanvas.brush.color = Color(sender.color)
            if let index = tools.firstIndex(where: {$0["Name"] as? String == "Pen_Color"}){
                tools[index]["Icon_Color"] = sender.color.withAlphaComponent(0.5)
                if let cell = toolCollectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? DrawToolsCell{
                    cell.toolBtn.tintColor = sender.color.withAlphaComponent(0.5)
                }
            }
        }
        else if sender == textSlider{
            activeLbl?.color = sender.color
        }
    }
    
    @objc func undoColors(_ sender: UIButton){
        drawCanvas.undo()
        if drawCanvas.drawItems.isEmpty{
            if drawCanvas.brush.blendMode == .clear{
                drawCanvas.isEnabled = false
            }
        }
    }
    
    @objc func switchBrush(_ sender: UIButton){
        
        if drawCanvas.brush.blendMode == .clear{
            sender.setImage(UIImage(nameOrSystemName: "pencil.circle", systemPointSize: 25, iconSize: 9), for: .normal)
            drawCanvas.brush.blendMode = .normal
            drawCanvas.brush.color = Color(slider.color)
            drawCanvas.isEnabled = true
        }
        else{
            sender.setImage(UIImage(named: "eraser"), for: .normal)
            drawCanvas.brush.blendMode = .clear
            if drawCanvas.drawItems.isEmpty{
                drawCanvas.isEnabled = false
            }
        }
    }
    
    @objc func activateNewLine(_ sender: UIButton){
        if let lineImageView = lineTypeView.subviews.first(where: {$0.isKind(of: UIImageView.self)}) as? UIImageView{
            lineTypeView.center = drawCanvas.center
            lineTypeView.center.y = drawCanvas.center.y - self.view.safeAreaInsets.top
            lineImageView.frame.origin = CGPoint.zero
            lineTypeView.tintColor = slider.color
            lineTypeView.isHidden = false
            AudioServicesPlaySystemSound(1519)
            
            switch drawCanvas.drawMode{
            case .draw:
                drawCanvas.drawMode = .line
                lineImageView.image = UIImage(named: "straight.mode")
                sender.setImage(UIImage(named: "straight.mode"), for: .normal)
            case .line:
                drawCanvas.drawMode = .ellipse
                lineImageView.image = UIImage(systemName: "circle")
                sender.setImage(UIImage(systemName: "circle"), for: .normal)
            case .ellipse:
                drawCanvas.drawMode = .rect
                lineImageView.image = UIImage(systemName: "rectangle")
                sender.setImage(UIImage(systemName: "rectangle"), for: .normal)
            case .rect:
                drawCanvas.drawMode = .draw
                lineImageView.image = UIImage(named: "scribble.mode")
                sender.setImage(UIImage(named: "scribble.mode"), for: .normal)
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
        
    }
    
    func swiftyDraw(isDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) {
        guard drawingView.drawMode == .line else{return}
        if drawingView.firstPoint.x == drawingView.currentPoint.x, drawingView.firstPoint.y != drawingView.currentPoint.y{
            print("match")
        }
    }
    
    func swiftyDraw(didFinishDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) {
    }
    
    
    func swiftyDraw(didCancelDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) {
    }
    
    @objc func changeBrushSize(_ sender: UIPinchGestureRecognizer){
        switch sender.state {
        case .began:
            if !drawCanvas.drawItems.isEmpty{
                drawCanvas.undo()
            }
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
        default:
            brushCircle.isHidden = true
            drawCanvas.isEnabled = true
            return
        }
    }
    
    
}

extension SwiftyDraw.SwiftyDrawView.DrawItem {
    func copy() -> SwiftyDraw.SwiftyDrawView.DrawItem {
        return SwiftyDraw.SwiftyDrawView.DrawItem(path: self.path, brush: self.brush, isFillPath: self.isFillPath)
    }
}
