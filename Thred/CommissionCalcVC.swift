//
//  CommissionCalcVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-07-09.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class CommissionCalcVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var commissionLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
    @IBOutlet weak var commissionField: UITextField!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var productType: Template!
    var designCount = 1
    
    var minimumPrice: Double!{
        get{
            var price = 0.00
            if productType.isDiscount ?? false{
                price = productType?.discountPrice ?? 0
            }
            else{
                price = productType?.minPrice ?? 0
            }
            price += (((productType.extraCost ?? 0) * 100) * Double(designCount - 1))
            return price
        }
    }
    
    var productName: String!{
        get{
            return productType?.templateDisplayName
        }
    }
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        let price = Double(sender.value) * 100.00
        var commission = (price - minimumPrice) * 0.90
        if commission < 0.00{
            commission = 0.00
        }
        priceLbl.text = price.formatPrice()
        commissionLbl.text = commission.formatPrice()
        
        var priceForField = price.formatPrice()
        priceForField.removeFirst()
        commissionField.text = priceForField
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Pricing Guide - \(productName ?? "")"
        slider.minimumValue = Float(minimumPrice ?? 0) / 100
        
        let image = UIImage(named: "thred.logo.light")
        slider.setThumbImage(image?.sd_roundedCornerImage(withRadius: (image?.size.height ?? 0) / 2, corners: .allCorners, borderWidth: 2, borderColor: .gray)?.sd_resizedImage(with: CGSize(width: 30, height: 30), scaleMode: .aspectFit), for: .normal)
        
        
        sliderChanged(slider)
        commissionField.inputAccessoryView = toolBar
        commissionField.delegate = self
        
    
        // Do any additional setup after loading the view.
    }
    
    lazy var toolBar: UIView = {
        let bar = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 45))
        bar.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        let stackView = UIStackView(frame: bar.frame)
        bar.addSubview(stackView)
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
        button.setTitle("OK", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.addTarget(self, action: #selector(doneEditing(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(button)
        
        return bar
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        setKeyBoardNotifs()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setKeyBoardNotifs(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text?.removeAll()
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {

        let bottomPadding = view.safeAreaInsets.bottom
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            if (notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool ?? true){
                let keyboardFrame = keyboardFrame.cgRectValue
                let keyboardHeight = keyboardFrame.height
                UIView.animate(withDuration: 0.2, animations: {
                    if self.scrollView.contentInset.bottom == 0{
                        self.scrollView.contentOffset.y -= keyboardHeight - bottomPadding
                    }
                    self.scrollView.contentInset.bottom = keyboardHeight - bottomPadding
                    self.scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight - bottomPadding
                }, completion: { finished in
                    if finished{}
                })
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if (notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool ?? true){
            UIView.animate(withDuration: 0.2, animations: {
                self.scrollView.contentInset.bottom = 0
                self.scrollView.verticalScrollIndicatorInsets.bottom = 0
            })
        }
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        
        guard var text = textField.text else{
            return}
        
        if text.count > 5{
            text.removeLast(text.count - 5)
            textField.text = text
        }
        
        guard let price = Float(text) else{
            var price = priceLbl.text
            price?.removeFirst()
            textField.text = price
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
        
        guard let newText = textField.text, let value = Float(newText) else{return}
        slider.value = value / Float(100)
        sliderChanged(slider)
    }
    
    func formattedMinPrice() -> String{
        return "\(minimumPrice.formatPrice().replacingOccurrences(of: "$", with: ""))"
    }
    
    @objc func doneEditing(_ sender: UIButton){
        
        commissionField.resignFirstResponder()
    }
    
    @IBAction func doneBtnPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
