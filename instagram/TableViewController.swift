//
//  TableViewController.swift
//  PicShare
//
//  Created by Abid Amirali on 6/15/16.
//  Copyright © 2016 Abid Amirali. All rights reserved.
//

import UIKit
import Firebase

let ref: FIRDatabaseReference = FIRDatabase.database().reference()
let userPath = ref.child("users")

class TableViewController: UITableViewController {

    @IBOutlet var taskTable: UITableView!
    var followingStoreLocal = ""
    var following = [String]()
    var followersStoreLocal = ""
    var followers = [String]()
    var refresher: UIRefreshControl!
    var actvitityIndicator = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        refresher = UIRefreshControl()
        refresher.attributedTitle = NSAttributedString(string: "Pull To Refresh")
        refresher.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refresher)
    }

    func refresh() {
        // get data from firebase
        userPath.observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) in
            emails = []
            uids = []
            emails.append("")
            uids.append("")
            for child in snapshot.children {
                print(child.value.objectForKey("email"), "\n")
                if (child.key != FIRAuth.auth()?.currentUser?.uid) {
                    if let newEmail = child.value.objectForKey("email") as? String {
                        emails.append(newEmail)
                    }
                    if let newUid = child.value.objectForKey("uid") as? String {
                        uids.append(newUid)
                    }

                } else {
                    print("PRITING CHILD\n\(child)")
                    if let followingDatabaseStore = child.value.objectForKey("following") as? String {
                        self.followingStoreLocal = followingDatabaseStore
                        let followingRaw = self.followingStoreLocal.componentsSeparatedByString(",")
                        self.following = []
                        for user in followingRaw {
                            if (user.characters.count > 0) {
                                self.following.append(user)
                            }
                        }
//                        print(self.following.removeLast())
                        print("PRITING FOLLOWING\n\(self.following)")

                    }

                }

            }

            print(emails)
            print(uids)
            print(self.following)
            self.taskTable.reloadData()
            self.stopSpinner()
            self.refresher.endRefreshing()
        })

        // done with data

    }

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

    override func viewDidAppear(animated: Bool) {

        // self.userPath.removeAllObservers()
        startSpinner()
        refresh()

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
        return emails.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        // Configure the cell...
        if (indexPath.row == 0) {
            cell.textLabel?.text = "Select Users To Follow"
        } else {
            cell.textLabel?.text = emails[indexPath.row]
            if following.contains(uids[indexPath.row]) {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark

            } else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
        }
        return cell
    }

    func updateFollowing(index: Int, add: Bool) {
        if (index != 0) {
            if add {
                followingStoreLocal += "\(uids[index]),"
                let currentUId = FIRAuth.auth()?.currentUser?.uid
                following.append("\(uids[index])")
                userPath.child("/\(currentUId!)/following/").setValue(followingStoreLocal)
                print("followers updated")
            } else {
                followingStoreLocal = ""
                following.removeAtIndex(following.indexOf(uids[index])!)
                for user in following {
                    if (user.characters.count > 0) {
                        followingStoreLocal += "\(user),"
                    }
                }
                let currentUId = FIRAuth.auth()?.currentUser?.uid
                userPath.child("/\(currentUId!)/following/").setValue(followingStoreLocal)
                print("followers updated2")
            }
        }
    }

    func addFollower(index: Int, add: Bool) {
        if (index != 0) {
            if add {
                let followedUID = uids[index]
                let currentUId = FIRAuth.auth()?.currentUser?.uid
                let followedPath = userPath.child(("/\(followedUID)"))
                followedPath.observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) in
                    print(snapshot)
                    print(self.followers)
                    if let followersDatabaseStore = snapshot.value!.objectForKey("followers") as? String {
                        self.followersStoreLocal = followersDatabaseStore
                        self.followers = followersDatabaseStore.componentsSeparatedByString(",")
                        print(self.followers)
                        self.followers.append("\(currentUId!)")
                        self.followersStoreLocal = ""
                        for user in self.followers {
                            print(user)
                            if (user.characters.count > 0) {
                                self.followersStoreLocal += "\(user),"
                            }
                        }
                        print(self.followersStoreLocal)
                        print(self.followers)
                        userPath.child("/\(followedUID)/followers/").setValue(self.followersStoreLocal)
                        print("done updating followers add")
                        
                    } else {
                        self.followersStoreLocal = ""
                        self.followers = []
                        self.followersStoreLocal += "\(currentUId!),"
                        userPath.child("/\(followedUID)/followers/").setValue(self.followersStoreLocal)
                        print("done updating followers add")
                    }
                    self.stopSpinner()
                })
            } else {
                let followedUID = uids[index]
                followersStoreLocal = ""
                followers = []
                let followedPath = userPath.child(("/\(followedUID)"))
                print(followedPath)
//            followedPath.child("/followers/").removeValue()
                followedPath.observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) in
                    print(snapshot)
                    print(self.followers)
                    if let followersDatabaseStore = snapshot.value!.objectForKey("followers") as? String {
                        self.followersStoreLocal = followersDatabaseStore
                        self.followers = followersDatabaseStore.componentsSeparatedByString(",")
                        print(self.followers)
//                    self.followers.removeLast()
                        print(self.followers)
                        let removeIndex = self.followers.indexOf((FIRAuth.auth()?.currentUser?.uid)!)
                        self.followers.removeAtIndex(removeIndex!)
                        print(self.followers.count)
                        self.followersStoreLocal = ""
                        for user in self.followers {
                            print(user)
                            if (user.characters.count > 0) {
                                self.followersStoreLocal += "\(user),"
                            }
                        }
                        print(self.followersStoreLocal)
                        print(self.followers)
                        userPath.child("/\(followedUID)/followers/").setValue(self.followersStoreLocal)
                        print("done updating followers del")
                    }
                    self.stopSpinner()
                }) { (error) in
                    print(error.localizedDescription)
                }

            }
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var cell = tableView.cellForRowAtIndexPath(indexPath)
        startSpinner()
        if (!following.contains(uids[indexPath.row])) {
            // Updating following of current user
            updateFollowing(indexPath.row, add: true)

            // Updating followers of followed user by current user
            addFollower(indexPath.row, add: true)

            cell?.accessoryType = UITableViewCellAccessoryType.Checkmark

        } else {
            // update follwing fo current user
            updateFollowing(indexPath.row, add: false)

            // Updating followers of followed user by current user
            addFollower(indexPath.row, add: false)

            cell?.accessoryType = UITableViewCellAccessoryType.None

        }
    }
    @IBAction func signOut(sender: AnyObject) {
        if FIRAuth.auth()?.currentUser != nil {
            do {
                try FIRAuth.auth()?.signOut()
            } catch {
                print("not signed out")
            }
//            print(FIRAuth.auth()?.currentUser?.uid)
            performSegueWithIdentifier("signOut", sender: self)
        }
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
