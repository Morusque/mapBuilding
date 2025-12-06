// Rendering configuration and presets

enum RenderFillType {
  RENDER_FILL_COLOR,
  RENDER_FILL_PATTERN
}

enum ElevationLinesStyle {
  ELEV_LINES_BASIC
}

class RenderPreset {
  String name;
  RenderSettings values;

  RenderPreset(String name, RenderSettings values) {
    this.name = name;
    this.values = values;
  }
}

class RenderSettings {
  // Base colors (HSB 0..1) and overlays
  float landHue01 = 0.0f;
  float landSat01 = 0.0f;
  float landBri01 = 0.85f;
  float waterHue01 = 0.58f;
  float waterSat01 = 0.28f;
  float waterBri01 = 0.35f;
  float cellBorderAlpha01 = 0.0f;

  // Biomes
  float biomeFillAlpha01 = 0.5f;
  float biomeSatScale01 = 1.0f;
  RenderFillType biomeFillType = RenderFillType.RENDER_FILL_COLOR;
  String biomePatternName = "dots01.png";
  float biomeOutlineSizePx = 0.0f;
  float biomeOutlineAlpha01 = 1.0f;
  boolean biomeShowUnderwater = false;

  // Shading
  float waterDepthAlpha01 = 0.65f;
  float elevationLightAlpha01 = 0.0f;
  float elevationLightAzimuthDeg = 220.0f;
  float elevationLightAltitudeDeg = 45.0f;

  // Contours
  float waterContourSizePx = 2.0f;
  int waterRippleCount = 0;
  float waterRippleDistancePx = 12.0f;
  float waterContourHue01 = 0.0f;
  float waterContourSat01 = 0.0f;
  float waterContourBri01 = 0.0f;
  float waterContourAlpha01 = 1.0f;
  int elevationLinesCount = 0;
  ElevationLinesStyle elevationLinesStyle = ElevationLinesStyle.ELEV_LINES_BASIC;
  float elevationLinesAlpha01 = 0.25f;

  // Paths
  float pathSatScale01 = 1.0f;
  boolean showPaths = true;

  // Zones (strokes only)
  float zoneStrokeAlpha01 = 1.0f;
  float zoneStrokeSatScale01 = 1.0f;
  boolean showZones = true;

  // Structures
  boolean showStructures = true;
  boolean mergeStructures = false; // placeholder
  float structureSatScale01 = 1.0f;
  float structureAlphaScale01 = 1.0f;

  // Labels
  boolean showLabelsArbitrary = true;
  boolean showLabelsZones = true;
  boolean showLabelsPaths = true;
  boolean showLabelsStructures = true;
  float labelOutlineAlpha01 = 0.7f;
  float labelMinFontPx = 10.0f;

  // General
  float exportPaddingPct = 0.01f;
  boolean antialiasing = true;
  int activePresetIndex = 0;

  RenderSettings copy() {
    RenderSettings c = new RenderSettings();
    // Base
    c.landHue01 = landHue01;
    c.landSat01 = landSat01;
    c.landBri01 = landBri01;
    c.waterHue01 = waterHue01;
    c.waterSat01 = waterSat01;
    c.waterBri01 = waterBri01;
    c.cellBorderAlpha01 = cellBorderAlpha01;
    // Biomes
    c.biomeFillAlpha01 = biomeFillAlpha01;
    c.biomeSatScale01 = biomeSatScale01;
    c.biomeFillType = biomeFillType;
    c.biomeOutlineSizePx = biomeOutlineSizePx;
    c.biomeOutlineAlpha01 = biomeOutlineAlpha01;
    c.biomeShowUnderwater = biomeShowUnderwater;
    // Shading
    c.waterDepthAlpha01 = waterDepthAlpha01;
    c.elevationLightAlpha01 = elevationLightAlpha01;
    c.elevationLightAzimuthDeg = elevationLightAzimuthDeg;
    c.elevationLightAltitudeDeg = elevationLightAltitudeDeg;
    // Contours
    c.waterContourSizePx = waterContourSizePx;
    c.waterRippleCount = waterRippleCount;
    c.waterRippleDistancePx = waterRippleDistancePx;
    c.waterContourHue01 = waterContourHue01;
    c.waterContourSat01 = waterContourSat01;
    c.waterContourBri01 = waterContourBri01;
    c.waterContourAlpha01 = waterContourAlpha01;
    c.elevationLinesCount = elevationLinesCount;
    c.elevationLinesStyle = elevationLinesStyle;
    c.elevationLinesAlpha01 = elevationLinesAlpha01;
    // Paths
    c.pathSatScale01 = pathSatScale01;
    c.showPaths = showPaths;
    // Zones
    c.zoneStrokeAlpha01 = zoneStrokeAlpha01;
    c.zoneStrokeSatScale01 = zoneStrokeSatScale01;
    c.showZones = showZones;
    // Structures
    c.showStructures = showStructures;
    c.mergeStructures = mergeStructures;
    c.structureSatScale01 = structureSatScale01;
    c.structureAlphaScale01 = structureAlphaScale01;
    // Labels
    c.showLabelsArbitrary = showLabelsArbitrary;
    c.showLabelsZones = showLabelsZones;
    c.showLabelsPaths = showLabelsPaths;
    c.showLabelsStructures = showLabelsStructures;
    c.labelOutlineAlpha01 = labelOutlineAlpha01;
    c.labelMinFontPx = labelMinFontPx;
    // General
    c.exportPaddingPct = exportPaddingPct;
    c.antialiasing = antialiasing;
    c.activePresetIndex = activePresetIndex;
    return c;
  }

