//
//  PerfilViewController.swift
//  repo-bueno-IOS
//
//  Created by mac on 03/03/25.
//

import UIKit

class PerfilViewController: UIViewController {

    @IBOutlet weak var imgPerfil: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imgPerfil.layer.cornerRadius = imgPerfil.frame.size.width / 2
        imgPerfil.clipsToBounds = true
        
        imgPerfil.layer.borderWidth = 2
        imgPerfil.layer.borderColor = UIColor.white.cgColor
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
