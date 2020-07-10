//
//  FullOrderVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-06-07.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import PopupDialog
import Firebase

class Address{
    
    
    required init(instance: Address) {
        self.postalCode = instance.postalCode
        self.streetAddress = instance.streetAddress
        self.unitNumber = instance.unitNumber
        self.city = instance.city
        self.adminArea = instance.adminArea
        self.country = instance.country
    }
        
    var postalCode: String!
    var streetAddress: String!
    var unitNumber: String?
    var city: String!
    var adminArea: String!
    var country: String!
    
    init(postalCode: String?, streetAddress: String?, unitNumber: String?, city: String?, adminArea: String?, country: String?) {
        self.postalCode = postalCode
        self.streetAddress = streetAddress
        self.unitNumber = unitNumber
        self.city = city
        self.adminArea = adminArea
        self.country = country
    }
    
    convenience init(){
        self.init(postalCode: nil, streetAddress: nil, unitNumber: nil, city: nil, adminArea: nil, country: nil)
    }
}

class FullOrderVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var featuredHeader: FeaturedPostView!
    var order: Order!
    var productToOpen: Product!
    var didCancel = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.delegate = self
        
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
        
        featuredHeader = tableView.loadFeaturedHeaderFromNib()
        featuredHeader.order = order
        featuredHeader.vc = self
        featuredHeader.numberOfItems = order.products.count
        featuredHeader.collectionView.reloadData()
        
        view.addSubview(loadingView)
        loadingView.isHidden = true

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        hideCenterBtn()
    }
    
    override func viewDidLayoutSubviews() {
        featuredHeader.frame.size.height = view.frame.width
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    lazy var loadingView: UIView = {
        
        let view = UIView(frame: self.view.frame)
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.75)
        let spinner = MapSpinnerView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        spinner.center.x = view.center.x
        spinner.center.y = view.center.y - spinner.frame.height - 20
        view.addSubview(spinner)
        let label = UILabel(frame: CGRect(x: 0, y: spinner.frame.minY - 30, width: view.frame.width, height: 20))
        label.textAlignment = .center
        label.text = "Cancelling your order ..."
        label.font = UIFont(name: "NexaW01-Heavy", size: 16)
        view.addSubview(label)
        spinner.animate()
        
        return view
        
    }()
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 6{
            let cell = UITableViewCell(style: .default, reuseIdentifier: "DefaultCell")
            cell.textLabel?.textAlignment = .center
            var color: UIColor!
            let string = "Cancel Order"
            
            switch order.status{
            case "confirmed":
                color = UIColor.red
            case "cancelled":
                color = UIColor.systemFill
            case "cancelled-print":
                color = UIColor.systemFill
            case "completed":
                color = UIColor.systemFill
            default:
                color = UIColor.systemFill
                break
            }
            cell.textLabel?.text = string
            cell.textLabel?.textColor = color
            cell.textLabel?.font = UIFont(name: "NexaW01-Heavy", size: 14)
            
            return cell
        }
        else{
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "textCell")
            
            cell.textLabel?.text = nil
            cell.detailTextLabel?.text = nil
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.detailTextLabel?.backgroundColor = .clear
            cell.detailTextLabel?.font = UIFont(name: "NexaW01-Heavy", size: 16)
            cell.textLabel?.font = UIFont(name: "NexaW01-Heavy", size: 16)

            print(indexPath.row)
            
            switch indexPath.row{
                
            case 0:
                cell.textLabel?.text = "Order Status:"
                var color: UIColor!
                var string: String!
                
                switch order.status{
                case "confirmed":
                    color = UIColor.systemYellow
                    string = "CONFIRMED"
                case "cancelled":
                    color = UIColor.red
                    string = "CANCELLED"
                case "cancelled-print":
                    color = UIColor.red
                    string = "CANCELLED"
                case "completed":
                    color = UIColor.systemGreen
                    string = "COMPLETED"
                default:
                    color = UIColor.systemGreen
                    string = "ERROR"
                    break
                }
                cell.detailTextLabel?.text = string
                cell.detailTextLabel?.textColor = color
            case 1:
                cell.textLabel?.text = "Delivery Address:"
                cell.detailTextLabel?.text = "VIEW"
            case 2:
                cell.textLabel?.text = "Subtotal:"
                if let cost = order.subtotal, cost != 0.00{
                    cell.detailTextLabel?.text = "\((order.subtotal ?? 0.00).formatPrice())"
                }
                else{
                    cell.detailTextLabel?.text = "FREE"
                }
            case 3:
                cell.textLabel?.text = "Shipping:"
                if let cost = order.shippingCost, cost != 0.00{
                    cell.detailTextLabel?.text = "\((order.shippingCost ?? 0.00).formatPrice())"
                }
                else{
                    cell.detailTextLabel?.text = "FREE"
                }
            case 4:
                cell.textLabel?.text = "Tax:"
                if let cost = order.tax, cost != 0.00{
                    cell.detailTextLabel?.text = "\((order.tax ?? 0.00).formatPrice())"
                }
                else{
                    cell.detailTextLabel?.text = "N/A"
                }
            case 5:
                cell.textLabel?.text = "Total:"
                if let cost = order.totalCost, cost != 0.00{
                    cell.detailTextLabel?.text = "\((order.totalCost ?? 0.00).formatPrice())"
                }
                else{
                    cell.detailTextLabel?.text = "FREE"
                }
            default:
                break
            }
            return cell
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row{
        case 0:
            tableView.deselectRow(at: indexPath, animated: true)
            showStatusMessage {}
        case 1:
            showAddressMessage {}
            tableView.deselectRow(at: indexPath, animated: true)
        case 6:
            confirmCancellation {}
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func showStatusMessage(completed: @escaping () -> ()){
        
        var title = String()
        var description = String()
        var titleColor = UIColor()
        
        switch order.status{
        case "confirmed":
            titleColor = UIColor.systemYellow
            title = "CONFIRMED"
            description = "Your order is confirmed and is still processing. Orders in this stage can be cancelled."

        case "cancelled":
            titleColor = UIColor.red
            title = "CANCELLED"
            description = "Your order has been cancelled and a full refund has been issued to your card."
        case "cancelled-print":
            titleColor = UIColor.red
            title = "CANCELLED"
            description = "Your order has been cancelled and a full refund has been issued to your card."
        case "completed":
            titleColor = UIColor.systemGreen
            title = "COMPLETED"
            description = "Your order is completed and may take 1-2 business days to ship. Orders in this stage cannot be cancelled."
        default:
            titleColor = UIColor.red
            title = "ERROR"
            description = "There was an error completing this order, please contact Thred support."
            break
        }
        
        let yesBtn = DefaultButton(title: "OK", dismissOnTap: true) {
            completed()
        }
        
        showPopUp(title: title, message: description, image: nil, buttons: [yesBtn], titleColor: titleColor)
    }
    
    func showAddressMessage(completed: @escaping () -> ()){
        
        var description = "\(order.address.streetAddress ?? "").\n\(order.address.city ?? "").\n\(order.address.adminArea ?? "").\n\(order.address.postalCode ?? "")."
        
        if let unit = order.address.unitNumber{
            description += "\nUnit: \(unit)"
        }
        
        let yesBtn = DefaultButton(title: "OK", dismissOnTap: true) {
            completed()
        }
        
        showPopUp(title: nil, message: description, image: nil, buttons: [yesBtn], titleColor: .label)
    }
    
    func showCancelConfirmationMessage(completed: @escaping () -> ()){
        let title = "Are you sure you want to cancel your order?"
        let description = "You will receive a full refund for this item. This action cannot be undone"
        let titleColor = UIColor.label
        
        let yesBtn = DefaultButton(title: "YES", dismissOnTap: true) {
            completed()
        }
        let noBtn = DefaultButton(title: "NEVER MIND", dismissOnTap: true) {
            
        }
        
        showPopUp(title: title, message: description, image: nil, buttons: [yesBtn, noBtn], titleColor: titleColor)
    }
    
    func errorCancelling(completed: @escaping () -> ()){
        
        navigationItem.hidesBackButton = false
        loadingView.isHidden = true

        let title = "Error cancelling order"
        let description = "This order cannot be cancelled."
        let titleColor = UIColor.red
        
        let yesBtn = DefaultButton(title: "OK", dismissOnTap: true) {
            completed()
        }
        
        showPopUp(title: title, message: description, image: nil, buttons: [yesBtn], titleColor: titleColor)
    }
    
    func confirmCancellation(completed: @escaping () -> ()){
        if order.canCancel{
            showCancelConfirmationMessage {
                self.cancelOrder {
                    self.didCancel = true
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
        else{
            showStatusMessage {}
        }
    }
    
    
    
    func cancelOrder(completed: @escaping () -> ()){
        
        navigationItem.hidesBackButton = true
        loadingView.isHidden = false
        
        
        
        let spinner = loadingView.subviews.first(where: {$0.isKind(of: MapSpinnerView.self)}) as? MapSpinnerView
        spinner?.animate()
        guard
            let uncancelledOrders = order.products?.filter({!($0.isDeleted)}).compactMap({$0.saleID}),
            let intents = order.intents?.filter({uncancelledOrders.contains($0["ID"] ?? "null")}), !intents.isEmpty,
            let shippingCost = order.shippingCost,
            let id = order.orderID,
            let uid = userInfo.uid else{
            errorCancelling {}
        return }
        print(intents)
        
        let shipping_intent = order.shippingIntent ?? ""
        
        let data = [
            "intents" : intents,
            "shipping_intent" : shipping_intent,
            "shipping_cost" : shippingCost,
            "orderID" : id,
            "uid" : uid
        ] as [String : Any]
        
        Functions.functions().httpsCallable("cancelOrder").call(data, completion: { result, error in
            if let err = error{
                print(err.localizedDescription)
                self.errorCancelling {}
            }
            else{
                if let completedProcessing = result?.data as? Bool, !completedProcessing{
                    self.errorCancelling {}
                }
                else{
                    completed()
                }
            }
        })
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {

        if didCancel{
            if let vc = viewController as? NotificationVC, let section = vc.orders.firstIndex(where: {$0.orderID == order.orderID}){
                vc.orders[section].status = "cancelled"
                vc.ordersTableView.performBatchUpdates({
                    vc.ordersTableView.reloadSections(IndexSet(integer: section), with: .automatic)
                }, completion: { finished in
                    if finished{
                        
                    }
                })
            }
        }
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        if let full = segue.destination as? FullProductVC{
            full.fullProduct = productToOpen
        }
    }
}
