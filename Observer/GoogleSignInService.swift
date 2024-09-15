//
//  GoogleSignInService.swift
//  Observer
//
//  Created by Jiwon Kim on 9/11/24.
//

import Foundation
import GoogleSignIn

protocol GoogleSignInServiceProtocol {
    func handle(_ url: URL) -> Bool
    func restorePreviousSignIn(completion: @escaping (Result<String, Error>) -> Void)
}

class GoogleSignInService: GoogleSignInServiceProtocol {
    func handle(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    func restorePreviousSignIn(completion: @escaping (Result<String, Error>) -> Void) {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = user, let idToken = user.idToken?.tokenString {
                completion(.success(idToken))
            } else {
                completion(.failure(NSError(domain: "GoogleSignIn", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user or ID token found"])))
            }
        }
    }
}
