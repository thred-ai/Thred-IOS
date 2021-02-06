//
//  DesignInfoViewController.swift
//  Thred
//
//  Created by Arta Koroushnia on 2021-01-26.
//  Copyright © 2021 Thred. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SDWebImage
import ColorCompatibility
import SwiftyDraw
import ColorSlider
import AVKit
import PopupDialog

class DesignInfoViewController: UIViewController, UITextViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate {

    @IBOutlet weak var designImg: UIImageView!
    @IBOutlet weak var titleView: UITextField!
    @IBOutlet weak var priceView: UITextField!
    @IBOutlet weak var publicLbl: UILabel!
    @IBOutlet weak var scrollview: UIScrollView!

    var product: ProductInProgress!
    var isEditingProduct = false
    var deletingPost = false
    var isPublic = true
    @IBOutlet weak var deletePostBtn: UIButton!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var thredWatermark: UIStackView!
    @IBOutlet weak var saveBtn: UIButton!

    @IBOutlet weak var saveToPhotosLbl: UIView!
    
    
    
    @IBAction func changeVisibility(_ sender: UIButton) {
        if isPublic{
            showVisibilityMessage(makePublic: false, completed: {
                self.publicLbl.text = "Only me"
                self.isPublic = false
            })
        }
        else{
            showVisibilityMessage(makePublic: true, completed: {
                self.publicLbl.text = "Everyone"
                self.isPublic = true
            })
        }
        if !cannotPost(){
            showNextBtn()
        }
        else{
            hideNextBtn()
        }
    }
    
    func cannotPost() -> Bool{
        return titleView.text?.replacingOccurrences(of: " ", with: "").isEmpty ?? true || priceView.text?.isEmpty ?? true
    }
    
    func showVisibilityMessage(makePublic: Bool, completed: @escaping () -> ()){
        var postStatus = "private"
        var message = "Only you will be able to view/buy this post"
        if makePublic{
            postStatus = "public"
            message = "Anyone on Thred will be able to view/buy this post"
        }
        let title = "Are you sure you want to make your product \(postStatus)?"

        let yesBtn = DefaultButton(title: "YES", dismissOnTap: true) {
            completed()
        }
        let cancelBtn = DefaultButton(title: "NEVER MIND", dismissOnTap: true) {
        }
        
        showPopUp(title: title, message: message, image: nil, buttons: [yesBtn, cancelBtn], titleColor: .label, blurBack: true)
    }
    
    @IBAction func deletePost(_ sender: UIButton) {
        deletingPost = true
        performSegue(withIdentifier: "DoneDesigning", sender: nil)
    }
    
