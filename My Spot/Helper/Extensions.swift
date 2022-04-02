//
//  Extensions.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/14/22.
//

import SwiftUI
import MapKit

// compresses uiimage
extension UIImage {
    func aspectFittedToHeight(_ newHeight: CGFloat) -> UIImage {
        let scale = newHeight / self.size.height
        let newWidth = self.size.width * scale
        let newSize = CGSize(width: newWidth, height: newHeight)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// check if value exists in userdefaults
extension UserDefaults {
    func valueExists(forKey key: String) -> Bool {
        return object(forKey: key) != nil
    }
}

// parses string for hashtags and returns string of comma seperated tags
extension String {
    func findTags() -> String {
        var arr_hasStrings:String = ""
        let regex = try? NSRegularExpression(pattern: "(#[a-zA-Z0-9_\\p{Arabic}\\p{N}]*)", options: [])
        if let matches = regex?.matches(in: self, options:[], range:NSMakeRange(0, self.count)) {
            for match in matches {
                var tag = NSString(string: self).substring(with: NSRange(location:match.range.location, length: match.range.length ))
                if (tag.count != 1) {
                    tag.removeFirst()
                    arr_hasStrings.append(tag)
                    arr_hasStrings += ", "
                }
            }
        }
        if (!arr_hasStrings.isEmpty) {
            arr_hasStrings.removeLast()
            arr_hasStrings.removeLast()
        }
        return arr_hasStrings
    }
}

// defines shortcut to get screen width and height
extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}


// allows conditional modifier to views to add certain modifiers, ex (makes text yellowMode if yellow is true): Text("hello").if(yellowmode == true){ view in view.foregroundColor(.yellow) }
extension View {

    @ViewBuilder func `if`<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
}

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


extension MKCoordinateRegion{
    ///Identify the length of the span in meters north to south
    var spanLatitude: Measurement<UnitLength>{
        let loc1 = CLLocation(latitude: center.latitude, longitude: center.longitude - span.latitudeDelta * 0.5)
        let loc2 = CLLocation(latitude: center.latitude, longitude: center.longitude + span.latitudeDelta * 0.5)
        let metersInLatitude = loc1.distance(from: loc2)
        return Measurement(value: metersInLatitude, unit: UnitLength.meters)
    }
}

extension UIApplication {
     func dismissKeyboard() {
         sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
     }
 }
