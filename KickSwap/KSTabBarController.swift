//
//  KSTabBarController.swift
//  KickSwap
//
//  Created by Brandon Sanchez on 3/10/16.
//  Copyright © 2016 Hugh A. Miles II. All rights reserved.
//

import UIKit

class KSTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        Style.loadTheme()
        self.selectedIndex = 1
        
        //set current User
        let profile = self.viewControllers![2] as! KSProfileViewController
        profile.profileUser = User.currentUser
        
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        layoutTheme()
        self.selectedIndex = 1
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func layoutTheme() {
        self.tabBar.tintColor = tabBarTintColor
        self.tabBar.barTintColor = tabBarBarTintColor
    }
    
    @IBAction func customizeTapped(segue: UIStoryboardSegue, sender: UIStoryboardSegue) {
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
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
