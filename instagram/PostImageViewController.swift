//
//  PostImageViewController.swift
//  PicShare
//
//  Created by Abid Amirali on 6/16/16.
//  Copyright © 2016 Abid Amirali. All rights reserved.
//

import UIKit
import Firebase

class PostImageViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var caption: UITextField!

    var actvitityIndicator = UIActivityIndicatorView()

    let currentUser: String = (FIRAuth.auth()?.currentUser?.uid)!

    var localImageStore = ""

    var captionTextLocal = ""

    var captions = [String]()

    var images = [String]()

    let storageReference = FIRStorage.storage().reference().child("userImages")

    func startSpinner() {
        actvitityIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 80, 80))
        actvitityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        actvitityIndicator.transform = CGAffineTransformMakeScale(1.5, 1.5)
        actvitityIndicator.hidesWhenStopped = true
        actvitityIndicator.center = self.view.center
        self.view.addSubview(actvitityIndicator)
        actvitityIndicator.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()

    }

    func stopSpinner() {
        actvitityIndicator.stopAnimating()
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }

    @IBAction func postImage(sender: AnyObject) {
        self.startSpinner()

        let userDir = storageReference.child("\(currentUser)")
        let currentDate = NSDate()
        let dateString = "\(currentDate)"
        let imageDir = userDir.child("\(currentDate).png")
        let postsImage = UIImagePNGRepresentation(imageView.image!)
        print(imageDir)
        let imageMetaData = FIRStorageMetadata()
        imageMetaData.contentType = "image/png"

        imageDir.putData(postsImage!, metadata: imageMetaData) { (metaData, error) in
            if (error != nil) {
                print(error?.localizedDescription)
                var alert = UIAlertController(title: "Operatoin Unsuccesfull", message: "\(error?.localizedDescription)", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: { (action) in
                    self.actvitityIndicator.stopAnimating()
                    }))
                self.stopSpinner()
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                // adding image name to image store
                let imageName = (metaData?.name)! as String
                let databaseDir = userPath.child("\(self.currentUser)/images")
                self.localImageStore += "\(imageName),"
                self.images.append(imageName)
                databaseDir.setValue(self.localImageStore)
                print(self.images)
                print(self.localImageStore)

                // adding image text to the database

                var imageText = self.caption.text!;
                if (imageText.characters.count == 0) {
                    imageText = " "
                }
                let textDir = userPath.child("\(self.currentUser)/imageCaptions")
                self.captionTextLocal += "\(imageText),"
                self.captions.append(imageText)
                textDir.setValue(self.captionTextLocal)

                // showing success alert ot user
                var alert = UIAlertController(title: "Operation Succesfull", message: "Your image was uploaded succesfully", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: { (action) in
//                    self.dismissViewControllerAnimated(true, completion: nil)
                    self.performSegueWithIdentifier("imagePosted", sender: self)
                    }))
                self.stopSpinner()
                self.presentViewController(alert, animated: true, completion: nil)
            }

        }
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String: AnyObject]?) {
        self.dismissViewControllerAnimated(true, completion: nil)
        imageView.image = image
    }

    @IBAction func loadImageFromCamera(sender: AnyObject) {
        var image = UIImagePickerController()
        image.delegate = self
        image.allowsEditing = true
        image.sourceType = UIImagePickerControllerSourceType.Camera
        self.presentViewController(image, animated: true, completion: nil)
    }

    @IBAction func loadImageFromLibrary(sender: AnyObject) {
        var image = UIImagePickerController()
        image.delegate = self
        image.allowsEditing = true
        image.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        self.presentViewController(image, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.caption.delegate = self
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(animated: Bool) {
        updateData()

    }
    
    
    func textFieldDidBeginEditing(textField: UITextField) {
        var captionInput = UIAlertController(title: "Captoin", message: "Please enter your desired caption below",preferredStyle: .Alert)
        captionInput.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: {
            (action) in
            self.navigationController?.popViewControllerAnimated(true)
        }))
        captionInput.addAction(UIAlertAction(title: "Add", style: .Default, handler: {
            (action) in
           let text = captionInput.textFields?[0].text
            textField.text = text!
            
        }))
        captionInput.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Caption. eg:Hey World!"
        }
        captionInput.view.setNeedsLayout()
        self.presentViewController(captionInput, animated: true, completion: nil)
    }

    func updateData() {
        let databaseDir = userPath.child("\(self.currentUser)")
        databaseDir.observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) in

            if let dataBaseImageStore = snapshot.value?.objectForKey("images") {
                let tempImages = dataBaseImageStore.componentsSeparatedByString(",")
                self.images = []
                self.localImageStore = ""
                for image in tempImages {
                    if (image.characters.count > 0) {
                        self.images.append(image)
                        self.localImageStore += "\(image),"
                    }
                }

            }

            if let dataBaseCaptionStore = snapshot.value?.objectForKey("imageCaptions") {
                let tempCaptions = dataBaseCaptionStore.componentsSeparatedByString(",")
                self.captions = []
                self.captionTextLocal = ""
                for caption in tempCaptions {
                    if (caption.characters.count > 0) {
                        self.captions.append(caption)
                        self.captionTextLocal += "\(caption),"
                    }
                }

            }

        })

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
