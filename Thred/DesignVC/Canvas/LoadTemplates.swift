//
//  LoadTemplates.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore
import SDWebImage

extension UIViewController{
    func loadDesigns(completed: @escaping ()->()){
        
        switch all.tees.getAllObjects(type: "Templates", name: "Templates"){
        case let cachedTees:
            for tee in cachedTees ?? []{
                all.tees.append(tee)
            }
            DispatchQueue.main.async {
                (self as? FeedVC)?.tableView.reloadData()
            }
            fallthrough
        default:
            Firestore.firestore().collection("Templates").order(by: "index").getDocuments(completion: { snaps, error in
                if let err = error{
                    print(err.localizedDescription)
                }
                else{
                    guard let docs = snaps?.documents, !docs.isEmpty else{completed(); return}
                    all.tees.removeAll()
                    for doc in snaps?.documents ?? []{
                        let type = doc.documentID
                        
                        let testingAccounts = doc["testingAccounts"] as? [String]
                        let isAvailable = doc["isAvailable"] as? Bool
                        guard isAvailable ?? false || testingAccounts?.contains(pUserInfo.uid ?? "") ?? false else{continue}
                        
                        let display = doc["Display_Name"] as? String
                        let info = doc["Info"] as? String
                        guard let supportedSides = doc["Supported_Sides"] as? [[String : Any]], !supportedSides.isEmpty else{continue}

                        let vari = doc["Colors"] as! [[String : Any]]
                        
                        let minPrice = doc["Min_Price_USD"] as? Double
                        let extra = doc["Extra_Cost_USD"] as? Double
                        let code = doc["Code"] as? String
                        let sizes = doc["Sizes"] as? [String]
                        let category = doc["category"] as? String
                        let moreInfo = (doc["More_info"] as? String)?.replacingOccurrences(of: "\\n", with: "\n")
                        let discountInfo = doc["Discount"] as? [String : Any]
                        let discountedUsers = discountInfo?["Artists"] as? [String]
                        let discountedPrice = discountInfo?["Minimum_Price_USD"] as? Double
                        
                        let template = Template(templateID: type, templateDisplayName: display, colors: [], info: info, minPrice: minPrice, productCode: code, sizes: sizes, category: category, moreInfo: moreInfo, discountInfo: (discountedUsers?.contains(pUserInfo.uid ?? ""), discountedPrice), supportedSides: [], extraCost: extra)

                    
                        for side in supportedSides{
                            let name = side["Name"] as? String
                            let height = side["HeightCM"] as? Double
                            let width = side["WidthCM"] as? Double
                            let widthMultiplier = side["WidthMultiplier"] as? Double
                            let centerYConst = side["CenterYConst"] as? Double
                            let centerXConst = side["CenterXConst"] as? Double
                            let rotation = side["Rotation"] as? Double
                            let useReverseAspect = side["useReverseAspect"] as? Bool ?? false
                            
                            let supportedSide = TemplateSide(name: name, heightCM: height, widthCM: width, widthMultiplier: widthMultiplier, centerY: centerYConst, useReverseAspect: useReverseAspect, centerXConst: centerXConst, rotation: rotation)
                            
                            template.supportedSides.append(supportedSide)
                        }
                        
                        for v in vari{
                            let code = v["Code"] as? String
                            let display = v["Display"] as? String
                            let img = v["IMG"] as? Data
                            let backImg = v["IMG_BACK"] as? Data
                            let rgb = v["RGB"] as? [Double]
                            let color = Colors(code: code, display: display, rgb: rgb, img: img, imgBack: backImg)
                            template.colors.append(color)
                        }
                        template.colors.shuffle()
                            
                            //.sort(by: {$0.code ?? "" < $1.code ?? ""})
                        all.tees.append(template)
                    }
                    all.tees.saveAllObjects(type: "Templates")
                    DispatchQueue.main.async {
                        if let visible = (UIApplication.shared.delegate as? AppDelegate)?.visibleViewController(), visible != self{
                            
                            if let user = visible as? UserVC{
                                let layout = ColorSectionFlowLayout.init()
                                user.collectionView.reloadData()
                                let context = user.collectionView.collectionViewLayout.invalidationContext(forBoundsChange: user.collectionView.bounds)
                                context.contentOffsetAdjustment = CGPoint.zero
                                user.collectionView.collectionViewLayout.invalidateLayout(with: context)
                                user.collectionView.setCollectionViewLayout(layout, animated: true)
                            }
                            else if let notif = visible as? NotificationVC{
                                notif.tableView?.reloadData()
                            }
                            else if let full = visible as? FullProductVC{
                                full.tableView?.reloadData()
                            }
                        }
                    }
                    completed()
                }
            })
        }
    }
}

extension String {
    func toBool() -> Bool?{
        if self == "false" {
            return false
        }else if self == "true"{
            return true
        }
        return nil
    }
}
