//
//  Extensions.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/14/22.
//

import SwiftUI

// compresses uiimage to send to cloudkit storage
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

extension UserDefaults {
    func valueExists(forKey key: String) -> Bool {
        return object(forKey: key) != nil
    }
}

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

extension View {

    @ViewBuilder func `if`<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
}
