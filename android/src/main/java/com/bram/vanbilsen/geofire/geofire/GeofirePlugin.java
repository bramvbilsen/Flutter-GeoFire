package com.bram.vanbilsen.geofire.geofire;

import android.app.Activity;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import com.firebase.geofire.GeoLocation;
import com.firebase.geofire.GeoQuery;
import com.firebase.geofire.GeoQueryEventListener;
import com.firebase.geofire.LocationCallback;
import com.google.firebase.FirebaseException;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.firebase.geofire.GeoFire;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;

/**
 * GeofirePlugin
 */
public class GeofirePlugin implements MethodCallHandler {
  /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "com.bram.vanbilsen.geofire.GeoFire");
		final MethodChannel queryListenerChannel = new MethodChannel(registrar.messenger(), "com.bram.vanbilsen.geofire.GeoQuery");
    final GeofirePlugin instance = new GeofirePlugin(registrar.activity(), registrar, channel, queryListenerChannel);
	  channel.setMethodCallHandler(instance);
  }

  GeofirePlugin(Activity activity, Registrar registrar, MethodChannel channel, MethodChannel queryChannel) {
    this.activity = activity;
		this.channel = channel;
		this.queryListenerChannel = queryChannel;
		this.queryListenerChannels = new HashMap<>();
		this.geoQueries = new HashMap<>();
		this.registrar = registrar;
		this.setLocationListenerChannels = new HashSet<>();
		this.removeLocationListenerChannels = new HashSet<>();
		this.getLocationListenerChannels = new HashSet<>();
  }

  private final MethodChannel channel;
	private final MethodChannel queryListenerChannel;
	private final HashMap<String, GeoQueryEventListener> queryListenerChannels;
	private final HashMap<String, GeoQuery> geoQueries;
	private final HashSet<MethodChannel> setLocationListenerChannels;
	private final HashSet<MethodChannel> removeLocationListenerChannels;
	private final HashSet<MethodChannel> getLocationListenerChannels;
	private final Registrar registrar;
  private final Activity activity;

  @Override
  public void onMethodCall(MethodCall call, final Result result) {

		if (call.method.equals("newSetLocationChannel")) {
			String name = call.argument("name");
			final MethodChannel setLocationListenerChannel = new MethodChannel(this.registrar.messenger(), name);
			setLocationListenerChannels.add(setLocationListenerChannel);
			setLocationListenerChannel.setMethodCallHandler(new MethodCallHandler() {
				@Override
				public void onMethodCall(MethodCall call, Result result) {
					if (call.method.equals("setLocation")) {
						String refPath = call.argument("refPath");
						DatabaseReference ref = FirebaseDatabase.getInstance().getReference();
						ref = ref.child(refPath);
						GeoFire geofire = new GeoFire(ref);
						List<Double> geoLocation = call.argument("geoLocation");
						String key = call.argument("key");
						geofire.setLocation(key, new GeoLocation(geoLocation.get(0), geoLocation.get(1)), new GeoFire.CompletionListener() {
							@Override
							public void onComplete(String key, DatabaseError error) {
								if (error != null) {
									HashMap<String, HashMap> arguments = new HashMap<>();
									HashMap<String, String> databaseError = new HashMap<>();
									databaseError.put("code", Integer.toString(error.getCode()));
									databaseError.put("details", error.getMessage());
									databaseError.put("message", error.getMessage());
									databaseError.put("key", key);
									arguments.put("result", databaseError);
									setLocationListenerChannel.invokeMethod("setLocationError", arguments);
									setLocationListenerChannels.remove(setLocationListenerChannel);
								} else {
									HashMap<String, String> arguments = new HashMap<>();
									arguments.put("result", key);
									setLocationListenerChannel.invokeMethod("setLocationSuccess", arguments);
									setLocationListenerChannels.remove(setLocationListenerChannel);
								}
							}
						});
					}
				}
			});
			result.success("success");
		} else if(call.method.equals("newRemoveLocationChannel")) {
			String name = call.argument("name");
			final MethodChannel removeLocationListenerChannel = new MethodChannel(this.registrar.messenger(), name);
			removeLocationListenerChannels.add(removeLocationListenerChannel);
			removeLocationListenerChannel.setMethodCallHandler(new MethodCallHandler() {
				@Override
				public void onMethodCall(MethodCall call, Result result) {
					if (call.method.equals("removeLocation")) {
						String refPath = call.argument("refPath");
						DatabaseReference ref = FirebaseDatabase.getInstance().getReference();
						ref = ref.child(refPath);
						GeoFire geofire = new GeoFire(ref);
						String key = call.argument("key");
						geofire.removeLocation(key, new GeoFire.CompletionListener() {
							@Override
							public void onComplete(String key, DatabaseError error) {
								if (error != null) {
									HashMap<String, HashMap> arguments = new HashMap<>();
									HashMap<String, String> databaseError = new HashMap<>();
									databaseError.put("code", Integer.toString(error.getCode()));
									databaseError.put("details", error.getMessage());
									databaseError.put("message", error.getMessage());
									databaseError.put("key", key);
									arguments.put("result", databaseError);
									removeLocationListenerChannel.invokeMethod("removeLocationError", arguments);
									removeLocationListenerChannels.remove(removeLocationListenerChannel);
								} else {
									HashMap<String, String> arguments = new HashMap<>();
									arguments.put("result", key);
									removeLocationListenerChannel.invokeMethod("removeLocationSuccess", arguments);
									removeLocationListenerChannels.remove(removeLocationListenerChannel);
								}
							}
						});
					}
				}
			});
			result.success("success");
		} else if (call.method.equals("newGetLocationChannel")) {
			String name = call.argument("name");
			final MethodChannel getLocationListenerChannel = new MethodChannel(this.registrar.messenger(), name);
			getLocationListenerChannels.add(getLocationListenerChannel);
			getLocationListenerChannel.setMethodCallHandler(new MethodCallHandler() {
				@Override
				public void onMethodCall(MethodCall call, Result result) {
					if (call.method.equals("getLocation")) {
						String refPath = call.argument("refPath");
						DatabaseReference ref = FirebaseDatabase.getInstance().getReference();
						ref = ref.child(refPath);
						GeoFire geofire = new GeoFire(ref);
						String key = call.argument("key");
						geofire.getLocation(key, new LocationCallback() {
							@Override
							public void onLocationResult(String key, GeoLocation location) {
								if (location == null) { // This most likely means that the key that you are trying to access does not exist!
									HashMap<String, HashMap<String, ArrayList<Double>>> arguments = new HashMap<>();
									HashMap<String, ArrayList<Double>> result = new HashMap<>();
									result.put(key, null);
									arguments.put("result", result);
									getLocationListenerChannel.invokeMethod("getLocationSuccess", arguments);
									getLocationListenerChannels.remove(getLocationListenerChannel);
								} else {
									HashMap<String, HashMap<String, ArrayList<Double>>> arguments = new HashMap<>();
									HashMap<String, ArrayList<Double>> result = new HashMap<>();
									ArrayList<Double> geoLocation = convertGeoLocation(location);
									result.put(key, geoLocation);
									arguments.put("result", result);
									getLocationListenerChannel.invokeMethod("getLocationSuccess", arguments);
									getLocationListenerChannels.remove(getLocationListenerChannel);
								}
							}

							@Override
							public void onCancelled(DatabaseError error) {
								HashMap<String, HashMap> arguments = new HashMap<>();
								HashMap<String, String> databaseError = new HashMap<>();
								databaseError.put("code", Integer.toString(error.getCode()));
								databaseError.put("details", error.getMessage());
								databaseError.put("message", error.getMessage());
								arguments.put("result", databaseError);
								getLocationListenerChannel.invokeMethod("getLocationError", arguments);
								getLocationListenerChannels.remove(getLocationListenerChannel);
							}
						});
					}
				}
			});
			result.success("success");

		} else if (call.method.equals("newGeoQueryChannel")) {
			String name = call.argument("name");
			final MethodChannel geoQueryListenerChannel = new MethodChannel(this.registrar.messenger(), name);
			GeoQueryEventListener listener = new GeoQueryEventListener() {
				@Override
				public void onKeyEntered(String key, GeoLocation location) {
					HashMap<String, HashMap<String, ArrayList<Double>>> arguments = new HashMap<>();
					HashMap<String, ArrayList<Double>> result = new HashMap<>();
					ArrayList<Double> geoLocation = convertGeoLocation(location);
					result.put(key, geoLocation);
					arguments.put("result", result);
					geoQueryListenerChannel.invokeMethod("geoQueryEventKeyEntered", arguments);
				}

				@Override
				public void onKeyExited(String key) {
					HashMap<String, String> arguments = new HashMap<>();
					arguments.put("result", key);
					geoQueryListenerChannel.invokeMethod("geoQueryEventKeyExited", arguments);
				}

				@Override
				public void onKeyMoved(String key, GeoLocation location) {
					HashMap<String, HashMap<String, ArrayList<Double>>> arguments = new HashMap<>();
					HashMap<String, ArrayList<Double>> result = new HashMap<>();
					ArrayList<Double> geoLocation = convertGeoLocation(location);
					result.put(key, geoLocation);
					arguments.put("result", result);
					geoQueryListenerChannel.invokeMethod("geoQueryEventKeyMoved", arguments);
				}

				@Override
				public void onGeoQueryReady() {
					HashMap<String, String> arguments = new HashMap<>();
					arguments.put("result", "success");
					geoQueryListenerChannel.invokeMethod("geoQueryEventReady", arguments);
				}

				@Override
				public void onGeoQueryError(DatabaseError error) {
					HashMap<String, HashMap> arguments = new HashMap<>();
					HashMap<String, String> databaseError = new HashMap<>();
					databaseError.put("code", Integer.toString(error.getCode()));
					databaseError.put("details", error.getMessage());
					databaseError.put("message", error.getMessage());
					arguments.put("result", databaseError);
					geoQueryListenerChannel.invokeMethod("geoQueryEventError", arguments);
				}
			};
			queryListenerChannels.put(name, listener);
			geoQueryListenerChannel.setMethodCallHandler(new MethodCallHandler() {
				@Override
				public void onMethodCall(MethodCall call, Result result) {
					if (call.method.equals("addGeoQueryEventListener")) {
						String refPath = call.argument("refPath");
						DatabaseReference ref = FirebaseDatabase.getInstance().getReference();
						ref = ref.child(refPath);
						final GeoFire geofire = new GeoFire(ref);
						List<Double> center = call.argument("center");
						double radius = call.argument("radius");
						String name = call.argument("name");
						GeoQuery query = geofire.queryAtLocation(new GeoLocation(center.get(0), center.get(1)), radius);
						geoQueries.put(name, query);
						query.addGeoQueryEventListener(queryListenerChannels.get(name));
					} else if (call.method.equals("setRadius")) {
						double radius = call.argument("radius");
						String name = call.argument("name");
						GeoQuery query = geoQueries.get(name);
						query.setRadius(radius);
					} else if (call.method.equals("setCenter")) {
						List<Double> center = call.argument("center");
						String name = call.argument("name");
						GeoQuery query = geoQueries.get(name);
						query.setCenter(new GeoLocation(center.get(0), center.get(1)));
					} else if(call.method.equals("removeGeoQueryEventListener")) {
						String name = call.argument("name");
						GeoQuery query = geoQueries.get(name);
						GeoQueryEventListener listener = queryListenerChannels.get(name);
						query.removeGeoQueryEventListener(listener);
						queryListenerChannels.remove(name);
						geoQueries.remove(name);
						result.success(true);
					}
				}
			});
			result.success("success");
		} else {
			System.out.println("Not implemented in Android side of things");
			result.notImplemented();
    }
  }

  private ArrayList<Double> convertGeoLocation(GeoLocation location) {
		ArrayList<Double> geoLocation = new ArrayList<>();
		geoLocation.add(location.latitude);
		geoLocation.add(location.longitude);
		return geoLocation;
	}
}
