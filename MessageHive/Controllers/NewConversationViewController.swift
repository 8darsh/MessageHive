//
//  NewConversationViewController.swift
//  MessageHive
//
//  Created by Adarsh Singh on 18/10/23.
//

import UIKit
import JGProgressHUD
class NewConversationViewController: UIViewController {

    private let spinner = JGProgressHUD(style: .dark)
    private var users = [[String:String]]()
    private var results = [[String:String]]()
    private var hasFetched = false
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for users..."
        return searchBar
    }()
    private let tableView: UITableView = {
        var table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        
        return table
    }()
    
    private let noResultLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.textColor = .green
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.text = "No result"
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        view.addSubview(noResultLabel)
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
        
        searchBar.becomeFirstResponder()
    }
    
    @objc private func dismissSelf(){
        dismiss(animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultLabel.frame = CGRect(x: view.width/4, y: (view.height-200)/2, width: view.width/2, height: 200)
    }
   

}

extension NewConversationViewController: UISearchBarDelegate{
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else{
            return
        }
        searchBar.resignFirstResponder()
        results.removeAll()
        spinner.show(in: view)
        self.searchUsers(query: text)
    }
    
    func searchUsers(query: String){
        //check if array has firebase result
        if hasFetched{
            //if fetched: filter
            filterUsers(with: query)
        }else{
            //if not fetched:fetch then filter
            DatabaseManager.shared.getAllUsers { [weak self] result in
                switch result {
                case .success(let userCollection):
                    self?.hasFetched = true
                    self?.users = userCollection
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("failed to get user: \(error)")
                }
            }
        }
    }
    
    func filterUsers(with term: String){
        guard hasFetched else{
            return
        }
        self.spinner.dismiss()
        
        let result:[[String:String]] = self.users.filter {
            guard let name = $0["name"]?.lowercased() else{
                return false
            }
            return name.hasPrefix(term.lowercased())
        }
        
        self.results = result
        
        updateUI()
    }
    
    func updateUI(){
        if results.isEmpty{
            self.noResultLabel.isHidden = false
            self.tableView.isHidden = true
        }else{
            self.noResultLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
    
    
    
}
extension NewConversationViewController: UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
