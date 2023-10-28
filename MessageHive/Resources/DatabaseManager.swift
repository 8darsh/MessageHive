//
//  DatabaseManager.swift
//  MessageHive
//
//  Created by Adarsh Singh on 22/10/23.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager{
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String{
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }

}

// Mark: - Account management
extension DatabaseManager{
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)){
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            
            guard let foundemail = snapshot.value as? String else {
                completion(false)
                return
            }
            
            completion(true)
        }
        
    }
    
    /// inserts new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool)->Void){
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ]) { error, _ in
            guard error == nil else{
                print("Failed to write to database")
                completion(false)
                return
            }

            
            self.database.child("users").observeSingleEvent(of: .value) { snapshot in
                if var userCollection = snapshot.value as? [[String:String]]{
                    //append to dictionary
                    let newElement = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "safe_Email": user.safeEmail
                    
                        ]
                    ]
                    userCollection.append(contentsOf: newElement)
                    self.database.child("users").setValue(userCollection) { error, _ in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    }
                    
                }else{
                    //create the array
                    let newCollection:[[String:String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "safe_Email": user.safeEmail
                    
                        ]
                    ]
                    self.database.child("users").setValue(newCollection) { error, _ in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    }
                }
            }
            
            
        }
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String:String]],Error>)-> Void){
        database.child("users").observeSingleEvent(of: .value) { snapshot  in
            guard let value = snapshot.value as? [[String:String]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    public enum DatabaseError: Error{
        case failedToFetch
    }
    /*
     users => [
        [
            "name":
            "safe_Email":
        ],
        [
            "name":
            "safe_Email":
        ]
     ]
     */
}

struct ChatAppUser{
    
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String{
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String{
        
        return "\(safeEmail)_profile_picture.png"
    }
}
