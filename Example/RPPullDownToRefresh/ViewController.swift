//
//  ViewController.swift
//  RPPullDownToRefresh
//
//  Created by Francesco on 08/04/2015.
//  Copyright (c) 2015 Francesco. All rights reserved.
//

import UIKit
import RPPullDownToRefresh

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    var refreshControl : PullDownToRefresh?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.tableView.delegate = self
        let colors = [UIColor.yellowColor(), UIColor.purpleColor(), UIColor.cyanColor(), UIColor.brownColor()]
        
        self.refreshControl = PullDownToRefresh(scrollView: self.tableView, marginFromTop : 64, colors : colors)
        self.view.addSubview(self.refreshControl!)
        self.refreshControl?.addTarget(self, action: "refreshData:", forControlEvents: UIControlEvents.ValueChanged)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 30
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel?.text = "My Cell \(indexPath.row)"
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func refreshData(sender : AnyObject?){
        let delay = 5 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.refreshControl!.stopRefreshing()
        }
    }
}

