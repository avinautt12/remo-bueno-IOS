import UIKit

class ProductoCell: UICollectionViewCell {
    
    // MARK: - Identificador y Nib
    static let identifier = "ProductoCell"
    static let nib = UINib(nibName: "ProductoCell", bundle: nil)
    
    // MARK: - Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var stockLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Contenedor principal
        containerView.layer.cornerRadius = 12
        containerView.layer.masksToBounds = false
        
        // Sombra
        containerView.layer.shadowColor = UIColor.blue.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 12).cgPath
        
        // Imagen
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .systemGray6
        
        // Etiquetas
        nameLabel.numberOfLines = 2
        nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        codeLabel.font = UIFont.systemFont(ofSize: 12)
        areaLabel.font = UIFont.systemFont(ofSize: 12)
        stockLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
    }
    
    // MARK: - Configuration
    func configure(with material: Material) {
        nameLabel.text = material.name
        codeLabel.text = "Código: \(material.exit_code)"
        areaLabel.text = material.area
        stockLabel.text = "Stock: \(material.stock_weight) g"
        
        loadImage(from: material.image)
    }
    
    private func loadImage(from urlString: String) {
        guard let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let imageUrl = URL(string: encodedString) else {
            imageView.image = UIImage(systemName: "photo")
            return
        }
        
        // Usar SDWebImage o Kingfisher en producción para caché
        URLSession.shared.dataTask(with: imageUrl) { [weak self] data, _, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
                    self.imageView.image = image
                } else {
                    self.imageView.image = UIImage(systemName: "photo")?
                        .withTintColor(.lightGray, renderingMode: .alwaysOriginal)
                }
            }
        }.resume()
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        // Actualizar sombra cuando cambia el tamaño
        containerView.layer.shadowPath = UIBezierPath(roundedRect: containerView.bounds, cornerRadius: 12).cgPath
    }
}
