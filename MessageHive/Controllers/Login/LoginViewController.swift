//
//  LoginViewController.swift
//  MessageHive
//
//  Created by Adarsh Singh on 18/10/23.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import FirebaseCore
import JGProgressHUD
class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage (named: "logo")
        return iv
    }()
    
    private let emailField:UITextField={
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let passwordField:UITextField={
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("Log In", for: .normal)
        btn.backgroundColor = .link
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        btn.layer.masksToBounds = true
        btn.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return btn
    }()
    
    private let googleLogInButton = GIDSignInButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        
        //add subview
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(googleLogInButton)
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        googleLogInButton.addTarget(self, action: #selector(googleLogInButtonTapped), for: .touchUpInside)
        
        
        emailField.delegate = self
        passwordField.delegate = self
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width-size)/2,
                                 y: 20,
                                 width: size,
                                 height: size)
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom+10,
                                  width: scrollView.width-60,
                                 height: 47)
        passwordField.frame = CGRect(x: 30,
                                  y: emailField.bottom+10,
                                  width: scrollView.width-60,
                                 height: 47)
        loginButton.frame = CGRect(x: 30,
                                  y: passwordField.bottom+10,
                                  width: scrollView.width-60,
                                 height: 47)
        googleLogInButton.frame = CGRect(x: 30,
                                  y: loginButton.bottom+10,
                                  width: scrollView.width-60,
                                 height: 47)
        
    }
    
    @objc private func loginButtonTapped(){
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else{
            alertUserLoginError()
            return
        }
        //Firebase login
        
        spinner.show(in: view)
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            
            guard let self else {return}
            
            DispatchQueue.main.async {
                self.spinner.dismiss()
            }
            guard let result = authResult, error == nil else{
                print("Failed to login user with email: \(email)")
                return
            }
            
            let user = result.user
            UserDefaults.standard.set(email, forKey: "email")
            print("logged in user \(user)")
            self.navigationController?.dismiss(animated: true)
        }
        
        
    }
    @objc func googleLogInButtonTapped(){
        spinner.show(in: view)
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [unowned self] result, error in
          
            DispatchQueue.main.async {
                self.spinner.dismiss()
            }
          guard error == nil else {
            // ...
              return
          }
            
          guard let user = result?.user,
            let idToken = user.idToken?.tokenString
          else {
            // ...
              return
          }
            guard let email = user.profile?.email,
                  let firstName = user.profile?.givenName,
                  let lastName = user.profile?.familyName else{return}
            UserDefaults.standard.set(email, forKey: "email")
            
            DatabaseManager.shared.userExists(with: email) { exists in
                if !exists{
                    // insert to database
                    let ChatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                    DatabaseManager.shared.insertUser(with: ChatUser) { success in
                        if success{
                            
                            if user.profile!.hasImage{
                                guard let url = user.profile?.imageURL(withDimension: 200) else{
                                    return
                                }
                                URLSession.shared.dataTask(with: url) { data, _, _ in
                                    guard let data else {
                                        return
                                    }
                                    let fileName = ChatUser.profilePictureFileName
                                    
                                    StorageManager.shared.uploadProfilePicture(with: data, filename: fileName) { result in
                                        switch result{
                                            
                                        case .success(let downloadUrl):
                                            UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                            print("\(downloadUrl)")
                                        case .failure(let error):
                                            print("Storage manager error: \(error)")
                                        }
                                    }
                                }.resume()
                            
                            
                            }


                        }
                    }
                }
            }

          let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: user.accessToken.tokenString)

          // ...
            FirebaseAuth.Auth.auth().signIn(with: credential) { result, error in
                
                guard result != nil, error == nil else{
                    print("failed to log in with google")
                    return
                }
                self.navigationController?.dismiss(animated: true)
            }
                
        }
    }
    
    
    
    func alertUserLoginError(){
        let alert = UIAlertController(title: "Woops", message: "Please enter all info to login.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
        
    }
   

}

extension LoginViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField{
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField{
            loginButtonTapped()
        }
        
        
        return true
    }
    
    
}
