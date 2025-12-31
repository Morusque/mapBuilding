// Default render presets (all fields explicitly assigned for review)
RenderPreset[] buildDefaultRenderPresets() {
  ArrayList<RenderPreset> list = new ArrayList<RenderPreset>();

  // Default
  {
    RenderSettings s = new RenderSettings();
    // Base
    s.landHue01 = 0.0f;
    s.landSat01 = 0.0f;
    s.landBri01 = 0.85f;
    s.waterHue01 = 0.55f;
    s.waterSat01 = 0.55f;
    s.waterBri01 = 0.55f;
    s.cellBorderAlpha01 = 0.0f;
    s.cellBorderSizePx = 1.0f;
    s.cellBorderScaleWithZoom = true;
    s.cellBorderRefZoom = DEFAULT_VIEW_ZOOM;
    s.backgroundNoiseAlpha01 = 0.1f;
    // Biomes
    s.biomeFillAlpha01 = 0.5f;
    s.biomeSatScale01 = 1.0f;
    s.biomeBriScale01 = 1.0f;
    s.biomeFillType = RenderFillType.RENDER_FILL_COLOR;
    s.biomeOutlineSizePx = 1.0f;
    s.biomeOutlineAlpha01 = 0.5f;
    s.biomeOutlineScaleWithZoom = true;
    s.biomeOutlineRefZoom = DEFAULT_VIEW_ZOOM;
    s.biomeUnderwaterAlpha01 = 0.1f;
    // Shading
    s.waterDepthAlpha01 = 0.75f;
    s.elevationLightAlpha01 = 0.75f;
    s.elevationLightAzimuthDeg = 220.0f;
    s.elevationLightAltitudeDeg = 45.0f;
    s.elevationLightDitherPx = 3.0f;
    s.elevationLightDitherScaleWithZoom = true;
    s.elevationLightDitherRefZoom = DEFAULT_VIEW_ZOOM;
    // Contours
    s.waterContourSizePx = 2.0f;
    s.waterRippleCount = 0;
    s.waterRippleDistancePx = 5.0f;
    s.waterContourHue01 = 0.6f;
    s.waterContourSat01 = 0.0f;
    s.waterContourBri01 = 0.0f;
    s.waterContourAlpha01 = 1.0f;
    s.waterCoastAlpha01 = 1.0f;
    s.waterCoastSizePx = 2.0f;
    s.waterCoastScaleWithZoom = true;
    s.waterCoastAboveZones = true;
    s.waterContourScaleWithZoom = true;
    s.waterContourRefZoom = DEFAULT_VIEW_ZOOM;
    s.waterRippleAlphaStart01 = 1.0f;
    s.waterRippleAlphaEnd01 = 0.3f;
    s.waterHatchAngleDeg = 0.0f;
    s.waterHatchLengthPx = 5.0f;
    s.waterHatchSpacingPx = 4.0f;
    s.waterHatchAlpha01 = 0.0f;
    s.elevationLinesCount = 0;
    s.elevationLinesStyle = ElevationLinesStyle.ELEV_LINES_BASIC;
    s.elevationLinesAlpha01 = 0.3f;
    s.elevationLinesSizePx = 1.0f;
    s.elevationLinesScaleWithZoom = true;
    s.elevationLinesRefZoom = DEFAULT_VIEW_ZOOM;
    // Paths
    s.pathSatScale01 = 1.0f;
    s.pathBriScale01 = 1.0f;
    s.showPaths = true;
    s.pathScaleWithZoom = true;
    s.pathScaleRefZoom = DEFAULT_VIEW_ZOOM;
    // Zones
    s.zoneStrokeAlpha01 = 0.75f;
    s.zoneStrokeSizePx = 2.0f;
    s.zoneStrokeSatScale01 = 0.75f;
    s.zoneStrokeBriScale01 = 1.0f;
    s.zoneStrokeScaleWithZoom = true;
    s.zoneStrokeRefZoom = DEFAULT_VIEW_ZOOM;
    // Structures
    s.showStructures = true;
    s.mergeStructures = true;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.structureShadowAlpha01 = 0.2f;
    s.structureStrokeScaleWithZoom = true;
    s.structureStrokeRefZoom = DEFAULT_VIEW_ZOOM;
    // Labels
    s.showLabelsArbitrary = true;
    s.showLabelsZones = true;
    s.showLabelsPaths = true;
    s.showLabelsStructures = true;
    s.labelOutlineAlpha01 = 1.0f;
    s.labelOutlineSizePx = 2.0f;
    s.labelSizeArbPx = 19.0f;
    s.labelSizeZonePx = 17.0f;
    s.labelSizePathPx = 12.0f;
    s.labelSizeStructPx = 14.0f;
    s.labelScaleWithZoom = true;
    s.labelScaleRefZoom = DEFAULT_VIEW_ZOOM;
    s.labelOutlineScaleWithZoom = true;
    s.labelFontIndex = 4;
    // General
    s.exportPaddingPct = 0.015f;
    s.antialiasing = true;
    s.activePresetIndex = 0;
    list.add(new RenderPreset("Default", s));
  }

  // Satellite
  {
    RenderSettings s = new RenderSettings();
    // Base
    s.landHue01 = 0.2f;
    s.landSat01 = 0.1f;
    s.landBri01 = 0.9f;
    s.waterHue01 = 0.6f;
    s.waterSat01 = 0.2f;
    s.waterBri01 = 0.4f;
    s.cellBorderAlpha01 = 0.0f;
    s.cellBorderSizePx = 1.0f;
    s.cellBorderScaleWithZoom = true;
    s.cellBorderRefZoom = DEFAULT_VIEW_ZOOM;
    s.backgroundNoiseAlpha01 = 0.0f;
    // Biomes
    s.biomeFillAlpha01 = 0.8f;
    s.biomeSatScale01 = 0.4f;
    s.biomeBriScale01 = 1.0f;
    s.biomeFillType = RenderFillType.RENDER_FILL_COLOR;
    s.biomeOutlineSizePx = 0.0f;
    s.biomeOutlineAlpha01 = 0.0f;
    s.biomeOutlineScaleWithZoom = true;
    s.biomeOutlineRefZoom = DEFAULT_VIEW_ZOOM;
    s.biomeUnderwaterAlpha01 = 0.0f;
    // Shading
    s.waterDepthAlpha01 = 0.8f;
    s.elevationLightAlpha01 = 0.6f;
    s.elevationLightAzimuthDeg = 200.0f;
    s.elevationLightAltitudeDeg = 60.0f;
    s.elevationLightDitherPx = 0.0f;
    // Contours
    s.waterContourSizePx = 5.0f;
    s.waterRippleCount = 0;
    s.waterRippleDistancePx = 0.0f;
    s.waterContourHue01 = 0.6f;
    s.waterContourSat01 = 0.3f;
    s.waterContourBri01 = 0.6f;
    s.waterContourAlpha01 = 0.3f;
    s.waterCoastAlpha01 = 0.3f;
    s.waterCoastSizePx = 2.0f;
    s.waterCoastScaleWithZoom = true;
    s.waterCoastAboveZones = false;
    s.waterContourScaleWithZoom = true;
    s.waterContourRefZoom = DEFAULT_VIEW_ZOOM;
    s.waterRippleAlphaStart01 = 0.25f;
    s.waterRippleAlphaEnd01 = 0.08f;
    s.waterHatchAngleDeg = 0.0f;
    s.waterHatchLengthPx = 0.0f;
    s.waterHatchSpacingPx = 12.0f;
    s.waterHatchAlpha01 = 0.0f;
    s.elevationLinesCount = 0;
    s.elevationLinesStyle = ElevationLinesStyle.ELEV_LINES_BASIC;
    s.elevationLinesAlpha01 = 0.0f;
    s.elevationLinesSizePx = 1.0f;
    s.elevationLinesScaleWithZoom = true;
    s.elevationLinesRefZoom = DEFAULT_VIEW_ZOOM;
    // Paths
    s.pathSatScale01 = 0.7f;
    s.pathBriScale01 = 1.0f;
    s.showPaths = true;
    s.pathScaleWithZoom = true;
    s.pathScaleRefZoom = DEFAULT_VIEW_ZOOM;
    // Zones
    s.zoneStrokeAlpha01 = 0.0f;
    s.zoneStrokeSizePx = 2.0f;
    s.zoneStrokeSatScale01 = 0.0f;
    s.zoneStrokeBriScale01 = 0.0f;
    s.zoneStrokeScaleWithZoom = true;
    s.zoneStrokeRefZoom = DEFAULT_VIEW_ZOOM;
    // Structures
    s.showStructures = true;
    s.mergeStructures = false;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.structureShadowAlpha01 = 0.2f;
    s.structureStrokeScaleWithZoom = true;
    s.structureStrokeRefZoom = DEFAULT_VIEW_ZOOM;
    // Labels
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
    s.labelScaleWithZoom = true;
    s.labelScaleRefZoom = DEFAULT_VIEW_ZOOM;
    s.labelOutlineScaleWithZoom = true;
    s.labelFontIndex = 0;
    // General
    s.exportPaddingPct = 0.01f;
    s.antialiasing = true;
    s.activePresetIndex = 0;
    list.add(new RenderPreset("Satellite", s));
  }

  // Geographic
  {
    RenderSettings s = new RenderSettings();
    // Base
    s.landHue01 = 0.2f;
    s.landSat01 = 0.0f;
    s.landBri01 = 1.0f;
    s.waterHue01 = 0.6f;
    s.waterSat01 = 0.7f;
    s.waterBri01 = 0.6f;
    s.cellBorderAlpha01 = 0.0f;
    s.cellBorderSizePx = 1.0f;
    s.cellBorderScaleWithZoom = true;
    s.cellBorderRefZoom = DEFAULT_VIEW_ZOOM;
    s.backgroundNoiseAlpha01 = 0.0f;
    // Biomes
    s.biomeFillAlpha01 = 1.0f;
    s.biomeSatScale01 = 0.75f;
    s.biomeBriScale01 = 1.0f;
    s.biomeFillType = RenderFillType.RENDER_FILL_COLOR;
    s.biomeOutlineSizePx = 1.0f;
    s.biomeOutlineAlpha01 = 0.0f;
    s.biomeOutlineScaleWithZoom = true;
    s.biomeOutlineRefZoom = DEFAULT_VIEW_ZOOM;
    s.biomeUnderwaterAlpha01 = 0.0f;
    // Shading
    s.waterDepthAlpha01 = 0.3f;
    s.elevationLightAlpha01 = 0.3f;
    s.elevationLightAzimuthDeg = 280.0f;
    s.elevationLightAltitudeDeg = 15.0f;
    s.elevationLightDitherPx = 0.0f;
    // Contours
    s.waterContourSizePx = 2.5f;
    s.waterRippleCount = 0;
    s.waterRippleDistancePx = 0.0f;
    s.waterContourHue01 = 0.6f;
    s.waterContourSat01 = 0.25f;
    s.waterContourBri01 = 0.0f;
    s.waterContourAlpha01 = 1.0f;
    s.waterCoastAlpha01 = 1.0f;
    s.waterCoastSizePx = 2.0f;
    s.waterCoastScaleWithZoom = true;
    s.waterCoastAboveZones = false;
    s.waterContourScaleWithZoom = true;
    s.waterContourRefZoom = DEFAULT_VIEW_ZOOM;
    s.waterRippleAlphaStart01 = 0.9f;
    s.waterRippleAlphaEnd01 = 0.25f;
    s.waterHatchAngleDeg = 0.0f;
    s.waterHatchLengthPx = 0.0f;
    s.waterHatchSpacingPx = 12.0f;
    s.waterHatchAlpha01 = 0.0f;
    s.elevationLinesCount = 10;
    s.elevationLinesStyle = ElevationLinesStyle.ELEV_LINES_BASIC;
    s.elevationLinesAlpha01 = 0.6f;
    s.elevationLinesSizePx = 1.0f;
    s.elevationLinesScaleWithZoom = true;
    s.elevationLinesRefZoom = DEFAULT_VIEW_ZOOM;
    // Paths
    s.pathSatScale01 = 1.0f;
    s.pathBriScale01 = 1.0f;
    s.showPaths = true;
    s.pathScaleWithZoom = true;
    s.pathScaleRefZoom = DEFAULT_VIEW_ZOOM;
    // Zones
    s.zoneStrokeAlpha01 = 0.0f;
    s.zoneStrokeSizePx = 2.0f;
    s.zoneStrokeSatScale01 = 0.0f;
    s.zoneStrokeBriScale01 = 0.0f;
    s.zoneStrokeScaleWithZoom = true;
    s.zoneStrokeRefZoom = DEFAULT_VIEW_ZOOM;
    // Structures
    s.showStructures = false;
    s.mergeStructures = false;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.structureShadowAlpha01 = 0.2f;
    s.structureStrokeScaleWithZoom = true;
    s.structureStrokeRefZoom = DEFAULT_VIEW_ZOOM;
    // Labels
    s.showLabelsArbitrary = true;
    s.showLabelsZones = true;
    s.showLabelsPaths = true;
    s.showLabelsStructures = false;
    s.labelOutlineAlpha01 = 1.0f;
    s.labelOutlineSizePx = 2.0f;
    s.labelSizeArbPx = 16.0f;
    s.labelSizeZonePx = 17.0f;
    s.labelSizePathPx = 15.0f;
    s.labelSizeStructPx = 14.0f;
    s.labelScaleWithZoom = true;
    s.labelScaleRefZoom = DEFAULT_VIEW_ZOOM;
    s.labelOutlineScaleWithZoom = true;
    s.labelFontIndex = 2;
    // General
    s.exportPaddingPct = 0.02f;
    s.antialiasing = true;
    s.activePresetIndex = 0;
    list.add(new RenderPreset("Geographic", s));
  }

  // Grey
  {
    RenderSettings s = new RenderSettings();
    // Base
    s.landHue01 = 0.1f;
    s.landSat01 = 0.0f;
    s.landBri01 = 1.0f;
    s.waterHue01 = 0.0f;
    s.waterSat01 = 0.0f;
    s.waterBri01 = 0.25f;
    s.cellBorderAlpha01 = 0.0f;
    s.cellBorderSizePx = 1.0f;
    s.cellBorderScaleWithZoom = true;
    s.cellBorderRefZoom = DEFAULT_VIEW_ZOOM;
    s.backgroundNoiseAlpha01 = 0.0f;
    // Biomes
    s.biomeFillAlpha01 = 1.0f;
    s.biomeSatScale01 = 0.0f;
    s.biomeBriScale01 = 1.0f;
    s.biomeFillType = RenderFillType.RENDER_FILL_COLOR;
    s.biomeOutlineSizePx = 1.0f;
    s.biomeOutlineAlpha01 = 0.0f;
    s.biomeOutlineScaleWithZoom = true;
    s.biomeOutlineRefZoom = DEFAULT_VIEW_ZOOM;
    s.biomeUnderwaterAlpha01 = 0.0f;
    // Shading
    s.waterDepthAlpha01 = 0.5f;
    s.elevationLightAlpha01 = 0.25f;
    s.elevationLightAzimuthDeg = 220.0f;
    s.elevationLightAltitudeDeg = 25.0f;
    s.elevationLightDitherPx = 0.0f;
    // Contours
    s.waterContourSizePx = 3.0f;
    s.waterRippleCount = 0;
    s.waterRippleDistancePx = 0.0f;
    s.waterContourHue01 = 0.0f;
    s.waterContourSat01 = 0.0f;
    s.waterContourBri01 = 0.0f;
    s.waterContourAlpha01 = 1.0f;
    s.waterCoastAlpha01 = 1.0f;
    s.waterCoastSizePx = 2.0f;
    s.waterCoastScaleWithZoom = true;
    s.waterCoastAboveZones = false;
    s.waterContourScaleWithZoom = true;
    s.waterContourRefZoom = DEFAULT_VIEW_ZOOM;
    s.waterRippleAlphaStart01 = 0.8f;
    s.waterRippleAlphaEnd01 = 0.25f;
    s.waterHatchAngleDeg = 0.0f;
    s.waterHatchLengthPx = 0.0f;
    s.waterHatchSpacingPx = 12.0f;
    s.waterHatchAlpha01 = 0.0f;
    s.elevationLinesCount = 4;
    s.elevationLinesStyle = ElevationLinesStyle.ELEV_LINES_BASIC;
    s.elevationLinesAlpha01 = 0.25f;
    s.elevationLinesSizePx = 1.0f;
    s.elevationLinesScaleWithZoom = true;
    s.elevationLinesRefZoom = DEFAULT_VIEW_ZOOM;
    // Paths
    s.pathSatScale01 = 0.0f;
    s.pathBriScale01 = 1.0f;
    s.showPaths = true;
    s.pathScaleWithZoom = true;
    s.pathScaleRefZoom = DEFAULT_VIEW_ZOOM;
    // Zones
    s.zoneStrokeAlpha01 = 0.7f;
    s.zoneStrokeSizePx = 2.0f;
    s.zoneStrokeSatScale01 = 0.0f;
    s.zoneStrokeBriScale01 = 0.0f;
    s.zoneStrokeScaleWithZoom = true;
    s.zoneStrokeRefZoom = DEFAULT_VIEW_ZOOM;
    // Structures
    s.showStructures = true;
    s.mergeStructures = false;
    s.structureSatScale01 = 0.0f;
    s.structureAlphaScale01 = 1.0f;
    s.structureShadowAlpha01 = 0.25f;
    s.structureStrokeScaleWithZoom = true;
    s.structureStrokeRefZoom = DEFAULT_VIEW_ZOOM;
    // Labels
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
    s.labelScaleWithZoom = true;
    s.labelScaleRefZoom = DEFAULT_VIEW_ZOOM;
    s.labelOutlineScaleWithZoom = true;
    s.labelFontIndex = 0;
    // General
    s.exportPaddingPct = 0.015f;
    s.antialiasing = true;
    s.activePresetIndex = 0;
    list.add(new RenderPreset("Grey", s));
  }

  // Bitmap
  {
    RenderSettings s = new RenderSettings();
    // Base
    s.landHue01 = 0.1f;
    s.landSat01 = 0.0f;
    s.landBri01 = 1.0f;
    s.waterHue01 = 0.0f;
    s.waterSat01 = 0.0f;
    s.waterBri01 = 1.0f;
    s.cellBorderAlpha01 = 0.0f;
    s.cellBorderSizePx = 1.0f;
    s.cellBorderScaleWithZoom = true;
    s.cellBorderRefZoom = DEFAULT_VIEW_ZOOM;
    s.backgroundNoiseAlpha01 = 0.0f;
    // Biomes
    s.biomeFillAlpha01 = 1.0f;
    s.biomeSatScale01 = 0.0f;
    s.biomeBriScale01 = 0.0f;
    s.biomeFillType = RenderFillType.RENDER_FILL_PATTERN;
    s.biomeOutlineSizePx = 1.0f;
    s.biomeOutlineAlpha01 = 0.0f;
    s.biomeOutlineScaleWithZoom = true;
    s.biomeOutlineRefZoom = DEFAULT_VIEW_ZOOM;
    s.biomeUnderwaterAlpha01 = 0.0f;
    // Shading
    s.waterDepthAlpha01 = 0.0f;
    s.elevationLightAlpha01 = 0.0f;
    s.elevationLightAzimuthDeg = 220.0f;
    s.elevationLightAltitudeDeg = 45.0f;
    s.elevationLightDitherPx = 0.0f;
    // Contours
    s.waterContourSizePx = 2.0f;
    s.waterRippleCount = 0;
    s.waterRippleDistancePx = 4.0f;
    s.waterContourHue01 = 0.0f;
    s.waterContourSat01 = 0.0f;
    s.waterContourBri01 = 0.0f;
    s.waterContourAlpha01 = 1.0f;
    s.waterCoastAlpha01 = 1.0f;
    s.waterCoastSizePx = 2.0f;
    s.waterCoastScaleWithZoom = true;
    s.waterCoastAboveZones = false;
    s.waterContourScaleWithZoom = true;
    s.waterContourRefZoom = DEFAULT_VIEW_ZOOM;
    s.waterRippleAlphaStart01 = 0.8f;
    s.waterRippleAlphaEnd01 = 0.25f;
    s.waterHatchAngleDeg = -40.0f;
    s.waterHatchLengthPx = 8.0f;
    s.waterHatchSpacingPx = 4.0f;
    s.waterHatchAlpha01 = 1.0f;
    s.elevationLinesCount = 2;
    s.elevationLinesStyle = ElevationLinesStyle.ELEV_LINES_BASIC;
    s.elevationLinesAlpha01 = 1.0f;
    s.elevationLinesSizePx = 1.0f;
    s.elevationLinesScaleWithZoom = true;
    s.elevationLinesRefZoom = DEFAULT_VIEW_ZOOM;
    // Paths
    s.pathSatScale01 = 0.0f;
    s.pathBriScale01 = 1.0f;
    s.showPaths = true;
    s.pathScaleWithZoom = true;
    s.pathScaleRefZoom = DEFAULT_VIEW_ZOOM;
    // Zones
    s.zoneStrokeAlpha01 = 1.0f;
    s.zoneStrokeSizePx = 2.0f;
    s.zoneStrokeSatScale01 = 0.0f;
    s.zoneStrokeBriScale01 = 0.0f;
    s.zoneStrokeScaleWithZoom = true;
    s.zoneStrokeRefZoom = DEFAULT_VIEW_ZOOM;
    // Structures
    s.showStructures = true;
    s.mergeStructures = false;
    s.structureSatScale01 = 0.0f;
    s.structureAlphaScale01 = 1.0f;
    s.structureShadowAlpha01 = 1.0f;
    s.structureStrokeScaleWithZoom = true;
    s.structureStrokeRefZoom = DEFAULT_VIEW_ZOOM;
    // Labels
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
    s.labelScaleWithZoom = true;
    s.labelScaleRefZoom = DEFAULT_VIEW_ZOOM;
    s.labelOutlineScaleWithZoom = true;
    s.labelFontIndex = 0;
    // General
    s.exportPaddingPct = 0.015f;
    s.antialiasing = false;
    s.activePresetIndex = 0;
    list.add(new RenderPreset("Bitmap", s));
  }

  // Much
  {
    RenderSettings s = new RenderSettings();
    // Base
    s.landHue01 = 0.1f;
    s.landSat01 = 0.1f;
    s.landBri01 = 0.8f;
    s.waterHue01 = 0.6f;
    s.waterSat01 = 0.7f;
    s.waterBri01 = 0.2f;
    s.cellBorderAlpha01 = 0.05f;
    s.cellBorderSizePx = 1.0f;
    s.cellBorderScaleWithZoom = true;
    s.cellBorderRefZoom = DEFAULT_VIEW_ZOOM;
    s.backgroundNoiseAlpha01 = 0.0f;
    // Biomes
    s.biomeFillAlpha01 = 0.3f;
    s.biomeSatScale01 = 0.9f;
    s.biomeBriScale01 = 1.0f;
    s.biomeFillType = RenderFillType.RENDER_FILL_PATTERN;
    s.biomeOutlineSizePx = 2.0f;
    s.biomeOutlineAlpha01 = 0.9f;
    s.biomeOutlineScaleWithZoom = true;
    s.biomeOutlineRefZoom = DEFAULT_VIEW_ZOOM;
    s.biomeUnderwaterAlpha01 = 1.0f;
    // Shading
    s.waterDepthAlpha01 = 1.0f;
    s.elevationLightAlpha01 = 0.4f;
    s.elevationLightAzimuthDeg = 250.0f;
    s.elevationLightAltitudeDeg = 10.0f;
    s.elevationLightDitherPx = 0.0f;
    // Contours
    s.waterContourSizePx = 2.0f;
    s.waterRippleCount = 4;
    s.waterRippleDistancePx = 6.0f;
    s.waterContourHue01 = 0.6f;
    s.waterContourSat01 = 1.0f;
    s.waterContourBri01 = 0.3f;
    s.waterContourAlpha01 = 1.0f;
    s.waterCoastAlpha01 = 1.0f;
    s.waterCoastSizePx = 2.0f;
    s.waterCoastScaleWithZoom = true;
    s.waterCoastAboveZones = false;
    s.waterContourScaleWithZoom = true;
    s.waterContourRefZoom = DEFAULT_VIEW_ZOOM;
    s.waterRippleAlphaStart01 = 0.8f;
    s.waterRippleAlphaEnd01 = 0.25f;
    s.waterHatchAngleDeg = 0.0f;
    s.waterHatchLengthPx = 0.0f;
    s.waterHatchSpacingPx = 12.0f;
    s.waterHatchAlpha01 = 0.0f;
    s.elevationLinesCount = 16;
    s.elevationLinesStyle = ElevationLinesStyle.ELEV_LINES_BASIC;
    s.elevationLinesAlpha01 = 0.3f;
    s.elevationLinesSizePx = 1.0f;
    s.elevationLinesScaleWithZoom = false;
    s.elevationLinesRefZoom = DEFAULT_VIEW_ZOOM;
    // Paths
    s.pathSatScale01 = 1.0f;
    s.pathBriScale01 = 1.0f;
    s.showPaths = true;
    s.pathScaleWithZoom = true;
    s.pathScaleRefZoom = DEFAULT_VIEW_ZOOM;
    // Zones
    s.zoneStrokeAlpha01 = 0.5f;
    s.zoneStrokeSizePx = 2.0f;
    s.zoneStrokeSatScale01 = 0.8f;
    s.zoneStrokeBriScale01 = 0.2f;
    s.zoneStrokeScaleWithZoom = true;
    s.zoneStrokeRefZoom = DEFAULT_VIEW_ZOOM;
    // Structures
    s.showStructures = true;
    s.mergeStructures = true;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.structureShadowAlpha01 = 0.4f;
    s.structureStrokeScaleWithZoom = true;
    s.structureStrokeRefZoom = DEFAULT_VIEW_ZOOM;
    // Labels
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
    s.labelScaleWithZoom = true;
    s.labelScaleRefZoom = DEFAULT_VIEW_ZOOM;
    s.labelOutlineScaleWithZoom = true;
    s.labelFontIndex = 0;
    // General
    s.exportPaddingPct = 0.02f;
    s.antialiasing = true;
    s.activePresetIndex = 0;
    list.add(new RenderPreset("Much", s));
  }

  // Administrative
  {
    RenderSettings s = new RenderSettings();
    // Base
    s.landHue01 = 0.2f;
    s.landSat01 = 0.0f;
    s.landBri01 = 1.0f;
    s.waterHue01 = 0.6f;
    s.waterSat01 = 0.7f;
    s.waterBri01 = 0.5f;
    s.cellBorderAlpha01 = 0.0f;
    s.cellBorderSizePx = 1.0f;
    s.cellBorderScaleWithZoom = true;
    s.cellBorderRefZoom = DEFAULT_VIEW_ZOOM;
    s.backgroundNoiseAlpha01 = 0.0f;
    // Biomes
    s.biomeFillAlpha01 = 0.3f;
    s.biomeSatScale01 = 0.3f;
    s.biomeBriScale01 = 1.0f;
    s.biomeFillType = RenderFillType.RENDER_FILL_COLOR;
    s.biomeOutlineSizePx = 1.0f;
    s.biomeOutlineAlpha01 = 0.0f;
    s.biomeOutlineScaleWithZoom = true;
    s.biomeOutlineRefZoom = DEFAULT_VIEW_ZOOM;
    s.biomeUnderwaterAlpha01 = 1.0f;
    // Shading
    s.waterDepthAlpha01 = 0.0f;
    s.elevationLightAlpha01 = 0.0f;
    s.elevationLightAzimuthDeg = 0.0f;
    s.elevationLightAltitudeDeg = 10.0f;
    s.elevationLightDitherPx = 0.0f;
    // Contours
    s.waterContourSizePx = 2.0f;
    s.waterRippleCount = 0;
    s.waterRippleDistancePx = 0.0f;
    s.waterContourHue01 = 0.5f;
    s.waterContourSat01 = 0.25f;
    s.waterContourBri01 = 0.0f;
    s.waterContourAlpha01 = 0.5f;
    s.waterCoastAlpha01 = 0.5f;
    s.waterCoastSizePx = 2.0f;
    s.waterCoastScaleWithZoom = true;
    s.waterCoastAboveZones = false;
    s.waterContourScaleWithZoom = true;
    s.waterContourRefZoom = DEFAULT_VIEW_ZOOM;
    s.waterRippleAlphaStart01 = 0.35f;
    s.waterRippleAlphaEnd01 = 0.15f;
    s.waterHatchAngleDeg = 0.0f;
    s.waterHatchLengthPx = 0.0f;
    s.waterHatchSpacingPx = 12.0f;
    s.waterHatchAlpha01 = 0.0f;
    s.elevationLinesCount = 0;
    s.elevationLinesStyle = ElevationLinesStyle.ELEV_LINES_BASIC;
    s.elevationLinesAlpha01 = 0.1f;
    s.elevationLinesSizePx = 1.0f;
    s.elevationLinesScaleWithZoom = true;
    s.elevationLinesRefZoom = DEFAULT_VIEW_ZOOM;
    // Paths
    s.pathSatScale01 = 0.8f;
    s.pathBriScale01 = 1.0f;
    s.showPaths = true;
    s.pathScaleWithZoom = true;
    s.pathScaleRefZoom = DEFAULT_VIEW_ZOOM;
    // Zones
    s.zoneStrokeAlpha01 = 1.0f;
    s.zoneStrokeSizePx = 2.0f;
    s.zoneStrokeSatScale01 = 1.0f;
    s.zoneStrokeBriScale01 = 1.0f;
    s.zoneStrokeScaleWithZoom = true;
    s.zoneStrokeRefZoom = DEFAULT_VIEW_ZOOM;
    // Structures
    s.showStructures = true;
    s.mergeStructures = true;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.structureShadowAlpha01 = 0.2f;
    s.structureStrokeScaleWithZoom = true;
    s.structureStrokeRefZoom = DEFAULT_VIEW_ZOOM;
    // Labels
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
    s.labelScaleWithZoom = true;
    s.labelScaleRefZoom = DEFAULT_VIEW_ZOOM;
    s.labelOutlineScaleWithZoom = true;
    s.labelFontIndex = 0;
    // General
    s.exportPaddingPct = 0.015f;
    s.antialiasing = true;
    s.activePresetIndex = 0;
    list.add(new RenderPreset("Administrative", s));
  }

  // Simple
  {
    RenderSettings s = new RenderSettings();
    // Base
    s.landHue01 = 0.1f;
    s.landSat01 = 0.1f;
    s.landBri01 = 1.0f;
    s.waterHue01 = 0.6f;
    s.waterSat01 = 0.7f;
    s.waterBri01 = 0.5f;
    s.cellBorderAlpha01 = 0.0f;
    s.cellBorderSizePx = 1.0f;
    s.cellBorderScaleWithZoom = true;
    s.cellBorderRefZoom = DEFAULT_VIEW_ZOOM;
    s.backgroundNoiseAlpha01 = 0.0f;
    // Biomes
    s.biomeFillAlpha01 = 1.0f;
    s.biomeSatScale01 = 1.0f;
    s.biomeBriScale01 = 1.0f;
    s.biomeFillType = RenderFillType.RENDER_FILL_COLOR;
    s.biomeOutlineSizePx = 1.0f;
    s.biomeOutlineAlpha01 = 0.0f;
    s.biomeOutlineScaleWithZoom = true;
    s.biomeOutlineRefZoom = DEFAULT_VIEW_ZOOM;
    s.biomeUnderwaterAlpha01 = 0.0f;
    // Shading
    s.waterDepthAlpha01 = 0.0f;
    s.elevationLightAlpha01 = 0.0f;
    s.elevationLightAzimuthDeg = 0.0f;
    s.elevationLightAltitudeDeg = 10.0f;
    s.elevationLightDitherPx = 0.0f;
    // Contours
    s.waterContourSizePx = 3.0f;
    s.waterRippleCount = 0;
    s.waterRippleDistancePx = 0.0f;
    s.waterContourHue01 = 0.5f;
    s.waterContourSat01 = 0.25f;
    s.waterContourBri01 = 0.0f;
    s.waterContourAlpha01 = 1.0f;
    s.waterCoastAlpha01 = 1.0f;
    s.waterCoastSizePx = 2.0f;
    s.waterCoastScaleWithZoom = true;
    s.waterCoastAboveZones = false;
    s.waterContourScaleWithZoom = true;
    s.waterContourRefZoom = DEFAULT_VIEW_ZOOM;
    s.waterRippleAlphaStart01 = 0.8f;
    s.waterRippleAlphaEnd01 = 0.25f;
    s.waterHatchAngleDeg = 0.0f;
    s.waterHatchLengthPx = 0.0f;
    s.waterHatchSpacingPx = 12.0f;
    s.waterHatchAlpha01 = 0.0f;
    s.elevationLinesCount = 0;
    s.elevationLinesStyle = ElevationLinesStyle.ELEV_LINES_BASIC;
    s.elevationLinesAlpha01 = 1.0f;
    s.elevationLinesSizePx = 1.0f;
    s.elevationLinesScaleWithZoom = true;
    s.elevationLinesRefZoom = DEFAULT_VIEW_ZOOM;
    // Paths
    s.pathSatScale01 = 0.8f;
    s.pathBriScale01 = 1.0f;
    s.showPaths = false;
    s.pathScaleWithZoom = true;
    s.pathScaleRefZoom = DEFAULT_VIEW_ZOOM;
    // Zones
    s.zoneStrokeAlpha01 = 1.0f;
    s.zoneStrokeSizePx = 2.0f;
    s.zoneStrokeSatScale01 = 1.0f;
    s.zoneStrokeBriScale01 = 1.0f;
    s.zoneStrokeScaleWithZoom = true;
    s.zoneStrokeRefZoom = DEFAULT_VIEW_ZOOM;
    // Structures
    s.showStructures = false;
    s.mergeStructures = true;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.structureShadowAlpha01 = 0.2f;
    s.structureStrokeScaleWithZoom = true;
    s.structureStrokeRefZoom = DEFAULT_VIEW_ZOOM;
    // Labels
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
    s.labelScaleWithZoom = true;
    s.labelScaleRefZoom = DEFAULT_VIEW_ZOOM;
    s.labelOutlineScaleWithZoom = true;
    s.labelFontIndex = 0;
    // General
    s.exportPaddingPct = 0.015f;
    s.antialiasing = true;
    s.activePresetIndex = 0;
    list.add(new RenderPreset("Simple", s));
  }

  // Rocky
  {
    RenderSettings s = new RenderSettings();
    // Base
    s.landHue01 = 0.7f;
    s.landSat01 = 1.0f;
    s.landBri01 = 0.4f;
    s.waterHue01 = 0.1f;
    s.waterSat01 = 1.0f;
    s.waterBri01 = 1.0f;
    s.cellBorderAlpha01 = 0.8f;
    s.cellBorderSizePx = 1.0f;
    s.cellBorderScaleWithZoom = false;
    s.cellBorderRefZoom = DEFAULT_VIEW_ZOOM;
    s.backgroundNoiseAlpha01 = 0.0f;
    // Biomes
    s.biomeFillAlpha01 = 0.7f;
    s.biomeSatScale01 = 1.0f;
    s.biomeBriScale01 = 1.0f;
    s.biomeFillType = RenderFillType.RENDER_FILL_PATTERN;
    s.biomeOutlineSizePx = 4.0f;
    s.biomeOutlineAlpha01 = 0.3f;
    s.biomeOutlineScaleWithZoom = true;
    s.biomeOutlineRefZoom = DEFAULT_VIEW_ZOOM;
    s.biomeUnderwaterAlpha01 = 0.0f;
    // Shading
    s.waterDepthAlpha01 = 0.6f;
    s.elevationLightAlpha01 = 1.0f;
    s.elevationLightAzimuthDeg = 300.0f;
    s.elevationLightAltitudeDeg = 70.0f;
    s.elevationLightDitherPx = 0.0f;
    // Contours
    s.waterContourSizePx = 4.0f;
    s.waterRippleCount = 5;
    s.waterRippleDistancePx = 20.0f;
    s.waterContourHue01 = 0.1f;
    s.waterContourSat01 = 1.0f;
    s.waterContourBri01 = 1.0f;
    s.waterContourAlpha01 = 1.0f;
    s.waterCoastAlpha01 = 1.0f;
    s.waterCoastSizePx = 2.0f;
    s.waterCoastScaleWithZoom = true;
    s.waterCoastAboveZones = false;
    s.waterContourScaleWithZoom = true;
    s.waterContourRefZoom = DEFAULT_VIEW_ZOOM;
    s.waterRippleAlphaStart01 = 0.8f;
    s.waterRippleAlphaEnd01 = 0.25f;
    s.waterHatchAngleDeg = 0.0f;
    s.waterHatchLengthPx = 0.0f;
    s.waterHatchSpacingPx = 12.0f;
    s.waterHatchAlpha01 = 0.0f;
    s.elevationLinesCount = 24;
    s.elevationLinesStyle = ElevationLinesStyle.ELEV_LINES_BASIC;
    s.elevationLinesAlpha01 = 1.0f;
    s.elevationLinesSizePx = 1.0f;
    s.elevationLinesScaleWithZoom = true;
    s.elevationLinesRefZoom = DEFAULT_VIEW_ZOOM;
    // Paths
    s.pathSatScale01 = 0.3f;
    s.pathBriScale01 = 1.0f;
    s.showPaths = false;
    s.pathScaleWithZoom = false;
    s.pathScaleRefZoom = DEFAULT_VIEW_ZOOM;
    // Zones
    s.zoneStrokeAlpha01 = 1.0f;
    s.zoneStrokeSizePx = 2.0f;
    s.zoneStrokeSatScale01 = 0.3f;
    s.zoneStrokeBriScale01 = 0.5f;
    s.zoneStrokeScaleWithZoom = false;
    s.zoneStrokeRefZoom = DEFAULT_VIEW_ZOOM;
    // Structures
    s.showStructures = false;
    s.mergeStructures = true;
    s.structureSatScale01 = 1.0f;
    s.structureAlphaScale01 = 1.0f;
    s.structureShadowAlpha01 = 0.25f;
    s.structureStrokeScaleWithZoom = false;
    s.structureStrokeRefZoom = DEFAULT_VIEW_ZOOM;
    // Labels
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
    s.labelScaleWithZoom = true;
    s.labelScaleRefZoom = DEFAULT_VIEW_ZOOM;
    s.labelOutlineScaleWithZoom = true;
    s.labelFontIndex = 0;
    // General
    s.exportPaddingPct = 0.0f;
    s.antialiasing = true;
    s.activePresetIndex = 0;
    list.add(new RenderPreset("Rocky", s));
  }

  RenderPreset[] arr = new RenderPreset[list.size()];
  list.toArray(arr);
  return arr;
}
