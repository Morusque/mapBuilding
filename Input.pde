void handlePathsMousePressed(float wx, float wy) {
  if (mapModel.paths.isEmpty()) {
    Path np = new Path();
    np.typeId = activePathTypeIndex;
    np.name = mapModel.defaultPathNameForType(np.typeId);
    mapModel.paths.add(np);
    selectedPathIndex = 0;
  }
  wx = constrain(wx, mapModel.minX, mapModel.maxX);
  wy = constrain(wy, mapModel.minY, mapModel.maxY);

  // Always snap to the nearest available point; skip if none
  PVector snapped = findNearestSnappingPoint(wx, wy, Float.MAX_VALUE);
  if (snapped == null) return;
  PVector target = snapped;

  if (pendingPathStart == null) {
    pendingPathStart = target;
    return;
  }

  // Ignore zero-length
  if (dist(pendingPathStart.x, pendingPathStart.y, target.x, target.y) < 1e-6f) {
    pendingPathStart = null;
    return;
  }

  Path targetPath = (selectedPathIndex >= 0 && selectedPathIndex < mapModel.paths.size())
                    ? mapModel.paths.get(selectedPathIndex)
                    : null;
  ArrayList<PVector> route = new ArrayList<PVector>();
  if (pendingPathStart != null) {
    PathRouteMode mode = currentPathRouteMode();
    if (mode == PathRouteMode.ENDS) {
      route.add(pendingPathStart.copy());
      route.add(target.copy());
    } else if (mode == PathRouteMode.PATHFIND) {
      ArrayList<PVector> rp = mapModel.findSnapPathFlattest(pendingPathStart, target);
      if (rp != null && rp.size() > 1) route = rp;
    }
    if (route.isEmpty()) {
      route = new ArrayList<PVector>();
      route.add(pendingPathStart.copy());
      route.add(target.copy());
    }
  }

  if (targetPath == null) {
    Path np = new Path();
    np.typeId = activePathTypeIndex;
    np.name = mapModel.defaultPathNameForType(np.typeId);
    mapModel.paths.add(np);
    selectedPathIndex = mapModel.paths.size() - 1;
    targetPath = np;
  }

  if (targetPath.routes.isEmpty()) {
    targetPath.typeId = activePathTypeIndex;
  }
  mapModel.appendRouteToPath(targetPath, route);
  pendingPathStart = null;
}

