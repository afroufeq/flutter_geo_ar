/// Generated file. Do not edit.
///
/// Original: assets/translations
/// To regenerate, run: `dart run slang`
///
/// Locales: 2
/// Strings: 82 (41 per locale)
///
/// Built on 2025-11-27 at 14:41 UTC

// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:flutter/widgets.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang_flutter/slang_flutter.dart';
export 'package:slang_flutter/slang_flutter.dart';

const AppLocale _baseLocale = AppLocale.es;

/// Supported locales, see extension methods below.
///
/// Usage:
/// - LocaleSettings.setLocale(AppLocale.es) // set locale
/// - Locale locale = AppLocale.es.flutterLocale // get flutter locale from enum
/// - if (LocaleSettings.currentLocale == AppLocale.es) // locale check
enum AppLocale with BaseAppLocale<AppLocale, Translations> {
	es(languageCode: 'es', build: Translations.build),
	en(languageCode: 'en', build: StringsEn.build);

	const AppLocale({required this.languageCode, this.scriptCode, this.countryCode, required this.build}); // ignore: unused_element

	@override final String languageCode;
	@override final String? scriptCode;
	@override final String? countryCode;
	@override final TranslationBuilder<AppLocale, Translations> build;

	/// Gets current instance managed by [LocaleSettings].
	Translations get translations => LocaleSettings.instance.translationMap[this]!;
}

/// Method A: Simple
///
/// No rebuild after locale change.
/// Translation happens during initialization of the widget (call of t).
/// Configurable via 'translate_var'.
///
/// Usage:
/// String a = t.someKey.anotherKey;
/// String b = t['someKey.anotherKey']; // Only for edge cases!
Translations get t => LocaleSettings.instance.currentTranslations;

/// Method B: Advanced
///
/// All widgets using this method will trigger a rebuild when locale changes.
/// Use this if you have e.g. a settings page where the user can select the locale during runtime.
///
/// Step 1:
/// wrap your App with
/// TranslationProvider(
/// 	child: MyApp()
/// );
///
/// Step 2:
/// final t = Translations.of(context); // Get t variable.
/// String a = t.someKey.anotherKey; // Use t variable.
/// String b = t['someKey.anotherKey']; // Only for edge cases!
class TranslationProvider extends BaseTranslationProvider<AppLocale, Translations> {
	TranslationProvider({required super.child}) : super(settings: LocaleSettings.instance);

	static InheritedLocaleData<AppLocale, Translations> of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context);
}

/// Method B shorthand via [BuildContext] extension method.
/// Configurable via 'translate_var'.
///
/// Usage (e.g. in a widget's build method):
/// context.t.someKey.anotherKey
extension BuildContextTranslationsExtension on BuildContext {
	Translations get t => TranslationProvider.of(this).translations;
}

/// Manages all translation instances and the current locale
class LocaleSettings extends BaseFlutterLocaleSettings<AppLocale, Translations> {
	LocaleSettings._() : super(utils: AppLocaleUtils.instance);

	static final instance = LocaleSettings._();

