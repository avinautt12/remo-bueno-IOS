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
        setupDynamicColors()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            setupDynamicColors()
            updateShadow()
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Contenedor principal
        containerView.layer.cornerRadius = 12
        containerView.layer.masksToBounds = false
        
        // Imagen
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .secondarySystemBackground
        
        // Etiquetas
        nameLabel.numberOfLines = 2
        nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        codeLabel.font = UIFont.systemFont(ofSize: 12)
        areaLabel.font = UIFont.systemFont(ofSize: 12)
        stockLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)

        updateShadow()
    }
    
    private func setupDynamicColors() {
        containerView.backgroundColor = UIColor { trait in
            return trait.userInterfaceStyle == .dark ? .systemGray6 : .systemBackground
        }
        
        nameLabel.textColor = .label
        codeLabel.textColor = .secondaryLabel
        areaLabel.textColor = .secondaryLabel
    }
    
    private func updateShadow() {
        containerView.layer.shadowColor = UIColor.label.cgColor
        containerView.layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.1 : 0.05
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
    }
    
    // MARK: - Configuration
    func configure(with material: Material) {
        nameLabel.text = material.name
        codeLabel.text = "Código: \(material.exit_code)"
        areaLabel.text = material.area
        stockLabel.text = "Stock: \(material.stock_weight) g"
        
        // Configurar color de stock
        if material.tieneStockBajo() {
            stockLabel.textColor = .systemRed
        } else {
            stockLabel.textColor = .systemGreen
        }
        
        loadImage(from: material.image)
    }
    
    private func loadImage(from urlString: String) {
        imageView.image = UIImage(systemName: "photo")?
            .withTintColor(.systemGray3, renderingMode: .alwaysOriginal)
        
        guard let cleanedURLString = urlString
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let imageUrl = URL(string: cleanedURLString) else {
            setPlaceholderImage()
            return
        }
        
        if let cachedImage = ImageCache.shared.image(forKey: cleanedURLString) {
            imageView.image = cachedImage
            return
        }
        
        URLSession.shared.dataTask(with: imageUrl) { [weak self] data, _, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error cargando imagen: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.setPlaceholderImage()
                }
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                ImageCache.shared.save(image: image, forKey: cleanedURLString)
                DispatchQueue.main.async {
                    self.imageView.image = image
                }
            } else {
                DispatchQueue.main.async {
                    self.setPlaceholderImage()
                }
            }
        }.resume()
    }
    
    private func setPlaceholderImage() {
        imageView.image = UIImage(systemName: "photo")?
            .withTintColor(.systemGray3, renderingMode: .alwaysOriginal)
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.shadowPath = UIBezierPath(
            roundedRect: containerView.bounds,
            cornerRadius: containerView.layer.cornerRadius
        ).cgPath
    }
}

// Caché simple para imágenes
class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {}
    
    func image(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func save(image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}