void mouseDragged() {
  if (isPanning) {
    int dx = mouseX - lastMouseX;
    int dy = mouseY - lastMouseY;
    viewport.panScreen(dx, dy);
    lastMouseX = mouseX;
    lastMouseY = mouseY;
    return;
  }

   // If a slider is active, keep updating that slider only
  if (mouseButton == LEFT && activeSlider != SLIDER_NONE) {
    updateActiveSlider(mouseX, mouseY);
    return;
  }

  // Dragging sliders in Sites panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_SITES && isInSitesPanel(mouseX, mouseY)) {
    SitesLayout layout = buildSitesLayout();
    if (layout.densitySlider.contains(mouseX, mouseY)) {
      float t = (mouseX - layout.densitySlider.x) / (float)layout.densitySlider.w;
      int newCount = round(t * MAX_SITE_COUNT);
      siteTargetCount = constrain(newCount, 0, MAX_SITE_COUNT);
      return;
    }

    if (layout.fuzzSlider.contains(mouseX, mouseY)) {
      float t = (mouseX - layout.fuzzSlider.x) / (float)layout.fuzzSlider.w;
      t = constrain(t, 0, 1);
      siteFuzz = t * 0.3f;
      return;
    }

    if (layout.modeSlider.contains(mouseX, mouseY)) {
      int modeCount = placementModes.length;
      if (modeCount < 1) modeCount = 1;
      float t = (mouseX - layout.modeSlider.x) / (float)layout.modeSlider.w;
      t = constrain(t, 0, 1);
      int idx = round(t * (modeCount - 1));
      placementModeIndex = constrain(idx, 0, placementModes.length - 1);
      return;
    }

    return;
  }

  // Elevation: sliders dragging
  if (mouseButton == LEFT && currentTool == Tool.EDIT_ELEVATION && isInElevationPanel(mouseX, mouseY)) {
    ElevationLayout layout = buildElevationLayout();
    if (layout.seaSlider.contains(mouseX, mouseY)) {
      float t = constrain((mouseX - layout.seaSlider.x) / (float)layout.seaSlider.w, 0, 1);
      seaLevel = t * 1.0f - 0.5f;
      return;
    }
    if (layout.radiusSlider.contains(mouseX, mouseY)) {
      float t = constrain((mouseX - layout.radiusSlider.x) / (float)layout.radiusSlider.w, 0, 1);
      elevationBrushRadius = constrain(0.01f + t * (0.2f - 0.01f), 0.01f, 0.2f);
      return;
    }
    if (layout.strengthSlider.contains(mouseX, mouseY)) {
      float t = constrain((mouseX - layout.strengthSlider.x) / (float)layout.strengthSlider.w, 0, 1);
      elevationBrushStrength = constrain(0.005f + t * (0.2f - 0.005f), 0.005f, 0.2f);
      return;
    }
    if (layout.noiseSlider.contains(mouseX, mouseY)) {
      float t = constrain((mouseX - layout.noiseSlider.x) / (float)layout.noiseSlider.w, 0, 1);
      elevationNoiseScale = constrain(1.0f + t * (12.0f - 1.0f), 1.0f, 12.0f);
      return;
    }
  }

  // Zones: slider dragging (only for hue + paint while dragging)
  if (mouseButton == LEFT && currentTool == Tool.EDIT_BIOMES && isInBiomesPanel(mouseX, mouseY)) {
    BiomesLayout layout = buildBiomesLayout();
    int n = (mapModel.biomeTypes == null) ? 0 : mapModel.biomeTypes.size();

    if (n > 0 && activeBiomeIndex >= 0 && activeBiomeIndex < n) {
      if (layout.hueSlider.contains(mouseX, mouseY)) {
        float t = (mouseX - layout.hueSlider.x) / (float)layout.hueSlider.w;
        t = constrain(t, 0, 1);
        ZoneType active = mapModel.biomeTypes.get(activeBiomeIndex);
        active.hue01 = t;
        active.updateColorFromHSB();
        activeSlider = SLIDER_BIOME_HUE;
        return;
      }
      if (layout.satSlider != null && layout.satSlider.contains(mouseX, mouseY)) {
        float t = (mouseX - layout.satSlider.x) / (float)layout.satSlider.w;
        t = constrain(t, 0, 1);
        ZoneType active = mapModel.biomeTypes.get(activeBiomeIndex);
        active.sat01 = t;
        active.updateColorFromHSB();
        activeSlider = SLIDER_BIOME_SAT;
        return;
      }
      if (layout.briSlider != null && layout.briSlider.contains(mouseX, mouseY)) {
        float t = (mouseX - layout.briSlider.x) / (float)layout.briSlider.w;
        t = constrain(t, 0, 1);
        ZoneType active = mapModel.biomeTypes.get(activeBiomeIndex);
        active.bri01 = t;
        active.updateColorFromHSB();
        activeSlider = SLIDER_BIOME_BRI;
        return;
      }
    }

    if (layout.brushSlider.contains(mouseX, mouseY)) {
      float t = constrain((mouseX - layout.brushSlider.x) / (float)layout.brushSlider.w, 0, 1);
      zoneBrushRadius = constrain(0.01f + t * (0.15f - 0.01f), 0.01f, 0.15f);
      activeSlider = SLIDER_BIOME_BRUSH;
      return;
    }
  }

  // Zones: paint while dragging (only for Paint mode, outside UI)
  if (mouseButton == LEFT && currentTool == Tool.EDIT_BIOMES) {
    IntRect panel = getActivePanelRect();
    boolean inPanel = (panel != null && panel.contains(mouseX, mouseY));
    if (!inPanel) {
      PVector w = viewport.screenToWorld(mouseX, mouseY);
      if (currentBiomePaintMode == ZonePaintMode.ZONE_PAINT) {
        paintBiomeBrush(w.x, w.y);
      }
    }
    return;
  }

  // Zones: slider dragging
  if (mouseButton == LEFT && currentTool == Tool.EDIT_ZONES && isInZonesPanel(mouseX, mouseY)) {
    ZonesLayout layout = buildZonesLayout();
    if (layout.brushSlider.contains(mouseX, mouseY)) {
      float t = constrain((mouseX - layout.brushSlider.x) / (float)layout.brushSlider.w, 0, 1);
      zoneBrushRadius = constrain(0.01f + t * (0.15f - 0.01f), 0.01f, 0.15f);
      activeSlider = SLIDER_ZONES_BRUSH;
      return;
    }
  }

  // Zones: paint while dragging
  if (mouseButton == LEFT && currentTool == Tool.EDIT_ZONES) {
    IntRect panel = getActivePanelRect();
    boolean inPanel = (panel != null && panel.contains(mouseX, mouseY));
    if (!inPanel) {
      PVector w = viewport.screenToWorld(mouseX, mouseY);
      if (currentZonePaintMode == ZonePaintMode.ZONE_PAINT) {
        paintZoneBrush(w.x, w.y);
      }
    }
    return;
  }

  // Paths: erase while dragging
  if (mouseButton == LEFT && currentTool == Tool.EDIT_PATHS && pathEraserMode) {
    IntRect panel = getActivePanelRect();
    boolean inPanel = (panel != null && panel.contains(mouseX, mouseY));
    if (!inPanel && !isInPathsListPanel(mouseX, mouseY)) {
      PVector w = viewport.screenToWorld(mouseX, mouseY);
      mapModel.erasePathSegments(w.x, w.y, pathEraserRadius);
    }
    return;
  }

  // Export: slider dragging
  if (mouseButton == LEFT && currentTool == Tool.EDIT_EXPORT && isInExportPanel(mouseX, mouseY)) {
    ExportLayout layout = buildExportLayout();
    if (layout.scaleSlider != null && layout.scaleSlider.contains(mouseX, mouseY)) {
      float t = constrain((mouseX - layout.scaleSlider.x) / (float)layout.scaleSlider.w, 0, 1);
      exportScale = constrain(1.0f + t * (4.0f - 1.0f), 1.0f, 4.0f);
      activeSlider = SLIDER_EXPORT_SCALE;
      return;
    }
  }

  // Ignore world if dragging in UI
  if (isInActivePanel(mouseX, mouseY)) return;

  if (mouseButton == LEFT && currentTool == Tool.EDIT_SITES && isDraggingSite && draggingSite != null) {
    PVector worldPos = viewport.screenToWorld(mouseX, mouseY);
    draggingSite.x = constrain(worldPos.x, mapModel.minX, mapModel.maxX);
    draggingSite.y = constrain(worldPos.y, mapModel.minY, mapModel.maxY);
    siteDirtyDuringDrag = true;
  } else if (mouseButton == LEFT && currentTool == Tool.EDIT_ELEVATION) {
    PVector w = viewport.screenToWorld(mouseX, mouseY);
    float dir = elevationBrushRaise ? 1 : -1;
    mapModel.applyElevationBrush(w.x, w.y, elevationBrushRadius, elevationBrushStrength * dir, seaLevel);
    renderContoursDirty = true;
  }
}

void mouseReleased() {
  isPanning = false;
  if (mouseButton == LEFT) {
    runPendingButtonAction(mouseX, mouseY);
    isDraggingSite = false;
    draggingSite = null;
    if (siteDirtyDuringDrag) {
      mapModel.markVoronoiDirty();
      renderContoursDirty = true;
      siteDirtyDuringDrag = false;
    }
    activeSlider = SLIDER_NONE;
  }
}

