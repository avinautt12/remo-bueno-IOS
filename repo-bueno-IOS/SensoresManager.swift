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
      
      private let baseURL = "https://backendv3.smartgames.tech/api"
      private let urlSession = URLSession.shared
      
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ" // Maneja 6 dígitos fraccionales
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()
    
      // Método para obtener áreas
      func fetchAreas(completion: @escaping (Result<[Area], SensorError>) -> Void) {
          let endpoint = "\(baseURL)/areas"
          guard let url = URL(string: endpoint) else {
              completion(.failure(.invalidURL))
              return
          }
          
          var request = URLRequest(url: url)
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
                  let areas = try self.jsonDecoder.decode([Area].self, from: data)
                  completion(.success(areas))
              } catch {
                  completion(.failure(.decodingFailed(error)))
              }
          }.resume()
      }
    
    func fetchSensors(for areaId: Int, completion: @escaping (Result<[Sensor], SensorError>) -> Void) {
        let endpoint = "\(baseURL)/sensors/area/\(areaId)"
        print("🕸️ Requesting endpoint: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addAuthHeader(to: &request)
        
        urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error de red: \(error.localizedDescription)")
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Respuesta inválida (no HTTPURLResponse)")
                completion(.failure(.invalidResponse))
                return
            }
            
            print("🔢 Status code: \(httpResponse.statusCode)")
            print("📦 Headers de respuesta: \(httpResponse.allHeaderFields)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ Error del servidor: \(httpResponse.statusCode)")
                completion(.failure(.serverError(statusCode: httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                print("❌ No hay datos en la respuesta")
                completion(.failure(.noData))
                return
            }
            
            // Imprimir el JSON crudo como string
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 RAW JSON RESPONSE:")
                print(jsonString)
            } else {
                print("⚠️ No se pudo convertir data a string")
            }
            
            do {
                let response = try self.jsonDecoder.decode(SensorResponse.self, from: data)
                var sensors = [Sensor]()
                
                // Verificar si ambos sensores son nulos
                guard response.temperature_sensors != nil || response.pir_sensors != nil else {
                    throw SensorError.noSensorsInArea
                }
                
                if let tempSensor = response.temperature_sensors {
                    sensors.append(tempSensor)
                }
                if let pirSensor = response.pir_sensors {
                    sensors.append(pirSensor)
                }
                
                completion(.success(sensors))
            } catch {
                // Manejar error específico
                if let decodingError = error as? DecodingError {
                    completion(.failure(.decodingFailed(decodingError)))
                } else {
                    completion(.failure(error as? SensorError ?? .noSensorsInArea))
                }
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
    
    private func handleResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        completion: @escaping (Result<[Sensor], SensorError>) -> Void
    ) {
        if let error = error {
            print("❌ Error en la solicitud: \(error.localizedDescription)")
            completion(.failure(.requestFailed(error)))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Respuesta inválida")
            completion(.failure(.invalidResponse))
            return
        }
        
        print("🔢 Código de estado HTTP: \(httpResponse.statusCode)")
        
        guard (200  ... 299).contains(httpResponse.statusCode) else {
            print("❌ Error del servidor: \(httpResponse.statusCode)")
            completion(.failure(.serverError(statusCode: httpResponse.statusCode)))
            return
        }
        
        guard let data = data else {
            print("❌ No se recibieron datos")
            completion(.failure(.noData))
            return
        }
        
        // Imprimir el JSON recibido
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 JSON recibido: \(jsonString)")
        }
        
        do {
            // Si el endpoint retorna array
            let sensores = try self.jsonDecoder.decode([Sensor].self, from: data)
            completion(.success(sensores))
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
        case noSensorsInArea // <-- Agregar este caso

        
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
            case .noSensorsInArea:
                  return "No hay sensores en esta área actualmente"
            case .noSensorsInArea:
                       return "No hay sensores en esta área actualmente"
            case .serverError(let statusCode):
                return "Error del servidor (Código: \(statusCode))"
            }
        }
    }
}

// En SensorManager.swift
extension SensorManager {
    func fetchLightSensor(completion: @escaping (Result<Sensor, SensorError>) -> Void) {
        let endpoint = "\(baseURL)/light-sensor"
        fetchSingleSensor(endpoint: endpoint, completion: completion)
    }
    
    func fetchTemperatureHumiditySensor(completion: @escaping (Result<Sensor, SensorError>) -> Void) {
        let endpoint = "\(baseURL)/temperature-humidity-sensor"
        fetchSingleSensor(endpoint: endpoint, completion: completion)
    }
    
    private func fetchSingleSensor(
        endpoint: String,
        completion: @escaping (Result<Sensor, SensorError>) -> Void
    ) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
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
                 let sensor = try self.jsonDecoder.decode(Sensor.self, from: data)
                 completion(.success(sensor))
             } catch {
                 completion(.failure(.decodingFailed(error)))
             }
        }.resume()
    }
}
