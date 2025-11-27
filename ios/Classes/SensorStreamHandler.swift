import Flutter
import CoreLocation
import CoreMotion

/**
 * Stream handler para sensores en iOS con optimizaciones de batería:
 * - Usa xMagneticNorthZVertical para orientación fusionada
 * - GPS con precisión adaptativa según modo de consumo
 * - Throttling unificado para reducir tráfico nativo-Dart
 * - Thread-safe con sincronización
 */
class SensorStreamHandler: NSObject, FlutterStreamHandler {
    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()
    
    private var eventSink: FlutterEventSink?
    private var minInterval: TimeInterval = 0.1  // 100ms por defecto (10Hz)
    private var lowPowerMode: Bool = false
    
    // Buffer unificado para throttling
    private var pendingData: [String: Any] = [:]
    private var lastEmitTime: TimeInterval = 0
    private var throttleTimer: Timer?
    private var isThrottleScheduled: Bool = false
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        // Obtener configuración de throttle y modo bajo consumo
        if let args = arguments as? [String: Any] {
            if let throttleMs = args["throttleMs"] as? Int {
                self.minInterval = Double(throttleMs) / 1000.0
            }
            if let lowPower = args["lowPowerMode"] as? Bool {
                self.lowPowerMode = lowPower
            }
        }
        
        // Iniciar sensores de orientación
        startDeviceMotion()
        
        // Iniciar GPS
        startLocation()
        
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        // Detener sensores
        motionManager.stopDeviceMotionUpdates()
        locationManager.stopUpdatingLocation()
        
        // Limpiar throttling
        throttleTimer?.invalidate()
        throttleTimer = nil
        
        objc_sync_enter(self)
        pendingData.removeAll()
        isThrottleScheduled = false
        objc_sync_exit(self)
        
        eventSink = nil
        
        return nil
    }
    
    private func startDeviceMotion() {
        guard motionManager.isDeviceMotionAvailable else {
            eventSink?(FlutterError(code: "UNAVAILABLE", message: "Device motion no disponible", details: nil))
            return
        }
        
        // Usar referencia magnética norte para obtener heading absoluto
        motionManager.deviceMotionUpdateInterval = lowPowerMode ? 0.2 : 0.1  // 5Hz o 10Hz
        motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] (motion, error) in
            guard let self = self, let motion = motion else { return }
            
            // Obtener ángulos de Euler desde la actitud
            let attitude = motion.attitude
            
            // Convertir a grados y normalizar
            var heading = attitude.yaw * 180.0 / .pi
            if heading < 0 {
                heading += 360.0
            }
            
            let pitch = attitude.pitch * 180.0 / .pi
            let roll = attitude.roll * 180.0 / .pi
            
            // Acumular datos de orientación en el buffer
            let orientationData: [String: Any] = [
                "heading": heading,
                "pitch": pitch,
                "roll": roll,
                "ts": Date().timeIntervalSince1970 * 1000.0
            ]
            
            self.pushToThrottler(data: orientationData)
        }
    }
    
    private func startLocation() {
        // Solicitar permisos si no están concedidos
        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        // Ajustar precisión del GPS según el modo de consumo
        // En modo bajo consumo: kCLLocationAccuracyNearestTenMeters (ahorra batería)
        // En modo normal: kCLLocationAccuracyBest (máxima precisión)
        locationManager.desiredAccuracy = lowPowerMode ? 
            kCLLocationAccuracyNearestTenMeters : 
            kCLLocationAccuracyBest
        
        // Filtro de distancia: solo actualizar si se mueve 5m (optimización GPS)
        locationManager.distanceFilter = 5.0
        
        // Activar actualizaciones continuas en background si es necesario
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = true
        
        locationManager.startUpdatingLocation()
    }
    
    /**
     * Acumula datos en el buffer y programa la emisión según el throttling configurado.
     * Thread-safe usando objc_sync.
     */
    private func pushToThrottler(data: [String: Any]) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        // Fusionar nuevos datos con datos pendientes
        pendingData.merge(data) { (_, new) in new }
        
        let now = Date().timeIntervalSince1970
        let timeSinceLastEmit = now - lastEmitTime
        
        if timeSinceLastEmit >= minInterval {
            // Ha pasado suficiente tiempo, emitir inmediatamente
            emitNow()
        } else if !isThrottleScheduled {
            // Programar emisión para el tiempo restante
            isThrottleScheduled = true
            let remainingTime = minInterval - timeSinceLastEmit
            
            DispatchQueue.main.async { [weak self] in
                self?.throttleTimer = Timer.scheduledTimer(withTimeInterval: remainingTime, repeats: false) { [weak self] _ in
                    self?.emitNow()
                }
            }
        }
    }
    
    /**
     * Emite el paquete unificado de datos acumulados.
     * Debe ser llamado dentro de un bloque sincronizado o desde el timer.
     */
    private func emitNow() {
        objc_sync_enter(self)
        
        isThrottleScheduled = false
        
        guard !pendingData.isEmpty else {
            objc_sync_exit(self)
            return
        }
        
        let dataToEmit = pendingData
        pendingData.removeAll()
        lastEmitTime = Date().timeIntervalSince1970
        
        objc_sync_exit(self)
        
        // Emitir fuera del bloque sincronizado para evitar deadlocks
        eventSink?(dataToEmit)
    }
}

// MARK: - CLLocationManagerDelegate
extension SensorStreamHandler: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Acumular datos de ubicación en el buffer
        let locationData: [String: Any] = [
            "lat": location.coordinate.latitude,
            "lon": location.coordinate.longitude,
            "alt": location.altitude,
            "accuracy": location.horizontalAccuracy,
            "ts": Date().timeIntervalSince1970 * 1000.0
        ]
        
        pushToThrottler(data: locationData)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        eventSink?(FlutterError(code: "LOCATION_ERROR", 
                                message: "Error de ubicación: \(error.localizedDescription)", 
                                details: nil))
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            eventSink?(FlutterError(code: "PERMISSION_DENIED", 
                                    message: "Permisos de ubicación denegados", 
                                    details: nil))
        case .authorizedWhenInUse, .authorizedAlways:
            // Permisos concedidos, continuar
            break
        case .notDetermined:
            // Esperar respuesta del usuario
            break
        @unknown default:
            break
        }
    }
}
