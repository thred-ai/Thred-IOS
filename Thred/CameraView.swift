//
//  CameraView.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-11-28.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import UIKit
import Photos
import ColorCompatibility


class CameraView: UIView, AVCapturePhotoCaptureDelegate{
    
    
    var flashBtn: UIButton!
    var dismissBtn: UIButton!
    var useBtn: UIButton!
    var saveToCameraRollBtn: UIButton!
    var retakeBtn: UIButton!
    var captureBtn: UIButton!
    var rotateBtn: UIButton!
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var output: AVCapturePhotoOutput?
    var frontCamera: AVCaptureDevice?
    var rearCamera: AVCaptureDevice?
    var currentCameraPosition: CameraPosition?
    var frontCameraInput: AVCaptureDeviceInput?
    var rearCameraInput: AVCaptureDeviceInput?
    var flashMode = AVCaptureDevice.FlashMode.off
    var photoCaptureCompletionBlock: ((UIImage?, Error?) -> Void)?
    var camPos = "Back"
    let minimumZoom: CGFloat = 1.0
    let maximumZoom: CGFloat = 3.0
    var lastZoomFactor: CGFloat = 1.0
    var selectedImage: UIImage?
    
    

    enum CameraControllerError: Swift.Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
    
    public enum CameraPosition {
        case front
        case rear
    }
    
