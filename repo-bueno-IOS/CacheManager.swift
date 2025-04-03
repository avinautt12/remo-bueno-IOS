import Foundation

class CacheManager {
    static let shared = CacheManager()
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Orders
    func saveOrders(_ orders: [Orden]) {
        do {
            let data = try encoder.encode(orders)
            userDefaults.set(data, forKey: "cachedOrders")
            userDefaults.synchronize()
        } catch {
            print("Error saving orders: \(error.localizedDescription)")
        }
    }
    
    func getOrders() -> [Orden]? {
        guard let data = userDefaults.data(forKey: "cachedOrders") else { return nil }
        
        do {
            return try decoder.decode([Orden].self, from: data)
        } catch {
            print("Error loading orders: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Materials
    func saveMaterials(_ materials: [Material]) {
        do {
            let data = try encoder.encode(materials)
            userDefaults.set(data, forKey: "cachedMaterials")
            userDefaults.synchronize()
        } catch {
            print("Error saving materials: \(error.localizedDescription)")
        }
    }
    
    func getMaterials() -> [Material]? {
        guard let data = userDefaults.data(forKey: "cachedMaterials") else { return nil }
        
        do {
            return try decoder.decode([Material].self, from: data)
        } catch {
            print("Error loading materials: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Clear Cache
    func clearCache() {
        userDefaults.removeObject(forKey: "cachedOrders")
        userDefaults.removeObject(forKey: "cachedMaterials")
        userDefaults.synchronize()
    }
}
