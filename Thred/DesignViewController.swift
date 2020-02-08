//
//  DesignViewController.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-12-25.
//  Copyright © 2019 Thred. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage
import ColorCompatibility
import SwiftyDraw
import ColorSlider

class Template: Codable{
    
    var templateID: String!
    var templateData: Data!
    
    init(templateID: String!, templateData: Data!){
        self.templateID = templateID
        self.templateData = templateData
    }
    
    convenience init() {
        self.init(templateID: nil, templateData: nil)
    }
    
    static func == (lhs: Template, rhs: Template) -> Bool {
        return true
    }
}

class DesignViewController: UIViewController, UITextViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, SwiftyDrawViewDelegate {
    
    
    

    var cameraBtn: UIButton!
    var photosBtn: UIButton!
    var drawBtn: UIButton!
    var doneBtn: UIButton!
    
    
    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var titleView: UITextField!
    @IBOutlet weak var nextBtn: UIBarButtonItem!
    
    var currentItemIndex: Int! = 0

    @IBAction func nextPage(_ sender: UIBarButtonItem) {
        
        
    }
    
    lazy var carousel: TemplateCarousel = {
        let carousel = TemplateCarousel(frame: CGRect(x: 0, y: 0, width: displayView.frame.width, height: displayView.frame.height))
        carousel.translatesAutoresizingMaskIntoConstraints = false
        return carousel
    }()
    
    
    @objc func closeCamera(_ sender: UIButton?){
        self.titleView.isHidden = false
        self.bottomBar.isHidden = false
        canvas.gestureRecognizers?.first?.isEnabled = true
        self.cameraView.hideCameraAnimate(viewToCarry: self.bottomBar) {
            self.cameraView.resetDisplayImage()
        }
    }
    
    lazy var drawToolBar: UIStackView = {
        
        let stack = UIStackView(frame: CGRect(x: 10, y: 5, width: self.view.frame.width - 20, height: 35))
        
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.backgroundColor =
            ColorCompatibility.systemBackground
        stack.spacing = 10
        
        slider = ColorSlider(orientation: .horizontal, previewSide: .top)
        slider.gradientView.layer.borderColor = UIColor(named: "LoadingColor")?.cgColor
        slider.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        slider.color = .cyan
        
        let btnFrame = CGRect(x: 0, y: 0, width: stack.frame.height, height: stack.frame.height)
        
        done = UIButton(frame: btnFrame)
        done.tintColor = UIColor(named: "LoadingColor")
        done.addTarget(self, action: #selector(closeDrawCanvas(_:)), for: .touchUpInside)
        
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration.init(pointSize: 25, weight: UIImage.SymbolWeight.bold, scale: UIImage.SymbolScale.large)
            done.setImage(UIImage(systemName: "checkmark.circle", withConfiguration: configuration), for: .normal)
            done.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)
        } else {
            // Fallback on earlier versions
        }
        
