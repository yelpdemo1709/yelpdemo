# yelpdemo
an iOS app to demo the usage of some Yelp API (Search, Review).

## Environment
- Xcode 9
- Swift 4.0
- Base SDK iOS 11.0
- Deployment Target >= 10.3
- Testing Devices: iPad mini 2 A1489 (iOS 10.3.3), iOS simulators

## Usage
- Open RestaurantFinder/RestaurantFinder.xcworkspace with latest Xcode, build and run target "RestaurantFinder" of project "RestaurantFinder".
- To run the app on a real iOS device one has to configure bundle id, certificate and provisioning profile for the target.

## Features
- Universal app, adapt to all iPad/iPhone size classes.
- Keyword search return restaurant list (10 w/ term, 50 w/o term) from the Yelp API.
- Results displayed in a “grid” view that includes restaurant name and address.
- Grid sortable alphabetically by restaurant name (asc/desc).
- Tap each grid item to be taken to a detail view.
- Details view of each restaurant include the latest review and a photo as well as the name and address.

## Known Issues
- Tried to make the code testable, but didn't get the chance to write the UT yet.
- Given the simplicity of the demo, current verison of YelpRestaurantFinder is somewhat like a utility class, may consider to have a data model entity as needed to maintain states and handle caching.
- Hardcoded values, literal strings.
- UI improvement needed, such as image button, loading indicator, app icon, default image, keeping cell selection while sorting restaurants, ...
- Draft code many places to be improved.
- There exist several minor warnings in thirdparty libraries which are left as is.
