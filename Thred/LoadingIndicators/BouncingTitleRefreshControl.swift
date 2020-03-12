//
//  BouncingTitleRefreshControl.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-10-30.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import UIKit

class BouncingTitleRefreshControl: UIRefreshControl {

    var labelsArray: Array<UILabel> = []
    var currentColorIndex: Int! = 0
    var currentLabelIndex: Int! = 0
    
    init(title: String){
        super.init()
        backgroundColor = UIColor.clear
        tintColor = UIColor.clear
        
        
        initStackView(view: initCustomView(), title: title)
        NotificationCenter.default.addObserver(self, selector: #selector(endRefreshing), name: UIApplication.willResignActiveNotification, object: nil)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func endRefreshing() {
        super.endRefreshing()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func initCustomView() -> UIView{
        let view = UIView()
        view.backgroundColor = UIColor(named: "TopBackgroundColor")
               
        view.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(view)

        NSLayoutConstraint.activate([
            
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.centerXAnchor.constraint(equalTo: centerXAnchor),
            view.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        return view
    }
    
    func initStackView(view: UIView, title: String){
        
        let stackView = UIStackView()
        stackView.alignment = .fill
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 0
        let title = title
        var size = CGFloat()
        for letter in title{
            let label = UILabel()
            label.font = UIFont(name: "NexaW01-Heavy", size: 48)!
            label.text = "\(letter)"
            label.textColor = UIColor(red: 0, green: 0.749, blue: 1, alpha: 1.0)
            label.textAlignment = .center
            size += label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: label.frame.height)).width
            stackView.addArrangedSubview(label)
            labelsArray.append(label)
        }
        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalToConstant: size),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    func animateRefresh() {

        UIView.animate(withDuration: 0.11, delay: 0.0, options: .curveLinear, animations: {
            self.labelsArray[self.currentLabelIndex].transform = CGAffineTransform(translationX: 0, y: -15)
            self.labelsArray[self.currentLabelIndex].textColor = self.getNextColor()
        }, completion: { (finished) in
            UIView.animate(withDuration: 0.05, delay: 0.0, options: .curveLinear, animations: {
                self.labelsArray[self.currentLabelIndex].transform = CGAffineTransform.identity
                               
                self.labelsArray[self.currentLabelIndex].textColor = UIColor(red: 0, green: 0.749, blue: 1, alpha: 1.0)
                
            }, completion: { (finished) in
                self.currentLabelIndex += 1
                
                if self.isRefreshing {
                    if self.currentLabelIndex < self.labelsArray.count {
                        self.animateRefresh()
                    }
                    else{
                        self.currentLabelIndex = 0
                        self.animateRefresh()
                    }
                }
                else{
                    self.currentLabelIndex = 0
                    for label in self.labelsArray{
                        label.textColor = UIColor(red: 0, green: 0.749, blue: 1, alpha: 1.0)
                        label.transform = CGAffineTransform.identity
                    }
                    return
                }
            })
        })
    }
    func getNextColor() -> UIColor {
        let colorsArray: Array<UIColor> = [UIColor.magenta, UIColor.white, UIColor.yellow, UIColor.red, UIColor.green, UIColor.blue, UIColor.orange]
     
        if currentColorIndex == colorsArray.count {
            currentColorIndex = 0
        }
     
        let returnColor = colorsArray[currentColorIndex]
        currentColorIndex += 1
     
        return returnColor
    }
}
