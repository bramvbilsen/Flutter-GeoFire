// GeoFire wrapper for Flutter SDK.
// Author: Bram Vanbilsen

library geofire;

import 'dart:async';
import 'dart:collection'; 

import 'package:flutter/services.dart';

import 'UUID.dart';

part 'eventlistener.dart';
part 'error.dart';

/// A class that allows for storing and receiving geo location data from a Firebase Database.
/// 
/// Every Geofire instance needs a path to the desired location in the database.
class GeoFire {
    static const MethodChannel _channel = const MethodChannel('com.bram.vanbilsen.geofire.GeoFire');
    MethodChannel _setLocationListenerChannel;
    MethodChannel _removeLocationListenerChannel;
    MethodChannel _getLocationListenerChannel;

    final String _uuid = generateUUID();

    String _path;

    List<GeoQuery> _queries = new List<GeoQuery>();

    /// Creates new `GeoFire` instance
    GeoFire(String path) {
        this._path = path;
    }

     /// Returns the path in which the instance of the GeoFire class is working.
    String getPath() {
        return this._path;
    }

    /// Associates the key with the provided location in the database.
    /// 
    /// The location argument should be a `List<double>` with two values. The first one being the latitude and the second one being the longitude.
    /// An optional `GeoFireEventListener` can be provided.
    /// Throws an `ArgumentError` if the location argument is not in the correct format.
    void setLocation(String key, List<double> geoLocation, [GeoFireEventListener listener]) {
        if (geoLocation.length != 2) {
            throw new ArgumentError("setLocation expects a list of 2 doubles [latitude, longitude] for the second argurment (geoLocation). " + geoLocation.length.toString() + " were given!");
        }

        String uuid = generateUUID();

        _channel.invokeMethod(
            "newSetLocationChannel",
            <String, String>{
                "name": _channel.name + ".setLocationListener." + uuid
            }
        ).then((String result) {
            _setLocationListenerChannel = new MethodChannel(_channel.name + ".setLocationListener." + uuid);
            _setLocationListenerChannel.setMethodCallHandler((MethodCall call) {
                if (call.method == "setLocationSuccess") {
                    if (listener != null) {
                        listener._onComplete((call.arguments["result"]), null);
                    } else {
                        print("Location set successfully!");
                    }
                } else if (call.method == "setLocationError") {
                    Map<String, String> args = call.arguments["result"];
                    DatabaseError error = new DatabaseError(int.parse(args["code"]), args["details"], args["message"]);
                    if (listener != null) {
                        listener._onComplete(args["key"], error);
                    } else {
                        print("Error setting location!");
                        print(error.toString());
                    }
                }
            });
            _setLocationListenerChannel.invokeMethod(
                "setLocation",
                <String, dynamic>{
                    "refPath": getPath(),
                    "geoLocation": geoLocation,
                    "key": key
                }
            );
        });
    }

    /// Removes location from database with provided key.
    /// 
    /// An optional `GeoFireEventListener` can be provided.
    void removeLocation(String key, [GeoFireEventListener listener]) {

        String uuid = generateUUID();

        _channel.invokeMethod(
            "newRemoveLocationChannel",
            <String, String>{
                "name": _channel.name + ".removeLocationListener." + uuid
            }
        ).then((String result) {
            _removeLocationListenerChannel = new MethodChannel(_channel.name + ".removeLocationListener." + uuid);
            _removeLocationListenerChannel.setMethodCallHandler((MethodCall call) {
                if (call.method == "removeLocationSuccess") {
                    if (listener != null) {
                        listener._onComplete((call.arguments["result"]), null);
                    } else {
                        print("Location removed successfully!");
                    }
                } else if (call.method == "removeLocationError") {
                    Map<String, String> args = call.arguments["result"];
                    DatabaseError error = new DatabaseError(int.parse(args["code"]), args["details"], args["message"]);
                    if (listener != null) {
                        listener._onComplete(args["key"], error);
                    } else {
                        print("Error removing location!");
                        print(error.toString());
                    }
                }
            });

            _removeLocationListenerChannel.invokeMethod(
                "removeLocation",
                <String, dynamic>{
                    "refPath": getPath(),
                    "key": key
                }
            );
        });
    }

    /// Gets the location from the database with the provided key.
    /// 
    /// A `LocationCallBack` is required to listen for completion of the function.
    void getLocation(String key, LocationCallBack callback) {

        String uuid = generateUUID();

        _channel.invokeMethod(
            "newGetLocationChannel",
            <String, String>{
                "name": _channel.name + ".getLocationListener." + uuid
            }
        ).then((String result) {
            _getLocationListenerChannel = new MethodChannel(_channel.name + ".getLocationListener." + uuid);
            _getLocationListenerChannel.setMethodCallHandler((MethodCall call) {
                if (call.method == "getLocationSuccess") {
                    Map<String, List<double>> args = call.arguments["result"];
                    args.forEach((String key, List<double> location) => callback._onLocationResult(key, location));
                } else if (call.method == "getLocationError") {
                    Map<String, String> args = call.arguments["result"];
                    DatabaseError error = new DatabaseError(int.parse(args["code"]), args["details"], args["message"]);
                    callback._onCancelled(error);
                }
            });
            _getLocationListenerChannel.invokeMethod(
                "getLocation",
                <String, dynamic>{
                    "refPath": getPath(),
                    "key": key
                }
            );
        });
    }

