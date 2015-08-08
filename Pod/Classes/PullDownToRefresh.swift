//
//  RPPullDownToRefresh.swift
//  RPPullDownToRefresh
//
//  Created by Francesco Petrungaro on 08/04/2015.
//  Copyright (c) 2015 Francesco Petrungaro. All rights reserved.
//

import UIKit

private enum PullDownToRefreshState : Int {
    case Ready = 0, Dragging = 1, Refreshing = 2, Completed = 3
}

private let kBounceAnimation = "kBounceAnimation"
private let kBlowAnimation = "kBlowAnimation"
private let kTopSpaceVerticalOffset : CGFloat = 50.0

public class PullDownToRefresh: UIControl {
    
    var colors : [UIColor]?
    var finalColor : UIColor?
    
    private var finalLayer: CAShapeLayer!
    private var dispatchOnceToken : dispatch_once_t = 0
    private var topSpaceVerticalConstrait : NSLayoutConstraint!
    private var centerXConstrait : NSLayoutConstraint!
    private var targetScrollView : UIScrollView?
    private var mainView : UIView!
    private var bouncingLayer : CAShapeLayer!
    private var _marginFromTop : CGFloat?
    private var isDraggingScrollView : Bool?
    private var isPullDownCompleted : Bool?
    private var currentRefreshState = PullDownToRefreshState.Ready
    private var indexColor : Int = 0
    
    var marginFromTop : CGFloat! {
        get{
            return _marginFromTop
        }
        set (newMarginTop) {
            
            _marginFromTop = -newMarginTop
            self.layoutIfNeeded()
        }
    }
    
    // MARK: - Initializer

    convenience public init(scrollView : UIScrollView!, marginFromTop : CGFloat!, colors : [UIColor]?){
        self.init(frame: scrollView.frame)
        
        self.backgroundColor = UIColor.clearColor()
        
        self.marginFromTop = marginFromTop
        
        if let colors = colors {
            self.colors = colors
        }
        else{
            self.colors = [self.tintColor]
        }
        
        self.setupMainView()
        self.setupBouncingLayer()
        self.setupFrame()
        
        if let targetScrollView = scrollView {
            self.targetScrollView = targetScrollView
            self.setupObservers()
        }
    }
    
    deinit{
        self.targetScrollView?.removeObserver(self, forKeyPath: "contentOffset")
        self.targetScrollView?.removeObserver(self, forKeyPath: "pan.state")
    }
    
    override public func didMoveToSuperview() {
        self.addConstraints()
    }
    
    override public func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        
        let duration : NSTimeInterval = 0.2
        
