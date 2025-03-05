//
//  AuthService.swift
//  repo-bueno-IOS
//
//  Created by mac on 03/03/25.
//

import Foundation


class AuthService {
    static let shared = AuthService()
    
    private let baseURL = "https://da69-177-244-54-50.ngrok-free.app/api"
    
    private init() {}
    
    func login(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/login") else { return }
        
        let parameters: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let token = json["token"] as? String {
                    
                    self.saveToken(token)
                    completion(.success(token))
                } else {
                    let apiError = NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Credenciales inválidas"])
                    completion(.failure(apiError))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    func logout(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/logout") else { return }
        guard let token = getToken() else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { _, _, _ in
            self.removeToken()
            completion(true)
        }
        task.resume()
    }
    
    func saveToken(_ token: String) {
        UserDefaults.standard.setValue(token, forKey: "authToken")
    }
    
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    func removeToken() {
        UserDefaults.standard.removeObject(forKey: "authToken")
    }
    
    func isAuthenticated() -> Bool {
        return getToken() != nil
    }
}
