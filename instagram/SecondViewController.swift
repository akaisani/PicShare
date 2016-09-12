//
//  SecondViewController.swift
//  PicShare
//
//  Created by Abid Amirali on 6/14/16.
//  Copyright © 2016 Abid Amirali. All rights reserved.
//

import UIKit
import Firebase

class SecondViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var UnameField: UITextField!

    @IBOutlet weak var passwordField: UITextField!

    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        self.loginButtonPressed(1)
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.UnameField.delegate = self
        self.passwordField.delegate = self
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
                self.performSegueWithIdentifier("userLoggedIn", sender: self)
            }

        })
    }

    @IBAction func loginButtonPressed(sender: AnyObject) {
        self.view.endEditing(true)
        if UnameField.text == "" && passwordField.text == "" {
            var alert = UIAlertController(title: "Error", message: "Please enter a valid email address and password", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: { (action) -> Void in
                self.dismissViewControllerAnimated(true, completion: nil)
                }))
            presentViewController(alert, animated: true, completion: nil)
        } else if UnameField.text == "" {
            var alert = UIAlertController(title: "Error", message: "Please enter a valid email address", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: { (action) -> Void in
                self.dismissViewControllerAnimated(true, completion: nil) }))
            presentViewController(alert, animated: true, completion: nil)
        } else if passwordField.text == "" {
            var alert = UIAlertController(title: "Error", message: "Please enter a valid password", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: { (action) -> Void in
                self.dismissViewControllerAnimated(true, completion: nil) }))
            presentViewController(alert, animated: true, completion: nil)

        } else {
            startSpinner()
            login(UnameField.text! as String, password: passwordField.text! as String)
        }

    }

    override func viewDidAppear(animated: Bool) {
        if FIRAuth.auth()?.currentUser != nil {
            print(FIRAuth.auth()?.currentUser?.uid)
            performSegueWithIdentifier("userLoggedIn", sender: self)
        }
    }

}

