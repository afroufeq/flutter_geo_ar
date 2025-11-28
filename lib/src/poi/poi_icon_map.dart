import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Map from POI key (category:subtype) to FontAwesome icon data.
final Map<String, IconData> poiIcons = {
  // --- NATURAL ---
  'natural:peak': FontAwesomeIcons.mountain,
  'natural:volcano': FontAwesomeIcons.volcano,
  'natural:spring': FontAwesomeIcons.droplet, // O FontAwesomeIcons.water
  'natural:arch': FontAwesomeIcons.archway,
  'natural:viewpoint': FontAwesomeIcons.eye, // Mirador natural
  'natural:cave_entrance': FontAwesomeIcons.dungeon, // Entrada de cueva
  'natural:cape': FontAwesomeIcons.compass, // Cabo/Promontorio
  'natural:waterfall': FontAwesomeIcons.water, // Cascada
  'natural:beach': FontAwesomeIcons.umbrellaBeach, // Playa
  'natural:cliff': FontAwesomeIcons.mountainSun, // Acantilado
  'natural:rock': FontAwesomeIcons.gem, // Formación rocosa
  'natural:stone': FontAwesomeIcons.circle, // Piedra

  // --- LEISURE ---
  'leisure:nature_reserve': FontAwesomeIcons.tree, // Reserva natural

  // --- BOUNDARY ---
  'boundary:protected_area': FontAwesomeIcons.shieldHeart, // Área protegida

  // --- TOURISM ---
  'tourism:viewpoint': FontAwesomeIcons.binoculars,
  'tourism:museum': FontAwesomeIcons.buildingColumns,
  'tourism:attraction': FontAwesomeIcons.camera, // O FontAwesomeIcons.star

  // --- AMENITY (Servicios) ---
  'amenity:hospital': FontAwesomeIcons.hospital,
  'amenity:clinic': FontAwesomeIcons.houseMedical, // O FontAwesomeIcons.staffSnake
  'amenity:police': FontAwesomeIcons.shieldHalved,
  'amenity:shelter': FontAwesomeIcons.houseChimney,

  // --- HISTORIC ---
  'historic:monument': FontAwesomeIcons.monument,
  'historic:ruins': FontAwesomeIcons.scroll, // Representa historia antigua
  'historic:castle': FontAwesomeIcons.chessRook, // O FontAwesomeIcons.fortAwesome
  'historic:church': FontAwesomeIcons.church,

  // --- MAN MADE ---
  'man_made:lighthouse': FontAwesomeIcons.towerObservation, // Lo más cercano a un faro en free
  'man_made:bridge': FontAwesomeIcons.bridge,

  // --- PLACE (Lugares / Asentamientos) ---
  // Ordenados de mayor a menor tamaño aproximado
  'place:city': FontAwesomeIcons.city,
  'place:town': FontAwesomeIcons.building,
  'place:village': FontAwesomeIcons.house,
  'place:suburb': FontAwesomeIcons.treeCity,
  'place:neighbourhood': FontAwesomeIcons.peopleRoof,
  'place:hamlet': FontAwesomeIcons.tents, // O FontAwesomeIcons.houseUser para aldeas pequeñas
  'place:isolated_dwelling': FontAwesomeIcons.houseChimneyUser,
  'place:farm': FontAwesomeIcons.tractor,

  // --- PLACE (Geográfico / Otros) ---
  'place:island': FontAwesomeIcons.umbrellaBeach,
  'place:islet': FontAwesomeIcons.fish,
  'place:locality': FontAwesomeIcons.mapPin, // Lugares genéricos
  'place:square': FontAwesomeIcons.kaaba, // Representa una plaza/cubo
  'place:quarter': FontAwesomeIcons.shop, // Barrios a veces comerciales

  // --- DEFAULT ---
  'default': FontAwesomeIcons.locationDot,
};