	// static aliases (checkout base methods for documentation)
	static AppLocale get currentLocale => instance.currentLocale;
	static Stream<AppLocale> getLocaleStream() => instance.getLocaleStream();
	static AppLocale setLocale(AppLocale locale, {bool? listenToDeviceLocale = false}) => instance.setLocale(locale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale setLocaleRaw(String rawLocale, {bool? listenToDeviceLocale = false}) => instance.setLocaleRaw(rawLocale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale useDeviceLocale() => instance.useDeviceLocale();
	@Deprecated('Use [AppLocaleUtils.supportedLocales]') static List<Locale> get supportedLocales => instance.supportedLocales;
	@Deprecated('Use [AppLocaleUtils.supportedLocalesRaw]') static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
	static void setPluralResolver({String? language, AppLocale? locale, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) => instance.setPluralResolver(
		language: language,
		locale: locale,
		cardinalResolver: cardinalResolver,
		ordinalResolver: ordinalResolver,
	);
}

/// Provides utility functions without any side effects.
class AppLocaleUtils extends BaseAppLocaleUtils<AppLocale, Translations> {
	AppLocaleUtils._() : super(baseLocale: _baseLocale, locales: AppLocale.values);

	static final instance = AppLocaleUtils._();

	// static aliases (checkout base methods for documentation)
	static AppLocale parse(String rawLocale) => instance.parse(rawLocale);
	static AppLocale parseLocaleParts({required String languageCode, String? scriptCode, String? countryCode}) => instance.parseLocaleParts(languageCode: languageCode, scriptCode: scriptCode, countryCode: countryCode);
	static AppLocale findDeviceLocale() => instance.findDeviceLocale();
	static List<Locale> get supportedLocales => instance.supportedLocales;
	static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
}

// translations

// Path: <root>
typedef StringsEs = Translations; // ignore: unused_element
class Translations implements BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.es,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <es>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	// Translations
	late final StringsDebugEs debug = StringsDebugEs._(_root);
	late final StringsVisualDensityEs visualDensity = StringsVisualDensityEs._(_root);
	late final StringsSensorAccuracyEs sensorAccuracy = StringsSensorAccuracyEs._(_root);
}

// Path: debug
class StringsDebugEs {
	StringsDebugEs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final StringsDebugSectionsEs sections = StringsDebugSectionsEs._(_root);
	late final StringsDebugMetricsEs metrics = StringsDebugMetricsEs._(_root);
	late final StringsDebugModeEs mode = StringsDebugModeEs._(_root);
	late final StringsDebugActionsEs actions = StringsDebugActionsEs._(_root);
}

// Path: visualDensity
class StringsVisualDensityEs {
	StringsVisualDensityEs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Densidad Visual';
	String get description => 'Ajusta la cantidad de información visible en pantalla';
	String get minimal => 'Mínima';
	String get low => 'Baja';
	String get normal => 'Normal';
	String get high => 'Alta';
	String get maximum => 'Máxima';
	String get hint => 'Desliza para ajustar cuántos POIs se muestran';
	late final StringsVisualDensitySettingsEs settings = StringsVisualDensitySettingsEs._(_root);
}

// Path: sensorAccuracy
class StringsSensorAccuracyEs {
	StringsSensorAccuracyEs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get high => 'Alta';
	String get medium => 'Media';
	String get low => 'Baja';
	String get unreliable => 'No fiable';
	String get highDescription => 'Precisión alta - Calibración óptima';
	String get mediumDescription => 'Precisión media - Puede requerir calibración';
	String get lowDescription => 'Precisión baja - Calibración recomendada';
	String get unreliableDescription => 'No fiable - Interferencia magnética, calibración necesaria';
	String get tapToCalibrate => 'Toca para calibrar';
}

// Path: debug.sections
class StringsDebugSectionsEs {
	StringsDebugSectionsEs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get debug => 'DEPURACIÓN';
	String get filters => 'FILTROS';
	String get sensors => 'SENSORES';
}

// Path: debug.metrics
class StringsDebugMetricsEs {
	StringsDebugMetricsEs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get fps => 'FPS';
	String get poisVisibleTotal => 'POIs visible/total';
	String get cacheHitRate => 'Cache hit rate';
	String get projectionTime => 'Projection time';
	String get declutterTime => 'Declutter time';
	String get behind => 'Detrás';
	String get tooFar => 'Muy lejos';
	String get horizon => 'Horizonte';
	String get latitude => 'Latitud';
	String get longitude => 'Longitud';
	String get altitude => 'Altitud';
	String get heading => 'Rumbo';
	String get pitch => 'Inclinación';
	String get calibration => 'Calibración';
}

// Path: debug.mode
class StringsDebugModeEs {
	StringsDebugModeEs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get debugMode => 'MODO DEBUG';
}

// Path: debug.actions
class StringsDebugActionsEs {
	StringsDebugActionsEs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get calibrating => 'Calibrando: {offset}°';
	String get hideDebug => 'Ocultar debug';
	String get showDebug => 'Mostrar debug';
}

// Path: visualDensity.settings
class StringsVisualDensitySettingsEs {
	StringsVisualDensitySettingsEs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get maxDistance => 'Distancia máxima';
	String get minImportance => 'Importancia mínima';
	String get declutterMode => 'Modo anti-solapamiento';
}

// Path: <root>
class StringsEn extends Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	StringsEn.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	@override late final StringsEn _root = this; // ignore: unused_field

	// Translations
	@override late final StringsDebugEn debug = StringsDebugEn._(_root);
	@override late final StringsVisualDensityEn visualDensity = StringsVisualDensityEn._(_root);
	@override late final StringsSensorAccuracyEn sensorAccuracy = StringsSensorAccuracyEn._(_root);
}

// Path: debug
class StringsDebugEn extends StringsDebugEs {
	StringsDebugEn._(StringsEn root) : this._root = root, super._(root);

	@override final StringsEn _root; // ignore: unused_field

	// Translations
	@override late final StringsDebugSectionsEn sections = StringsDebugSectionsEn._(_root);
	@override late final StringsDebugMetricsEn metrics = StringsDebugMetricsEn._(_root);
	@override late final StringsDebugModeEn mode = StringsDebugModeEn._(_root);
	@override late final StringsDebugActionsEn actions = StringsDebugActionsEn._(_root);
}

// Path: visualDensity
class StringsVisualDensityEn extends StringsVisualDensityEs {
	StringsVisualDensityEn._(StringsEn root) : this._root = root, super._(root);

