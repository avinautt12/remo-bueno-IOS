import UIKit

class OrderDetailViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var orderIdLabel: UILabel!
    @IBOutlet weak var statusBadge: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var carrierLabel: UILabel!
    @IBOutlet weak var productsTableView: UITableView!
    @IBOutlet weak var productsTableHeight: NSLayoutConstraint!
    @IBOutlet weak var summaryView: UIView!
    @IBOutlet weak var totalWeightLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var carrierVerificationField: UITextField!
    @IBOutlet weak var verificationView: UIView!
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    // MARK: - Properties
    var order: Orden?
    var onStatusUpdated: ((Orden) -> Void)?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureWithOrder()
        setupTableView()
        setupCustomBackButton()
        setupKeyboardDismissal()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableHeight()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Detalle de Orden"
        view.backgroundColor = .systemGroupedBackground
        
        if let headerTopConstraint = headerView.constraints.first(where: {
            $0.firstAttribute == .top && $0.firstItem as? UIView == headerView
        }) {
            headerTopConstraint.constant = 60 // Ajusta este valor según necesites
        }
        
        // Configurar header
        headerView.backgroundColor = .systemBackground
        headerView.layer.cornerRadius = 12
        headerView.layer.shadowColor = UIColor.black.cgColor
        headerView.layer.shadowOpacity = 0.1
        headerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        headerView.layer.shadowRadius = 4
        
        // Configurar status badge
        statusBadge.layer.cornerRadius = 4
        
        // Configurar summary view
        summaryView.backgroundColor = .systemBackground
        summaryView.layer.cornerRadius = 12
        summaryView.layer.shadowColor = UIColor.black.cgColor
        summaryView.layer.shadowOpacity = 0.1
        summaryView.layer.shadowOffset = CGSize(width: 0, height: 2)
        summaryView.layer.shadowRadius = 4
        
        // Configurar botón de acción
        actionButton.layer.cornerRadius = 8
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        actionButton.layer.shadowColor = UIColor.black.cgColor
        actionButton.layer.shadowOpacity = 0.1
        actionButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        actionButton.layer.shadowRadius = 4
        
        // Configurar vista de verificación
        verificationView.backgroundColor = .systemBackground
        verificationView.layer.cornerRadius = 12
        verificationView.layer.shadowColor = UIColor.black.cgColor
        verificationView.layer.shadowOpacity = 0.1
        verificationView.layer.shadowOffset = CGSize(width: 0, height: 2)
        verificationView.layer.shadowRadius = 4
        verificationView.isHidden = true
        
        // Configurar campo de verificación
        carrierVerificationField.placeholder = "Ingrese código del carrier"
        carrierVerificationField.layer.cornerRadius = 8
        carrierVerificationField.layer.borderWidth = 1
        carrierVerificationField.layer.borderColor = UIColor.systemGray4.cgColor
        carrierVerificationField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        carrierVerificationField.leftViewMode = .always
        carrierVerificationField.clearButtonMode = .whileEditing
        
        // Configurar botón de verificación
        verifyButton.layer.cornerRadius = 8
        verifyButton.backgroundColor = .systemBlue
        verifyButton.setTitleColor(.white, for: .normal)
        verifyButton.setTitle("Verificar Código", for: .normal)
        verifyButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        // Configurar mensaje de error
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.isHidden = true
    }
    
    private func setupTableView() {
        productsTableView.register(ProductoOrdenCell.self, forCellReuseIdentifier: ProductoOrdenCell.identifier)
        productsTableView.dataSource = self
        productsTableView.delegate = self
        productsTableView.isScrollEnabled = false
        productsTableView.rowHeight = UITableView.automaticDimension
        productsTableView.estimatedRowHeight = 60
        productsTableView.separatorStyle = .none
        productsTableView.backgroundColor = .clear
    }
    
    private func setupCustomBackButton() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "arrow.backward"), for: .normal)
        backButton.setTitle(" Volver", for: .normal)
        backButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        view.bringSubviewToFront(backButton)
    }
    
    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func backButtonPressed() {
        if navigationController?.viewControllers.count ?? 0 > 1 {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Configuration
    private func configureWithOrder() {
        guard let order = order else { return }
        
        orderIdLabel.text = "Orden #\(order.id)"
        dateLabel.text = "📅 \(order.formattedDate)"
        carrierLabel.text = "🚚 \(order.carrier)"
        
        let weightInKg = Double(order.totalWeight) / 1000
        totalWeightLabel.text = String(format: "Peso total: %.2f Kg", weightInKg)
        
        statusLabel.text = order.status.localizedCapitalized
        switch order.status.lowercased() {
        case "pending":
            statusBadge.backgroundColor = .systemOrange
            actionButton.setTitle("✅ Marcar como Completado", for: .normal)
            actionButton.backgroundColor = .systemGreen
        case "completed":
            statusBadge.backgroundColor = .systemGreen
            actionButton.isHidden = true
        default:
            statusBadge.backgroundColor = .systemGray
            actionButton.isHidden = true
        }
        
        productsTableView.reloadData()
    }
    
    private func updateTableHeight() {
        productsTableHeight.constant = productsTableView.contentSize.height
        view.layoutIfNeeded()
    }
    
    // MARK: - Actions
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        verificationView.isHidden = false
        carrierVerificationField.becomeFirstResponder()
    }
    
    @IBAction func verifyButtonTapped(_ sender: UIButton) {
        completeOrderWithVerification()
    }
    
    private func completeOrderWithVerification() {
        guard let order = order else { return }
        
        let carrierCode = carrierVerificationField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // Validación básica
        if carrierCode.isEmpty {
            showError(message: "Debes ingresar el código del carrier")
            return
        }
        
        print("Código ingresado: '\(carrierCode)'")
        print("Código esperado: '\(order.carrier)'")
        print("¿Son iguales?: \(carrierCode == order.carrier)")
        print("¿Son iguales sin case?: \(carrierCode.lowercased() == order.carrier.lowercased())")
        print("Orden id: \(order.id)")
        
        // Limpia cualquier error previo
        errorLabel.isHidden = true
        
        // Mostrar indicador de actividad
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        // Preparar la solicitud
        let endpoint = "\(APIManager.shared.baseURL)/delivery/\(order.id)/complete"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        APIManager.shared.addAuthHeader(to: &request)
        
        let body: [String: Any] = ["carrier": carrierCode]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            activityIndicator.removeFromSuperview()
            showAlert(title: "Error", message: "Error al preparar los datos para enviar")
            return
        }
        
        // Enviar solicitud
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                activityIndicator.removeFromSuperview()
                
                if let error = error {
                    self?.showAlert(title: "Error de conexión", message: error.localizedDescription)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.showAlert(title: "Error", message: "Respuesta inválida del servidor")
                    return
                }
                
                switch httpResponse.statusCode {
                case 200:
                    // Éxito - actualizar la orden
                    var updatedOrder = order
                    updatedOrder.status = "Completed"
                    self?.order = updatedOrder
                    
                    // Actualizar UI
                    self?.configureWithOrder()
                    self?.carrierVerificationField.text = ""
                    self?.verificationView.isHidden = true
                    self?.onStatusUpdated?(updatedOrder)
                    
                    self?.showAlert(title: "Éxito", message: "Orden marcada como completada")
                    
                case 400:
                    // Error específico del carrier
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        self?.showError(message: message)
                    } else {
                        self?.showError(message: "Código de carrier incorrecto")
                    }
                    
                default:
                    self?.showAlert(title: "Error", message: "Error inesperado (Código: \(httpResponse.statusCode))")
                }
            }
        }.resume()
    }

    private func showError(message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        carrierVerificationField.layer.borderColor = UIColor.systemRed.cgColor
        
        // Animación de shake
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: carrierVerificationField.center.x - 10, y: carrierVerificationField.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: carrierVerificationField.center.x + 10, y: carrierVerificationField.center.y))
        carrierVerificationField.layer.add(animation, forKey: "position")
        
        // Restaurar el borde después de 2 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.carrierVerificationField.layer.borderColor = UIColor.systemGray4.cgColor
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension OrderDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return order?.products.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductoOrdenCell.identifier, for: indexPath) as? ProductoOrdenCell,
              let product = order?.products[indexPath.row] else {
            return UITableViewCell()
        }
        
        cell.configure(with: product)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
