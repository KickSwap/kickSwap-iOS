//
//  KSTimelineViewController.swift
//  KickSwap
//
//  Created by Hugh A. Miles II on 2/18/16.
//  Copyright © 2016 Hugh A. Miles II. All rights reserved.
//

import UIKit
import Material
import ChameleonFramework
import IBAnimatable
import SnapKit
import PagingMenuController
import AFNetworking
import Firebase
import ASValueTrackingSlider

class KSTimelineViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, TextDelegate, TextViewDelegate, PagingMenuControllerDelegate {

   // @IBOutlet var timelineBackground: AnimatableImageView!
    @IBOutlet weak var timelineBackground: AnimatableImageView!

    @IBOutlet var timelineColorBackground: UIView!
   // @IBOutlet var timeline: UICollectionView!
    @IBOutlet weak var timeline: UICollectionView!

   // @IBOutlet var userProfileImage: UIImageView!
    @IBOutlet weak var userProfileImage: UIImageView!
    @IBOutlet var profileTrayView: CardView!
    @IBOutlet var trayViewButton: UIButton!
    @IBOutlet var profileName: UILabel!


    var mainCollectionViewCellIndexPath: NSIndexPath?

    var trayOriginalCenter: CGPoint!
    var tapCount = 0

    var shoeTimeline: [Shoe]?
    var allUsers: [User]?
    let backgroundImages = [UIImage(named:"blackBox"),UIImage(named:"boxStack"),UIImage(named:"greenBox")]
    var pictureIndex:Int?
    var visibleUser: User?
    var bidValue: Float?
    
    let cardView: CardView = CardView()


    /// A Text storage object that monitors the changes within the textView.
    lazy var text: Text = Text()

    /// A TextView UI Component.
    var textView: TextView!



