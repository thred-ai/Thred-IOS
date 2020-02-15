//
//  DesignViewController.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-12-25.
//  Copyright © 2019 Thred. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SDWebImage
import ColorCompatibility
import SwiftyDraw
import ColorSlider
import AVKit


class DesignViewController: UIViewController, UITextViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, SwiftyDrawViewDelegate {
    
    var cameraBtn: UIButton!
    var photosBtn: UIButton!
    var textBtn: UIButton!
    var drawBtn: UIButton!
    var doneBtn: UIButton!
    
    
    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var titleView: UITextField!
    @IBOutlet weak var nextBtn: UIBarButtonItem!
    
    var currentItemIndex: Int! = 0
    
    
    var product = ProductInProgress()

    @IBAction func nextPage(_ sender: UIBarButtonItem) {
        
        if let indexPath = carousel.collectionView.indexPathsForVisibleItems.first{
            if let cell = carousel.collectionView.cellForItem(at: indexPath) as? carouselCollectionViewCell{
                if cell.canvasDisplayView.image != nil{
                    zoomBtn.isHidden = true
                    product.designOnShirt = displayView.makeSnapshot()
                    product.design = cell.canvasDisplayView.makeSnapshot()
                    product.caption = descriptionView.text
                    product.uid = userInfo.uid
                    product.name = titleView.text
                    product.templateColor = self.tees[indexPath.item].templateID
                    zoomBtn.isHidden = false
                    self.performSegue(withIdentifier: "nextPage", sender: nil)

                }
            }
        }
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
        done.setImage(UIImage(nameOrSystemName: "checkmark.circle", systemPointSize: 25, iconSize: 9), for: .normal)

        
        undo = UIButton(frame: btnFrame)
        undo.tintColor = UIColor(named: "LoadingColor")
        undo.addTarget(self, action: #selector(undoColors(_:)), for: .touchUpInside)
        undo.setImage(UIImage(nameOrSystemName: "arrow.uturn.left.circle", systemPointSize: 25, iconSize: 9), for: .normal)
        undo.isEnabled = false
        
        brushBtn = UIButton(frame: btnFrame)
        brushBtn.tintColor = UIColor(named: "LoadingColor")
        brushBtn.addTarget(self, action: #selector(switchBrush(_:)), for: .touchUpInside)
        brushBtn.setImage(UIImage(nameOrSystemName: "pencil.circle", systemPointSize: 25, iconSize: 9), for: .normal)
        brushBtn.isEnabled = true
        
        clearBtn = UIButton(frame: btnFrame)
        clearBtn.tintColor = UIColor(named: "LoadingColor")
        clearBtn.addTarget(self, action: #selector(clearCanvas(_:)), for: .touchUpInside)
        clearBtn.setImage(UIImage(nameOrSystemName: "xmark.circle", systemPointSize: 25, iconSize: 9), for: .normal)
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
        
        if drawCanvas.brush.blendMode == .clear{
            brushBtn.setImage(UIImage(nameOrSystemName: "pencil.circle", systemPointSize: 25, iconSize: 9), for: .normal)
            drawCanvas.brush.blendMode = .normal
            drawCanvas.brush.color = Color(slider.color)
        }
        else{
            brushBtn.setImage(UIImage(nameOrSystemName: "pencil.circle.fill", systemPointSize: 25, iconSize: 9), for: .normal)
            drawCanvas.brush.blendMode = .clear
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
        canvas.addSubview(imageView)
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
    
    var viewCenteredY = false
    var viewCenteredX = false

    
    
    
    var angleLocked = false
    

    var prevTransform: CGAffineTransform!

    
    
        
    
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
                        if !(textView.accessibilityIdentifier?.isEmpty ?? false){
                            textView.text = textView.accessibilityIdentifier
                        }
                        self.textStyleBtn.superview?.isHidden = false
                        self.fontSlider.isHidden = false
                        self.textCoverView.isHidden = false

                        UIView.animate(withDuration: 0.15, animations: {
                            textView.transform = CGAffineTransform.identity
                        }, completion: { finished in
                            if finished{
                                self.textViewDidChange(textView)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                    self.textDoneBtn.isEnabled = true
                                }
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
    
    var textDoneBtn: UIButton!
    
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
        
        textDoneBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 90, height: 45))
        textDoneBtn.setTitle("Done", for: .normal)
        textDoneBtn.setTitleColor(UIColor(named: "LoadingColor"), for: .normal)
        textDoneBtn.addTarget(self, action: #selector(doneLabelTyping(_:)), for: .touchUpInside)
        
        shadowBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
        shadowBtn.setImage(UIImage(nameOrSystemName: "rectangle.on.rectangle", systemPointSize: 22, iconSize: 7), for: .normal)

        shadowBtn.tintColor = UIColor(named: "LoadingColor")
        shadowBtn.addTarget(self, action: #selector(configureTextShadow(_:)), for: .touchUpInside)
        
        stack.addArrangedSubview(shadowBtn)
        stack.addArrangedSubview(textSlider)
        stack.addArrangedSubview(textDoneBtn)
        
        view.addSubview(stack)
        
        return view
    }()
    
    
    
    
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
    
    
    var keyboardHeight: CGFloat!
    
    func textViewDidChange(_ textView: UITextView) {
        if textView == descriptionView{
            placeholderLabel.isHidden = !textView.text.isEmpty
        }
        else{
            let size = textView.sizeThatFits(CGSize(width: canvas.frame.width, height: CGFloat.greatestFiniteMagnitude))
            textView.center.x = canvas.center.x
            if keyboardHeight != nil{
                textView.accessibilityIdentifier = textView.text
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
        view.isUserInteractionEnabled = true
        view.isHidden = true
        return view
    }()
    
    var textCoverView: UIView!
    var defaultFontSize = 55
        
    
    
    var exitTapper: UITapGestureRecognizer!
    
    var midXLine: UIView!
    var midYLine: UIView!
    var angleLine: UIView!
    
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
        drawCanvas.addSubview(brushCircle)
        brushCircle.isHidden = true
        let gesture = UIPinchGestureRecognizer(target: self, action: #selector(changeBrushSize(_:)))
        drawCanvas.addGestureRecognizer(gesture)
        let lineWidth: CGFloat = 1
        midXLine = UIView.init(frame: CGRect(x: 0, y: 0, width: lineWidth, height: view.frame.height))
        midXLine.center.x = view.center.x
        midXLine.backgroundColor = .systemYellow
        midXLine.setRadiusWithShadow()
        midXLine.isHidden = true
        midYLine = UIView.init(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: lineWidth))
        midYLine.center.y = view.center.y
        midYLine.backgroundColor = .systemYellow
        midYLine.setRadiusWithShadow()
        midYLine.isHidden = true
        angleLine = UIView.init(frame: CGRect(x: 0, y: 0, width: lineWidth, height: view.frame.height * 2))
        angleLine.backgroundColor = .systemRed
        angleLine.setRadiusWithShadow()
        angleLine.isHidden = true
        garbageBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        garbageBtn.center.x = view.center.x
        garbageBtn.center.y = (view.frame.maxY) - (garbageBtn.frame.height / 2) - 10
        garbageBtn.setRadiusWithShadow()
        garbageBtn.tintColor = UIColor(named: "LoadingColor")
        garbageBtn.isUserInteractionEnabled = false
        
        garbageBtn.setImage(UIImage(nameOrSystemName: "trash.circle", systemPointSize: 30, iconSize: 7), for: .normal)
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
        view.addSubview(midXLine)
        view.addSubview(midYLine)
        view.addSubview(angleLine)
        view.addSubview(drawCanvas)
        return view
    }()
    
    lazy var brushCircle: UIView = {
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: drawCanvas.brush.originalWidth, height: drawCanvas.brush.originalWidth))
        view.backgroundColor = .white
        view.layer.cornerRadius = view.frame.height / 2
        view.clipsToBounds = true
        view.layer.borderColor = ColorCompatibility.systemFill.cgColor
        view.layer.borderWidth = 1.5
        view.setRadiusWithShadow()

        return view
    }()
    
    
    
    
    
    var fontSlider: UISlider!
    
    
    
    var currentLabelStyle: LabelStyle!
    
    public enum LabelStyle {
        case large
        case normal
        case nexa
        case fancy
        case fill
        case hype
    }
    
    var currentFontSize: CGFloat!
     
    var selectedView: UIImageView!
    
    lazy var bottomSafeAreaView: UIView = {
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: bottomBar.frame.width, height: 0))
        view.backgroundColor = bottomBar.backgroundColor
        return view
    }()
    
    
    
    
    
    
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
        
        textBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: view.frame.height, height: view.frame.height))
        textBtn.tintColor = UIColor(named: "LoadingColor")
        textBtn.addTarget(self, action: #selector(addLabel(_:)), for: .touchUpInside)
        
        
        drawBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: view.frame.height, height: view.frame.height))
        drawBtn.tintColor = UIColor(named: "LoadingColor")
        drawBtn.addTarget(self, action: #selector(openDrawCanvas(_:)), for: .touchUpInside)
        
        doneBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: view.frame.height, height: view.frame.height))
        doneBtn.setTitle("Done", for: .normal)
        doneBtn.setTitleColor(UIColor(named: "LoadingColor"), for: .normal)
        doneBtn.addTarget(self, action: #selector(minimizeDrawingArea(_:)), for: .touchUpInside)
        

        cameraBtn.setImage(UIImage(nameOrSystemName: "camera.fill", systemPointSize: 20, iconSize: 9), for: .normal)
        photosBtn.setImage(UIImage(nameOrSystemName: "photo.fill", systemPointSize: 20, iconSize: 9), for: .normal)
        textBtn.setImage(UIImage(nameOrSystemName: "textbox", systemPointSize: 20, iconSize: 9), for: .normal)
        drawBtn.setImage(UIImage(nameOrSystemName: "scribble", systemPointSize: 20, iconSize: 9), for: .normal)
        
        stackView.addArrangedSubview(cameraBtn)
        stackView.addArrangedSubview(photosBtn)
        stackView.addArrangedSubview(textBtn)
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
    
    
    
    func setCarouselConstraints(){
        NSLayoutConstraint(item: carousel, attribute: .top, relatedBy: .equal, toItem: displayView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: carousel, attribute: .bottom, relatedBy: .equal, toItem: displayView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: carousel, attribute: .left, relatedBy: .equal, toItem: displayView, attribute: .left, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: carousel, attribute: .right, relatedBy: .equal, toItem: displayView, attribute: .right, multiplier: 1.0, constant: 0).isActive = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollview.alwaysBounceVertical = false
        navigationController?.navigationBar.setBackgroundImage(UIImage.init(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage.init()
        descriptionView.delegate = self
        descriptionView.inputAccessoryView = toolBar
        titleView.inputAccessoryView = toolBar
        displayView.addSubview(carousel)
        setCarouselConstraints()
        setPlaceholder(textView: descriptionView, textColor: ColorCompatibility.tertiaryLabel)
        textViewDidChange(descriptionView)
        setKeyBoardNotifs()
        loadDesigns(){
            self.carousel.setCarouselTemplates(templates: self.tees)
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
            self.nextBtn.isEnabled = false
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
        doneZoomingBtn.setImage(UIImage(nameOrSystemName: "xmark", systemPointSize: 18, iconSize: 9), for: .normal)
        doneZoomingBtn.tintColor = UIColor(named: "LoadingColor")
        doneZoomingBtn.frame.origin.y = self.view.safeAreaInsets.top - doneZoomingBtn.frame.height
        doneZoomingBtn.addTarget(self, action: #selector(hideZoomableView(_:)), for: .touchUpInside)
        view.addSubview(doneZoomingBtn)
        return view
    }()
    
    
    lazy var zoomBtn: UIButton = {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
        btn.setImage(UIImage(nameOrSystemName: "doc.text.magnifyingglass", systemPointSize: 18, iconSize: 9), for: .normal)
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

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nextVC = segue.destination as? OtherProductInfoViewController{
            nextVC.product = product
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

extension UIImage {
/// Returns a system image on iOS 13, otherwise returns an image from the Bundle provided.
    convenience init?(nameOrSystemName: String, systemPointSize: CGFloat?, iconSize: Int?, in bundle: Bundle? = Bundle.main, compatibleWith traitCollection: UITraitCollection? = nil) {
if #available(iOS 13, *) {
    self.init(systemName: nameOrSystemName, withConfiguration: UIImage.SymbolConfiguration.init(pointSize: systemPointSize ?? 20, weight: UIImage.SymbolWeight(rawValue: iconSize ?? 9) ?? UIImage.SymbolWeight.black, scale: UIImage.SymbolScale.large))
        } else {
self.init(named: nameOrSystemName, in: bundle, compatibleWith: traitCollection)
        }
    }
}


