//
//  PhotoLibraryCollectionView.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-11-28.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import UIKit
import Photos
import ColorCompatibility
import FirebaseFirestore
import SDWebImage

class PhotosView: UIView{
    
    var selectedImage: UIImage!
    var firstTimeSwitch = false
    
    lazy var topTab: UISegmentedControl = {
        
        let control = UISegmentedControl.init(frame: CGRect(x: 5, y: 5, width: self.frame.width - 10, height: 30))
        control.insertSegment(withTitle: "Photos", at: 0, animated: false)
        control.insertSegment(withTitle: "My Threds", at: 1, animated: false)
        control.setTitleFont(UIFont(name: "NexaW01-Heavy", size: 14)!)
        control.setTitleColor(.white)
        control.selectedSegmentTintColor = UIColor(named: "LoadingColor")
        control.backgroundColor = .systemGroupedBackground
        control.layer.cornerRadius = 0
        control.selectedSegmentIndex = 0
        control.clipsToBounds = true
        control.addTarget(self, action: #selector(switchedSegment(_:)), for: .valueChanged)
        return control
    }()
    
    @objc func switchedSegment(_ sender: UISegmentedControl){
        
        sendPicBtn.isHidden = true
        selectedImage = nil
        
        if let rollIndex = cameraRollCollectionView.indexPathsForSelectedItems?.first{
            cameraRollCollectionView.deselectItem(at: rollIndex, animated: false)
        }
        if let thredIndex = thredListView.indexPathsForSelectedItems?.first{
            thredListView.deselectItem(at: thredIndex, animated: false)
        }

        if sender.selectedSegmentIndex == 0{
            thredListView.isHidden = true
            cameraRollCollectionView.isHidden = false

        }
        else{
            cameraRollCollectionView.isHidden = true
            thredListView.isHidden = false
            if firstTimeSwitch{
                firstTimeSwitch = false
                thredListView.isLoading = false
                thredListView.getProducts(fromInterval: nil){
                    
                }
            }
        }
    }
    
    
    lazy var cameraRollCollectionView: CameraRollView = {
        
        let y = self.frame.midY
        let collectionView = CameraRollView.init(frame: CGRect(x: 0, y: topTab.frame.maxY + 5, width: self.frame.width, height: self.frame.height - topTab.frame.height - 5), collectionViewLayout: CollectionViewLayout())
        
        if let backView = collectionView.backgroundView{
            backView.addViewSpinner(centerX: backView.center.x, centerY: (collectionView.visibleSize.height / 2) - 20, width: 40, height: 40)
        }
        return collectionView
    }()
    
    lazy var thredListView: ThredListView = {
        
        let y = self.frame.midY
        let collectionView = ThredListView.init(frame: CGRect(x: 0, y: topTab.frame.maxY + 5, width: self.frame.width, height: self.frame.height - topTab.frame.height - 5), collectionViewLayout: CollectionViewLayout())
        
        if let backView = collectionView.backgroundView{
            backView.addViewSpinner(centerX: backView.center.x, centerY: (collectionView.visibleSize.height / 2) - 20, width: 40, height: 40)
        }
        return collectionView
    }()
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        addSubview(topTab)
        addSubview(cameraRollCollectionView)
        addSubview(thredListView)
        addSubview(sendPicBtn)
        sendPicBtn.isHidden = true
        thredListView.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var sendPicBtn: UIButton = {
        
        let button = UIButton.init(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        button.backgroundColor = .cyan
        button.layer.cornerRadius = button.frame.height / 2
        button.clipsToBounds = true
        button.setImage(UIImage.init(named: "SendIcon"), for: .normal)
        button.center.x = self.center.x
        button.center.y = frame.height - 60
        button.tintColor = .systemBackground
        button.addTarget(self, action: #selector(self.sendText(_:)), for: .touchUpInside)
        button.setRadiusWithShadow()
        button.accessibilityIdentifier = "LibrarySendBtn"
        return button
    }()
    
    @objc func sendText(_ sender: UIButton){
        if let parent = self.getViewController(){
            if let edit = parent as? EditProfileVC{
                edit.usePhoto(sender)
            }
            else if let design = parent as? DesignViewController{
                design.usePhoto(sender)
            }
            else if let comments = parent as? CommentsVC{
                comments.usePhoto(sender)
            }
            else if let chat = parent as? ChatVC{
                chat.usePhoto(sender)
            }
        }
    }
    
    func animatehideCameraRoll(viewToCarry: UIView, backgroundView: UIView, tableView: UITableView?, completed: @escaping () -> ()){
        self.sendPicBtn.isHidden = true

        UIView.animate(withDuration: 0.2, animations: {
            self.transform = CGAffineTransform(translationX: 0, y: backgroundView.frame.height - self.frame.minY)
            viewToCarry.transform = CGAffineTransform.identity
            tableView?.contentInset.top = 0
            tableView?.verticalScrollIndicatorInsets.top = 0
        }, completion: { finished in
            if finished{
                self.hidePhotosCollectionView(){
                    completed()
                }
                self.transform = .identity
            }
        })
    }
    
    
    
    
    func hidePhotosCollectionView(completed: () -> ()){
        
        cameraRollCollectionView.images.removeAll()
        cameraRollCollectionView.reloadData()
        
        thredListView.images.removeAll()
        thredListView.reloadData()
        
        self.selectedImage = nil
        self.isHidden = true
        self.sendPicBtn.isHidden = true
        
        completed()
    }
    
    
    
    func showCameraRollAnimate(completed: @escaping (Bool) -> ()){
    
        topTab.selectedSegmentIndex = 0
        switchedSegment(topTab)
        self.isHidden = false
        firstTimeSwitch = true
        
        
        if let view = cameraRollCollectionView.backgroundView{
            view.addViewSpinner(centerX: view.center.x, centerY: (cameraRollCollectionView.visibleSize.height / 2), width: 40, height: 40)
        }
        self.alpha = 0.0
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 1.0
        }, completion: { finished in
            if finished{
                self.cameraRollCollectionView.checkPhotosAccess{[weak self] status, firstTime in
                    if status == .authorized{
                        completed(true)
                        self?.cameraRollCollectionView.getImages()
                    }
                    else{
                        if #available(iOS 14, *) {
                            if status == .limited{
                                completed(true)
                                self?.cameraRollCollectionView.getImages()
                            }
                        } else {
                            // Fallback on earlier versions
                        }
                        
                        if firstTime{
                            completed(false)
                        }
                        else{
                            if status == .restricted{
                                completed(false)
                            }
                            else{
                                self?.cameraRollCollectionView.presentCameraRollSettings(){
                                    completed(false)
                                }
                            }
                        }
                    }
                }
            }
        })
    }
}

