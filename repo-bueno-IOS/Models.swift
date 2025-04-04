import Foundation

struct OrdenResponse: Codable {
    let data: [Orden]
}


struct Orden: Codable, Identifiable {
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
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: deliveryDate) {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return deliveryDate
    }
    
    var products: [ProductoOrden] {
        return productsString.components(separatedBy: ", ")
            .compactMap { item in
                let components = item.components(separatedBy: ": ")
                guard components.count == 2 else { return nil }
                let nombre = components[0]
                let pesoString = components[1].replacingOccurrences(of: "g", with: "")
                let peso = Double(pesoString) ?? 0.0
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
    
    // URL segura para la imagen
    var safeImageURL: URL? {
        let cleanedURL = image
            .replacingOccurrences(of: " ", with: "%20")
            .replacingOccurrences(of: "+", with: "%20")
        return URL(string: cleanedURL)
    }
    
    // Método para verificar stock bajo
    func tieneStockBajo() -> Bool {
        guard let minimo = stockMinimo else { return false }
        return stock_weight <= minimo
    }
}

struct User: Codable {
    static var current = User(name: "Juan Pérez")
    let name: String
    var token: String? // Para autenticación
    
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
