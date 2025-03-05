import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var BotonView: UIButton!
    @IBOutlet weak var LoginView: UIView!
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    var isPasswordHidden = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        redondearLoginView()
        setUpTextFieldStyles()
        addEyeIconToPasswordTextField()
        
        usernameTextField.addTarget(self, action: #selector(textFieldDidBeginEditing(_:)), for: .editingDidBegin)
        passwordTextField.addTarget(self, action: #selector(textFieldDidBeginEditing(_:)), for: .editingDidBegin)
        usernameTextField.addTarget(self, action: #selector(textFieldDidEndEditing(_:)), for: .editingDidEnd)
        passwordTextField.addTarget(self, action: #selector(textFieldDidEndEditing(_:)), for: .editingDidEnd)
        
        // Agregar eventos para el botón
        BotonView.addTarget(self, action: #selector(buttonPressed), for: .touchDown)
        BotonView.addTarget(self, action: #selector(buttonReleased), for: [.touchUpInside, .touchCancel, .touchDragExit])
        
        BotonView.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
    }


    func redondearLoginView(){
        // Redondear LoginView
        LoginView.layer.cornerRadius = 20
        LoginView.layer.masksToBounds = true
        
        // Sombra suave alrededor de LoginView
        LoginView.layer.shadowColor = UIColor.black.cgColor  // Color negro
        LoginView.layer.shadowOpacity = 0.2  // Opacidad suave
        LoginView.layer.shadowRadius = 10  // Radio de la sombra (que tan difusa es)
        LoginView.layer.shadowOffset = CGSize(width: 0, height: 2)  // Desplazamiento suave de la sombra
        
        // Redondear BotonView
        BotonView.layer.cornerRadius = 10
        BotonView.layer.masksToBounds = true
    }
        
    

    func setUpTextFieldStyles() {
       
        usernameTextField.layer.shadowColor = UIColor.black.cgColor
        usernameTextField.layer.shadowOffset = CGSize(width: 2, height: 5)
        usernameTextField.layer.shadowOpacity = 0.1
        usernameTextField.layer.shadowRadius = 5
        usernameTextField.layer.masksToBounds = false

        passwordTextField.layer.shadowColor = UIColor.black.cgColor
        passwordTextField.layer.shadowOffset = CGSize(width: 2, height: 5)
        passwordTextField.layer.shadowOpacity = 0.1
        passwordTextField.layer.shadowRadius = 5
        passwordTextField.layer.masksToBounds = false
        
        // Eliminar el borde negro
        usernameTextField.layer.borderWidth = 0  // Eliminar el borde
        passwordTextField.layer.borderWidth = 0  // Eliminar el borde
        
        // Establecer el fondo oscuro, similar al de tu CSS
        usernameTextField.backgroundColor = UIColor(named: "BackgroundColor") ?? UIColor(white: 0.08, alpha: 1)
        passwordTextField.backgroundColor = UIColor(named: "BackgroundColor") ?? UIColor(white: 0.08, alpha: 1)

        // Configurar el color de texto blanco y fuente ajustada
        usernameTextField.textColor = .white
        passwordTextField.textColor = .white
        usernameTextField.font = UIFont.systemFont(ofSize: 14.5)
        passwordTextField.font = UIFont.systemFont(ofSize: 14.5)
    }



    func addEyeIconToPasswordTextField() {
        let eyeButton = UIButton(type: .custom)
        let eyeImage = UIImage(systemName: "eye")
        eyeButton.setImage(eyeImage, for: .normal)
        eyeButton.tintColor = .white // Color del ojo en blanco
        eyeButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        eyeButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        
        // Asignamos el ícono solo al campo de la contraseña
        passwordTextField.rightView = eyeButton
        passwordTextField.rightViewMode = .always
    }

    @objc func togglePasswordVisibility() {
        isPasswordHidden.toggle()
        
        // Alternamos la visibilidad de la contraseña
        passwordTextField.isSecureTextEntry = isPasswordHidden
        
        // Cambiamos el ícono según la visibilidad de la contraseña
        let eyeImage = isPasswordHidden ? UIImage(systemName: "eye") : UIImage(systemName: "eye.slash")
        if let eyeButton = passwordTextField.rightView as? UIButton {
            eyeButton.setImage(eyeImage, for: .normal)
        }
    }

    @objc func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.layer.shadowColor = UIColor.green.cgColor
        textField.layer.shadowOffset = CGSize(width: 0, height: 0)
        textField.layer.shadowOpacity = 0.3
        textField.layer.shadowRadius = 5
    }

    @objc func textFieldDidEndEditing(_ textField: UITextField) {
        textField.layer.shadowColor = UIColor.clear.cgColor // Eliminar la sombra cuando el campo pierde el foco
    }

    @objc func buttonPressed() {
        UIView.animate(withDuration: 0.2, animations: {
            self.BotonView.backgroundColor = .blue
            self.BotonView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        })
    }

    @objc func buttonReleased() {
        UIView.animate(withDuration: 0.2, animations: {
            self.BotonView.backgroundColor = .lightGray
            self.BotonView.transform = CGAffineTransform.identity
        })
    }
    
    @objc func loginButtonTapped() {
        guard let email = usernameTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            print("Por favor, ingresa email y contraseña")
            return
        }
        
        AuthService.shared.login(email: email, password: password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let token):
                    print("Login exitoso. Token: \(token)")
                    self.navigateToHome()
                case .failure(let error):
                    print("Error en el login: \(error.localizedDescription)")
                }
            }
        }
    }

    func navigateToHome() {
        let storyboard = UIStoryboard(name: "InicioStoryboard", bundle: nil)
        if let homeVC = storyboard.instantiateInitialViewController() {
            homeVC.modalPresentationStyle = .fullScreen
            self.present(homeVC, animated: true, completion: nil)
        }
    }
}
