//
//  GarbageBtn.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import Foundation
import UIKit

extension DesignViewController{
    func eatGarbageAnimation(completed: @escaping ()->()){
        UIView.animate(withDuration: 0.1, animations: {
            self.garbageBtn.transform = self.garbageBtn.transform.scaledBy(x: 1.5, y: 1.5)
        }, completion: { finished in
            if finished{
                UIView.animate(withDuration: 0.1, animations: {
                    self.garbageBtn.transform = self.garbageBtn.transform.rotated(by: CGFloat.pi)
                }, completion: { finished in
                    if finished{
                        UIView.animate(withDuration: 0.1, animations: {
                            self.garbageBtn.transform = .identity
                        }, completion: { finished in
                            if finished{
                                completed()
                            }
                        })
                    }
                })
            }
        })
    }
    
    func showGarbageBtn(){
        if garbageBtn.isHidden{
            garbageBtn.isHidden = false
            garbageBtn.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            garbageBtn.alpha = 0.0
            UIView.animate(withDuration: 0.1, animations: {
                self.garbageBtn.alpha = 1.0
                self.garbageBtn.transform = .identity
            })
        }
    }
    
    func hideGarbageBtn(){
        if !garbageBtn.isHidden{
            garbageBtn.alpha = 1.0
            UIView.animate(withDuration: 0.1, animations: {
                self.garbageBtn.alpha = 0.0
                self.garbageBtn.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            }, completion: { finished in
                if finished{
                    self.garbageBtn.isHidden = true
                    self.garbageBtn.transform = .identity
                }
            })
        }
    }
    
    
    func checkInGarbage(sender: UIPanGestureRecognizer, completed: @escaping (Bool)->()){
        if let view = sender.view{
            let selectionFrame = CGRect(x: garbageBtn.frame.origin.x - 5, y: garbageBtn.frame.origin.y - 5, width: garbageBtn.frame.size.height + 10, height: garbageBtn.frame.size.width + 10)
            if sender.numberOfTouches == 1{
                if sender.translation(in: canvas).y.magnitude >= 2.5 || sender.translation(in: canvas).x.magnitude >= 2.5{
                    showGarbageBtn()
                }
                if !self.garbageBtn.isHidden{
                    if selectionFrame.contains(sender.location(in: canvas)){
                        maximiseGarbage(view: view) {
                            completed(true)
                        }
                    }
                    else{
                        minimizeGarbage(view: view){
                            completed(false)
                        }
                    }
                }
            }
            else if sender.numberOfTouches == 0{
                if selectionFrame.contains(sender.location(in: canvas)){
                    maximiseGarbage(view: view) {
                        completed(true)
                    }
                }
                else{
                    hideGarbageBtn()
                }
            }
            else{
                hideGarbageBtn()
                completed(false)
            }
        }
    }
    
    func minimizeGarbage(view: UIView, completed: @escaping () ->()){
        UIView.animate(withDuration: 0.2, animations: {
            if self.garbageBtn.transform == CGAffineTransform(scaleX: 1.2, y: 1.2){
                view.transform = self.prevTransform
                view.alpha = 1.0
                if view == self.backgroundView{
                    self.canvas.sendSubviewToBack(view)
                }
                else{
                    self.canvas.bringSubviewToFront(view)
                }
            }
            self.garbageBtn.transform = CGAffineTransform.identity
        }, completion: { finished in
            if finished{
                completed()
            }
        })
    }
}