class CameraRollView: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource{
    
    var images = [PHAsset]()
    
    fileprivate func getImages() {
        
        self.images.removeAll()
        
        let options = PHFetchOptions()
        options.sortDescriptors =  [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assets = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: options)
        
        assets.enumerateObjects({ (object, count, stop) in
            // self.cameraAssets.add(object)
            self.images.append(object)
        })
        
        //In order to get latest image first, we just reverse the array
        
        DispatchQueue.main.async {
            (self.backgroundView?.subviews.first as? MapSpinnerView)?.isHidden = true
            self.reloadData()
        }
    }

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        self.register(UINib(nibName: "PhotosCell", bundle: nil), forCellWithReuseIdentifier: "PhotosCell")
        self.isScrollEnabled = true
        self.alwaysBounceVertical = true
        self.delegate = self
        self.dataSource = self
        self.backgroundColor = .systemBackground
        backgroundView = UIView.init(frame: frame)
           
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotosCell", for: indexPath) as? PhotosCell
        cell?.photoImageView.clipsToBounds = true
        cell?.photoImageView.image = nil
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.version = .current
        
        if let layout = collectionView.collectionViewLayout as? CollectionViewLayout{
            self.downloadImage(options: options, targetSize: CGSize(width: layout.itemSize.width * 2, height: layout.itemSize.height * 2), asset: self.images[indexPath.item], completed: { image in
                DispatchQueue.main.async {
                    cell?.photoImageView.image = image
                }
            })
        }
        
