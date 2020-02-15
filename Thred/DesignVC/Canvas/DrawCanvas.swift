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

extension DesignViewController{
    
    func swiftyDraw(shouldBeginDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) -> Bool {
        if (!drawingView.isHidden && !drawingView.isEnabled) || (drawingView.brush.blendMode == .clear && drawingView.lines.isEmpty){
            return false
        }
        drawingView.brush.adjustWidth(for: touch)
        return true
    }
    
    func swiftyDraw(didBeginDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) {
        
    }
    
    func swiftyDraw(isDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) {
        
    }
    
    func swiftyDraw(didFinishDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) {
        undo.isEnabled = true
        
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

        default:
            brushCircle.isHidden = true
            drawCanvas.isEnabled = true

            return
        }
    }
    
    
}