  void applyFrom(RenderSettings other) {
    if (other == null) return;
    RenderSettings o = other;
    // Base
    landHue01 = o.landHue01;
    landSat01 = o.landSat01;
    landBri01 = o.landBri01;
    waterHue01 = o.waterHue01;
    waterSat01 = o.waterSat01;
    waterBri01 = o.waterBri01;
    cellBorderAlpha01 = o.cellBorderAlpha01;
    // Biomes
    biomeFillAlpha01 = o.biomeFillAlpha01;
    biomeSatScale01 = o.biomeSatScale01;
    biomeFillType = o.biomeFillType;
    biomeOutlineSizePx = o.biomeOutlineSizePx;
    biomeOutlineAlpha01 = o.biomeOutlineAlpha01;
    biomeShowUnderwater = o.biomeShowUnderwater;
    // Shading
    waterDepthAlpha01 = o.waterDepthAlpha01;
    elevationLightAlpha01 = o.elevationLightAlpha01;
    elevationLightAzimuthDeg = o.elevationLightAzimuthDeg;
    elevationLightAltitudeDeg = o.elevationLightAltitudeDeg;
    // Contours
    waterContourSizePx = o.waterContourSizePx;
    waterRippleCount = o.waterRippleCount;
    waterRippleDistancePx = o.waterRippleDistancePx;
    waterContourHue01 = o.waterContourHue01;
    waterContourSat01 = o.waterContourSat01;
    waterContourBri01 = o.waterContourBri01;
    waterContourAlpha01 = o.waterContourAlpha01;
    elevationLinesCount = o.elevationLinesCount;
    elevationLinesStyle = o.elevationLinesStyle;
    elevationLinesAlpha01 = o.elevationLinesAlpha01;
    // Paths
    pathSatScale01 = o.pathSatScale01;
    showPaths = o.showPaths;
    // Zones
    zoneStrokeAlpha01 = o.zoneStrokeAlpha01;
    zoneStrokeSatScale01 = o.zoneStrokeSatScale01;
    showZones = o.showZones;
    // Structures
    showStructures = o.showStructures;
    mergeStructures = o.mergeStructures;
    structureSatScale01 = o.structureSatScale01;
    structureAlphaScale01 = o.structureAlphaScale01;
    // Labels
    showLabelsArbitrary = o.showLabelsArbitrary;
    showLabelsZones = o.showLabelsZones;
    showLabelsPaths = o.showLabelsPaths;
    showLabelsStructures = o.showLabelsStructures;
    labelOutlineAlpha01 = o.labelOutlineAlpha01;
    labelMinFontPx = o.labelMinFontPx;
    // General
    exportPaddingPct = o.exportPaddingPct;
    antialiasing = o.antialiasing;
    activePresetIndex = o.activePresetIndex;
  }
}

