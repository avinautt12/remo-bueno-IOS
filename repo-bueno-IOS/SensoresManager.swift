//
//  SensoresManager.swift
//  repo-bueno-IOS
//
//  Created by Carolina Gonzalez on 04/04/25.
//

// SensorManager.swift
import Foundation

class SensorManager {
    static let shared = SensorManager()
    
    private let baseURL = "https://00ec-177-244-54-50.ngrok-free.app/api"
    private let urlSession = URLSession.shared
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    // MARK: - Sensor Endpoints
    
    func fetchSensors(completion: @escaping (Result<[Sensor], SensorError>) -> Void) {
        let endpoint = baseURL
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        addAuthHeader(to: &request)
        
        urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.serverError(statusCode: httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let response = try self.jsonDecoder.decode(SensorResponse.self, from: data)
                completion(.success(response.data))
            } catch {
                completion(.failure(.decodingFailed(error)))
            }
        }.resume()
    }
    
    func fetchSensorHistory(sensorId: Int, completion: @escaping (Result<[Sensor], SensorError>) -> Void) {
        let endpoint = "\(baseURL)/\(sensorId)/history"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        addAuthHeader(to: &request)
        
        urlSession.dataTask(with: request) { data, response, error in
            // Mismo manejo de respuesta que en fetchSensors
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    // MARK: - Private Methods
    
    private func handleResponse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<[Sensor], SensorError>) -> Void) {
        if let error = error {
            completion(.failure(.requestFailed(error)))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(.invalidResponse))
            return
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            completion(.failure(.serverError(statusCode: httpResponse.statusCode)))
            return
        }
        
        guard let data = data else {
            completion(.failure(.noData))
            return
        }
        
        do {
            let response = try self.jsonDecoder.decode(SensorResponse.self, from: data)
            completion(.success(response.data))
        } catch {
            completion(.failure(.decodingFailed(error)))
        }
    }
    
    private func addAuthHeader(to request: inout URLRequest) {
        if let token = AuthService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
    
    // MARK: - Error Handling
    enum SensorError: Error, LocalizedError {
        case invalidURL
        case requestFailed(Error)
        case invalidResponse
        case noData
        case decodingFailed(Error)
        case unauthorized
        case notFound
        case serverError(statusCode: Int)
        
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
                return "Sensor no encontrado"
            case .serverError(let statusCode):
                return "Error del servidor (Código: \(statusCode))"
            }
        }
    }
}