        return cell!
    }
    
    func downloadImage(options: PHImageRequestOptions?, targetSize: CGSize, asset: PHAsset, completed: @escaping (UIImage?) -> ()){
        
        let manager = PHImageManager.default()
        
        manager.requestImage(for: asset,
                         
        targetSize: targetSize,
        contentMode: .aspectFill,
        
        options: options) { (result, _) in
            completed(result)
        }
    }
    
    func checkPhotosAccess(completed: @escaping (PHAuthorizationStatus, Bool) -> ()) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .denied:
            
            print("Denied, request permission from settings")
            UserDefaults.standard.set(false, forKey: "AuthPhoto")
            completed(.denied, false)
        case .restricted:
            print("Restricted, device owner must approve")
            UserDefaults.standard.set(false, forKey: "AuthPhoto")
            completed(.restricted, false)
            
        case .authorized:
            
            print("Authorized, proceed")
            UserDefaults.standard.set(true, forKey: "AuthPhoto")
            completed(.authorized, false)
        case .limited:
            print("Authorized, proceed")
            UserDefaults.standard.set(true, forKey: "AuthPhoto")
            if #available(iOS 14, *) {
                completed(.limited, false)
            }
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ status in
                if status == .authorized  {
                    print("Permission granted, proceed")
                    UserDefaults.standard.set(true, forKey: "AuthPhoto")
                    if UserDefaults.standard.synchronize(){
                        completed(.authorized, true)
                    }
                    
                } else {
                    print("Permission denied")
                    UserDefaults.standard.set(false, forKey: "AuthPhoto")
                    completed(.denied, true)
                }
            })
        @unknown default:
            return
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        if collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false{
            collectionView.deselectItem(at: indexPath, animated: true)
            let photosView = superview as? PhotosView
            photosView?.sendPicBtn.isHidden = true
            photosView?.selectedImage = nil

            return false
        }
        else{
            
            return true
        }
    }
    
    
    
    internal func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let asset = self.images[indexPath.item]
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.version = .current
        options.isNetworkAccessAllowed = true

        
            self.downloadImage(options: options, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), asset: asset, completed: { image in
                
                DispatchQueue.main.async {
                    if let selectedIndexes = collectionView.indexPathsForSelectedItems?.filter({$0 != indexPath}){
                        for index in selectedIndexes{
                            collectionView.deselectItem(at: index, animated: true)
                        }
                    }
                    if let img = image{
                        let photosView = self.superview as? PhotosView
                        photosView?.selectedImage = img
                        photosView?.sendPicBtn.isHidden = false
                    }
                    else{
                        return
                    }
                }
            })
        
    }
    
    
    func presentCameraRollSettings(completed: @escaping () -> ()) {
        let alertController = UIAlertController(
            title:
            "Sorry!",
            message:
            "Photo Library Access must be enabled from settings in order to use this feature",
            preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default) { _ in
            completed()
        })
        alertController.addAction(UIAlertAction(title: "Settings", style: .cancel) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: self.convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: { _ in
                    // Handle
                    completed()
                })
            }
        })
        
        DispatchQueue.main.async {
            self.getViewController()?.present(alertController, animated: true)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}


class ThredListView: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource{
    
