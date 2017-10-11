part of geofire;

class GeoFireEventListener {
    void Function(String key, DatabaseError error) _onComplete;

    GeoFireEventListener(this._onComplete);

    void onComplete(String key, DatabaseError error) {
        _onComplete(key, error);
    } 
}

class LocationCallBack {
    void Function(DatabaseError error) _onCancelled;
    void Function(String key, List<double> location) _onLocationResult;

    LocationCallBack(this._onLocationResult, this._onCancelled);

    void onCancelled(DatabaseError error) {
        _onCancelled(error);
    }

    void onLocationResult(String key, List<double> location) {
        _onLocationResult(key, location);
    }
}

class GeoQueryEventListener {
    void Function(String key, List<double> location) _onKeyEntered;
    void Function(String key) _onKeyExited;
    void Function(String key, List<double> location) _onKeyMoved;
    void Function() _onGeoQueryReady;
    void Function(DatabaseError error) _onGeoQueryError;

    GeoQueryEventListener(this._onKeyEntered, this._onKeyExited, this._onKeyMoved, this._onGeoQueryReady, this._onGeoQueryError);

    void onKeyEntered(String key, List<double> location) {
        _onKeyEntered(key, location);
    }
    void onKeyExited(String key) {
        _onKeyExited(key);
    }
    void onKeyMoved(String key, List<double> location) {
        _onKeyMoved(key, location);
    }
    void onGeoQueryReady() {
        _onGeoQueryReady();
    }
    void onGeoQueryError(DatabaseError error) {
        _onGeoQueryError(error);
    }
}