        undo = UIButton(frame: btnFrame)
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration.init(pointSize: 25, weight: UIImage.SymbolWeight.bold, scale: UIImage.SymbolScale.large)
            undo.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)
            undo.setImage(UIImage(systemName: "arrow.uturn.left.circle"), for: .normal)
        } else {
            // Fallback on earlier versions
        }
        undo.tintColor = UIColor(named: "LoadingColor")
        undo.addTarget(self, action: #selector(undoColors(_:)), for: .touchUpInside)
        undo.isEnabled = false
        
        brushBtn = UIButton(frame: btnFrame)
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration.init(pointSize: 25, weight: UIImage.SymbolWeight.bold, scale: UIImage.SymbolScale.large)
            brushBtn.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)
            brushBtn.setImage(UIImage(systemName: "pencil.circle"), for: .normal)
        } else {
            // Fallback on earlier versions
        }
        brushBtn.tintColor = UIColor(named: "LoadingColor")
        brushBtn.addTarget(self, action: #selector(switchBrush(_:)), for: .touchUpInside)
        brushBtn.isEnabled = true
        
        clearBtn = UIButton(frame: btnFrame)
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration.init(pointSize: 25, weight: UIImage.SymbolWeight.bold, scale: UIImage.SymbolScale.large)
            clearBtn.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)
            clearBtn.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        } else {
            // Fallback on earlier versions
        }
        clearBtn.tintColor = UIColor(named: "LoadingColor")
        clearBtn.addTarget(self, action: #selector(clearCanvas(_:)), for: .touchUpInside)
        clearBtn.isEnabled = true

        stack.addArrangedSubview(brushBtn)
        stack.addArrangedSubview(clearBtn)
        stack.addArrangedSubview(slider)
        stack.addArrangedSubview(undo)
        stack.addArrangedSubview(done)
        
        return stack
    }()
    
    
    
    var undo: UIButton!
    var brushBtn: UIButton!
    var clearBtn: UIButton!
    var done: UIButton!
    var slider: ColorSlider!
    var garbageBtn: UIButton!
    var activeLbl: UITextView?
    
    @objc func colorChanged(_ sender: ColorSlider){
        if sender == slider{
            drawCanvas.brush.color = Color(sender.color)
        }
        else if sender == textSlider{
            if currentLabelStyle == .fill{
                activeLbl?.backgroundColor = sender.color
                if sender.color == UIColor(red: 1, green: 1, blue: 1, alpha: 1){
                    activeLbl?.textColor = .black
                }
                else{
                    activeLbl?.textColor = .white
                }
            }
            else{
                activeLbl?.textColor = sender.color
            }
        }
    }
    
    @objc func clearCanvas(_ sender: ColorSlider){
        drawCanvas.clear()
    }
    
    @objc func undoColors(_ sender: UIButton){
        drawCanvas.undo()
        if drawCanvas.lines.isEmpty{
            undo.isEnabled = false
        }
    }
    
    @objc func switchBrush(_ sender: UIButton){
        
        if drawCanvas.brush == .eraser{
            print(drawCanvas.brush)
            
            if #available(iOS 13.0, *) {
                brushBtn.setImage(UIImage(systemName: "pencil.circle"), for: .normal)
            } else {
                // Fallback on earlier versions
            }
            drawCanvas.brush = .medium
            drawCanvas.brush.color = Color(slider.color)
        }
        else{
            if #available(iOS 13.0, *) {
                brushBtn.setImage(UIImage(systemName: "pencil.circle.fill"), for: .normal)
            } else {
                // Fallback on earlier versions
            }
            drawCanvas.brush = .eraser
            drawCanvas.brush.width = 20
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
        
        let aspectRatio = selectedImage.size.height / selectedImage.size.width
        
        let width = canvas.frame.width / 4

        let imageView = UIImageView.init(frame: CGRect(x: canvas.frame.width / 2, y: canvas.frame.height / 2, width: width, height: width * aspectRatio))
        imageView.contentMode = .scaleAspectFit
        imageView.image = selectedImage
        let tapper = UILongPressGestureRecognizer(target: self, action: #selector(configureAsBackground(_:)))
        imageView.addGestureRecognizer(tapper)
        
        makeMovable(view: imageView)
        
        canvas.insertSubview(imageView, belowSubview: drawCanvas)
    }
    
    var backgroundView: UIImageView!
    
    @objc func configureAsBackground(_ sender: UILongPressGestureRecognizer){
        
        if sender.state == .began{
            if let heldView = sender.view as? UIImageView{
                if backgroundView == heldView{
                    backgroundView = nil
                    self.canvas.bringSubviewToFront(heldView)
                    heldView.alpha = 0.0
                    UIView.animate(withDuration: 0.25, animations: {
                        heldView.alpha = 1.0
                    })
                }
                else{
                    backgroundView = heldView
                    self.canvas.sendSubviewToBack(heldView)
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
            for view in self.canvas.subviews.filter({$0.isKind(of: UITextView.self) || $0.isKind(of: UIImageView.self)}){
                if view != ignoredView{
                    view.isUserInteractionEnabled = false
                }
            }
        }
        else{
            for view in self.canvas.subviews.filter({$0.isKind(of: UITextView.self) || $0.isKind(of: UIImageView.self)}){
                if view != ignoredView{
                    view.isUserInteractionEnabled = true
                }
            }
        }
    }
    
    func makeMovable(view: UIView){
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleObjectPan(_:)))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleObjectPinch(_:)))
        let rotate = UIRotationGestureRecognizer(target: self, action: #selector(handleObjectRotation(_:)))
        pan.accessibilityLabel = "pan"
        pinch.accessibilityLabel = "pinch"
        rotate.accessibilityLabel = "rotate"

        pan.delegate = self
        pinch.delegate = self
        rotate.delegate = self

        view.addGestureRecognizer(pan)
        view.addGestureRecognizer(pinch)
        view.addGestureRecognizer(rotate)

        view.isUserInteractionEnabled = true
        view.clipsToBounds = true
    }
    
    @objc func handleObjectPan(_ sender: UIPanGestureRecognizer){
        
        let viewDrag = sender.view!

        switch sender.state {
        case .began, .changed:
            canvas.gestureRecognizers?.first?.isEnabled = false

            if viewDrag != backgroundView{
                canvas.bringSubviewToFront(viewDrag)
                if viewDrag is UIImageView{
                    canvas.bringSubviewToFront(drawCanvas)
                }
                canvas.bringSubviewToFront(bottomBar)
            }
            
            configureOtherStickersGestures(ignoredView: viewDrag, disable: true)
            
            let translation = sender.translation(in: view)
            viewDrag.center = CGPoint(x: viewDrag.center.x + translation.x, y: viewDrag.center.y + translation.y)
            checkInGarbage(sender: sender, completed: {inGarbage in
                if !inGarbage{
                    self.canvas.bringSubviewToFront(self.garbageBtn)
                }
            })
            sender.setTranslation(CGPoint.zero, in: view)

        default:
            canvas.gestureRecognizers?.first?.isEnabled = true
            configureOtherStickersGestures(ignoredView: viewDrag, disable: false)
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
    
    @objc func handleObjectPinch(_ sender: UIPinchGestureRecognizer){
        switch sender.state {
        case .began, .changed:
            canvas.gestureRecognizers?.first?.isEnabled = false
            
            let viewDrag = sender.view!
            if viewDrag != backgroundView{
                canvas.bringSubviewToFront(viewDrag)
                if viewDrag is UIImageView{
                    canvas.bringSubviewToFront(drawCanvas)
                }
                canvas.bringSubviewToFront(bottomBar)
            }
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
            canvas.gestureRecognizers?.first?.isEnabled = false
            let viewDrag = sender.view!
            if viewDrag != backgroundView{
                canvas.bringSubviewToFront(viewDrag)
                if viewDrag is UIImageView{
                    canvas.bringSubviewToFront(drawCanvas)
                }
                canvas.bringSubviewToFront(bottomBar)
            }
            sender.view!.transform = sender.view!.transform.rotated(by: sender.rotation)
            sender.rotation = 0
            break
        default:
            canvas.gestureRecognizers?.first?.isEnabled = true
            break
        }
    }
    
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
    var prevTransform: CGAffineTransform!

    
    func maximiseGarbage(view: UIView, completed: @escaping () -> ()){
        if self.garbageBtn.transform != CGAffineTransform(scaleX: 1.2, y: 1.2){
            var scale: CGFloat!
            if view.frame.width > view.frame.height{
                scale = garbageBtn.frame.width / view.frame.width
            }
            else{
                scale = garbageBtn.frame.height / view.frame.height
            }
            prevTransform = view.transform
            UIView.animate(withDuration: 0.2, animations: {
                view.transform = view.transform.scaledBy(x: scale, y: scale)
                view.center = self.garbageBtn.center
                view.alpha = 0.8
                self.canvas.bringSubviewToFront(view)
                self.garbageBtn.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }, completion: { finished in
                if finished{
                    completed()
                }
            })
        }
        else{
            completed()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
        
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
                   //self.tableView.isHidden = true
                   //self.tableView.contentInset.bottom = 0
            }
        }
    }
    
    lazy var toolBar: UIView = {
        let bar = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 45))
        bar.backgroundColor = ColorCompatibility.systemBackground.withAlphaComponent(0.8)
        let stackView = UIStackView(frame: bar.frame)
        bar.addSubview(stackView)
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
    
        button.setTitle("Done", for: .normal)
        button.setTitleColor(ColorCompatibility.label, for: .normal)
        button.addTarget(self, action: #selector(doneEditing(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(button)
       
        return bar
    }()
    
    @objc func doneEditing(_ sender: UIButton){
        descriptionView.resignFirstResponder()
        titleView.resignFirstResponder()
    }
    
    
    @IBOutlet weak var descriptionView: UITextView!
    
    @objc func keyboardWillShow(_ notification: Notification) {

        let bottomPadding = view.safeAreaInsets.bottom
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            if (notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool ?? true){
                let keyboardFrame = keyboardFrame.cgRectValue
                keyboardHeight = keyboardFrame.height
                if canvas.isHidden{
                    UIView.animate(withDuration: 0.2, animations: {
                        //self.bottomBar.transform = CGAffineTransform(translationX: 0, y: -(keyboardHeight - bottomPadding))
                        
                        if self.scrollview.contentInset.bottom == 0{
                            self.scrollview.contentOffset.y -= self.keyboardHeight - bottomPadding
                        }
                        self.scrollview.contentInset.bottom = self.keyboardHeight - bottomPadding
                        self.scrollview.verticalScrollIndicatorInsets.bottom = self.keyboardHeight - bottomPadding
                        
                    }, completion: { finished in
                        if finished{}
                    })
                }
                else{
                    if let textView = canvas.subviews.first(where: {$0.isFirstResponder && $0.isKind(of: UITextView.self)}) as? UITextView{
                        self.activeLbl = textView
                        self.editingTransform = textView.transform
                        self.editingCenter = textView.center
                        self.textStyleBtn.superview?.isHidden = false
                        self.fontSlider.isHidden = false
                        self.textCoverView.isHidden = false

                        UIView.animate(withDuration: 0.15, animations: {
                            textView.transform = CGAffineTransform.identity
                        }, completion: { finished in
                            if finished{
                                self.textViewDidChange(textView)
                                if let textStyleView = self.textStyleBtn.superview{
                                    self.canvas.bringSubviewToFront(self.textCoverView)
                                    self.canvas.bringSubviewToFront(textStyleView)
                                    self.canvas.bringSubviewToFront(self.fontSlider)

                                    self.canvas.bringSubviewToFront(textView)
                                }
                                textView.center.x = self.canvas.center.x
                                if let imageView = textView.subviews.first(where: {$0.isKind(of: UIImageView.self)}) as? UIImageView{
                                    imageView.isHidden = true
                                }
                                for gesture in textView.gestureRecognizers ?? []{
                                    if gesture.accessibilityLabel == "pan" || gesture.accessibilityLabel == "pinch" || gesture.accessibilityLabel == "rotate"{
                                        gesture.isEnabled = false
                                    }
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    var textSlider: ColorSlider!
    var shadowBtn: UIButton!
    
    lazy var textToolBar: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: canvas.frame.width, height: 45))
        view.backgroundColor = ColorCompatibility.systemBackground
        
        let stack = UIStackView.init(frame: CGRect(x: 20, y: 10, width: view.frame.width - 40, height: view.frame.height - 20))
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.spacing = 20
        
        textSlider = ColorSlider(orientation: .horizontal, previewSide: .top)
        textSlider.gradientView.layer.borderColor = UIColor(named: "LoadingColor")?.cgColor
        textSlider.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        textSlider.color = .white
        
        let button1 = UIButton(frame: CGRect(x: 0, y: 0, width: 90, height: 45))
        button1.setTitle("Done", for: .normal)
        button1.setTitleColor(UIColor(named: "LoadingColor"), for: .normal)
        button1.addTarget(self, action: #selector(doneLabelTyping(_:)), for: .touchUpInside)
        
        shadowBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration.init(pointSize: 22, weight: UIImage.SymbolWeight.bold, scale: UIImage.SymbolScale.large)

            shadowBtn.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)
            shadowBtn.setImage(UIImage(systemName: "rectangle.on.rectangle"), for: .normal)
        } else {
            // Fallback on earlier versions
        }
        shadowBtn.tintColor = UIColor(named: "LoadingColor")
        shadowBtn.addTarget(self, action: #selector(configureTextShadow(_:)), for: .touchUpInside)
        
        stack.addArrangedSubview(shadowBtn)
        stack.addArrangedSubview(textSlider)
        stack.addArrangedSubview(button1)
        
        view.addSubview(stack)
        
        return view
    }()
    
    
    @objc func configureTextShadow(_ sender: UIButton){
        
        if let textView = self.canvas.subviews.first(where: {$0.isFirstResponder}) as? UITextView{
            if #available(iOS 13.0, *) {
                if sender.isSelected{
                    sender.setImage(UIImage(systemName: "rectangle.on.rectangle"), for: .normal)
                    textView.removeShadow()
                    sender.isSelected = false
                }
                else{
                    sender.setImage(UIImage(systemName: "rectangle.fill.on.rectangle.fill"), for: .normal)
                    textView.setRadiusWithShadow()
                    sender.isSelected = true
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    @objc func doneLabelTyping(_ sender: Any){
        if let textView = self.canvas.subviews.first(where: {$0.isFirstResponder}) as? UITextView{
            textView.resignFirstResponder()
            textView.isScrollEnabled = false
            self.textStyleBtn.superview?.isHidden = true
            self.fontSlider.isHidden = true
            self.textCoverView.isHidden = true

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
                
                
                if !textView.text.isEmpty{
                    imageView.isHidden = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        imageView.image = textView.makeSnapshot()
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
    
    @objc func keyboardWillHide(_ notification: Notification) {
        
        if (notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool ?? true){
            descriptionView.scrollRangeToVisible(NSRange(location: 0, length: 0))
            UIView.animate(withDuration: 0.2, animations: {
                self.bottomBar.transform = CGAffineTransform.identity
                self.scrollview.contentInset.bottom = 0
                self.scrollview.verticalScrollIndicatorInsets.bottom = 0
            })
        }
    }
    
    var placeholderLabel = UILabel()

    func setPlaceholder(textView: UITextView, textColor: UIColor?){
        
        
        placeholderLabel.text = "Describe this design..."
        placeholderLabel.font = UIFont(name: "NexaW01-Heavy", size: 16)
        placeholderLabel.sizeToFit()
        placeholderLabel.backgroundColor = UIColor.clear
        placeholderLabel.textColor = textColor
        
        if !textView.subviews.contains(placeholderLabel){
            textView.addSubview(placeholderLabel)
            placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
            placeholderLabel.centerYAnchor.constraint(equalTo: textView.centerYAnchor).isActive = true
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor,  constant: 5).isActive = true
            placeholderLabel.isHidden = !textView.text.isEmpty
        }
    }
    
    var textEditInfo = [[String: Any]]()
    var editingTransform: CGAffineTransform!
    var editingCenter: CGPoint!
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == descriptionView{
            
        }
        else{
            
        }
    }
    
    
    
    func textViewDidEndEditing(_ textView: UITextView) {
        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView == descriptionView{
                
            }
            else{
                
            }
        }
    }
    
    var keyboardHeight: CGFloat!
    
    func textViewDidChange(_ textView: UITextView) {
        if textView == descriptionView{
            placeholderLabel.isHidden = !textView.text.isEmpty
        }
        else{
            let size = textView.sizeThatFits(CGSize(width: canvas.frame.width, height: CGFloat.greatestFiniteMagnitude))
            textView.center.x = canvas.center.x
            if keyboardHeight != nil{
                UIView.animate(withDuration: 0.1, animations: {
                    let resizedY = (self.view.frame.height - self.keyboardHeight - size.height) - self.view.safeAreaInsets.top
                    
                    if let textStyleView = self.textStyleBtn.superview{
                        let minY = textStyleView.frame.maxY + 10
                        if resizedY <= minY{
                            textView.isScrollEnabled = true
                            textView.frame.origin.y = minY
                            textView.frame.size.height = -(minY - (self.canvas.frame.maxY - self.keyboardHeight)) + self.view.safeAreaInsets.bottom
                            if textView.text.count > 250{
                                textView.text.removeLast(textView.text.count - 250)
                            }
                        }
                        else{
                            textView.isScrollEnabled = false
                            textView.frame.size = size
                            textView.frame.size.width = self.canvas.frame.width
                            textView.frame.origin.y = resizedY
                        }
                    }
                })
            }
        }
    }
    
    var hoodies = [Data]()
    var tees = [Template]()
    
    func loadDesigns(completed: @escaping ()->()){
        
        tees.checkAndLoadTemplates(type: "TeeTemplates"){
            
            DispatchQueue.main.async {
                if self.tees.isEmpty{
                    Firestore.firestore().document("Templates/Tees").getDocument(completion: { snap, error in
                        if error != nil{
                            print(error?.localizedDescription ?? "")
                        }
                        else{
                            //for doc in snaps?.documents ?? []{
                            guard let doc = snap else{return}
                                let ids = doc["IDs"] as? [String]
                                for id in ids ?? []{
                                    Storage.storage().reference(withPath: "Templates/\(doc.documentID)/\(id).png").downloadURL(completion: { url, error in
                                        if error != nil{
                                            print(error?.localizedDescription ?? "")
                                        }
                                        else{
                                            var dub: CGFloat = 0
                                            var oldDub: CGFloat = 0
                                            SDWebImageDownloader.shared.requestImage(with: url, options: [.highPriority, .continueInBackground, .scaleDownLargeImages], context: nil, progress: { (receivedSize: Int, expectedSize: Int, link) -> Void in
                                                dub = CGFloat(receivedSize) / CGFloat(expectedSize)
                                                print("Progress \(dub)")
                                                print("Old Progress \(oldDub)")
                                                DispatchQueue.main.sync {
                                                    //cp?.setProgressWithAnimation(duration: 0.0, value: dub, from: oldDub, finished: true){
                                                        oldDub = dub
                                                   // }
                                                }
                                            }, completed: {[weak self] (image, data, error, finished) in
                                                if error != nil{
                                                    print(error?.localizedDescription ?? "")
                                                }
                                                else{
                                                    if let imgData = data{
                                                        let tee = Template(templateID: id, templateData: imgData)
                                                        self?.tees.append(tee)
                                                        
                                                        if self?.tees.count == ids?.count{
                                                            self?.tees.sort(by: {$0.templateID < $1.templateID})
                                                        
                                                            self?.tees.saveTemplates(type: "TeeTemplates", name: "TemplateData")
                                                            completed()
                                                        }
                                                    }
                                                }
                                            })
                                        }
                                    })
                                }
                            //}
                        }
                    })
                }
                else{
                    completed()
                }
            }
        }
    }
    
    
    
    @IBOutlet weak var displayView: UIView!
    
    
    lazy var cameraView: CameraView = {
        
        let cameraView = CameraView.init(frame: CGRect(x: 0, y: bottomBar.frame.maxY, width: view.frame.width, height: view.frame.height))
        
        cameraView.bottomBar.frame.size.height = cameraView.bottomBar.frame.height + view.safeAreaInsets.bottom
        cameraView.bottomBar.frame.origin.y = cameraView.frame.height - (cameraView.bottomBar.frame.height)
        
        cameraView.dismissBtn.addTarget(self, action: #selector(closeCamera(_:)), for: .touchUpInside)
        
        view.addSubview(cameraView)

        return cameraView
        
    }()
    
    var aspectRatio: CGFloat = 1
    var drawCanvas: SwiftyDrawView!
    var textStyleBtn: UIButton!
    
    lazy var canvasDisplayView: UIImageView = {
        
        let stack = displayView.superview as! UIStackView
        let x = displayView.frame.width / 3
        let y = stack.spacing + displayView.frame.height / 4
        let width = displayView.frame.width / 4
        
        let height = (displayView.frame.height - displayView.frame.height / 2) - 50
        let view = UIImageView(frame: CGRect(x: x, y: y, width: width, height: height))
        view.center.x = displayView.center.x
        view.layer.borderColor = UIColor.gray.cgColor
        view.layer.borderWidth = 1
        view.isUserInteractionEnabled = true
        view.isHidden = true
        //view.backgroundColor = UIColor(named: tees[currentItemIndex].templateID)?.withAlphaComponent(0.25)

        return view
    }()
    
    var textCoverView: UIView!
    var defaultFontSize = 55
        
    @objc func exitPhotosTap(_ sender: UITapGestureRecognizer){
        if !self.cameraRollCollectionView.isHidden{
            self.configurePhotos(photosBtn)
        }
    }
    
    var exitTapper: UITapGestureRecognizer!
    
    lazy var canvas: UIView = {
        
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height * aspectRatio))
        view.isUserInteractionEnabled = true
        view.backgroundColor = UIColor(named: tees[currentItemIndex].templateID)
        view.clipsToBounds = true
        
        let tapper = UITapGestureRecognizer(target: self, action: #selector(addLabel(_:)))
        view.addGestureRecognizer(tapper)
        
        exitTapper = UITapGestureRecognizer(target: self, action: #selector(exitPhotosTap(_:)))
        view.addGestureRecognizer(exitTapper)
        exitTapper.isEnabled = false

        drawCanvas = SwiftyDrawView.init(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        drawCanvas.delegate = self
        drawCanvas.isEnabled = false
        drawCanvas.brush = .medium
        drawCanvas.brush.color = Color(.cyan)
        drawCanvas.isUserInteractionEnabled = false
        
        
        garbageBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        garbageBtn.center.x = view.center.x
        garbageBtn.center.y = (view.frame.maxY) - (garbageBtn.frame.height / 2) - 10
        garbageBtn.setRadiusWithShadow()
        garbageBtn.tintColor = UIColor(named: "LoadingColor")
        garbageBtn.isUserInteractionEnabled = false
        

        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration.init(pointSize: 30, weight: UIImage.SymbolWeight.bold, scale: UIImage.SymbolScale.large)
            garbageBtn.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)
            garbageBtn.setImage(UIImage(systemName: "trash.circle"), for: .normal)
        } else {
            // Fallback on earlier versions
        }
        
        let backView = UIView(frame: CGRect(x: 10, y: 10, width: 100, height: 30))
        backView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backView.layer.borderColor = UIColor(named: "LoadingColor")?.cgColor
        backView.layer.borderWidth = 1
        backView.layer.cornerRadius = backView.frame.height / 2
        backView.clipsToBounds = true
        textStyleBtn = UIButton.init(frame: CGRect(x: 5, y: 5, width: backView.frame.width - 10, height: backView.frame.height - 10))
        textStyleBtn.setTitle("Large", for: .normal)
        textStyleBtn.setTitleColor(UIColor(named: "LoadingColor"), for: .normal)
        textStyleBtn.addTarget(self, action: #selector(changeTextStyle(_:)), for: .touchUpInside)
        currentLabelStyle = .large
        textStyleBtn.showsTouchWhenHighlighted = true
        backView.addSubview(textStyleBtn)
        textCoverView = UIView.init(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        let textTapper = UITapGestureRecognizer(target: self, action: #selector(doneLabelTyping(_:)))
        textCoverView.addGestureRecognizer(textTapper)
        textCoverView.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        fontSlider = UISlider(frame: CGRect(x: backView.frame.maxX + 10, y: 10, width: view.frame.width - 10 - backView.frame.width - 10 - 10, height: 30))
        fontSlider.minimumValue = 20
        fontSlider.maximumValue = Float(defaultFontSize)
        fontSlider.value = Float(defaultFontSize)
        fontSlider.maximumTrackTintColor = UIColor(named: "LoadingColor")
        fontSlider.minimumTrackTintColor = UIColor(named: "LoadingColor")
        currentFontSize = CGFloat(defaultFontSize)
        fontSlider.addTarget(self, action: #selector(resizeFont(_:)), for: .valueChanged)
        
        view.addSubview(garbageBtn)
        view.addSubview(textCoverView)
        view.addSubview(backView)
        view.addSubview(fontSlider)
        view.addSubview(drawCanvas)
                
        return view
    }()
    
    @objc func resizeFont(_ sender: UISlider){
        if let textView = self.canvas.subviews.first(where: {$0.isFirstResponder}) as? UITextView{
            let size = CGFloat(sender.value)
            textView.font = textView.font?.withSize(size)
            currentFontSize = size
            textViewDidChange(textView)
        }
    }
    
    var fontSlider: UISlider!
    
    public enum LabelStyle {
        case large
        case normal
        case nexa
        case fancy
        case fill
        case hype
    }
    
    var currentLabelStyle: LabelStyle!
    var currentFontSize: CGFloat!
    

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
                textView.font = UIFont(name: "HYPE", size: currentFontSize ?? CGFloat(defaultFontSize))
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
            textView.font = UIFont(name: "HYPE", size: currentFontSize ?? CGFloat(defaultFontSize))
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
    
    @objc func addLabel(_ sender: UITapGestureRecognizer){
        
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
    
    

    
    
    func swiftyDraw(shouldBeginDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) -> Bool {
        if (!drawingView.isHidden && !drawingView.isEnabled) || (drawingView.brush == .eraser && drawingView.lines.isEmpty){
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
    
    override func viewDidLayoutSubviews() {
        
    }
    
    
    
    @objc func minimizeDrawingArea(_ sender: UIButton){
        
        canvasDisplayView.image = nil
        garbageBtn.isHidden = true
        textCoverView.isHidden = true
        textStyleBtn.superview?.isHidden = true
        fontSlider.isHidden = true
        if canvas.subviews.contains(where: {$0.isKind(of: UIImageView.self) || ($0.isKind(of: UITextView.self))}) || drawCanvas.lines.contains(where: {$0.brush != .eraser}){
            canvasDisplayView.image = canvas.makeSnapshot()
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
            //self.displayView.image = UIImage(data: self.tees[self.currentItemIndex].templateData)
            self.titleView.isUserInteractionEnabled = true
            self.bottomBar.isHidden = true
            self.bottomSafeAreaView.isHidden = true
            self.descriptionView.isHidden = false
            self.drawCanvas.isEnabled = false
            self.drawBtn.isSelected = false
            self.drawBtn.tintColor = UIColor(named: "LoadingColor")

            //check if empty
            if self.canvasDisplayView.image == nil{
                self.canvasDisplayView.layer.borderWidth = 1
                self.selectedView.layer.borderWidth = 1
            }
            else{
                self.canvasDisplayView.layer.borderWidth = 0
                self.selectedView.layer.borderWidth = 1

            }
            
            self.drawCanvas.isHidden = true
            self.canvas.isHidden = true
            
            UIView.animate(withDuration: 0.2, animations: {
                self.descriptionView.alpha = 1.0
                self.canvasDisplayView.frame = CGRect(x: x, y: y, width: width, height: height)
                self.canvasDisplayView.center.x = self.displayView.center.x
            }, completion: { finished in
                if finished{
                    UIView.animate(withDuration: 0.1, animations: {
                        self.carousel.displayImage = self.canvasDisplayView.image
                        self.carousel.collectionView.reloadData()
                        self.selectedView.isHidden = false
                        self.selectedView = nil
                        self.canvasDisplayView.isHidden = true
                        self.canvasDisplayView.backgroundColor = UIColor(named: self.tees[self.currentItemIndex].templateID)?.withAlphaComponent(0.25)
                    })
                }
            })
        }
    }
    
    @objc func closeDrawCanvas(_ sender: UIButton){
        for label in canvas.subviews.filter({$0.isKind(of: UITextView.self)}){
            label.isUserInteractionEnabled = true
        }
        drawToolBar.isHidden = true
        canvas.gestureRecognizers?.first?.isEnabled = true
        drawToolBar.isHidden = true
        drawCanvas.isUserInteractionEnabled = false
        drawBtn.superview?.isHidden = false
        drawCanvas.isEnabled = false
        drawBtn.isSelected = false
    }

    @objc func openDrawCanvas(_ sender: UIButton){
        
        drawToolBar.isHidden = false
        sender.superview?.isHidden = true
        if !cameraRollCollectionView.isHidden{
            configurePhotos(photosBtn)
        }
        
        canvas.bringSubviewToFront(drawCanvas)
        for label in canvas.subviews.filter({$0.isKind(of: UITextView.self)}){
            label.isUserInteractionEnabled = false
            canvas.bringSubviewToFront(label)
        }
        drawCanvas.isEnabled = true
        canvas.gestureRecognizers?.first?.isEnabled = false
        drawCanvas.isUserInteractionEnabled = true
        sender.isSelected = true
        
    }
    
    
        
    var selectedView: UIImageView!
    
    lazy var bottomSafeAreaView: UIView = {
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: bottomBar.frame.width, height: 0))
        view.backgroundColor = bottomBar.backgroundColor
        return view
    }()
    
    @objc func maximiseDrawingArea(displayView: UIImageView){
        
        if let selectedIndex = carousel.collectionView.indexPathsForVisibleItems.first?.item{
            aspectRatio = displayView.frame.height / displayView.frame.width
            
            print(displayView.frame.width)
            print(displayView.frame.height)
            
            let viewY = displayView.frame.origin.y
            let width = view.frame.width
            let height = view.frame.width * aspectRatio
            
            let difference = (canvas.frame.height - height).magnitude
            garbageBtn.center.y -= difference
            
            self.titleView.isUserInteractionEnabled = false
            self.canvasDisplayView.isHidden = false
            self.canvasDisplayView.frame.size = displayView.frame.size
            self.canvasDisplayView.frame.origin.y = viewY
            displayView.isHidden = true
            self.carousel.displayImage = self.canvasDisplayView.image
            selectedView = displayView

            
            DispatchQueue.main.async {
                self.scrollview.setContentOffset(.zero, animated: true)
                self.scrollview.isScrollEnabled = false
                self.canvas.backgroundColor = UIColor(named: self.tees[selectedIndex].templateID)
                self.canvasDisplayView.backgroundColor = UIColor(named: self.tees[selectedIndex].templateID)
                self.garbageBtn.isHidden = true
                self.textStyleBtn.superview?.isHidden = true
                self.fontSlider.isHidden = true
                self.textCoverView.isHidden = true
                self.bottomBar.isHidden = false
                self.bottomSafeAreaView.isHidden = false
                //self.bottomBar
                let y = self.displayView.frame.origin.y
                var bottomBarY = y + height + self.view.safeAreaInsets.top
                if bottomBarY >= self.view.frame.maxY - self.bottomBar.frame.height{
                    bottomBarY = self.view.frame.maxY - self.bottomBar.frame.height
                }
                self.bottomBar.frame.origin.y = bottomBarY
                self.bottomSafeAreaView.frame.origin.y = self.bottomBar.frame.maxY
                self.bottomSafeAreaView.frame.size.height = self.view.frame.maxY - self.bottomSafeAreaView.frame.origin.y
                
                UIView.animate(withDuration: 0.2, animations: {
                    self.descriptionView.alpha = 0.0
                    self.canvasDisplayView.frame = CGRect(x: 0, y: y, width: width, height: height)
                    self.canvasDisplayView.center.x = self.view.center.x
                    self.canvas.frame = CGRect(x: 0, y: y + self.view.safeAreaInsets.top, width: width, height: height)
                    self.canvasDisplayView.layer.borderWidth = 0
                    self.canvas.center.x = self.view.center.x
                    
                }, completion: { finished in
                    if finished{
                        //self.displayView.image = nil
                        self.descriptionView.isHidden = true
                        self.canvas.isHidden = false
                        self.drawCanvas.isHidden = false
                    }
                })
            }
        }
    }
    
    
    
    
    lazy var cameraRollCollectionView: CameraRollView = {
        
        let y = view.frame.midY
        let collectionView = CameraRollView.init(frame: CGRect(x: 0, y: view.frame.height - y, width: view.frame.width, height: y), collectionViewLayout: CollectionViewLayout())
        
        if let backView = collectionView.backgroundView{
            backView.addViewSpinner(centerX: backView.center.x, centerY: (collectionView.visibleSize.height / 2) - 20, width: 40, height: 40)
        }
        view.addSubview(collectionView)
        collectionView.isHidden = true

        return collectionView
    }()
    
    
    
    func showCamRoll(sender: UIButton?){
        let y = view.frame.midY
        let btnMaxY = bottomBar.frame.maxY
        bottomBar.transform = CGAffineTransform(translationX: 0, y: (y - btnMaxY))
        //self.animateOptionMenuCameraRollButton(didOpen: true)
        cameraRollCollectionView.showCameraRollAnimate(completed: { openedRoll in
            if !openedRoll{
                //self.animateOptionMenuCameraRollButton(didOpen: false)
                self.cameraRollCollectionView.animatehideCameraRoll(viewToCarry: self.bottomBar, backgroundView: self.view, tableView: nil){
                }
            }
        })
    }
    
    
    lazy var bottomBar: UIView = {
        
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 45))
        view.backgroundColor = ColorCompatibility.secondarySystemBackground
        
        let stackView = UIStackView.init(frame: view.frame)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        
        view.addSubview(stackView)
        
        cameraBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: view.frame.height, height: view.frame.height))
        cameraBtn.tintColor = UIColor(named: "LoadingColor")
        cameraBtn.addTarget(self, action: #selector(openCamera(_:)), for: .touchUpInside)
        
        photosBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: view.frame.height, height: view.frame.height))
        photosBtn.tintColor = UIColor(named: "LoadingColor")
        photosBtn.addTarget(self, action: #selector(configurePhotos(_:)), for: .touchUpInside)
        
        drawBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: view.frame.height, height: view.frame.height))
        drawBtn.tintColor = UIColor(named: "LoadingColor")
        drawBtn.addTarget(self, action: #selector(openDrawCanvas(_:)), for: .touchUpInside)
        
        doneBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: view.frame.height, height: view.frame.height))
        doneBtn.setTitle("Done", for: .normal)
        doneBtn.setTitleColor(UIColor(named: "LoadingColor"), for: .normal)
        doneBtn.addTarget(self, action: #selector(minimizeDrawingArea(_:)), for: .touchUpInside)

        
        if #available(iOS 13.0, *) {
            
            let configuration = UIImage.SymbolConfiguration.init(pointSize: 20, weight: UIImage.SymbolWeight.black, scale: UIImage.SymbolScale.large)
            
            cameraBtn.setImage(UIImage(systemName: "camera.fill", withConfiguration: configuration), for: .normal)
            cameraBtn.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)
            
            photosBtn.setImage(UIImage(systemName: "photo.fill", withConfiguration: configuration), for: .normal)
            photosBtn.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)

            drawBtn.setImage(UIImage(systemName: "scribble", withConfiguration: configuration), for: .normal)
            drawBtn.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)

            
        } else {
            // Fallback on earlier versions
            cameraBtn.setImage(UIImage(named: "camera"), for: .normal)
            photosBtn.setImage(UIImage(named: "photos"), for: .normal)
            drawBtn.setImage(UIImage(named: "pencil"), for: .normal)

        }
        
        stackView.addArrangedSubview(cameraBtn)
        stackView.addArrangedSubview(photosBtn)
        stackView.addArrangedSubview(drawBtn)
        stackView.addArrangedSubview(doneBtn)
        
        return view
    }()
    
    
    
    
    @objc func configurePhotos(_ sender: UIButton) {
        if self.cameraRollCollectionView.isHidden{
            sender.tintColor = .cyan
            drawBtn.isSelected = true
            closeDrawCanvas(drawBtn)
            exitTapper.isEnabled = true
            showCamRoll(sender: sender)
            //canvas.gestureRecognizers?.first?.isEnabled = false
        }
        else{
            exitTapper.isEnabled = false
            sender.tintColor = UIColor(named: "LoadingColor")
            cameraRollCollectionView.animatehideCameraRoll(viewToCarry: self.bottomBar, backgroundView: view, tableView: nil){
                //self.canvas.gestureRecognizers?.first?.isEnabled = true
            }
        }
    }
    
    func setCarouselTemplates(){
        
        for (index, tee) in tees.enumerated(){
            guard let teeImage = UIImage(data: tee.templateData) else{continue}
            let slide = TemplateCarouselSlide(image: teeImage, canvasColor: UIColor(named: self.tees[index].templateID)?.withAlphaComponent(0.25))
            carousel.slides.append(slide)
        }
    }
    
    func setCarouselConstraints(){
        NSLayoutConstraint(item: carousel, attribute: .top, relatedBy: .equal, toItem: displayView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: carousel, attribute: .bottom, relatedBy: .equal, toItem: displayView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: carousel, attribute: .left, relatedBy: .equal, toItem: displayView, attribute: .left, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: carousel, attribute: .right, relatedBy: .equal, toItem: displayView, attribute: .right, multiplier: 1.0, constant: 0).isActive = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.setBackgroundImage(UIImage.init(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage.init()
        descriptionView.delegate = self
        descriptionView.inputAccessoryView = toolBar
        titleView.inputAccessoryView = toolBar
        displayView.addSubview(carousel)
        setCarouselConstraints()
        setPlaceholder(textView: descriptionView, textColor: ColorCompatibility.secondaryLabel)
        textViewDidChange(descriptionView)
        setKeyBoardNotifs()
        loadDesigns(){
            self.setCarouselTemplates()
            self.scrollview.addSubview(self.canvasDisplayView)
            self.view.addSubview(self.canvas)
            self.canvas.isHidden = true
            self.view.addSubview(self.bottomBar)
            self.bottomBar.isHidden = true
            self.view.addSubview(self.bottomSafeAreaView)
            self.bottomSafeAreaView.isHidden = true
            self.bottomBar.addSubview(self.drawToolBar)
            self.drawToolBar.isHidden = true
            self.displayView.addSubview(self.zoomBtn)
            self.zoomBtn.frame.origin = CGPoint(x: 5, y: self.displayView.frame.maxY - self.zoomBtn.frame.height - 5)
            self.view.addSubview(self.zoomableView)
            self.zoomableView.isHidden = true
        }
        // Do any additional setup after loading the view.
    }
    
    lazy var zoomableView: UIView = {
        let view = UIView.init(frame: self.view.frame)
        view.backgroundColor = displayView.backgroundColor?.withAlphaComponent(0.95)
        let tapper = UITapGestureRecognizer.init(target: self, action: #selector(hideZoomableView(_:)))
        view.addGestureRecognizer(tapper)
        
        let imageView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.width))
        imageView.center = view.center
        imageView.isUserInteractionEnabled = true
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleZoom(_:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        pan.delegate = self
        pinch.delegate = self
        imageView.addGestureRecognizer(pinch)
        imageView.addGestureRecognizer(pan)
        view.addSubview(imageView)
        let doneZoomingBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 20))
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration.init(pointSize: 18, weight: UIImage.SymbolWeight.black, scale: UIImage.SymbolScale.large)
            doneZoomingBtn.setImage(UIImage(systemName: "xmark"), for: .normal)
            doneZoomingBtn.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)
        } else {
            // Fallback on earlier versions
        }
        doneZoomingBtn.tintColor = UIColor(named: "LoadingColor")
        doneZoomingBtn.frame.origin.y = self.view.safeAreaInsets.top - doneZoomingBtn.frame.height
        doneZoomingBtn.addTarget(self, action: #selector(hideZoomableView(_:)), for: .touchUpInside)
        view.addSubview(doneZoomingBtn)
        return view
    }()
    
    @objc func showZoomableView(_ sender: UIButton){
        
        if let indexPath = carousel.collectionView.indexPathsForVisibleItems.first{
            if let cell = carousel.collectionView.cellForItem(at: indexPath) as? carouselCollectionViewCell{
                zoomableView.isHidden = false
                self.navigationItem.leftBarButtonItem?.isEnabled = false
                self.navigationItem.rightBarButtonItem?.isEnabled = false
                let imageView = zoomableView.subviews.first as? UIImageView
                imageView?.image = nil
                sender.isHidden = true
                if cell.canvasDisplayView.image == nil{
                    cell.canvasDisplayView.isHidden = true
                }
                imageView?.image = sender.superview?.makeSnapshot()
                sender.isHidden = false
                cell.canvasDisplayView.isHidden = false

                zoomableView.alpha = 0.0
                UIView.animate(withDuration: 0.2, animations: {
                    self.zoomableView.alpha = 1.0
                }, completion: { finished in
                    if finished{
                        self.navigationController?.setNavigationBarHidden(true, animated: true)
                    }
                })
            }
        }
    }
    
    @objc func hideZoomableView(_ sender: Any){
        zoomableView.alpha = 1.0
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationItem.leftBarButtonItem?.isEnabled = true
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        UIView.animate(withDuration: 0.2, animations: {
            self.zoomableView.alpha = 0.0
        }, completion: { finished in
            if finished{
                self.zoomableView.isHidden = true
            }
        })
    }
    
    lazy var zoomBtn: UIButton = {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration.init(pointSize: 18, weight: UIImage.SymbolWeight.black, scale: UIImage.SymbolScale.large)
            btn.setImage(UIImage(systemName: "doc.text.magnifyingglass"), for: .normal)
            btn.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)
        } else {
            // Fallback on earlier versions
        }
        btn.tintColor = UIColor(named: "LoadingColor")
        btn.setRadiusWithShadow()
        btn.addTarget(self, action: #selector(showZoomableView(_:)), for: .touchUpInside)
        return btn
    }()
    
    //lazy var designView:
    
    func setKeyBoardNotifs(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func handleZoom(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began, .changed:
                // Only zoom in, not out
                if gesture.scale >= 1 {
                  
                    // Get the scale from the gesture passed in the function
                    let scale = gesture.scale
                  
                    // use CGAffineTransform to transform the imageView
                    gesture.view!.transform = CGAffineTransform(scaleX: scale, y: scale)
                }
              
                // Show the overlay
                break;
            default:
                // If the gesture has cancelled/terminated/failed or everything else that's not performing
                // Smoothly restore the transform to the "original"
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                  gesture.view!.transform = .identity
                }) { _ in
                  // Hide the overlay

                }
            }
        
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            switch gesture.state {
            case .began, .changed:
                // Get the touch position
                let translation = gesture.translation(in: self.displayView)
                    
                // Edit the center of the target by adding the gesture position
                gesture.view?.center = CGPoint(x: gesture.view!.center.x + translation.x, y: gesture.view!.center.y + translation.y)
                gesture.setTranslation(.zero, in: self.zoomableView)
                // Show the overlay

                break;
            default:
                // If the gesture has cancelled/terminated/failed or everything else that's not performing
                // Smoothly restore the transform to the "original"
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                    gesture.view?.center = self.zoomableView.center
                    gesture.setTranslation(.zero, in: self.zoomableView)
                    
                }) { _ in
                  // Hide the overaly

                }
                break
            }
        
    }

}

extension UIView {
    func makeSnapshot() -> UIImage? {
        let color = self.backgroundColor
        self.backgroundColor = .clear
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        let image = renderer.image { ctx in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
        self.backgroundColor = color
        return image
    }
}