    override func viewDidLoad() {
        super.viewDidLoad()
        getShoesFromFirebase()
        prefersStatusBarHidden()
        timeline.dataSource = self
        timeline.delegate = self
//        visibleUser = FirebaseClient.getUserById(shoeTimeline![0].ownerId!)
//        userProfileImage.setImageWithURL(NSURL(string: (visibleUser?.profilePicUrl)!)!)
//        userProfileImage.clipsToBounds = true
//        profileName.text = visibleUser?.displayName
        prepareView()
        prepareTextView()
        addToolBar(textView)

        //set image initially
        pictureIndex = 0
        timelineBackground.image = backgroundImages[pictureIndex!]

        //start timer
        var timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(KSTimelineViewController.loadImage), userInfo: nil, repeats: true)

    }

    func loadImage(){
        //setImage2
        var newIndex = pictureIndex! + 1
        if newIndex > 1 {
            pictureIndex = 0
            newIndex = pictureIndex!
        }

        UIView.transitionWithView(self.timelineBackground,
            duration:5,
            options: UIViewAnimationOptions.TransitionCrossDissolve,
            animations: { self.timelineBackground.image = self.backgroundImages[newIndex]},
            completion: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Style.loadTheme()
        layoutTheme()
        self.profileTrayView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo((profileTrayView.superview?.frame.height)! * 0.82).constraint
        }

        //Instantiate pages for container view
        let profileViewController = self.storyboard?.instantiateViewControllerWithIdentifier("KSProfileViewController") as! KSProfileViewController
        let detailViewController = self.storyboard?.instantiateViewControllerWithIdentifier("DetailViewController") as! DetailViewController
        profileViewController.title = "Profile"
        detailViewController.title = "Details"
        let viewControllers = [detailViewController, profileViewController]

        //instantiate PagingMenuController and customization
        let pagingMenuController = self.childViewControllers.first as! PagingMenuController

        let options = PagingMenuOptions()
        options.defaultPage = 0
        options.backgroundColor = pagingMenuBackgroundColor!
        options.selectedBackgroundColor = pagingMenuSelectedBackgroundColor!
        options.textColor = pagingMenuTextColor!
        options.selectedTextColor = pagingMenuSelectedTextColor!
        options.menuHeight = 25
        options.font = RobotoFont.regular
        options.selectedFont = RobotoFont.bold
        options.menuItemMode = .Underline(height: 3, color: pagingMenuUnderlineColor!, horizontalPadding: 0, verticalPadding: 0)
        //options.menuPosition = .Bottom
        pagingMenuController.delegate = self
        options.menuDisplayMode = .SegmentedControl
        //(widthMode: .Flexible, centerItem: true, scrollingMode: .PagingEnabled)
        pagingMenuController.setup(viewControllers: viewControllers, options: options)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // set initial tray view location
        self.profileTrayView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo((profileTrayView.superview?.frame.height)! * 0.82).constraint
        }

    }

    /// General preparation statements.
    private func prepareView() {
        view.backgroundColor = UIColor.clearColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?){
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }

    /// Prepares the textView.
    func prepareTextView() {
        let layoutManager: NSLayoutManager = NSLayoutManager()
        let textContainer: NSTextContainer = NSTextContainer(size: view.bounds.size)
        layoutManager.addTextContainer(textContainer)

        text.delegate = self
        text.textStorage.addLayoutManager(layoutManager)


        textView = TextView(textContainer: textContainer)
        textView.backgroundColor = UIColor.clearColor()
        textView.delegate = self
        textView.font = RobotoFont.regular
        textView.textColor = UIColor.whiteColor()
        textView.textContainer.maximumNumberOfLines = 1

        textView.placeholderLabel = UILabel()
        textView.placeholderLabel!.textColor = MaterialColor.white
        textView.placeholderLabel!.text = "Discover"

        // Discover label
        textView.titleLabel = UILabel()
        textView.titleLabel!.font = RobotoFont.mediumWithSize(12)
        textView.titleLabelColor = MaterialColor.white
        textView.titleLabelActiveColor = UIColor(hexString: "FA4A07")

        view.addSubview(textView)
        textView!.translatesAutoresizingMaskIntoConstraints = false
        MaterialLayout.alignToParent(view, child: textView!, top: 40, left: 24, bottom: 608, right: 100)
    }

    func addToolBar(textView: UITextView){
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.Default
        toolBar.translucent = true
        toolBar.tintColor = UIColor(hexString: "FA4A07")
        //toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: #selector(KSTimelineViewController.discoverPressed))
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(KSTimelineViewController.cancelPressed))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.userInteractionEnabled = true
        toolBar.sizeToFit()

        textView.delegate = self
        textView.inputAccessoryView = toolBar
    }
    func discoverPressed(){
        view.endEditing(true)
    }
    func cancelPressed(){
        view.endEditing(true) // or do something
    }

    /**
     When changes in the textView text are made, this delegation method
     is executed with the added text string and range.
     */
    func textWillProcessEdit(text: Text, textStorage: TextStorage, string: String, range: NSRange) {
        textStorage.removeAttribute(NSFontAttributeName, range: range)
        textStorage.addAttribute(NSFontAttributeName, value: RobotoFont.regular, range: range)
    }

    /**
     When a match is detected within the textView text, this delegation
     method is executed with the added text string and range.
     */
    func textDidProcessEdit(text: Text, textStorage: TextStorage, string: String, result: NSTextCheckingResult?, flags: NSMatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) {
        textStorage.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFontOfSize(16), range: result!.range)
    }



    @IBAction func onTrayPanGesture(sender: UIPanGestureRecognizer) {
        // Absolute (x,y) coordinates in parent view's coordinate system
        let point = sender.locationInView(view)

        // Total translation (x,y) over time in parent view's coordinate system
        let translation = sender.translationInView(view)

        if sender.state == UIGestureRecognizerState.Began {
            print("Gesture began at: \(point)")
            trayOriginalCenter = profileTrayView.center
        } else if sender.state == UIGestureRecognizerState.Changed {
            print("Gesture changed at: \(point)")
            profileTrayView.center = CGPoint(x: trayOriginalCenter.x, y: trayOriginalCenter.y + translation.y)
        } else if sender.state == UIGestureRecognizerState.Ended {
            print("Gesture ended at: \(point)")
            let velocity = sender.velocityInView(view)
            if velocity.y > 0 {
                self.profileTrayView.snp_remakeConstraints { (make) -> Void in
                    //make.top.equalTo(self.timeline.snp_bottom)
                    make.top.equalTo((profileTrayView.superview?.frame.height)! * 0.82)
                }
                //profileTrayView.superview?.userInteractionEnabled = true
                tapCount += 1
                profileTrayView.setNeedsLayout()
                UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options:[] , animations: { () -> Void in
                    //self.trayView.center = self.trayDown
                    self.profileTrayView.layoutIfNeeded()
                    }, completion: { (Bool) -> Void in
                })
            } else {
                self.profileTrayView.snp_remakeConstraints { (make) -> Void in
                    make.top.equalTo((profileTrayView.superview?.snp_top)!)
                }
                //trayView.superview?.userInteractionEnabled = false
                //ignoreView.hidden = false
                textView.userInteractionEnabled = false
                textView.hidden = true
                tapCount += 1
                profileTrayView.setNeedsLayout()
                UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options:[] , animations: { () -> Void in
                    //self.trayView.center = self.trayUp
                    self.profileTrayView.layoutIfNeeded()
                    }, completion: { (Bool) -> Void in
                })
            }
        }


    }

    @IBAction func onTapTrayViewButton(sender: AnyObject) {

        tapCount += 1
        //print(tapCount)
        if tapCount % 2 == 0 {
            self.profileTrayView.snp_remakeConstraints { (make) -> Void in
                make.top.equalTo((profileTrayView.superview?.frame.height)! * 0.82).constraint
            }
            //ignoreView.userInteractionEnabled = false
            //ignoreView.hidden = true
            profileTrayView.setNeedsLayout()
            UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options:[] , animations: { () -> Void in
                //self.trayView.center = self.trayUp
                self.profileTrayView.layoutIfNeeded()
                }, completion: { (Bool) -> Void in
            })

        } else {
            self.profileTrayView.snp_remakeConstraints { (make) -> Void in
                make.top.equalTo((profileTrayView.superview?.snp_top)!).offset(0).constraint
            }
            //trayView.superview?.userInteractionEnabled = false
            //ignoreView.hidden = false
            textView.userInteractionEnabled = false
            textView.hidden = true
            profileTrayView.setNeedsLayout()
            UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.2, options:[] , animations: { () -> Void in
                //self.trayView.center = self.trayDown
                self.profileTrayView.layoutIfNeeded()
                }, completion: { (Bool) -> Void in
            })
        }

    }
    
    func addBidView() {
        
        // Title label.
        let titleLabel: UILabel = UILabel()
        titleLabel.text = "How Much?"
        titleLabel.textColor = MaterialColor.blue.darken1
        titleLabel.font = RobotoFont.mediumWithSize(20)
        cardView.titleLabel = titleLabel
        
        // Detail label.
        let shoeValueSlider: ASValueTrackingSlider = ASValueTrackingSlider()
        var formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        shoeValueSlider.numberFormatter = formatter
        //print(self.shoeTimeline![mainCollectionViewCellIndexPath!.row].price)
        shoeValueSlider.minimumValue = Float(self.shoeTimeline![(mainCollectionViewCellIndexPath?.row)!].price!)! - 10
        shoeValueSlider.maximumValue = Float(self.shoeTimeline![(mainCollectionViewCellIndexPath?.row)!].price!)! + 100
        shoeValueSlider.addTarget(self, action: "bidSliderDidChange:", forControlEvents:UIControlEvents.ValueChanged)
        cardView.detailView = shoeValueSlider
        
        
        // Yes button.
        let btn1: FlatButton = FlatButton()
        btn1.pulseColor = MaterialColor.blue.lighten1
        btn1.pulseScale = false
        btn1.setTitle("Submit", forState: .Normal)
        btn1.setTitleColor(MaterialColor.blue.darken1, forState: .Normal)
        btn1.addTarget(self, action: "submitBid:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // No button.
        let btn2: FlatButton = FlatButton()
        btn2.pulseColor = MaterialColor.blue.lighten1
        btn2.pulseScale = false
        btn2.setTitle("Cancel", forState: .Normal)
        btn2.setTitleColor(MaterialColor.blue.darken1, forState: .Normal)
        btn2.addTarget(self, action: "cancelBid:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Add buttons to left side.
        cardView.rightButtons = [btn1, btn2]
        
        // To support orientation changes, use MaterialLayout.
        view.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        MaterialLayout.alignFromTop(view, child: cardView, top: self.view.center.y - (cardView.height/2))
        MaterialLayout.alignToParentHorizontally(view, child: cardView, left: 20, right: 20)
    }


    @IBAction func logOutPressed(sender: AnyObject) {
        User.currentUser?.logout()
    }

    func collectionView(timeline: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if shoeTimeline != nil {
            return (shoeTimeline?.count)!
        } else {
            return 0
        }
    }

    func items() {

    }

    func collectionView(timeline: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = timeline.dequeueReusableCellWithReuseIdentifier("TimelineCell", forIndexPath: indexPath) as! KSTimelineCollectionViewCell

        cell.shoeNameLabel.text = shoeTimeline![indexPath.row].name
        cell.shoeImageView.image = shoeTimeline![indexPath.row].shoeImage
        cell.sizeLabel.text = shoeTimeline![indexPath.row].size!
        cell.conditionLabel.text = shoeTimeline![indexPath.row].condition
        cell.shoeTagView.backgroundColor = shoeTagViewColor

        return cell
    }

    func collectionView(timeline: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        tapCount += 1
        self.profileTrayView.snp_remakeConstraints { (make) -> Void in
            make.top.equalTo((profileTrayView.superview?.snp_top)!).offset(0).constraint
        }
        textView.userInteractionEnabled = false
        textView.hidden = true
        profileTrayView.setNeedsLayout()
        UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.5, options:[] , animations: { () -> Void in
            self.profileTrayView.layoutIfNeeded()
            }, completion: { (Bool) -> Void in
        })
    }

    //MARK: - Firebase Get Methods
    func getShoesFromFirebase() {
        // Get a reference to our posts
        FirebaseClient.sharedClient.getTimelineShoes({ (shoes, error) in
            if error == nil {
                self.shoeTimeline = shoes as! [Shoe]
                self.timeline.reloadData()
            } else {
                print("Error: KSTimelineViewController.getShoes")
            }
        })
    }

    func getUserById(userId: String) {
            // Get a reference to our posts
//            let userRef = FirebaseClient.getRefWith("users")
//
//        userRef.observeEventType(.Value, withBlock: { snapshot in
//            var tempUser: User?
//            let dict = snapshot.value as! NSDictionary
//            for x in dict {
//                var userToAppend = User(dictionary: x.value as! NSDictionary)
//                if "facebook:\(userToAppend.uid!)" == userId {
//                    tempUser = userToAppend
//                }
//            }
//
//            self.visibleUser = tempUser
//            self.userProfileImage.setImageWithURL(NSURL(string: (self.visibleUser?.profilePicUrl)!)!)
//            self.userProfileImage.clipsToBounds = true
//            self.profileName.text = self.visibleUser?.displayName
//
//            }, withCancelBlock: { error in
//                print(error.description)
//        })
        
        FirebaseClient.sharedClient.getUserById(userId) { (user, error) in
            if(error == nil){ //good tings..
                self.visibleUser = user
                self.userProfileImage.setImageWithURL(NSURL(string: (self.visibleUser?.profilePicUrl)!)!)
                self.userProfileImage.clipsToBounds = true
                self.profileName.text = self.visibleUser?.displayName
                self.userProfileImage.setImageWithURL(NSURL(string: (self.visibleUser?.profilePicUrl)!)!)
                self.userProfileImage.clipsToBounds = true
                self.profileName.text = self.visibleUser?.displayName
            } else { //bad ting dat :(
                print(error)
            }
        }

    }

    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        //profile card view animation
        UIView.transitionWithView(profileTrayView, duration: 1, options: UIViewAnimationOptions.TransitionFlipFromBottom, animations: { self.profileTrayView = self.profileTrayView}, completion: { (value: Bool) in
            //self.profileTrayView.alpha = 1
        })
    }

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        var currentCellCenter = CGPointMake(self.timeline.center.x + self.timeline.contentOffset.x,
            self.timeline.center.y + self.timeline.contentOffset.y)

        self.mainCollectionViewCellIndexPath = self.timeline.indexPathForItemAtPoint(currentCellCenter)

        print(self.shoeTimeline![mainCollectionViewCellIndexPath!.row].price)

        //var cellInViewIndex = Int(mainCollectionViewCellIndexPath.row)

        getUserById(shoeTimeline![(mainCollectionViewCellIndexPath?.row)!].ownerId!)

    }

    //initiate theme
    func layoutTheme() {
        self.timelineColorBackground.backgroundColor = timelineBackgroundColor
        self.profileTrayView.backgroundColor = profileTrayViewColor
        self.profileTrayView.pulseColor = pulseColor
        //trayViewButton.setBackgroundImage(UIImage(named: ""), forState: .Normal)
        //trayViewButton.setBackgroundImage(UIImage(named: ""), forState: .Highlighted)
        profileName.textColor = textColor
    }
    
    
    @IBAction func bidButtonPressed(sender: AnyObject) {
        print("bid")
        addBidView()
    }
    
    func cancelBid(sender:UIButton!) {
        cardView.removeFromSuperview()
    }
    
    func submitBid(sender:UIButton!) {
        print(bidValue)
        var tempBidArray = shoeTimeline![mainCollectionViewCellIndexPath!.row].bids
        tempBidArray?.append("\(bidValue)")
        shoeTimeline![mainCollectionViewCellIndexPath!.row].bids = tempBidArray
        print(shoeTimeline![mainCollectionViewCellIndexPath!.row].bids)
        cardView.removeFromSuperview()
    }
    
    func bidSliderDidChange(sender: UISlider) {
//        sender.setValue(ceil(((sender.value + 2.5) / 5) * 5), animated: false)
        sender.value = ceil(sender.value)
        bidValue = ceil(sender.value)
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
