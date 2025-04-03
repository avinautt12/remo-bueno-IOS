import UIKit

class MaterialViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var materialImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var stockLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    // MARK: - Properties
    var material: Material? {
        didSet {
            guard isViewLoaded else { return }
            configureWithMaterial()
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureWithMaterial()
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Configuración de imagen
        materialImageView.layer.cornerRadius = 12
        materialImageView.layer.borderWidth = 1
        materialImageView.layer.borderColor = UIColor.systemGray4.cgColor
        materialImageView.contentMode = .scaleAspectFit
        
        materialImageView.image = UIImage(systemName: "shippingbox")
        
        // Configuración texto
        nameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        descriptionTextView.isEditable = false
        
        // Valores por defecto
        resetUI()
    }
    
    private func resetUI() {
        title = "Detalle de Material"
        nameLabel.text = "Nombre no disponible"
        codeLabel.text = "Código: --"
        areaLabel.text = "Área: --"
        stockLabel.text = "Stock: -- g"
        descriptionTextView.text = "Descripción no disponible"
    }
    
    private func configureWithMaterial() {
        guard let material = material else {
            resetUI()
            return
        }
        
        title = material.name
        nameLabel.text = material.name
        codeLabel.text = "Código: \(material.exit_code)"
        areaLabel.text = "Área: \(material.area)"
        stockLabel.text = "Stock: \(material.stock_weight) g"
        descriptionTextView.text = material.description
        
        // Carga de imagen segura
        if let urlString = material.image.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: urlString) {
            materialImageView.load(url: url)
        } else {
            materialImageView.image = UIImage(systemName: "exclamationmark.triangle")
        }
    }
}

// Extensión mejorada para carga de imágenes
extension UIImageView {
    func load(url: URL, placeholder: UIImage? = UIImage(systemName: "shippingbox")) {
        self.image = placeholder
        
        DispatchQueue.global().async { [weak self] in
            URLSession.shared.dataTask(with: url) { data, _, error in
                guard let data = data, error == nil else {
                    DispatchQueue.main.async {
                        self?.image = UIImage(systemName: "exclamationmark.triangle")
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self?.image = UIImage(data: data) ?? placeholder
                }
            }.resume()
        }
    }
}
