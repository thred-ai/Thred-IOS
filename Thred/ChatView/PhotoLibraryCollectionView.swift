//
//  PhotoLibraryCollectionView.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-11-28.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import Foundation
import UIKit
import Photos
import ColorCompatibility


class CameraRollView: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource{
    
    var selectedImage: UIImage!
    var images = [PHAsset]()
    
    lazy var sendPicBtn: UIButton? = {
        
        let button = UIButton.init(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        button.backgroundColor = ColorCompatibility.systemBackground
        button.layer.cornerRadius = button.frame.height / 2
        button.clipsToBounds = true
        guard let parentView = self.getViewController()?.view else{return nil}
        button.setImage(UIImage.init(named: "SendIcon"), for: .normal)
        button.center.x = self.center.x
        button.center.y = parentView.frame.height - 60
        button.tintColor = .cyan
        button.addTarget(self, action: #selector(self.sendText(_:)), for: .touchUpInside)
        button.setRadiusWithShadow()
        button.accessibilityIdentifier = "LibrarySendBtn"
        button.layer.borderColor = UIColor.cyan.cgColor
        button.layer.borderWidth = 2
        parentView.addSubview(button)
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
        }
        
    }
    
    func showCameraRollAnimate(completed: @escaping (Bool) -> ()){
    
        self.isHidden = false
        if let view = backgroundView{
            view.addViewSpinner(centerX: view.center.x, centerY: (self.visibleSize.height / 2), width: 40, height: 40)
        }
        self.alpha = 0.0
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 1.0
        }, completion: { finished in
            if finished{
                self.checkPhotosAccess{[weak self] status, firstTime in
                    if status == .authorized{
                        completed(true)
                        self?.getImages()
                    }
                    else{
                        if firstTime{
                            completed(false)
                        }
                        else{
                            if status == .restricted{
                                completed(false)
                            }
                            else{
                                self?.presentCameraRollSettings(){
                                    completed(false)
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    
    func animatehideCameraRoll(viewToCarry: UIView, backgroundView: UIView, tableView: UITableView?, completed: @escaping () -> ()){
        self.sendPicBtn?.isHidden = true

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
        self.isHidden = true
        completed()
        self.sendPicBtn?.isHidden = true
        self.images.removeAll()
        self.selectedImage = nil
        self.reloadData()
    }
    
    
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
        self.backgroundColor = ColorCompatibility.systemBackground
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
    
    internal func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? PhotosCell{
            cell.photoImageView.alpha = 1.0
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        if collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false{
            collectionView.deselectItem(at: indexPath, animated: true)
            self.collectionView(collectionView, didDeselectItemAt: indexPath)
            self.sendPicBtn?.isHidden = true
            self.selectedImage = nil

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
        options.isSynchronous = true
        options.resizeMode = .exact
        options.version = .current

        
        DispatchQueue.global(qos: .background).sync {
            self.downloadImage(options: options, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), asset: asset, completed: {[weak self] image in
                
                DispatchQueue.main.async {
                    if let selectedIndexes = collectionView.indexPathsForSelectedItems?.filter({$0 != indexPath}){
                        for index in selectedIndexes{
                            collectionView.deselectItem(at: index, animated: true)
                        }
                    }
                    if let img = image{
                        self?.selectedImage = img
                        self?.sendPicBtn?.isHidden = false
                    }
                    else{
                        return
                    }
                }
            })
        }
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
    
    fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
        return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
