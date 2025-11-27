import Flutter
import UIKit

public class FlutterGeoArPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_geo_ar", binaryMessenger: registrar.messenger())
    let instance = FlutterGeoArPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    
    // Registrar EventChannel para sensores con optimizaciones
    let sensorEventChannel = FlutterEventChannel(name: "flutter_geo_ar/sensors", binaryMessenger: registrar.messenger())
    let sensorStreamHandler = SensorStreamHandler()
    sensorEventChannel.setStreamHandler(sensorStreamHandler)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
