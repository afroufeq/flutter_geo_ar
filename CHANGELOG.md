# Changelog

Todos los cambios importantes de este proyecto serán documentados en este archivo.

## [0.0.2] - 2025-11-27

- Agregado sistema de estabilización visual (ver [documentación](/docs/VISUAL_STABILIZATION.md))
- Debug Overlay para monitorización en tiempo real de métricas de rendimiento, sensores y filtros (ver [documentación](/docs/DEBUG_OVERLAY.md))

## [0.0.1] - 2025-11-27

### 🎉 Release Inicial

Plugin Flutter para Realidad Aumentada Geográfica optimizado para senderismo y rutas offline.

### ✨ Características Principales

#### Sistema de Sensores
- **Fusión de sensores nativos**: Giroscopio, acelerómetro y magnetómetro con EventChannel optimizado
- **Modo bajo consumo**: Ahorro de 30-40% batería con throttling adaptativo (5Hz/10Hz)
- **Calibración persistente**: Sistema de calibración de heading con almacenamiento local
- **Paridad Android/iOS**: Comportamiento unificado en ambas plataformas

#### Visualización AR
- **Widget GeoArView**: Vista AR completa con cámara y overlay de información geográfica
- **Renderizado de POIs**: Proyección 3D→2D de puntos de interés geo-referenciados con iconos
- **Generación de horizonte**: Línea de horizonte dinámica calculada desde DEM
- **Tracking visual**: Corrección visual opcional para mayor precisión en el posicionamiento

#### Datos Geográficos
- **Soporte DEM (COG)**: Carga y procesamiento de modelos digitales de elevación Cloud Optimized GeoTIFF
- **Carga de POIs**: Sistema flexible para cargar puntos de interés desde JSON
- **Proyección cartográfica**: Conversión de coordenadas con proj4dart para precisión global

#### Optimización
- **Arquitectura con isolates**: Offloading de cálculos pesados a threads separados
- **Throttling inteligente**: Control de frecuencia de eventos según modo de consumo
- **Gestión eficiente**: Sistema de sesión con control de ciclo de vida y liberación de recursos

#### Plataformas
- **Android**: Soporte completo con sensor delay adaptativo y permisos optimizados
- **iOS**: Implementación nativa con CoreMotion y CoreLocation, GPS adaptativo

#### Utilidades
- **Telemetría opcional**: Sistema de métricas para monitorización de rendimiento
- **Debug mode**: Overlay de información técnica para desarrollo y testing
- **Internacionalización**: Sistema i18n con slang para múltiples idiomas
- **Ejemplos incluidos**: App de ejemplo completa con datos de las Islas Canarias

---

[0.0.1]: https://github.com/afroufeq/flutter_geo_ar/releases/tag/v0.0.1
