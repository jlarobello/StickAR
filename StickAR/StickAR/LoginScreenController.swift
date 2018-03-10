//
//  LoginScreenController.swift
//  StickAR
//
//  Created by Christopher Kim on 3/9/18.
//  Copyright © 2018 Christopher Kim. All rights reserved.
//

import UIKit

class LoginScreenController: UIViewController {

    @IBOutlet weak var txtUsername: UITextField!
    
    @IBOutlet weak var txtPassword: UITextField!
    
    @IBOutlet weak var btnLogin: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtUsername.layer.borderWidth = 1
        txtUsername.layer.borderColor = UIColor.white.cgColor
        txtUsername.layer.cornerRadius = 20
        txtUsername.clipsToBounds = true
        
        txtPassword.layer.borderWidth = 1
        txtPassword.layer.borderColor = UIColor.white.cgColor
        txtPassword.layer.cornerRadius = 20
        txtPassword.clipsToBounds = true

        btnLogin.layer.cornerRadius = 20
        btnLogin.clipsToBounds = true
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