void updateActiveSlider(int mx, int my) {
  if (my < -99999) return; // retain parameter to avoid unused warning
  switch (activeSlider) {
    case SLIDER_SITES_DENSITY: {
      SitesLayout l = buildSitesLayout();
      float t = (mx - l.densitySlider.x) / (float)l.densitySlider.w;
      int newCount = round(t * MAX_SITE_COUNT);
      siteTargetCount = constrain(newCount, 0, MAX_SITE_COUNT);
      break;
    }
    case SLIDER_SITES_FUZZ: {
      SitesLayout l = buildSitesLayout();
      float t = (mx - l.fuzzSlider.x) / (float)l.fuzzSlider.w;
      t = constrain(t, 0, 1);
      siteFuzz = t * 0.3f;
      break;
    }
    case SLIDER_SITES_MODE: {
      SitesLayout l = buildSitesLayout();
      int modeCount = placementModes.length;
      float t = (mx - l.modeSlider.x) / (float)l.modeSlider.w;
      t = constrain(t, 0, 1);
      int idx = round(t * max(1, modeCount - 1));
      placementModeIndex = constrain(idx, 0, placementModes.length - 1);
      break;
    }
    case SLIDER_BIOME_HUE: {
      BiomesLayout l = buildBiomesLayout();
      float t = (mx - l.hueSlider.x) / (float)l.hueSlider.w;
      t = constrain(t, 0, 1);
      if (mapModel.biomeTypes != null && activeBiomeIndex >= 0 && activeBiomeIndex < mapModel.biomeTypes.size()) {
        ZoneType active = mapModel.biomeTypes.get(activeBiomeIndex);
        active.hue01 = t;
        active.updateColorFromHSB();
      }
      break;
    }
    case SLIDER_BIOME_SAT: {
      BiomesLayout l = buildBiomesLayout();
      float t = (mx - l.satSlider.x) / (float)l.satSlider.w;
      t = constrain(t, 0, 1);
      if (mapModel.biomeTypes != null && activeBiomeIndex >= 0 && activeBiomeIndex < mapModel.biomeTypes.size()) {
        ZoneType active = mapModel.biomeTypes.get(activeBiomeIndex);
        active.sat01 = t;
        active.updateColorFromHSB();
      }
      break;
    }
    case SLIDER_BIOME_BRI: {
      BiomesLayout l = buildBiomesLayout();
      float t = (mx - l.briSlider.x) / (float)l.briSlider.w;
      t = constrain(t, 0, 1);
      if (mapModel.biomeTypes != null && activeBiomeIndex >= 0 && activeBiomeIndex < mapModel.biomeTypes.size()) {
        ZoneType active = mapModel.biomeTypes.get(activeBiomeIndex);
        active.bri01 = t;
        active.updateColorFromHSB();
      }
      break;
    }
    case SLIDER_BIOME_BRUSH: {
      BiomesLayout l = buildBiomesLayout();
      float t = (mx - l.brushSlider.x) / (float)l.brushSlider.w;
      t = constrain(t, 0, 1);
      zoneBrushRadius = constrain(0.01f + t * (0.15f - 0.01f), 0.01f, 0.15f);
      break;
    }
    case SLIDER_BIOME_GEN_MODE: {
      BiomesLayout l = buildBiomesLayout();
      int modeCount = biomeGenerateModes.length;
      float t = (mx - l.genModeSelector.x) / (float)l.genModeSelector.w;
      t = constrain(t, 0, 1);
      int idx = round(t * max(1, modeCount - 1));
      biomeGenerateModeIndex = constrain(idx, 0, modeCount - 1);
      break;
    }
    case SLIDER_BIOME_GEN_VALUE: {
      BiomesLayout l = buildBiomesLayout();
      float t = (mx - l.genValueSlider.x) / (float)l.genValueSlider.w;
      t = constrain(t, 0, 1);
      biomeGenerateValue01 = t;
      break;
    }
    case SLIDER_ELEV_SEA: {
      ElevationLayout l = buildElevationLayout();
      float t = (mx - l.seaSlider.x) / (float)l.seaSlider.w;
      t = constrain(t, 0, 1);
      float newSea = lerp(-1.2f, 1.2f, t);
      if (abs(newSea - seaLevel) > 1e-6f) {
        seaLevel = newSea;
        renderContoursDirty = true;
      }
      break;
    }
    case SLIDER_ELEV_RADIUS: {
      ElevationLayout l = buildElevationLayout();
      float t = (mx - l.radiusSlider.x) / (float)l.radiusSlider.w;
      t = constrain(t, 0, 1);
      elevationBrushRadius = constrain(0.01f + t * (0.2f - 0.01f), 0.01f, 0.2f);
      break;
    }
    case SLIDER_ELEV_STRENGTH: {
      ElevationLayout l = buildElevationLayout();
      float t = (mx - l.strengthSlider.x) / (float)l.strengthSlider.w;
      t = constrain(t, 0, 1);
      elevationBrushStrength = constrain(0.005f + t * (0.2f - 0.005f), 0.005f, 0.2f);
      break;
    }
    case SLIDER_ELEV_NOISE: {
      ElevationLayout l = buildElevationLayout();
      float t = (mx - l.noiseSlider.x) / (float)l.noiseSlider.w;
      t = constrain(t, 0, 1);
      elevationNoiseScale = constrain(1.0f + t * (12.0f - 1.0f), 1.0f, 12.0f);
      break;
    }
    case SLIDER_PATH_TYPE_HUE: {
      PathsLayout l = buildPathsLayout();
      float t = (mx - l.typeHueSlider.x) / (float)l.typeHueSlider.w;
      t = constrain(t, 0, 1);
      if (activePathTypeIndex >= 0 && activePathTypeIndex < mapModel.pathTypes.size()) {
        PathType pt = mapModel.pathTypes.get(activePathTypeIndex);
        pt.hue01 = t;
        pt.updateColorFromHSB();
      }
      break;
    }
    case SLIDER_PATH_TYPE_SAT: {
      PathsLayout l = buildPathsLayout();
      float t = (mx - l.typeSatSlider.x) / (float)l.typeSatSlider.w;
      t = constrain(t, 0, 1);
      if (activePathTypeIndex >= 0 && activePathTypeIndex < mapModel.pathTypes.size()) {
        PathType pt = mapModel.pathTypes.get(activePathTypeIndex);
        pt.sat01 = t;
        pt.updateColorFromHSB();
      }
      break;
    }
    case SLIDER_PATH_TYPE_BRI: {
      PathsLayout l = buildPathsLayout();
      float t = (mx - l.typeBriSlider.x) / (float)l.typeBriSlider.w;
      t = constrain(t, 0, 1);
      if (activePathTypeIndex >= 0 && activePathTypeIndex < mapModel.pathTypes.size()) {
        PathType pt = mapModel.pathTypes.get(activePathTypeIndex);
        pt.bri01 = t;
        pt.updateColorFromHSB();
      }
      break;
    }
    case SLIDER_PATH_TYPE_WEIGHT: {
      PathsLayout l = buildPathsLayout();
      float t = (mx - l.typeWeightSlider.x) / (float)l.typeWeightSlider.w;
      t = constrain(t, 0, 1);
      if (activePathTypeIndex >= 0 && activePathTypeIndex < mapModel.pathTypes.size()) {
        PathType pt = mapModel.pathTypes.get(activePathTypeIndex);
        pt.weightPx = constrain(0.5f + t * (8.0f - 0.5f), 0.5f, 8.0f);
      }
      break;
    }
    case SLIDER_PATH_TYPE_MIN_WEIGHT: {
      PathsLayout l = buildPathsLayout();
      float t = (mx - l.typeMinWeightSlider.x) / (float)l.typeMinWeightSlider.w;
      t = constrain(t, 0, 1);
      if (activePathTypeIndex >= 0 && activePathTypeIndex < mapModel.pathTypes.size()) {
        PathType pt = mapModel.pathTypes.get(activePathTypeIndex);
        float minW = constrain(0.5f + t * (pt.weightPx - 0.5f), 0.5f, pt.weightPx);
        pt.minWeightPx = minW;
      }
      break;
    }
    case SLIDER_ZONES_HUE: {
      // Deprecated: zone hue is edited via list panel per-row slider
      break;
    }
    case SLIDER_ZONES_BRUSH: {
      ZonesLayout l = buildZonesLayout();
      float t = constrain((mx - l.brushSlider.x) / (float)l.brushSlider.w, 0, 1);
      zoneBrushRadius = constrain(0.01f + t * (0.15f - 0.01f), 0.01f, 0.15f);
      break;
    }
    case SLIDER_ZONES_ROW_HUE: {
      ZonesListLayout l = buildZonesListLayout();
      populateZonesRows(l);
      if (activeZoneIndex >= 0 && activeZoneIndex < l.rows.size()) {
        ZoneRowLayout row = l.rows.get(activeZoneIndex);
        float t = constrain((mx - row.hueSlider.x) / (float)row.hueSlider.w, 0, 1);
        MapModel.MapZone az = mapModel.zones.get(activeZoneIndex);
        az.hue01 = t;
        az.updateColorFromHSB();
      }
      break;
    }
    case SLIDER_FLATTEST_BIAS: {
      PathsLayout l = buildPathsLayout();
      float t = (mx - l.flattestSlider.x) / (float)l.flattestSlider.w;
      t = constrain(t, 0, 1);
      flattestSlopeBias = constrain(FLATTEST_BIAS_MIN + t * (FLATTEST_BIAS_MAX - FLATTEST_BIAS_MIN),
                                    FLATTEST_BIAS_MIN, FLATTEST_BIAS_MAX);
      break;
    }
    case SLIDER_STRUCT_SIZE:
    case SLIDER_STRUCT_SELECTED_SIZE: {
      StructuresLayout l = buildStructuresLayout();
      float t = (mx - l.sizeSlider.x) / (float)l.sizeSlider.w;
      t = constrain(t, 0, 1);
      float newSize = constrain(0.01f + t * (0.2f - 0.01f), 0.01f, 0.2f);
      structureSize = newSize;
      if (selectedStructureIndices != null && !selectedStructureIndices.isEmpty()) {
        for (int idx : selectedStructureIndices) {
          if (idx < 0 || idx >= mapModel.structures.size()) continue;
          mapModel.structures.get(idx).size = newSize;
        }
      }
      break;
    }
    case SLIDER_STRUCT_ANGLE:
    case SLIDER_STRUCT_SELECTED_ANGLE: {
      StructuresLayout l = buildStructuresLayout();
      float t = (mx - l.angleSlider.x) / (float)l.angleSlider.w;
      t = constrain(t, 0, 1);
      float angDeg = -180.0f + t * 360.0f;
      float angRad = radians(angDeg);
      structureAngleOffsetRad = angRad;
      if (selectedStructureIndices != null && !selectedStructureIndices.isEmpty()) {
        for (int idx : selectedStructureIndices) {
          if (idx < 0 || idx >= mapModel.structures.size()) continue;
          mapModel.structures.get(idx).angle = angRad;
        }
      }
      break;
    }
    case SLIDER_STRUCT_RATIO: {
      StructuresLayout l = buildStructuresLayout();
      float t = constrain((mx - l.ratioSlider.x) / (float)l.ratioSlider.w, 0, 1);
      float newRatio = constrain(0.3f + t * (3.0f - 0.3f), 0.3f, 3.0f);
      structureAspectRatio = newRatio;
      if (selectedStructureIndices != null && !selectedStructureIndices.isEmpty()) {
        for (int idx : selectedStructureIndices) {
          if (idx < 0 || idx >= mapModel.structures.size()) continue;
          mapModel.structures.get(idx).aspect = newRatio;
        }
      }
      break;
    }
    case SLIDER_STRUCT_SELECTED_HUE: {
      StructuresLayout l = buildStructuresLayout();
      float t = constrain((mx - l.hueSlider.x) / (float)l.hueSlider.w, 0, 1);
      structureHue01 = t;
      if (selectedStructureIndices != null && !selectedStructureIndices.isEmpty()) {
        for (int idx : selectedStructureIndices) {
          if (idx < 0 || idx >= mapModel.structures.size()) continue;
          mapModel.structures.get(idx).setHue(t);
        }
      }
      break;
    }
    case SLIDER_STRUCT_SELECTED_ALPHA: {
      StructuresLayout l = buildStructuresLayout();
      float t = constrain((mx - l.alphaSlider.x) / (float)l.alphaSlider.w, 0, 1);
      structureAlpha01 = t;
      if (selectedStructureIndices != null && !selectedStructureIndices.isEmpty()) {
        for (int idx : selectedStructureIndices) {
          if (idx < 0 || idx >= mapModel.structures.size()) continue;
          mapModel.structures.get(idx).setAlpha(t);
        }
      }
      break;
    }
    case SLIDER_STRUCT_SELECTED_SAT: {
      StructuresLayout l = buildStructuresLayout();
      float t = constrain((mx - l.satSlider.x) / (float)l.satSlider.w, 0, 1);
      structureSat01 = t;
      if (selectedStructureIndices != null && !selectedStructureIndices.isEmpty()) {
        for (int idx : selectedStructureIndices) {
          if (idx < 0 || idx >= mapModel.structures.size()) continue;
          mapModel.structures.get(idx).setSaturation(t);
        }
      }
      break;
    }
    case SLIDER_STRUCT_SELECTED_STROKE: {
      StructuresLayout l = buildStructuresLayout();
      float t = constrain((mx - l.strokeSlider.x) / (float)l.strokeSlider.w, 0, 1);
      float w = constrain(0.5f + t * (4.0f - 0.5f), 0.5f, 4.0f);
      structureStrokePx = w;
      if (selectedStructureIndices != null && !selectedStructureIndices.isEmpty()) {
        for (int idx : selectedStructureIndices) {
          if (idx < 0 || idx >= mapModel.structures.size()) continue;
          mapModel.structures.get(idx).strokeWeightPx = w;
        }
      }
      break;
    }
    case SLIDER_RENDER_LAND_H: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.landHSB[0].x) / (float)l.landHSB[0].w, 0, 1);
      renderSettings.landHue01 = t;
      break;
    }
    case SLIDER_RENDER_LAND_S: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.landHSB[1].x) / (float)l.landHSB[1].w, 0, 1);
      renderSettings.landSat01 = t;
      break;
    }
    case SLIDER_RENDER_LAND_B: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.landHSB[2].x) / (float)l.landHSB[2].w, 0, 1);
      renderSettings.landBri01 = t;
      break;
    }
    case SLIDER_RENDER_WATER_H: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.waterHSB[0].x) / (float)l.waterHSB[0].w, 0, 1);
      renderSettings.waterHue01 = t;
      break;
    }
    case SLIDER_RENDER_WATER_S: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.waterHSB[1].x) / (float)l.waterHSB[1].w, 0, 1);
      renderSettings.waterSat01 = t;
      break;
    }
    case SLIDER_RENDER_WATER_B: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.waterHSB[2].x) / (float)l.waterHSB[2].w, 0, 1);
      renderSettings.waterBri01 = t;
      break;
    }
    case SLIDER_RENDER_CELL_BORDER_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.cellBordersAlphaSlider.x) / (float)l.cellBordersAlphaSlider.w, 0, 1);
      renderSettings.cellBorderAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_BIOME_FILL_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.biomeFillAlphaSlider.x) / (float)l.biomeFillAlphaSlider.w, 0, 1);
      renderSettings.biomeFillAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_BIOME_SAT: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.biomeSatSlider.x) / (float)l.biomeSatSlider.w, 0, 1);
      renderSettings.biomeSatScale01 = t;
      break;
    }
    case SLIDER_RENDER_BIOME_BRI: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.biomeBriSlider.x) / (float)l.biomeBriSlider.w, 0, 1);
      renderSettings.biomeBriScale01 = t;
      break;
    }
    case SLIDER_RENDER_BIOME_OUTLINE_SIZE: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.biomeOutlineSizeSlider.x) / (float)l.biomeOutlineSizeSlider.w, 0, 1);
      renderSettings.biomeOutlineSizePx = constrain(t * 5.0f, 0, 5.0f);
      break;
    }
    case SLIDER_RENDER_BIOME_OUTLINE_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.biomeOutlineAlphaSlider.x) / (float)l.biomeOutlineAlphaSlider.w, 0, 1);
      renderSettings.biomeOutlineAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_BIOME_UNDERWATER_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.biomeUnderwaterAlphaSlider.x) / (float)l.biomeUnderwaterAlphaSlider.w, 0, 1);
      renderSettings.biomeUnderwaterAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_WATER_DEPTH_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.waterDepthAlphaSlider.x) / (float)l.waterDepthAlphaSlider.w, 0, 1);
      renderSettings.waterDepthAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_LIGHT_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.lightAlphaSlider.x) / (float)l.lightAlphaSlider.w, 0, 1);
      renderSettings.elevationLightAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_LIGHT_AZIMUTH: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.lightAzimuthSlider.x) / (float)l.lightAzimuthSlider.w, 0, 1);
      renderSettings.elevationLightAzimuthDeg = constrain(t * 360.0f, 0, 360);
      break;
    }
    case SLIDER_RENDER_LIGHT_ALTITUDE: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.lightAltitudeSlider.x) / (float)l.lightAltitudeSlider.w, 0, 1);
      renderSettings.elevationLightAltitudeDeg = constrain(5.0f + t * (80.0f - 5.0f), 5.0f, 80.0f);
      break;
    }
    case SLIDER_RENDER_WATER_CONTOUR_SIZE: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.waterContourSizeSlider.x) / (float)l.waterContourSizeSlider.w, 0, 1);
      renderSettings.waterContourSizePx = constrain(t * 5.0f, 0, 5.0f);
      break;
    }
    case SLIDER_RENDER_WATER_RIPPLE_COUNT: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.waterRippleCountSlider.x) / (float)l.waterRippleCountSlider.w, 0, 1);
      renderSettings.waterRippleCount = constrain(round(t * 5.0f), 0, 5);
      break;
    }
    case SLIDER_RENDER_WATER_RIPPLE_DIST: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.waterRippleDistanceSlider.x) / (float)l.waterRippleDistanceSlider.w, 0, 1);
      renderSettings.waterRippleDistancePx = constrain(t * 40.0f, 0.0f, 40.0f);
      break;
    }
    case SLIDER_RENDER_WATER_CONTOUR_H: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.waterContourHSB[0].x) / (float)l.waterContourHSB[0].w, 0, 1);
      renderSettings.waterContourHue01 = t;
      break;
    }
    case SLIDER_RENDER_WATER_CONTOUR_S: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.waterContourHSB[1].x) / (float)l.waterContourHSB[1].w, 0, 1);
      renderSettings.waterContourSat01 = t;
      break;
    }
    case SLIDER_RENDER_WATER_CONTOUR_B: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.waterContourHSB[2].x) / (float)l.waterContourHSB[2].w, 0, 1);
      renderSettings.waterContourBri01 = t;
      break;
    }
    case SLIDER_RENDER_WATER_CONTOUR_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.waterContourCoastAlphaSlider.x) / (float)l.waterContourCoastAlphaSlider.w, 0, 1);
      renderSettings.waterCoastAlpha01 = t;
      renderSettings.waterContourAlpha01 = renderSettings.waterCoastAlpha01; // keep legacy field aligned
      break;
    }
    case SLIDER_RENDER_WATER_HATCH_ANGLE: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.waterHatchAngleSlider.x) / (float)l.waterHatchAngleSlider.w, 0, 1);
      renderSettings.waterHatchAngleDeg = constrain(-90.0f + t * 180.0f, -90.0f, 90.0f);
      break;
    }
    case SLIDER_RENDER_WATER_HATCH_LENGTH: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.waterHatchLengthSlider.x) / (float)l.waterHatchLengthSlider.w, 0, 1);
      renderSettings.waterHatchLengthPx = constrain(t * 80.0f, 0, 80);
      break;
    }
    case SLIDER_RENDER_WATER_HATCH_SPACING: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.waterHatchSpacingSlider.x) / (float)l.waterHatchSpacingSlider.w, 0, 1);
      renderSettings.waterHatchSpacingPx = constrain(4.0f + t * (50.0f - 4.0f), 4.0f, 50.0f);
      break;
    }
    case SLIDER_RENDER_WATER_HATCH_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.waterHatchAlphaSlider.x) / (float)l.waterHatchAlphaSlider.w, 0, 1);
      renderSettings.waterHatchAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_WATER_RIPPLE_ALPHA_START: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.waterRippleAlphaStartSlider.x) / (float)l.waterRippleAlphaStartSlider.w, 0, 1);
      renderSettings.waterRippleAlphaStart01 = t;
      break;
    }
    case SLIDER_RENDER_WATER_RIPPLE_ALPHA_END: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.waterRippleAlphaEndSlider.x) / (float)l.waterRippleAlphaEndSlider.w, 0, 1);
      renderSettings.waterRippleAlphaEnd01 = t;
      break;
    }
    case SLIDER_RENDER_ELEV_LINES_COUNT: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.elevationLinesCountSlider.x) / (float)l.elevationLinesCountSlider.w, 0, 1);
      renderSettings.elevationLinesCount = constrain(round(t * 24.0f), 0, 24);
      break;
    }
    case SLIDER_RENDER_ELEV_LINES_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.elevationLinesAlphaSlider.x) / (float)l.elevationLinesAlphaSlider.w, 0, 1);
      renderSettings.elevationLinesAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_PATH_SAT: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.pathSatSlider.x) / (float)l.pathSatSlider.w, 0, 1);
      renderSettings.pathSatScale01 = t;
      break;
    }
    case SLIDER_RENDER_PATH_BRI: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.pathBriSlider.x) / (float)l.pathBriSlider.w, 0, 1);
      renderSettings.pathBriScale01 = t;
      break;
    }
    case SLIDER_RENDER_ZONE_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.zoneAlphaSlider.x) / (float)l.zoneAlphaSlider.w, 0, 1);
      renderSettings.zoneStrokeAlpha01 = t;
      renderShowZoneOutlines = t > 0.001f;
      break;
    }
    case SLIDER_RENDER_ZONE_SIZE: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.zoneSizeSlider.x) / (float)l.zoneSizeSlider.w, 0, 1);
      renderSettings.zoneStrokeSizePx = constrain(t * 5.0f, 0, 5.0f);
      break;
    }
    case SLIDER_RENDER_ZONE_SAT: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.zoneSatSlider.x) / (float)l.zoneSatSlider.w, 0, 1);
      renderSettings.zoneStrokeSatScale01 = t;
      break;
    }
    case SLIDER_RENDER_ZONE_BRI: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.zoneBriSlider.x) / (float)l.zoneBriSlider.w, 0, 1);
      renderSettings.zoneStrokeBriScale01 = t;
      break;
    }
    case SLIDER_RENDER_LIGHT_DITHER: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.lightDitherSlider.x) / (float)l.lightDitherSlider.w, 0, 1);
      renderSettings.elevationLightDitherPx = constrain(t * 10.0f, 0, 10.0f);
      break;
    }
    case SLIDER_RENDER_LABEL_OUTLINE_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.labelsOutlineAlphaSlider.x) / (float)l.labelsOutlineAlphaSlider.w, 0, 1);
      renderSettings.labelOutlineAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_BACKGROUND_NOISE: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.backgroundNoiseSlider.x) / (float)l.backgroundNoiseSlider.w, 0, 1);
      renderSettings.backgroundNoiseAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_STRUCT_SHADOW_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.structuresShadowAlphaSlider.x) / (float)l.structuresShadowAlphaSlider.w, 0, 1);
      renderSettings.structureShadowAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_ELEV_LINES_STYLE: {
      // Only one style for now; keep the slider responsive for consistency.
      renderSettings.elevationLinesStyle = ElevationLinesStyle.ELEV_LINES_BASIC;
      break;
    }
    case SLIDER_RENDER_PADDING: {
      RenderLayout l = buildRenderLayout();
      float t = (mx - l.exportPaddingSlider.x) / (float)l.exportPaddingSlider.w;
      t = constrain(t, 0, 1);
      renderSettings.exportPaddingPct = constrain(t * 0.10f, 0, 0.10f);
      renderPaddingPct = renderSettings.exportPaddingPct;
      break;
    }
    case SLIDER_RENDER_PRESET_SELECT: {
      RenderLayout l = buildRenderLayout();
      if (renderPresets != null && renderPresets.length > 0) {
        int n = max(1, renderPresets.length - 1);
        float t = constrain((mx - l.presetSelector.x) / (float)l.presetSelector.w, 0, 1);
        int idx = constrain(round(t * n), 0, renderPresets.length - 1);
        renderSettings.activePresetIndex = idx;
      }
      break;
    }
    case SLIDER_EXPORT_SCALE: {
      ExportLayout l = buildExportLayout();
      if (l.scaleSlider != null) {
        float t = constrain((mx - l.scaleSlider.x) / (float)l.scaleSlider.w, 0, 1);
        exportScale = constrain(1.0f + t * (4.0f - 1.0f), 1.0f, 4.0f);
      }
      break;
    }
    default:
      break;
  }
}

