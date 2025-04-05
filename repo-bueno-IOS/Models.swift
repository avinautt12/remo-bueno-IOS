import Foundation

struct OrdenResponse: Codable {
    let data: [Orden]
}

struct SensorResponse: Decodable {
    let data: [Sensor]
}

struct Orden: Codable {
    let id: Int
    let workerId: Int
    let deliveryDate: String
    let productsString: String
    let workerName: String
    let carrier: String
    var status: String
    let totalWeight: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "invoice_id"
        case workerId = "worker_id"
        case deliveryDate = "delivery_date"
        case productsString = "products"
        case workerName = "worker_name"
        case carrier
        case status
        case totalWeight = "total_weight"
    }
    
    var products: [ProductoOrden] {
        return parseProducts(from: productsString)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: deliveryDate) {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return deliveryDate
    }
    
    private func parseProducts(from string: String) -> [ProductoOrden] {
        return string.components(separatedBy: ", ")
            .compactMap { item in
                let components = item.components(separatedBy: ": ")
                guard components.count == 2 else { return nil }
                let nombre = components[0].trimmingCharacters(in: .whitespaces)
                let pesoString = components[1]
                    .replacingOccurrences(of: "g", with:"")
                    .trimmingCharacters(in: .whitespaces)
                guard let peso = Double(pesoString) else { return nil }
                return ProductoOrden(nombre: nombre, peso: peso)
            }
    }
}

struct ProductoOrden {
    let nombre: String
    let peso: Double
}
struct Producto {
    let nombre: String
    let peso: Double
}

struct Material: Codable, Identifiable, Hashable {
    var id: String { exit_code }
    let name: String
    let description: String
    let stock_weight: Int
    let exit_code: String
    let image: String
    let area: String
    var ultimaActualizacion: Date?
    var stockMinimo: Int?
    
    enum Area: String, Codable {
        case a = "Area A"
        case b = "Area B"
        case c = "Area C"
        case d = "Area D"
        case e = "Area E"
        case f = "Area F"
    }
    
    enum CodingKeys: String, CodingKey {
        case name, description
        case stock_weight = "stock_weight"
        case exit_code = "exit_code"
        case image = "image"
        case area
        case ultimaActualizacion = "ultima_actualizacion"
        case stockMinimo = "stock_minimo"
    }
    
    var safeImageURL: URL? {
        let cleanedURL = image
            .replacingOccurrences(of: " ", with: "%20")
            .replacingOccurrences(of: "+", with: "%20")
        return URL(string: cleanedURL)
    }
    
    func tieneStockBajo() -> Bool {
        guard let minimo = stockMinimo else { return false }
        return stock_weight <= minimo
    }
}

struct User: Codable {
    static var current = User(name: "Juan Pérez")
    let name: String
    var token: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case token
    }
}

struct WorkerData: Codable {
    let name: String
    let email: String
    let RFC: String
    let RFID: String
    let NSS: String
    let phone: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case email
        case RFC
        case RFID
        case NSS
        case phone
    }
}


struct Sensor: Decodable {
    let id: String
    let status: String?
    let temperatureC: Double?
    let humidityPercent: Double?
    let eventDate: Date
    let alertTriggered: Bool
    let alertMessage: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case status
        case temperatureC = "temperature_c"
        case humidityPercent = "humidity_percent"
        case eventDate = "event_date"
        case alertTriggered = "alert_triggered"
        case alertMessage = "alert_message"
    }
    
    // Propiedad computada para determinar el tipo
    var type: SensorType {
        if temperatureC != nil || humidityPercent != nil {
            return .temperatureHumidity
        } else if status != nil {
            return .light
        } else {
            return .pir
        }
    }
}

enum SensorType {
    case light
    case pir
    case temperatureHumidity
}
