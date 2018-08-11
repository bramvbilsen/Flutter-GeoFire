# Abandoned!
Because I do not have the time to actively support this anymore, I changed the status of this project to "abandoned". This project was last tested when Flutter was still in Alpha, so things might be broken. For those still willing to contribute, I will accept pull requests.

# Flutter GeoFire

![Firebase logo](https://firebase.google.com/_static/images/firebase/touchicon-180.png)

GeoFire is a library that makes it easy to store location in a Firebase database. The main advantage of GeoFire is the ability to use queries to search for locations. This plugin is an unofficial wrapper to make the library available for use with Flutter. This plugin works with the [FlutterFire] plugins. **Currently only supports Android!**

## Getting started
GeoFire requires the Firebase database in order to store location data. You can sign up [here] for a free account.

## Quickstart

### Adding to a project
You can add this project to your repo by adding the following to your `pubspec.yaml` under your dependencies:
```dart
geofire:
  git:
    url: "git://github.com/bramvbilsen/Flutter-GeoFire.git"
```
You can import the library like this:
```dart
import 'package:geofire/geofire.dart';
```

### GeoFire
Use a `GeoFire` object to read and write location data to your Firebase database. A `GeoFire` instance needs a path reference to where you are working in the database. This path reference will be a `String`. 
```dart
String path = "loc/loc1/loc2";
final DatabaseReference ref = FirebaseDatabase.instance.reference().child(path);
GeoFire geofire = new GeoFire(path);
```

##### Setting location data
To set a location with a specific key, we use `setLocation` on your `GeoFire` instance. This method takes a key as a string and a location which is a list of doubles of length two: The first element in the list will be the latitude and the second element will be the longitude.
```dart
geofire.setLocation("Mechelen", [51.0259, 4.4775])
```
Optionally, you can also pass the method a `GeoFireEventListener`. This will notify you when the key location pair is written away successfully in the database or if an error occurred.
```dart
geofire.setLocation("Mechelen", [51.0259, 4.4775],  new GeoFireEventListener((String key, DatabaseError error) {
    if (error != null) {
        print(error.toString());
    } else {
        print("Success!");
    }
}))
```

##### Removing location data
To remove location data from the database, we call `removeLocation`. Simply provide the key that is associated with the location.
```dart
geofire.removeLocation("Mechelen")
```
Optionally, you can also pass the method a `GeoFireEventListener`. This will notify you when the location got removed successfully in the database or if an error occurred.
```dart
geofire.removeLocation("Mechelen", new GeoFireEventListener((String key, DatabaseError error) {
    if (error == null) {
        print("No error");
        print(key + " removed!");
    } else {
        print("Error");
        print(error.toString());
    }
}));
```

##### Retrieving a location
To retrieve location data from a single key, we call `getLocation`. This method takes the key of which you want to receive the location and a `LocationCallBack`.
```dart
geofire.getLocation("Mechelen", new LocationCallBack(
  (String key, List<double> location) { // onLocationResult
    print("Successfully received location!");
    print(key + ": " + location.toString());
  }, 
  (DatabaseError error) { // onCancelled
    print("Error receiving location!");
    print(error.toString());
  }
));
```

### GeoQuery
You can perform queries with GeoFire to get back multiple keys in a certain region with the `GeoQuery` class. You can add a `GeoQueryEventListener` which to an instance of a `GeoQuery` object which will notify you when the listener is ready to use, when new keys enter the region, when keys leave the region, when keys move and when an error occurred. To add a `GeoQuery` to a `GeoFire` instance, you call `addGeoQueryEventListener`. The first argument will be the center (again in the double list notation), and the second argument will be a double to represent the radius.
```dart
GeoQuery query = geofire.queryAtLocation([51.0259, 4.4775], 50.0)
```

##### Receiving events for GeoQueries
As mentioned, we can listen for events that occur with our query. More specifically, there are 5 events that can be triggered:
* **Key Entered**: A key entered your query region.
* **Key Exited**: A key is no longer in the query region.
* **Key Moved**: A key that was in the query region moved, but is still in the query region.
* **Query Ready**: All current data has been loaded from the server and all initial events have been fired.
* **Query Error**: There was an error while performing this query, e.g. a violation of security rules.

To listen for events you must add a `GeoQueryEventListener` to the `GeoQuery`:
```dart
GeoQueryEventListener listener = new GeoQueryEventListener(
  (String key, List<double> location) { // onKeyEntered
    print("Key entered!");
    print(key + ": " + location[0].toString() + ", " + location[1].toString());
  }, 
  (String key) { // onKeyExited
    print("Key exited!");
    print(key);
  }, 
  (String key, List<double> location) { // onKeyMoved
    print("Key moved!");
    print(key + ": " + location[0].toString() + ", " + location[1].toString());
  }, 
  () { // onGeoQueryReady
    print("Finished with the query!");
  }, 
  (DatabaseError error) { // onGeoQueryError
    print("Query resulted in an error!");
    print(error.toString());
  }
);
query.addGeoQueryEventListener(listener);
```
To remove this listener from the query, simply call `removeGeoQueryEventListener`.

   [FlutterFire]: <https://github.com/flutter/plugins/blob/master/FlutterFire.md>
   [here]: <https://firebase.google.com/>
