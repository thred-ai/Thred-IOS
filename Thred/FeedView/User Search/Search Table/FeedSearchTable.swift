//
//  FeedSearchTable.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-11-16.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import Foundation
import UIKit
import ColorCompatibility


extension FeedVC{
    
    static var searchTable: UITableView = {
           
        let load = UITableView()
        load.separatorStyle = .none
        load.backgroundColor = ColorCompatibility.systemBackground.withAlphaComponent(0.85)
        load.isHidden = true
         
        return load
        
    }()
    
    func setSearchTableConstraints(){
        let safe = self.view.safeAreaLayoutGuide
        FeedVC.searchTable.translatesAutoresizingMaskIntoConstraints = false
               
        self.view.addSubview(FeedVC.searchTable)
        self.view.bringSubviewToFront(FeedVC.searchTable)
               
        FeedVC.searchTable.leadingAnchor.constraint(equalTo: safe.leadingAnchor).isActive = true
        FeedVC.searchTable.trailingAnchor.constraint(equalTo: safe.trailingAnchor).isActive = true
        FeedVC.searchTable.topAnchor.constraint(equalTo: safe.topAnchor).isActive = true
        FeedVC.searchTable.bottomAnchor.constraint(equalTo: safe.bottomAnchor).isActive = true
    }
}
