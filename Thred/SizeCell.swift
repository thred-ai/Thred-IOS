//
//  SizeCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-04-02.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility

class SizeCell: UITableViewCell, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var sizes = [
        "XS (Fun Size)",
        "S",
        "M",
        "L",
        "XL",
        "XXL"
    ]
    

    weak var vc: FullProductVC!{
        return getViewController() as? FullProductVC
    }
    
    @IBOutlet weak var sizingView: UITextField!
    @IBOutlet weak var sizeChartBtn: UIButton!
    let sizePicker = UIPickerView()

    
    @IBAction func viewSizingChart(_ sender: UIButton) {
        
        guard let url = URL(string: "https://thredapps.com/sizing-chart") else { return }
        UIApplication.shared.open(url)
        
    }
    
    
    lazy var toolBar: UIView = {
        let bar = UIView(frame: CGRect(x: 0, y: 0, width: self.contentView.frame.width, height: 45))
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
        sizingView.resignFirstResponder()
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let size = sizes[row].replacingOccurrences(of: " (Fun Size)", with: "")
        sizingView.text = "Size: \(size)"
        vc.selectedSize = size
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        sizingView.inputView = sizePicker
        sizePicker.delegate = self
        sizePicker.dataSource = self
        sizePicker.reloadComponent(0)
        if let index = sizes.firstIndex(of: "M"){
            sizePicker.selectRow(index, inComponent: 0, animated: false)
        }
    }
    
    override func layoutSubviews() {
        sizingView.inputAccessoryView = toolBar
        toolBar.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 45)
    }
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sizes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return sizes[row]
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
