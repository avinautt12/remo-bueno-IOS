import UIKit

class SensoresViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contenedorStackView: UIStackView!
    @IBOutlet weak var luzView: UIView!
    @IBOutlet weak var pirView: UIView!
    @IBOutlet weak var temHumView: UIView!
    @IBOutlet weak var LuzImg: UIImageView!
    @IBOutlet weak var pirImage: UIImageView!
    @IBOutlet weak var humedadTemperaturaImage: UIImageView!
    @IBOutlet weak var luzLabel: UILabel!
    @IBOutlet weak var deteccionLabel: UILabel!
    @IBOutlet weak var humedadLabel: UILabel!
    @IBOutlet weak var temperaturaLabel: UILabel!
    @IBOutlet weak var ultimaActualizacionLabel: UILabel!
    @IBOutlet weak var PIRindicadorView: UIView!
    @IBOutlet weak var HTIndicadorView: UIView!
    @IBOutlet weak var LuzIndicadorView: UIView!
    @IBOutlet weak var AreasSegmentedControl: UISegmentedControl!
    
    // MARK: - Properties
    private var timer: Timer?
    private let refreshControl = UIRefreshControl()
    private var lastUpdateDate: Date?
    private var sensoresPorArea: [Int: [Sensor]] = [:] // Clave ahora es Int
    private var areasDisponibles: [Area] = [] {
        didSet {
            updateAreaSegmentedControl()
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupRefreshControl()
        loadAreas()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startAutoRefresh()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoRefresh()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        scrollView.backgroundColor = .clear
        
        AreasSegmentedControl.removeAllSegments()
        AreasSegmentedControl.addTarget(self, action: #selector(areaSelectionChanged(_:)), for: .valueChanged)
        
        configureSensorView(luzView, title: "Sensor de Luz (Global)")
        configureSensorView(temHumView, title: "Sensor Ambiental")
        configureSensorView(pirView, title: "Sensor de Presencia")
        
        LuzImg.image = UIImage(systemName: "lightbulb")
        LuzImg.contentMode = .scaleAspectFit
        LuzImg.clipsToBounds = false
        
        pirImage.image = UIImage(systemName: "person")
        humedadTemperaturaImage.image = UIImage(systemName: "thermometer")
        
        [luzView, temHumView, pirView].forEach {
            $0?.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        }
        
        resetSensorViews()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(refreshData))
        tapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(tapGesture)
    }
    
    private func resetSensorViews() {
        luzLabel.text = "Cargando..."
        deteccionLabel.text = "Detección: --"
        humedadLabel.text = "Humedad: --%"
        temperaturaLabel.text = "Temperatura: --°C"
        ultimaActualizacionLabel.text = "Última actualización: --"
        
        [PIRindicadorView, HTIndicadorView, LuzIndicadorView].forEach {
            $0?.backgroundColor = .systemGray4
            $0?.layer.cornerRadius = ($0?.frame.width ?? 0) / 2
            $0?.layer.borderWidth = 1
            $0?.layer.borderColor = UIColor.systemGray3.cgColor
        }
    }
    
    @objc private func areaSelectionChanged(_ sender: UISegmentedControl) {
        let areaSeleccionada = areasDisponibles[sender.selectedSegmentIndex]
        if let sensores = sensoresPorArea[areaSeleccionada.id] { // Usar Int como clave
            updateUI(with: sensores)
        }else {
            loadSensorsForCurrentArea()
        }
    }
    
    // MARK: - Data Loading
    private func loadSensorsForCurrentArea() {
        guard !areasDisponibles.isEmpty else {
            print("⚠️ No hay áreas disponibles - Recargando áreas...")
            loadAreas()
            return
        }
        
        let areaSeleccionada = areasDisponibles[AreasSegmentedControl.selectedSegmentIndex]
        let areaId = areaSeleccionada.id
        print("🔄 Cargando sensores para área: \(areaSeleccionada.name)")
        
        showLoadingState()
        
        SensorManager.shared.fetchSensors(for: areaId) { [weak self] (result: Result<[Sensor], SensorManager.SensorError>) in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                
                switch result {
                case .success(let sensors):
                    print("✅ Sensores recibidos: \(sensors.count) para área \(areaSeleccionada.name)")
                    self?.sensoresPorArea[areaId] = sensors
                    self?.updateUI(with: sensors)
                case .failure(let error):
                    print("❌ Error cargando sensores: \(error.localizedDescription)")
                    self?.handleError(error)
                }
            }
        }
    }
    
    private func loadAreas() {
        print("🔄 Iniciando carga de áreas...")
        SensorManager.shared.fetchAreas { [weak self] (result: Result<[Area], SensorManager.SensorError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let areas):
                    print("✅ Áreas recibidas: \(areas.map { $0.name })")
                    self?.areasDisponibles = areas
                    if !areas.isEmpty {
                        self?.loadSensorsForCurrentArea()
                        self?.loadGlobalLightSensor()
                    } else {
                        print("⚠️ El servidor devolvió 0 áreas")
                        self?.showAlert(title: "Sin áreas", message: "No se encontraron áreas disponibles")
                    }
                case .failure(let error):
                    print("❌ Error cargando áreas: \(error.localizedDescription)")
                    self?.handleError(error)
                }
            }
        }
    }

    private func loadGlobalLightSensor() {
        SensorManager.shared.fetchLightSensor { [weak self] (result: Result<Sensor, SensorManager.SensorError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let sensor):
                    self?.updateLightUI(with: sensor)
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        }
    }
    
    // MARK: - Refresh Control
    private func setupRefreshControl() {
        refreshControl.tintColor = .systemBlue
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        scrollView.refreshControl = refreshControl
    }

    @objc private func refreshData() {
        loadSensorsForCurrentArea()
        loadGlobalLightSensor()
    }

    // MARK: - Auto Refresh
    private func startAutoRefresh() {
        stopAutoRefresh()
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.refreshData()
        }
    }

    private func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - UI Configuration
    private func configureSensorView(_ view: UIView, title: String) {
        view.backgroundColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                UIColor.systemGray6 :
                UIColor.systemBackground
        }
        
        view.layer.shadowColor = UIColor.label.cgColor
        view.layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.2 : 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 6
        view.layer.cornerRadius = 14
        view.layer.borderWidth = traitCollection.userInterfaceStyle == .dark ? 0.5 : 0
        view.layer.borderColor = UIColor.separator.cgColor
        
        if let stackView = view.subviews.first(where: { $0 is UIStackView }) {
            stackView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 44),
                stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12)
            ])
        }
    }
    
    // MARK: - UI Updates
    private func updateUI(with sensors: [Sensor]) {
        lastUpdateDate = Date()
        updateLastUpdateLabel()
        
        pirView.isHidden = true
        temHumView.isHidden = true
        
        for sensor in sensors {
            switch sensor.sensorType {
            case "Ambiental":
                updateTempHumUI(with: sensor)
            case "Luz":
                updateLightUI(with: sensor)
            case "Presencia":
                updatePirUI(with: sensor)
            default:
                break
            }
        }
    }
    
    private func updateLastUpdateLabel() {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
    }
    
    private func updateLightUI(with sensor: Sensor) {
        luzView.isHidden = false
        luzLabel.text = "Estado: \(sensor.status ?? "--")"
        
        let isLightOn = sensor.status?.lowercased() == "on"
        LuzImg.image = UIImage(systemName: isLightOn ? "lightbulb.fill" : "lightbulb")
        LuzImg.tintColor = isLightOn ? .systemYellow : .systemGray2
        LuzIndicadorView.backgroundColor = isLightOn ? .systemGreen : .systemRed
        

    }

    private func updateTempHumUI(with sensor: Sensor) {
        temHumView.isHidden = false
        
        if let temp = sensor.temperature_c {
            temperaturaLabel.text = "Temperatura: \(temp)°C"
        }
        
        if let humidity = sensor.humidity_percent {
            humedadLabel.text = "Humedad: \(humidity)%"
        }
        
    }

    private func updatePirUI(with sensor: Sensor) {
        pirView.isHidden = false
        deteccionLabel.text = "Detección: \(sensor.alert_triggered ? "Activa" : "Inactiva")"
        
        pirImage.image = UIImage(systemName: sensor.alert_triggered ? "person.fill" : "person")
        pirImage.tintColor = sensor.alert_triggered ? .systemRed : .systemGreen
        PIRindicadorView.backgroundColor = sensor.alert_triggered ? .systemRed : .systemGreen

    }


    // MARK: - Helpers
    private func updateAreaSegmentedControl() {
        AreasSegmentedControl.removeAllSegments()
        for (index, area) in areasDisponibles.enumerated() {
            AreasSegmentedControl.insertSegment(withTitle: area.name, at: index, animated: false)
        }
        AreasSegmentedControl.selectedSegmentIndex = 0
    }
    
    private func handleError(_ error: Error) {
        let errorMessage: String
        
        switch error {
        case SensorManager.SensorError.noSensorsInArea:
            errorMessage = "No hay sensores en esta área actualmente"
            pirView.isHidden = true
            temHumView.isHidden = true
        default:
            errorMessage = error.localizedDescription
        }
        
        let alert = UIAlertController(
            title: "Atención",
            message: errorMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showLoadingState() {
        luzLabel.text = "Cargando..."
        temperaturaLabel.text = "Cargando..."
        humedadLabel.text = "Cargando..."
        
        [LuzIndicadorView, HTIndicadorView].forEach {
            $0?.backgroundColor = .systemGray4
        }
    }
}
