//
//  FeedTableViewController.swift
//  PicShare
//
//  Created by Abid Amirali on 6/21/16.
//  Copyright © 2016 Abid Amirali. All rights reserved.
//

import UIKit
import Firebase

class FeedTableViewController: UITableViewController {

    let databaseRef = FIRDatabase.database().reference().child("users")
    let storageRef = FIRStorage.storage().referenceForURL("gs://instagram-3faf9.appspot.com").child("userImages")
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    var images = [FIRStorageReference]()
    var users = [String]()
    var captions = [String]()
    var refresher: UIRefreshControl!
    var isSpinning = false
    var addCount = 0
    var dirCount = 0
    var URLS = [NSURL]()
    var following = [String]()
    var didFindFollowing = false

    var imageFiles = [imageFile]()
    @IBOutlet var taskTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        refresher = UIRefreshControl()
        refresher.attributedTitle = NSAttributedString(string: "Pull To Refresh Feed")
        refresher.addTarget(self, action: "getDataFromFirebase", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refresher)
    }

    func getfollowing() {
        didFindFollowing = false
        databaseRef.observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) in
            print(snapshot)
            for user in snapshot.children {
                if (user.key! == (FIRAuth.auth()?.currentUser?.uid)!) {
                    if let followingDatabaseStore = user.value.objectForKey("following") as? String {
                        let tempStoreArray = followingDatabaseStore.componentsSeparatedByString(",")
                        for user in tempStoreArray {
                            if (user.characters.count > 0) {
                                if (!self.didFindFollowing) {
                                    self.didFindFollowing = true
                                }
                                self.following.append(user)
                            }
                        }
                    }
                }

            }
            self.getDataFromFirebase()
        })
    }

    override func viewDidAppear(animated: Bool) {
        startSpinner()
        getfollowing()
    }

    func startSpinner() {
        isSpinning = true
        activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 80, 80))
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        activityIndicator.transform = CGAffineTransformMakeScale(1.5, 1.5)
        activityIndicator.hidesWhenStopped = true
        self.view.addSubview(activityIndicator)
        activityIndicator.center = self.view.center
        activityIndicator.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    }

    func stopSpinner() {
        self.isSpinning = false
        activityIndicator.stopAnimating()
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
    }

    func getDataFromFirebase() {
        users = []
        captions = []
        images = []
        addCount = 0
        dirCount = 0
        imageFiles = []
        databaseRef.observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) in
            print(snapshot)
            for user in snapshot.children {

                if (user.key! != (FIRAuth.auth()?.currentUser?.uid)!) {
                    if (self.following.contains(user.key!)) {
                        if let imagesList = user.value.objectForKey("images") as? String {
                            let tempStore = imagesList.componentsSeparatedByString(",")
                            for value in tempStore {
                                if (value.characters.count > 0) {
                                    let imageUploader = user.key!
                                    let inputURL = self.storageRef.child("\(imageUploader)/\(value)")
                                    print("PRINTING IMAGE URL!!!\n\(inputURL)")
                                    self.images.append(inputURL)
                                    let newDir = NSURL(fileURLWithPath: NSTemporaryDirectory())
                                    let fileDir = newDir.URLByAppendingPathComponent("image\(self.dirCount)").URLByAppendingPathExtension("png")
                                    self.dirCount += 1
                                    print(fileDir)
                                    print(self.addCount)
                                    // Download to the local filesystem
                                    self.images[self.dirCount - 1].writeToFile(fileDir) { (URL, error) -> Void in
                                        if (error != nil) {
                                            print(error?.localizedDescription)
                                            print(error)

                                        } else {
                                            // Local file URL for "images/island.jpg" is returned
                                            print(URL)
                                            var newImage = imageFile()
                                            newImage.fileName = "image\(self.getImageIndexFromURL(URL!))"
                                            print(newImage.fileName)
                                            newImage.fileURL = URL!
                                            self.imageFiles.append(newImage)
                                            self.addCount += 1
                                            if (self.addCount == self.images.count) {
                                                self.imageFiles.sortInPlace({ $0.fileName < $1.fileName })
                                                for img in self.imageFiles {
                                                    print(img.fileName)
                                                }
                                                self.refresher.endRefreshing()
                                                self.taskTable.reloadData()
                                                if (self.isSpinning) {
                                                    self.stopSpinner()
                                                }
                                            }
                                        }

                                    }
                                }
                            }
                        }
                        if let captionList = user.value.objectForKey("imageCaptions") as? String {
                            let tempStore = captionList.componentsSeparatedByString(",")
                            for value in tempStore {
                                if (value.characters.count > 0) {
                                    self.captions.append(value)
                                    if let userName = user.value.objectForKey("email") {
                                        self.users.append(userName as! String)
                                    }
                                }
                            }
                        }

                    } else {
                        if (!self.didFindFollowing) {
                            if (self.isSpinning) {
                                self.stopSpinner()
                            }
                            self.refresher.endRefreshing()
                            self.taskTable.reloadData()
                        }
                    }
                }
            }
        })
    }

    func getImageIndexFromURL(urlString: NSURL) -> Character {
        let inputString = "\(urlString)"
        let index = inputString.rangeOfString("image")?.endIndex
        let numString = "\(index!)"
        let num = Int(numString)
        let retString = inputString[inputString.startIndex.advancedBy(num!)]
        print(retString)
        return retString
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if (imageFiles.count > 0) {
            return imageFiles.count
        } else {
            return 1
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Configure the cell...
        let myCell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! Cell

        if (imageFiles.count > 0) {
            dispatch_async(dispatch_get_main_queue()) {
                // getting uiImag from data
                let imageURL = self.imageFiles[indexPath.row].fileURL
                let imageData = NSData(contentsOfURL: imageURL)
                // adding data to cells
                myCell.postedImage.image = UIImage(data: imageData!)
                myCell.userName.text = self.users[indexPath.row]
                myCell.caption.text = self.captions[indexPath.row]

            }

        } else {
            myCell.userName.text = "\t\tPlease Follow Some Users\t\t"
            myCell.caption.text = ""
        }

        return myCell
    }

    /*
     // Override to support conditional editing of the table view.
     override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */

    /*
     // Override to support editing the table view.
     override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
     if editingStyle == .Delete {
     // Delete the row from the data source
     tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
     } else if editingStyle == .Insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */

    /*
     // Override to support rearranging the table view.
     override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

     }
     */

    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

}
