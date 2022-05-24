My Spot - Exporation

Check it out on the AppStore: https://apps.apple.com/us/app/my-spot-exploration/id1613618373
Tiktok 2-min summary: https://www.tiktok.com/@myspotexploration/video/7099636047973272874?is_copy_url=1&is_from_webapp=v1
Youtube My Spot 1.4 Update (Widgets, apple watch, shared playlists, notifications): https://www.youtube.com/watch?v=OSmGs8Fs5_I&t=324s
Youtube My Spot Demo up to 1.3.3: https://www.youtube.com/watch?v=UcQJhaeTPng&t=11s

---What is My Spot---

My Spot is a simple app that allows users to create spots that save photos, location, date, and description info to keep track of certain locations. It also alows for spots to be uploaded and shared to others.

---Features of My Spot---

- create spots
- search for other spots in area
- create playlists to organize spots
- share playlists to a group of friends to all collobarate by adding or removing spots in the same playlists
- spots and playlists are backed up in iCloud and sync across devices
- Widgets
- Apple watch support, ipad support, ipod/iphone support
- localized in 12 languages

---Who is My Spot For---

Everyone! Whether you are a skater, hiker, mountain biker, etc, or maybe you just want a quiet place to watch the sunset. These are all spots you can find on My Spot. Special locations are difficult to find with a quick google search and My Spot comes in as a solution.

---How to Use My Spot---

(See Youtube videos, timestamps are included)

---Important Requirements---

My Spot may request the following permissions:
- (required) an icloud account to upload, download, or browse spots hosted with cloudkit
- location services to create a spot
- camera access to take a photo of spot
- notifications to alert users when new spots are added to their area.

---libraries used---

- Swiftui
- MapKit
- Combine
- CloudKit


******IMPORTANT******

In order to run this project with cloukit:

- you must change signing and capabilities to your own apple developer accont with an icloud container
- that container must be in entitlements as well
- the discover tab will load indefinitely until a spot is uploaded as public (is will keep searching for spots until the cloudkit container is empty) 
- the container must also alow for sorting by creation date and distance in indexes
- a small package named, mantis is used to crop photos to 1:1. This package should automatically be downloaded by xcode's package manager
