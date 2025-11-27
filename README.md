# flutter_geo_ar

**Flutter Geo-AR** — plugin ligero y optimizado para superponer POIs y otra información geográfica sobre la cámara del dispositivo usando sensores y DEM. Diseñado para uso en senderismo y rutas (trabaja offline con GPS y COG DEMs).

---

## Descripción

`flutter_geo_ar` ofrece una vista Geo-AR que:
- muestra POIs geo-referenciados sobre la cámara,
- usa fusión de sensores (giroscopio, acelerómetro, magnetómetro/compass),
- calcula proyección 3D→2D con posibilidad de usar DEM (COG) para altitud y horizonte,
- incluye calibración persistente del heading,
- minimiza consumo de batería mediante EventChannel nativo, throttling y uso de isolates,
- proporciona Debug Overlay en tiempo real para monitorización de rendimiento, sensores y filtros,
- soporte multiidioma (español e inglés) para la interfaz del plugin.

El objetivo es proporcionar una solución práctica y eficiente para superponer información geográfica en tiempo real en apps de senderismo, turismo y urbanismo.

## Características

### Internacionalización

El plugin incluye soporte multiidioma para los textos que aparecen en pantalla (interfaz del debug overlay y mensajes del sistema). Idiomas soportados:

- **Español (es)** - Idioma por defecto
- **Inglés (en)**

Para configurar el idioma del plugin, usa el parámetro `language` en el constructor de `GeoArView`:

```dart
GeoArView(
  language: 'en',  // 'es' para español (por defecto), 'en' para inglés
  poisPath: 'assets/data/pois/tenerife_pois.json',
  demPath: 'assets/data/dem/tenerife_cog.tif',
  // ... otros parámetros
)
```

**Nota:** La internacionalización solo afecta a los textos del plugin (debug overlay, tooltips, etc.). Los textos de tu aplicación deben gestionarse por separado.
