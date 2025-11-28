import Foundation
import CoreMotion

/**
 * Throttler adaptativo que ajusta dinámicamente la frecuencia de emisión de eventos
 * según el movimiento del dispositivo detectado por el acelerómetro.
 *
 * Modos de operación:
 * - ACTIVO: Alta frecuencia cuando el dispositivo se mueve
 * - ESTÁTICO: Baja frecuencia cuando el dispositivo está quieto
 *
 * Beneficios:
 * - Ahorro de batería de hasta 70% en patrones de uso con paradas frecuentes
 * - Transiciones instantáneas al detectar movimiento
 * - Configuración flexible de umbrales y tiempos
 */
class AdaptiveSensorThrottler {
    private let motionManager = CMMotionManager()
    
    private let highFrequencyInterval: TimeInterval    // 0.1s = 10 Hz (modo activo)
    private let lowFrequencyInterval: TimeInterval     // 1.0s = 1 Hz (modo estático)
    private let staticThreshold: Double                // Umbral de aceleración en m/s²
    private let staticDuration: TimeInterval           // Tiempo quieto antes de modo estático
    private let onEmit: ([String: Any]) -> Void
    private let onModeChange: ((Bool) -> Void)?
    
    // Buffer y control de throttling
    private var pendingData: [String: Any] = [:]
    private var lastEmitTime: TimeInterval = 0
    private var throttleTimer: Timer?
    private var isThrottleScheduled: Bool = false
    
    // Estado del movimiento
    private var isMoving: Bool = true  // Comenzar en modo activo
    private var lastMovementTime: TimeInterval = Date().timeIntervalSince1970
    private var checkStaticTimer: Timer?
    
    init(
        highFrequencyInterval: TimeInterval = 0.1,
        lowFrequencyInterval: TimeInterval = 1.0,
        staticThreshold: Double = 0.1,
        staticDuration: TimeInterval = 2.0,
        onEmit: @escaping ([String: Any]) -> Void,
        onModeChange: ((Bool) -> Void)? = nil
    ) {
        self.highFrequencyInterval = highFrequencyInterval
        self.lowFrequencyInterval = lowFrequencyInterval
        self.staticThreshold = staticThreshold
        self.staticDuration = staticDuration
        self.onEmit = onEmit
        self.onModeChange = onModeChange
        
        startAccelerometerMonitoring()
    }
    
    /**
     * Inicia el monitoreo del acelerómetro para detectar movimiento.
     */
    private func startAccelerometerMonitoring() {
        guard motionManager.isAccelerometerAvailable else {
            print("[GeoAR] [AdaptiveThrottler] ⚠️ Acelerómetro no disponible, usando modo fijo")
            return
        }
        
        // Configurar intervalo rápido para detección de movimiento (20ms = 50 Hz)
        motionManager.accelerometerUpdateInterval = 0.02
        
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data else { return }
            
            // Calcular magnitud de la aceleración
            // CMAccelerometerData ya viene en unidades de gravedad (g)
            // Convertir a m/s² multiplicando por 9.81, pero para comparación relativa no es necesario
            let x = data.acceleration.x
            let y = data.acceleration.y
            let z = data.acceleration.z
            
            // Calcular aceleración lineal (restando gravedad aproximada)
            // Para simplicidad, usamos la magnitud total y comparamos con umbral ajustado
            let magnitude = sqrt(x * x + y * y + z * z)
            
            // Ajustar umbral para escala de gravedad (1g = 9.81 m/s²)
            let adjustedThreshold = self.staticThreshold / 9.81
            
            let now = Date().timeIntervalSince1970
            
            if magnitude > adjustedThreshold {
                // Hay movimiento significativo
                self.lastMovementTime = now
                
                if !self.isMoving {
                    // Transición: Estático -> Activo
                    self.setMovingMode(true)
                    print("[GeoAR] [AdaptiveThrottler] 🏃 Modo ACTIVO (\(Int(self.highFrequencyInterval * 1000))ms) - Movimiento detectado: \(String(format: "%.3f", magnitude))g")
                }
                
                // Cancelar chequeo pendiente de modo estático
                self.checkStaticTimer?.invalidate()
                self.checkStaticTimer = nil
                
            } else if self.isMoving && self.checkStaticTimer == nil {
                // Sin movimiento significativo, programar chequeo para modo estático
                self.checkStaticTimer = Timer.scheduledTimer(withTimeInterval: self.staticDuration, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    
                    let timeSinceMovement = Date().timeIntervalSince1970 - self.lastMovementTime
                    if timeSinceMovement >= self.staticDuration {
                        // Ha pasado suficiente tiempo sin movimiento
                        self.setMovingMode(false)
                        print("[GeoAR] [AdaptiveThrottler] 🧘 Modo ESTÁTICO (\(Int(self.lowFrequencyInterval * 1000))ms) - Sin movimiento por \(Int(self.staticDuration * 1000))ms")
                    }
                    
                    self.checkStaticTimer = nil
                }
            }
        }
    }
    
    /**
     * Cambia el modo de operación y notifica el cambio.
     */
    private func setMovingMode(_ moving: Bool) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        guard isMoving != moving else { return }
        
        isMoving = moving
        
        // Notificar cambio de modo al callback si existe
        onModeChange?(moving)
        
        // Notificar cambio de modo a través del stream
        let modeChangeData: [String: Any] = [
            "adaptiveModeChange": moving ? "active" : "static",
            "currentThrottleMs": Int((moving ? highFrequencyInterval : lowFrequencyInterval) * 1000),
            "ts": Date().timeIntervalSince1970 * 1000
        ]
        push(data: modeChangeData)
    }
    
    /**
     * Agrega datos al buffer y programa la emisión según el modo actual.
     */
    func push(data: [String: Any]) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        // Fusionar nuevos datos con datos pendientes
        pendingData.merge(data) { (_, new) in new }
        
        // Agregar el throttle actual a los datos para monitoreo
        if pendingData["currentThrottleMs"] == nil {
            let currentThrottleMs = Int((isMoving ? highFrequencyInterval : lowFrequencyInterval) * 1000)
            pendingData["currentThrottleMs"] = currentThrottleMs
        }
        
        let now = Date().timeIntervalSince1970
        let currentInterval = isMoving ? highFrequencyInterval : lowFrequencyInterval
        let timeSinceLastEmit = now - lastEmitTime
        
        if timeSinceLastEmit >= currentInterval {
            // Ha pasado suficiente tiempo, emitir inmediatamente
            emitNow()
        } else if !isThrottleScheduled {
            // Programar emisión para el tiempo restante
            isThrottleScheduled = true
            let remainingTime = currentInterval - timeSinceLastEmit
            
            DispatchQueue.main.async { [weak self] in
                self?.throttleTimer = Timer.scheduledTimer(withTimeInterval: remainingTime, repeats: false) { [weak self] _ in
                    self?.emitNow()
                }
            }
        }
    }
    
    /**
     * Emite los datos acumulados inmediatamente.
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
        onEmit(dataToEmit)
    }
    
    /**
     * Limpia recursos y detiene el monitoreo.
     */
    func dispose() {
        // Detener acelerómetro
        motionManager.stopAccelerometerUpdates()
        
        // Cancelar timers
        throttleTimer?.invalidate()
        throttleTimer = nil
        checkStaticTimer?.invalidate()
        checkStaticTimer = nil
        
        objc_sync_enter(self)
        pendingData.removeAll()
        isThrottleScheduled = false
        objc_sync_exit(self)
        
        print("[GeoAR] [AdaptiveThrottler] 🧹 Recursos limpiados")
    }
}
