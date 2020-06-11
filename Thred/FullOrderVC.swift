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

class FullOrderVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var featuredHeader: FeaturedPostView!
    var order: Order!
    var productToOpen: Product!
    var didCancel = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.delegate = self
        
        print(order.products.first!.product.name!)
        
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
    }
    
    @IBAction func dismissVC(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
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
        return 3
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
        
        if indexPath.row == 2{
            let cell = UITableViewCell(style: .default, reuseIdentifier: "DefaultCell")
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.text = "Cancel Order"
            cell.textLabel?.textColor = UIColor.red
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
                if order.canCancel{
                    cell.detailTextLabel?.text = "CONFIRMED"
                    cell.detailTextLabel?.textColor = .red
                }
                else{
                    cell.detailTextLabel?.text = "COMPLETED"
                    cell.detailTextLabel?.textColor = .systemGreen
                }
            case 1:
                cell.textLabel?.text = "Shipping:"
                cell.detailTextLabel?.text = "\(order.shippingCost.formatPrice())"
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
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            confirmCancellation {}
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func showStatusMessage(completed: @escaping () -> ()){
        
        var title = String()
        var description = String()
        var titleColor = UIColor()
        
        if order.canCancel{
            title = "CONFIRMED"
            titleColor = .red
            description = "Your order is confirmed and is still processing. Orders in this stage can be cancelled."
        }
        else{
            title = "COMPLETE"
            titleColor = .systemGreen
            description = "Your order is completed and may take 1-2 business days to ship. Orders in this stage cannot be cancelled."
        }
        
        let yesBtn = DefaultButton(title: "OK", dismissOnTap: true) {
            completed()
        }
        
        showPopUp(title: title, message: description, image: nil, buttons: [yesBtn], titleColor: titleColor)
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
        
        guard let intents = order.intents, !intents.isEmpty, let shippingCost = order.shippingCost, let id = order.orderID, let uid = userInfo.uid else{
            errorCancelling {}
            return }
        
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
                vc.orders.remove(at: section)
                vc.ordersTableView.performBatchUpdates({
                    vc.ordersTableView.deleteSections(IndexSet(integer: section), with: .automatic)
                }, completion: { finished in
                    if finished{
                        for (index, _) in vc.orders.enumerated(){
                            vc.ordersTableView.performBatchUpdates({
                                vc.ordersTableView.reloadSections(IndexSet(integer: index), with: .automatic)
                            }, completion: { finished in })
                        }
                    }
                })
            }
        }
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.

    }
    

}
