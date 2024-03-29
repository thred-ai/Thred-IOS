//
//  LabelSticker.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import Foundation
import UIKit

extension CaseIterable where Self: Equatable {
    var index: Self.AllCases.Index? {
        return Self.allCases.firstIndex { self == $0 }
    }
}

extension DesignViewController{
    
    @objc func changeTextStyle(_ sender: UIButton){
        
        switch fontTable.isHidden {
        case true:
            showFontTable(sender: sender)
        default:
            hideFontTable()
        }
    }
    
    func showFontTable(sender: UIButton){
        if let section = labelFontCategories.firstIndex(where: {$0.containedFonts.contains(where: {$0.name == sender.title(for: .normal)})}), let index = labelFontCategories[section].containedFonts.firstIndex(where: {$0.name == sender.title(for: .normal)}){
            self.fontTable.selectRow(at: IndexPath(row: index, section: section), animated: false, scrollPosition: .middle)
        }
        self.fontTable.isHidden = false
        for gesture in self.textCoverView.gestureRecognizers ?? []{
            gesture.isEnabled = false
        }
        if let textView = self.canvas.subviews.first(where: {$0.isFirstResponder}) as? CanvasTextView{
            textView.isHidden = true
        }
    }
    
    func hideFontTable(){
        self.fontTable.isHidden = true
        if let textView = self.canvas.subviews.first(where: {$0.isFirstResponder}) as? CanvasTextView{
            textView.isHidden = false
        }
        for gesture in self.textCoverView.gestureRecognizers ?? []{
            gesture.isEnabled = true
        }
    }
    
    func setTextStyle(_ sender: UIButton, textView: CanvasTextView){
        
        textSlider.color = textView.color
        textSlider.previewView?.center.x = 0
        fontSlider.value = Float(textView.currentFontSize)
        shadowBtn.isSelected = !textView.hasShadow
        configureTextShadow(shadowBtn)
        
        sender.setTitle("\(textView.labelFont.name ?? "Large")".capitalizingFirstLetter(), for: .normal)

    }
    
    @objc func addLabel(_ sender: Any){
        
        if !cameraRollCollectionView.isHidden{
            configurePhotos(photosBtn)
        }
        if !canvas.subviews.contains(where: {($0.isKind(of: UITextView.self) && $0.isFirstResponder)}){
            
            let label = CanvasTextView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 80))
            label.center = canvas.center
            label.center.y = canvas.center.y - 200
            label.textAlignment = .center
            label.backgroundColor = .clear
            label.color = lastTextView?.color ?? .white
            label.defaultFontSize = defaultFontSize
            if let fontSize = lastTextView?.currentFontSize{
                label.currentFontSize = fontSize
            }
            if lastTextView?.hasShadow ?? false{
                label.setRadiusWithShadowDesign()
            }
            label.labelFont = lastTextView?.labelFont ?? labelFontCategories[0].containedFonts.first
            
            label.autoresizesSubviews = true
            label.showsVerticalScrollIndicator = false
            label.isScrollEnabled = false
            label.delegate = self
            label.inputAccessoryView = textToolBar
            label.keyboardAppearance = .dark
            label.becomeFirstResponder()
            makeMovable(view: label)
            canvas.addSubview(label)
            canvas.gestureRecognizers?.first?.isEnabled = false
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
                textView.removeShadow()
                sender.isSelected = false
            }
            else{
                shadowBtn.setImage(UIImage(nameOrSystemName: "rectangle.fill.on.rectangle.fill", systemPointSize: 22, iconSize: 7), for: .normal)
                textView.setRadiusWithShadowDesign()
                sender.isSelected = true
            }
        }
    }
    
    @objc func doneLabelTyping(_ sender: Any){
        textDoneBtn.isEnabled = false
        hideFontTable()
        
        for gesture in self.canvas.gestureRecognizers?.filter({$0 != exitTapper}) ?? []{
            gesture.isEnabled = true
        }
        if let textView = self.canvas.subviews.first(where: {$0.isFirstResponder}) as? CanvasTextView{
            lastTextView = textView
            textView.resignFirstResponder()
            textView.isScrollEnabled = false
            textStyleBtn.superview?.isHidden = true
            fontSlider.isHidden = true
            textCoverView.isHidden = true
            canvas.bringSubviewToFront(drawCanvas)
            let textChars = textView.text.replacingOccurrences(of: " ", with: "")
            if let imageView = textView.subviews.first(where: {$0.isKind(of: UIImageView.self)}) as? UIImageView{
                let size = textView.sizeThatFits(CGSize(width: self.canvas.frame.width, height: CGFloat.greatestFiniteMagnitude))
                DispatchQueue.main.async {
                    let resizedY = (self.view.frame.height - (self.keyboardHeight ?? 0) - size.height) - self.view.safeAreaInsets.top
                    textView.frame.origin.y = resizedY
                    imageView.frame.origin = CGPoint.zero
                    textView.frame.size = size
                    textView.center = self.canvas.center
                    imageView.frame.size = size
                }
                
                imageView.image = nil
                textView.textToStore = textView.text

                if !textChars.isEmpty{
                    imageView.isHidden = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        if let img = textView.makeSnapshot(clear: true, subviewsToIgnore: [imageView]){
                            imageView.image = img
                        }
                        textView.text = nil
                        if self.editingTransform != nil && self.editingCenter != nil{
                            textView.transform = self.editingTransform
                            textView.center = self.editingCenter
                        }
                    }
                }
                else{
                    textView.removeFromSuperview()
                    self.canvas.gestureRecognizers?.first?.isEnabled = true
                    return
                }
            }
            if self.editingTransform != nil && self.editingCenter != nil{
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
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
        if let textView = self.canvas.subviews.first(where: {$0.isFirstResponder}) as? CanvasTextView{
            let size = CGFloat(sender.value)
            textView.currentFontSize = size
            textViewDidChange(textView)
        }
    }
}
