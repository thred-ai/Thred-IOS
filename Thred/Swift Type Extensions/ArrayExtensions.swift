//
//  ArrayExtensions.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-10-28.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation

extension Array where Element:Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()
        
        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }
        
        return result
    }
}
