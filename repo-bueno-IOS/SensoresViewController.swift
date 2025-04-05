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
    
    // MARK: - Properties
    private var sensors: [Sensor] = []
    private let refreshControl = UIRefreshControl()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupRefreshControl()
        loadSensors()
    }
    
    // MARK: - Setup
    private func setupUI() {
        
        // Configurar vistas de sensores
        [luzView, pirView, temHumView].forEach { view in
            view?.layer.cornerRadius = 12
            view?.layer.shadowColor = UIColor.blue.cgColor
            view?.layer.shadowOpacity = 0.1
            view?.layer.shadowOffset = CGSize(width: 0, height: 2)
            view?.layer.shadowRadius = 4
        }
        
        // Configurar imágenes
        LuzImg.tintColor = .systemYellow
        pirImage.tintColor = .systemBlue
        humedadTemperaturaImage.tintColor = .systemGreen
        
        // Configurar indicadores
        [PIRindicadorView, HTIndicadorView, LuzIndicadorView].forEach {
            $0?.layer.cornerRadius = ($0?.frame.width ?? 0) / 2
            $0?.backgroundColor = .systemGray4
        }
        
        // Configurar labels
        luzLabel.text = "Luz: --"
        deteccionLabel.text = "Detección: --"
        humedadLabel.text = "Humedad: --%"
        temperaturaLabel.text = "Temperatura: --°C"
        ultimaActualizacionLabel.text = "Última actualización: --"
    }
    
    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshSensorData), for: .valueChanged)
        scrollView.refreshControl = refreshControl
    }
    
    // MARK: - Data Loading
    @objc private func refreshSensorData() {
        loadSensors()
    }
    
    private func loadSensors() {
        SensorManager.shared.fetchSensors { [weak self] result in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                
                switch result {
                case .success(let sensors):
                    self?.sensors = sensors
                    self?.updateUI(with: sensors)
                    
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - UI Update
    private func updateUI(with sensors: [Sensor]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        // Obtener la fecha más reciente para la última actualización
        if let latestDate = sensors.map({ $0.eventDate }).max() {
            ultimaActualizacionLabel.text = "Última actualización: \(dateFormatter.string(from: latestDate))"
        }
        
        for sensor in sensors {
            switch sensor.type {
            case .light:
                luzLabel.text = "Luz: \(sensor.status?.localizedCapitalized ?? "--")"
                LuzImg.image = UIImage(systemName: sensor.status == "on" ? "lightbulb.fill" : "lightbulb")
                LuzImg.tintColor = sensor.status == "on" ? .systemYellow : .systemGray
                LuzIndicadorView.backgroundColor = sensor.status == "on" ? .systemGreen : .systemRed
                
            case .pir:
                deteccionLabel.text = "Detección: \(sensor.alertTriggered ? "Activa" : "Inactiva")"
                pirImage.image = UIImage(systemName: sensor.alertTriggered ? "person.fill" : "person")
                pirImage.tintColor = sensor.alertTriggered ? .systemRed : .systemGreen
                PIRindicadorView.backgroundColor = sensor.alertTriggered ? .systemRed : .systemGreen
                
            case .temperatureHumidity:
                if let temp = sensor.temperatureC {
                    temperaturaLabel.text = String(format: "Temperatura: %.1f°C", temp)
                    
                    // Cambiar color según temperatura
                    if temp > 30 {
                        temperaturaLabel.textColor = .systemRed
                        HTIndicadorView.backgroundColor = .systemRed
                    } else if temp < 15 {
                        temperaturaLabel.textColor = .systemBlue
                        HTIndicadorView.backgroundColor = .systemBlue
                    } else {
                        temperaturaLabel.textColor = .systemGreen
                        HTIndicadorView.backgroundColor = .systemGreen
                    }
                }
                
                if let humidity = sensor.humidityPercent {
                    humedadLabel.text = String(format: "Humedad: %.0f%%", humidity)
                }
            }
        }
    }
    
    // MARK: - Alert
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