    @IBAction func doneDesigning(_ sender: UIButton) {
        
        sender.isEnabled = false
        
        guard checkInternetConnection() else{
            sender.isEnabled = true
            return
        }
        let canPost = canPostDesign()
        if canPost.0{
            if isEditingProduct{
                product.caption = descriptionView.text?.prepared()
                product.uid = pUserInfo.uid
                product.name = titleView.text?.prepared()
                product.isPublic = isPublic
                guard let price = priceView.text else{
                    sender.isEnabled = true
                    return
                }
                guard let decimalPrice = Double(price) else{
                    sender.isEnabled = true
                    return
                }
                product.price = decimalPrice * 100
                performSegue(withIdentifier: "DoneDesigning", sender: nil)
            }
            else{
                guard let price = priceView.text else{
                    sender.isEnabled = true
                    return
                }
                guard let decimalPrice = Double(price) else{
                    sender.isEnabled = true
                    return
                }
                                
                product.caption = descriptionView.text?.prepared()
                product.uid = pUserInfo.uid
                product.name = titleView.text?.prepared()
                product.isPublic = isPublic
                
                product.price = decimalPrice * 100
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.performSegue(withIdentifier: "DoneDesigning", sender: nil)
                }
                            
                
            }
        }
        else{
            if canPost.1 == "title"{
                //throw title empty error
            }
            else if canPost.1 == "price"{
                //throw price empty error
            }
        }
 
    }
    
    var topCanvasConstraints = [NSLayoutConstraint]()
    var canvasDisplayViews = [CanvasDisplayView]()

    
    func addConstraints(template: Template!){
        
        switch topCanvasConstraints.isEmpty{
        case false:
            for constraint in topCanvasConstraints{
                constraint.isActive = false
            }
            topCanvasConstraints.removeAll()
        case true:
            break
        }
        
        for canvas in canvasDisplayViews{
            canvas.removeFromSuperview()
        }
        canvasDisplayViews.removeAll()
        let sameProduct = all.tees.first(where: {$0.productCode == product.productType})
        if let sideString = product?.displaySide.capitalizingFirstLetter(), let side = sameProduct?.supportedSides.first(where: {$0.name == sideString}) ?? sameProduct?.supportedSides.first(where: {$0.name == "Front"}){
            guard let name = side.name, let canvas = designImg.canvasDisplayView(for: name) else{return}

            designImg.addSubview(canvas)
            canvasDisplayViews.append(canvas)
            setConstraints(side: side, canvasDisplayView: canvas)
        }
    }
    
    func setConstraints(side: TemplateSide, canvasDisplayView: UIButton){
        
        switch topCanvasConstraints.isEmpty{
        case false:
            fallthrough
        default:
            guard self.designImg.subviews.contains(canvasDisplayView) else{return}

            let centerX = NSLayoutConstraint(item: canvasDisplayView, attribute: .centerX, relatedBy: .equal, toItem: designImg, attribute: .centerX, multiplier: 1.0, constant: 0)
            let centerY = NSLayoutConstraint(item: canvasDisplayView, attribute: .centerY, relatedBy: .equal, toItem: designImg, attribute: .centerY, multiplier: 1.0, constant: CGFloat(side.centerYConst ?? 0))
            
            let width = NSLayoutConstraint(item: canvasDisplayView, attribute: .width, relatedBy: .equal, toItem: designImg, attribute: .width, multiplier: CGFloat(side.widthMultiplier ?? 0), constant: 0)
            
            let height = NSLayoutConstraint(item: canvasDisplayView, attribute: .height, relatedBy: .equal, toItem: canvasDisplayView, attribute: .width, multiplier: side.regularAspectRatio, constant: 0)
            
            topCanvasConstraints.append(centerX)
            topCanvasConstraints.append(centerY)
            topCanvasConstraints.append(width)
            topCanvasConstraints.append(height)
            
            for constraint in topCanvasConstraints{
                constraint.isActive = true
            }
        }
    }
    
    lazy var toolBar: UIView = {
        let bar = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 45))
        bar.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        let stackView = UIStackView(frame: bar.frame)
        bar.addSubview(stackView)
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
        button.setTitle("Done", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.addTarget(self, action: #selector(doneEditing(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(button)
        
        return bar
    }()
    
    @objc func doneEditing(_ sender: UIButton){
        descriptionView.resignFirstResponder()
        titleView.resignFirstResponder()
        priceView.resignFirstResponder()
    }
    
    @IBOutlet weak var descriptionView: UITextView!
    
    func canPostDesign() -> (Bool, String?){
        
        if titleView.text?.isEmpty ?? false{
            return (false, "title")
        }
        else if priceView.text?.isEmpty ?? false{
            return (false, "price")
        }
        else{
            return (true, nil)
        }

    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        
        if (notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool ?? true){
            descriptionView.scrollRangeToVisible(NSRange(location: 0, length: 0))
            UIView.animate(withDuration: 0.2, animations: {
                self.scrollview.contentInset.bottom = 0
                self.scrollview.verticalScrollIndicatorInsets.bottom = 0
            })
        }
    }
    
    var placeholderLabel = UILabel()

    func setPlaceholder(textView: UITextView, textColor: UIColor?){
        
        
        placeholderLabel.text = "Describe this design..."
        placeholderLabel.font = UIFont(name: "NexaW01-Regular", size: 16)
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
    
    func textViewDidChange(_ textView: UITextView) {
        
        if textView == descriptionView{
            placeholderLabel.isHidden = !textView.text.isEmpty
            if isEditingProduct, textView.text != product.caption{
                showNextBtn()
            }
        }
    }
    
    func setKeyBoardNotifs(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    var keyboardHeight: CGFloat!

    
    @objc func keyboardWillShow(_ notification: Notification) {

        let bottomPadding = view.safeAreaInsets.bottom
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            if (notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool ?? true){
                let keyboardFrame = keyboardFrame.cgRectValue
                keyboardHeight = keyboardFrame.height
                
                UIView.animate(withDuration: 0.2, animations: {
                    if self.scrollview.contentInset.bottom == 0{
                        self.scrollview.contentOffset.y -= self.keyboardHeight - bottomPadding
                    }
                    self.scrollview.contentInset.bottom = self.keyboardHeight - bottomPadding
                    self.scrollview.verticalScrollIndicatorInsets.bottom = self.keyboardHeight - bottomPadding
                }, completion: { finished in
                    if finished{}
                })
            }
        }
    }
    
   
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setKeyBoardNotifs()
    }
    
    @objc func showSaveView(_ sender: UIButton?){
        saveToPhotosLbl.superview?.bringSubviewToFront(saveToPhotosLbl)
        saveToPhotosLbl.isHidden = false
    }
    
    @objc func hideSaveView(_ sender: UIButton?){
        saveToPhotosLbl.isHidden = true
    }
    
    @IBAction func saveToCameraRoll(_ sender: UIButton){
        
        
        
        if let thredLabel = self.thredWatermark.arrangedSubviews.first(where: {$0.isKind(of: UILabel.self)}) as? UILabel{
            hideSaveView(nil)
            thredLabel.text = "thred"
            saveBtn.isEnabled = false
            UIView.animate(withDuration: 0.15, animations: {
                sender.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                sender.alpha = 1.0
                thredLabel.alpha = 1.0
            }, completion: { finished in
                sender.transform = CGAffineTransform.identity
                guard let image = self.saveToPhotosLbl.superview?.makeSnapshot(clear: false, subviewsToIgnore: []) else{return}
                sender.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                image.saveToPhotos { (success) in
                    DispatchQueue.main.async {
                        if success{
                            thredLabel.text = "save"
                        }
                        else{
                            thredLabel.text = "error!"
                        }
                        self.saveBtn.isEnabled = true
                        UIView.animate(withDuration: 0.2, animations: {
                            sender.transform = CGAffineTransform.identity
                        }, completion: { finished in
                            if finished{
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75){
                                    UIView.animate(withDuration: 0.15, animations: {
                                        if thredLabel.text != "save"{
                                            thredLabel.text = "save"
                                        }
                                    }, completion: { finished in
                                        if finished{
                                        }
                                    })
                                }
                            }
                        })
                    }
                }
            })
        }
 
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        descriptionView.delegate = self
        descriptionView.inputAccessoryView = toolBar
        titleView.inputAccessoryView = toolBar
        priceView.delegate = self
        titleView.delegate = self
        
        saveBtn.addTarget(self, action: #selector(showSaveView(_:)), for: .touchDown)
        saveBtn.addTarget(self, action: #selector(showSaveView(_:)), for: .touchDragEnter)
        saveBtn.addTarget(self, action: #selector(hideSaveView(_:)), for: .touchDragOutside)
        saveBtn.adjustsImageWhenDisabled = false

        saveToPhotosLbl.layer.cornerRadius = saveToPhotosLbl.frame.height / 2
        saveToPhotosLbl.clipsToBounds = true
        saveToPhotosLbl.isHidden = true

        priceView.inputAccessoryView = toolBar
                
        if let product = product, !product.designs.compactMap({$0}).isEmpty, let productColor = productType?.colors.first(where: {$0.code == product.templateColor}){
            
            var productImgData: Data!
            addConstraints(template: productType)

            if product.displaySide == "front"{
                productImgData = productColor.img
                
                let front = product.designs.compactMap({$0}).first(where: {$0.side.name == "Front"})
                
                for view in canvasDisplayViews{
                    if let data = front?.img, let img = UIImage(data: data){
                        view.setImage(img, for: .normal)
                    }
                }
            }
            else{
                productImgData = productColor.imgBack
                
                let back = product.designs.compactMap({$0}).first(where: {$0.side.name == "Back"})
                
                for view in canvasDisplayViews{
                    if let data = back?.img, let img = UIImage(data: data){
                        view.setImage(img, for: .normal)
                    }
                }
            }
            
            let productImg = UIImage(data: productImgData)

            designImg.image = productImg
            
        }
        
        
        nextBtn.layer.cornerRadius = nextBtn.frame.height / 2
        nextBtn.clipsToBounds = true
        textFieldDidChange(titleView)
        titleView.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        priceView.text = formattedMinPrice()
        priceView.placeholder = "Price (min $\(formattedMinPrice()))"
        
        setPlaceholder(textView: descriptionView, textColor: .secondaryLabel)

        if isEditingProduct{
            
            guard let price = product.price else{return}
            print(price)
            priceView.text = "\(price)"
            textFieldDidEndEditing(priceView, reason: .committed)
            descriptionView.text = product.caption
            titleView.text = product.name
            if !(product.isPublic ?? true){
                publicLbl.text = "Private"
                isPublic = false
            }
            nextBtn.setTitle("Update", for: .normal)
            textViewDidChange(descriptionView)
            
            if uploadingPosts.contains(where: {$0.productID == product.productID}){
                descriptionView.isEditable = false
                titleView.isEnabled = false
                hideNextBtn()
            }
        }
        else{
            textViewDidChange(descriptionView)
            deletePostBtn.isHidden = true
        }
        // Do any additional setup after loading the view.
    }
    
    lazy var productType: Template? = {
        return all.tees.first(where: {$0.productCode == product?.productType})?.copy() as? Template
    }()
    
    func formattedMinPrice() -> String{
        let defaultPrice = 2000.0
        
        var price = defaultPrice
        if productType?.isDiscount ?? false{
            price = productType?.discountPrice ?? defaultPrice
        }
        else{
            price = productType?.minPrice ?? defaultPrice
        }
        
        if (product?.designs.count ?? 0) > 1{
            price += ((productType?.extraCost ?? 0.00) * 100)
        }
        return price.formatPrice().replacingOccurrences(of: "$", with: "")
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        
        if textField == priceView{
            guard var text = textField.text else{
                textFieldDidChange(textField)
                return}
            
            if text.count > 5{
                text.removeLast(text.count - 5)
                textField.text = text
            }
            
            guard let price = Float(text) else{
                
                textField.text = formattedMinPrice()
                textFieldDidChange(textField)
                return}
            
            print(price)
            
            guard let minPrice = Float(formattedMinPrice()) else{return}
            if price >= minPrice{
                if let index = text.firstIndex(of: ".")?.utf16Offset(in: text){
                    switch index{
                    case text.count - 1:
                        textField.text?.append(contentsOf: "00")
                    case text.count - 2:
                        textField.text?.append(contentsOf: "0")
                    default:
                        break
                    }
                }
                else{
                    if text.isEmpty{
                        textField.text = formattedMinPrice()
                    }
                    else{
                        textField.text?.append(contentsOf: ".00")
                    }
                }
            }
            else{
                textField.text = formattedMinPrice()
            }
            textFieldDidChange(textField)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        
        if textField == priceView && textField.text == formattedMinPrice(){
            textField.text?.removeAll()
            textFieldDidChange(textField)
            //profitLbl.text = "Profit (per. shirt): $0.00"
        }
 
    }
    
    @IBAction func viewPricingGuide(_ sender: UIButton) {
        self.performSegue(withIdentifier: "toCommissionCalc", sender: nil)
    }
    
    func hideNextBtn(){
        UIView.animate(withDuration: 0.2, animations: {
            self.nextBtn.alpha = 0.0
            self.nextBtn.isUserInteractionEnabled = false
        }, completion: nil)
    }
    
    func showNextBtn(){
        
        UIView.animate(withDuration: 0.2, animations: {
            self.nextBtn.alpha = 1.0
            self.nextBtn.isUserInteractionEnabled = true
        }, completion: nil)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField){
        
        if cannotPost(){
            hideNextBtn()
        }
        else{
            showNextBtn()
        }
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if let tabVC = segue.destination as? MainTabBarViewController{
            if product != nil{
                tabVC.product = product
                tabVC.deletingPost = deletingPost
                tabVC.posted = !isEditingProduct
            }
            else{
                tabVC.posted = false
            }
        }
        else if let calcVC = (segue.destination as? UINavigationController)?.viewControllers.first as? CommissionCalcVC{
            calcVC.productType = productType
            calcVC.designCount = product?.designs.count ?? 0
        }
    }
    

}
