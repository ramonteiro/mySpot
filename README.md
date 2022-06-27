# My Spot - Exporation

## Links
[AppStore](https://apps.apple.com/us/app/my-spot-exploration/id1613618373), download and drop a review ;)

[Tiktok](https://www.tiktok.com/@myspotexploration/video/7099636047973272874?is_copy_url=1&is_from_webapp=v1), short 2-min summary

[Youtube My Spot 1.4 Demo](https://www.youtube.com/watch?v=OSmGs8Fs5_I&t=324s), this includes: Widgets, apple watch, shared playlists, notifications

[Youtube My Spot Demo up to 1.3.3](https://www.youtube.com/watch?v=UcQJhaeTPng&t=11s), this includes everything else

[Youtube My Spot Demo up to 2.0.0](https://youtube.com/shorts/P-rfnfZ44XM?feature=share), this will include only changes made in 2.0.0

## What is My Spot?
My Spot is a simple app that allows users to create spots that save photos, location, date, and description info to keep track of certain locations. It also alows for spots to be uploaded and shared to others.

## Features of My Spot
- create spots
- search for other spots in area
- create playlists to organize spots
- share playlists to a group of friends to all collobarate by adding or removing spots in the same playlists
- spots and playlists are backed up in iCloud and sync across devices
- Widgets
- Apple watch support, ipad support, ipod/iphone support
- localized in 12 languages

## Who is My Spot For?
Everyone! Whether you are a skater, hiker, mountain biker, etc, or maybe you just want a quiet place to watch the sunset. These are all spots you can find on My Spot. Special locations are difficult to find with a quick google search and My Spot comes in as a solution.

## How to Use My Spot?
(See Youtube videos, timestamps are included)

## Permissions
My Spot may request the following permissions:
- (required) an icloud account to upload, download, or browse spots hosted with cloudkit
- location services to create a spot
- camera access to take a photo of spot
- notifications to alert users when new spots are added to their area.

## Libraries Used
```swift
import Swiftui
import MapKit
import Combine
import CloudKit
import UIKit
import Vision
```


## Installation
In order to run this project with cloukit:

- you must change signing and capabilities to your own apple developer accont with an icloud container
- that container must be in entitlements as well
- the discover tab will load indefinitely until a spot is uploaded as public
- the container must also allow for sorting by creation date and distance in indexes


## TODOS
Features:
- Re-design detail view
- add section to find users in discover
- app clip (ios 16 only, this is due to cloudkit only available in app clips in ios 16)
- support new ios 16: better ipad screen size handling, share views
- Mac support
- Update detail view map to use uikit mapview and add cluters in of map annotations + satellite view
- Make filters + search a half sheet (ios 16)

Clean-up:
- Create generic cruid funtions for cloudkit…clean up entire cloudkit view model
- Create view models for each view and inject that view model instead of the model itself 
- Remove spot data from defaults and change iMessage app to use core data
- refactor names, create a naming convention and give more thought to names

Bugs:
- None at the moment :) (at least none found yet)

Business:
- Create github pages website and replace wordpress
- Monetize app

