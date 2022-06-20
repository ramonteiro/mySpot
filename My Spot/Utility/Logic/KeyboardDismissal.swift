//
//  KeyboardDismissal.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/18/22.
//

import UIKit

extension UIApplication {
     func dismissKeyboard() {
         sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
     }
 }
