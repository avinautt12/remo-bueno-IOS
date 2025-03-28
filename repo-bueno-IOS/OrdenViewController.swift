//
//  OrdenViewController.swift
//  repo-bueno-IOS
//
//  Created by mac on 20/03/25.
//

import UIKit

class OrdenViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
           collectionView.delegate = self
           
           if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
               layout.itemSize = CGSize(width: collectionView.frame.width * 0.9, height: 100) // Ajusta tamaño de celda
               layout.minimumLineSpacing = 10 // Espacio entre celdas
           }
        
        
        // Configura tu UITableView aquí
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10 // Número de órdenes, cámbialo según tu data
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OrderCell", for: indexPath)
        cell.layer.cornerRadius = 15 // Bordes redondeados
        return cell
    }
}
