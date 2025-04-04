import UIKit

class PerfilViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    // Header Section
    @IBOutlet weak var profileImageView: UIImageView!
    
    // Personal Info Section
    @IBOutlet weak var personalInfoView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    
    // Work Info Section
    @IBOutlet weak var workInfoView: UIView!
    @IBOutlet weak var rfcLabel: UILabel!
    @IBOutlet weak var rfidLabel: UILabel!
    @IBOutlet weak var nssLabel: UILabel!
    
    // Actions Section
    @IBOutlet weak var changePasswordButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchWorkerData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Mi Perfil"
        view.backgroundColor = .systemGroupedBackground
        
        // Configurar imagen de perfil
        configureProfileImage()
        
        // Configurar secciones
        configurePersonalInfoSection()
        configureWorkInfoSection()
        
        // Configurar botón
        configureChangePasswordButton()
    }
    
    private func configureProfileImage() {
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemBlue
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.systemBlue.cgColor
    }
    
    private func configurePersonalInfoSection() {
        personalInfoView.backgroundColor = .systemBackground
        personalInfoView.layer.cornerRadius = 12
        personalInfoView.layer.shadowColor = UIColor.black.cgColor
        personalInfoView.layer.shadowOpacity = 0.1
        personalInfoView.layer.shadowOffset = CGSize(width: 0, height: 2)
        personalInfoView.layer.shadowRadius = 4
    }
    
    private func configureWorkInfoSection() {
        workInfoView.backgroundColor = .systemBackground
        workInfoView.layer.cornerRadius = 12
        workInfoView.layer.shadowColor = UIColor.black.cgColor
        workInfoView.layer.shadowOpacity = 0.1
        workInfoView.layer.shadowOffset = CGSize(width: 0, height: 2)
        workInfoView.layer.shadowRadius = 4
    }
    
    private func configureChangePasswordButton() {
        changePasswordButton.setTitle("Cambiar Contraseña", for: .normal)
        changePasswordButton.backgroundColor = .systemBlue
        changePasswordButton.setTitleColor(.white, for: .normal)
        changePasswordButton.layer.cornerRadius = 8
        changePasswordButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        // Efecto visual al presionar
        changePasswordButton.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        changePasswordButton.addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside])
    }

    @objc private func buttonTouchDown() {
        UIView.animate(withDuration: 0.1) {
            self.changePasswordButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.changePasswordButton.alpha = 0.8
        }
    }

    @objc private func buttonTouchUp() {
        UIView.animate(withDuration: 0.1) {
            self.changePasswordButton.transform = .identity
            self.changePasswordButton.alpha = 1.0
        }
    }
    
    // MARK: - Data Fetching
    private func fetchWorkerData() {
        let endpoint = "\(APIManager.shared.baseURL)/worker-data"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        APIManager.shared.addAuthHeader(to: &request)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                    return
                }
                
                guard let data = data else {
                    self?.showAlert(title: "Error", message: "No se recibieron datos")
                    return
                }
                
                do {
                    let workerData = try JSONDecoder().decode(WorkerData.self, from: data)
                    self?.updateUI(with: workerData)
                } catch {
                    self?.showAlert(title: "Error", message: "Error al decodificar los datos: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    private func updateUI(with workerData: WorkerData) {
        nameLabel.text = workerData.name
        emailLabel.text = workerData.email
        phoneLabel.text = workerData.phone
        rfcLabel.text = "RFC: \(workerData.RFC)"
        rfidLabel.text = "RFID: \(workerData.RFID)"
        nssLabel.text = "NSS: \(workerData.NSS)"
    }
    
    // MARK: - Actions
    @IBAction func changePasswordTapped(_ sender: UIButton) {
        showChangePasswordForm()
    }
    private func showChangePasswordForm() {
        let alert = UIAlertController(
            title: "Cambiar Contraseña",
            message: "Ingresa tu nueva contraseña (mínimo 8 caracteres)",
            preferredStyle: .alert
        )
        
        // Campo para contraseña actual
        alert.addTextField { textField in
            textField.placeholder = "Contraseña actual"
            textField.isSecureTextEntry = true
            textField.textContentType = .password
            textField.rightView = self.createEyeButton(for: textField)
            textField.rightViewMode = .always
        }
        
        // Campo para nueva contraseña
        alert.addTextField { textField in
            textField.placeholder = "Nueva contraseña"
            textField.isSecureTextEntry = true
            textField.textContentType = .newPassword
            textField.rightView = self.createEyeButton(for: textField)
            textField.rightViewMode = .always
        }
        
        // Campo para confirmar nueva contraseña
        alert.addTextField { textField in
            textField.placeholder = "Confirmar nueva contraseña"
            textField.isSecureTextEntry = true
            textField.textContentType = .newPassword
            textField.rightView = self.createEyeButton(for: textField)
            textField.rightViewMode = .always
        }
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Guardar", style: .default) { _ in
            self.handlePasswordChange(
                current: alert.textFields?[0].text ?? "",
                new: alert.textFields?[1].text ?? "",
                confirm: alert.textFields?[2].text ?? ""
            )
        })
        present(alert, animated: true)
    }

    private func createEyeButton(for textField: UITextField) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.tintColor = .gray
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        button.addTarget(self, action: #selector(togglePasswordVisibility(_:)), for: .touchUpInside)
        button.tag = 999 // Identificador para el textField asociado
        return button
    }

    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        guard let textField = sender.superview as? UITextField else { return }
        
        textField.isSecureTextEntry = !textField.isSecureTextEntry
        let imageName = textField.isSecureTextEntry ? "eye.slash" : "eye"
        sender.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    private func handlePasswordChange(current: String, new: String, confirm: String) {
        // Validación de campos vacíos
        guard !current.isEmpty, !new.isEmpty, !confirm.isEmpty else {
            showAlert(title: "Error", message: "Todos los campos son obligatorios")
            return
        }
        
        // Validación de coincidencia de contraseñas
        guard new == confirm else {
            showAlert(title: "Error", message: "Las nuevas contraseñas no coinciden")
            return
        }
        
        // Validación de longitud mínima
        guard new.count >= 8 else {
            showAlert(title: "Error", message: "La contraseña debe tener al menos 8 caracteres")
            return
        }
        
        // Validación de complejidad (opcional)
        let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$"
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        guard passwordTest.evaluate(with: new) else {
            showAlert(title: "Error", message: "La contraseña debe contener al menos una letra y un número")
            return
        }
        
        // Llamar al servidor para cambiar la contraseña
        changePasswordOnServer(current: current, new: new)
    }
    
    private func changePasswordOnServer(current: String, new: String) {
        let endpoint = "\(APIManager.shared.baseURL)/update-password"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        APIManager.shared.addAuthHeader(to: &request)
        
        let body: [String: Any] = [
            "current_password": current,
            "password": new,
            "password_confirmation": new
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            showAlert(title: "Error", message: "Error al preparar los datos para enviar")
            return
        }
        
        // Mostrar indicador de carga
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                activityIndicator.removeFromSuperview()
                
                if let error = error {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.showAlert(title: "Error", message: "Respuesta inválida del servidor")
                    return
                }
                
                // Imprimir respuesta para depuración
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Respuesta del servidor:", responseString)
                }
                
                switch httpResponse.statusCode {
                case 200:
                    self?.showAlert(title: "Éxito", message: "Contraseña cambiada correctamente") {
                        // Opcional: Cerrar sesión después de cambiar contraseña
                        AuthService.shared.logout { _ in
                            self?.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                    
                case 401:
                    self?.showAlert(title: "Error", message: "Contraseña actual incorrecta")
                    
                case 422:
                    self?.showAlert(title: "Error", message: "La nueva contraseña no cumple con los requisitos")
                    
                default:
                    self?.showAlert(title: "Error", message: "Error al cambiar la contraseña (Código: \(httpResponse.statusCode))")
                }
            }
        }.resume()
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension UIViewController {
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
