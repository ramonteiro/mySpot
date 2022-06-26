//
//  AccountModel.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/5/22.
//

import Foundation
import UIKit
import CloudKit

struct AccountModel: Hashable, Identifiable {
    let id: String
    let name: String
    var image: UIImage?
    let pronouns: String?
    let isExplorer: Bool
    let bio: String?
    let record: CKRecord
    let tiktok: String?
    let insta: String?
    let youtube: String?
    let email: String?
}
