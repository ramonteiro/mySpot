//
//  MailViewCallback.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/16/22.
//

import SwiftUI
import UIKit
import MessageUI

typealias MailViewCallback = ((Result<MFMailComposeResult, Error>) -> Void)?

struct MailView: UIViewControllerRepresentable {
  @Environment(\.presentationMode) var presentation
  @Binding var message: String
  let callback: MailViewCallback

  class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
    @Binding var presentation: PresentationMode
    @Binding var message: String
    let callback: MailViewCallback

    init(presentation: Binding<PresentationMode>,
         message: Binding<String>,
         callback: MailViewCallback) {
      _presentation = presentation
      _message = message
      self.callback = callback
    }

    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
      if let error = error {
        callback?(.failure(error))
      } else {
        callback?(.success(result))
      }
      $presentation.wrappedValue.dismiss()
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(presentation: presentation, message: $message, callback: callback)
  }

  func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
    let vc = MFMailComposeViewController()
    vc.mailComposeDelegate = context.coordinator
    vc.setSubject("My Spot - Exploration, Report")
    vc.setToRecipients(["iwp2358@gmail.com"])
    vc.setMessageBody(message, isHTML: false)
    vc.accessibilityElementDidLoseFocus()
    return vc
  }

  func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                              context: UIViewControllerRepresentableContext<MailView>) {
  }

  static var canSendMail: Bool {
    MFMailComposeViewController.canSendMail()
  }
}