	@override final StringsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Visual Density';
	@override String get description => 'Adjust the amount of information visible on screen';
	@override String get minimal => 'Minimal';
	@override String get low => 'Low';
	@override String get normal => 'Normal';
	@override String get high => 'High';
	@override String get maximum => 'Maximum';
	@override String get hint => 'Slide to adjust how many POIs are shown';
	@override late final StringsVisualDensitySettingsEn settings = StringsVisualDensitySettingsEn._(_root);
}

// Path: sensorAccuracy
class StringsSensorAccuracyEn extends StringsSensorAccuracyEs {
	StringsSensorAccuracyEn._(StringsEn root) : this._root = root, super._(root);

	@override final StringsEn _root; // ignore: unused_field

	// Translations
	@override String get high => 'High';
	@override String get medium => 'Medium';
	@override String get low => 'Low';
	@override String get unreliable => 'Unreliable';
	@override String get highDescription => 'High accuracy - Optimal calibration';
	@override String get mediumDescription => 'Medium accuracy - May require calibration';
	@override String get lowDescription => 'Low accuracy - Calibration recommended';
	@override String get unreliableDescription => 'Unreliable - Magnetic interference, calibration needed';
	@override String get tapToCalibrate => 'Tap to calibrate';
}

// Path: debug.sections
class StringsDebugSectionsEn extends StringsDebugSectionsEs {
	StringsDebugSectionsEn._(StringsEn root) : this._root = root, super._(root);

	@override final StringsEn _root; // ignore: unused_field

	// Translations
	@override String get debug => 'DEBUG';
	@override String get filters => 'FILTERS';
	@override String get sensors => 'SENSORS';
}

// Path: debug.metrics
class StringsDebugMetricsEn extends StringsDebugMetricsEs {
	StringsDebugMetricsEn._(StringsEn root) : this._root = root, super._(root);

	@override final StringsEn _root; // ignore: unused_field

	// Translations
	@override String get fps => 'FPS';
	@override String get poisVisibleTotal => 'POIs visible/total';
	@override String get cacheHitRate => 'Cache hit rate';
	@override String get projectionTime => 'Projection time';
	@override String get declutterTime => 'Declutter time';
	@override String get behind => 'Behind';
	@override String get tooFar => 'Too far';
	@override String get horizon => 'Horizon';
	@override String get latitude => 'Latitude';
	@override String get longitude => 'Longitude';
	@override String get altitude => 'Altitude';
	@override String get heading => 'Heading';
	@override String get pitch => 'Pitch';
	@override String get calibration => 'Calibration';
}

// Path: debug.mode
class StringsDebugModeEn extends StringsDebugModeEs {
	StringsDebugModeEn._(StringsEn root) : this._root = root, super._(root);

	@override final StringsEn _root; // ignore: unused_field

	// Translations
	@override String get debugMode => 'DEBUG MODE';
}

// Path: debug.actions
class StringsDebugActionsEn extends StringsDebugActionsEs {
	StringsDebugActionsEn._(StringsEn root) : this._root = root, super._(root);

	@override final StringsEn _root; // ignore: unused_field

	// Translations
	@override String get calibrating => 'Calibrating: {offset}°';
	@override String get hideDebug => 'Hide debug';
	@override String get showDebug => 'Show debug';
}

// Path: visualDensity.settings
class StringsVisualDensitySettingsEn extends StringsVisualDensitySettingsEs {
	StringsVisualDensitySettingsEn._(StringsEn root) : this._root = root, super._(root);

	@override final StringsEn _root; // ignore: unused_field

