import UIKit

class LoginViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet private weak var loginButton: UIButton!
    @IBOutlet private weak var loginContainerView: UIView!
    @IBOutlet private weak var usernameTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    
    // MARK: - Properties
    private var isPasswordHidden = true
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let errorLabel = UILabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        checkExistingSession()
        setupUI()
        setupTextFields()
        setupErrorLabel()
        setupButtonActions()
    }
    
    // MARK: - Setup Methods
    private func checkExistingSession() {
        if AuthService.shared.isAuthenticated() {
            navigateToHome()
        }
    }
    
    private func setupUI() {
        configureLoginContainer()
        configureLoginButton()
        activityIndicator.color = .white
    }
    
    private func configureLoginContainer() {
        loginContainerView.layer.cornerRadius = 20
        loginContainerView.layer.masksToBounds = true
        
        loginContainerView.layer.shadowColor = UIColor.black.cgColor
        loginContainerView.layer.shadowOpacity = 0.2
        loginContainerView.layer.shadowRadius = 10
        loginContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
    }
    
    private func configureLoginButton() {
        loginButton.layer.cornerRadius = 10
        loginButton.layer.masksToBounds = true
        loginButton.backgroundColor = .systemBlue
    }
    
    private func setupTextFields() {
        [usernameTextField, passwordTextField].forEach {
            $0?.layer.shadowColor = UIColor.black.cgColor
            $0?.layer.shadowOffset = CGSize(width: 2, height: 5)
            $0?.layer.shadowOpacity = 0.1
            $0?.layer.shadowRadius = 5
            $0?.layer.masksToBounds = false
            $0?.layer.borderWidth = 0
            $0?.backgroundColor = UIColor(named: "BackgroundColor") ?? UIColor(white: 0.08, alpha: 1)
            $0?.textColor = .white
            $0?.font = UIFont.systemFont(ofSize: 14.5)
        }
        
        addEyeButtonToPasswordField()
    }
    
    private func addEyeButtonToPasswordField() {
        let eyeButton = UIButton(type: .custom)
        eyeButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        eyeButton.tintColor = .white
        eyeButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        eyeButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        
        passwordTextField.rightView = eyeButton
        passwordTextField.rightViewMode = .always
        passwordTextField.isSecureTextEntry = true
    }
    
    private func setupErrorLabel() {
        errorLabel.textColor = .red
        errorLabel.font = UIFont.systemFont(ofSize: 14)
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(errorLabel)
        
        NSLayoutConstraint.activate([
            errorLabel.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 8),
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupButtonActions() {
        loginButton.addTarget(self, action: #selector(buttonPressed), for: .touchDown)
        loginButton.addTarget(self, action: #selector(buttonReleased), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        [usernameTextField, passwordTextField].forEach {
            $0?.addTarget(self, action: #selector(textFieldDidBeginEditing(_:)), for: .editingDidBegin)
            $0?.addTarget(self, action: #selector(textFieldDidEndEditing(_:)), for: .editingDidEnd)
        }
    }
    
    // MARK: - Actions
    @objc private func togglePasswordVisibility() {
        isPasswordHidden.toggle()
        passwordTextField.isSecureTextEntry = isPasswordHidden
        
        let imageName = isPasswordHidden ? "eye.slash" : "eye"
        if let eyeButton = passwordTextField.rightView as? UIButton {
            eyeButton.setImage(UIImage(systemName: imageName), for: .normal)
        }
    }
    
    @objc private func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.layer.shadowColor = UIColor.systemBlue.cgColor
        textField.layer.shadowOffset = CGSize(width: 0, height: 0)
        textField.layer.shadowOpacity = 0.3
        textField.layer.shadowRadius = 5
    }
    
    @objc private func textFieldDidEndEditing(_ textField: UITextField) {
        textField.layer.shadowColor = UIColor.clear.cgColor
    }
    
    @objc private func buttonPressed() {
        UIView.animate(withDuration: 0.2) {
            self.loginButton.backgroundColor = .cyan
            self.loginButton.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }
    }
    
    @objc private func buttonReleased() {
        UIView.animate(withDuration: 0.2) {
            self.loginButton.backgroundColor = .systemBlue
            self.loginButton.transform = .identity
        }
    }
    
    @objc private func loginButtonTapped() {
        guard validateInputs() else { return }
        
        startLoginProcess()
        
        AuthService.shared.login(
            email: usernameTextField.text!,
            password: passwordTextField.text!
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleLoginResult(result)
            }
        }
    }
    
    // MARK: - Login Helpers
    private func validateInputs() -> Bool {
        guard let email = usernameTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showError("Por favor, ingresa tu correo y contraseña.")
            return false
        }
        
        errorLabel.isHidden = true
        return true
    }
    
    private func startLoginProcess() {
        loginButton.isEnabled = false
        loginButton.setTitle("", for: .normal)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        loginButton.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: loginButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor)
        ])
        
        activityIndicator.startAnimating()
    }
    
    private func handleLoginResult(_ result: Result<String, Error>) {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
        loginButton.isEnabled = true
        
        switch result {
        case .success:
            navigateToHome()
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }
    
    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        errorLabel.shake()
    }
    
    // MARK: - Navigation
    private func navigateToHome() {
        guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
              let tabBarVC = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "HomeVC") as? UITabBarController else {
            return
        }
        
        UIView.transition(with: sceneDelegate.window!, duration: 0.3, options: .transitionCrossDissolve, animations: {
            sceneDelegate.window?.rootViewController = tabBarVC
        }, completion: nil)
    }
}

// MARK: - Animation Extension
extension UIView {
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-10, 10, -10, 10, -5, 5, -2.5, 2.5, 0]
        layer.add(animation, forKey: "shake")
    }
}
