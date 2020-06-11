//
//  SearchProductTableViewCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-29.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility
import FirebaseFirestore

class SearchProductTableViewCell: UITableViewCell{
    
    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var productNameLbl: UILabel!
    @IBOutlet weak var likesLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
    @IBOutlet weak var quantityView: UIStackView!
    weak var savedProduct: ProductInCart!
    weak var cartVC: ShoppingCartVC!
    @IBOutlet weak var quantityField: UITextField!
    
    @IBOutlet weak var sizingLbl: UILabel!
    @IBOutlet weak var likesView: UIStackView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        productImageView.layer.cornerRadius = productImageView.frame.height / 8
        productImageView.clipsToBounds = true
        quantityField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
    }
    
    override func layoutSubviews() {
        quantityField.inputAccessoryView = toolBar
    }
    
    lazy var toolBar: UIView = {
        let bar = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 45))
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
    
    @objc func textFieldDidChange(_ textField: UITextField){
    }
    
    @objc func doneEditing(_ sender: UIButton){
        guard let text = quantityField.text else{
        return}
        guard let intText = Int(text) else{return}
        quantityField.resignFirstResponder()
        savedProduct.quantity = intText
        quantityField.text = "\(intText)"
        if Int(text) == 0, let indexPath = cartVC.savedProducts.firstIndex(where: {$0.product.productID == savedProduct.product.productID}){
            cartVC.tableView(cartVC.tableView, commit: .delete, forRowAt: IndexPath(row: indexPath, section: 0))
        }
        else{
            cartVC.uploadToFirestore()
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
