//
//  loginViewController.swift
//  Crowdseye Filmer
//
//  Created by Patrick O'Grady on 11/1/15.
//  Copyright © 2015 crowdseye. All rights reserved.
//

import UIKit

class loginViewController: UIViewController {

    @IBOutlet weak var actionPicker: UISegmentedControl!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.firstName.hidden = true
        self.lastName.hidden = true
        self.actionPicker.selectedSegmentIndex = 0

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismiss(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func selectDifferentAction(sender: UISegmentedControl) {
        if(sender.selectedSegmentIndex == 0) {
            self.firstName.hidden = true
            self.lastName.hidden = true
        } else {
            self.firstName.hidden = false
            self.lastName.hidden = false
        }
    }
    @IBAction func goButton(sender: UIButton) {
        if(self.actionPicker.selectedSegmentIndex == 0) {
            //login
            if(username.text != "" && password.text != "") {
                PFUser.logInWithUsernameInBackground(username.text!, password: password.text!, block: { (user:PFUser?, error:NSError?) -> Void in
                    if user != nil {
                        self.dismissViewControllerAnimated(true, completion: nil)
                    } else {
                        UIAlertView(title: "Error", message: error!.description, delegate: nil, cancelButtonTitle: "Ok").show()
                    }
                })
                
            } else {
                UIAlertView(title: "Error", message: "Please type a username and password.", delegate: nil, cancelButtonTitle: "Ok").show()
            }
            
        } else {
            //sign up
            if(username.text != "" && password.text != "" && firstName.text != "" && lastName.text != "") {
                
                var currentUser = PFUser.currentUser()!
                currentUser.username = username.text
                currentUser.password = password.text!
                currentUser["name"] = self.firstName.text! + " " + self.lastName.text!
                
                currentUser.signUpInBackgroundWithBlock({ (succeeded: Bool, error:NSError?) -> Void in
                    if succeeded == true {
                        do {
                           try PFUser.logInWithUsername(self.username.text!, password: self.password.text!)
                        } catch {
                            print("Could not sign in.")
                        }
                        self.dismissViewControllerAnimated(true, completion: nil)
                    } else {
                        UIAlertView(title: "Error", message: error!.description, delegate: nil, cancelButtonTitle: "Ok").show()
                    }
                })
                

                
            } else {
                UIAlertView(title: "Error", message: "Please ensure you have typed a username, password, and name.", delegate: nil, cancelButtonTitle: "Ok").show()
            }
            
        }
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
