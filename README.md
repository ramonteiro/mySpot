My Spot - Exporation

Check it out on the AppStore: https://apps.apple.com/us/app/my-spot-exploration/id1613618373

---What is My Spot---

My Spot is a simple app that allows users to create spots that save photos, location, date, and description info to keep track of certain locations. It also alows for spots to be uploaded and shared to others.

---Features of My Spot---

- create spots
- search for other spots in area
- create playlists to organize spots
- spots and playlists are backed up in iCloud and sync across devices

---Who is My Spot For---

Everyone! Whether you are a skater, hiker, mountain biker, etc, or maybe you just want a quiet place to watch the sunset. These are all spots you can find on My Spot. Special locations are difficult to find with a quick google search and My Spot comes in as a solution.

---How to Use My Spot---

Demo Video: https://youtu.be/Q0FO_jjDHzA

When starting My Spot you are greeted with the my spots tab where you can start by adding a spot. These spots are stored locally in core data unless the public slider is checked in which case it is uploaded to a database hoted in cloudkit.

Quick interaction:
- press the map button to show the spots in the current tab on a map. In the map press the top left to exit, swipe through locations or tap on new locations to change, tap on the location preview to bring up a detailed description, press the top right arrow to focus on user location, press the top right line to get directions to selected spot.

Discover tab:
- to seacrh location from a specific point on a map, press the map button and select search here on the area you would like to search by. Now the spots listed are in order of the location you selected and the name of the city is displayed in the seacrh bar. Use the seacrh bar to further refine your seacrh by looking for specific names or tags.

---Important Requirements---

My Spot needs the following:
- an icloud account to upload, download, or browse spots hosted with cloudkit
- location services to create a spot (Spots MUST be created in the location, cooridinates are taken from gps and connot be entered manually)
- camera access to take a photo of spot (Spot photos cannot be taken from photo library)

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