	// Translations
	@override String get maxDistance => 'Maximum distance';
	@override String get minImportance => 'Minimum importance';
	@override String get declutterMode => 'Anti-overlap mode';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.

extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'debug.sections.debug': return 'DEPURACIÓN';
			case 'debug.sections.filters': return 'FILTROS';
			case 'debug.sections.sensors': return 'SENSORES';
			case 'debug.metrics.fps': return 'FPS';
			case 'debug.metrics.poisVisibleTotal': return 'POIs visible/total';
			case 'debug.metrics.cacheHitRate': return 'Cache hit rate';
			case 'debug.metrics.projectionTime': return 'Projection time';
			case 'debug.metrics.declutterTime': return 'Declutter time';
			case 'debug.metrics.behind': return 'Detrás';
			case 'debug.metrics.tooFar': return 'Muy lejos';
			case 'debug.metrics.horizon': return 'Horizonte';
			case 'debug.metrics.latitude': return 'Latitud';
			case 'debug.metrics.longitude': return 'Longitud';
			case 'debug.metrics.altitude': return 'Altitud';
			case 'debug.metrics.heading': return 'Rumbo';
			case 'debug.metrics.pitch': return 'Inclinación';
			case 'debug.metrics.calibration': return 'Calibración';
			case 'debug.mode.debugMode': return 'MODO DEBUG';
			case 'debug.actions.calibrating': return 'Calibrando: {offset}°';
			case 'debug.actions.hideDebug': return 'Ocultar debug';
			case 'debug.actions.showDebug': return 'Mostrar debug';
			case 'visualDensity.title': return 'Densidad Visual';
			case 'visualDensity.description': return 'Ajusta la cantidad de información visible en pantalla';
			case 'visualDensity.minimal': return 'Mínima';
			case 'visualDensity.low': return 'Baja';
			case 'visualDensity.normal': return 'Normal';
			case 'visualDensity.high': return 'Alta';
			case 'visualDensity.maximum': return 'Máxima';
			case 'visualDensity.hint': return 'Desliza para ajustar cuántos POIs se muestran';
			case 'visualDensity.settings.maxDistance': return 'Distancia máxima';
			case 'visualDensity.settings.minImportance': return 'Importancia mínima';
			case 'visualDensity.settings.declutterMode': return 'Modo anti-solapamiento';
			case 'sensorAccuracy.high': return 'Alta';
			case 'sensorAccuracy.medium': return 'Media';
			case 'sensorAccuracy.low': return 'Baja';
			case 'sensorAccuracy.unreliable': return 'No fiable';
			case 'sensorAccuracy.highDescription': return 'Precisión alta - Calibración óptima';
			case 'sensorAccuracy.mediumDescription': return 'Precisión media - Puede requerir calibración';
			case 'sensorAccuracy.lowDescription': return 'Precisión baja - Calibración recomendada';
			case 'sensorAccuracy.unreliableDescription': return 'No fiable - Interferencia magnética, calibración necesaria';
			case 'sensorAccuracy.tapToCalibrate': return 'Toca para calibrar';
			default: return null;
		}
	}
}

extension on StringsEn {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'debug.sections.debug': return 'DEBUG';
			case 'debug.sections.filters': return 'FILTERS';
			case 'debug.sections.sensors': return 'SENSORS';
			case 'debug.metrics.fps': return 'FPS';
			case 'debug.metrics.poisVisibleTotal': return 'POIs visible/total';
			case 'debug.metrics.cacheHitRate': return 'Cache hit rate';
			case 'debug.metrics.projectionTime': return 'Projection time';
			case 'debug.metrics.declutterTime': return 'Declutter time';
			case 'debug.metrics.behind': return 'Behind';
			case 'debug.metrics.tooFar': return 'Too far';
			case 'debug.metrics.horizon': return 'Horizon';
			case 'debug.metrics.latitude': return 'Latitude';
			case 'debug.metrics.longitude': return 'Longitude';
			case 'debug.metrics.altitude': return 'Altitude';
			case 'debug.metrics.heading': return 'Heading';
			case 'debug.metrics.pitch': return 'Pitch';
			case 'debug.metrics.calibration': return 'Calibration';
			case 'debug.mode.debugMode': return 'DEBUG MODE';
			case 'debug.actions.calibrating': return 'Calibrating: {offset}°';
			case 'debug.actions.hideDebug': return 'Hide debug';
			case 'debug.actions.showDebug': return 'Show debug';
			case 'visualDensity.title': return 'Visual Density';
			case 'visualDensity.description': return 'Adjust the amount of information visible on screen';
			case 'visualDensity.minimal': return 'Minimal';
			case 'visualDensity.low': return 'Low';
			case 'visualDensity.normal': return 'Normal';
			case 'visualDensity.high': return 'High';
			case 'visualDensity.maximum': return 'Maximum';
			case 'visualDensity.hint': return 'Slide to adjust how many POIs are shown';
			case 'visualDensity.settings.maxDistance': return 'Maximum distance';
			case 'visualDensity.settings.minImportance': return 'Minimum importance';
			case 'visualDensity.settings.declutterMode': return 'Anti-overlap mode';
			case 'sensorAccuracy.high': return 'High';
			case 'sensorAccuracy.medium': return 'Medium';
			case 'sensorAccuracy.low': return 'Low';
			case 'sensorAccuracy.unreliable': return 'Unreliable';
			case 'sensorAccuracy.highDescription': return 'High accuracy - Optimal calibration';
			case 'sensorAccuracy.mediumDescription': return 'Medium accuracy - May require calibration';
			case 'sensorAccuracy.lowDescription': return 'Low accuracy - Calibration recommended';
			case 'sensorAccuracy.unreliableDescription': return 'Unreliable - Magnetic interference, calibration needed';
			case 'sensorAccuracy.tapToCalibrate': return 'Tap to calibrate';
			default: return null;
		}
	}
}
