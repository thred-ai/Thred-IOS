//
//  ObjectAlignmentLines.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import Foundation
import UIKit
import AVKit

extension DesignViewController{
    func checkCentering(viewDrag: UIView){
        //Check X Centering
        if viewDrag.center.x != canvas.center.x{
            if viewDrag.center.x <= canvas.center.x + 2 && viewDrag.center.x >= canvas.center.x - 2 {
                let centeredX = canvas.center.x
                midXLine.center.x = centeredX
                viewDrag.center.x = centeredX
                midXLine.isHidden = false
                if !viewCenteredX{
                AudioServicesPlaySystemSound(1519)
                    viewCenteredX = true
                }
            }
            else{
                midXLine.isHidden = true
                viewCenteredX = false
            }
        }
        
        //Check Y Centering
        var centeredY = canvas.center.y - self.view.safeAreaInsets.top
        let y = self.canvas.frame.origin.y
        let height = self.canvas.frame.height
        let bottomBarY = y + height + self.view.safeAreaInsets.top
        if bottomBarY >= self.view.frame.maxY - self.bottomBar.frame.height{
            let difference = (bottomBarY - self.view.frame.maxY - self.bottomBar.frame.height).magnitude
            centeredY -= difference
        }
        if viewDrag.center.y != centeredY{
            if viewDrag.center.y <= centeredY + 2 && viewDrag.center.y >= centeredY - 2{
                midYLine.center.y = centeredY
                viewDrag.center.y = centeredY
                midYLine.isHidden = false
                if !viewCenteredY{
                    AudioServicesPlaySystemSound(1519)
                    viewCenteredY = true
                }
            }
            else{
                midYLine.isHidden = true
                viewCenteredY = false
            }
        }
    }
    
    func checkRotation(viewDrag: UIView){
        var rotation = atan2(viewDrag.transform.b, viewDrag.transform.a)
        let bounds = (2 * CGFloat.pi) / 180
        let a = CGFloat(0)
        let b = CGFloat.pi/2
        let c = CGFloat.pi
        let e = 2 * CGFloat.pi
        if rotation >= e{
            rotation = rotation / e
            viewDrag.transform = viewDrag.transform.rotated(by: -e)
        }
        else if rotation >= a - bounds && rotation <= a + bounds{
            angleLine.center = viewDrag.center
            angleLine.isHidden = false
            viewDrag.transform = viewDrag.transform.rotated(by: a - rotation)
            if !angleLocked{
                angleLocked = true
                angleLine.transform = .identity
                angleLine.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                AudioServicesPlaySystemSound(1519)
            }
        }
        else if rotation >= b - bounds && rotation <= b + bounds{
            angleLine.center = viewDrag.center
            angleLine.isHidden = false
            viewDrag.transform = viewDrag.transform.rotated(by: b - rotation)
            if !angleLocked{
                angleLocked = true
                angleLine.transform = .identity
                angleLine.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
                AudioServicesPlaySystemSound(1519)
            }
        }
        else if rotation >= c - bounds && rotation <= c + bounds{
            angleLine.center = viewDrag.center
            angleLine.isHidden = false
            viewDrag.transform = viewDrag.transform.rotated(by: c - rotation)
            if !angleLocked{
                angleLocked = true
                angleLine.transform = .identity
                angleLine.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                AudioServicesPlaySystemSound(1519)
            }
        }
        else if rotation >= -b - bounds && rotation <= -b + bounds{
            angleLine.center = viewDrag.center
            angleLine.isHidden = false
            viewDrag.transform = viewDrag.transform.rotated(by: -b - rotation)
            if !angleLocked{
                angleLocked = true
                angleLine.transform = .identity
                angleLine.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
                AudioServicesPlaySystemSound(1519)
            }
        }
        else{
            angleLine.isHidden = true
            angleLocked = false
        }
    }
}