boolean scrollListIfHovered(float wheelCount) {
  int deltaPx = round(wheelCount * SCROLL_STEP_PX);
  if (deltaPx == 0) return false;

  if (currentTool == Tool.EDIT_ZONES && isInZonesListPanel(mouseX, mouseY)) {
    ZonesListLayout l = buildZonesListLayout();
    int startY = l.newBtn.y + l.newBtn.h + PANEL_SECTION_GAP;
    int viewH = max(0, (l.panel.y + l.panel.h - PANEL_SECTION_GAP) - startY);
    int rowH = 28;
    int rowGap = 6;
    int total = (mapModel != null && mapModel.zones != null) ? mapModel.zones.size() : 0;
    int contentH = (total > 0) ? total * (rowH + rowGap) - rowGap : 0;
    if (contentH > viewH && viewH > 0) {
      zonesListScroll = clampScroll(zonesListScroll + deltaPx, contentH, viewH);
      return true;
    }
  }

  if (currentTool == Tool.EDIT_PATHS && isInPathsListPanel(mouseX, mouseY)) {
    PathsListLayout l = buildPathsListLayout();
    int startY = l.newBtn.y + l.newBtn.h + PANEL_SECTION_GAP;
    int viewH = max(0, (l.panel.y + l.panel.h - PANEL_SECTION_GAP) - startY);
    int textH = ceil(textAscent() + textDescent());
    int nameH = max(PANEL_LABEL_H + 6, textH + 8);
    int typeH = max(PANEL_LABEL_H + 2, textH + 6);
    int statsH = max(PANEL_LABEL_H, textH);
    int rowGap = 10;
    int rowTotal = nameH + 6 + typeH + 4 + statsH + rowGap;
    int total = (mapModel != null && mapModel.paths != null) ? mapModel.paths.size() : 0;
    int contentH = (total > 0) ? total * rowTotal : 0;
    if (contentH > viewH && viewH > 0) {
      pathsListScroll = clampScroll(pathsListScroll + deltaPx, contentH, viewH);
      return true;
    }
  }

  if (currentTool == Tool.EDIT_STRUCTURES && isInStructuresListPanel(mouseX, mouseY)) {
    StructuresListLayout l = buildStructuresListLayout();
    int startY = layoutStructureDetails(l);
    int viewH = max(0, (l.panel.y + l.panel.h - PANEL_SECTION_GAP) - startY);
    int rowH = 24;
    int rowGap = 6;
    int total = (mapModel != null && mapModel.structures != null) ? mapModel.structures.size() : 0;
    int contentH = (total > 0) ? total * (rowH + rowGap) - rowGap : 0;
    if (contentH > viewH && viewH > 0) {
      structuresListScroll = clampScroll(structuresListScroll + deltaPx, contentH, viewH);
      return true;
    }
  }

  if (currentTool == Tool.EDIT_LABELS && isInLabelsListPanel(mouseX, mouseY)) {
    LabelsListLayout l = buildLabelsListLayout();
    int startY = l.deselectBtn.y + l.deselectBtn.h + PANEL_SECTION_GAP + 6;
    int viewH = max(0, (l.panel.y + l.panel.h - PANEL_SECTION_GAP) - startY);
    int rowH = 24;
    int rowGap = 6;
    int total = (mapModel != null && mapModel.labels != null) ? mapModel.labels.size() : 0;
    int contentH = (total > 0) ? total * (rowH + rowGap) - rowGap : 0;
    if (contentH > viewH && viewH > 0) {
      labelsListScroll = clampScroll(labelsListScroll + deltaPx, contentH, viewH);
      return true;
    }
  }

  return false;
}