    lazy var pincher: UIPinchGestureRecognizer = {
        let pincher = UIPinchGestureRecognizer()
        pincher.addTarget(self, action: #selector(zoomCamera(_:)))
        return pincher
    }()
    
    lazy var doubleTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        gesture.numberOfTapsRequired = 2
        gesture.numberOfTouchesRequired = 1
        gesture.addTarget(self, action: #selector(rotateCamera(_:)))
        return gesture
    }()
    
    lazy var swiper: UIPanGestureRecognizer = {
       
        let gesture = UIPanGestureRecognizer()
        gesture.addTarget(self, action: #selector(checkSwipe(_:)))
        return gesture
    }()
    
    @objc func checkSwipe(_ sender: UIPanGestureRecognizer){
        
        if sender.state == .began || sender.state == .changed {
            let translation = sender.translation(in: self)
            if let view = sender.view{
                view.center.y += translation.y
                sender.setTranslation(CGPoint.zero, in: self)
            }
        }
        if sender.state == .ended{
            if self.frame.origin.y >= 100{
                
                print(self.frame.origin.y)
                //Switch for other app
                if let vc = self.getViewController(){
                    (vc as? EditProfileVC)?.hideProfileCam{
                    }
                    (vc as? DesignViewController)?.closeCamera(nil)
                }
            }
            else{
                UIView.animate(withDuration: 0.2, animations: {
                    self.frame.origin.y = 0
                }, completion: {finished in
                    if finished{
                        sender.setTranslation(CGPoint.zero, in: self)
                    }
                })
            }
        }
    }
    
    lazy var cameraMenuBarView: UIView = {
        
        var statusBarHeight = CGFloat()
        
        if #available(iOS 13.0, *) {
            statusBarHeight = UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 20//
        } else {
           statusBarHeight = UIApplication.shared.statusBarFrame.height
        }
        let view = UIView.init(frame: CGRect(x: 0, y: statusBarHeight, width: frame.width, height: 60))
        view.backgroundColor = UIColor.clear
        dismissBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        
        dismissBtn?.setImage(UIImage.init(nameOrSystemName: "chevron.up", systemPointSize: 22, iconSize: 9), for: .normal)


        dismissBtn?.tintColor = UIColor.white
        dismissBtn?.setRadiusWithShadow()
        dismissBtn?.center.x = view.center.x
        view.addSubview(dismissBtn)
        view.isHidden = true
        return view
    }()
    
    
    lazy var bottomBar: UIView = {
        let view = UIView.init(frame: CGRect(x: 0, y: frame.height - 90, width: frame.width, height: 120))
        view.center.x = center.x
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(bottomMenuBar)
        return view
    }()
    
    
    
    lazy var bottomMenuBar: UIView = {[weak self] in
        let view = UIView.init(frame: CGRect(x: 0, y: 10, width: frame.width, height: 80))
        //Rotate Camera Button
        

        rotateBtn = UIButton.init(frame: CGRect(x: 0, y: 10, width: 80, height: 80))
        rotateBtn.center.y = view.center.y
        rotateBtn.center.x = (view.frame.width / 3) / 2
        rotateBtn.tintColor = UIColor.white
        
        
        rotateBtn.addTarget(self, action: #selector(rotateCamera(_:)), for: .touchUpInside)
        view.addSubview(rotateBtn)
        //Capture Photo Button
        captureBtn = UIButton.init(frame: CGRect(x: 0, y: 10, width: 80, height: 80))
        captureBtn.layer.cornerRadius = captureBtn.frame.height / 2
        captureBtn.clipsToBounds = true
        captureBtn.center.x = view.center.x
        captureBtn.layer.borderWidth = 10
        captureBtn.layer.borderColor = UIColor(named: "LoadingColor")?.cgColor
        captureBtn.addTarget(self, action: #selector(takePicture(_:)), for: .touchUpInside)
        view.addSubview(captureBtn)
        //Flash Button
        flashBtn = UIButton.init(frame: CGRect(x: 0, y: 10, width: 80, height: 80))
        flashBtn.center.y = view.center.y
        flashBtn.center.x = view.frame.width - ((view.frame.width / 3) / 2)
        flashBtn.tintColor = UIColor.white
        flashBtn.addTarget(self, action: #selector(changeFlash(_:)), for: .touchUpInside)
        view.addSubview(flashBtn)
        
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration.init(pointSize: 22, weight: UIImage.SymbolWeight.black, scale: UIImage.SymbolScale.large)

            rotateBtn.setImage(UIImage.init(systemName: "camera.rotate.fill"), for: .normal)
            rotateBtn.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)
            
            flashBtn.setImage(UIImage.init(systemName: "bolt.slash.fill"), for: .normal)
            flashBtn.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)

        } else {
            //
            // Fallback on earlier versions
            rotateBtn.setImage(UIImage.init(named: "camera.rotate.fill"), for: .normal)
            flashBtn.setImage(UIImage.init(named: "bolt.slash.fill"), for: .normal)
        }
        
        return view
    }()
    
    lazy var displayImage: UIImageView = {[weak self] in
        
        guard let insets = superview?.safeAreaInsets else { return UIImageView()}

        let imageView = UIImageView.init(frame: CGRect(x: 0, y: insets.top, width: frame.width, height: frame.height - (insets.bottom + insets.top)))
        imageView.backgroundColor = .black
        if self?.getViewController() is EditProfileVC{
            imageView.contentMode = .scaleAspectFit
        }
        else{
            imageView.contentMode = .scaleAspectFill
        }
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        //Retake Button
        retakeBtn = UIButton.init(frame: CGRect(x: 0, y: 10, width: 60, height: 60))
        retakeBtn.tintColor = UIColor.white
        
        

        retakeBtn.addTarget(self, action: #selector(retakeImage(_:)), for: .touchUpInside)
        retakeBtn.center.x = 40

        retakeBtn.setRadiusWithShadow()
        imageView.addSubview(retakeBtn)
        //Use Image Button
        useBtn = UIButton.init(frame: CGRect(x: 0, y: imageView.frame.height - 70, width: 60, height: 60))
        useBtn.tintColor = .cyan
        useBtn.setImage(UIImage.init(named: "SendIcon"), for: .normal)
        
        addUseImageButtonTarget()
        useBtn.backgroundColor = ColorCompatibility.systemBackground
        
        useBtn.layer.borderColor = UIColor.cyan.cgColor
        useBtn.layer.borderWidth = 2
        useBtn.layer.cornerRadius = useBtn.frame.height / 2
        useBtn.clipsToBounds = true
        useBtn.setRadiusWithShadow()
        useBtn.center.x = imageView.frame.width - 40
        useBtn.accessibilityIdentifier = "CameraSendBtn"
        imageView.addSubview(useBtn)
        //Save To Camera Roll
        saveToCameraRollBtn = UIButton.init(frame: CGRect(x: 0, y: imageView.frame.height - 70, width: 60, height: 60))
        saveToCameraRollBtn.center.x = 40
        saveToCameraRollBtn.tintColor = UIColor.white
        saveToCameraRollBtn.setRadiusWithShadow()
        saveToCameraRollBtn.addTarget(self, action: #selector(saveToCameraRoll(_:)), for: .touchUpInside)
        imageView.addSubview(saveToCameraRollBtn)
        //Safe Area Overlay View
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration.init(pointSize: 22, weight: UIImage.SymbolWeight.black, scale: UIImage.SymbolScale.large)
            
            retakeBtn.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)
            useBtn.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)
        saveToCameraRollBtn.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)


            retakeBtn.setImage(UIImage.init(systemName: "xmark"), for: .normal)

            saveToCameraRollBtn.setImage(UIImage.init(systemName: "square.and.arrow.down.fill"), for: .normal)

        } else {
            // Fallback on earlier versions
            saveToCameraRollBtn.setImage(UIImage.init(named: "square.and.arrow.down.fill"), for: .normal)
            retakeBtn.setImage(UIImage.init(named: "xmark"), for: .normal)
        }

