# flutter_geo_ar

**Flutter Geo-AR** — plugin ligero y optimizado para superponer POIs y otra información geográfica sobre la cámara del dispositivo usando sensores y DEM. Diseñado para uso en senderismo y rutas (trabaja offline con GPS y COG DEMs).

---

## Descripción

`flutter_geo_ar` ofrece una vista Geo-AR que:
- muestra POIs geo-referenciados sobre la cámara,
- usa fusión de sensores (giroscopio, acelerómetro, magnetómetro/compass),
- calcula proyección 3D→2D con posibilidad de usar DEM (COG) para altitud y horizonte,
- incluye calibración persistente del heading,
- minimiza consumo de batería mediante EventChannel nativo, throttling y uso de isolates.

El objetivo es proporcionar una solución práctica y eficiente para superponer información geográfica en tiempo real en apps de senderismo, turismo y urbanismo.