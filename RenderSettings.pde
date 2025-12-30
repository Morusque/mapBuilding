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
