enum Tool {
  EDIT_SITES,
  EDIT_ELEVATION,
  EDIT_BIOMES,
  EDIT_ZONES,
  EDIT_PATHS,
  EDIT_STRUCTURES,
  EDIT_LABELS,
  EDIT_RENDER,
  EDIT_EXPORT
}

enum PlacementMode {
  GRID,
  POISSON,
  HEX
}

enum ZonePaintMode {
  ZONE_PAINT,
  ZONE_FILL
}

enum PathRouteMode {
  ENDS,
  PATHFIND
}

enum StructureSnapMode {
  NONE,
  NEXT_TO_PATH,
  ON_PATH
}

enum StructureShape {
  RECTANGLE,
  CIRCLE,
  TRIANGLE,
  HEXAGON
}

enum StructureSnapTargetType {
  NONE,
  PATH,
  FRONTIER,
  STRUCTURE
}

enum LabelTarget {
  FREE,
  BIOME,
  ZONE,
  PATH,
  STRUCTURE
}
