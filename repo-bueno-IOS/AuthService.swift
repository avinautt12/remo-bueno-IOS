import Foundation
import Security

class AuthService {
    
    // MARK: - Singleton
    static let shared = AuthService()
    private init() {}
    
    // MARK: - Constantes
    private struct Constants {
        static let baseURL = "https://9271-187-190-56-49.ngrok-free.app/api"
        static let tokenKey = "authToken"
        static let tokenAccount = "authToken"
    }
    
    // MARK: - API Requests
    
    func login(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/login") else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
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
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AuthError.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(AuthError.noData))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if httpResponse.statusCode == 200, let token = json?["token"] as? String {
                    self?.saveToken(token)
                    completion(.success(token))
                } else if let message = json?["message"] as? String {
                    completion(.failure(AuthError.serverMessage(message)))
                } else {
                    completion(.failure(AuthError.unknownError))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    func logout(completion: @escaping (Bool) -> Void) {
        removeToken()
        
        guard let url = URL(string: "\(Constants.baseURL)/logout") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if let token = getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                let success = error == nil
                completion(success)
            }
        }.resume()
    }
    
    // MARK: - Keychain Operations
    
    func saveToken(_ token: String) {
        let data = token.data(using: .utf8)!
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: Constants.tokenAccount,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error al guardar token en Keychain: \(status)")
        }
    }
    
    func getToken() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: Constants.tokenAccount,
            kSecReturnData: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    func removeToken() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: Constants.tokenAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Error al eliminar token de Keychain: \(status)")
        }
    }
    
    // MARK: - Helpers
    
    func isAuthenticated() -> Bool {
        return getToken() != nil
    }
    
    // MARK: - Error Handling
    
    enum AuthError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case noData
        case serverMessage(String)
        case unknownError
        
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "URL inválida"
            case .invalidResponse: return "Respuesta inválida del servidor"
            case .noData: return "No se recibieron datos"
            case .serverMessage(let message): return message
            case .unknownError: return "Error desconocido"
            }
        }
    }
}
