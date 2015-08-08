# RPPullDownToRefresh

[![CI Status](http://img.shields.io/travis/Francesco/RPPullDownToRefresh.svg?style=flat)](https://travis-ci.org/Francesco/RPPullDownToRefresh)
[![Version](https://img.shields.io/cocoapods/v/RPPullDownToRefresh.svg?style=flat)](http://cocoapods.org/pods/RPPullDownToRefresh)
[![License](https://img.shields.io/cocoapods/l/RPPullDownToRefresh.svg?style=flat)](http://cocoapods.org/pods/RPPullDownToRefresh)
[![Platform](https://img.shields.io/cocoapods/p/RPPullDownToRefresh.svg?style=flat)](http://cocoapods.org/pods/RPPullDownToRefresh)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
- iOS 8.0+
- Xcode 6.3
- Swift 1.2

## Installation

RPPullDownToRefresh is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
use_frameworks!
pod "RPPullDownToRefresh"
```

# RPPullDownToRefresh

![alt tag](https://github.com/RedPlumber/RPPullDownToRefresh.git)


#HOW TO USE IT

At first, import RPPullDownToRefresh framework:

```swift
import RPPullDownToRefresh
```

Ccreate the refresh control, add it to your view and provide and provide the end action

```swift
class ViewController: UIViewController{

    var refreshControl : PullDownToRefresh?

    override func viewDidLoad() {
        super.viewDidLoad()

        var colors = [UIColor.yellowColor(), UIColor.purpleColor(), UIColor.cyanColor(), UIColor.brownColor()]

        self.refreshControl = PullDownToRefresh(scrollView: self.tableView, marginFromTop : 64, colors : colors)
        self.view.addSubview(self.refreshControl!)
        self.refreshControl?.addTarget(self, action: "refreshData:", forControlEvents: UIControlEvents.ValueChanged)
    }

    func refreshData(sender : AnyObject?){
        let delay = 5 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.refreshControl!.stopRefreshing()
        }
    }
```

## Author

Francesco Petrungaro (RedPlumber), redplumber@icloud.com

## License

RPPullDownToRefresh is available under the MIT license. See the LICENSE file for more info.