        return imageView
    }()
    
    func setUpCam(){
        prepare {(error) in
            if let error = error {
                print(error)
            }
            try? self.displayPreview(on: self)
        }
    }
    
    @objc func rotateCamera(_ sender: Any){
        do {
            try rotateCameraViews()
        }
        catch {
            print(error)
        }
    }
       
       @objc func saveToCameraRoll(_ sender: UIButton){
           guard let image = displayImage.image else{return}
           PHPhotoLibrary.shared().performChanges({
               PHAssetChangeRequest.creationRequestForAsset(from: image)
           }, completionHandler: { success, error in
               if success {
                   // Saved successfully!
                   DispatchQueue.main.async {
                       //activity.stopAnimating()
                       //activity.removeFromSuperview()
                       //self.hideBtn(sender, shown: false)
                   }
               }
               else if error != nil {
                   // Save photo failed with error
                   print(error?.localizedDescription ?? "")
               }
               else {
                   // Save photo failed with no error
               }
           })
       }
       
       @objc func retakeImage(_ sender: UIButton){
           self.resetDisplayImage()
           self.setUpCam()
       }
       
       func rotateCameraViews() throws {
            guard let currentCameraPosition = currentCameraPosition, let captureSession = captureSession, captureSession.isRunning else {
               throw CameraControllerError.captureSessionIsMissing }
            captureSession.beginConfiguration()
            func rotateCameraToFront() throws {
                self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera!)
                captureSession.removeInput(rearCameraInput!)
                if captureSession.canAddInput(frontCameraInput!) {
                    captureSession.addInput(frontCameraInput!)
                    self.currentCameraPosition = .front
                }
                else { throw CameraView.CameraControllerError.invalidOperation }
            }
            func rotateCameraToRear() throws {
                self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera!)
                captureSession.removeInput(frontCameraInput!)
                if captureSession.canAddInput(rearCameraInput!) {
                    captureSession.addInput(rearCameraInput!)
                    self.currentCameraPosition = .rear
                }
                else { throw CameraView.CameraControllerError.invalidOperation }
            }
            switch currentCameraPosition {
            case .front:
                self.camPos = "Back"
                try rotateCameraToRear()
            case .rear:
                self.camPos = "Front"
                try rotateCameraToFront()
            }
            captureSession.commitConfiguration()
       }
       
       @objc func changeFlash(_ sender: UIButton){
           guard let camPos = self.currentCameraPosition else{return}
           switch camPos{
           case .front:
               switch self.frontCamera?.hasFlash{
               case true:
                   if self.flashMode == .on {
                       self.flashMode = .off
                        if #available(iOS 13.0, *) {
                            sender.setImage(UIImage.init(systemName: "bolt.slash.fill"), for: .normal)
                        } else {
                            sender.setImage(UIImage.init(named: "bolt.slash.fill"), for: .normal)
                        }
                   }
                   else if self.flashMode == .off{
                        self.flashMode = .on
                        if #available(iOS 13.0, *) {
                            sender.setImage(UIImage.init(systemName: "bolt.fill"), for: .normal)
                        } else {
                            sender.setImage(UIImage.init(named: "bolt.fill"), for: .normal)
                        }
                   }
               default:
                   return
               }
           case .rear:
               if self.flashMode == .on {
                    self.flashMode = .off
                    if #available(iOS 13.0, *) {
                        sender.setImage(UIImage.init(systemName: "bolt.slash.fill"), for: .normal)
                    } else {
                        sender.setImage(UIImage.init(named: "bolt.slash.fill"), for: .normal)
                    }
               }
               else if self.flashMode == .off{
                    self.flashMode = .on
                    if #available(iOS 13.0, *) {
                        sender.setImage(UIImage.init(systemName: "bolt.fill"), for: .normal)
                    } else {
                        sender.setImage(UIImage.init(named: "bolt.fill"), for: .normal)
                    }
               }
           }
    }
    
    func displayPreview(on view: UIView) throws {
        guard let captureSession = self.captureSession, self.captureSession?.isRunning ?? false else {
            
            throw CameraControllerError.captureSessionIsMissing }
        self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.videoPreviewLayer?.connection?.videoOrientation = .portrait
        view.layer.insertSublayer(self.videoPreviewLayer!, at: 0)
        if let vc = self.getViewController() as? EditProfileVC{
            let insets = vc.view.safeAreaInsets
            let x = view.layer.bounds.minX
            let y = ((view.layer.bounds.height + insets.top - insets.bottom) / 2 - view.layer.bounds.width / 2)
            let width = view.layer.bounds.width
            self.videoPreviewLayer?.frame = CGRect(x: x, y: y, width: width, height: width)
        }
        else{
            self.videoPreviewLayer?.frame = view.layer.bounds
        }
    }
    
    func prepare(completionHandler: @escaping (Error?) -> Void) {
        func createCaptureSession() { self.captureSession = AVCaptureSession() }
        func configureCaptureDevices() throws {
            
            var devices: [AVCaptureDevice.DeviceType] = [.builtInDualCamera, .builtInTelephotoCamera, .builtInTrueDepthCamera, .builtInWideAngleCamera]

            if #available(iOS 13.0, *) {
                devices.append(.builtInDualWideCamera)
                devices.append(.builtInTripleCamera)
                devices.append(.builtInUltraWideCamera)
            }
            
            let session = AVCaptureDevice.DiscoverySession(deviceTypes: devices, mediaType: AVMediaType.video, position: .unspecified)
            let cameras = (session.devices.compactMap { $0 })
            for camera in cameras {
                if camera.position == .front {
                    self.frontCamera = camera
                }
                if camera.position == .back {
                    self.rearCamera = camera
                    
                    if camera.isFocusModeSupported(.continuousAutoFocus){
                        try camera.lockForConfiguration()
                        camera.focusMode = .autoFocus
                        camera.unlockForConfiguration()
                    }
                }
            }
        }
        func configureDeviceInputs() throws {
            guard let captureSession = self.captureSession else {throw CameraControllerError.captureSessionIsMissing}
            if(self.camPos == "Back"){
                let rearCamera = self.rearCamera
                self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera!)
                if captureSession.canAddInput(self.rearCameraInput!) { captureSession.addInput(self.rearCameraInput!)
                }
                self.currentCameraPosition = .rear
            }
            else if(camPos == "Front"){
                let frontCamera = self.frontCamera
                    self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera!)
                    if captureSession.canAddInput(self.frontCameraInput!) { captureSession.addInput(self.frontCameraInput!) }
                    else { throw CameraControllerError.inputsAreInvalid }
                    self.currentCameraPosition = .front
            }
            else { throw CameraControllerError.noCamerasAvailable }
        }
        func configurePhotoOutput() throws {
            
            guard let captureSession = self.captureSession else {throw CameraControllerError.captureSessionIsMissing }
            self.output = AVCapturePhotoOutput()
            self.output!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
            if captureSession.canAddOutput(self.output!) { captureSession.addOutput(self.output!) }
            if(!(self.captureSession?.isRunning)!){
                DispatchQueue.global(qos: .background).sync {
                    self.captureSession?.startRunning()
                }
            }
        }
        DispatchQueue(label: "prepare").async {
            do {
                createCaptureSession()
                try configureCaptureDevices()
                try configureDeviceInputs()
                try configurePhotoOutput()
            }
            catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                return
            }
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    func addUseImageButtonTarget(){
        
        if let vc = self.superview?.getViewController(){
            //Switch for other app
            if let editVC = vc as? EditProfileVC{
                self.useBtn.addTarget(editVC, action: #selector(editVC.usePhoto(_:)), for: .touchUpInside)
            }
            if let designVC = vc as? DesignViewController{
                self.useBtn.addTarget(designVC, action: #selector(designVC.usePhoto(_:)), for: .touchUpInside)
            }
        }
    }
    
    func capture(image: UIImage?){
        self.addSubview(displayImage)
        self.displayImage.alpha = 0.0
        self.displayImage.image = image
        UIView.animate(withDuration: 0.2, animations: {
            self.displayImage.alpha = 1.0
        }, completion: { finished in
            self.bottomBar.isHidden = true
        })
    }
    
    @objc func zoomCamera(_ sender: UIPinchGestureRecognizer) {
        guard let device = rearCameraInput?.device else { return }
        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            return min(min(max(factor, minimumZoom), maximumZoom), device.activeFormat.videoMaxZoomFactor)
        }
        func update(scale factor: CGFloat) {
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                device.videoZoomFactor = factor
            } catch {
                print("\(error.localizedDescription)")
            }
        }
        let newScaleFactor = minMaxZoom(sender.scale * lastZoomFactor)
        switch sender.state {
        case .began: fallthrough
        case .changed: update(scale: newScaleFactor)
        case .ended:
            lastZoomFactor = minMaxZoom(newScaleFactor)
            update(scale: lastZoomFactor)
        default: break
        }
    }
    
    @objc func takePicture(_ sender: UIButton){
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        if captureSession?.isRunning ?? false{
            output?.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(){
            if let image = UIImage.init(data: data){
                self.add(image: image)
            }
        }
    }
    
    func add(image: UIImage){
        captureSession?.removeInput((captureSession?.inputs.first)!)
        videoPreviewLayer?.removeFromSuperlayer()
        //Switch for other app
            /*
        if let productVC = self.getViewController() as? ProductVC{
            productVC.isStatusBarHidden = true
            productVC.setNeedsStatusBarAppearanceUpdate()
        }
 */
        DispatchQueue.global(qos: .background).sync {
            self.captureSession?.stopRunning()
        }
        
        if let vc = self.getViewController(){
            
            switch vc{
            //Switch for other app
            case is EditProfileVC:
                self.evaluateImageForEditProfile(image: image)
            case is DesignViewController:
                self.evaluateImageForDesign(image: image)
            default:
                return
            }
 
        }
        
    }
    
    func evaluateImageForEditProfile(image: UIImage){
        var imageToUse: UIImage!
        switch camPos{
        case "Front":
            imageToUse = UIImage.init(cgImage: image.cgImage!, scale: image.scale, orientation: .leftMirrored)
        default:
            imageToUse = image
        }
        capture(image: imageToUse.crop())
        self.selectedImage = displayImage.image
    }
    
    func evaluateImageForDesign(image: UIImage){
        var imageToUse: UIImage!
        switch camPos{
        case "Front":
            imageToUse = UIImage.init(cgImage: image.cgImage!, scale: image.scale, orientation: .leftMirrored)
        default:
            imageToUse = image
        }
        capture(image: imageToUse)
        if let insets = self.superview?.safeAreaInsets{
            DispatchQueue.main.async {
                self.selectedImage = self.displayImage.cropImage(insets: insets)
            }
        }
    }
    
    
    func resetDisplayImage(){
        self.displayImage.removeFromSuperview()
        self.bottomBar.isHidden = false
        //Switch for other app
        /*
        if let productVC = self.getViewController() as? ProductVC{
            productVC.isStatusBarHidden = false
            productVC.setNeedsStatusBarAppearanceUpdate()
        }
 */
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .black
        self.addSubview(cameraMenuBarView)
        self.addSubview(bottomBar)
        self.addGestureRecognizer(pincher)
        self.addGestureRecognizer(doubleTapGesture)
        self.addGestureRecognizer(swiper)
        self.isHidden = true
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        
        
    }
    
    func openCameraAnimate(backgroundView: UIView, viewToCarry: UIView, viewMaxY: CGFloat, completed: @escaping () -> ()){
        self.cameraMenuBarView.isHidden = false
        self.cameraMenuBarView.alpha = 0.0
        
        self.isHidden = false
        self.frame.origin.y = viewMaxY
        
        UIView.animate(withDuration: 0.2, animations: {
            self.cameraMenuBarView.alpha = 1.0
        }, completion: { finished in
            self.getViewController()?.navigationController?.setNavigationBarHidden(true, animated: true)

            if finished{
                UIView.animate(withDuration: 0.2, animations: {
                    viewToCarry.transform = viewToCarry.transform.translatedBy(x: 0, y: -(backgroundView.frame.height - backgroundView.safeAreaInsets.bottom - backgroundView.safeAreaInsets.top - viewToCarry.frame.height + viewToCarry.transform.ty))
                    
                    self.frame.origin.y = 0
                    
                }, completion: { finished in
                    if finished{
                        print(viewToCarry.transform.ty)

                        completed()
                        //viewToCarry.isHidden = true
                            UIView.animate(withDuration: 0.5, animations: {
                                self.dismissBtn.transform = CGAffineTransform(scaleX: 1, y: -1)
                            })
                        self.checkToOpenCamera()
                    }
                })
            }
        })
    }
    
    func hideCameraAnimate(viewToCarry: UIView, completed: @escaping () -> ()){

        viewToCarry.isHidden = false
        viewToCarry.alpha = 0.0
        viewToCarry.transform = .identity
        let vc = self.getViewController()
        UIView.animate(withDuration: 0.2, animations: {
        vc?.navigationController?.setNavigationBarHidden(false, animated: true)
        viewToCarry.alpha = 1.0
        self.frame.origin.y = vc?.view.frame.height ?? 0
        }, completion: { finished in
            if finished{
                DispatchQueue.global(qos: .background).sync {
                    self.captureSession?.stopRunning()
                }
                self.isHidden = true
                self.cameraMenuBarView.isHidden = true
                self.cameraMenuBarView.alpha = 0.0
                self.dismissBtn.transform = .identity
                self.videoPreviewLayer?.removeFromSuperlayer()
                self.videoPreviewLayer = nil
                self.rearCameraInput = nil
                self.output = nil
                completed()
            }
        })
    }
    
    
    func checkToOpenCamera(){
        self.checkCameraAccess(completed: {[weak self] status, firstTime in
            if status == .authorized{
                self?.setUpCam()
            }
            else{
                if firstTime{
                    DispatchQueue.main.async {
                        //self?.hideCameraAnimate {
                            //return
                        //}
                    }
                }
                else{
                    if status == .restricted{
                        DispatchQueue.main.async {
                           // self?.hideCameraAnimate {
                           //     return
                           // }
                        }
                    }
                    else{
                        self?.presentCameraSettings(){
                            DispatchQueue.main.async {
                               // self?.hideCameraAnimate {
                               //     return
                               // }
                            }
                        }
                    }
                }
            }
        })
    }
    
    func presentCameraSettings(completed: @escaping () -> ()) {
        let alertController = UIAlertController(
            title: "Sorry!",
            message: "Camera Access must be enabled from settings in order to use this feature",
            preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default){ _ in
            completed()
        })
        alertController.addAction(UIAlertAction(title: "Settings", style: .cancel) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: self.convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: { _ in
                    completed()
                })
            }
        })
        self.getViewController()?.present(alertController, animated: true)
    }
    
    func checkCameraAccess(completed: @escaping (AVAuthorizationStatus, Bool) -> ()) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied:
            print("Denied, request permission from settings")
            completed(.denied, false)
        case .restricted:
            print("Restricted, device owner must approve")
            UserDefaults.standard.set(false, forKey: "AuthCam")
        case .authorized:
            print("Authorized, proceed")
            completed(.authorized, false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { success in
                if success {
                    print("Permission granted, proceed")
                    completed(.authorized, true)
                } else {
                    print("Permission denied")
                    completed(.denied, true)
                }
            }
        @unknown default:
            return
        }
    }
    
    fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
        return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
    }
    
}



extension UIImageView{
    func cropImage(insets: UIEdgeInsets) -> UIImage{
        
        let imsize = self.image!.size
        let ivsize = CGSize(width: self.bounds.size.width, height: self.bounds.size.height - (insets.top + insets.bottom))

        var scale : CGFloat = ivsize.width / imsize.width
        if imsize.height * scale < ivsize.height {
            scale = ivsize.height / imsize.height
        }

        let croppedImsize = CGSize(width:ivsize.width/scale, height:ivsize.height/scale)
        let croppedImrect =
            CGRect(origin: CGPoint(x: (imsize.width-croppedImsize.width)/2.0,
                                   y: (imsize.height-croppedImsize.height)/2.0),
                   size: croppedImsize)
        let r = UIGraphicsImageRenderer(size:croppedImsize)
        let croppedIm = r.image { _ in
            self.image!.draw(at: CGPoint(x:-croppedImrect.origin.x, y:-croppedImrect.origin.y))
        }
        return croppedIm
    }
}

extension UIView {
    func getViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.getViewController()
        } else {
            return nil
        }
    }
}
