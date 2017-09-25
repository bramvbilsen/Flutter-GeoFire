part of geofire;

class DatabaseError {
    final int _code;
    final String _details;
    final String _message;

    DatabaseError(this._code, this._details, this._message);

    int getCode() {
        return _code;
    }

    String getDetails() {
        return _details;
    }

    String getMessage() {
        return _message;
    }

    @override
    String toString() {
        return "Database error (GeoFire)\n" + "Error code: " + _code.toString() + "\nDetails: " + _details + "\nMessage: " + _message;
    }
}