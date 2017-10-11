import 'package:flutter/material.dart';
import 'package:flutter_geofire_plugin/geofire.dart';
import 'package:firebase_database/firebase_database.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final DatabaseReference ref = FirebaseDatabase.instance.reference().child("loc/loc1/loc2");
  GeoFire geofire = new GeoFire("loc/loc1/loc2");
  GeoQuery query;
  GeoQueryEventListener listener;

  int string = 1;

  @override
  initState() {
    super.initState();
  }

  void createQuery(List<double> location, double radius) {
    this.query = geofire.queryAtLocation(location, radius);
    print(this.query.toString());
  }

  void addGeoQueryEventListenerToQuery() {
    listener = new GeoQueryEventListener(
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
  }

  void getAndPrintLocation() {
    geofire.getLocation("Mechelen", new LocationCallBack(
      (String key, List<double> location) {
        print("Successfully received location!");
        print(key + ": " + location.toString());
      }, 
      (DatabaseError error) {
        print("Error receiving location!");
        print(error.toString());
      }
    ));
  }

  void setMutlipleLocations() {
    Map<String, List<double>> keyLocs = new Map<String, List<double>>();
    keyLocs["Brussels"] = [51.0259, 4.3517];
    keyLocs["London"] = [51.5074, 0.1278];
    keyLocs["New York"] = [40.7128, 74.0059];
    for(String key in keyLocs.keys) {
      geofire.setLocation(key, [keyLocs[key][0], keyLocs[key][1]], 
        new GeoFireEventListener((String key, DatabaseError error) {
          if (error == null) {
            print("No error");
            print(key + " added!");
          } else {
            print("Error");
            print(error.toString());
          }
        })
      );
    }
  }

  void removeMutlipleLocations() {
    List<String> locs = ["Brussels", "London", "New York"];
    for(String loc in locs) {
      geofire.removeLocation(loc, new GeoFireEventListener((String key, DatabaseError error) {
        if (error == null) {
          print("No error");
          print(key + " removed!");
        } else {
          print("Error");
          print(error.toString());
        }
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('Plugin example app'),
        ),
        body: 
        new Center(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new Padding(padding: new EdgeInsets.only(top: 20.0),),
              new RaisedButton(
                child: new Text("Set Location"),
                onPressed: () => geofire.setLocation("Mechelen", [51.0259, 4.4775], // Necessary
                                                      new GeoFireEventListener((String key, DatabaseError error) { // Optional
                                                        String s = error == null ? key : error.toString();
                                                        print(s);
                                                      }))
              ),
              new RaisedButton(
                child: new Text("Print location"),
                onPressed: () => getAndPrintLocation(),
              ),
              new RaisedButton(
                child: new Text("Remove previously set location"),
                onPressed: () => geofire.removeLocation("Mechelen")
              ),
              new RaisedButton(
                child: new Text("Set multiple locations"),
                onPressed: () => this.setMutlipleLocations(),
              ),
              new RaisedButton(
                child: new Text("Remove multiple locations"),
                onPressed: () => this.removeMutlipleLocations(),
              ),
              new RaisedButton(
                child: new Text("Create query at location"),
                onPressed: () {this.createQuery([51.0259, 4.4775], 450.0);},
              ),
              new RaisedButton(
                child: new Text("Add GeoQueryListener"),
                onPressed: () async => addGeoQueryEventListenerToQuery(),
              ),
              new RaisedButton(
                child: new Text("New query radius"),
                onPressed: () => query.setRadius(10.0),
              ),
              new RaisedButton(
                child: new Text("Reset radius"),
                onPressed: () => query.setRadius(450.0),
              ),
              new RaisedButton(
                child: new Text("New center"),
                onPressed: () => query.setCenter([40.7128, 74.0059]),
              ),
              new RaisedButton(
                child: new Text("Reset center"),
                onPressed: () => query.setCenter([51.0259, 4.4775]),
              ),
              new RaisedButton(
                child: new Text("Remove listener"),
                onPressed: () => query.removeGeoQueryEventListener(listener).then((bool result) => print("removed listener!")),
              ),
              new Padding(padding: new EdgeInsets.only(bottom: 20.0),),
            ],
          ),
        )
      ),
    );
  }
}