RenderPreset[] buildDefaultRenderPresets() {
  ArrayList<RenderPreset> list = new ArrayList<RenderPreset>();

  // Simple
  {
    RenderSettings s = new RenderSettings();
    s.landHue01 = 0.08f; s.landSat01 = 0.0f; s.landBri01 = 0.90f;
    s.waterHue01 = 0.58f; s.waterSat01 = 0.0f; s.waterBri01 = 0.30f;
    s.biomeFillAlpha01 = 0.0f;
    s.biomeSatScale01 = 1.0f;
    s.biomeOutlineSizePx = 0.0f;
    s.biomeOutlineAlpha01 = 0.0f;
    s.waterDepthAlpha01 = 0.0f;
    s.elevationLightAlpha01 = 0.0f;
    s.waterContourSizePx = 2.0f;
    s.waterRippleCount = 0;
    s.waterRippleDistancePx = 5.0f;
    s.waterContourAlpha01 = 1.0f;
    s.elevationLinesCount = 0;
    s.elevationLinesAlpha01 = 1.0f;
    list.add(new RenderPreset("Simple", s));
  }

  // Vivid Color
  {
    RenderSettings s = new RenderSettings();
    s.landHue01 = 0.08f; s.landSat01 = 0.05f; s.landBri01 = 0.90f;
    s.waterHue01 = 0.58f; s.waterSat01 = 0.30f; s.waterBri01 = 0.36f;
    s.biomeFillAlpha01 = 0.6f;
    s.biomeSatScale01 = 1.0f;
    s.biomeOutlineSizePx = 1.2f;
    s.biomeOutlineAlpha01 = 0.9f;
    s.waterDepthAlpha01 = 0.7f;
    s.elevationLightAlpha01 = 0.35f;
    s.waterContourSizePx = 2.0f;
    s.waterRippleCount = 2;
    s.waterRippleDistancePx = 12.0f;
    s.waterContourAlpha01 = 0.9f;
    s.elevationLinesCount = 6;
    s.elevationLinesAlpha01 = 0.22f;
    list.add(new RenderPreset("Vivid Color", s));
  }

  // Muted Terrain
  {
    RenderSettings s = new RenderSettings();
    s.landHue01 = 0.10f; s.landSat01 = 0.02f; s.landBri01 = 0.86f;
    s.waterHue01 = 0.56f; s.waterSat01 = 0.18f; s.waterBri01 = 0.32f;
    s.biomeFillAlpha01 = 0.45f;
    s.biomeSatScale01 = 0.65f;
    s.biomeOutlineSizePx = 0.8f;
    s.biomeOutlineAlpha01 = 0.6f;
    s.waterDepthAlpha01 = 0.55f;
    s.elevationLightAlpha01 = 0.25f;
    s.waterContourSizePx = 1.5f;
    s.waterRippleCount = 1;
    s.waterRippleDistancePx = 16.0f;
    s.waterContourAlpha01 = 0.7f;
    s.elevationLinesCount = 4;
    s.elevationLinesAlpha01 = 0.2f;
    list.add(new RenderPreset("Muted Terrain", s));
  }

  // Paper BW
  {
    RenderSettings s = new RenderSettings();
    s.landHue01 = 0.0f; s.landSat01 = 0.0f; s.landBri01 = 0.92f;
    s.waterHue01 = 0.55f; s.waterSat01 = 0.0f; s.waterBri01 = 0.75f;
    s.biomeFillAlpha01 = 0.4f;
    s.biomeSatScale01 = 0.0f;
    s.biomeOutlineSizePx = 1.2f;
    s.biomeOutlineAlpha01 = 1.0f;
    s.waterDepthAlpha01 = 0.0f;
    s.elevationLightAlpha01 = 0.0f;
    s.waterContourSizePx = 2.5f;
    s.waterRippleCount = 3;
    s.waterRippleDistancePx = 10.0f;
    s.waterContourAlpha01 = 1.0f;
    s.elevationLinesCount = 10;
    s.elevationLinesAlpha01 = 0.25f;
    s.antialiasing = false;
    list.add(new RenderPreset("Paper BW", s));
  }

  // Water Focus
  {
    RenderSettings s = new RenderSettings();
    s.landHue01 = 0.09f; s.landSat01 = 0.03f; s.landBri01 = 0.90f;
    s.waterHue01 = 0.58f; s.waterSat01 = 0.40f; s.waterBri01 = 0.42f;
    s.biomeFillAlpha01 = 0.35f;
    s.biomeSatScale01 = 0.8f;
    s.biomeOutlineSizePx = 0.8f;
    s.biomeOutlineAlpha01 = 0.7f;
    s.waterDepthAlpha01 = 0.85f;
    s.elevationLightAlpha01 = 0.2f;
    s.waterContourSizePx = 2.5f;
    s.waterRippleCount = 4;
    s.waterRippleDistancePx = 12.0f;
    s.waterContourAlpha01 = 0.9f;
    s.elevationLinesCount = 4;
    s.elevationLinesAlpha01 = 0.15f;
    list.add(new RenderPreset("Water Focus", s));
  }

  // Line Art / Simplified
  {
    RenderSettings s = new RenderSettings();
    s.landHue01 = 0.0f; s.landSat01 = 0.0f; s.landBri01 = 0.94f;
    s.waterHue01 = 0.56f; s.waterSat01 = 0.05f; s.waterBri01 = 0.80f;
    s.biomeFillAlpha01 = 0.25f;
    s.biomeSatScale01 = 0.2f;
    s.biomeOutlineSizePx = 1.6f;
    s.biomeOutlineAlpha01 = 1.0f;
    s.waterDepthAlpha01 = 0.0f;
    s.elevationLightAlpha01 = 0.0f;
    s.waterContourSizePx = 3.0f;
    s.waterRippleCount = 1;
    s.waterRippleDistancePx = 18.0f;
    s.waterContourAlpha01 = 1.0f;
    s.elevationLinesCount = 0;
    s.elevationLinesAlpha01 = 0.0f;
    list.add(new RenderPreset("Line Art", s));
  }

  RenderPreset[] arr = new RenderPreset[list.size()];
  list.toArray(arr);
  return arr;
}
