//
//  ProfileViewController.swift
//  MessageHive
//
//  Created by Adarsh Singh on 18/10/23.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    let data = ["Log Out"]
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }

}
extension ProfileViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // for unhilight the cell
        
        let ac = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
            guard let self else {return}
            
            let firebaseAuth = Auth.auth()
            do {
              try firebaseAuth.signOut()
            } catch let signOutError as NSError {
              print("Error signing out: %@", signOutError)
            }
            do{
                try FirebaseAuth.Auth.auth().signOut()
                let vc = LoginViewController()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                self.present(nav,animated:false)
            }catch{
                print("failed to log out")
            }
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(ac,animated: true)
        
    }
}
