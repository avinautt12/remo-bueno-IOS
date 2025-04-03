import UIKit

class PerfilViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var rfcLabel: UILabel!
    @IBOutlet weak var rfidLabel: UILabel!
    @IBOutlet weak var nssLabel: UILabel!
    @IBOutlet weak var changePasswordButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        
        // Configurar imagen de perfil
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemBlue
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true

        
        // Configurar botones
        changePasswordButton.setTitle("Cambiar Contraseña", for: .normal)
        changePasswordButton.layer.cornerRadius = 8
        
        
    }
    
    // MARK: - Data
    private func loadUserData() {
        // Aquí cargarías los datos reales del usuario
        // Ejemplo con datos estáticos:
        nameLabel.text = "Juan Pérez López"
        emailLabel.text = "juan.perez@empresa.com"
        rfcLabel.text = "PERJ820101ABC"
        rfidLabel.text = "RFID-1234-5678"
        nssLabel.text = "12345678901"
    }
    
    // MARK: - Actions
    @IBAction func changePasswordTapped(_ sender: UIButton) {
        showChangePasswordForm()
    }
    

    
    // MARK: - Private Methods
    private func showChangePasswordForm() {
        let alert = UIAlertController(
            title: "Cambiar Contraseña",
            message: "Ingresa tu nueva contraseña",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Contraseña actual"
            textField.isSecureTextEntry = true
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Nueva contraseña"
            textField.isSecureTextEntry = true
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Confirmar nueva contraseña"
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Guardar", style: .default) { _ in
            // Validar y cambiar contraseña
            self.changePassword(
                current: alert.textFields?[0].text ?? "",
                new: alert.textFields?[1].text ?? "",
                confirm: alert.textFields?[2].text ?? ""
            )
        })
        
        present(alert, animated: true)
    }
    
    private func changePassword(current: String, new: String, confirm: String) {
        // Validaciones básicas
        guard !current.isEmpty, !new.isEmpty, !confirm.isEmpty else {
            showAlert(title: "Error", message: "Todos los campos son obligatorios")
            return
        }
        
        guard new == confirm else {
            showAlert(title: "Error", message: "Las contraseñas no coinciden")
            return
        }
        
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
