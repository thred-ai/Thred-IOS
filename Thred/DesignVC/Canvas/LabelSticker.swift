//
//  LabelSticker.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import Foundation
import UIKit

extension DesignViewController{
    
    @objc func changeTextStyle(_ sender: UIButton){
        if let textView = self.canvas.subviews.first(where: {$0.isFirstResponder}) as? UITextView{
            switch currentLabelStyle{
            case .large:
                currentLabelStyle = .normal
                sender.setTitle("Normal", for: .normal)
                textView.font = UIFont.systemFont(ofSize: currentFontSize ?? CGFloat(defaultFontSize))
                textView.textColor = textSlider.color
                textView.backgroundColor = .clear
                textView.textAlignment = .left
            case .normal:
                currentLabelStyle = .nexa
                sender.setTitle("Nexa", for: .normal)
                textView.font = UIFont(name: "NexaW01-Heavy", size: currentFontSize ?? CGFloat(defaultFontSize))
                textView.textColor = textSlider.color
                textView.backgroundColor = .clear
                textView.textAlignment = .center
            case .nexa:
                currentLabelStyle = .fancy
                sender.setTitle("Fancy", for: .normal)
                textView.font = UIFont(name: "akaDora", size: currentFontSize ?? CGFloat(defaultFontSize))
                textView.textColor = textSlider.color
                textView.backgroundColor = .clear
                textView.textAlignment = .center
            case .fancy:
                currentLabelStyle = .fill
                sender.setTitle("Fill", for: .normal)
                textView.font = UIFont.boldSystemFont(ofSize: currentFontSize ?? CGFloat(defaultFontSize))
                if textSlider.color == UIColor(red: 1, green: 1, blue: 1, alpha: 1){
                    textView.textColor = .black
                }
                else{
                    textView.textColor = .white
                }
                textView.backgroundColor = textSlider.color
                textView.textAlignment = .center
            case .fill:
                currentLabelStyle = .hype
                sender.setTitle("Hype", for: .normal)
                textView.font = UIFont(name: "HOPE-HYPE", size: currentFontSize ?? CGFloat(defaultFontSize))
                textView.textColor = textSlider.color
                textView.backgroundColor = .clear
                textView.textAlignment = .center
            case .hype:
                currentLabelStyle = .large
                sender.setTitle("Large", for: .normal)
                textView.font = UIFont.boldSystemFont(ofSize: currentFontSize ?? CGFloat(defaultFontSize))
                textView.textColor = textSlider.color
                textView.backgroundColor = .clear
                textView.textAlignment = .center
            default:
                break
            }
            textViewDidChange(textView)
        }
    }
    
    func setTextStyle(_ sender: UIButton, textView: UITextView){
        switch currentLabelStyle{
        case .normal:
            currentLabelStyle = .normal
            sender.setTitle("Normal", for: .normal)
            textView.font = UIFont.systemFont(ofSize: currentFontSize ?? CGFloat(defaultFontSize))
            textView.textColor = textSlider.color
            textView.backgroundColor = .clear
            textView.textAlignment = .left
        case .nexa:
            currentLabelStyle = .nexa
            sender.setTitle("Nexa", for: .normal)
            textView.font = UIFont(name: "NexaW01-Heavy", size: currentFontSize ?? CGFloat(defaultFontSize))
            textView.textColor = textSlider.color
            textView.backgroundColor = .clear
            textView.textAlignment = .center
        case .fancy:
            currentLabelStyle = .fancy
            sender.setTitle("Fancy", for: .normal)
            textView.font = UIFont(name: "akaDora", size: currentFontSize ?? CGFloat(defaultFontSize))
            textView.textColor = textSlider.color
            textView.backgroundColor = .clear
            textView.textAlignment = .center
        case .fill:
            currentLabelStyle = .fill
            sender.setTitle("Fill", for: .normal)
            textView.font = UIFont.boldSystemFont(ofSize: currentFontSize ?? CGFloat(defaultFontSize))
            if textSlider.color == UIColor(red: 1, green: 1, blue: 1, alpha: 1){
                textView.textColor = .black
            }
            else{
                textView.textColor = .white
            }
            textView.backgroundColor = textSlider.color
            textView.textAlignment = .center
        case .hype:
            currentLabelStyle = .hype
            sender.setTitle("Hype", for: .normal)
            textView.font = UIFont(name: "HOPE-HYPE", size: currentFontSize ?? CGFloat(defaultFontSize))
            textView.textColor = textSlider.color
            textView.backgroundColor = .clear
            textView.textAlignment = .center
        case .large:
            currentLabelStyle = .large
            sender.setTitle("Large", for: .normal)
            textView.font = UIFont.boldSystemFont(ofSize: currentFontSize ?? CGFloat(defaultFontSize))
            textView.textColor = textSlider.color
            textView.backgroundColor = .clear
            textView.textAlignment = .center
        default:
            break
        }
    }
    
