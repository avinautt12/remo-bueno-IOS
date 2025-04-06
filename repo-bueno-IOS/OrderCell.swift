import UIKit

class OrderCell: UITableViewCell {
    static let identifier = "OrderCell"
    
    @IBOutlet weak var orderIdLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var detailImageView: UIImageView!
    @IBOutlet weak var ZonaEntregaLabel: UILabel!
    var onDetailTapped: (() -> Void)?

      override func awakeFromNib() {
          super.awakeFromNib()
          statusView.layer.cornerRadius = 8
          statusView.backgroundColor = .systemGray

          let tapGesture = UITapGestureRecognizer(target: self, action: #selector(detailImageTapped))
          detailImageView.isUserInteractionEnabled = true
          detailImageView.addGestureRecognizer(tapGesture)
      }

      @objc private func detailImageTapped() {
          onDetailTapped?()
      }

      func configure(with order: Orden, onDetailTapped: @escaping () -> Void) {
          orderIdLabel.text = "Orden #\(order.id)"
          dateLabel.text = order.formattedDate
          weightLabel.text = "\(order.totalWeight) g"
          ZonaEntregaLabel.text = "Entrega: \(order.carrier)"
          statusLabel.text = order.status
          switch order.status.lowercased() {
          case "pending":
              statusLabel.text = "Pendiente"
              statusView.backgroundColor = .systemOrange
          case "completed":
              statusLabel.text = "Completado"
              statusView.backgroundColor = .systemGreen
          default:
              statusView.backgroundColor = .systemGray
          }

          detailImageView.image = UIImage(systemName: "chevron.right")?
              .withTintColor(.systemBlue, renderingMode: .alwaysOriginal)

          self.onDetailTapped = onDetailTapped
      }
}
