//
//  PerfilViewController.swift
//  repo-bueno-IOS
//
//  Created by mac on 03/03/25.
//

import UIKit

class PerfilViewController: UIViewController {

    @IBOutlet weak var lbNSS: UILabel!
    @IBOutlet weak var lbTelefono: UILabel!
    @IBOutlet weak var lbCURP: UILabel!
    @IBOutlet weak var imgPerfil: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imgPerfil.layer.cornerRadius = imgPerfil.frame.size.width / 2
        imgPerfil.clipsToBounds = true
        imgPerfil.layer.borderWidth = 2
        imgPerfil.layer.borderColor = UIColor.white.cgColor
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            print("Token recuperado: \(token)")
            obtenerDatosUsuario(token: token)  // Llamamos a la función para obtener los datos reales
        } else {
            print("No se encontró token. Redirigir al login.")
            // Aquí puedes hacer que el usuario vuelva al login si no hay token
        }
    }

    
    func obtenerDatosUsuario(token: String) {
        let url = URL(string: "https://b88d-177-244-54-50.ngrok-free.app/api/workers")!  // Reemplaza con tu URL real
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error al obtener datos: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                // Decodificar la respuesta JSON
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                DispatchQueue.main.async {
                    self.lbTelefono.text = json?["telefono"] as? String ?? "No disponible"
                    self.lbCURP.text = json?["curp"] as? String ?? "No disponible"
                    self.lbNSS.text = json?["nss"] as? String ?? "No disponible"
                }
            } catch {
                print("Error al parsear JSON: \(error.localizedDescription)")
            }
        }
        task.resume()
    }

}
