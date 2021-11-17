//
//  StocksTableViewController.swift
//  NYSEStocks
//
//  Created by Maheswari Kanti on 11/9/21.
//

import UIKit
import RealmSwift
import SwiftyJSON
import SwiftSpinner
import PromiseKit
import Alamofire

class StocksTableViewController: UITableViewController {
    
    var arr = ["TSLA", "MSFT", "GOOG", "AMZN"]
    
    let stockQuoteURL = "https://financialmodelingprep.com/api/v3/quote-short/"
    let companyProfileURL = "https://financialmodelingprep.com/api/v3/profile/"
    let apiKey = "37f7ce2fbfb21606353494d2815fb685"

    @IBOutlet var tblView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadStockValue()

    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return arr.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.textLabel?.text = arr[indexPath.row]
        // Configure the cell...

        return cell
    }
    
    @IBAction func addStockAction(_ sender: Any) {
        var globalTextField: UITextField?
        
        let actioncontroller = UIAlertController(title: "Add Stock Symbol", message: "", preferredStyle: .alert)
        
        let OkButton = UIAlertAction(title: "Ok", style: .default) { action in
            //print("Stock Typed = \(globalTextField?.text)")
            guard let symbol = globalTextField?.text else {return}
            
            if(symbol == ""){
                return
            }
            self.storeValuesInDB(symbol)
        }
        
        let CancelButton = UIAlertAction(title: "Cancel", style: .default) { action in
            print("I am in cancel")
        }
        actioncontroller.addAction(OkButton)
        actioncontroller.addAction(CancelButton)
        
        actioncontroller.addTextField { stockTextField in
            stockTextField.placeholder = "Stock Symbol"
            globalTextField = stockTextField
        }
        
        self.present(actioncontroller, animated: true, completion: nil)
    }
    
    func storeValuesInDB(_ symbol : String){
        getCompnyInfo(symbol)
            .done { companyJSON in
            
                if companyJSON.count == 0 {
                    return
                }
                
            let companyInfo = CompanyInfo()
            
            companyInfo.symbol = companyJSON["symbol"].stringValue
            companyInfo.price = companyJSON["price"].floatValue
            companyInfo.volAvg = companyJSON["volAvg"].intValue
            companyInfo.companyName = companyJSON["companyName"].stringValue
            companyInfo.exchangeShortName = companyJSON["exchangeShortName"].stringValue
            companyInfo.website = companyJSON["website"].stringValue
            companyInfo.desc = companyJSON["description"].stringValue
            companyInfo.image = companyJSON["image"].stringValue
            
            self.addStockInDB(companyInfo)
                print(companyInfo)
            }
            .catch{ (error) in
                print(error)
            }
    }
    
    func addStockInDB(_ companyInfo : CompanyInfo){
        do{
            let realm = try Realm()
            try realm.write {
                realm.add(companyInfo, update: .modified)
            }
        }catch{
            print("Error in DB \(error)")
        }
    }
    
    func doesStockExistInDB(_ symbol: String ) -> Bool {
        do{
            let realm = try Realm()
            if realm.object(ofType: CompanyInfo.self, forPrimaryKey: symbol) != nil { return true }
        }catch{
            print("Error in DB \(error)")
        }
        return false
    }
    
    func getCompnyInfo(_ symbol : String) -> Promise < JSON > {
        return Promise< JSON > { seal -> Void in
            let url = companyProfileURL + symbol + "?apikey=" + apiKey
            AF.request(url).responseJSON { response in
                if response.error != nil {
                    seal.reject(response.error!)
                }
                
                let stocks = JSON( response.data!).array
                guard let firstStock = stocks!.first else {seal.fulfill(JSON())
                    return
                }
                seal.fulfill (firstStock)
            }
        }
    }
    
    func loadStockValue(){
        do{
            let realm = try Realm()
            let companies = realm.objects(CompanyInfo.self)
            
            arr.removeAll()
            
            for company in companies {
                arr.append("\(company.symbol) \(company.companyName)")
            }
            tblView.reloadData()
        }catch{
            print("Error reading DB ")
        }
    }
    
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
}

