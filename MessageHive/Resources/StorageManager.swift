//
//  StorageManager.swift
//  MessageHive
//
//  Created by Adarsh Singh on 24/10/23.
//

import Foundation
import FirebaseStorage


final class StorageManager{
    
    static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    
    typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    /// Uploads picture to firebase storage and returns completion with url string to download
    
    public func uploadProfilePicture(with data: Data, filename: String, completion: @escaping UploadPictureCompletion){
    
        storage.child("images/\(filename)").putData(data) { metadata, error in
            guard error == nil else{
                print("failed to upload data to firebase for pictures")
                completion(.failure(StorageError.failedToUplaod))
                return
            }
        }
        
        self.storage.child("images/\(filename)").downloadURL { url, error in
            guard let url else{
                print("Failed to get download url")
                completion(.failure(StorageError.failedToGetDownloadUrl))
                return
            }
            
            let urlString = url.absoluteString
            print("downlaod url return \(urlString)")
            completion(.success(urlString))
        }
    }
    
    public enum StorageError: Error{
        case failedToUplaod
        case failedToGetDownloadUrl
    }
    
    public func downloadUrl(for path: String, completion: @escaping (Result<URL,Error>) -> Void){
        let reference = storage.child(path)
        
        reference.downloadURL { url, error in
            
            guard let url = url,error == nil else{
                completion(.failure(StorageError.failedToGetDownloadUrl))
                return
            }
            
            completion(.success(url))
        }
    }
}