    @objc func addLabel(_ sender: Any){
        
        if !cameraRollCollectionView.isHidden{
            configurePhotos(photosBtn)
        }
        if !canvas.subviews.contains(where: {($0.isKind(of: UITextView.self) && $0.isFirstResponder)}){
            
            let label = UITextView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 80))
            label.center = canvas.center
            label.center.y = canvas.center.y - 200
            label.textAlignment = .center
            label.backgroundColor = .clear
            if shadowBtn != nil{
                if shadowBtn.isSelected{
                    label.setRadiusWithShadow()
                }
            }
            if textSlider != nil{
                label.textColor = textSlider.color
            }
            else{
                label.textColor = .white
            }
            label.autoresizesSubviews = true
            label.showsVerticalScrollIndicator = false
            label.isScrollEnabled = false
            label.delegate = self
            label.inputAccessoryView = textToolBar
            label.becomeFirstResponder()
            makeMovable(view: label)
            canvas.addSubview(label)
            canvas.gestureRecognizers?.first?.isEnabled = false
            setTextStyle(textStyleBtn, textView: label)
            let labelPreview = UIImageView.init(frame: CGRect(x: 0, y: 0, width: label.frame.width, height: label.frame.height))
            labelPreview.isUserInteractionEnabled = false
            labelPreview.backgroundColor = .clear
            label.addSubview(labelPreview)
        }
    }
    
    @objc func configureTextShadow(_ sender: UIButton){
        if let textView = self.canvas.subviews.first(where: {$0.isFirstResponder}) as? UITextView{
            if sender.isSelected{
                shadowBtn.setImage(UIImage(nameOrSystemName: "rectangle.on.rectangle", systemPointSize: 22, iconSize: 7), for: .normal)
            }
            else{
                shadowBtn.setImage(UIImage(nameOrSystemName: "rectangle.fill.on.rectangle.fill", systemPointSize: 22, iconSize: 7), for: .normal)
                textView.setRadiusWithShadow()
                sender.isSelected = true
            }
        }
    }
    
    @objc func doneLabelTyping(_ sender: Any){
        textDoneBtn.isEnabled = false
        if let textView = self.canvas.subviews.first(where: {$0.isFirstResponder}) as? UITextView{
            textView.resignFirstResponder()
            textView.isScrollEnabled = false
            self.textStyleBtn.superview?.isHidden = true
            self.fontSlider.isHidden = true
            self.textCoverView.isHidden = true
            
            let textChars = textView.text.replacingOccurrences(of: " ", with: "")
            if let imageView = textView.subviews.first(where: {$0.isKind(of: UIImageView.self)}) as? UIImageView{
                let size = textView.sizeThatFits(CGSize(width: self.canvas.frame.width, height: CGFloat.greatestFiniteMagnitude))
                DispatchQueue.main.async {
                    let resizedY = (self.view.frame.height - self.keyboardHeight - size.height) - self.view.safeAreaInsets.top
                    textView.frame.origin.y = resizedY
                    imageView.frame.origin = CGPoint.zero
                }
                textView.frame.size = size
                textView.center = canvas.center
                imageView.frame.size = size
                imageView.image = nil
                if !textChars.isEmpty{
                    imageView.isHidden = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        imageView.image = textView.makeSnapshot()
                        textView.accessibilityIdentifier = textView.text
                        textView.text.removeAll()
                    }
                }
                else{
                    textView.removeFromSuperview()
                    self.canvas.gestureRecognizers?.first?.isEnabled = true
                    return
                }
            }
            if self.editingTransform != nil && self.editingCenter != nil{
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.15, animations: {
                        textView.transform = self.editingTransform
                        textView.center = self.editingCenter
                    }, completion: { finished in
                        if finished{
                            self.editingTransform = nil
                            self.editingCenter = nil
                            self.activeLbl = nil
                            self.canvas.gestureRecognizers?.first?.isEnabled = true
                            for gesture in textView.gestureRecognizers ?? []{
                                if gesture.accessibilityLabel == "pan" || gesture.accessibilityLabel == "pinch" || gesture.accessibilityLabel == "rotate"{
                                    gesture.isEnabled = true
                                }
                            }
                        }
                    })
                }
            }
        }
    }
    
    @objc func resizeFont(_ sender: UISlider){
        if let textView = self.canvas.subviews.first(where: {$0.isFirstResponder}) as? UITextView{
            let size = CGFloat(sender.value)
            textView.font = textView.font?.withSize(size)
            currentFontSize = size
            textViewDidChange(textView)
        }
    }
}
