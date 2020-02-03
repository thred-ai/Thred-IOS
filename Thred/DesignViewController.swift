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
    
    
    
    @IBAction func nextItemColor(_ sender: UISwipeGestureRecognizer) {
        
        if sender.direction == .left{
            
            if self.currentItemIndex != tees.count - 1{
                self.currentItemIndex += 1
                self.displayImage.image = UIImage(data: self.tees[currentItemIndex].templateData)
                self.canvasDisplayView.backgroundColor = UIColor(named: self.tees[currentItemIndex].templateID)?.withAlphaComponent(0.25)
            }
        }
    }
    
    @IBAction func prevItemColor(_ sender: UISwipeGestureRecognizer) {
        
        if sender.direction == .right{
            
            if self.currentItemIndex != 0{
                self.currentItemIndex -= 1
                self.displayImage.image = UIImage(data: self.tees[currentItemIndex].templateData)
                 self.canvasDisplayView.backgroundColor = UIColor(named: self.tees[currentItemIndex].templateID)?.withAlphaComponent(0.25)
            }
        }
    }
    
    @objc func closeCamera(_ sender: UIButton?){
        self.titleView.isHidden = false
        self.bottomBar.isHidden = false
        canvas.gestureRecognizers?.first?.isEnabled = true
        self.cameraView.hideCameraAnimate(viewToCarry: self.bottomBar) {
            self.cameraView.resetDisplayImage()
        }
    }
    
    lazy var drawToolBar: UIStackView = {
        
        let stack = UIStackView(frame: CGRect(x: 20, y: 10, width: self.view.frame.width - 40, height: 35))
        
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.backgroundColor =
            ColorCompatibility.systemBackground
        stack.spacing = 20
        
        slider = ColorSlider(orientation: .horizontal, previewSide: .top)
        slider.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        slider.color = .cyan
        
        let btnFrame = CGRect(x: 0, y: 0, width: stack.frame.height, height: stack.frame.height)
        
        done = UIButton(frame: btnFrame)
        done.setTitle("Done", for: .normal)
        done.setTitleColor(UIColor(named: "LoadingColor"), for: .normal)
        done.addTarget(self, action: #selector(closeDrawCanvas(_:)), for: .touchUpInside)
        
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
            brushBtn.setImage(UIImage(systemName: "pencil.slash"), for: .normal)
        } else {
            // Fallback on earlier versions
        }
        brushBtn.tintColor = UIColor(named: "LoadingColor")
        brushBtn.addTarget(self, action: #selector(switchBrush(_:)), for: .touchUpInside)
        brushBtn.isEnabled = true

        stack.addArrangedSubview(brushBtn)
        stack.addArrangedSubview(slider)
        stack.addArrangedSubview(undo)
        stack.addArrangedSubview(done)
        
        return stack
    }()
    
    var undo: UIButton!
    var brushBtn: UIButton!
    var done: UIButton!
    var slider: ColorSlider!
    var garbageBtn: UIButton!
    
    @objc func colorChanged(_ sender: ColorSlider){
        drawCanvas.brush.color = Color(sender.color)
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
                brushBtn.setImage(UIImage(systemName: "pencil.slash"), for: .normal)
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
        
        makeMovable(view: imageView)
        
        canvas.insertSubview(imageView, belowSubview: drawCanvas)
    }
    
    func makeMovable(view: UIView){
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleImgPan(_:)))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleImgPinch(_:)))
        let rotate = UIRotationGestureRecognizer(target: self, action: #selector(handleImgRotation(_:)))

        pan.delegate = self
        pinch.delegate = self
        rotate.delegate = self

        view.addGestureRecognizer(pan)
        view.addGestureRecognizer(pinch)
        view.addGestureRecognizer(rotate)

        view.isUserInteractionEnabled = true
        view.clipsToBounds = true
    }
    
    func checkLabelMoving(label: UITextView?){
        self.editingTransform = label?.transform
        self.editingCenter = label?.center
        
        if label?.isFirstResponder ?? false{
            for otherLabel in canvas.subviews.filter({$0.isKind(of: UITextView.self)}){
                otherLabel.isUserInteractionEnabled = true
            }
            if label?.text.isEmpty ?? false{
                label?.removeFromSuperview()
            }
            label?.resignFirstResponder()
        }
    }
    
    @objc func handleImgPan(_ sender: UIPanGestureRecognizer){
        
        switch sender.state {
        case .began, .changed:
            canvas.gestureRecognizers?.first?.isEnabled = false

            let viewDrag = sender.view!
            canvas.bringSubviewToFront(viewDrag)
            if viewDrag is UIImageView{
                canvas.bringSubviewToFront(drawCanvas)
            }
            canvas.bringSubviewToFront(bottomBar)
            let translation = sender.translation(in: view)
            viewDrag.center = CGPoint(x: viewDrag.center.x + translation.x, y: viewDrag.center.y + translation.y)
            sender.setTranslation(CGPoint.zero, in: view)
            checkLabelMoving(label: sender.view as? UITextView)
            checkInGarbage(sender: sender, completed: {inGarbage in
                if !inGarbage{
                    self.canvas.bringSubviewToFront(self.garbageBtn)
                }
            })
            showGarbageBtn()
        default:
            canvas.gestureRecognizers?.first?.isEnabled = true
            checkInGarbage(sender: sender, completed: { inGarbage in
                if inGarbage{
                    sender.view?.removeFromSuperview()
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
    
    @objc func handleImgPinch(_ sender: UIPinchGestureRecognizer){
        switch sender.state {
        case .began, .changed:
            canvas.gestureRecognizers?.first?.isEnabled = false
            canvas.bringSubviewToFront(sender.view!)
            if sender.view! is UIImageView{
                canvas.bringSubviewToFront(drawCanvas)
            }
            canvas.bringSubviewToFront(bottomBar)
            let scale = sender.scale
            sender.view!.transform = sender.view!.transform.scaledBy(x: scale, y: scale)
            sender.scale = 1
            checkLabelMoving(label: sender.view as? UITextView)
            break
        default:
            canvas.gestureRecognizers?.first?.isEnabled = true
            break
        }
    }
    
    @objc func handleImgRotation(_ sender: UIRotationGestureRecognizer){
        
        switch sender.state{
        case .began, .changed:
            canvas.gestureRecognizers?.first?.isEnabled = false
            canvas.bringSubviewToFront(sender.view!)
            if sender.view! is UIImageView{
                canvas.bringSubviewToFront(drawCanvas)
            }
            canvas.bringSubviewToFront(bottomBar)
            sender.view!.transform = sender.view!.transform.rotated(by: sender.rotation)
            sender.rotation = 0
            checkLabelMoving(label: sender.view as? UITextView)
            break
        default:
            canvas.gestureRecognizers?.first?.isEnabled = true
            break
        }
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
    
    func minimizeGarbage(view: UIView, completed: @escaping () ->()){
        UIView.animate(withDuration: 0.2, animations: {
            if self.garbageBtn.transform == CGAffineTransform(scaleX: 1.2, y: 1.2){
                view.transform = self.prevTransform
                view.alpha = 1.0
                self.canvas.bringSubviewToFront(view)

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
        let stackView = UIStackView(frame: bar.frame)
        bar.addSubview(stackView)
        
        
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
    
        button.setTitle("Done", for: .normal)
        button.addTarget(self, action: #selector(doneEditing(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(button)
       
        return bar
    }()
    
    @objc func doneEditing(_ sender: UIButton){
        descriptionView.resignFirstResponder()
    }
    
    
    @IBOutlet weak var descriptionView: UITextView!
    
    @objc func keyboardWillShow(_ notification: Notification) {

        let bottomPadding = view.safeAreaInsets.bottom

            if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                if (notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool ?? true){
                    let keyboardcanvasDisplayView = keyboardFrame.cgRectValue
                    let keyboardHeight = keyboardcanvasDisplayView.height
                    UIView.animate(withDuration: 0.2, animations: {
                        //self.bottomBar.transform = CGAffineTransform(translationX: 0, y: -(keyboardHeight - bottomPadding))
                        
                        if self.scrollview.contentInset.bottom == 0{
                            self.scrollview.contentOffset.y -= keyboardHeight - bottomPadding
                        }
                        self.scrollview.contentInset.bottom = keyboardHeight - bottomPadding
                        self.scrollview.verticalScrollIndicatorInsets.bottom = keyboardHeight - bottomPadding
                        
                    }, completion: { finished in
                        if finished{}
                    })
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
        
        
        placeholderLabel.text = "Add a description..."
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
    
    var editingTransform: CGAffineTransform!
    var editingCenter: CGPoint!
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == descriptionView{
            
        }
        else{
            
            UIView.animate(withDuration: 0.2, animations: {
                textView.transform = CGAffineTransform.identity
                textView.center.x = self.canvas.center.x
                textView.center.y = self.canvas.center.y - 200

            })
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView == descriptionView{
                
            }
            else{
                self.editingTransform = textView.transform
                self.editingCenter = textView.center
                
                UIView.animate(withDuration: 0.2, animations: {
                    textView.transform = self.editingTransform
                    textView.center = self.editingCenter
                })
            }
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView == descriptionView{
            placeholderLabel.isHidden = !textView.text.isEmpty
        }
        else{
            textView.frame.size = textView.sizeThatFits(CGSize(width: canvas.frame.width, height: CGFloat.greatestFiniteMagnitude))
            textView.center.x = canvas.center.x

        }
    }
    
    var hoodies = [Data]()
    var tees = [Template]()
    
    func loadDesigns(completed: @escaping ()->()){
        
        tees.checkAndLoadTemplates(type: "TeeTemplates", with: {_ in
            
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
        })
    }
    
    
    
    @IBOutlet weak var displayImage: UIImageView!
    
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
    
    
    
    lazy var canvasDisplayView: UIImageView = {
        
        let stack = displayImage.superview as! UIStackView
        let x = displayImage.frame.width / 3
        let y = stack.spacing + titleView.frame.height + displayImage.frame.height / 4
        let width = displayImage.frame.width / 4
        
        let height = (displayImage.frame.height - displayImage.frame.height / 2) - 50
        self.aspectRatio = width / height
        let view = UIImageView(frame: CGRect(x: x, y: y, width: width, height: height))
        view.center.x = displayImage.center.x
        view.layer.borderColor = UIColor.gray.cgColor
        view.layer.borderWidth = 1
        view.isUserInteractionEnabled = true
        view.backgroundColor = UIColor(named: tees[currentItemIndex].templateID)?.withAlphaComponent(0.25)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(zoomDrawingArea(_:)))
        view.addGestureRecognizer(tapGesture)

        return view
    }()
    
    lazy var canvas: UIView = {
        
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height * aspectRatio))
        view.isUserInteractionEnabled = true
        view.backgroundColor = UIColor(named: tees[currentItemIndex].templateID)
        view.clipsToBounds = true
        
        let tapper = UITapGestureRecognizer(target: self, action: #selector(addLabel(_:)))
        view.addGestureRecognizer(tapper)

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
        garbageBtn.isHidden = true
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration.init(pointSize: 30, weight: UIImage.SymbolWeight.bold, scale: UIImage.SymbolScale.large)
            garbageBtn.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)
            garbageBtn.setImage(UIImage(systemName: "trash.circle"), for: .normal)
        } else {
            // Fallback on earlier versions
        }
        view.addSubview(garbageBtn)

        view.addSubview(drawCanvas)
        
        
        return view
    }()
    
    @objc func addLabel(_ sender: UITapGestureRecognizer){
        
        if !canvas.subviews.contains(where: {($0.isKind(of: UITextView.self) && $0.isFirstResponder)}){
            for otherLabel in canvas.subviews.filter({$0.isKind(of: UITextView.self)}){
                otherLabel.isUserInteractionEnabled = false
            }
            let label = UITextView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 200))
            label.center = canvas.center
            label.center.y = canvas.center.y - 200
            label.textAlignment = .center
            
            label.backgroundColor = .clear
            label.textColor = .white
            label.delegate = self
            label.setRadiusWithShadow()
            label.font = UIFont.systemFont(ofSize: 55)
            label.isScrollEnabled = false
            label.becomeFirstResponder()
            makeMovable(view: label)
            canvas.addSubview(label)
        }
    }

    
    
    func swiftyDraw(shouldBeginDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) -> Bool {
        if (!drawingView.isHidden && !drawingView.isEnabled) || (drawingView.brush == .eraser && drawingView.lines.isEmpty){
            return false
        }
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
        if canvas.subviews.contains(where: {$0.isKind(of: UIImageView.self) || ($0.isKind(of: UITextView.self))}) || drawCanvas.lines.contains(where: {$0.brush != .eraser}){
            canvasDisplayView.image = canvas.makeSnapshot()
            nextBtn.isEnabled = true
        }
        if !cameraRollCollectionView.isHidden{
            configurePhotos(photosBtn)
        }
        let stack = displayImage.superview as! UIStackView
        let x = displayImage.frame.width / 3
        let y = stack.spacing + titleView.frame.height + displayImage.frame.height / 4
        let width = displayImage.frame.width / 4
        let height = (displayImage.frame.height - displayImage.frame.height / 2) - 50
        
        DispatchQueue.main.async {
            self.displayImage.image = UIImage(data: self.tees[self.currentItemIndex].templateData)
            self.titleView.isUserInteractionEnabled = true
            self.bottomBar.isHidden = true
            self.descriptionView.isHidden = false
            self.drawCanvas.isEnabled = false
            self.drawBtn.isSelected = false
            self.drawBtn.tintColor = UIColor(named: "LoadingColor")


            //check if empty
            if self.canvasDisplayView.image == nil{
                self.canvasDisplayView.layer.borderWidth = 1
            }
            else{
                self.canvasDisplayView.layer.borderWidth = 0
            }
            
            self.drawCanvas.isHidden = true
            self.canvas.isHidden = true
            
            UIView.animate(withDuration: 0.2, animations: {
                self.descriptionView.alpha = 1.0
                self.canvasDisplayView.frame = CGRect(x: x, y: y, width: width, height: height)
                self.canvasDisplayView.center.x = self.displayImage.center.x

            }, completion: { finished in
                if finished{
                    UIView.animate(withDuration: 0.1, animations: {
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
    
    @objc func zoomDrawingArea(_ sender: UITapGestureRecognizer){
        
        self.nextBtn.isEnabled = false
        let width = view.frame.width
        let height = view.frame.height * aspectRatio
        self.titleView.isUserInteractionEnabled = false
        
        DispatchQueue.main.async {
            self.scrollview.setContentOffset(.zero, animated: true)
            self.canvas.backgroundColor = UIColor(named: self.tees[self.currentItemIndex].templateID)
            self.canvasDisplayView.backgroundColor = UIColor(named: self.tees[self.currentItemIndex].templateID)

            self.bottomBar.isHidden = false
            //self.bottomBar
            let y = self.displayImage.frame.origin.y
            self.bottomBar.frame.origin.y = y + height + self.view.safeAreaInsets.top

            UIView.animate(withDuration: 0.2, animations: {
                self.descriptionView.alpha = 0.0
                self.canvasDisplayView.frame = CGRect(x: 0, y: y, width: width, height: height)
                self.canvasDisplayView.center.x = self.view.center.x
                self.canvas.frame = CGRect(x: 0, y: y + self.view.safeAreaInsets.top, width: width, height: height)
                self.canvas.center.x = self.view.center.x
                
            }, completion: { finished in
                if finished{
                    self.displayImage.image = nil
                    self.descriptionView.isHidden = true
                    self.canvas.isHidden = false
                    self.drawCanvas.isHidden = false
                    
                }
            })
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
        view.backgroundColor = ColorCompatibility.systemBackground
        
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
        doneBtn.setTitle("Save", for: .normal)
        doneBtn.setTitleColor(UIColor(named: "LoadingColor"), for: .normal)
        doneBtn.addTarget(self, action: #selector(minimizeDrawingArea(_:)), for: .touchUpInside)

        
        if #available(iOS 13.0, *) {
            
            let configuration = UIImage.SymbolConfiguration.init(pointSize: 20, weight: UIImage.SymbolWeight.black, scale: UIImage.SymbolScale.large)
            
            cameraBtn.setImage(UIImage(systemName: "camera.fill", withConfiguration: configuration), for: .normal)
            cameraBtn.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)
            
            photosBtn.setImage(UIImage(systemName: "photo.fill", withConfiguration: configuration), for: .normal)
            photosBtn.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)

            drawBtn.setImage(UIImage(systemName: "pencil.tip.crop.circle", withConfiguration: configuration), for: .normal)
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
            showCamRoll(sender: sender)
            canvas.gestureRecognizers?.first?.isEnabled = false
        }
        else{
            //self.animateOptionMenuCameraRollButton(didOpen: false)
            sender.tintColor = UIColor(named: "LoadingColor")
            cameraRollCollectionView.animatehideCameraRoll(viewToCarry: self.bottomBar, backgroundView: view, tableView: nil){
                self.canvas.gestureRecognizers?.first?.isEnabled = true
            }
        }
    }
    
    func setToolBar(){
        
        if #available(iOS 13.0, *) {
            cameraBtn.setImage(UIImage(systemName: "camera.fill"), for: .normal)
            photosBtn.setImage(UIImage(systemName: "photo.fill"), for: .normal)
            drawBtn.setImage(UIImage(systemName: "pencil.tip.crop.circle"), for: .normal)

        } else {
            // Fallback on earlier versions
            cameraBtn.setImage(UIImage(named: "camera"), for: .normal)
            photosBtn.setImage(UIImage(named: "photos"), for: .normal)
            drawBtn.setImage(UIImage(named: "pencil"), for: .normal)
        }
    }
    
    func setNextBtn(){
        if #available(iOS 13.0, *) {
            nextBtn.image = UIImage(systemName: "chevron.right.2")
        } else {
            // Fallback on earlier versions
            nextBtn.image = UIImage(named: "chevron_right_2")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        descriptionView.delegate = self
        descriptionView.inputAccessoryView = toolBar
        descriptionView.text.removeAll()
        setPlaceholder(textView: descriptionView, textColor: ColorCompatibility.secondaryLabel)
        textViewDidChange(descriptionView)
        bottomBar.isHidden = true
        setToolBar()
        setKeyBoardNotifs()
        setNextBtn()
        loadDesigns(){
            self.displayImage.image = UIImage(data: self.tees.first!.templateData)
            self.currentItemIndex = 0
            self.scrollview.addSubview(self.canvasDisplayView)
            self.view.addSubview(self.canvas)
            self.canvas.isHidden = true
            self.view.addSubview(self.bottomBar)
            self.bottomBar.isHidden = true
            self.bottomBar.addSubview(self.drawToolBar)
            self.drawToolBar.isHidden = true
        }
        // Do any additional setup after loading the view.
    }
    
    //lazy var designView:
    
    func setKeyBoardNotifs(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }


}

extension UIView {
    func makeSnapshot() -> UIImage? {
        self.backgroundColor = .clear
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        let image = renderer.image { ctx in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
        return image
    }
}
