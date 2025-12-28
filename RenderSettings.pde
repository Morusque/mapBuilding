// Rendering configuration and presets

enum RenderFillType {
  RENDER_FILL_COLOR,
  RENDER_FILL_PATTERN,
  RENDER_FILL_PATTERN_BG
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
  float cellBorderSizePx = 1.0f;
  boolean cellBorderScaleWithZoom = false;
  float cellBorderRefZoom = DEFAULT_VIEW_ZOOM;
  float backgroundNoiseAlpha01 = 0.0f;

  // Biomes
  float biomeFillAlpha01 = 0.5f;
  float biomeSatScale01 = 1.0f;
  float biomeBriScale01 = 1.0f;
  RenderFillType biomeFillType = RenderFillType.RENDER_FILL_COLOR;
  String biomePatternName = "dots01.png";
  float biomeOutlineSizePx = 0.0f;
  float biomeOutlineAlpha01 = 1.0f;
  boolean biomeOutlineScaleWithZoom = false;
  float biomeOutlineRefZoom = DEFAULT_VIEW_ZOOM;
  float biomeUnderwaterAlpha01 = 0.0f;

  // Shading
  float waterDepthAlpha01 = 0.5f;
  float elevationLightAlpha01 = 0.5f;
  float elevationLightAzimuthDeg = 220.0f;
  float elevationLightAltitudeDeg = 45.0f;
  float elevationLightDitherPx = 0.0f;

  // Contours
  float waterContourSizePx = 2.0f;
  int waterRippleCount = 0;
  float waterRippleDistancePx = 5.0f;
  float waterContourHue01 = 0.0f;
  float waterContourSat01 = 0.0f;
  float waterContourBri01 = 0.0f;
  float waterContourAlpha01 = 1.0f; // legacy: keep for backward compat
  float waterCoastAlpha01 = 1.0f;
  float waterCoastSizePx = 2.0f;
  boolean waterCoastScaleWithZoom = false;
  boolean waterCoastAboveZones = false;
  boolean waterContourScaleWithZoom = false;
  float waterContourRefZoom = DEFAULT_VIEW_ZOOM;
  float waterRippleAlphaStart01 = 1.0f;
  float waterRippleAlphaEnd01 = 0.3f;
  float waterHatchAngleDeg = 0.0f;     // 0 = horizontal lines
  float waterHatchLengthPx = 0.0f;     // world length = px/zoom
  float waterHatchSpacingPx = 12.0f;   // spacing in screen px
  float waterHatchAlpha01 = 0.0f;
  int elevationLinesCount = 0;
  ElevationLinesStyle elevationLinesStyle = ElevationLinesStyle.ELEV_LINES_BASIC;
  float elevationLinesAlpha01 = 0.3f;
  float elevationLinesSizePx = 1.0f;
  boolean elevationLinesScaleWithZoom = false;
  float elevationLinesRefZoom = DEFAULT_VIEW_ZOOM;

  // Paths
  float pathSatScale01 = 1.0f;
  float pathBriScale01 = 1.0f;
  boolean showPaths = true;
  boolean pathScaleWithZoom = false;
  float pathScaleRefZoom = DEFAULT_VIEW_ZOOM;

  // Zones (strokes only)
  float zoneStrokeAlpha01 = 0.5f;
  float zoneStrokeSizePx = 2.0f;
  float zoneStrokeSatScale01 = 0.5f;
  float zoneStrokeBriScale01 = 1.0f;
  boolean zoneStrokeScaleWithZoom = false;
  float zoneStrokeRefZoom = DEFAULT_VIEW_ZOOM;

  // Structures
  boolean showStructures = true;
  boolean mergeStructures = false; // placeholder
  float structureSatScale01 = 1.0f;
  float structureAlphaScale01 = 1.0f;
  float structureShadowAlpha01 = 0.0f;
  boolean structureStrokeScaleWithZoom = false;
  float structureStrokeRefZoom = DEFAULT_VIEW_ZOOM;

