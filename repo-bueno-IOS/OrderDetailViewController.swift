import UIKit

class OrderDetailViewController: UIViewController {
    
    // MARK: - Outlets
    // Sección Información Básica
    
    @IBOutlet weak var orderIdLabel: UILabel!
    @IBOutlet weak var statusBadge: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var carrierLabel: UILabel!
    
    // Sección Productos
    @IBOutlet weak var productsTableView: UITableView!
    @IBOutlet weak var productsTableHeight: NSLayoutConstraint!
    
    // Sección Totales
    @IBOutlet weak var totalWeightLabel: UILabel!
    
    // Acciones
    @IBOutlet weak var actionButton: UIButton!
    
    // MARK: - Properties
    var order: Orden?
    var onStatusUpdated: ((Orden) -> Void)?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureWithOrder()
        setupTableView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableHeight()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Detalle de Orden"
        view.backgroundColor = .systemGroupedBackground
        
        // Estilo del badge de estado
        statusBadge.layer.cornerRadius = 4
        
        // Estilo del botón de acción
        actionButton.layer.cornerRadius = 8
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    }
    
    private func setupTableView() {
        productsTableView.register(ProductoOrdenCell.self, forCellReuseIdentifier: ProductoOrdenCell.identifier)
        productsTableView.dataSource = self
        productsTableView.delegate = self
        productsTableView.isScrollEnabled = false
        productsTableView.rowHeight = UITableView.automaticDimension
        productsTableView.separatorStyle = .none
        productsTableView.backgroundColor = .clear
    }
    
    // MARK: - Configuration
    private func configureWithOrder() {
        guard let order = order else { return }
        
        // Información básica
        orderIdLabel.text = "Orden #\(order.id)"
        dateLabel.text = "Fecha de entrega: \(order.formattedDate)"
        carrierLabel.text = "Zona de entrega: \(order.carrier)"
        
        // Peso total (convertir gramos a Kg)
        totalWeightLabel.text = "\(order.totalWeight) Kg)"
        
        // Configurar estado
        statusLabel.text = order.status.localizedCapitalized
        switch order.status.lowercased() {
        case "pending":
            statusBadge.backgroundColor = .systemOrange
            actionButton.setTitle("Marcar como Completado", for: .normal)
            actionButton.backgroundColor = .systemGreen
        case "completed":
            statusBadge.backgroundColor = .systemGreen
            actionButton.setTitle("Revertir a Pendiente", for: .normal)
            actionButton.backgroundColor = .systemOrange
        default:
            statusBadge.backgroundColor = .systemGray
            actionButton.isHidden = true
        }
        
        productsTableView.reloadData()
    }
    
    private func updateTableHeight() {
        let totalHeight = productsTableView.contentSize.height
        productsTableHeight.constant = totalHeight
        view.layoutIfNeeded()
    }
    
    // MARK: - Actions
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        guard let order = order else { return }
        
        let newStatus = order.status == "Pending" ? "Completed" : "Pending"
        let statusText = newStatus == "Pending" ? "Pendiente" : "Completado"
        
        let alert = UIAlertController(
            title: "Cambiar estado",
            message: "¿Estás seguro de cambiar el estado a \(statusText)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirmar", style: .default) { _ in
            self.updateOrderStatus(newStatus: newStatus)
        })
        
        present(alert, animated: true)
    }
    
    private func updateOrderStatus(newStatus: String) {
        guard var order = order else { return }
        
        self.order = order
        self.configureWithOrder()
        self.onStatusUpdated?(order)
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
        return 44
    }
}
