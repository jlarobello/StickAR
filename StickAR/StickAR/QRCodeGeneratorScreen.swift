//
//  QRCodeGeneratorScreen.swift
//  StickAR
//
//  Created by Christopher Kim on 3/9/18.
//  Copyright © 2018 Christopher Kim. All rights reserved.
//

import UIKit

class QRCodeGeneratorScreen: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate  {
    
//    @IBOutlet weak var btnCard: UIButton!
    
//    var isOpen = false
//
//    @IBAction func btnFlip(_ sender: Any) {
//        if isOpen {
//            isOpen = false
//            let image = UIImage(named: "walle")
//            btnCard.setImage(image, for: .normal)
//            UIView.transition(with: btnCard, duration: 0.3, options: .transitionFlipFromLeft, animations: nil, completion: nil)
//        } else {
//            isOpen = true
//            let image = UIImage(named: "walle_qr_code")
//            btnCard.setImage(image, for: .normal)
//            UIView.transition(with: btnCard, duration: 0.3, options: .transitionFlipFromRight, animations: nil, completion: nil)
//        }
//    }
//    @IBAction func importImage(_ sender: Any) {
//
//        let image = UIImagePickerController()
//        image.delegate = self
//
//        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
//
//        image.allowsEditing = false
//
//        self.present(image, animated: true) {
//            // After it is complete
//        }
//    }
    
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
//        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
//            myImageView.image = image
//        } else {
//            // Error Message
//        }
//
//        self.dismiss(animated: true, completion: nil)
//    }
    
    @IBOutlet weak var txtLink: UITextField!
    @IBOutlet weak var generateBtn: UIButton!
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var galleryBtn: UIButton!

    
    @IBAction func generateQRCode(_ sender: Any) {
        func generateQRCode(from string: String) -> UIImage? {
            let data = string.data(using: String.Encoding.ascii)
            
            if let filter = CIFilter(name: "CIQRCodeGenerator") {
                filter.setValue(data, forKey: "inputMessage")
                let transform = CGAffineTransform(scaleX: 3, y: 3)
                
                if let output = filter.outputImage?.transformed(by: transform) {
                    return UIImage(ciImage: output)
                }
            }
            
            return nil
        }
        
        myImageView.image = generateQRCode(from: txtLink.text!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtLink.delegate = self
        
        txtLink.layer.borderWidth = 1
        txtLink.layer.borderColor = UIColor.white.cgColor
        txtLink.layer.cornerRadius = 20
        txtLink.clipsToBounds = true
        
        generateBtn.layer.cornerRadius = 20
        generateBtn.clipsToBounds = true
        
        galleryBtn.layer.cornerRadius = 20
        galleryBtn.clipsToBounds = true
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ scoreText: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
