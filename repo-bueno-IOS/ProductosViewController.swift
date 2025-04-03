import UIKit

class ProductosViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    private var productos: [Material] = []
    private var filteredProductos: [Material] = []
    private let refreshControl = UIRefreshControl()
    private var currentTask: URLSessionDataTask?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadProductos()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        currentTask?.cancel() // Cancelar petición si la vista desaparece
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Productos"
        
        // Configurar collection view
        collectionView.register(ProductoCell.nib, forCellWithReuseIdentifier: ProductoCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // Configurar refresh control
        refreshControl.tintColor = .systemBlue
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        
        // Configurar search bar
        searchBar.delegate = self
        searchBar.placeholder = "Buscar por nombre o código"
        searchBar.searchTextField.backgroundColor = .systemBackground
        
        // Configurar layout
        configureCollectionViewLayout()
    }
    
    private func configureCollectionViewLayout() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let width = collectionView.frame.width - 32 // 16 de padding en cada lado
        layout.itemSize = CGSize(width: width, height: 100)
        
        collectionView.collectionViewLayout = layout
    }
    
    // MARK: - Data Management
    private func loadProductos() {
        // Cancelar tarea anterior si existe
        currentTask?.cancel()
        
        loadingIndicator.startAnimating()
        
        currentTask = APIManager.shared.fetchMaterials { [weak self] result in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.refreshControl.endRefreshing()
                
                switch result {
                case .success(let materiales):
                    self?.productos = materiales
                    self?.filteredProductos = materiales
                    self?.collectionView.reloadData()
                    
                    if materiales.isEmpty {
                        self?.showEmptyState(message: "No hay productos disponibles")
                    }
                    
                case .failure(let error):
                    self?.showErrorAlert(message: error.localizedDescription)
                    if self?.productos.isEmpty ?? true {
                        self?.showEmptyState(message: "Error al cargar productos")
                    }
                }
            }
        }
    }


    private func handleSuccessLoad(with materiales: [Material]) {
        productos = materiales
        filteredProductos = materiales
        collectionView.reloadData()
        
        // Mostrar mensaje si no hay productos
        if productos.isEmpty {
            showEmptyState(message: "No hay productos disponibles")
        } else {
            hideEmptyState()
        }
    }
    
    private func handleErrorLoad(error: Error) {
        showErrorAlert(message: error.localizedDescription)
        
        // Mostrar estado vacío si no hay datos
        if productos.isEmpty {
            showEmptyState(message: "No se pudieron cargar los productos")
        }
    }
    
    @objc private func refreshData() {
        loadProductos()
    }
    
    // MARK: - Filtering
    private func filterProductos(searchText: String? = nil) {
        filteredProductos = productos.filter { producto in
            let searchMatch = searchText?.isEmpty ?? true ||
            producto.name.localizedCaseInsensitiveContains(searchText ?? "") ||
            producto.exit_code.localizedCaseInsensitiveContains(searchText ?? "")
            
            return searchMatch
        }
        
        collectionView.reloadData()
        
        // Mostrar mensaje si no hay resultados
        if filteredProductos.isEmpty {
            showEmptyState(message: "No se encontraron resultados")
        } else {
            hideEmptyState()
        }
    }
    
    // MARK: - Empty State
    private func showEmptyState(message: String) {
        let emptyView = UIView(frame: CGRect(x: 0, y: 0, width: collectionView.bounds.width, height: collectionView.bounds.height))
        
        let label = UILabel()
        label.text = message
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        
        emptyView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor, constant: -32)
        ])
        
        collectionView.backgroundView = emptyView
    }
    
    private func hideEmptyState() {
        collectionView.backgroundView = nil
    }
    
    // MARK: - Navigation
    private func showDetail(for producto: Material) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "MaterialDetailVC") as? MaterialViewController {
            detailVC.material = producto
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
    
    // MARK: - Alerts
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - CollectionView DataSource & Delegate
extension ProductosViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredProductos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ProductoCell.identifier,
            for: indexPath
        ) as? ProductoCell else {
            fatalError("No se pudo dequeue la celda ProductoCell")
        }
        
        cell.configure(with: filteredProductos[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        showDetail(for: filteredProductos[indexPath.item])
    }
}

// MARK: - SearchBar Delegate
extension ProductosViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterProductos(searchText: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        filterProductos(searchText: nil)
    }
}