void mouseWheel(MouseEvent event) {
  float count = event.getCount();
  if (scrollListIfHovered(count)) return;
  float factor = pow(1.1f, -count);
  viewport.zoomAt(factor, mouseX, mouseY);
}

void keyPressed() {
  // Inline text editing for zones
  if (editingBiomeNameIndex >= 0) {
    if (key == ENTER || key == RETURN) {
      if (editingBiomeNameIndex < mapModel.biomeTypes.size()) {
        mapModel.biomeTypes.get(editingBiomeNameIndex).name = biomeNameDraft;
      }
      editingBiomeNameIndex = -1;
      return;
    } else if (key == BACKSPACE || key == DELETE) {
      if (biomeNameDraft.length() > 0) biomeNameDraft = biomeNameDraft.substring(0, biomeNameDraft.length() - 1);
      return;
    } else if (key >= 32) {
      biomeNameDraft += key;
      return;
    }
  }

  // Inline text editing for zones
  if (editingZoneNameIndex >= 0) {
    if (key == ENTER || key == RETURN) {
      if (editingZoneNameIndex < mapModel.zones.size()) {
        mapModel.zones.get(editingZoneNameIndex).name = zoneNameDraft;
      }
      editingZoneNameIndex = -1;
      return;
    } else if (key == BACKSPACE || key == DELETE) {
      if (zoneNameDraft.length() > 0) zoneNameDraft = zoneNameDraft.substring(0, zoneNameDraft.length() - 1);
      return;
    } else if (key >= 32) {
      zoneNameDraft += key;
      return;
    }
  }

  // Inline text editing for zone comment (single-line)
  if (editingZoneComment) {
    if (key == ENTER || key == RETURN) {
      if (activeZoneIndex >= 0 && activeZoneIndex < mapModel.zones.size()) {
        mapModel.zones.get(activeZoneIndex).comment = zoneCommentDraft;
      }
      editingZoneComment = false;
      return;
    } else if (key == BACKSPACE || key == DELETE) {
      if (zoneCommentDraft.length() > 0) zoneCommentDraft = zoneCommentDraft.substring(0, zoneCommentDraft.length() - 1);
      if (activeZoneIndex >= 0 && activeZoneIndex < mapModel.zones.size()) {
        mapModel.zones.get(activeZoneIndex).comment = zoneCommentDraft;
      }
      return;
    } else if (key >= 32) {
      zoneCommentDraft += key;
      if (activeZoneIndex >= 0 && activeZoneIndex < mapModel.zones.size()) {
        mapModel.zones.get(activeZoneIndex).comment = zoneCommentDraft;
      }
      return;
    }
  }

  // Inline text editing for labels
  if (editingLabelIndex >= 0) {
    if (key == ENTER || key == RETURN) {
      if (editingLabelIndex < mapModel.labels.size()) {
        mapModel.labels.get(editingLabelIndex).text = labelDraft;
      }
      editingLabelIndex = -1;
      return;
    } else if (key == BACKSPACE || key == DELETE) {
      if (labelDraft.length() > 0) labelDraft = labelDraft.substring(0, labelDraft.length() - 1);
      if (editingLabelIndex < mapModel.labels.size()) mapModel.labels.get(editingLabelIndex).text = labelDraft;
      return;
    } else if (key >= 32) {
      labelDraft += key;
      if (editingLabelIndex < mapModel.labels.size()) mapModel.labels.get(editingLabelIndex).text = labelDraft;
      return;
    }
  }

  // Inline text editing for label comment (single-line)
  if (editingLabelCommentIndex >= 0) {
    if (key == ENTER || key == RETURN) {
      if (editingLabelCommentIndex < mapModel.labels.size()) {
        mapModel.labels.get(editingLabelCommentIndex).comment = labelCommentDraft;
      }
      editingLabelCommentIndex = -1;
      return;
    } else if (key == BACKSPACE || key == DELETE) {
      if (labelCommentDraft.length() > 0) labelCommentDraft = labelCommentDraft.substring(0, labelCommentDraft.length() - 1);
      if (editingLabelCommentIndex < mapModel.labels.size() && editingLabelCommentIndex >= 0) {
        mapModel.labels.get(editingLabelCommentIndex).comment = labelCommentDraft;
      }
      return;
    } else if (key >= 32) {
      labelCommentDraft += key;
      if (editingLabelCommentIndex < mapModel.labels.size() && editingLabelCommentIndex >= 0) {
        mapModel.labels.get(editingLabelCommentIndex).comment = labelCommentDraft;
      }
      return;
    }
  }

  // Inline text editing for structures (name)
  if (editingStructureName) {
    if (key == ENTER || key == RETURN) {
      if (selectedStructureIndices != null && !selectedStructureIndices.isEmpty()) {
        for (int idx : selectedStructureIndices) {
          if (idx < 0 || idx >= mapModel.structures.size()) continue;
          mapModel.structures.get(idx).name = structureNameDraft;
        }
      }
      editingStructureName = false;
      editingStructureNameIndex = -1;
      return;
    } else if (key == BACKSPACE || key == DELETE) {
      if (structureNameDraft.length() > 0) structureNameDraft = structureNameDraft.substring(0, structureNameDraft.length() - 1);
      if (selectedStructureIndices != null && !selectedStructureIndices.isEmpty()) {
        for (int idx : selectedStructureIndices) {
          if (idx < 0 || idx >= mapModel.structures.size()) continue;
          mapModel.structures.get(idx).name = structureNameDraft;
        }
      }
      return;
    } else if (key >= 32) {
      structureNameDraft += key;
      if (selectedStructureIndices != null && !selectedStructureIndices.isEmpty()) {
        for (int idx : selectedStructureIndices) {
          if (idx < 0 || idx >= mapModel.structures.size()) continue;
          mapModel.structures.get(idx).name = structureNameDraft;
        }
      }
      return;
    }
  }

  // Inline text editing for structures (comment, single-line)
  if (editingStructureComment) {
    if (key == ENTER || key == RETURN) {
      if (selectedStructureIndices != null && !selectedStructureIndices.isEmpty()) {
        for (int idx : selectedStructureIndices) {
          if (idx < 0 || idx >= mapModel.structures.size()) continue;
          mapModel.structures.get(idx).comment = structureCommentDraft;
        }
      }
      editingStructureComment = false;
      return;
    } else if (key == BACKSPACE || key == DELETE) {
      if (structureCommentDraft.length() > 0) structureCommentDraft = structureCommentDraft.substring(0, structureCommentDraft.length() - 1);
      if (selectedStructureIndices != null && !selectedStructureIndices.isEmpty()) {
        for (int idx : selectedStructureIndices) {
          if (idx < 0 || idx >= mapModel.structures.size()) continue;
          mapModel.structures.get(idx).comment = structureCommentDraft;
        }
      }
      return;
    } else if (key >= 32) {
      structureCommentDraft += key;
      if (selectedStructureIndices != null && !selectedStructureIndices.isEmpty()) {
        for (int idx : selectedStructureIndices) {
          if (idx < 0 || idx >= mapModel.structures.size()) continue;
          mapModel.structures.get(idx).comment = structureCommentDraft;
        }
      }
      return;
    }
  }

  // Inline text editing for structures (type)
  // Structures: sliders dragging
  if (mouseButton == LEFT && currentTool == Tool.EDIT_STRUCTURES && isInStructuresPanel(mouseX, mouseY)) {
    StructuresLayout layout = buildStructuresLayout();
    if (layout.sizeSlider.contains(mouseX, mouseY)) {
      float t = constrain((mouseX - layout.sizeSlider.x) / (float)layout.sizeSlider.w, 0, 1);
      structureSize = constrain(0.01f + t * (0.2f - 0.01f), 0.01f, 0.2f);
      return;
    }
  }

  // Inline text editing for path types
  if (editingPathTypeNameIndex >= 0) {
    if (key == ENTER || key == RETURN) {
      if (editingPathTypeNameIndex < mapModel.pathTypes.size()) {
        mapModel.pathTypes.get(editingPathTypeNameIndex).name = pathTypeNameDraft;
      }
      editingPathTypeNameIndex = -1;
      return;
    } else if (key == BACKSPACE || key == DELETE) {
      if (pathTypeNameDraft.length() > 0) pathTypeNameDraft = pathTypeNameDraft.substring(0, pathTypeNameDraft.length() - 1);
      return;
    } else if (key >= 32) {
      pathTypeNameDraft += key;
      return;
    }
  }

  // Inline text editing for path names
  if (editingPathNameIndex >= 0) {
    if (key == ENTER || key == RETURN) {
      if (editingPathNameIndex < mapModel.paths.size()) {
        mapModel.paths.get(editingPathNameIndex).name = pathNameDraft;
      }
      editingPathNameIndex = -1;
      return;
    } else if (key == BACKSPACE || key == DELETE) {
      if (pathNameDraft.length() > 0) pathNameDraft = pathNameDraft.substring(0, pathNameDraft.length() - 1);
      return;
    } else if (key >= 32) {
      pathNameDraft += key;
      return;
    }
  }
  // Inline text editing for path comment (single-line)
  if (editingPathCommentIndex >= 0) {
    if (key == ENTER || key == RETURN) {
      if (editingPathCommentIndex < mapModel.paths.size()) {
        mapModel.paths.get(editingPathCommentIndex).comment = pathCommentDraft;
      }
      editingPathCommentIndex = -1;
      return;
    } else if (key == BACKSPACE || key == DELETE) {
      if (pathCommentDraft.length() > 0) pathCommentDraft = pathCommentDraft.substring(0, pathCommentDraft.length() - 1);
      if (editingPathCommentIndex < mapModel.paths.size() && editingPathCommentIndex >= 0) {
        mapModel.paths.get(editingPathCommentIndex).comment = pathCommentDraft;
      }
      return;
    } else if (key >= 32) {
      pathCommentDraft += key;
      if (editingPathCommentIndex < mapModel.paths.size() && editingPathCommentIndex >= 0) {
        mapModel.paths.get(editingPathCommentIndex).comment = pathCommentDraft;
      }
      return;
    }
  }
  // Delete selected sites or last path point
  if (key == DELETE || key == BACKSPACE) {
    if (currentTool == Tool.EDIT_SITES) {
      mapModel.deleteSelectedSites();
      return;
    }
    if (currentTool == Tool.EDIT_PATHS && pendingPathStart != null) {
      pendingPathStart = null;
      return;
    }
  }

  // Clear all paths with 'c' or 'C' in Paths mode
  if (currentTool == Tool.EDIT_PATHS &&
      (key == 'c' || key == 'C')) {
    mapModel.clearAllPaths();
    selectedPathIndex = -1;
    pendingPathStart = null;
    return;
  }
}
