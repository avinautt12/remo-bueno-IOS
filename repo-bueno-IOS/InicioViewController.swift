//
//  InicioViewController.swift
//  repo-bueno-IOS
//
//  Created by mac on 03/03/25.
//

import UIKit

class InicioViewController: UIViewController {

    @IBOutlet weak var UserIconButton: UIBarButtonItem!
    

        override func viewDidLoad() {
            super.viewDidLoad()

            // Do any additional setup after loading the view.
        }

    @IBAction func UserIconTapped(_ sender: UIBarButtonItem) {
            navigateToPerfil()
        }
    
    func navigateToPerfil() {
        // Cargar el storyboard "InicioStoryboard"
        let storyboard = UIStoryboard(name: "PerfilStoryboard", bundle: nil) //cambiarlo a donde quieras
        
        // Instanciar el controlador inicial del storyboard
        if let homeVC = storyboard.instantiateInitialViewController() {
            // Cambiar el estilo de presentación a full screen (si es necesario)
            homeVC.modalPresentationStyle = .fullScreen
            
            // Presentar la vista
            self.present(homeVC, animated: true, completion: nil)
            
            print("Navegación al inicio exitosa.")
        } else {
            print("No se pudo cargar el controlador inicial del storyboard InicioStoryboard.")
        }
    }


    
    
}
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