  // Labels
  boolean showLabelsArbitrary = true;
  boolean showLabelsZones = true;
  boolean showLabelsPaths = true;
  boolean showLabelsStructures = true;
  float labelOutlineAlpha01 = 0.0f;
  float labelOutlineSizePx = 1.0f;
  float labelSizeArbPx = 12.0f;
  float labelSizeZonePx = 14.0f;
  float labelSizePathPx = 12.0f;
  float labelSizeStructPx = 12.0f;
  boolean labelScaleWithZoom = false;
  float labelScaleRefZoom = 1.0f;
  boolean labelOutlineScaleWithZoom = false;
  int labelFontIndex = 0;

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
    c.cellBorderSizePx = cellBorderSizePx;
    c.cellBorderScaleWithZoom = cellBorderScaleWithZoom;
    c.cellBorderRefZoom = cellBorderRefZoom;
    c.backgroundNoiseAlpha01 = backgroundNoiseAlpha01;
    // Biomes
    c.biomeFillAlpha01 = biomeFillAlpha01;
    c.biomeSatScale01 = biomeSatScale01;
    c.biomeBriScale01 = biomeBriScale01;
    c.biomeFillType = biomeFillType;
    c.biomePatternName = biomePatternName;
    c.biomeOutlineSizePx = biomeOutlineSizePx;
    c.biomeOutlineAlpha01 = biomeOutlineAlpha01;
    c.biomeOutlineScaleWithZoom = biomeOutlineScaleWithZoom;
    c.biomeOutlineRefZoom = biomeOutlineRefZoom;
    c.biomeUnderwaterAlpha01 = biomeUnderwaterAlpha01;
    // Shading
    c.waterDepthAlpha01 = waterDepthAlpha01;
    c.elevationLightAlpha01 = elevationLightAlpha01;
    c.elevationLightAzimuthDeg = elevationLightAzimuthDeg;
    c.elevationLightAltitudeDeg = elevationLightAltitudeDeg;
    c.elevationLightDitherPx = elevationLightDitherPx;
    // Contours
    c.waterContourSizePx = waterContourSizePx;
    c.waterRippleCount = waterRippleCount;
    c.waterRippleDistancePx = waterRippleDistancePx;
    c.waterContourHue01 = waterContourHue01;
    c.waterContourSat01 = waterContourSat01;
    c.waterContourBri01 = waterContourBri01;
    c.waterContourAlpha01 = waterCoastAlpha01;
    c.waterCoastAlpha01 = waterCoastAlpha01;
    c.waterCoastSizePx = waterCoastSizePx;
    c.waterCoastScaleWithZoom = waterCoastScaleWithZoom;
    c.waterCoastAboveZones = waterCoastAboveZones;
    c.waterContourScaleWithZoom = waterContourScaleWithZoom;
    c.waterContourRefZoom = waterContourRefZoom;
    c.waterRippleAlphaStart01 = waterRippleAlphaStart01;
    c.waterRippleAlphaEnd01 = waterRippleAlphaEnd01;
    c.waterHatchAngleDeg = waterHatchAngleDeg;
    c.waterHatchLengthPx = waterHatchLengthPx;
    c.waterHatchSpacingPx = waterHatchSpacingPx;
    c.waterHatchAlpha01 = waterHatchAlpha01;
    c.elevationLinesCount = elevationLinesCount;
    c.elevationLinesStyle = elevationLinesStyle;
    c.elevationLinesAlpha01 = elevationLinesAlpha01;
    c.elevationLinesSizePx = elevationLinesSizePx;
    c.elevationLinesScaleWithZoom = elevationLinesScaleWithZoom;
    c.elevationLinesRefZoom = elevationLinesRefZoom;
    // Paths
    c.pathSatScale01 = pathSatScale01;
    c.pathBriScale01 = pathBriScale01;
    c.showPaths = showPaths;
    c.pathScaleWithZoom = pathScaleWithZoom;
    c.pathScaleRefZoom = pathScaleRefZoom;
    // Zones
    c.zoneStrokeAlpha01 = zoneStrokeAlpha01;
    c.zoneStrokeSizePx = zoneStrokeSizePx;
    c.zoneStrokeSatScale01 = zoneStrokeSatScale01;
    c.zoneStrokeBriScale01 = zoneStrokeBriScale01;
    c.zoneStrokeScaleWithZoom = zoneStrokeScaleWithZoom;
    c.zoneStrokeRefZoom = zoneStrokeRefZoom;
    // Structures
    c.showStructures = showStructures;
    c.mergeStructures = mergeStructures;
    c.structureSatScale01 = structureSatScale01;
    c.structureAlphaScale01 = structureAlphaScale01;
    c.structureShadowAlpha01 = structureShadowAlpha01;
    c.structureStrokeScaleWithZoom = structureStrokeScaleWithZoom;
    c.structureStrokeRefZoom = structureStrokeRefZoom;
    // Labels
    c.showLabelsArbitrary = showLabelsArbitrary;
    c.showLabelsZones = showLabelsZones;
    c.showLabelsPaths = showLabelsPaths;
    c.showLabelsStructures = showLabelsStructures;
    c.labelOutlineAlpha01 = labelOutlineAlpha01;
    c.labelOutlineSizePx = labelOutlineSizePx;
    c.labelSizeArbPx = labelSizeArbPx;
    c.labelSizeZonePx = labelSizeZonePx;
    c.labelSizePathPx = labelSizePathPx;
    c.labelSizeStructPx = labelSizeStructPx;
    c.labelScaleWithZoom = labelScaleWithZoom;
    c.labelScaleRefZoom = labelScaleRefZoom;
    c.labelOutlineScaleWithZoom = labelOutlineScaleWithZoom;
    c.labelFontIndex = labelFontIndex;
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
    cellBorderSizePx = o.cellBorderSizePx;
    cellBorderScaleWithZoom = o.cellBorderScaleWithZoom;
    cellBorderRefZoom = o.cellBorderRefZoom;
    backgroundNoiseAlpha01 = o.backgroundNoiseAlpha01;
    // Biomes
    biomeFillAlpha01 = o.biomeFillAlpha01;
    biomeSatScale01 = o.biomeSatScale01;
    biomeBriScale01 = o.biomeBriScale01;
    biomeFillType = o.biomeFillType;
    biomePatternName = o.biomePatternName;
    biomeOutlineSizePx = o.biomeOutlineSizePx;
    biomeOutlineAlpha01 = o.biomeOutlineAlpha01;
    biomeOutlineScaleWithZoom = o.biomeOutlineScaleWithZoom;
    biomeOutlineRefZoom = o.biomeOutlineRefZoom;
    biomeUnderwaterAlpha01 = o.biomeUnderwaterAlpha01;
    // Shading
    waterDepthAlpha01 = o.waterDepthAlpha01;
    elevationLightAlpha01 = o.elevationLightAlpha01;
    elevationLightAzimuthDeg = o.elevationLightAzimuthDeg;
    elevationLightAltitudeDeg = o.elevationLightAltitudeDeg;
    elevationLightDitherPx = o.elevationLightDitherPx;
    // Contours
    waterContourSizePx = o.waterContourSizePx;
    waterRippleCount = o.waterRippleCount;
    waterRippleDistancePx = o.waterRippleDistancePx;
    waterContourHue01 = o.waterContourHue01;
    waterContourSat01 = o.waterContourSat01;
    waterContourBri01 = o.waterContourBri01;
    waterContourAlpha01 = o.waterCoastAlpha01;
    waterCoastAlpha01 = o.waterCoastAlpha01;
    waterCoastSizePx = o.waterCoastSizePx;
    waterCoastScaleWithZoom = o.waterCoastScaleWithZoom;
    waterCoastAboveZones = o.waterCoastAboveZones;
    waterContourScaleWithZoom = o.waterContourScaleWithZoom;
    waterContourRefZoom = o.waterContourRefZoom;
    waterRippleAlphaStart01 = o.waterRippleAlphaStart01;
    waterRippleAlphaEnd01 = o.waterRippleAlphaEnd01;
    waterHatchAngleDeg = o.waterHatchAngleDeg;
    waterHatchLengthPx = o.waterHatchLengthPx;
    waterHatchSpacingPx = o.waterHatchSpacingPx;
    waterHatchAlpha01 = o.waterHatchAlpha01;
    elevationLinesCount = o.elevationLinesCount;
    elevationLinesStyle = o.elevationLinesStyle;
    elevationLinesAlpha01 = o.elevationLinesAlpha01;
    elevationLinesSizePx = o.elevationLinesSizePx;
    elevationLinesScaleWithZoom = o.elevationLinesScaleWithZoom;
    elevationLinesRefZoom = o.elevationLinesRefZoom;
    // Paths
    pathSatScale01 = o.pathSatScale01;
    pathBriScale01 = o.pathBriScale01;
    showPaths = o.showPaths;
    pathScaleWithZoom = o.pathScaleWithZoom;
    pathScaleRefZoom = o.pathScaleRefZoom;
    // Zones
    zoneStrokeAlpha01 = o.zoneStrokeAlpha01;
    zoneStrokeSizePx = o.zoneStrokeSizePx;
    zoneStrokeSatScale01 = o.zoneStrokeSatScale01;
    zoneStrokeBriScale01 = o.zoneStrokeBriScale01;
    zoneStrokeScaleWithZoom = o.zoneStrokeScaleWithZoom;
    zoneStrokeRefZoom = o.zoneStrokeRefZoom;
    // Structures
    showStructures = o.showStructures;
    mergeStructures = o.mergeStructures;
    structureSatScale01 = o.structureSatScale01;
    structureAlphaScale01 = o.structureAlphaScale01;
    structureShadowAlpha01 = o.structureShadowAlpha01;
    structureStrokeScaleWithZoom = o.structureStrokeScaleWithZoom;
    structureStrokeRefZoom = o.structureStrokeRefZoom;
    // Labels
    showLabelsArbitrary = o.showLabelsArbitrary;
    showLabelsZones = o.showLabelsZones;
    showLabelsPaths = o.showLabelsPaths;
    showLabelsStructures = o.showLabelsStructures;
    labelOutlineAlpha01 = o.labelOutlineAlpha01;
    labelOutlineSizePx = o.labelOutlineSizePx;
    labelSizeArbPx = o.labelSizeArbPx;
    labelSizeZonePx = o.labelSizeZonePx;
    labelSizePathPx = o.labelSizePathPx;
    labelSizeStructPx = o.labelSizeStructPx;
    labelScaleWithZoom = o.labelScaleWithZoom;
    labelScaleRefZoom = o.labelScaleRefZoom;
    labelOutlineScaleWithZoom = o.labelOutlineScaleWithZoom;
    labelFontIndex = o.labelFontIndex;
    if (LABEL_FONT_OPTIONS != null && LABEL_FONT_OPTIONS.length > 0) {
      labelFontIndex = constrain(labelFontIndex, 0, LABEL_FONT_OPTIONS.length - 1);
    } else {
      labelFontIndex = 0;
    }
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
    s.backgroundNoiseAlpha01 = 0.0f;
    s.biomeFillAlpha01 = 0.5f;
    s.biomeSatScale01 = 1.0f;
    s.biomeBriScale01 = 1.0f;
    s.biomeOutlineSizePx = 0.0f;
    s.biomeOutlineAlpha01 = 1.0f;
    s.biomeUnderwaterAlpha01 = 0.0f;
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
    s.waterCoastAlpha01 = 1.0f;
    s.waterCoastSizePx = 2.0f;
    s.waterCoastScaleWithZoom = false;
    s.waterCoastAboveZones = false;
    s.waterRippleAlphaStart01 = 1.0f;
    s.waterRippleAlphaEnd01 = 0.3f;
    s.waterHatchAngleDeg = 0.0f;
    s.waterHatchLengthPx = 0.0f;
    s.waterHatchSpacingPx = 12.0f;
    s.waterHatchAlpha01 = 0.0f;
    s.elevationLinesCount = 0;
    s.elevationLinesAlpha01 = 0.3f;
    s.pathSatScale01 = 1.0f;
    s.pathScaleWithZoom = false;
    s.showPaths = true;
    s.zoneStrokeAlpha01 = 0.5f;
    s.zoneStrokeSizePx = 2.0f;
    s.zoneStrokeSatScale01 = 0.5f;
    s.zoneStrokeBriScale01 = 1.0f;
    s.showStructures = true;
    s.mergeStructures = true;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.structureShadowAlpha01 = 0.0f;
    s.showLabelsArbitrary = true;
    s.showLabelsZones = true;
    s.showLabelsPaths = true;
    s.showLabelsStructures = true;
    s.labelOutlineAlpha01 = 0.0f;
    s.labelOutlineSizePx = 1.0f;
    s.labelSizeArbPx = 12.0f;
    s.labelSizeZonePx = 14.0f;
    s.labelSizePathPx = 12.0f;
    s.labelSizeStructPx = 12.0f;
    s.labelScaleWithZoom = false;
    s.labelFontIndex = 0;
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
    s.biomeUnderwaterAlpha01 = 0.0f;
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
    s.waterCoastAlpha01 = 0.3f;
    s.waterRippleAlphaStart01 = 0.25f;
    s.waterRippleAlphaEnd01 = 0.08f;
    s.elevationLinesCount = 0;
    s.elevationLinesAlpha01 = 0.0f;
    s.pathSatScale01 = 0.7f;
    s.showPaths = true;
    s.zoneStrokeAlpha01 = 0.0f;
    s.zoneStrokeSizePx = 2.0f;
    s.zoneStrokeSatScale01 = 0.0f;
    s.zoneStrokeBriScale01 = 0.0f;
    s.showStructures = true;
    s.mergeStructures = false;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.structureShadowAlpha01 = 0.2f;
    s.showLabelsArbitrary = false;
    s.showLabelsZones = false;
    s.showLabelsPaths = false;
    s.showLabelsStructures = false;
    s.labelOutlineAlpha01 = 0.0f;
    s.labelOutlineSizePx = 1.0f;
    s.labelSizeArbPx = 12.0f;
    s.labelSizeZonePx = 14.0f;
    s.labelSizePathPx = 12.0f;
    s.labelSizeStructPx = 12.0f;
    s.labelFontIndex = 0;
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
    s.biomeUnderwaterAlpha01 = 0.0f;
    s.waterDepthAlpha01 = 0.3f;
    s.elevationLightAlpha01 = 0.3f;
    s.elevationLightAzimuthDeg = 280.0f;
    s.elevationLightAltitudeDeg = 15.0f;
    s.elevationLightDitherPx = 0.0f;
    s.waterContourSizePx = 2.5f;
    s.waterRippleCount = 0;
    s.waterRippleDistancePx = 0.0f;
    s.waterContourHue01 = 0.6f;
    s.waterContourSat01 = 0.25f;
    s.waterContourBri01 = 0.0f;
    s.waterContourAlpha01 = 1.0f;
    s.waterCoastAlpha01 = 1.0f;
    s.waterRippleAlphaStart01 = 0.9f;
    s.waterRippleAlphaEnd01 = 0.25f;
    s.elevationLinesCount = 10;
    s.elevationLinesAlpha01 = 0.6f;
    s.pathSatScale01 = 1.0f;
    s.showPaths = true;
    s.zoneStrokeAlpha01 = 0.0f;
    s.zoneStrokeSizePx = 2.0f;
    s.zoneStrokeSatScale01 = 0.0f;
    s.zoneStrokeBriScale01 = 0.0f;
    s.showStructures = false;
    s.mergeStructures = false;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.structureShadowAlpha01 = 0.2f;
    s.showLabelsArbitrary = true;
    s.showLabelsZones = true;
    s.showLabelsPaths = true;
    s.showLabelsStructures = false;
    s.labelOutlineAlpha01 = 0.0f;
    s.labelOutlineSizePx = 1.0f;
    s.labelSizeArbPx = 12.0f;
    s.labelSizeZonePx = 14.0f;
    s.labelSizePathPx = 12.0f;
    s.labelSizeStructPx = 12.0f;
    s.labelScaleWithZoom = false;
    s.labelFontIndex = 0;
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
    s.biomeUnderwaterAlpha01 = 0.0f;
    s.waterDepthAlpha01 = 0.5f;
    s.elevationLightAlpha01 = 0.25f;
    s.elevationLightAzimuthDeg = 220.0f;
    s.elevationLightAltitudeDeg = 25.0f;
    s.elevationLightDitherPx = 0.0f;
    s.waterContourSizePx = 3.0f;
    s.waterRippleCount = 0;
    s.waterRippleDistancePx = 0.0f;
    s.waterContourHue01 = 0.5f;
    s.waterContourSat01 = 0.0f;
    s.waterContourBri01 = 0.0f;
    s.waterContourAlpha01 = 1.0f;
    s.waterCoastAlpha01 = 1.0f;
    s.waterRippleAlphaStart01 = 0.8f;
    s.waterRippleAlphaEnd01 = 0.25f;
    s.elevationLinesCount = 4;
    s.elevationLinesAlpha01 = 0.25f;
    s.pathSatScale01 = 0.8f;
    s.showPaths = true;
    s.zoneStrokeAlpha01 = 0.7f;
    s.zoneStrokeSizePx = 2.0f;
    s.zoneStrokeSatScale01 = 0.0f;
    s.zoneStrokeBriScale01 = 0.0f;
    s.showStructures = true;
    s.mergeStructures = false;
    s.structureSatScale01 = 0.0f;
    s.structureAlphaScale01 = 1.0f;
    s.structureShadowAlpha01 = 0.25f;
    s.showLabelsArbitrary = true;
    s.showLabelsZones = true;
    s.showLabelsPaths = true;
    s.showLabelsStructures = true;
    s.labelOutlineAlpha01 = 0.8f;
    s.labelOutlineSizePx = 1.0f;
    s.labelSizeArbPx = 12.0f;
    s.labelSizeZonePx = 14.0f;
    s.labelSizePathPx = 12.0f;
    s.labelSizeStructPx = 12.0f;
    s.labelFontIndex = 0;
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
    s.biomeUnderwaterAlpha01 = 0.0f;
    s.waterDepthAlpha01 = 0.0f;
    s.elevationLightAlpha01 = 0.0f;
    s.elevationLightAzimuthDeg = 220.0f;
    s.elevationLightAltitudeDeg = 45.0f;
    s.elevationLightDitherPx = 0.0f;
    s.waterContourSizePx = 2.0f;
    s.waterRippleCount = 3;
    s.waterRippleDistancePx = 4.0f;
    s.waterContourHue01 = 0.5f;
    s.waterContourSat01 = 0.0f;
    s.waterContourBri01 = 0.0f;
    s.waterContourAlpha01 = 1.0f;
    s.waterCoastAlpha01 = 1.0f;
    s.waterRippleAlphaStart01 = 0.8f;
    s.waterRippleAlphaEnd01 = 0.25f;
    s.elevationLinesCount = 2;
    s.elevationLinesAlpha01 = 1.0f;
    s.pathSatScale01 = 0.0f;
    s.showPaths = true;
    s.zoneStrokeAlpha01 = 1.0f;
    s.zoneStrokeSizePx = 2.0f;
    s.zoneStrokeSatScale01 = 0.0f;
    s.zoneStrokeBriScale01 = 0.0f;
    s.showStructures = true;
    s.mergeStructures = false;
    s.structureSatScale01 = 0.0f;
    s.structureAlphaScale01 = 1.0f;
    s.structureShadowAlpha01 = 0.25f;
    s.showLabelsArbitrary = true;
    s.showLabelsZones = true;
    s.showLabelsPaths = true;
    s.showLabelsStructures = true;
    s.labelOutlineAlpha01 = 1.0f;
    s.labelOutlineSizePx = 1.0f;
    s.labelSizeArbPx = 12.0f;
    s.labelSizeZonePx = 14.0f;
    s.labelSizePathPx = 12.0f;
    s.labelSizeStructPx = 12.0f;
    s.labelScaleWithZoom = false;
    s.labelScaleRefZoom = 1.0f;
    s.labelFontIndex = 0;
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
    s.biomeUnderwaterAlpha01 = 1.0f;
    s.waterDepthAlpha01 = 1.0f;
    s.elevationLightAlpha01 = 0.4f;
    s.elevationLightAzimuthDeg = 250.0f;
    s.elevationLightAltitudeDeg = 10.0f;
    s.elevationLightDitherPx = 0.0f;
    s.waterContourSizePx = 2.0f;
    s.waterRippleCount = 4;
    s.waterRippleDistancePx = 6.0f;
    s.waterContourHue01 = 0.6f;
    s.waterContourSat01 = 1.0f;
    s.waterContourBri01 = 0.3f;
    s.waterContourAlpha01 = 1.0f;
    s.waterCoastAlpha01 = 1.0f;
    s.waterRippleAlphaStart01 = 0.8f;
    s.waterRippleAlphaEnd01 = 0.25f;
    s.elevationLinesCount = 16;
    s.elevationLinesAlpha01 = 0.3f;
    s.pathSatScale01 = 1.0f;
    s.showPaths = true;
    s.zoneStrokeAlpha01 = 0.5f;
    s.zoneStrokeSizePx = 2.0f;
    s.zoneStrokeSatScale01 = 0.8f;
    s.zoneStrokeBriScale01 = 0.2f;
    s.showStructures = true;
    s.mergeStructures = true;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.structureShadowAlpha01 = 0.4f;
    s.showLabelsArbitrary = true;
    s.showLabelsZones = true;
    s.showLabelsPaths = true;
    s.showLabelsStructures = true;
    s.labelOutlineAlpha01 = 0.9f;
    s.labelOutlineSizePx = 1.0f;
    s.labelSizeArbPx = 12.0f;
    s.labelSizeZonePx = 14.0f;
    s.labelSizePathPx = 12.0f;
    s.labelSizeStructPx = 12.0f;
    s.labelFontIndex = 0;
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
    s.biomeBriScale01 = 1.0f;
    s.biomeOutlineSizePx = 1.0f;
    s.biomeOutlineAlpha01 = 0.0f;
    s.biomeUnderwaterAlpha01 = 1.0f;
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
    s.waterCoastAlpha01 = 0.5f;
    s.waterRippleAlphaStart01 = 0.35f;
    s.waterRippleAlphaEnd01 = 0.15f;
    s.elevationLinesCount = 0;
    s.elevationLinesAlpha01 = 0.1f;
    s.pathSatScale01 = 0.8f;
    s.showPaths = true;
    s.zoneStrokeAlpha01 = 1.0f;
    s.zoneStrokeSizePx = 2.0f;
    s.zoneStrokeSatScale01 = 1.0f;
    s.zoneStrokeBriScale01 = 1.0f;
    s.showStructures = true;
    s.mergeStructures = true;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.structureShadowAlpha01 = 0.2f;
    s.showLabelsArbitrary = true;
    s.showLabelsZones = true;
    s.showLabelsPaths = true;
    s.showLabelsStructures = true;
    s.labelOutlineAlpha01 = 1.0f;
    s.labelOutlineSizePx = 1.0f;
    s.labelSizeArbPx = 12.0f;
    s.labelSizeZonePx = 14.0f;
    s.labelSizePathPx = 12.0f;
    s.labelSizeStructPx = 12.0f;
    s.labelFontIndex = 0;
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
    s.waterCoastAlpha01 = 1.0f;
    s.waterRippleAlphaStart01 = 0.8f;
    s.waterRippleAlphaEnd01 = 0.25f;
    s.elevationLinesCount = 0;
    s.elevationLinesAlpha01 = 1.0f;
    s.pathSatScale01 = 0.8f;
    s.showPaths = false;
    s.zoneStrokeAlpha01 = 1.0f;
    s.zoneStrokeSizePx = 2.0f;
    s.zoneStrokeSatScale01 = 1.0f;
    s.zoneStrokeBriScale01 = 1.0f;
    s.showStructures = false;
    s.mergeStructures = true;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.structureShadowAlpha01 = 0.2f;
    s.showLabelsArbitrary = false;
    s.showLabelsZones = false;
    s.showLabelsPaths = false;
    s.showLabelsStructures = false;
    s.labelOutlineAlpha01 = 1.0f;
    s.labelOutlineSizePx = 1.0f;
    s.labelSizeArbPx = 12.0f;
    s.labelSizeZonePx = 14.0f;
    s.labelSizePathPx = 12.0f;
    s.labelSizeStructPx = 12.0f;
    s.labelFontIndex = 0;
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
    s.waterDepthAlpha01 = 0.6f;
    s.elevationLightAlpha01 = 1.0f;
    s.elevationLightAzimuthDeg = 300.0f;
    s.elevationLightAltitudeDeg = 70.0f;
    s.elevationLightDitherPx = 0.0f;
    s.waterContourSizePx = 4.0f;
    s.waterRippleCount = 5;
    s.waterRippleDistancePx = 20.0f;
    s.waterContourHue01 = 0.1f;
    s.waterContourSat01 = 1.0f;
    s.waterContourBri01 = 1.0f;
    s.waterContourAlpha01 = 1.0f;
    s.waterCoastAlpha01 = 1.0f;
    s.waterRippleAlphaStart01 = 0.8f;
    s.waterRippleAlphaEnd01 = 0.25f;
    s.elevationLinesCount = 24;
    s.elevationLinesAlpha01 = 1.0f;
    s.pathSatScale01 = 0.3f;
    s.showPaths = false;
    s.zoneStrokeAlpha01 = 1.0f;
    s.zoneStrokeSizePx = 2.0f;
    s.zoneStrokeSatScale01 = 0.3f;
    s.zoneStrokeBriScale01 = 0.5f;
    s.showStructures = false;
    s.mergeStructures = true;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.structureShadowAlpha01 = 0.25f;
    s.showLabelsArbitrary = false;
    s.showLabelsZones = false;
    s.showLabelsPaths = false;
    s.showLabelsStructures = false;
    s.labelOutlineAlpha01 = 0.3f;
    s.labelOutlineSizePx = 1.0f;
    s.labelSizeArbPx = 12.0f;
    s.labelSizeZonePx = 14.0f;
    s.labelSizePathPx = 12.0f;
    s.labelSizeStructPx = 12.0f;
    s.labelFontIndex = 0;
    s.exportPaddingPct = 0.0f;
    s.antialiasing = true;
    s.biomeFillType = RenderFillType.RENDER_FILL_PATTERN;
    list.add(new RenderPreset("Rocky", s));
  }

  RenderPreset[] arr = new RenderPreset[list.size()];
  list.toArray(arr);
  return arr;
}
