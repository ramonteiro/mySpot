//
//  ShareViewController.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/4/22.
//

import Foundation
import SwiftUI

struct ShareViewController: UIViewControllerRepresentable {
    @Binding var isPresenting: Bool
    var content: () -> UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresenting {
            uiViewController.present(content(), animated: true, completion: nil)
        }
    }
}
