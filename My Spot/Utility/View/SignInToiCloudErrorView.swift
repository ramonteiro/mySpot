//
//  SignInToiCloudErrorView.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/18/22.
//

import SwiftUI

struct SignInToiCloudErrorView: View {
    
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    
    @ViewBuilder
    var body: some View {
        if let accountStatus = cloudViewModel.accountStatus {
            if accountStatus == .noAccount {
                notSignedIn
            } else if accountStatus == .couldNotDetermine {
                checkInternet
            } else if accountStatus == .restricted {
                restrictedAccount
            } else if accountStatus == .temporarilyUnavailable {
                tempBroken
            }
        } else {
            unknownError
        }
    }
    
    private var tempBroken: some View {
        VStack(spacing: 6) {
            HStack {
                Spacer()
                Text("iCloud account temporarily unavailable".localized())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
            HStack {
                Spacer()
                Text("Please try again later".localized()).font(.subheadline).foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
        }
    }
    
    private var restrictedAccount: some View {
        VStack(spacing: 6) {
            HStack {
                Spacer()
                Text("Restricted iCloud account".localized())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
            HStack {
                Spacer()
                Button {
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: nil)
                    }
                } label: {
                    Text("Your iCloud account is restricted by parental controls or remote management".localized()).font(.subheadline).foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
            }
        }
    }
    
    private var checkInternet: some View {
        VStack(spacing: 6) {
            HStack {
                Spacer()
                Text("Could not verify iCloud account".localized())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
            HStack {
                Spacer()
                Button {
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: nil)
                    }
                } label: {
                    Text("Please check internet and try again".localized()).font(.subheadline).foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
            }
        }
    }
    
    private var notSignedIn: some View {
        VStack(spacing: 6) {
            HStack {
                Spacer()
                Text("You Must Be Signed In To iCloud".localized())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
            HStack {
                Spacer()
                Button {
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: nil)
                    }
                } label: {
                    Text("Please Sign In Or Create An Account In Settings and enable iCloud for My Spot".localized()).font(.subheadline).foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
            }
            HStack {
                Spacer()
                Button {
                    let youtubeId = "wsu8ZPWMMrw"
                    if let youtubeURL = URL(string: "youtube://\(youtubeId)"),
                       UIApplication.shared.canOpenURL(youtubeURL) {
                        // redirect to app
                        UIApplication.shared.open(youtubeURL, options: [:], completionHandler: nil)
                    } else if let youtubeURL = URL(string: "https://www.youtube.com/watch?v=\(youtubeId)") {
                        // redirect through safari
                        UIApplication.shared.open(youtubeURL, options: [:], completionHandler: nil)
                    }
                } label: {
                    Text("Help".localized())
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Image(systemName: "questionmark.circle")
                }
                Spacer()
            }
            .padding(.top, 20)
        }
    }
    
    private var unknownError: some View {
        VStack(spacing: 6) {
            HStack {
                Spacer()
                Text("Unknown Error Occured".localized())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
            HStack {
                Spacer()
                Button {
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: nil)
                    }
                } label: {
                    Text("Please make sure you are signed in to iCloud".localized()).font(.subheadline).foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
            }
        }
    }
}
