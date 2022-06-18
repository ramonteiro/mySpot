//
//  GetTags.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/18/22.
//

import Foundation

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