    var images = [[String : Any?]]()
    var tokens = [String]()
    var isLoading = false

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height) / 2{
            print("fromScroll")
            if let last = images.last{
                if let interval = last["Timestamp"] as? Date{
                    if !isLoading, canLoadMore{
                        isLoading = true
                        getProducts(fromInterval: interval){
                            self.isLoading = false
                        }
                    }
                }
            }
        }
    }
    
    var canLoadMore = false
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let translation = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if translation.y > 0 {
            canLoadMore = false
            // swipes from top to bottom of screen -> down
        } else {
            canLoadMore = true
            // swipes from bottom to top of screen -> up
        }
    }
    
    func getProducts(fromInterval: Date?, completed: @escaping () -> ()){
        
        /*
         QUERY COMMENTS:
         - ORDERING THE "Timestamp" VALUE BY THE EARLIEST TIME
         - STARTING FROM THE LOCAL \(fromInterval) VAR
         - RETRIEVING DOCUMENT SNAPSHOTS IN THE \(snapDocuments) VAR
         - IF THERE IS AN ERROR, IT WILL BE IN THE \(err) VAR
         - A COMMENT WILL EITHER BE A PICTURE OR TEXT, NOT BOTH
         */
        
        var query: Query! = nil
        //REMOVE LATER
        //
        guard let uid = pUserInfo.uid else{return}

        
        if fromInterval == nil{
            if let view = self.backgroundView{
                view.addViewSpinner(centerX: view.center.x, centerY: (visibleSize.height / 2), width: 40, height: 40)
            }
            query = Firestore.firestore().collection("Users").document(uid).collection("Products").whereField("Timestamp", isLessThanOrEqualTo: Timestamp(date: Date())).whereField("Available", isEqualTo: true).limit(to: 15).order(by: "Timestamp", descending: true)
        }
        else if let last = fromInterval{
            query = Firestore.firestore().collection("Users").document(uid).collection("Products").whereField("Timestamp", isLessThan: Timestamp(date: last)).whereField("Available", isEqualTo: true).limit(to: 15).order(by: "Timestamp", descending: true)
        }
        query.getDocuments(completion: { (snapDocuments, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                
                return
            }
            else{
                if snapDocuments?.isEmpty ?? true{
                    (self.backgroundView?.subviews.first as? MapSpinnerView)?.isHidden = true
                    completed()
                    return
                }
                else{
                    guard let snaps = snapDocuments?.documents else
                    {return}
                    
                    for snap in snaps{
                        
                        let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                        let color = snap["Template_Color"] as? String
                        let type = snap["Type"] as? String ?? defaultProductType
                        let side = snap["Side"] as? String

                        self.images.append([
                            "ID" : snap.documentID,
                            "Timestamp" : timestamp,
                            "Image" : nil,
                            "Color" : color,
                            "Type" : type,
                            "Side" : side
                            ])
                        self.performBatchUpdates({
                            self.insertItems(at: [IndexPath(item: self.images.count - 1, section: 0)])
                        }, completion: nil)
                    }
                    (self.backgroundView?.subviews.first as? MapSpinnerView)?.isHidden = true
                    completed()
                }
            }
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotosCell", for: indexPath) as? PhotosCell
        cell?.photoImageView.clipsToBounds = true
        cell?.photoImageView.backgroundColor = .tertiarySystemGroupedBackground
        cell?.photo = nil
        let design = self.images[indexPath.item]
        guard let color = design["Color"] as? String else{return cell!}
        guard let designID = design["ID"] as? String else{return cell!}
        guard let designType = design["Type"] as? String else{return cell!}
        guard let uid = pUserInfo.uid else{return cell!}
        let designImg = design["Image"] as? UIImage
        let side = design["Side"] as? String ?? "front"

        let colorObject = all.tees.first(where: {$0.productCode == designType})?.colors.first(where: {$0.code == color})?.getColor()

        if designImg != nil{
            cell?.photo = designImg
            cell?.photoImageView.backgroundColor = colorObject
        }
        else{
            if let image = cache.imageFromCache(forKey: designID){
                cell?.photo = image
                cell?.photoImageView.backgroundColor = colorObject
                self.images[indexPath.item]["Image"] = image
            }
            else{
                if !(tokens.contains(designID)){
                        //cell?.circularProgress.isHidden = false
                    tokens.append(designID)
                    self.downloadThredListImage(isThumbnail: true, cell: cell, followingUID: uid, picID: designID, displaySide: side){ img in
                        self.tokens.removeAll(where: {$0 == designID})
                        if self.images.indices.contains(indexPath.item){
                            self.images[indexPath.item]["Image"] = img
                            collectionView.performBatchUpdates({
                                collectionView.reloadItems(at: [indexPath])
                            }, completion: nil)
                        }
                    }
                }
            }
        }
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotosCell else{return}
        let design = images[indexPath.item]
        guard let designID = design["ID"] as? String else{return}
        guard let uid = pUserInfo.uid else{return}
        let photosView = superview as? PhotosView
        let designImg = design["Image"] as? UIImage
        let side = design["Side"] as? String ?? "front"

        photosView?.selectedImage = designImg
        photosView?.sendPicBtn.isHidden = false
        
        downloadThredListImage(isThumbnail: false, cell: cell, followingUID: uid, picID: designID, displaySide: side){ img in
            
            self.tokens.removeAll(where: {$0 == designID})
            
            if img == nil{
                
                return}
            
            if self.images.indices.contains(indexPath.item){
                self.images[indexPath.item]["Image"] = img
            }
            if photosView?.selectedImage == designImg{
                photosView?.selectedImage = img
            }
            
            if let designVC = self.getViewController() as? DesignViewController{
                let imageViews = designVC.canvas.subviews.filter({$0.isKind(of: UIImageView.self)}) as? [UIImageView]
                
                if let imageView = imageViews?.first(where: {$0.image == designImg}){
                    imageView.image = img
                }
            }
            
            
            cell.photo = img
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        if collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false{
            collectionView.deselectItem(at: indexPath, animated: true)
            let photosView = superview as? PhotosView
            photosView?.sendPicBtn.isHidden = true
            photosView?.selectedImage = nil
            return false
        }
        else{
            
            return true
        }
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        self.register(UINib(nibName: "PhotosCell", bundle: nil), forCellWithReuseIdentifier: "PhotosCell")
        self.isScrollEnabled = true
        self.alwaysBounceVertical = true
        self.delegate = self
        self.dataSource = self
        self.backgroundColor = .systemBackground
        backgroundView = UIView.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
