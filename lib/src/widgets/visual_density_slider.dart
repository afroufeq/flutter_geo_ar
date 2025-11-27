import 'package:flutter/material.dart';
import 'visual_density_controller.dart';
import '../i18n/strings.g.dart';
import '../poi/declutter_mode.dart';

/// Widget UI que proporciona una interfaz visual para ajustar la densidad visual
///
/// Características:
/// - Slider continuo de 0.0 a 1.0
/// - Botones de preset para cambios rápidos
/// - Información detallada opcional de parámetros
/// - Diseño compacto y semitransparente
/// - Expandible/colapsable
class VisualDensitySlider extends StatefulWidget {
  /// Controlador de densidad visual
  final VisualDensityController controller;

  /// Muestra información detallada de los parámetros resultantes
  final bool showDetailedInfo;

  /// Alineación del widget en la pantalla
  final Alignment alignment;

  /// Padding alrededor del widget
  final EdgeInsets padding;

  const VisualDensitySlider({
    super.key,
    required this.controller,
    this.showDetailedInfo = false,
    this.alignment = Alignment.bottomCenter,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  State<VisualDensitySlider> createState() => _VisualDensitySliderState();
}

class _VisualDensitySliderState extends State<VisualDensitySlider> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);

    return Align(
      alignment: widget.alignment,
      child: Padding(
        padding: widget.padding,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con título y botón de expandir/colapsar
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.tune,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.visualDensity.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Contenido expandible
              if (_isExpanded) ...[
                const Divider(color: Colors.white24, height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Descripción
                      Text(
                        t.visualDensity.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Slider con etiquetas
                      ListenableBuilder(
                        listenable: widget.controller,
                        builder: (context, _) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _getPresetLabel(widget.controller.density),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${(widget.controller.density * 100).round()}%',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: _getColorForDensity(widget.controller.density),
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: _getColorForDensity(widget.controller.density),
                                  overlayColor: _getColorForDensity(widget.controller.density).withValues(alpha: 0.2),
                                  trackHeight: 4,
                                ),
                                child: Slider(
                                  value: widget.controller.density,
                                  onChanged: (value) {
                                    widget.controller.setDensity(value);
                                  },
                                  min: 0.0,
                                  max: 1.0,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      // Botones de presets
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _PresetButton(
                            label: t.visualDensity.minimal,
                            preset: VisualDensityPreset.minimal,
                            controller: widget.controller,
                            color: Colors.green,
                          ),
                          _PresetButton(
                            label: t.visualDensity.low,
                            preset: VisualDensityPreset.low,
                            controller: widget.controller,
                            color: Colors.lightGreen,
                          ),
                          _PresetButton(
                            label: t.visualDensity.normal,
                            preset: VisualDensityPreset.normal,
                            controller: widget.controller,
                            color: Colors.orange,
                          ),
                          _PresetButton(
                            label: t.visualDensity.high,
                            preset: VisualDensityPreset.high,
                            controller: widget.controller,
                            color: Colors.deepOrange,
                          ),
                          _PresetButton(
                            label: t.visualDensity.maximum,
                            preset: VisualDensityPreset.maximum,
                            controller: widget.controller,
                            color: Colors.red,
                          ),
                        ],
                      ),

                      // Información detallada
                      if (widget.showDetailedInfo) ...[
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 12),
                        ListenableBuilder(
                          listenable: widget.controller,
                          builder: (context, _) {
                            return Column(
                              children: [
                                _InfoRow(
                                  label: t.visualDensity.settings.maxDistance,
                                  value: '${(widget.controller.maxDistance / 1000).toStringAsFixed(1)} km',
                                ),
                                const SizedBox(height: 4),
                                _InfoRow(
                                  label: t.visualDensity.settings.minImportance,
                                  value: '≥ ${widget.controller.minImportance}',
                                ),
                                const SizedBox(height: 4),
                                _InfoRow(
                                  label: t.visualDensity.settings.declutterMode,
                                  value: _getDeclutterModeLabel(widget.controller.declutterMode),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Obtiene la etiqueta del preset según el valor de densidad
  String _getPresetLabel(double density) {
    final t = Translations.of(context);
    if (density < 0.125) {
      return t.visualDensity.minimal;
    } else if (density < 0.375) {
      return t.visualDensity.low;
    } else if (density < 0.625) {
      return t.visualDensity.normal;
    } else if (density < 0.875) {
      return t.visualDensity.high;
    } else {
      return t.visualDensity.maximum;
    }
  }

  /// Obtiene el color según el valor de densidad
  Color _getColorForDensity(double density) {
    if (density < 0.25) {
      return Colors.green;
    } else if (density < 0.5) {
      return Colors.lightGreen;
    } else if (density < 0.75) {
      return Colors.orange;
    } else if (density < 0.9) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }

  /// Obtiene la etiqueta del modo de declutter
  String _getDeclutterModeLabel(DeclutterMode mode) {
    switch (mode) {
      case DeclutterMode.off:
        return 'Off';
      case DeclutterMode.light:
        return 'Light';
      case DeclutterMode.normal:
        return 'Normal';
      case DeclutterMode.aggressive:
        return 'Aggressive';
    }
  }
}

/// Widget de botón de preset
class _PresetButton extends StatelessWidget {
  final String label;
  final VisualDensityPreset preset;
  final VisualDensityController controller;
  final Color color;

  const _PresetButton({
    required this.label,
    required this.preset,
    required this.controller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final presetValue = VisualDensityController.getPresetValue(preset);
        final isActive = (controller.density - presetValue).abs() < 0.01;

        return Material(
          color: isActive ? color.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => controller.setPreset(preset),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget de fila de información
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
