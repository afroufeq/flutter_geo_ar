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
    
    // Guardar última precisión de heading para incluirla en todos los eventos
    private var lastHeadingAccuracy: Double?
    
    // Throttlers
    private var adaptiveThrottler: AdaptiveSensorThrottler?
    
    // Buffer unificado para throttling (cuando no se usa adaptiveThrottler)
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
        var adaptiveThrottling = false
        var lowFrequencyInterval: TimeInterval = 1.0
        var staticThreshold: Double = 0.1
        var staticDuration: TimeInterval = 2.0
        
        if let args = arguments as? [String: Any] {
            if let throttleMs = args["throttleMs"] as? Int {
                self.minInterval = Double(throttleMs) / 1000.0
            }
            if let lowPower = args["lowPowerMode"] as? Bool {
                self.lowPowerMode = lowPower
            }
            if let adaptive = args["adaptiveThrottling"] as? Bool {
                adaptiveThrottling = adaptive
            }
            if let lowFreqMs = args["lowFrequencyMs"] as? Int {
                lowFrequencyInterval = Double(lowFreqMs) / 1000.0
            }
            if let threshold = args["staticThreshold"] as? Double {
                staticThreshold = threshold
            }
            if let duration = args["staticDurationMs"] as? Int {
                staticDuration = Double(duration) / 1000.0
            }
        }
        
        // Inicializar throttler según la configuración
        if adaptiveThrottling {
            print("[GeoAR] 🎯 Usando throttler ADAPTATIVO (\(Int(minInterval * 1000))ms -> \(Int(lowFrequencyInterval * 1000))ms)")
            adaptiveThrottler = AdaptiveSensorThrottler(
                highFrequencyInterval: minInterval,
                lowFrequencyInterval: lowFrequencyInterval,
                staticThreshold: staticThreshold,
                staticDuration: staticDuration,
                onEmit: { [weak self] data in
                    self?.eventSink?(data)
                },
                onModeChange: { isMoving in
                    print("[GeoAR] 📊 Cambio de modo: \(isMoving ? "ACTIVO" : "ESTÁTICO")")
                }
            )
        } else {
            print("[GeoAR] ⏱️ Usando throttler FIJO (\(Int(minInterval * 1000))ms)")
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
        locationManager.stopUpdatingHeading()
        
        // Limpiar throttling
        throttleTimer?.invalidate()
        throttleTimer = nil
        
        // Limpiar throttler adaptativo
        adaptiveThrottler?.dispose()
        adaptiveThrottler = nil
        
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
            
            // Acumular datos de orientación en el buffer, incluyendo precisión de heading si está disponible
            var orientationData: [String: Any] = [
                "heading": heading,
                "pitch": pitch,
                "roll": roll,
                "ts": Date().timeIntervalSince1970 * 1000.0
            ]
            
            // Incluir headingAccuracy si ya se ha recibido
            if let headingAccuracy = self.lastHeadingAccuracy {
                orientationData["headingAccuracy"] = headingAccuracy
            }
            
            // Usar el throttler correspondiente
            if let adaptive = self.adaptiveThrottler {
                adaptive.push(data: orientationData)
            } else {
                self.pushToThrottler(data: orientationData)
            }
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
        
        // Iniciar actualizaciones de heading para obtener precisión de la brújula
        locationManager.startUpdatingHeading()
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
        
        // Usar el throttler correspondiente
        if let adaptive = adaptiveThrottler {
            adaptive.push(data: locationData)
        } else {
            pushToThrottler(data: locationData)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Guardar la precisión del heading (brújula) para incluirla en todos los eventos de orientación
        // headingAccuracy en grados: negativo = inválido, < 10 = alta, 10-30 = media, 30-90 = baja, > 90 = no fiable
        lastHeadingAccuracy = newHeading.headingAccuracy
        
        print("[GeoAR] 🧭 Precisión de heading actualizada: \(newHeading.headingAccuracy)° (< 0 = inválido, < 10 = alta, 10-30 = media, 30-90 = baja, > 90 = no fiable)")
        
        // Enviar actualización inmediata con la nueva precisión
        let headingAccuracyData: [String: Any] = [
            "headingAccuracy": newHeading.headingAccuracy,
            "ts": Date().timeIntervalSince1970 * 1000.0
        ]
        
        // Usar el throttler correspondiente
        if let adaptive = adaptiveThrottler {
            adaptive.push(data: headingAccuracyData)
        } else {
            pushToThrottler(data: headingAccuracyData)
        }
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
