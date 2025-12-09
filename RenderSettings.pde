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
  float waterDepthAlpha01 = 0.5f;
  float elevationLightAlpha01 = 0.5f;
  float elevationLightAzimuthDeg = 220.0f;
  float elevationLightAltitudeDeg = 45.0f;

  // Contours
  float waterContourSizePx = 2.0f;
  int waterRippleCount = 0;
  float waterRippleDistancePx = 5.0f;
  float waterContourHue01 = 0.0f;
  float waterContourSat01 = 0.0f;
  float waterContourBri01 = 0.0f;
  float waterContourAlpha01 = 1.0f;
  int elevationLinesCount = 0;
  ElevationLinesStyle elevationLinesStyle = ElevationLinesStyle.ELEV_LINES_BASIC;
  float elevationLinesAlpha01 = 0.3f;

  // Paths
  float pathSatScale01 = 1.0f;
  boolean showPaths = true;

  // Zones (strokes only)
  float zoneStrokeAlpha01 = 0.5f;
  float zoneStrokeSatScale01 = 0.5f;
  float zoneStrokeBriScale01 = 1.0f;

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
  float labelOutlineAlpha01 = 0.0f;

  // General
  float exportPaddingPct = 0.015f;
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
    c.biomePatternName = biomePatternName;
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
    c.zoneStrokeBriScale01 = zoneStrokeBriScale01;
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
    biomePatternName = o.biomePatternName;
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
    zoneStrokeBriScale01 = o.zoneStrokeBriScale01;
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
    // General
    exportPaddingPct = o.exportPaddingPct;
    antialiasing = o.antialiasing;
    activePresetIndex = o.activePresetIndex;
  }
}

