import Foundation

class APIManager {
    static let shared = APIManager()
    
    public let baseURL = "https://9271-187-190-56-49.ngrok-free.app/api"
    private let urlSession = URLSession.shared
    private let cache = NSCache<NSString, NSData>()
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    // MARK: - Orders Endpoints
    func fetchOrders(completion: @escaping (Result<[Orden], APIError>) -> Void) {
        let endpoint = "\(baseURL)/my-deliveries"
        print("Solicitando órdenes a:", endpoint)
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        addAuthHeader(to: &request)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error en la solicitud:", error.localizedDescription)
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let data = data else {
                print("No se recibieron datos")
                completion(.failure(.noData))
                return
            }
            
            // Imprimir respuesta JSON para depuración
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Respuesta JSON recibida:", jsonString)
            }
            
            do {
                let response = try JSONDecoder().decode(OrdenResponse.self, from: data)
                print("Órdenes decodificadas:", response.data.count)
                completion(.success(response.data))
            } catch {
                print("Error al decodificar:", error)
                completion(.failure(.decodingFailed(error)))
            }
        }.resume()
    }
    
    func updateOrderStatus(orderId: String, newStatus: String, completion: @escaping (Result<Orden, APIError>) -> Void) {
        let endpoint = "\(baseURL)/orders/\(orderId)/status"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeader(to: &request)
        
        let bodyDict = ["status": newStatus]
        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyDict)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(OrdenResponse.self, from: data)
                completion(.success(response.data.first!)) // Asumiendo que devuelve la orden actualizada
            } catch {
                completion(.failure(.decodingFailed(error)))
            }
        }.resume()
    }
    
    // MARK: - Materials Endpoints
    func fetchMaterials(completion: @escaping (Result<[Material], APIError>) -> Void) -> URLSessionDataTask {
        let endpoint = "\(baseURL)/products"
        
        // Creamos una URL por defecto segura si falla la construcción
        let url = URL(string: endpoint) ?? URL(string: "\(baseURL)/")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addAuthHeader(to: &request)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Manejo de errores
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            // Procesamiento exitoso
            do {
                let materiales = try JSONDecoder().decode([Material].self, from: data)
                completion(.success(materiales))
            } catch {
                completion(.failure(.decodingFailed(error)))
            }
        }
        
        task.resume()
        return task
    }
    
    func searchMaterial(code: String, completion: @escaping (Result<Material, APIError>) -> Void) -> URLSessionDataTask? {
        let endpoint = "\(baseURL)/materials/search?code=\(code)"
        return fetchData(endpoint: endpoint, completion: completion)
    }
    
    // MARK: - Private Methods
    private func fetchData<T: Decodable>(endpoint: String, completion: @escaping (Result<T, APIError>) -> Void) -> URLSessionDataTask? {
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidURL))
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addAuthHeader(to: &request)
        
        print("Headers: \(request.allHTTPHeaderFields ?? [:])") // Debug
        
        let task = urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error en la petición: \(error.localizedDescription)") // Debug
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error: Respuesta inválida") // Debug
                completion(.failure(.invalidResponse))
                return
            }
            
            print("Status code: \(httpResponse.statusCode)") // Debug
            
            guard let data = data else {
                print("Error: Sin datos recibidos") // Debug
                completion(.failure(.noData))
                return
            }
            
            // Imprime la respuesta cruda como string
            if let responseString = String(data: data, encoding: .utf8) {
                print("Respuesta cruda: \(responseString)") // Debug
            }
            
            do {
                let decoded = try self.jsonDecoder.decode(T.self, from: data)
                completion(.success(decoded))
            } catch let decodingError {
                print("Error de decodificación: \(decodingError)") // Debug
                completion(.failure(.decodingFailed(decodingError)))
            }
        }
        task.resume()
        return task
    }
    
    private func handleResponse<T: Decodable>(data: Data?,
                                              response: URLResponse?,
                                              error: Error?,
                                              completion: @escaping (Result<T, APIError>) -> Void) {
        if let error = error {
            completion(.failure(.requestFailed(error)))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(.invalidResponse))
            return
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let decoded = try jsonDecoder.decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(.decodingFailed(error)))
            }
            
        case 401:
            completion(.failure(.unauthorized))
        case 404:
            completion(.failure(.notFound))
        default:
            completion(.failure(.serverError(statusCode: httpResponse.statusCode)))
        }
    }
    
    public func addAuthHeader(to request: inout URLRequest) {
        if let token = AuthManager.shared.authToken {
            print("✅ Token siendo enviado: \(token)")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("⚠️ No se encontró token de autenticación")
        }
    }
    
    // MARK: - Mock Data
    private var mockOrders: [Orden] = [
        Orden(
            id: 1,
            workerId: 1,
            deliveryDate: "2025-04-03",
            productsString: "C. Compacto: 1039.00g, C. Corrugado: 480.00g, C. Plastificado: 2347.00g",
            workerName: "Jonathan Alejandro",
            carrier: "Redpack-4756",
            status: "Pending",
            totalWeight: 25604
        ),
        Orden(
            id: 2,
            workerId: 2,
            deliveryDate: "2025-04-04",
            productsString: "C. Kraft: 1660.00g, C. Compacto: 4854.00g",
            workerName: "María González",
            carrier: "Fedex-1234",
            status: "Completed",
            totalWeight: 6514
        )
    ]
    
    // MARK: - Error Handling
    enum APIError: Error, LocalizedError {
        case invalidURL
        case requestFailed(Error)
        case invalidResponse
        case noData
        case decodingFailed(Error)
        case unauthorized
        case notFound
        case serverError(statusCode: Int)
        case cancelled
           
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "URL inválida"
            case .requestFailed(let error):
                return "Error en la solicitud: \(error.localizedDescription)"
            case .invalidResponse:
                return "Respuesta inválida del servidor"
            case .noData:
                return "No se recibieron datos"
            case .decodingFailed(let error):
                return "Error decodificando los datos: \(error.localizedDescription)"
            case .unauthorized:
                return "No autorizado - Por favor inicie sesión nuevamente"
            case .notFound:
                return "Recurso no encontrado"
            case .serverError(let statusCode):
                return "Error del servidor (Código: \(statusCode))"
            case .cancelled:
                   return nil
            }
        }
    }
    
    // MARK: - Auth Manager
    class AuthManager {
        static let shared = AuthManager()
        
        var authToken: String? {
            // Usamos AuthService como fuente única de verdad
            get { AuthService.shared.getToken() }
            set {
                if let token = newValue {
                    AuthService.shared.saveToken(token)
                } else {
                    AuthService.shared.removeToken()
                }
            }
        }
        
        init() {
            // Opcional: Verificación de sincronización al iniciar
            print("Token al iniciar AuthManager - Keychain: \(AuthService.shared.getToken() ?? "nil")")
        }
        
        func logout(completion: @escaping (Bool) -> Void) {
            AuthService.shared.logout { success in
                if success {
                    self.authToken = nil // Esto automáticamente llama a removeToken en AuthService
                }
                completion(success)
            }
        }
    }
}