        switch(keyPath)
        {
        case "contentOffset" :
            if let point: CGPoint = change[NSKeyValueChangeNewKey]?.CGPointValue() {
                self.scrollViewDidScroll(point)
            }
        case "pan.state" :
            if (currentRefreshState != PullDownToRefreshState.Refreshing){
                if let state: Int = change[NSKeyValueChangeNewKey] as? Int {
                    if (state == PullDownToRefreshState.Refreshing.rawValue) {
                        if (currentRefreshState == PullDownToRefreshState.Completed) {
                            if (self.targetScrollView!.contentOffset.y > -kTopSpaceVerticalOffset + self.marginFromTop!) {
                                self.isDraggingScrollView = true
                                self.currentRefreshState = PullDownToRefreshState.Dragging
                            }
                        }
                        else {
                            self.isDraggingScrollView = true
                            self.currentRefreshState = PullDownToRefreshState.Dragging
                        }
                        
                    } else if (state == PullDownToRefreshState.Completed.rawValue) {
                        
                        if (self.currentRefreshState != PullDownToRefreshState.Dragging) {
                            return
                        }
                        
                        self.isDraggingScrollView = true
                        if (self.isPullDownCompleted == true) {
                            self.currentRefreshState = PullDownToRefreshState.Refreshing
                            UIView.animateWithDuration(duration, animations: { () -> Void in
                                self.topSpaceVerticalConstrait.constant = kTopSpaceVerticalOffset - self.marginFromTop!
                                self.layoutIfNeeded()
                            })
                            
                            self.startRefreshing()
                            self.sendActionsForControlEvents(UIControlEvents.ValueChanged)
                        }
                    }
                }
            }
        default:
            UIView.animateWithDuration(duration, animations: { () -> Void in
                self.topSpaceVerticalConstrait.constant = -kTopSpaceVerticalOffset - self.marginFromTop!
                self.layoutIfNeeded()
                
                }, completion: { (completed) -> Void in
                    let color : UIColor = self.colors![self.indexColor] as UIColor
                    self.bouncingLayer.fillColor = color.CGColor
            })
        }
    }
    
    // MARK: - Setup
    
    private func setupFrame(){
        let origin = self.superview == nil ? 0.0 : CGRectGetWidth(self.superview!.frame)
        
        let rect = CGRectMake((origin - CGRectGetWidth(self.mainView.frame))/2, -kTopSpaceVerticalOffset + self.marginFromTop, CGRectGetWidth(self.mainView.frame), CGRectGetWidth(self.mainView.frame))
        self.frame = rect
    }
    
    private func setupMainView(){
        self.mainView = UIView(frame: CGRectMake(0, 0, 40, 40))
        self.mainView.clipsToBounds = false
        self.mainView.layer.backgroundColor = UIColor.whiteColor().CGColor
        self.mainView.layer.cornerRadius = CGRectGetWidth(self.mainView.frame)/2
        self.mainView.layer.shadowRadius = 1.0
        self.mainView.layer.shadowOpacity = 0.10
        self.mainView.layer.shadowOffset = CGSizeMake(0, 0.8)
        self.mainView.layer.shadowColor = UIColor.blackColor().CGColor
        self.addSubview(mainView)
    }
    
    private func setupBouncingLayer(){
        self.bouncingLayer = CAShapeLayer()
        self.bouncingLayer.cornerRadius = self.bouncingLayer.frame.size.width/2
        self.bouncingLayer.anchorPoint = CGPoint(x: 1.0, y: 1.0)
        let startPath = UIBezierPath(roundedRect: CGRect(origin: self.mainView.frame.origin, size: self.mainView.frame.size), cornerRadius: self.mainView.frame.size.width/2)
        self.bouncingLayer.path = startPath.CGPath
        self.mainView.layer.addSublayer(self.bouncingLayer)
    }
    
    private func addConstraints(){
        dispatch_once(&dispatchOnceToken, { () -> Void in
            
            self.topSpaceVerticalConstrait = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.superview, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: -kTopSpaceVerticalOffset)
            self.centerXConstrait = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.superview, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: -CGRectGetWidth(self.mainView.frame)/2)
            
            self.setTranslatesAutoresizingMaskIntoConstraints(false)
            self.superview?.addConstraint(self.topSpaceVerticalConstrait)
            self.superview?.addConstraint(self.centerXConstrait)
        })
    }
    
    private func setupObservers(){
        self.targetScrollView!.addObserver(self, forKeyPath: "contentOffset", options: NSKeyValueObservingOptions.New, context: nil)
        self.targetScrollView!.addObserver(self, forKeyPath: "pan.state", options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    // MARK: - scrollViewDidScroll
    
    private func scrollViewDidScroll(contentOffset : CGPoint){
        if (self.currentRefreshState == PullDownToRefreshState.Refreshing) {
            return
        }
        
        self.layer.opacity = 1
        
        let newY = -contentOffset.y - kTopSpaceVerticalOffset

        if abs(contentOffset.y) % 5 == 0 {
            self.indexColor++
            if (self.indexColor > self.colors!.count - 1) {
                self.indexColor = 0
            }
        }
        
        if (contentOffset.y - self.marginFromTop! > -100) {
            self.isPullDownCompleted = false
            let color = self.colors![indexColor] as UIColor
            self.bouncingLayer.fillColor = color.CGColor
            
            if (self.isDraggingScrollView == true) {
                self.topSpaceVerticalConstrait.constant = newY
                self.layoutIfNeeded()
            }
            
        } else {
            self.isPullDownCompleted = true
        }
    }
    
    // MARK: - Rotate Colors

    func rotateColors(){
        
        if (self.currentRefreshState == PullDownToRefreshState.Refreshing) {
            
            self.indexColor++
            if (self.indexColor > self.colors!.count - 1) {
                self.indexColor = 0
            }
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            let color = self.colors![indexColor] as UIColor
            self.bouncingLayer.fillColor = color.CGColor
            CATransaction.commit()
            
            let timer = NSTimer(timeInterval: 1.0, target: self, selector: "rotateColors", userInfo: nil, repeats: false)
            NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
        }
    }
    
    // MARK: - Start Refreshing Animations

    private func startRefreshing(){
        
        let offset = CGFloat(10)
        let endOrigin = CGPoint(x: -offset/2 , y: -offset/2)
        let endPath = UIBezierPath(roundedRect: CGRect(origin: endOrigin , size: CGSize(width: CGRectGetWidth(self.mainView.frame)+offset, height: CGRectGetHeight(self.mainView.frame)+offset)), cornerRadius: CGRectGetWidth(self.mainView.frame)+offset)
        
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = self.bouncingLayer.path
        pathAnimation.toValue = endPath.CGPath
        pathAnimation.duration = 0.5
        pathAnimation.fillMode = kCAFillModeForwards
        pathAnimation.autoreverses = true
        pathAnimation.removedOnCompletion = false
        pathAnimation.repeatCount = Float.infinity
        pathAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        pathAnimation.delegate = self
        self.bouncingLayer.addAnimation(pathAnimation, forKey: kBounceAnimation)
        
        let timer = NSTimer(timeInterval: 0.5, target: self, selector: "rotateColors", userInfo: nil, repeats: false)
        NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
    }
    
    // MARK: - Stop Refreshing Animations

    public func stopRefreshing() {
        
        self.mainView.backgroundColor = UIColor.clearColor()
        self.bouncingLayer.backgroundColor = UIColor.clearColor().CGColor
        self.bouncingLayer.removeAllAnimations()
        self.bouncingLayer.opacity = 0
        
        self.addFinalLayer()
        self.finalAnimation()
    }
    
    private func addFinalLayer() {
        self.finalLayer = CAShapeLayer()
        self.finalLayer.cornerRadius = self.finalLayer.frame.size.width/2
        
        if let finalColor = self.finalColor {
            self.finalLayer.fillColor = finalColor.CGColor
        }
        else{
            let color = self.colors![indexColor] as UIColor
            self.finalLayer.fillColor = color.CGColor
        }
        
        self.finalLayer.anchorPoint = CGPoint(x: 1.0, y: 1.0)
        let startPath = UIBezierPath(roundedRect: CGRect(origin: self.mainView.frame.origin, size: self.mainView.frame.size), cornerRadius: self.mainView.frame.size.width/2)
        self.finalLayer.path = startPath.CGPath
        self.mainView.layer.addSublayer(self.finalLayer)
    }
    
    private func finalAnimation() {
        
        let endPath = self.fullScreenCirclePath()
        
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = self.finalLayer.path
        pathAnimation.toValue = endPath.CGPath
        pathAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1
        opacityAnimation.toValue = 0
        opacityAnimation.beginTime = 0.3
        opacityAnimation.duration = 0.1
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        let animationGroup = CAAnimationGroup()
        animationGroup.fillMode = kCAFillModeForwards
        animationGroup.removedOnCompletion = false
        animationGroup.delegate = self
        animationGroup.duration = 0.4
        animationGroup.animations = [pathAnimation, opacityAnimation]
        
        self.finalLayer.path = endPath.CGPath
        self.finalLayer.addAnimation(animationGroup, forKey: kBlowAnimation)
    }
    
    private func fullScreenCirclePath() -> UIBezierPath {
        let newRadius = UIScreen.mainScreen().bounds.size.width*2
        let endOrigin = CGPoint(x: -newRadius/2 + self.mainView.frame.size.width/2, y: -newRadius/6)
        let endPath = UIBezierPath(roundedRect: CGRect(origin: endOrigin , size: CGSize(width: newRadius, height: newRadius)), cornerRadius: newRadius)
        return endPath
    }
    
    // MARK: - CAAnimation Delegate
    
    override public func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        if self.finalLayer.animationForKey(kBlowAnimation) != nil && anim == self.finalLayer.animationForKey(kBlowAnimation) {
            
            self.finalLayer.removeAllAnimations()
            self.finalLayer.path = UIBezierPath(rect: CGRect.zeroRect).CGPath
            
            self.centerXConstrait.constant = -CGRectGetWidth(self.mainView.frame)/2
            
            self.currentRefreshState = PullDownToRefreshState.Completed
            self.indexColor = 0
            
            self.topSpaceVerticalConstrait.constant = -kTopSpaceVerticalOffset + self.marginFromTop!
            
            self.mainView.backgroundColor = UIColor.whiteColor()
            self.bouncingLayer.removeAllAnimations()
            self.bouncingLayer.opacity = 1
            
            self.layer.opacity = 0
        }
    }

}
