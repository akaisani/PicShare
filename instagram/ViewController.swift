//
//  ViewController.swift
//  PicShare
//
//  Created by Abid Amirali on 6/14/16.
//  Copyright © 2016 Abid Amirali. All rights reserved.
//

import UIKit
import Firebase

var emails: [String] = [String]()
var uids: [String] = [String]()

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var Uname: UITextField!

    @IBOutlet weak var passwordField: UITextField!

    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()

    internal func login(email: String, password: String) {
        FIRAuth.auth()?.signInWithEmail(email, password: password, completion: { (user, error) in
            if error != nil {
                let messageText = error?.localizedDescription
                var alert = UIAlertController(title: "Error", message: messageText!, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: { (action) -> Void in
                    self.navigationController?.popViewControllerAnimated(true)
                    }))
                self.activityIndicator.stopAnimating()
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                self.stopSpinner()
                print("user logged in")
                self.performSegueWithIdentifier("userLoggedIn2", sender: self)
            }

        })
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        self.SignUp(1)
        return true
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }

    func startSpinner() {
        activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 80, 80))
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        activityIndicator.transform = CGAffineTransformMakeScale(1.5, 1.5)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = self.view.center
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()

    }

    func stopSpinner() {
        activityIndicator.stopAnimating()
        UIApplication.sharedApplication().endIgnoringInteractionEvents()

    }

    @IBAction func SignUp(sender: AnyObject) {
        self.view.endEditing(true)
//        startSpinner()
        if Uname.text == "" && passwordField.text == "" {

            var alert = UIAlertController(title: "Error", message: "Please enter a valid email address and password.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: { (action) -> Void in
                self.navigationController?.popViewControllerAnimated(true)
                }))
//            stopSpinner()
            self.presentViewController(alert, animated: true, completion: nil)
        } else if Uname.text == "" {
            var alert = UIAlertController(title: "Error", message: "Please enter a valid email address", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: { (action) -> Void in
                self.navigationController?.popViewControllerAnimated(true)

                }))
//            stopSpinner()
            self.presentViewController(alert, animated: true, completion: nil)
        } else if passwordField.text == "" {
            var alert = UIAlertController(title: "Error", message: "Please enter a valid password", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: { (action) -> Void in
                self.navigationController?.popViewControllerAnimated(true)

                }))
//            stopSpinner()
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            startSpinner()
            FIRAuth.auth()?.createUserWithEmail(Uname.text!, password: passwordField.text!, completion: { (user, error) in
                if (error != nil) {
                    let messageText = error?.localizedDescription
                    var alert = UIAlertController(title: "Error", message: messageText!, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: { (action) -> Void in
                        self.navigationController?.popViewControllerAnimated(true)

                        }))
                    self.activityIndicator.stopAnimating()
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    self.presentViewController(alert, animated: true, completion: nil)
                } else {
                    print("user created\nuser logging in now")
                    self.activityIndicator.stopAnimating()
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    // adding user to database

                    // loggin user in
                    self.login(self.Uname.text!, password: self.passwordField.text!)

                    let userID = (user?.uid)!
                    let userData = [
                        "email": self.Uname.text! as String,
                        "uid": userID as String
                    ]
                    let userPath = ref.child("users")
                    userPath.child("/\(userID)").setValue(userData)
                }
            })
        }

    }

    override func viewDidAppear(animated: Bool) {
        if let user = FIRAuth.auth()?.currentUser {
            performSegueWithIdentifier("userLoggedIn2", sender: self)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.Uname.delegate = self
        self.passwordField.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

