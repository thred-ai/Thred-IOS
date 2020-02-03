//
//  EditProfileVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-11-25.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import UIKit
import Firebase
import AVKit
import FirebaseFunctions
import ColorCompatibility


class EditProfileVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIGestureRecognizerDelegate {


    @IBOutlet weak var profilePhotoView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    var editUserInfo: UserInfo! = UserInfo()
    
    
    @IBAction func changeProfilePhoto(_ sender: UIButton) {
        
        if optionMenu.isHidden{
            showOptionMenuAnimate()
        }
        else{
            if self.cameraRollCollectionView.isHidden{
                hideOptionMenuAnimate()
            }
        }
        //self.performSegue(withIdentifier: "ChangeProfilePhoto", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        tableView.delegate = self
        tableView.dataSource = self
        self.navigationController?.delegate = self
        let tapper = UITapGestureRecognizer()
        tapper.addTarget(self, action: #selector(hideCollectionViewAndOptionMenu(_:)))
        tapper.cancelsTouchesInView = false
        tapper.delegate = self
        self.setEditUserInfo()
        self.profilePhotoView.image = editUserInfo.dp
        self.view.addGestureRecognizer(tapper)
   
    }
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isDescendant(of: self.tableView) ?? false{
            return true
        }
        return false
    }
    
    
    @objc func hideCollectionViewAndOptionMenu(_ sender: UITapGestureRecognizer?){
        if !self.cameraRollCollectionView.isHidden{
            self.animateOptionMenuCameraRollButton(didOpen: false)
            self.cameraRollCollectionView.animatehideCameraRoll(viewToCarry: optionMenu, backgroundView: self.view, tableView: nil){
            }
        }
        if !self.optionMenu.isHidden{
            self.hideOptionMenuAnimate()
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.hideCollectionViewAndOptionMenu(nil)
    }
    
    func setEditUserInfo(){
        self.editUserInfo.username = userInfo.username
        self.editUserInfo.fullName = userInfo.fullName
        self.editUserInfo.dp = userInfo.dp
        self.editUserInfo.bio = userInfo.bio
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLayoutSubviews() {
        self.profilePhotoView.layer.cornerRadius = self.profilePhotoView.frame.height / 2
        self.profilePhotoView.clipsToBounds = true
        profilePhotoView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        profilePhotoView.layer.borderWidth = profilePhotoView.frame.width / 17.75
    }

    // MARK: - Table view data source

    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "FullNameField", for: indexPath) as! FullNameCell
            cell.fullNameField.text = editUserInfo.fullName
            return cell

        }
        else if indexPath.section == 1{
            let cell = tableView.dequeueReusableCell(withIdentifier: "UsernameField", for: indexPath) as! UsernameCell
            cell.usernameField.text = editUserInfo.username
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "BioField", for: indexPath) as! BioCell
            cell.bioView.text = editUserInfo.bio
            return cell
        }
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == 0{
            return "Full Name:"
        }
        else if section == 1{
            return "Username:"
        }
        else{
            return "Bio:"
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0{
            self.performSegue(withIdentifier: "ToFullnameEdit", sender: nil)
        }
        else if indexPath.section == 1{
            self.performSegue(withIdentifier: "ToUsernameEdit", sender: nil)
        }
        else{
            self.performSegue(withIdentifier: "ToBioEdit", sender: nil)
        }
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    @IBAction func cancelBtn(_ sender: UIBarButtonItem) {
        
        //Display confirmation alert
        UserDefaults.standard.set(editUserInfo.username, forKey: "USERNAME")
        userInfo.username = editUserInfo.username
        self.performSegue(withIdentifier: "backToProfile", sender: nil)
 
    }
    
    @objc func usePhoto(_ sender: UIButton){
        guard let selectedImage = self.cameraView.selectedImage ?? (self.cameraRollCollectionView.selectedImage.crop()) else{return}
        self.editUserInfo.dp = selectedImage
        self.profilePhotoView.image = self.editUserInfo.dp
        
        self.hideOptionMenuAnimate()
        self.hideProfileCam {}
        self.animateOptionMenuCameraRollButton(didOpen: false)
        self.cameraRollCollectionView.hidePhotosCollectionView {
        }
    }
    
    func save(completed: @escaping () -> ()){
        
        let data = [
            "Bio" : editUserInfo.bio,
            "Username" : editUserInfo.username,
            "Fullname" : editUserInfo.fullName,
            "UID" : userInfo.uid
        ]
        
        Functions.functions().httpsCallable("updateUserInfo").call(data, completion: { result, error  in
           
            if error != nil{
                print(error?.localizedDescription ?? "")
                
            }
            else{
                if self.editUserInfo.dp != userInfo.dp{
                    guard let imageData = self.editUserInfo.dp?.sd_resizedImage(with: CGSize(width: 200, height: 200), scaleMode: .aspectFit)?.jpegData(compressionQuality: 0.6) else {return}

                    let picID = NSUUID().uuidString.replacingOccurrences(of: "-", with: "")
                    let ref = Storage.storage().reference().child("Users/" + userInfo.uid + "/" + "profile_pic-" + picID + ".jpeg")
                    ref.putData(imageData, metadata: nil, completion: { metaData, error in
                        
                        if error != nil{
                            self.editUserInfo.dp = userInfo.dp
                            
                            completed()
                            print(error?.localizedDescription ?? "")
                        }
                        else{
                            self.editUserInfo.dpID = picID
                            completed()
                        }
                    })
                }
                else{
                    completed()
                }
            }
        })
    }
    

    @IBAction func saveInfo(_ sender: UIBarButtonItem) {
        
        sender.isEnabled = false
        
        self.save {
            self.setUserInfo(username: self.editUserInfo.username, fullname: self.editUserInfo.fullName, image: self.editUserInfo.dp, bio: self.editUserInfo.bio, notifID: self.editUserInfo.notifID, dpUID: self.editUserInfo.dpID)
            self.performSegue(withIdentifier: "backToProfile", sender: nil)
        }
 
    }
    
    lazy var optionMenu: OptionMenu = {
        
        let height = ((self.view.frame.height - self.view.safeAreaInsets.top - self.view.safeAreaInsets.bottom) / 3)
        
        let option = OptionMenu.init(frame: CGRect(x: 0, y: self.view.frame.maxY - self.view.safeAreaInsets.bottom - height, width: self.view.frame.width, height: height))
        
        option.removeBtn.addTarget(self, action: #selector(self.removePhoto(_:)), for: .touchUpInside)
        option.cameraBtn.addTarget(self, action: #selector(self.cameraPhoto(_:)), for: .touchUpInside)
        option.photosBtn.addTarget(self, action: #selector(self.libraryPhoto(_:)), for: .touchUpInside)
        option.cancelBtn.addTarget(self, action: #selector(self.cancelPhoto(_:)), for: .touchUpInside)
        self.view.insertSubview(option, aboveSubview: self.tableView)
        option.isHidden = true

        return option
    }()
    
    func showOptionMenuAnimate(){
        optionMenu.isHidden = false
        self.optionMenu.transform = CGAffineTransform(translationX: 0, y: self.optionMenu.frame.height)
        
        UIView.animate(withDuration: 0.2, animations: {
            self.optionMenu.transform = .identity
        })
    }
    
    func hideOptionMenuAnimate(){
        
        UIView.animate(withDuration: 0.2, animations: {
            self.optionMenu.transform = CGAffineTransform(translationX: 0, y: self.optionMenu.frame.height)
        }, completion: { finished in
            if finished{
                self.optionMenu.isHidden = true
            }
        })
    }
    
    
    @objc func removePhoto(_ sender: UIButton){
        
        self.editUserInfo.dp = defaultDP
        self.profilePhotoView.image = defaultDP
        self.hideOptionMenuAnimate()
        
    }
    
    lazy var cameraView: CameraView = {
        
        let stackPadding = ((self.optionMenu.subviews.first as? UIStackView)?.spacing ?? 0) * 2
        
        let y = self.view.frame.height - self.view.safeAreaInsets.bottom -  self.optionMenu.frame.height + self.optionMenu.cameraBtn.frame.maxY + stackPadding
        
        self.optionMenu.cameraBtnBottom = y
        
        let cameraView = CameraView.init(frame: CGRect(x: 0, y: y, width: self.view.frame.width, height: self.view.frame.height))
        
        cameraView.bottomBar.frame.size.height = cameraView.bottomBar.frame.height + self.view.safeAreaInsets.bottom
        cameraView.bottomBar.frame.origin.y = cameraView.frame.height - (cameraView.bottomBar.frame.height)
        
        cameraView.dismissBtn.addTarget(self, action: #selector(hideCam(_:)), for: .touchUpInside)
        
        self.view.addSubview(cameraView)

        return cameraView
        
    }()
    
    lazy var cameraRollCollectionView: CameraRollView = {
        
        let y = self.view.frame.midY
        let collectionView = CameraRollView.init(frame: CGRect(x: 0, y: self.view.frame.height - y, width: self.view.frame.width, height: y), collectionViewLayout: CollectionViewLayout())
        
        if let backView = collectionView.backgroundView{
            backView.addViewSpinner(centerX: backView.center.x, centerY: (collectionView.visibleSize.height / 2) - 20, width: 40, height: 40)
        }
        self.view.addSubview(collectionView)
        collectionView.isHidden = true

        return collectionView
    }()
    
    @objc func hideCam(_ sender: UIButton?){
        self.hideProfileCam{
        }
    }
    
    
    func hideProfileCam(completed: @escaping () -> ()){
        self.tableView.isHidden = false
        self.cameraView.hideCameraAnimate(viewToCarry: optionMenu.cameraBtn) {
            self.cameraView.resetDisplayImage()
            completed()
        }
    }
    
    @objc func cameraPhoto(_ sender: UIButton){
        self.animateOptionMenuCameraRollButton(didOpen: false)
        self.cameraRollCollectionView.hidePhotosCollectionView {
            self.cameraView.isHidden = false
            guard let cameraBtnMaxY = self.optionMenu.cameraBtnBottom else{
                return}
            self.cameraView.openCameraAnimate(backgroundView: self.view, viewToCarry: optionMenu.cameraBtn, viewMaxY: cameraBtnMaxY + self.optionMenu.transform.ty){
                self.hideOptionMenuAnimate()
                self.tableView.isHidden = true
                self.tableView.contentInset.bottom = 0
            }
        }
    }
    
    func animateOptionMenuCameraRollButton(didOpen: Bool){
        let button = self.optionMenu.photosBtn
        if didOpen{
            button?.tintColor = .cyan
            button?.setTitle(nil, for: .normal)
            if #available(iOS 13.0, *) {
                button?.setImage(UIImage(systemName: "chevron.down"), for: .normal)
            } else {
                // Fallback on earlier versions
                button?.setImage(UIImage(named: "chevron_down"), for: .normal)
            }
        }
        else{
            button?.tintColor = nil
            button?.setTitle("Photos", for: .normal)
            button?.setImage(nil, for: .normal)
        }
        button?.alpha = 0.0
        UIView.animate(withDuration: 0.2, animations: {
            button?.alpha = 1.0
        })
    }

    func showCamRoll(sender: UIButton?){
        let y = self.view.frame.midY
        let btnMaxY = self.optionMenu.frame.maxY - self.optionMenu.photosBtn.frame.maxY - self.optionMenu.stackView.spacing
        self.optionMenu.transform = CGAffineTransform(translationX: 0, y: (y - btnMaxY))
        self.animateOptionMenuCameraRollButton(didOpen: true)
        self.cameraRollCollectionView.showCameraRollAnimate(completed: { openedRoll in
            if !openedRoll{
                self.animateOptionMenuCameraRollButton(didOpen: false)
                self.cameraRollCollectionView.animatehideCameraRoll(viewToCarry: self.optionMenu, backgroundView: self.view, tableView: nil){
                }
            }
        })
    }
    
    
    @objc func libraryPhoto(_ sender: UIButton){
        
        if self.cameraRollCollectionView.isHidden{
            self.showCamRoll(sender: sender)
        }
        else{
            self.animateOptionMenuCameraRollButton(didOpen: false)
            self.cameraRollCollectionView.animatehideCameraRoll(viewToCarry: self.optionMenu, backgroundView: self.view, tableView: nil){
            }
        }
        
    }
    
    
    
    @objc func cancelPhoto(_ sender: UIButton){
        
        self.hideOptionMenuAnimate()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        switch segue.destination{
            
        case let editUsernameVC as EditUsernameVC:
            editUsernameVC.username = editUserInfo.username
        case let editFullnameVC as EditFullnameVC:
            editFullnameVC.fullname = editUserInfo.fullName
        case let editBioVC as EditBioVC:
            editBioVC.bio = editUserInfo.bio
        default:
            return
        }
        
    }
    

    
}

class OptionMenu: UIView{
    
    var photosBtn: UIButton!
    var cameraBtn: UIButton!
    var cancelBtn: UIButton!
    var removeBtn: UIButton!
    var cameraBtnBottom: CGFloat!

    
    
    override init(frame: CGRect){
        super.init(frame: frame)
        self.backgroundColor = ColorCompatibility.systemBackground
        self.addSubview(stackView)
    }
    
    override func didAddSubview(_ subview: UIView) {
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10),
        ])
    }
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView.init(frame: frame)
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        cameraBtn = UIButton.init(frame: CGRect(x: 0, y:0, width: frame.width, height: 45))
        cameraBtn.setTitle("Camera", for: .normal)
        cameraBtn.backgroundColor = ColorCompatibility.tertiarySystemFill
        cameraBtn.setTitleColor(UIColor(named: "LoadingColor"), for: .normal)
        cameraBtn.layer.cornerRadius = cameraBtn.frame.height / 4
        cameraBtn.clipsToBounds = true
        
        photosBtn = UIButton.init(frame: CGRect(x: 0, y:0, width: frame.width, height: 45))
        photosBtn.setTitle("Photos", for: .normal)
        photosBtn.backgroundColor = ColorCompatibility.tertiarySystemFill
        photosBtn.setTitleColor(UIColor(named: "LoadingColor"), for: .normal)
        photosBtn.layer.cornerRadius = photosBtn.frame.height / 4
        photosBtn.clipsToBounds = true
        
        removeBtn = UIButton.init(frame: CGRect(x: 0, y:0, width: frame.width, height: 45))
        removeBtn.setTitle("Remove Photo", for: .normal)
        removeBtn.backgroundColor = ColorCompatibility.tertiarySystemFill
        removeBtn.setTitleColor(.red, for: .normal)
        removeBtn.layer.cornerRadius = removeBtn.frame.height / 4
        removeBtn.clipsToBounds = true
        
        cancelBtn = UIButton.init(frame: CGRect(x: 0, y:0, width: frame.width, height: 45))
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.backgroundColor = ColorCompatibility.tertiarySystemFill
        cancelBtn.setTitleColor(ColorCompatibility.label, for: .normal)
        cancelBtn.layer.cornerRadius = cancelBtn.frame.height / 4
        cancelBtn.clipsToBounds = true
        
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration.init(pointSize: 22, weight: UIImage.SymbolWeight.black, scale: UIImage.SymbolScale.large)
            photosBtn.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)

        } else {
            // Fallback on earlier versions
        }


        
        stackView.addArrangedSubview(cancelBtn)
        stackView.addArrangedSubview(cameraBtn)
        stackView.addArrangedSubview(photosBtn)
        stackView.addArrangedSubview(removeBtn)
        stackView.addArrangedSubview(cancelBtn)
        
        return stackView
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

extension UIView{
    
    func addBackgroundBlur(blurEffect: UIBlurEffect){
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.insertSubview(blurEffectView, at: 0)
    }
    
    func addViewSpinner(centerX: CGFloat, centerY: CGFloat, width: CGFloat, height: CGFloat){
        
        if let oldSpinner = self.subviews.first(where: {$0.isKind(of: MapSpinnerView.self)}){
            oldSpinner.removeFromSuperview()
        }
        
        let spinner = MapSpinnerView.init(frame: CGRect(x: 0, y: 0, width: width, height: height))

        self.addSubview(spinner)
        spinner.center.x = centerX
        spinner.center.y = centerY
        spinner.animate()
    }
}
