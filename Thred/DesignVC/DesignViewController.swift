//
//  DesignViewController.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-12-25.
//  Copyright © 2019 Thred. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SDWebImage
import ColorCompatibility
import SwiftyDraw
import ColorSlider
import AVKit
import PopupDialog

class AllTemplates{
    var tees = [Template]()
}

var all = AllTemplates()


class LabelFont: NSObject, NSCoding{
    
    
    func encode(with coder: NSCoder) {
        coder.encode(fontName, forKey: "fontName")
        coder.encode(name, forKey: "name")
        coder.encode(textAlignment, forKey: "textAlignment")
        coder.encode(backgroundColor, forKey: "backgroundColor")
        coder.encode(textColor, forKey: "textColor")
    }
    
    required init?(coder: NSCoder) {
        fontName = coder.decodeObject(forKey: "fontName") as? String
        name = coder.decodeObject(forKey: "name") as? String
        //textAlignment =
        let o = NSTextAlignment.left
            
            //(coder.decodeObject(forKey: "textAlignment") as? NSTextAlignment).index
        backgroundColor = coder.decodeObject(forKey: "backgroundColor") as? UIColor
        textColor = coder.decodeObject(forKey: "textColor") as? UIColor
    }
        
    var fontName: String!
    var name: String!
    var textAlignment: NSTextAlignment!
    var backgroundColor: UIColor!
    var textColor: UIColor!
    
    init(font: String?, name: String, textAlignment: NSTextAlignment, backgroundColor: UIColor, textColor: UIColor) {
        self.fontName = font
        self.name = name
        self.textAlignment = textAlignment
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }
    
}

class CanvasDesign: NSObject, NSCoding{
    
    func encode(with coder: NSCoder) {
        drawItems.saveAllObjects(type: "Designs")
        coder.encode(subviews, forKey: "subviews")
        coder.encode(name, forKey: "name")
        coder.encode(currentImage, forKey: "image")
    }
    
    required init?(coder: NSCoder) {
        drawItems = drawItems.getAllObjects(type: "Designs", name: "Designs") ?? []
        subviews = coder.decodeObject(forKey: "subviews") as? [UIView] ?? []
        name = coder.decodeObject(forKey: "name") as? String ?? ""
        currentImage = coder.decodeObject(forKey: "image") as? Data
    }
    
    var drawItems = [SwiftyDraw.SwiftyDrawView.DrawItem]()
    var subviews = [UIView]()
    var name: String!
    var currentImage: Data?
    
    init(drawItems: [SwiftyDraw.SwiftyDrawView.DrawItem], subviews: [UIView], name: String, currentImage: Data?) {
        self.drawItems = drawItems
        self.subviews = subviews
        self.name = name
        self.currentImage = currentImage
    }
}

