//
//  StringExtensions.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-10-23.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import UIKit

extension String {
    
    var stripped: String {
        let okayChars = Set("+0123456789")
        return self.filter {okayChars.contains($0) }
    }
        
    var revert: String {
        let okayChars = Set("123456789")
        return self.filter {okayChars.contains($0) }
    }
    
    
    func substring(from: Int?, to: Int?) -> String {
        if let start = from {
            guard start < self.count else {
                return ""
            }
        }
        
        if let end = to {
            guard end >= 0 else {
                return ""
            }
        }
        
        if let start = from, let end = to {
            guard end - start >= 0 else {
                return ""
            }
        }
        
        let startIndex: String.Index
        if let start = from, start >= 0 {
            startIndex = self.index(self.startIndex, offsetBy: start)
        } else {
            startIndex = self.startIndex
        }
        
        let endIndex: String.Index
        if let end = to, end >= 0, end < self.count {
            endIndex = self.index(self.startIndex, offsetBy: end + 1)
        } else {
            endIndex = self.endIndex
        }
        
        return String(self[startIndex ..< endIndex])
    }
    
    func substring(from: Int) -> String {
        return self.substring(from: from, to: nil)
    }
    
    func substring(to: Int) -> String {
        return self.substring(from: nil, to: to)
    }
    
    func substring(from: Int?, length: Int) -> String {
        guard length > 0 else {
            return ""
        }
        
        let end: Int
        if let start = from, start > 0 {
            end = start + length - 1
        } else {
            end = length - 1
        }
        
        return self.substring(from: from, to: end)
    }
    
    func substring(length: Int, to: Int?) -> String {
        guard let end = to, end > 0, length > 0 else {
            return ""
        }
        
        let start: Int
        if let end = to, end - length > 0 {
            start = end - length + 1
        } else {
            start = 0
        }
        
        return self.substring(from: start, to: to)
    }
    
    func getDayOfWeek(_ today:String) -> String? {
        let formatter  = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd, a hh:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
            
        guard let todayDate = formatter.date(from: today) else {
            return nil }
        
        
        formatter.dateStyle = .short
        formatter.timeZone = TimeZone.current
        
        let l = formatter.string(from: todayDate)
        
        print(l)
        
        
        return l
    }
    
    func getDateFromString(timezone: TimeZone?) -> Date?{
        
        let dateFormatter = DateFormatter.iSO8601DateWithMillisec
        let date = dateFormatter.date(from: self)
        return date
    }
    
    func getMessageDateFromString(timezone: TimeZone) -> Date?{
        
        let formatter  = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = timezone
            
        guard let todayDate = formatter.date(from: self) else {return nil}
        
        return todayDate
    }
}

extension DateFormatter {
    static var iSO8601DateWithMillisec: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter
    }
}
