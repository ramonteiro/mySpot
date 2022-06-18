//
//  SetNavigationSwipeToPop.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/18/22.
//

import UIKit

// overrides uigestures to allow for swipe to pop navigation view WITH backbutton hidden
extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