class DesignViewController: UIViewController, UITextViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, SwiftyDrawViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var displaySideLbl: UILabel!
    var canvasDesigns = [CanvasDesign]()
    @IBOutlet weak var colorDisplayLbl: UILabel!
    
    @IBOutlet weak var colorCollectionBackView: UIView!
    @IBOutlet weak var rotateBtn: UIButton!
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        switch tableView{
        
        case productTypesTableView:
            return all.tees.count
        default:
            return labelFonts.count
        }
    }
    
    var labelFonts: [LabelFont]! =
        [
            LabelFont(font: "bold", name: "Large", textAlignment: .center, backgroundColor: .clear, textColor: .clear),
            LabelFont(font: "normal", name: "Normal", textAlignment: .left, backgroundColor: .clear, textColor: .clear),
            LabelFont(font: "NexaW01-Heavy", name: "Nexa", textAlignment: .center, backgroundColor: .clear, textColor: .clear),
            LabelFont(font: "AguafinaScript-Regular", name: "Fancy", textAlignment: .center, backgroundColor: .clear, textColor: .clear),
            
            
            LabelFont(font: "Vanity", name: "Vanity", textAlignment: .center, backgroundColor: .clear, textColor: .clear),
            LabelFont(font: "xirod", name: "Xirod", textAlignment: .center, backgroundColor: .clear, textColor: .clear),
            LabelFont(font: "fill", name: "Fill", textAlignment: .center, backgroundColor: .clear, textColor: .clear),
            LabelFont(font: "A Alloy Ink", name: "Bubbles", textAlignment: .center, backgroundColor: .clear, textColor: .clear),
            
            
            LabelFont(font: "HOPE-HYPE", name: "Hype", textAlignment: .center, backgroundColor: .clear, textColor: .clear),
            LabelFont(font: "Varsity Team", name: "Varsity", textAlignment: .center, backgroundColor: .clear, textColor: .clear),
            LabelFont(font: "Hey November", name: "Thriller", textAlignment: .center, backgroundColor: .clear, textColor: .clear),
            LabelFont(font: "Hacked", name: "Hacked", textAlignment: .center, backgroundColor: .clear, textColor: .clear),
            
            
            LabelFont(font: "Whoa! 2", name: "Subway", textAlignment: .center, backgroundColor: .clear, textColor: .clear),
            LabelFont(font: "New Waltograph", name: "Story", textAlignment: .center, backgroundColor: .clear, textColor: .clear),
            LabelFont(font: "A Arang", name: "Bangarang", textAlignment: .center, backgroundColor: .clear, textColor: .clear),
            LabelFont(font: "Basic Font", name: "Comic", textAlignment: .center, backgroundColor: .clear, textColor: .clear)
    ]
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch tableView{
        
        case productTypesTableView:
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
            guard all.tees.indices.contains(indexPath.row) else{return cell}
            let product = all.tees[indexPath.row]
            cell.textLabel?.text = product.templateDisplayName
            cell.textLabel?.font = UIFont(name: "NexaW01-Heavy", size: cell.textLabel?.font.pointSize ?? 16)
            cell.backgroundColor = .clear
            return cell
        default:
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
            guard labelFonts.indices.contains(indexPath.row) else{return cell}
            let font = labelFonts[indexPath.row]
            cell.textLabel?.text = font.name.lowercased()
            cell.textLabel?.textColor = .black
            cell.textLabel?.font = UIFont(name: font.fontName, size: 24)
            cell.backgroundColor = .clear
            return cell
        }
    }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch tableView{
        
        case productTypesTableView:
            guard all.tees.indices.contains(indexPath.row) else{return}
            let product = all.tees[indexPath.row]
            selectedProductType = product
            hideList()
        default:
            
            if let textView = self.canvas.subviews.first(where: {$0.isFirstResponder}) as? CanvasTextView, labelFonts.indices.contains(indexPath.row){
                let font = labelFonts[indexPath.row]
                textStyleBtn.setTitle(font.name.uppercased(), for: .normal)
                textView.labelFont = font
                textViewDidChange(textView)
                hideFontTable()
            }
        }
    }
    
    var selectedSide: TemplateSide!{

        didSet{
            if selectedSide.name == "Front"{
                displaySide = .front
            }
            else{
                displaySide = .back
            }
            carousel.collectionView.reloadData()
        }
    }
    
    var displaySide: DisplaySide!{
        didSet{
            if (selectedProductType?.supportedSides.count ?? 0) > 1{
                guard let side = displaySide else{return}
                rotateBtn.superview?.isHidden = false
                print(side)
                rotateBtn.setTitle("\(side)".uppercased(), for: .normal)
            }
            else{
                rotateBtn.superview?.superview?.isHidden = true
            }
        }
    }
    
    
    var selectedProductType: Template!{
        
        willSet{
            
            if selectedProductType?.templateID != newValue?.templateID{
                
                selectedSide = newValue.supportedSides.first(where: {$0.name == "Front"})

                if newValue.category == "Accessories"{
                    var image = self.carousel.currentImage()
                    if newValue?.category != selectedProductType?.category, selectedProductType != nil{
                        image = self.carousel.currentImage()?.rotate(radians: .pi / 2)
                    }
                    self.canvasDisplayView.image = image
                    self.carousel.replaceImageSide(side: selectedSide, with: image, onlyReplaceImage: true)
                    self.selectedView?.imageView?.image = image
                    self.selectedView?.setImage(image, for: .normal)
                }
                else if newValue.category == "Tops"{
                    var image = self.carousel.currentImage()
                    if newValue?.category != selectedProductType?.category, selectedProductType != nil{
                        image = self.carousel.currentImage()?.rotate(radians: -(.pi / 2))
                    }
                    self.canvasDisplayView.image = image
                    self.carousel.replaceImageSide(side: selectedSide, with: image, onlyReplaceImage: true)
                    self.selectedView?.imageView?.image = image
                    self.selectedView?.setImage(image, for: .normal)
                    
                }
                if newValue.supportedSides.contains(where: {$0.name == "Back"}){
                    rotateBtn.superview?.superview?.isHidden = false
                }
                else{
                    canvasDesigns.removeAll(where: {$0.name == "Back"})
                    rotateBtn.superview?.superview?.isHidden = true
                }
            }
            
        }
        
        didSet{
            var title = all.tees.first(where: {$0.templateID == selectedProductType?.templateID})?.templateDisplayName
            if !isEditingProduct{
                title! += " ▾"
            }
            productTypeBtn.titleLabel?.text = title
            productTypeBtn.setTitle(title, for: .normal)
            productTypeBtn.sizeToFit()
            canvasDisplayView.image = nil
            colorCollectionView.reloadData()
            carousel.slides.removeAll()
            
            carousel.setCarouselTemplates(templates: all.tees.filter({$0.templateID == selectedProductType?.templateID}))
            
            carousel.collectionView.reloadData()
            
            DispatchQueue.main.async {
                self.collectionView(self.colorCollectionView, didSelectItemAt: IndexPath(item: 0, section: 0))
                self.colorCollectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .centeredHorizontally)
            }
        }
    }
    
    var cameraBtn: UIButton!
    var photosBtn: UIButton!
    var textBtn: UIButton!
    var drawBtn: UIButton!
    var doneBtn: UIButton!
    @IBOutlet weak var colorCollectionView: UICollectionView!
    
    @IBOutlet weak var thredWatermark: UIStackView!
    
    @IBOutlet weak var saveToPhotosLbl: UIView!
    @IBOutlet weak var scrollview: UIScrollView!
    //@IBOutlet weak var titleView: UITextField!
    @IBOutlet weak var nextBtn: UIButton!
    //@IBOutlet weak var priceView: UITextField!
    //@IBOutlet weak var profitLbl: UILabel!
    
    var currentItemIndex: Int! = 0
    
    
    var product: ProductInProgress!
    var isEditingProduct = false
    var deletingPost = false
    
    override func viewWillLayoutSubviews() {
        barView.roundCorners([.topLeft, .topRight], radius: colorCollectionBackView.frame.height / 4)
        barView.superview?.superview?.clipsToBounds = true
        rotateBtn.superview?.superview?.layer.cornerRadius = (rotateBtn.superview?.frame.height ?? 0) / 2
        rotateBtn.superview?.superview?.clipsToBounds = true
        colorCollectionBackView.roundCorners([.topLeft, .topRight], radius: colorCollectionBackView.frame.height / 4)

    }
    
    override func viewDidLayoutSubviews() {
        barView?.roundCorners([.topLeft, .topRight], radius: colorCollectionBackView.frame.height / 4)
        barView?.clipsToBounds = true
        colorCollectionBackView.roundCorners([.topLeft, .topRight], radius: colorCollectionBackView.frame.height / 4)
    }

    //@IBOutlet weak var deletePostBtn: UIButton!
    
    @IBOutlet weak var publicLbl: UILabel!
    @IBOutlet weak var barView: UIView!

    var isPublic = true
    
    
    
    @IBOutlet weak var productTypeBtn: UIButton!
    
    func hideList(){
        productTypeBtn.isSelected = false
        
        productTypesTableView.isHidden = true
           
    }
    
    func showList(){
        productTypesTableView.isHidden = false
        
        
        productTypesTableView.reloadData()
        productTypeBtn.isSelected = true
    }
    
    @IBAction func showProductList(_ sender: UIButton) {
        
        productTypesTableView.frame = CGRect(x: 0, y: self.view.safeAreaInsets.top, width: self.view.frame.width, height: CGFloat(all.tees.count * 40))
        
        if sender.isSelected{
            hideList()
        }
        else{
            showList()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch tableView{
        case productTypesTableView:
            let num = productTypesTableView.frame.height / CGFloat(all.tees.count)
            print("Height: \(num)")
            return num
        default:
            return 40
        }
    }
    
    lazy var productTypesTableView: UITableView = {
        let tableView = UITableView.init(frame: CGRect(x: 0, y: self.view.safeAreaInsets.top, width: self.view.frame.width, height: CGFloat(all.tees.count * 40)))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.8)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()
    
    
    
    @IBAction func doneDesigning(_ sender: UIButton) {
        
        sender.isEnabled = false
        
        guard checkInternetConnection() else{
            sender.isEnabled = true
            return
        }
        if let indexPath = carousel.collectionView.indexPathsForVisibleItems.first{
            if !(canvasDesigns.filter({$0.currentImage != nil}).isEmpty){
                saveToPhotosLbl.isHidden = true
                product = ProductInProgress()
                
                let designs = canvasDesigns.filter({$0.currentImage != nil})
                
                if designs.contains(where: {$0.name == "Front" && $0.currentImage != nil}){
                    product.displaySide = "\(DisplaySide.front)"
                    selectedSide = selectedProductType.supportedSides.first(where: {$0.name == "Front"})
                }
                else if designs.contains(where: {$0.name == "Back" && $0.currentImage != nil}){
                    product.displaySide = "\(DisplaySide.back)"
                    selectedSide = selectedProductType.supportedSides.first(where: {$0.name == "Back"})
                }
                
                for des in designs{
                    guard let data = des.currentImage, let name = des.name, let side = selectedProductType.supportedSides.first(where: {$0.name == name}) else{continue}
                    let design = Design(img: data, side: side)
                    product.designs.append(design)
                }
                product.uid = pUserInfo.uid
                product.isPublic = isPublic
                product.productType = selectedProductType?.productCode
                product.display = displayView.makeSnapshot(clear: true, subviewsToIgnore: [thredWatermark])?.withBackground(color: UIColor(red: 0.949, green: 0.949, blue: 0.969, alpha: 1.0))?.jpegData(compressionQuality: 0.5)
                product.templateColor = selectedProductType.colors[indexPath.item].code
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    sender.isEnabled = true
                    self.performSegue(withIdentifier: "toInfo", sender: nil)
                }
            }
            else{
                sender.isEnabled = true
            }
        }
        else{
            sender.isEnabled = true
        }
    }
    
    
    func setLeftNavigationItem(image: UIImage?, style: UIBarButtonItem.Style, target: Any?, action: Selector?){
        let item = UIBarButtonItem(image: image, style: style, target: target, action: action)
        navigationItem.setLeftBarButton(item, animated: false)
    }
    
    lazy var carousel: TemplateCarousel! = {
        let carousel = TemplateCarousel(frame: CGRect(x: 0, y: 0, width: displayView.frame.width, height: displayView.frame.height))
        carousel.translatesAutoresizingMaskIntoConstraints = false
        return carousel
    }()
    
    var toolCollectionView: UICollectionView!
    
    lazy var drawToolBar: UIStackView = {
        
        let stack = UIStackView(frame: CGRect(x: 10, y: 5, width: view.frame.width - 20, height: 35))
        
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.spacing = 10
        
        
        toolCollectionView = UICollectionView.init(frame: CGRect(x: 5, y: 0, width: stack.frame.width - stack.frame.height, height: stack.frame.height), collectionViewLayout: DrawToolsLayout())
        toolCollectionView.backgroundColor = .systemBackground
        toolCollectionView.showsHorizontalScrollIndicator = false
        toolCollectionView.alwaysBounceHorizontal = true
        toolCollectionView.alwaysBounceVertical = false
        toolCollectionView.allowsSelection = false
        
        
        toolCollectionView.layer.cornerRadius = toolCollectionView.frame.height / 2
        toolCollectionView.clipsToBounds = true
        
        toolCollectionView.delegate = self
        toolCollectionView.dataSource = self
        
        toolCollectionView.register(UINib(nibName: "DrawToolsCell", bundle: nil), forCellWithReuseIdentifier: "DrawToolsCell")
        
        done = UIButton(frame: CGRect(x: 0, y: 0, width: stack.frame.height, height: stack.frame.height))
        done.addTarget(self, action: #selector(closeDrawCanvas(_:)), for: .touchUpInside)
        done.setTitle("Done", for: .normal)
        done.setTitleColor(.secondaryLabel, for: .normal)
        done.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        stack.addArrangedSubview(toolCollectionView)
        stack.addArrangedSubview(done)
        

        return stack
    }()
    

    
    var undo: UIButton!
    var brushBtn: UIButton!
    var done: UIButton!
    var clear: UIButton!
    var redo: UIButton!
    var slider: ColorSlider!
    
    var garbageBtn: UIButton!
    var activeLbl: CanvasTextView?
    
    func makeMovable(view: UIView){
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleObjectPan(_:)))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleObjectPinch(_:)))
        let rotate = UIRotationGestureRecognizer(target: self, action: #selector(handleObjectRotation(_:)))
        pan.accessibilityLabel = "pan"
        pinch.accessibilityLabel = "pinch"
        rotate.accessibilityLabel = "rotate"
        pan.delegate = self
        pinch.delegate = self
        rotate.delegate = self
        view.addGestureRecognizer(pan)
        view.addGestureRecognizer(pinch)
        view.addGestureRecognizer(rotate)
        view.isUserInteractionEnabled = true
        view.clipsToBounds = true
    }
    
    var viewCenteredY = false
    var viewCenteredX = false
    var angleLocked = false
    var prevTransform: CGAffineTransform!
    
    
    var backgroundView: UIImageView!

    @objc func keyboardWillShow(_ notification: Notification) {

        let bottomPadding = view.safeAreaInsets.bottom
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            if (notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool ?? true){
                let keyboardFrame = keyboardFrame.cgRectValue
                keyboardHeight = keyboardFrame.height
                switch product{
                case .none:
                    if canvas.isHidden{
                        fallthrough
                    }
                    else{
                        configureCanvasLabel()
                    }
                default:
                    UIView.animate(withDuration: 0.2, animations: {
                        if self.scrollview.contentInset.bottom == 0{
                            self.scrollview.contentOffset.y -= self.keyboardHeight - bottomPadding
                        }
                        self.scrollview.contentInset.bottom = self.keyboardHeight - bottomPadding
                        self.scrollview.verticalScrollIndicatorInsets.bottom = self.keyboardHeight - bottomPadding
                    }, completion: { finished in
                        if finished{}
                    })
                }
            }
        }
    }
    
    func configureCanvasLabel(){
        if let textView = canvas.subviews.first(where: {$0.isFirstResponder && $0.isKind(of: UITextView.self)}) as? CanvasTextView{
            for gesture in self.canvas.gestureRecognizers ?? []{
                gesture.isEnabled = false
            }
            if !cameraRollCollectionView.isHidden{
                configurePhotos(self.photosBtn)
            }
            activeLbl = textView
            editingTransform = textView.transform
            editingCenter = textView.center
            if let text = textView.textToStore{
                if !(text.isEmpty){
                    textView.text = text
                }
            }
            textStyleBtn.superview?.isHidden = false
            setTextStyle(textStyleBtn, textView: textView)
            fontSlider.isHidden = false
            textCoverView.isHidden = false
            UIView.animate(withDuration: 0.15, animations: {
                textView.transform = CGAffineTransform.identity
            }, completion: { finished in
                if finished{
                    self.textViewDidChange(textView)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        self.textDoneBtn.isEnabled = true
                        if !self.textCoverView.subviews.contains(self.fontTable){
                            self.textCoverView.addSubview(self.fontTable)
                            self.fontTable.isHidden = true
                        }
                    }
                    if let textStyleView = self.textStyleBtn.superview{
                        self.canvas.bringSubviewToFront(self.textCoverView)
                        self.canvas.bringSubviewToFront(textStyleView)
                        self.canvas.bringSubviewToFront(self.fontSlider)
                        self.canvas.bringSubviewToFront(textView)
                    }
                    textView.center.x = self.canvas.center.x
                    if let imageView = textView.subviews.first(where: {$0.isKind(of: UIImageView.self)}) as? UIImageView{
                        imageView.isHidden = true
                    }
                    for gesture in textView.gestureRecognizers ?? []{
                        if gesture.accessibilityLabel == "pan" || gesture.accessibilityLabel == "pinch" || gesture.accessibilityLabel == "rotate"{
                            gesture.isEnabled = false
                        }
                    }
                }
            })
        }
    }
    
    var textSlider: ColorSlider!
    var shadowBtn: UIButton!
    
    var textDoneBtn: UIButton!
    
    lazy var textToolBar: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: canvas.frame.width, height: 45))
        view.backgroundColor = .black
        
        let stack = UIStackView.init(frame: CGRect(x: 20, y: 10, width: view.frame.width - 40, height: view.frame.height - 20))
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.spacing = 20
        
        textSlider = ColorSlider(orientation: .horizontal, previewSide: .top)
        textSlider.gradientView.layer.borderColor = UIColor(named: "LoadingColor")?.cgColor
        textSlider.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        textSlider.color = .white
        
        textDoneBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 90, height: 45))
        textDoneBtn.setTitle("Done", for: .normal)
        textDoneBtn.setTitleColor(UIColor(named: "LoadingColor"), for: .normal)
        textDoneBtn.addTarget(self, action: #selector(doneLabelTyping(_:)), for: .touchUpInside)
        
        shadowBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
        shadowBtn.setImage(UIImage(nameOrSystemName: "rectangle.on.rectangle", systemPointSize: 22, iconSize: 7), for: .normal)

        shadowBtn.tintColor = UIColor(named: "LoadingColor")
        shadowBtn.addTarget(self, action: #selector(configureTextShadow(_:)), for: .touchUpInside)
        
        stack.addArrangedSubview(shadowBtn)
        stack.addArrangedSubview(textSlider)
        stack.addArrangedSubview(textDoneBtn)
        
        view.addSubview(stack)
        
        return view
    }()
    
    
    
    
    @objc func keyboardWillHide(_ notification: Notification) {
        
        if (notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool ?? true){
            UIView.animate(withDuration: 0.2, animations: {
                self.bottomBar.transform = CGAffineTransform.identity
                self.scrollview.contentInset.bottom = 0
                self.scrollview.verticalScrollIndicatorInsets.bottom = 0
            })
        }
    }

    
    var textEditInfo = [[String: Any]]()
    var editingTransform: CGAffineTransform!
    var editingCenter: CGPoint!
    var keyboardHeight: CGFloat!

    
    
    func textViewDidChange(_ textView: UITextView) {

            let size = textView.sizeThatFits(CGSize(width: canvas.frame.width, height: CGFloat.greatestFiniteMagnitude))
            textView.center.x = canvas.center.x
            if keyboardHeight != nil{
                (textView as? CanvasTextView)?.textToStore = textView.text
                UIView.animate(withDuration: 0.1, animations: {
                    let resizedY = (self.view.frame.height - self.keyboardHeight - size.height) - self.view.safeAreaInsets.top
                    
                    if let textStyleView = self.textStyleBtn.superview{
                        let minY = textStyleView.frame.maxY + 10
                        let bottomInset = self.view.safeAreaInsets.bottom
                        
                        if resizedY <= minY{
                            textView.isScrollEnabled = true
                            textView.frame.origin.y = minY
                            
                            let p1 = self.view.frame.maxY - self.keyboardHeight - self.textToolBar.frame.height - 10
                            let maxY = p1 - bottomInset - 10
                            
                            textView.frame.size.height = maxY - minY
                          
                            if textView.text.count > 250{
                                    textView.text.removeLast(textView.text.count - 250)
                            }
                        }
                        else{
                            textView.isScrollEnabled = false
                            textView.frame.size = size
                            textView.frame.size.width = self.canvas.frame.width
                            textView.frame.origin.y = resizedY
                        }
                    }
                })
            }
    }
        
    @IBOutlet weak var displayView: UIView!
    
    
    
    lazy var cameraView: CameraView = {
        let cameraView = CameraView.init(frame: CGRect(x: 0, y: bottomBar.frame.maxY, width: view.frame.width, height: view.frame.height))
        cameraView.bottomBar.frame.size.height = cameraView.bottomBar.frame.height + view.safeAreaInsets.bottom
        cameraView.bottomBar.frame.origin.y = cameraView.frame.height - (cameraView.bottomBar.frame.height)
        cameraView.dismissBtn.addTarget(self, action: #selector(closeCamera(_:)), for: .touchUpInside)
        view.addSubview(cameraView)
        return cameraView
        
    }()
    
    var aspectRatio: CGFloat = 1
    var drawCanvas: SwiftyDrawView!
    var textStyleBtn: UIButton!
    
    lazy var canvasDisplayView: UIImageView = {
        let stack = displayView.superview?.superview as! UIStackView
        let x = displayView.frame.width / 3
        let y = stack.spacing + displayView.frame.height / 4
        let width = displayView.frame.width / 4
        let height = (displayView.frame.height - displayView.frame.height / 2) - 50
        let view = UIImageView(frame: CGRect(x: x, y: y, width: width, height: height))
        view.center.x = displayView.center.x
        view.isUserInteractionEnabled = true
        view.isHidden = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    var textCoverView: UIView!
    var defaultFontSize = 55
        
    
    
    var exitTapper: UITapGestureRecognizer!
    
    var midXLine: UIView!
    var midYLine: UIView!
    var angleLine: UIView!
    var lineTypeView: UIView!
    var alignmentCanvas: UIView!
    
    
    var lastTextView: CanvasTextView!
    

     
    
    
    lazy var canvas: UIView = {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height * aspectRatio))
        view.isUserInteractionEnabled = true
        let color = all.tees.first(where: {$0.templateID == selectedProductType?.templateID})?.colors[currentItemIndex].getColor()

        view.backgroundColor = color
        view.clipsToBounds = true
        let tapper = UITapGestureRecognizer(target: self, action: #selector(addLabel(_:)))
        tapper.delegate = self
        view.addGestureRecognizer(tapper)
        exitTapper = UITapGestureRecognizer(target: self, action: #selector(exitPhotosTap(_:)))
        view.addGestureRecognizer(exitTapper)
        exitTapper.isEnabled = false
        drawCanvas = SwiftyDrawView.init(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        drawCanvas.delegate = self
        drawCanvas.isEnabled = false
        drawCanvas.brush = .medium
        drawCanvas.brush.color = Color(.cyan)
        drawCanvas.isUserInteractionEnabled = false
        drawCanvas.addSubview(brushCircle)
        brushCircle.isHidden = true
        let gesture = UIPinchGestureRecognizer(target: self, action: #selector(changeBrushSize(_:)))
        drawCanvas.addGestureRecognizer(gesture)
        
        slider = ColorSlider(orientation: .vertical, previewSide: .right)
        slider.frame = CGRect(x: 10, y: 10, width: 15, height: 250)
        slider.gradientView.layer.borderColor = UIColor(named: "LoadingColor")?.cgColor
        slider.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        slider.color = .cyan
        drawCanvas.addSubview(slider)
        slider.isHidden = true
        
        lineTypeView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let lineImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: lineTypeView.frame.width, height: lineTypeView.frame.height))
        lineImageView.image = UIImage(named: "scribble.mode")
        lineTypeView.center = drawCanvas.center
        lineImageView.frame.origin = CGPoint.zero
        lineTypeView.addSubview(lineImageView)
        
        
        
        if #available(iOS 13.0, *) {
            lineTypeView.addBackgroundBlur(blurEffect: UIBlurEffect(style: UIBlurEffect.Style.systemUltraThinMaterial))
        } else {
            lineTypeView.addBackgroundBlur(blurEffect: UIBlurEffect(style: UIBlurEffect.Style.regular))
        }
        
 
        
        lineTypeView.tintColor = UIColor.cyan
        lineTypeView.layer.cornerRadius = lineTypeView.frame.height / 8
        lineTypeView.clipsToBounds = true
        drawCanvas.addSubview(lineTypeView)
        
        
        let lineWidth: CGFloat = 1
        midXLine = UIView.init(frame: CGRect(x: 0, y: 0, width: lineWidth, height: view.frame.height))
        midXLine.center.x = view.center.x
        midXLine.backgroundColor = .systemYellow
        midXLine.setRadiusWithShadow()
        midXLine.isHidden = true
        midYLine = UIView.init(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: lineWidth))
        midYLine.center.y = view.center.y
        midYLine.backgroundColor = .systemYellow
        midYLine.setRadiusWithShadow()
        midYLine.isHidden = true
        angleLine = UIView.init(frame: CGRect(x: 0, y: 0, width: lineWidth, height: view.frame.height * 2))
        angleLine.backgroundColor = .systemRed
        angleLine.setRadiusWithShadow()
        angleLine.isHidden = true
        garbageBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        garbageBtn.center.x = view.center.x
        garbageBtn.center.y = (view.frame.maxY) - (garbageBtn.frame.height / 2) - 10
        garbageBtn.setRadiusWithShadow()
        garbageBtn.tintColor = UIColor(named: "LoadingColor")
        garbageBtn.isUserInteractionEnabled = false
        
        garbageBtn.setImage(UIImage(nameOrSystemName: "trash.circle", systemPointSize: 30, iconSize: 7), for: .normal)
        let backView = UIView(frame: CGRect(x: 10, y: 10, width: 160, height: 30))
        backView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backView.layer.borderColor = UIColor(named: "LoadingColor")?.cgColor
        backView.layer.borderWidth = 3
        backView.layer.cornerRadius = backView.frame.height / 2
        backView.clipsToBounds = true
        textStyleBtn = UIButton.init(frame: CGRect(x: 5, y: 5, width: backView.frame.width - 10, height: backView.frame.height - 10))
        textStyleBtn.setTitle("Large", for: .normal)
        textStyleBtn.setTitleColor(UIColor(named: "LoadingColor"), for: .normal)
        textStyleBtn.titleLabel?.minimumScaleFactor = 0.5
        textStyleBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        textStyleBtn.addTarget(self, action: #selector(changeTextStyle(_:)), for: .touchUpInside)
        textStyleBtn.showsTouchWhenHighlighted = true
        backView.addSubview(textStyleBtn)
        textCoverView = UIView.init(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        let textTapper = UITapGestureRecognizer(target: self, action: #selector(doneLabelTyping(_:)))
        textCoverView.addGestureRecognizer(textTapper)
        textCoverView.backgroundColor = UIColor.black.withAlphaComponent(0.75)

        fontSlider = UISlider(frame: CGRect(x: backView.frame.maxX + 10, y: 10, width: view.frame.width - 10 - backView.frame.width - 10 - 10, height: 30))
        fontSlider.minimumValue = 20
        fontSlider.maximumValue = Float(defaultFontSize)
        fontSlider.value = Float(defaultFontSize)
        fontSlider.maximumTrackTintColor = UIColor(named: "LoadingColor")
        fontSlider.minimumTrackTintColor = UIColor(named: "LoadingColor")
        fontSlider.addTarget(self, action: #selector(resizeFont(_:)), for: .valueChanged)
        
        alignmentCanvas = UIView(frame: view.bounds)
        alignmentCanvas.isUserInteractionEnabled = false
        alignmentCanvas.addSubview(midXLine)
        alignmentCanvas.addSubview(midYLine)
        alignmentCanvas.addSubview(angleLine)
        
        
        view.addSubview(garbageBtn)
        view.addSubview(textCoverView)
        view.addSubview(backView)
        view.addSubview(fontSlider)
        view.addSubview(drawCanvas)
        view.addSubview(alignmentCanvas)
        return view
    }()
    
    lazy var fontTable: UITableView = {
        
        let bottomY = self.view.convert(textToolBar.frame, from: textToolBar).minY + 10
        let topY = self.view.convert(textStyleBtn.superview!.frame, from: textStyleBtn.superview!).maxY + 10
        let tableView = UITableView(frame: CGRect(x: textStyleBtn.superview?.frame.minX ?? 0, y: (textStyleBtn.superview?.frame.maxY ?? 0) + 10, width: 160, height: bottomY - topY), style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.white.withAlphaComponent(0.75)
        tableView.layer.cornerRadius = 6
        tableView.clipsToBounds = true
        tableView.reloadData()
        return tableView
    }()
    
    lazy var brushCircle: UIView = {
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: drawCanvas.brush.originalWidth, height: drawCanvas.brush.originalWidth))
        view.backgroundColor = .white
        view.layer.cornerRadius = view.frame.height / 2
        view.clipsToBounds = true
        view.layer.borderColor = UIColor.systemFill.cgColor
        view.layer.borderWidth = 1.5
        view.setRadiusWithShadow()

        return view
    }()
    
    var fontSlider: UISlider!
    
    
    var currentFontSize: CGFloat!
     
    var selectedView: UIButton!
    
    lazy var bottomSafeAreaView: UIView = {
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: bottomBar.frame.width, height: 0))
        view.backgroundColor = bottomBar.backgroundColor
        return view
    }()

    
    lazy var cameraRollCollectionView: PhotosView = {
        
        let y = view.frame.midY
        let collectionView = PhotosView.init(frame: CGRect(x: 0, y: view.frame.height - y, width: view.frame.width, height: y))
        
        view.addSubview(collectionView)
        collectionView.isHidden = true

        return collectionView
    }()
    
    
    
    
    lazy var bottomBar: UIView = {
        
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 45))
        view.backgroundColor = .secondarySystemBackground
        
        let stackView = UIStackView.init(frame: view.frame)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        
        view.addSubview(stackView)
        
        cameraBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: view.frame.height, height: view.frame.height))
        cameraBtn.tintColor = UIColor(named: "LoadingColor")
        cameraBtn.addTarget(self, action: #selector(openCamera(_:)), for: .touchUpInside)
        
        photosBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: view.frame.height, height: view.frame.height))
        photosBtn.tintColor = UIColor(named: "LoadingColor")
        photosBtn.addTarget(self, action: #selector(configurePhotos(_:)), for: .touchUpInside)
        
        textBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: view.frame.height, height: view.frame.height))
        textBtn.tintColor = UIColor(named: "LoadingColor")
        textBtn.addTarget(self, action: #selector(addLabel(_:)), for: .touchUpInside)
        
        
        drawBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: view.frame.height, height: view.frame.height))
        drawBtn.tintColor = UIColor(named: "LoadingColor")
        drawBtn.addTarget(self, action: #selector(openDrawCanvas(_:)), for: .touchUpInside)
        

        doneBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: view.frame.height, height: view.frame.height))
        doneBtn.setTitle("Done", for: .normal)
        doneBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        doneBtn.setTitleColor(UIColor(named: "LoadingColor")?.withAlphaComponent(0.5), for: .disabled)
        doneBtn.setTitleColor(UIColor(named: "LoadingColor"), for: .normal)
        doneBtn.addTarget(self, action: #selector(minimizeDrawingArea(_:)), for: .touchUpInside)

        cameraBtn.setImage(UIImage(nameOrSystemName: "camera.fill", systemPointSize: 20, iconSize: 9), for: .normal)
        photosBtn.setImage(UIImage(nameOrSystemName: "photo.fill", systemPointSize: 20, iconSize: 9), for: .normal)
        textBtn.setImage(UIImage(nameOrSystemName: "textbox", systemPointSize: 20, iconSize: 9), for: .normal)
        drawBtn.setImage(UIImage(nameOrSystemName: "scribble", systemPointSize: 20, iconSize: 9), for: .normal)

        
        stackView.addArrangedSubview(cameraBtn)
        stackView.addArrangedSubview(photosBtn)
        stackView.addArrangedSubview(textBtn)
        stackView.addArrangedSubview(drawBtn)
        stackView.addArrangedSubview(doneBtn)
        
        
        return view
    }()
    
    var tools = [
        
        [
            "Name" : "Pen",
            "Icon_Color" : UIColor(named: "LoadingColor")!,
            "Image" : UIImage(nameOrSystemName: "pencil.circle", systemPointSize: 25, iconSize: 9)!,
        ],
        
        [
            "Name" : "Ruler",
            "Icon_Color" : UIColor(named: "LoadingColor")!,
            "Image" : UIImage(named: "scribble.mode")!
        ],
        
        [
            "Name" : "Pen_Color",
            "Icon_Color" : UIColor.cyan,
            "Image" : UIImage(nameOrSystemName: "largecircle.fill.circle", systemPointSize: 25, iconSize: 9)!,
        ],
        
        [
            "Name" : "Undo",
            "Icon_Color" : UIColor(named: "LoadingColor")!,
            "Image" : UIImage(nameOrSystemName: "arrow.uturn.left.circle", systemPointSize: 25, iconSize: 9)!,
        ],
        
        [
            "Name" : "Redo",
            "Icon_Color" : UIColor(named: "LoadingColor")!,
            "Image" : UIImage(nameOrSystemName: "arrow.uturn.right.circle", systemPointSize: 25, iconSize: 9)!,
        ],
        
        /*
        [
            "Name" : "Dropper",
            "Icon_Color" : UIColor(named: "LoadingColor")!,
            "Image" : UIImage(nameOrSystemName: "eyedropper.halffull", systemPointSize: 25, iconSize: 9)!,
        ],
        */
        [
            "Name" : "Clear",
            "Icon_Color" : UIColor(named: "LoadingColor")!,
            "Image" : UIImage(nameOrSystemName: "xmark.circle", systemPointSize: 25, iconSize: 9)!,
        ]
    ]
    
    func showClearMessage(){
        let message = "Are you sure you want to clear your drawing?"
        let yesBtn = DefaultButton(title: "YES", dismissOnTap: true) {
            self.drawCanvas.clear()
        }
        let cancelBtn = DefaultButton(title: "NEVER MIND", dismissOnTap: true) {
        }
        
        showPopUp(title: nil, message: message, image: nil, buttons: [yesBtn, cancelBtn], titleColor: .label, blurBack: true)
    }
    
    func clearDrawing(){
        
        if drawCanvas.drawItems.count >= 3{
            showClearMessage()
        }
        else{
            drawCanvas.clear()
        }
    }
    
    func redoColors(){
        drawCanvas.redo()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == toolCollectionView{
            print(tools.count)
            return tools.count
        }
                
        return all.tees.first(where: {$0.templateID == selectedProductType?.templateID})?.colors.count ?? 0
        
    }
    
    func updateToolIcons(tool: inout [String : Any]){
        if (tool["Name"] as? String) == "Ruler"{
            switch drawCanvas.drawMode{
            case .draw:
                tool["Image"] = UIImage(named: "scribble.mode")
            case .line:
                tool["Image"] = UIImage(named: "straight.mode")
            case .ellipse:
                tool["Image"] = UIImage(systemName: "circle")
            case .rect:
                tool["Image"] = UIImage(systemName: "rectangle")
            }
        }
        else if tool["Name"] as? String == "Pen"{
            if drawCanvas.brush.blendMode == .clear{
                tool["Image"] = UIImage(named: "eraser")
            }
            else{
                tool["Image"] = UIImage(nameOrSystemName: "pencil.circle", systemPointSize: 25, iconSize: 9)
            }
        }
        else if tool["Name"] as? String == "Pen_Color"{
            if slider.isHidden{
                tool["Icon_Color"] = slider.color
            }
            else{
                tool["Icon_Color"] = slider.color.withAlphaComponent(0.5)
            }
        }
    }
    
    func showOrHideSlider(_ sender: UIButton?){
        if slider.isHidden{
            self.slider.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                self.slider.transform = CGAffineTransform.identity
            })
            if let sender = sender{
                sender.tintColor = slider.color.withAlphaComponent(0.5)
            }
            else if let index = tools.firstIndex(where: {$0["Name"] as? String == "Pen_Color"}){
                tools[index]["Icon_Color"] = slider.color.withAlphaComponent(0.5)
                if let cell = toolCollectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? DrawToolsCell{
                    cell.toolBtn.tintColor = slider.color.withAlphaComponent(0.5)
                }
            }
            
        }
        else{
            UIView.animate(withDuration: 0.2, animations: {
                self.slider.transform = CGAffineTransform(translationX: -(self.slider.frame.minX + self.slider.frame.width), y: 0)
            }, completion: { finished in
                if finished{
                    self.slider.isHidden = true
                }
            })
            if let sender = sender{
                sender.tintColor = slider.color
            }
            else if let index = tools.firstIndex(where: {$0["Name"] as? String == "Pen_Color"}){
                tools[index]["Icon_Color"] = slider.color
                if let cell = toolCollectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? DrawToolsCell{
                    cell.toolBtn.tintColor = slider.color
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == toolCollectionView{
            var tool = self.tools[indexPath.item]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DrawToolsCell", for: indexPath) as? DrawToolsCell
            cell?.vc = self
            updateToolIcons(tool: &tool)
            cell?.tool = tool
            return cell!
        }
        else{
            let colorInfo = all.tees.first(where: {$0.templateID == selectedProductType?.templateID})?.colors[indexPath.item]
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "color_icon", for: indexPath) as? TemplateColorChooserCell
            cell?.colorView.backgroundColor = nil
            cell?.isSelected = false
            
            if let index = carousel.collectionView.indexPathsForVisibleItems.first, index.item == indexPath.item{
                cell?.isSelected = true
            }
            
            cell?.setShape()
            
            
            cell?.colorView.backgroundColor = colorInfo?.getColor()
            
            
            return cell!
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        guard scrollView == carousel?.collectionView else{return}

        let x = scrollView.contentOffset.x
        let w = scrollView.bounds.size.width
        let currentPage = Int(ceil(x/w))
        guard let collectionView = colorCollectionView else{return}
        if all.tees.first(where: {$0.templateID == selectedProductType.templateID})?.colors.indices.contains(currentPage) ?? false{
            collectionView.selectItem(at: IndexPath(item: currentPage, section: 0), animated: true, scrollPosition: .centeredHorizontally)
            DispatchQueue.main.async {
                if let item = collectionView.indexPathsForSelectedItems?.first(where: {$0.item != currentPage}){
                    collectionView.deselectItem(at: item, animated: false)
                }
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == carousel?.collectionView else{return}
        let x = scrollView.contentOffset.x
        let w = scrollView.bounds.size.width
        let currentPage = Int(ceil(x/w))
        guard let collectionView = colorCollectionView else{return}
        if all.tees.first(where: {$0.templateID == selectedProductType.templateID})?.colors.indices.contains(currentPage) ?? false{
            collectionView.selectItem(at: IndexPath(item: currentPage, section: 0), animated: true, scrollPosition: .centeredHorizontally)
            DispatchQueue.main.async {
                if let item = collectionView.indexPathsForSelectedItems?.first(where: {$0.item != currentPage}){
                    collectionView.deselectItem(at: item, animated: false)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if colorCollectionView.indexPathsForSelectedItems?.first == indexPath, let cell = carousel.collectionView.cellForItem(at: indexPath) as? CarouselCollectionViewCell, let displayView = cell.canvasDisplayViews.first{
            
            maximiseDrawingArea(displayView: displayView)
            
            return false
        }
        return true
    }
     
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        
        carousel.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        colorCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        
    }
    
    
    func setCarouselConstraints(){
        NSLayoutConstraint(item: carousel!, attribute: .top, relatedBy: .equal, toItem: displayView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: carousel!, attribute: .bottom, relatedBy: .equal, toItem: displayView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: carousel!, attribute: .left, relatedBy: .equal, toItem: displayView, attribute: .left, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: carousel!, attribute: .right, relatedBy: .equal, toItem: displayView, attribute: .right, multiplier: 1.0, constant: 0).isActive = true
    }
   
    


    
    @IBOutlet weak var saveBtn: UIButton!
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {

        if collectionView == colorCollectionView{
            let leftInset = (collectionView.frame.width / 2) - ((collectionView.frame.width / 3) / 2)
            let rightInset = leftInset

            return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
        }
        else{
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
   
    
    @IBAction func displaySideChanged(_ sender: UIButton?) {

        if selectedSide.name == "Front"{
            selectedSide = selectedProductType.supportedSides.first(where: {$0.name == "Back"})
        }
        else{
            selectedSide = selectedProductType.supportedSides.first(where: {$0.name == "Front"})
        }
    }
    

    
    
    var editingTees = [Template]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        colorCollectionView.delegate = self
        colorCollectionView.dataSource = self
        colorCollectionView.decelerationRate = .fast
        
        
        //canvasDesigns = canvasDesigns.getAllObjects(type: "", name: "") ?? []
        
        
        print(canvasDesigns.compactMap({$0.drawItems}))
        print(canvasDesigns.compactMap({$0.subviews}))

        saveBtn.addTarget(self, action: #selector(showSaveView(_:)), for: .touchDown)
        saveBtn.addTarget(self, action: #selector(showSaveView(_:)), for: .touchDragEnter)
        saveBtn.addTarget(self, action: #selector(hideSaveView(_:)), for: .touchDragOutside)
        saveBtn.adjustsImageWhenDisabled = false

        saveToPhotosLbl.layer.cornerRadius = saveToPhotosLbl.frame.height / 2
        saveToPhotosLbl.clipsToBounds = true
        saveToPhotosLbl.isHidden = true
        
        nextBtn.layer.cornerRadius = nextBtn.frame.height / 2
        nextBtn.clipsToBounds = true
        nextBtn.adjustsImageWhenDisabled = true
        
        colorDisplayLbl.superview?.layer.cornerRadius = (colorDisplayLbl.superview?.frame.height ?? 0) / 2
        colorDisplayLbl.superview?.clipsToBounds = true
        
        
        navigationController?.navigationBar.setBackgroundImage(UIImage.init(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage.init()
        
        displayView.addSubview(carousel)
        displayView.bringSubviewToFront(thredWatermark)
        setCarouselConstraints()
        
        setLeftNavigationItem(image: UIImage(nameOrSystemName: "xmark", systemPointSize: 18, iconSize: 9), style: .plain, target: self, action: #selector(cancelDesigning(_:)))
        setKeyBoardNotifs()
        
        let spinner = MapSpinnerView.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        displayView.addSubview(spinner)
        spinner.center.x = view.center.x
        spinner.center.y = displayView.center.y
        spinner.animate()
        
        loadDesigns(){
            
            DispatchQueue.main.async {
                spinner.removeFromSuperview()
                self.colorCollectionView.reloadData()
                DispatchQueue.main.async {
                    self.colorCollectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .centeredHorizontally)
                }
                
                self.carousel.setCarouselTemplates(templates: all.tees)
                                
                
                if !self.scrollview.subviews.contains(self.canvasDisplayView){
                    self.scrollview.addSubview(self.canvasDisplayView)
                }
                if !self.view.subviews.contains(self.canvas){
                    self.view.addSubview(self.canvas)
                    
                }
                self.canvas.isHidden = true

                if !self.view.subviews.contains(self.bottomBar){
                    self.view.addSubview(self.bottomBar)
                    self.bottomBar.isHidden = true
                }
                if !self.view.subviews.contains(self.bottomSafeAreaView){
                    self.view.addSubview(self.bottomSafeAreaView)
                    self.bottomSafeAreaView.isHidden = true
                }
                if !self.bottomBar.subviews.contains(self.drawToolBar){
                    self.bottomBar.addSubview(self.drawToolBar)
                    self.drawToolBar.isHidden = true
                    self.toolCollectionView.reloadData()
                }
                if !self.view.subviews.contains(self.canvasImageView){
                    self.view.addSubview(self.canvasImageView)
                    self.canvasImageView.isHidden = true
                }
                if !self.view.subviews.contains(self.productTypesTableView){
                    self.view.addSubview(self.productTypesTableView)
                    self.productTypesTableView.isHidden = true
                    self.selectedProductType = all.tees.first
                    //self.priceView.text = self.formattedMinPrice()
                }
                if !(self.displayView.superview?.subviews.contains(self.zoomBtn) ?? false){
                    self.displayView.superview?.addSubview(self.zoomBtn)
                    self.zoomBtn.frame.origin = CGPoint(x: 5, y: self.displayView.frame.maxY - self.zoomBtn.frame.height - 5)
                }
                if !self.view.subviews.contains(self.zoomableView){
                    self.view.addSubview(self.zoomableView)
                    self.zoomableView.isHidden = true
                }
            }
        }
    }
    
    func hideNextBtn(){
        UIView.animate(withDuration: 0.2, animations: {
            self.nextBtn.alpha = 0.0
            self.nextBtn.isUserInteractionEnabled = false
        }, completion: nil)
    }
    
    func showNextBtn(){
        
        UIView.animate(withDuration: 0.2, animations: {
            self.nextBtn.alpha = 1.0
            self.nextBtn.isUserInteractionEnabled = true
        }, completion: nil)
    }
    
    
    
    func checkIfCardSet() -> Bool{
                
        if UserDefaults.standard.string(forKey: "CARD_BRAND") != nil, UserDefaults.standard.string(forKey: "CARD_LAST_4") != nil, UserDefaults.standard.string(forKey: "CARD_POSTAL_CODE") != nil{
            return true
        }
        return false
    }
    
    lazy var canvasImageView: UIImageView = {
        let imageView = UIImageView(frame: canvas.frame)
        return imageView
    }()
    
    func cannotPost() -> Bool{
        guard let indexPath = carousel.collectionView.indexPathsForVisibleItems.first, let cell = carousel.collectionView.cellForItem(at: indexPath) as? CarouselCollectionViewCell else {return true}
        return cell.canvasDisplayViews.filter({$0.image(for: .normal) != nil}).isEmpty
    }
    
    
    func showCancelMessage(completed: @escaping () -> ()){
        
        
//
        guard let indexPath = carousel.collectionView.indexPathsForVisibleItems.first, let cell = carousel.collectionView.cellForItem(at: indexPath) as? CarouselCollectionViewCell, !(        cell.canvasDisplayViews.filter({$0.image(for: .normal) != nil}).isEmpty)
        else{
            completed()
            return
        }

        let message = "Are you sure you want to abandon your Thred-in-progress?"
        let yesBtn = DefaultButton(title: "YES", dismissOnTap: true) {
            completed()
        }
        let cancelBtn = DefaultButton(title: "NEVER MIND", dismissOnTap: true) {
        }
            
        let image = displayView.makeSnapshot(clear: true, subviewsToIgnore: [thredWatermark])
        showPopUp(title: nil, message: message, image: image, buttons: [yesBtn, cancelBtn], titleColor: .label, blurBack: true)
 
    }
    
    @objc func cancelDesigning(_ sender: UIBarButtonItem){
        
        showCancelMessage{
            self.product = nil
            self.performSegue(withIdentifier: "DoneDesigning", sender: nil)
        }
    }
    
    lazy var zoomableView: UIView = {
        let view = UIView.init(frame: self.view.frame)
        view.backgroundColor = displayView.backgroundColor?.withAlphaComponent(0.95)
        let tapper = UITapGestureRecognizer.init(target: self, action: #selector(hideZoomableView(_:)))
        view.addGestureRecognizer(tapper)
        
        let imageView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.width))
        imageView.center = view.center
        imageView.isUserInteractionEnabled = true
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleZoom(_:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        pan.delegate = self
        pinch.delegate = self
        imageView.addGestureRecognizer(pinch)
        imageView.addGestureRecognizer(pan)
        view.addSubview(imageView)
        let doneZoomingBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 20))
        doneZoomingBtn.setImage(UIImage(nameOrSystemName: "xmark", systemPointSize: 18, iconSize: 9), for: .normal)
        doneZoomingBtn.tintColor = UIColor(named: "LoadingColor")
        doneZoomingBtn.frame.origin.y = self.view.safeAreaInsets.top - doneZoomingBtn.frame.height
        doneZoomingBtn.addTarget(self, action: #selector(hideZoomableView(_:)), for: .touchUpInside)
        view.addSubview(doneZoomingBtn)
        return view
    }()
    
    
    
    lazy var zoomBtn: UIButton = {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
        btn.setImage(UIImage(nameOrSystemName: "doc.text.magnifyingglass", systemPointSize: 18, iconSize: 9), for: .normal)
        btn.tintColor = UIColor(named: "LoadingColor")
        btn.addTarget(self, action: #selector(showZoomableView(_:)), for: .touchUpInside)
        return btn
    }()
    

    func setKeyBoardNotifs(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
   
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let infoVC = segue.destination as? DesignInfoViewController{
            infoVC.product = product
        }
    }
}

extension UIView {
    func makeSnapshot(clear: Bool, subviewsToIgnore: [UIView]) -> UIImage? {
        
        let color = backgroundColor
        if clear{
            backgroundColor = .clear
        }
        
        for view in subviewsToIgnore{
            view.isHidden = true
        }
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        let image = renderer.image { ctx in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
        backgroundColor = color
        
        for view in subviewsToIgnore{
            view.isHidden = false
        }
        return image
    }
}

extension UIImage {
/// Returns a system image on iOS 13, otherwise returns an image from the Bundle provided.
/// Icon Sizes: 3 (light), 5 (medium), 7 (bold), 8 (heavy), 9 (black)
 
    convenience init?(nameOrSystemName: String, systemPointSize: CGFloat?, iconSize: Int?, in bundle: Bundle? = Bundle.main, compatibleWith traitCollection: UITraitCollection? = nil) {
        if #available(iOS 13, *) {
            self.init(systemName: nameOrSystemName, withConfiguration: UIImage.SymbolConfiguration.init(pointSize: systemPointSize ?? 20, weight: UIImage.SymbolWeight(rawValue: iconSize ?? 9) ?? UIImage.SymbolWeight.heavy, scale: UIImage.SymbolScale.large))
        } else {
            self.init(named: nameOrSystemName, in: bundle, compatibleWith: traitCollection)
        }
    }
}


extension UIViewController {

    /**
     *  Height of status bar + navigation bar (if navigation bar exist)
     */

    var topbarHeight: CGFloat {
        if #available(iOS 13.0, *) {
            return (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0) +
                (self.navigationController?.navigationBar.frame.height ?? 0.0)
        } else {
            return UIApplication.shared.statusBarFrame.height + (self.navigationController?.navigationBar.frame.height ?? 0.0)
        }
    }
}

class CanvasTextView: UITextView {

    var textToStore: String!
    
    var currentFontSize: CGFloat!{
        didSet{
            font = font?.withSize(currentFontSize)
        }
    }
    var defaultFontSize: Int!{
        didSet{
            currentFontSize = CGFloat(defaultFontSize)
        }
    }
    var color: UIColor!{
        didSet{
            if labelFont?.fontName == "fill"{
                determineFillColor()
            }
            else{
                textColor = color
            }
        }
    }
    
    var labelFont: LabelFont!{
        
        didSet{
            switch labelFont.fontName {

            case "bold":
                self.font = UIFont.boldSystemFont(ofSize: currentFontSize ?? CGFloat(defaultFontSize))
                self.textColor = color
                self.backgroundColor = labelFont.backgroundColor
                self.textAlignment = labelFont.textAlignment

            case "normal":
                self.font = UIFont.systemFont(ofSize: currentFontSize ?? CGFloat(defaultFontSize))
                self.textColor = color
                self.backgroundColor = labelFont.backgroundColor
                self.textAlignment = labelFont.textAlignment

            case "fill":
                self.font = UIFont.boldSystemFont(ofSize: currentFontSize ?? CGFloat(defaultFontSize))
                determineFillColor()
            default:
                self.font = UIFont(name: labelFont.fontName, size: currentFontSize ?? CGFloat(defaultFontSize))
                self.textColor = color
                self.backgroundColor = labelFont.backgroundColor
                self.textAlignment = labelFont.textAlignment
            }
        }
    }
    
    func determineFillColor(){
        if color == UIColor(red: 1, green: 1, blue: 1, alpha: 1){
            self.textColor = .black
        }
        else{
            self.textColor = .white
        }
        self.backgroundColor = color
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(textToStore, forKey: "textToStore")
        coder.encode(currentFontSize, forKey: "currentFontSize")
        coder.encode(defaultFontSize, forKey: "defaultFontSize")
        coder.encode(color, forKey: "color")
        coder.encode(labelFont, forKey: "labelFont")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        textToStore = coder.decodeObject(forKey: "textToStore") as? String
        currentFontSize = coder.decodeObject(forKey: "currentFontSize") as? CGFloat
        defaultFontSize = coder.decodeObject(forKey: "defaultFontSize") as? Int
        color = coder.decodeObject(forKey: "color") as? UIColor
        labelFont = coder.decodeObject(forKey: "labelFont") as? LabelFont
    }
    
}

extension UIViewController{
    func showPopUp(title: String?, message: String?, image: UIImage?, buttons: [DefaultButton], titleColor: UIColor, blurBack: Bool, transitionStyle: PopupDialogTransitionStyle = .bounceUp, dismissOnlyBtns: Bool = true, shakeOnBtnTap: Bool = false){

        let popup = PopupDialog(title: title, message: message, image: image, buttonAlignment: .vertical, transitionStyle: transitionStyle, preferredWidth: self.view.frame.width - 40, tapGestureDismissal: !dismissOnlyBtns, panGestureDismissal: !dismissOnlyBtns, hideStatusBar: false, completion: nil)
        let dialogAppearance = PopupDialogDefaultView.appearance()
        
        dialogAppearance.backgroundColor      = .secondarySystemBackground
        dialogAppearance.titleFont            = UIFont(name: "NexaW01-Heavy", size: 18)!
        dialogAppearance.titleColor           = titleColor
        dialogAppearance.titleTextAlignment   = .center
        dialogAppearance.messageFont          = UIFont(name: "NexaW01-Regular", size: 16)!
        dialogAppearance.messageColor         = .secondaryLabel
        dialogAppearance.messageTextAlignment = .center
        // Create buttons
        
        // This button will not the dismiss the dialog
        
        for button in buttons{
            button.titleFont = UIFont(name: "NexaW01-Heavy", size: 16)
            button.backgroundColor = .tertiarySystemBackground
            button.setTitleColor(UIColor(named: "LoadingColor"), for: .normal)
        }
        
        popup.addButtons(buttons)
        
        if !blurBack{
            let vc = PopupDialogOverlayView.appearance()
            vc.blurEnabled = false
            
            vc.opacity = 0.2
        }
                
        self.present(popup, animated: true, completion: {
            
        })
    }
}

extension UIImage {

    func withBackground(color: UIColor) -> UIImage? {
        var image: UIImage?
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let imageRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(imageRect)
            draw(in: imageRect, blendMode: .normal, alpha: 1.0)
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        return nil
    }
    
    
}

extension UIImage{
    func overlayImage(color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()

        color.setFill()

        context!.translateBy(x: 0, y: self.size.height)
        context!.scaleBy(x: 1.0, y: -1.0)

        context!.setBlendMode(CGBlendMode.colorBurn)
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        context!.draw(self.cgImage!, in: rect)

        context!.setBlendMode(CGBlendMode.sourceIn)
        context!.addRect(rect)
        context!.drawPath(using: CGPathDrawingMode.fill)

        let coloredImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return coloredImage!
    }
}

extension Colors{
    func getColor() -> UIColor{
        let colors = rgb

        let r = colors?.first ?? 0
        let g = colors?[1] ?? 0
        let b = colors?.last ?? 0

        return UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)
    }
}

extension String{
    func prepared() -> String{
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