    /// Crates a new `GeoQuery` with the provided information.
    /// 
    /// Throws an `ArgumentError` if the location argument is not in the correct format.
    GeoQuery queryAtLocation(List<double> center, double radius) {
        if (center.length != 2) {
            throw new ArgumentError("queryAtLocation expects a list of 2 doubles [latitude, longitude] for the first argurment (center). " + center.length.toString() + " were given!");
        }
        GeoQuery query = new GeoQuery(center, radius, this);
        _queries.add(query);
        return query;
    }

}

/// A class that allows for performing location queries on a Firebase database.
/// 
/// This class needs a `GeoFire` reference to get the database path from.
class GeoQuery {
    static const MethodChannel _channel = const MethodChannel('com.bram.vanbilsen.geofire.GeoFire');

    GeoFire _geofire;
    double _radius;
    List<double> _center;

    HashMap<GeoQueryEventListener, MethodChannel> _listenerChannels = new HashMap<GeoQueryEventListener, MethodChannel>();

    /// Creates new `GeoQuery` instance.
    /// 
    /// The center argument should be a `List<double>` with two values. The first one being the latitude and the second one being the longitude.
    /// Throws an `ArgumentError` if the center argument is not in the correct format.
    GeoQuery(List<double> center, double radius, GeoFire geofire) {
        if (geofire == null)
            throw new ArgumentError("The provided geofire instance is null!");
        if (center.length != 2)
            throw new ArgumentError("setLocation expects a list of 2 doubles [latitude, longitude] for the second argurment (geoLocation). " + center.length.toString() + " were given!");
        this._geofire = geofire;
        setRadius(radius);
        setCenter(center);
    }

    /// Sets the radius for this query and retriggers events if necessary.
    void setRadius(double radius) {
        this._radius = radius;
        for (MethodChannel channel in _listenerChannels.values) {
            channel.invokeMethod(
                "setRadius",
                <String, dynamic> {
                    // Radius of search area.
                    "radius": this._radius,
                    // Channel name.
                    "name": channel.name
                }
            );
        }
    }

    /// Sets the center for this query and retriggers events if necessary.
    void setCenter(List<double> center) {
        this._center = center;
        for (MethodChannel channel in _listenerChannels.values) {
            channel.invokeMethod(
                "setCenter",
                <String, dynamic> {
                    // Radius of search area.
                    "center": this._center,
                    // Channel name.
                    "name": channel.name
                }
            );
        }
    }

    /// Returns the radius of this query.
    double getRadius() {
        return this._radius;
    }

    /// Returns the center of this query.
    List<double> getCenter() {
        return this._center;
    }

    void _setMethodCallHandlerListener(GeoQueryEventListener listener, MethodChannel channel) {
        channel.setMethodCallHandler((MethodCall call) {
            print("LISTENER CALL:" + call.method);
            switch(call.method) {
                case "geoQueryEventKeyEntered":
                    Map<String, List<double>> args = call.arguments["result"];
                    args.forEach((String key, List<double> location) => listener.onKeyEntered(key, location));
                    break;
                case "geoQueryEventKeyExited":
                    listener.onKeyExited(call.arguments["result"]);
                    break;
                case "geoQueryEventKeyMoved":
                    Map<String, List<double>> args = call.arguments["result"];
                    args.forEach((String key, List<double> location) => listener.onKeyMoved(key, location));
                    break;
                case "geoQueryEventReady":
                    listener.onGeoQueryReady();
                    break;
                case "geoQueryEventError":
                    Map<String, String> args = call.arguments["result"];
                    DatabaseError error = new DatabaseError(int.parse(args["code"]), args["details"], args["message"]);
                    listener._onGeoQueryError(error);
                    break;
                default: throw new MissingPluginException("The method you tried invoking is not implemented!");
            }
        });
    }

    /// Adds new `GeoQueryEventListener` to this query.
    /// 
    /// Throws `ArgumentError` if you are attempting to add the same listener twice.
    void addGeoQueryEventListener(GeoQueryEventListener listener) {
        if (_listenerChannels.containsKey(listener)) {
            throw new ArgumentError("Can't add the same listener twice!");
        }

        String uuid = generateUUID();
        String channelName = _channel.name + ".geoQueryListener." + uuid;
        MethodChannel listenerChannel = new MethodChannel(channelName);

        _listenerChannels[listener] = listenerChannel;

        _channel.invokeMethod(
            "newGeoQueryChannel",
            <String, String> {
                "name": channelName
            }
        ).then((String result) {
            _setMethodCallHandlerListener(listener, listenerChannel);

            listenerChannel.invokeMethod(
                "addGeoQueryEventListener",
                <String, dynamic> {
                    "refPath": this._geofire.getPath(),
                    "center": this._center,
                    "radius": this._radius,
                    "name": channelName
                }
            );
        });
    }

    Future<bool> _removeListener(MethodChannel channel) {
        return channel.invokeMethod(
            "removeGeoQueryEventListener",
            <String, String> {
                "name": channel.name
            }
        );
    }

    /// Removes provided listener from this query.
    /// 
    /// Future will cary true if the listener got removed correctly.
    Future<bool> removeGeoQueryEventListener(GeoQueryEventListener listener) {
        MethodChannel channel = _listenerChannels[listener];
        return _removeListener(channel);
    }

    @override
    String toString() {
        return "GeoQuery\n--- Center: " +  _center.toString() + "\n--- Radius: " + _radius.toString();
    }

}