RenderPreset[] buildDefaultRenderPresets() {
  ArrayList<RenderPreset> list = new ArrayList<RenderPreset>();

  // default
  {
    RenderSettings s = new RenderSettings();
    s.landHue01 = 0.0f;
    s.landSat01 = 0.0f;
    s.landBri01 = 0.85f;
    s.waterHue01 = 0.58f;
    s.waterSat01 = 0.28f;
    s.waterBri01 = 0.35f;
    s.cellBorderAlpha01 = 0.0f;
    s.biomeFillAlpha01 = 0.5f;
    s.biomeSatScale01 = 1.0f;
    s.biomeOutlineSizePx = 0.0f;
    s.biomeOutlineAlpha01 = 1.0f;
    s.biomeShowUnderwater = false;
    s.waterDepthAlpha01 = 0.5f;
    s.elevationLightAlpha01 = 0.5f;
    s.elevationLightAzimuthDeg = 220.0f;
    s.elevationLightAltitudeDeg = 45.0f;
    s.waterContourSizePx = 2.0f;
    s.waterRippleCount = 0;
    s.waterRippleDistancePx = 5.0f;
    s.waterContourHue01 = 0.0f;
    s.waterContourSat01 = 0.0f;
    s.waterContourBri01 = 0.0f;
    s.waterContourAlpha01 = 1.0f;
    s.elevationLinesCount = 0;
    s.elevationLinesAlpha01 = 0.3f;
    s.pathSatScale01 = 1.0f;
    s.showPaths = true;
    s.zoneStrokeAlpha01 = 0.5f;
    s.zoneStrokeSatScale01 = 0.5f;
    s.zoneStrokeBriScale01 = 1.0f;
    s.showStructures = true;
    s.mergeStructures = true;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.showLabelsArbitrary = true;
    s.showLabelsZones = true;
    s.showLabelsPaths = true;
    s.showLabelsStructures = true;
    s.labelOutlineAlpha01 = 0.0f;
    s.exportPaddingPct = 0.015f;
    s.antialiasing = true;
    list.add(new RenderPreset("Default", s));
  }

  // satellite
  {
    RenderSettings s = new RenderSettings();
    s.landHue01 = 0.2f;
    s.landSat01 = 0.1f;
    s.landBri01 = 0.9f;
    s.waterHue01 = 0.6f;
    s.waterSat01 = 0.2f;
    s.waterBri01 = 0.4f;
    s.cellBorderAlpha01 = 0.0f;
    s.biomeFillAlpha01 = 0.8f;
    s.biomeSatScale01 = 0.4f;
    s.biomeOutlineSizePx = 0.0f;
    s.biomeOutlineAlpha01 = 0.0f;
    s.biomeShowUnderwater = false;
    s.waterDepthAlpha01 = 0.8f;
    s.elevationLightAlpha01 = 0.6f;
    s.elevationLightAzimuthDeg = 200.0f;
    s.elevationLightAltitudeDeg = 60.0f;
    s.waterContourSizePx = 5.0f;
    s.waterRippleCount = 0;
    s.waterRippleDistancePx = 0.0f;
    s.waterContourHue01 = 0.6f;
    s.waterContourSat01 = 0.3f;
    s.waterContourBri01 = 0.6f;
    s.waterContourAlpha01 = 0.3f;
    s.elevationLinesCount = 0;
    s.elevationLinesAlpha01 = 0.0f;
    s.pathSatScale01 = 0.7f;
    s.showPaths = true;
    s.zoneStrokeAlpha01 = 0.0f;
    s.zoneStrokeSatScale01 = 0.0f;
    s.zoneStrokeBriScale01 = 0.0f;
    s.showStructures = true;
    s.mergeStructures = false;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.showLabelsArbitrary = false;
    s.showLabelsZones = false;
    s.showLabelsPaths = false;
    s.showLabelsStructures = false;
    s.labelOutlineAlpha01 = 0.0f;
    s.exportPaddingPct = 0.01f;
    s.antialiasing = true;
    list.add(new RenderPreset("Satellite", s));
  }

  // geographic
  {
    RenderSettings s = new RenderSettings();
    s.landHue01 = 0.2f;
    s.landSat01 = 0.0f;
    s.landBri01 = 1.0f;
    s.waterHue01 = 0.6f;
    s.waterSat01 = 0.7f;
    s.waterBri01 = 0.6f;
    s.cellBorderAlpha01 = 0.0f;
    s.biomeFillAlpha01 = 1.0f;
    s.biomeSatScale01 = 0.75f;
    s.biomeOutlineSizePx = 1.0f;
    s.biomeOutlineAlpha01 = 0.0f;
    s.biomeShowUnderwater = false;
    s.waterDepthAlpha01 = 0.3f;
    s.elevationLightAlpha01 = 0.3f;
    s.elevationLightAzimuthDeg = 280.0f;
    s.elevationLightAltitudeDeg = 15.0f;
    s.waterContourSizePx = 2.5f;
    s.waterRippleCount = 0;
    s.waterRippleDistancePx = 0.0f;
    s.waterContourHue01 = 0.6f;
    s.waterContourSat01 = 0.25f;
    s.waterContourBri01 = 0.0f;
    s.waterContourAlpha01 = 1.0f;
    s.elevationLinesCount = 10;
    s.elevationLinesAlpha01 = 0.6f;
    s.pathSatScale01 = 1.0f;
    s.showPaths = true;
    s.zoneStrokeAlpha01 = 0.0f;
    s.zoneStrokeSatScale01 = 0.0f;
    s.zoneStrokeBriScale01 = 0.0f;
    s.showStructures = false;
    s.mergeStructures = false;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.showLabelsArbitrary = true;
    s.showLabelsZones = true;
    s.showLabelsPaths = true;
    s.showLabelsStructures = false;
    s.labelOutlineAlpha01 = 0.0f;
    s.exportPaddingPct = 0.02f;
    s.antialiasing = true;
    list.add(new RenderPreset("Geographic", s));
  }

  // grey
  {
    RenderSettings s = new RenderSettings();
    s.landHue01 = 0.1f;
    s.landSat01 = 0.0f;
    s.landBri01 = 1.0f;
    s.waterHue01 = 0.6f;
    s.waterSat01 = 0.0f;
    s.waterBri01 = 0.2f;
    s.cellBorderAlpha01 = 0.0f;
    s.biomeFillAlpha01 = 1.0f;
    s.biomeSatScale01 = 0.0f;
    s.biomeOutlineSizePx = 1.0f;
    s.biomeOutlineAlpha01 = 0.0f;
    s.biomeShowUnderwater = false;
    s.waterDepthAlpha01 = 0.5f;
    s.elevationLightAlpha01 = 0.25f;
    s.elevationLightAzimuthDeg = 220.0f;
    s.elevationLightAltitudeDeg = 25.0f;
    s.waterContourSizePx = 3.0f;
    s.waterRippleCount = 0;
    s.waterRippleDistancePx = 0.0f;
    s.waterContourHue01 = 0.5f;
    s.waterContourSat01 = 0.0f;
    s.waterContourBri01 = 0.0f;
    s.waterContourAlpha01 = 1.0f;
    s.elevationLinesCount = 4;
    s.elevationLinesAlpha01 = 0.25f;
    s.pathSatScale01 = 0.8f;
    s.showPaths = true;
    s.zoneStrokeAlpha01 = 0.7f;
    s.zoneStrokeSatScale01 = 0.0f;
    s.zoneStrokeBriScale01 = 0.0f;
    s.showStructures = true;
    s.mergeStructures = false;
    s.structureSatScale01 = 0.0f;
    s.structureAlphaScale01 = 1.0f;
    s.showLabelsArbitrary = true;
    s.showLabelsZones = true;
    s.showLabelsPaths = true;
    s.showLabelsStructures = true;
    s.labelOutlineAlpha01 = 0.8f;
    s.exportPaddingPct = 0.015f;
    s.antialiasing = true;
    list.add(new RenderPreset("Grey", s));
  }

  // bitmap
  {
    RenderSettings s = new RenderSettings();
    s.landHue01 = 0.1f;
    s.landSat01 = 0.0f;
    s.landBri01 = 1.0f;
    s.waterHue01 = 0.6f;
    s.waterSat01 = 0.0f;
    s.waterBri01 = 1.0f;
    s.cellBorderAlpha01 = 0.0f;
    s.biomeFillAlpha01 = 1.0f;
    s.biomeSatScale01 = 0.0f;
    s.biomeOutlineSizePx = 1.0f;
    s.biomeOutlineAlpha01 = 0.0f;
    s.biomeShowUnderwater = false;
    s.waterDepthAlpha01 = 0.0f;
    s.elevationLightAlpha01 = 0.0f;
    s.elevationLightAzimuthDeg = 220.0f;
    s.elevationLightAltitudeDeg = 45.0f;
    s.waterContourSizePx = 2.0f;
    s.waterRippleCount = 3;
    s.waterRippleDistancePx = 4.0f;
    s.waterContourHue01 = 0.5f;
    s.waterContourSat01 = 0.0f;
    s.waterContourBri01 = 0.0f;
    s.waterContourAlpha01 = 1.0f;
    s.elevationLinesCount = 2;
    s.elevationLinesAlpha01 = 1.0f;
    s.pathSatScale01 = 0.0f;
    s.showPaths = true;
    s.zoneStrokeAlpha01 = 1.0f;
    s.zoneStrokeSatScale01 = 0.0f;
    s.zoneStrokeBriScale01 = 0.0f;
    s.showStructures = true;
    s.mergeStructures = false;
    s.structureSatScale01 = 0.0f;
    s.structureAlphaScale01 = 1.0f;
    s.showLabelsArbitrary = true;
    s.showLabelsZones = true;
    s.showLabelsPaths = true;
    s.showLabelsStructures = true;
    s.labelOutlineAlpha01 = 1.0f;
    s.exportPaddingPct = 0.015f;
    s.antialiasing = false;
    s.biomeFillType = RenderFillType.RENDER_FILL_PATTERN;
    list.add(new RenderPreset("Bitmap", s));
  }

  // much
  {
    RenderSettings s = new RenderSettings();
    s.landHue01 = 0.1f;
    s.landSat01 = 0.1f;
    s.landBri01 = 0.8f;
    s.waterHue01 = 0.6f;
    s.waterSat01 = 0.7f;
    s.waterBri01 = 0.2f;
    s.cellBorderAlpha01 = 0.05f;
    s.biomeFillAlpha01 = 0.3f;
    s.biomeSatScale01 = 0.9f;
    s.biomeOutlineSizePx = 2.0f;
    s.biomeOutlineAlpha01 = 0.9f;
    s.biomeShowUnderwater = true;
    s.waterDepthAlpha01 = 1.0f;
    s.elevationLightAlpha01 = 0.4f;
    s.elevationLightAzimuthDeg = 250.0f;
    s.elevationLightAltitudeDeg = 10.0f;
    s.waterContourSizePx = 2.0f;
    s.waterRippleCount = 4;
    s.waterRippleDistancePx = 6.0f;
    s.waterContourHue01 = 0.6f;
    s.waterContourSat01 = 1.0f;
    s.waterContourBri01 = 0.3f;
    s.waterContourAlpha01 = 1.0f;
    s.elevationLinesCount = 16;
    s.elevationLinesAlpha01 = 0.3f;
    s.pathSatScale01 = 1.0f;
    s.showPaths = true;
    s.zoneStrokeAlpha01 = 0.5f;
    s.zoneStrokeSatScale01 = 0.8f;
    s.zoneStrokeBriScale01 = 0.2f;
    s.showStructures = true;
    s.mergeStructures = true;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.showLabelsArbitrary = true;
    s.showLabelsZones = true;
    s.showLabelsPaths = true;
    s.showLabelsStructures = true;
    s.labelOutlineAlpha01 = 0.9f;
    s.exportPaddingPct = 0.02f;
    s.antialiasing = true;
    s.biomeFillType = RenderFillType.RENDER_FILL_PATTERN;
    list.add(new RenderPreset("Much", s));
  }

  // administrative
  {
    RenderSettings s = new RenderSettings();
    s.landHue01 = 0.2f;
    s.landSat01 = 0.0f;
    s.landBri01 = 1.0f;
    s.waterHue01 = 0.6f;
    s.waterSat01 = 0.7f;
    s.waterBri01 = 0.5f;
    s.cellBorderAlpha01 = 0.0f;
    s.biomeFillAlpha01 = 0.3f;
    s.biomeSatScale01 = 0.3f;
    s.biomeOutlineSizePx = 1.0f;
    s.biomeOutlineAlpha01 = 0.0f;
    s.biomeShowUnderwater = true;
    s.waterDepthAlpha01 = 0.0f;
    s.elevationLightAlpha01 = 0.0f;
    s.elevationLightAzimuthDeg = 0.0f;
    s.elevationLightAltitudeDeg = 10.0f;
    s.waterContourSizePx = 2.0f;
    s.waterRippleCount = 0;
    s.waterRippleDistancePx = 0.0f;
    s.waterContourHue01 = 0.5f;
    s.waterContourSat01 = 0.25f;
    s.waterContourBri01 = 0.0f;
    s.waterContourAlpha01 = 0.5f;
    s.elevationLinesCount = 0;
    s.elevationLinesAlpha01 = 0.1f;
    s.pathSatScale01 = 0.8f;
    s.showPaths = true;
    s.zoneStrokeAlpha01 = 1.0f;
    s.zoneStrokeSatScale01 = 1.0f;
    s.zoneStrokeBriScale01 = 1.0f;
    s.showStructures = true;
    s.mergeStructures = true;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.showLabelsArbitrary = true;
    s.showLabelsZones = true;
    s.showLabelsPaths = true;
    s.showLabelsStructures = true;
    s.labelOutlineAlpha01 = 1.0f;
    s.exportPaddingPct = 0.015f;
    s.antialiasing = true;
    list.add(new RenderPreset("Administrative", s));
  }

  // simple
  {
    RenderSettings s = new RenderSettings();
    s.landHue01 = 0.1f;
    s.landSat01 = 0.1f;
    s.landBri01 = 1.0f;
    s.waterHue01 = 0.6f;
    s.waterSat01 = 0.7f;
    s.waterBri01 = 0.5f;
    s.cellBorderAlpha01 = 0.0f;
    s.biomeFillAlpha01 = 1.0f;
    s.biomeSatScale01 = 1.0f;
    s.biomeOutlineSizePx = 1.0f;
    s.biomeOutlineAlpha01 = 0.0f;
    s.biomeShowUnderwater = false;
    s.waterDepthAlpha01 = 0.0f;
    s.elevationLightAlpha01 = 0.0f;
    s.elevationLightAzimuthDeg = 0.0f;
    s.elevationLightAltitudeDeg = 10.0f;
    s.waterContourSizePx = 3.0f;
    s.waterRippleCount = 0;
    s.waterRippleDistancePx = 0.0f;
    s.waterContourHue01 = 0.5f;
    s.waterContourSat01 = 0.25f;
    s.waterContourBri01 = 0.0f;
    s.waterContourAlpha01 = 1.0f;
    s.elevationLinesCount = 0;
    s.elevationLinesAlpha01 = 1.0f;
    s.pathSatScale01 = 0.8f;
    s.showPaths = false;
    s.zoneStrokeAlpha01 = 1.0f;
    s.zoneStrokeSatScale01 = 1.0f;
    s.zoneStrokeBriScale01 = 1.0f;
    s.showStructures = false;
    s.mergeStructures = true;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.showLabelsArbitrary = false;
    s.showLabelsZones = false;
    s.showLabelsPaths = false;
    s.showLabelsStructures = false;
    s.labelOutlineAlpha01 = 1.0f;
    s.exportPaddingPct = 0.015f;
    s.antialiasing = true;
    list.add(new RenderPreset("Simple", s));
  }

  // rocky
  {
    RenderSettings s = new RenderSettings();
    s.landHue01 = 0.7f;
    s.landSat01 = 1.0f;
    s.landBri01 = 0.4f;
    s.waterHue01 = 0.1f;
    s.waterSat01 = 1.0f;
    s.waterBri01 = 1.0f;
    s.cellBorderAlpha01 = 0.8f;
    s.biomeFillAlpha01 = 0.7f;
    s.biomeSatScale01 = 1.0f;
    s.biomeOutlineSizePx = 4.0f;
    s.biomeOutlineAlpha01 = 0.3f;
    s.biomeShowUnderwater = true;
    s.waterDepthAlpha01 = 0.6f;
    s.elevationLightAlpha01 = 1.0f;
    s.elevationLightAzimuthDeg = 300.0f;
    s.elevationLightAltitudeDeg = 70.0f;
    s.waterContourSizePx = 4.0f;
    s.waterRippleCount = 5;
    s.waterRippleDistancePx = 20.0f;
    s.waterContourHue01 = 0.1f;
    s.waterContourSat01 = 1.0f;
    s.waterContourBri01 = 1.0f;
    s.waterContourAlpha01 = 1.0f;
    s.elevationLinesCount = 24;
    s.elevationLinesAlpha01 = 1.0f;
    s.pathSatScale01 = 0.3f;
    s.showPaths = false;
    s.zoneStrokeAlpha01 = 1.0f;
    s.zoneStrokeSatScale01 = 0.3f;
    s.zoneStrokeBriScale01 = 0.5f;
    s.showStructures = false;
    s.mergeStructures = true;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.showLabelsArbitrary = false;
    s.showLabelsZones = false;
    s.showLabelsPaths = false;
    s.showLabelsStructures = false;
    s.labelOutlineAlpha01 = 0.3f;
    s.exportPaddingPct = 0.0f;
    s.antialiasing = true;
    s.biomeFillType = RenderFillType.RENDER_FILL_PATTERN;
    list.add(new RenderPreset("Rocky", s));
  }

  RenderPreset[] arr = new RenderPreset[list.size()];
  list.toArray(arr);
  return arr;
}
