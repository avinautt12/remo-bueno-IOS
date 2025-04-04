import UIKit

class InicioViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var logoutButton: UIButton!
    
    // MARK: - Propiedades
    private var orders: [Orden] = []
    private let refreshControl = UIRefreshControl()
    
    // MARK: - Ciclo de Vida
    override func viewDidLoad() {
        super.viewDidLoad()
        configurarInterfaz()
        configurarTabla()
        cargarDatosCache()
        obtenerDatos()
    }
    
    // MARK: - Configuración
    private func configurarInterfaz() {
        configurarBarraNavegacion()
        configurarEstilosBasicos()
    }
    
    private func configurarTabla() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(recargarDatos), for: .valueChanged)
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.tableFooterView = UIView()
    }
    
    private func configurarBarraNavegacion() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Productos",
            style: .plain,
            target: self,
            action: #selector(irAProductos))
    }
    
    private func configurarEstilosBasicos() {
        view.backgroundColor = .systemBackground
        tableView.backgroundColor = .systemGroupedBackground
    }
    
    // MARK: - Manejo de Datos
    private func cargarDatosCache() {
        if let ordenesCache = CacheManager.shared.getOrders() {
            self.orders = ordenesCache
            tableView.reloadData()
        }
    }
    
    private func obtenerDatos() {
        loadingIndicator.startAnimating()
        
        APIManager.shared.fetchOrders { [weak self] resultado in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.refreshControl.endRefreshing()
                
                switch resultado {
                case .success(let ordenes):
                    self?.actualizarDatos(con: ordenes)
                case .failure(let error):
                    self?.mostrarError(error.localizedDescription)
                }
            }
        }
    }
    
    private func actualizarDatos(con ordenes: [Orden]) {
        orders = ordenes
        tableView.reloadData()
        CacheManager.shared.saveOrders(ordenes)
    }
    
    // MARK: - Navegación
    @objc private func irAProductos() {
        let productosVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "ProductosViewController")
        navigationController?.pushViewController(productosVC, animated: true)
    }
    
    private func irADetalleOrden(_ orden: Orden) {
        print("Intentando navegar a detalle de orden: \(orden.id)")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let detalleVC = storyboard.instantiateViewController(withIdentifier: "OrderDetailViewController") as? OrderDetailViewController else {
            print("Error: No se pudo instanciar OrderDetailViewController")
            print("Identificadores disponibles: \(storyboard.value(forKey: "identifierToNibNameMap") ?? "N/A")")
            return
        }
        
        print("ViewController instanciado correctamente")
        detalleVC.order = orden
        print("Orden asignada: \(orden)")
        
        detalleVC.onStatusUpdated = { [weak self] ordenActualizada in
            print("Orden actualizada recibida: \(ordenActualizada.id)")
            self?.actualizarOrden(ordenActualizada)
        }
        
        if navigationController == nil {
            print("Error: navigationController es nil")
        } else {
            navigationController?.pushViewController(detalleVC, animated: true)
            print("Navegación iniciada")
        }
    }
    
    private func actualizarOrden(_ orden: Orden) {
        if let indice = orders.firstIndex(where: { $0.id == orden.id }) {
            orders[indice] = orden
            tableView.reloadRows(at: [IndexPath(row: indice, section: 0)], with: .automatic)
        }
    }
    
    // MARK: - Acciones
    @objc private func recargarDatos() {
        obtenerDatos()
    }
    
    @IBAction private func cerrarSesionTapped(_ sender: UIButton) {
        confirmarCierreSesion()
    }
    
    // MARK: - Alertas
    private func confirmarCierreSesion() {
        let alerta = UIAlertController(
            title: "Cerrar Sesión",
            message: "¿Estás seguro que deseas salir de tu cuenta?",
            preferredStyle: .alert
        )
        
        alerta.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alerta.addAction(UIAlertAction(title: "Salir", style: .destructive) { _ in
            self.cerrarSesion()
        })
        
        present(alerta, animated: true)
    }
    
    private func mostrarError(_ mensaje: String) {
        let alerta = UIAlertController(title: "Error", message: mensaje, preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "OK", style: .default))
        present(alerta, animated: true)
    }
    
    // MARK: - Cierre de Sesión
    private func cerrarSesion() {
        mostrarCargando()
        CacheManager.shared.clearCache()
        
        AuthService.shared.logout { [weak self] exito in
            DispatchQueue.main.async {
                self?.irALogin()
            }
        }
    }
    
    private func mostrarCargando() {
        let indicador = UIActivityIndicatorView(style: .medium)
        indicador.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: indicador)
    }
    
    private func irALogin() {
        let loginVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "LoginViewController")
        
        if let window = UIApplication.shared.windows.first {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = loginVC
            })
        }
    }
    
    // Reemplaza el método showOrderDetail con esto:
    private func showOrderDetail(_ order: Orden) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let detailVC = storyboard.instantiateViewController(withIdentifier: "OrderDetailViewController") as? OrderDetailViewController else {
            print("Error al instanciar OrderDetailViewController")
            return
        }
        
        detailVC.order = order
        
        detailVC.onStatusUpdated = { [weak self] updatedOrder in
            if let index = self?.orders.firstIndex(where: { $0.id == updatedOrder.id }) {
                self?.orders[index] = updatedOrder
                self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            }
        }
        
        // Presentación modal como alternativa temporal
        detailVC.modalPresentationStyle = .fullScreen
        present(detailVC, animated: true)
    }

}

// MARK: - UITableViewDataSource
extension InicioViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderCell.identifier, for: indexPath) as? OrderCell else {
            fatalError("No se pudo crear la celda OrderCell")
        }
        
        let order = orders[indexPath.row]
        cell.configure(with: order) { [weak self] in
            self?.showOrderDetail(order)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension InicioViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let order = orders[indexPath.row]
        showOrderDetail(order)
    }
}
