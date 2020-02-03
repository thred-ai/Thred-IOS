//
//  FeedSearchBar.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-11-16.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import Foundation
import UIKit

extension FeedVC{
    
    static var searchBar: UISearchBar = {
        
        let search = UISearchBar()
        search.autocapitalizationType = .none
        search.returnKeyType = .search
        search.searchBarStyle = .default
        search.keyboardType = .alphabet
        search.tintColor = UIColor(named: "LoadingColor")
        search.placeholder = "Search"
        search.searchTextField.font = UIFont(name: "ArialRoundedMTBold", size: 18)
        search.searchTextField.adjustsFontSizeToFitWidth = true
        search.isTranslucent = false
        search.searchTextField.minimumFontSize = 15
        if #available(iOS 13.0, *) {
            let attributes:[NSAttributedString.Key:Any] = [
                NSAttributedString.Key.foregroundColor : UIColor.label,
                NSAttributedString.Key.backgroundColor : UIColor.clear,
                NSAttributedString.Key.font : UIFont(name: "ArialRoundedMTBold", size: 18)!
            ]
            UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(attributes, for: .normal)
            
        } else {
            let attributes:[NSAttributedString.Key:Any] = [
                NSAttributedString.Key.foregroundColor : UIColor.black,
                NSAttributedString.Key.backgroundColor : UIColor.clear,
                NSAttributedString.Key.font : UIFont(name: "ArialRoundedMTBold", size: 18)!
            ]
            UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(attributes, for: .normal)
            // Fallback on earlier versions
        }
        
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor(named: "ProfileMask")
        
        
        
        return search
    }()
}
