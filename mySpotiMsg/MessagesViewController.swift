//
//  MessagesViewController.swift
//  mySpotiMsg
//
//  Created by Isaac Paschall on 5/25/22.
//

import UIKit
import MapKit
import Messages

class MessagesViewController: MSMessagesAppViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Data model: These strings will be the data for the table view cells
    var spots: [msgSpot] = []
    
    // cell reuse id (cells that scroll out of view can be reused)
    let cellReuseIdentifier = "cell"
    
    var tableView = UITableView()
    var noSpotsMessage = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        syncFromAppGroups()
        configureTableView()
    }
    
    // MARK: - UI
    
    func configureTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 100
        tableView.register(SpotCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.pin(to: view)
        if spots.count == 0 {
            view.addSubview(noSpotsMessage)
            noSpotsMessage.text = "No Spots Here Yet!".localized()
            noSpotsMessage.textAlignment = .center
            noSpotsMessage.pin(to: tableView)
            noSpotsMessage.layer.zPosition = 100
            noSpotsMessage.center.x = view.center.x
            noSpotsMessage.center.y = view.center.y
        }
    }
    
    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return spots.count
    }
    
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: SpotCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! SpotCell
        let spot = spots[indexPath.row]
        cell.set(spot: spot)
        cell.selectionStyle = .none
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let entry = spots[indexPath.row]
        
        let layout = MSMessageTemplateLayout()
        layout.caption = entry.name
        layout.subcaption = (entry.locationName.isEmpty ? "My Spot" : entry.locationName)
        layout.image = entry.image
        let message = MSMessage()
        message.summaryText = "\(entry.x)+\(entry.y)+\(entry.name)"
        message.layout = layout
        if (self.activeConversation != nil) {
            self.activeConversation?.insert(message, completionHandler: nil)
        } else {
            print("No convo")
        }
    }
    
    // MARK: - Data Handling
    func syncFromAppGroups() {
        let userDefaults = UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")
        if let spotCount = userDefaults?.integer(forKey: "spotCount") {
            if spotCount != spots.count {
                guard let xArr: [Double] = userDefaults?.object(forKey: "spotXs") as? [Double] else { return }
                guard let yArr: [Double] = userDefaults?.object(forKey: "spotYs") as? [Double] else { return }
                guard let nameArr: [String] = userDefaults?.object(forKey: "spotNames") as? [String] else { return }
                guard let locationNameArr: [String] = userDefaults?.object(forKey: "spotLocationName") as? [String] else { return }
                guard let imgArr: [Data] = userDefaults?.object(forKey: "spotImgs") as? [Data] else { return }
                for i in imgArr.indices {
                    let decoded = try! PropertyListDecoder().decode(Data.self, from: imgArr[i])
                    let image = UIImage(data: decoded)!
                    let x = xArr[i]
                    let y = yArr[i]
                    let name = nameArr[i]
                    let newSpot = msgSpot(name: name, image: image, x: x, y: y, locationName: (locationNameArr[i].isEmpty ? "My Spot" : locationNameArr[i]))
                    spots.append(newSpot)
                }
            }
        }
    }
    
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.
        
        // Use this method to configure the extension and restore previously stored state.
    }
    
    override func willSelect(_ message: MSMessage, conversation: MSConversation) {
        super.willSelect(message, conversation: conversation)
        guard let locationArr: [String] = message.summaryText?.components(separatedBy: "+") else { return }
        if locationArr.count > 1 {
            let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: Double(locationArr[0]) ?? 128.0, longitude: Double(locationArr[1]) ?? 129.0)))
            if locationArr.count == 3 {
                routeMeTo.name = locationArr[2]
            } else {
                routeMeTo.name = "My Spot"
            }
            routeMeTo.openInMaps(launchOptions: nil)
        }
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dismisses the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
    }
    
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
        
        // Use this to clean up state related to the deleted message.
    }
    
    override func willTransition(to newPresentationStyle: MSMessagesAppPresentationStyle) {
        
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
        
        // Use this method to finalize any behaviors associated with the change in presentation style.
    }
    
}

class SpotCell: UITableViewCell {
    
    var spotImageView = UIImageView()
    var spotTitleLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(spotImageView)
        addSubview(spotTitleLabel)
        configureImageView()
        configureTitleView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(spot: msgSpot) {
        spotImageView.image = spot.image
        spotTitleLabel.text = spot.name
    }
    
    func configureImageView() {
        spotImageView.layer.cornerRadius = 10
        spotImageView.clipsToBounds = true
        
        spotImageView.translatesAutoresizingMaskIntoConstraints = false
        spotImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        spotImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        spotImageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        spotImageView.widthAnchor.constraint(equalTo: spotImageView.heightAnchor).isActive = true
    }
    
    func configureTitleView() {
        spotTitleLabel.numberOfLines = 0
        spotTitleLabel.adjustsFontSizeToFitWidth = true
        
        spotTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        spotTitleLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        spotTitleLabel.leadingAnchor.constraint(equalTo: spotImageView.trailingAnchor, constant: 20).isActive = true
        spotTitleLabel.heightAnchor.constraint(equalToConstant: 80).isActive = true
        spotTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
    }
}


struct msgSpot: Identifiable {
    let id = UUID()
    let name: String
    let image: UIImage
    let x: Double
    let y: Double
    let locationName: String
}

extension UIView {
    func pin(to superView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: superview!.topAnchor).isActive = true
        leadingAnchor.constraint(equalTo: superview!.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: superview!.trailingAnchor).isActive = true
        bottomAnchor.constraint(equalTo: superview!.bottomAnchor).isActive = true
    }
}

extension String {
    func localized() -> String {
        return NSLocalizedString(self, tableName: "Localizable", bundle: .main, value: self, comment: self)
    }
}
