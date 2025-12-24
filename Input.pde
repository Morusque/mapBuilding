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
      float t = sliderNorm(layout.seaSlider, mouseX);
      seaLevel = t * 1.0f - 0.5f;
      return;
    }
    if (layout.radiusSlider.contains(mouseX, mouseY)) {
      float t = sliderNorm(layout.radiusSlider, mouseX);
      elevationBrushRadius = constrain(0.01f + t * (0.2f - 0.01f), 0.01f, 0.2f);
      return;
    }
    if (layout.strengthSlider.contains(mouseX, mouseY)) {
      float t = sliderNorm(layout.strengthSlider, mouseX);
      elevationBrushStrength = constrain(0.005f + t * (0.2f - 0.005f), 0.005f, 0.2f);
      return;
    }
    if (layout.noiseSlider.contains(mouseX, mouseY)) {
      float t = sliderNorm(layout.noiseSlider, mouseX);
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
      float t = sliderNorm(layout.brushSlider, mouseX);
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
      float t = sliderNorm(layout.brushSlider, mouseX);
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
      float t = sliderNorm(layout.scaleSlider, mouseX);
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
    markRenderDirty();
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
      markRenderDirty();
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
      float t = sliderNorm(l.densitySlider, mx);
      int newCount = round(t * MAX_SITE_COUNT);
      siteTargetCount = constrain(newCount, 0, MAX_SITE_COUNT);
      break;
    }
    case SLIDER_SITES_FUZZ: {
      SitesLayout l = buildSitesLayout();
      float t = sliderNorm(l.fuzzSlider, mx);
      t = constrain(t, 0, 1);
      siteFuzz = t * 0.3f;
      break;
    }
    case SLIDER_SITES_MODE: {
      SitesLayout l = buildSitesLayout();
      int modeCount = placementModes.length;
      float t = sliderNorm(l.modeSlider, mx);
      t = constrain(t, 0, 1);
      int idx = round(t * max(1, modeCount - 1));
      placementModeIndex = constrain(idx, 0, placementModes.length - 1);
      break;
    }
    case SLIDER_BIOME_HUE: {
      BiomesLayout l = buildBiomesLayout();
      float t = sliderNorm(l.hueSlider, mx);
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
      float t = sliderNorm(l.satSlider, mx);
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
      float t = sliderNorm(l.briSlider, mx);
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
      float t = sliderNorm(l.brushSlider, mx);
      t = constrain(t, 0, 1);
      zoneBrushRadius = constrain(0.01f + t * (0.15f - 0.01f), 0.01f, 0.15f);
      break;
    }
    case SLIDER_BIOME_GEN_MODE: {
      BiomesLayout l = buildBiomesLayout();
      int modeCount = biomeGenerateModes.length;
      float t = sliderNorm(l.genModeSelector, mx);
      t = constrain(t, 0, 1);
      int idx = round(t * max(1, modeCount - 1));
      biomeGenerateModeIndex = constrain(idx, 0, modeCount - 1);
      break;
    }
    case SLIDER_BIOME_GEN_VALUE: {
      BiomesLayout l = buildBiomesLayout();
      float t = sliderNorm(l.genValueSlider, mx);
      t = constrain(t, 0, 1);
      biomeGenerateValue01 = t;
      break;
    }
    case SLIDER_BIOME_PATTERN: {
      BiomesLayout l = buildBiomesLayout();
      if (mapModel.biomeTypes != null && activeBiomeIndex >= 0 && activeBiomeIndex < mapModel.biomeTypes.size()) {
        int patCount = max(1, mapModel.biomePatternCount);
        float t = sliderNorm(l.patternSlider, mx);
        int idx = (patCount > 1) ? round(t * (patCount - 1)) : 0;
        idx = constrain(idx, 0, patCount - 1);
        mapModel.biomeTypes.get(activeBiomeIndex).patternIndex = idx;
      }
      break;
    }
    case SLIDER_ELEV_SEA: {
      ElevationLayout l = buildElevationLayout();
      float t = sliderNorm(l.seaSlider, mx);
      t = constrain(t, 0, 1);
      float newSea = lerp(-1.2f, 1.2f, t);
      if (abs(newSea - seaLevel) > 1e-6f) {
        seaLevel = newSea;
        markRenderDirty();
      }
      break;
    }
    case SLIDER_ELEV_RADIUS: {
      ElevationLayout l = buildElevationLayout();
      float t = sliderNorm(l.radiusSlider, mx);
      t = constrain(t, 0, 1);
      elevationBrushRadius = constrain(0.01f + t * (0.2f - 0.01f), 0.01f, 0.2f);
      break;
    }
    case SLIDER_ELEV_STRENGTH: {
      ElevationLayout l = buildElevationLayout();
      float t = sliderNorm(l.strengthSlider, mx);
      t = constrain(t, 0, 1);
      elevationBrushStrength = constrain(0.005f + t * (0.2f - 0.005f), 0.005f, 0.2f);
      break;
    }
    case SLIDER_ELEV_NOISE: {
      ElevationLayout l = buildElevationLayout();
      float t = sliderNorm(l.noiseSlider, mx);
      t = constrain(t, 0, 1);
      elevationNoiseScale = constrain(1.0f + t * (12.0f - 1.0f), 1.0f, 12.0f);
      break;
    }
    case SLIDER_PATH_TYPE_HUE: {
      PathsLayout l = buildPathsLayout();
      float t = sliderNorm(l.typeHueSlider, mx);
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
      float t = sliderNorm(l.typeSatSlider, mx);
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
      float t = sliderNorm(l.typeBriSlider, mx);
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
      float t = sliderNorm(l.typeWeightSlider, mx);
      t = constrain(t, 0, 1);
      if (activePathTypeIndex >= 0 && activePathTypeIndex < mapModel.pathTypes.size()) {
        PathType pt = mapModel.pathTypes.get(activePathTypeIndex);
        pt.weightPx = constrain(0.5f + t * (8.0f - 0.5f), 0.5f, 8.0f);
      }
      break;
    }
    case SLIDER_PATH_TYPE_MIN_WEIGHT: {
      PathsLayout l = buildPathsLayout();
      float t = sliderNorm(l.typeMinWeightSlider, mx);
      t = constrain(t, 0, 1);
      if (activePathTypeIndex >= 0 && activePathTypeIndex < mapModel.pathTypes.size()) {
        PathType pt = mapModel.pathTypes.get(activePathTypeIndex);
        float minW = constrain(0.5f + t * (pt.weightPx - 0.5f), 0.5f, pt.weightPx);
        pt.minWeightPx = minW;
      }
      break;
    }
    case SLIDER_PATH_ROUTE_MODE: {
      PathsLayout l = buildPathsLayout();
      String[] modes = { "Ends", "Pathfind" };
      int modeCount = modes.length;
      float t = sliderNorm(l.routeSlider, mx);
      int idx = round(t * max(1, modeCount - 1));
      pathRouteModeIndex = constrain(idx, 0, modeCount - 1);
      if (activePathTypeIndex >= 0 && activePathTypeIndex < mapModel.pathTypes.size()) {
        PathType pt = mapModel.pathTypes.get(activePathTypeIndex);
        pt.routeMode = PathRouteMode.values()[pathRouteModeIndex];
      }
      break;
    }
    case SLIDER_ZONES_HUE: {
      // Deprecated: zone hue is edited via list panel per-row slider
      break;
    }
    case SLIDER_ZONES_BRUSH: {
      ZonesLayout l = buildZonesLayout();
      float t = sliderNorm(l.brushSlider, mx);
      zoneBrushRadius = constrain(0.01f + t * (0.15f - 0.01f), 0.01f, 0.15f);
      break;
    }
    case SLIDER_ZONES_ROW_HUE: {
      ZonesListLayout l = buildZonesListLayout();
      populateZonesRows(l);
      if (activeZoneIndex >= 0 && activeZoneIndex < l.rows.size()) {
        ZoneRowLayout row = l.rows.get(activeZoneIndex);
        float t = sliderNorm(row.hueSlider, mx);
        MapModel.MapZone az = mapModel.zones.get(activeZoneIndex);
        az.hue01 = t;
        az.updateColorFromHSB();
      }
      break;
    }
    case SLIDER_FLATTEST_BIAS: {
      PathsLayout l = buildPathsLayout();
      float t = sliderNorm(l.flattestSlider, mx);
      t = constrain(t, 0, 1);
      flattestSlopeBias = constrain(FLATTEST_BIAS_MIN + t * (FLATTEST_BIAS_MAX - FLATTEST_BIAS_MIN),
                                    FLATTEST_BIAS_MIN, FLATTEST_BIAS_MAX);
      break;
    }
    case SLIDER_STRUCT_SIZE:
    case SLIDER_STRUCT_SELECTED_SIZE: {
      StructuresLayout l = buildStructuresLayout();
      float t = sliderNorm(l.sizeSlider, mx);
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
      float t = sliderNorm(l.angleSlider, mx);
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
      float t = sliderNorm(l.ratioSlider, mx);
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
    case SLIDER_STRUCT_GEN_TOWN: {
      StructuresLayout l = buildStructuresLayout();
      float t = sliderNorm(l.genTownSlider, mx);
      structGenTownCount = constrain(round(t * 8), 0, 8);
      break;
    }
    case SLIDER_STRUCT_GEN_BUILDING: {
      StructuresLayout l = buildStructuresLayout();
      float t = sliderNorm(l.genBuildingSlider, mx);
      structGenBuildingDensity = constrain(t, 0, 1);
      break;
    }
    case SLIDER_STRUCT_SNAP_DIV: {
      StructuresLayout l = buildStructuresLayout();
      int divMin = 2;
      int divMax = 24;
      float t = sliderNorm(l.snapElevationSlider, mx);
      snapElevationDivisions = round(lerp(divMin, divMax, t));
      break;
    }
    case SLIDER_STRUCT_SHAPE: {
      StructuresLayout l = buildStructuresLayout();
      StructureShape[] shapes = StructureShape.values();
      float t = sliderNorm(l.shapeSelector, mx);
      int idx = round(t * max(0, shapes.length - 1));
      idx = constrain(idx, 0, shapes.length - 1);
      structureShape = shapes[idx];
      if (selectedStructureIndices != null && !selectedStructureIndices.isEmpty()) {
        for (int si : selectedStructureIndices) {
          if (si < 0 || si >= mapModel.structures.size()) continue;
          mapModel.structures.get(si).shape = structureShape;
        }
      }
      break;
    }
    case SLIDER_STRUCT_ALIGNMENT: {
      StructuresLayout l = buildStructuresLayout();
      StructureSnapMode[] snaps = StructureSnapMode.values();
      float t = sliderNorm(l.alignmentSelector, mx);
      int idx = round(t * max(0, snaps.length - 1));
      idx = constrain(idx, 0, snaps.length - 1);
      structureSnapMode = snaps[idx];
      if (selectedStructureIndices != null && !selectedStructureIndices.isEmpty()) {
        for (int si : selectedStructureIndices) {
          if (si < 0 || si >= mapModel.structures.size()) continue;
          mapModel.structures.get(si).alignment = structureSnapMode;
        }
      }
      break;
    }
    case SLIDER_STRUCT_SELECTED_HUE: {
      StructuresLayout l = buildStructuresLayout();
      float t = sliderNorm(l.hueSlider, mx);
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
      float t = sliderNorm(l.alphaSlider, mx);
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
      float t = sliderNorm(l.satSlider, mx);
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
      float t = sliderNorm(l.strokeSlider, mx);
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
      renderSettings.landHue01 = sliderNorm(l.landHSB[0], mx);
      break;
    }
    case SLIDER_RENDER_LAND_S: {
      RenderLayout l = buildRenderLayout();
      renderSettings.landSat01 = sliderNorm(l.landHSB[1], mx);
      break;
    }
    case SLIDER_RENDER_LAND_B: {
      RenderLayout l = buildRenderLayout();
      renderSettings.landBri01 = sliderNorm(l.landHSB[2], mx);
      break;
    }
    case SLIDER_RENDER_WATER_H: {
      RenderLayout l = buildRenderLayout();
      renderSettings.waterHue01 = sliderNorm(l.waterHSB[0], mx);
      break;
    }
    case SLIDER_RENDER_WATER_S: {
      RenderLayout l = buildRenderLayout();
      renderSettings.waterSat01 = sliderNorm(l.waterHSB[1], mx);
      break;
    }
    case SLIDER_RENDER_WATER_B: {
      RenderLayout l = buildRenderLayout();
      renderSettings.waterBri01 = sliderNorm(l.waterHSB[2], mx);
      break;
    }
    case SLIDER_RENDER_CELL_BORDER_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.cellBordersAlphaSlider, mx);
      renderSettings.cellBorderAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_BIOME_FILL_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.biomeFillAlphaSlider, mx);
      renderSettings.biomeFillAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_BIOME_SAT: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.biomeSatSlider, mx);
      renderSettings.biomeSatScale01 = t;
      break;
    }
    case SLIDER_RENDER_BIOME_BRI: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.biomeBriSlider, mx);
      renderSettings.biomeBriScale01 = t;
      break;
    }
    case SLIDER_RENDER_BIOME_OUTLINE_SIZE: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.biomeOutlineSizeSlider, mx);
      renderSettings.biomeOutlineSizePx = constrain(t * 5.0f, 0, 5.0f);
      break;
    }
    case SLIDER_RENDER_BIOME_OUTLINE_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.biomeOutlineAlphaSlider, mx);
      renderSettings.biomeOutlineAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_BIOME_UNDERWATER_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.biomeUnderwaterAlphaSlider, mx);
      renderSettings.biomeUnderwaterAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_WATER_DEPTH_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.waterDepthAlphaSlider, mx);
      renderSettings.waterDepthAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_LIGHT_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.lightAlphaSlider, mx);
      renderSettings.elevationLightAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_LIGHT_AZIMUTH: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.lightAzimuthSlider, mx);
      renderSettings.elevationLightAzimuthDeg = constrain(t * 360.0f, 0, 360);
      break;
    }
    case SLIDER_RENDER_LIGHT_ALTITUDE: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.lightAltitudeSlider, mx);
      renderSettings.elevationLightAltitudeDeg = constrain(5.0f + t * (80.0f - 5.0f), 5.0f, 80.0f);
      break;
    }
    case SLIDER_RENDER_WATER_CONTOUR_SIZE: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.waterContourSizeSlider, mx);
      renderSettings.waterContourSizePx = constrain(t * 5.0f, 0, 5.0f);
      break;
    }
    case SLIDER_RENDER_WATER_RIPPLE_COUNT: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.waterRippleCountSlider, mx);
      renderSettings.waterRippleCount = constrain(round(t * 5.0f), 0, 5);
      break;
    }
    case SLIDER_RENDER_WATER_RIPPLE_DIST: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.waterRippleDistanceSlider, mx);
      renderSettings.waterRippleDistancePx = constrain(t * 40.0f, 0.0f, 40.0f);
      break;
    }
    case SLIDER_RENDER_WATER_CONTOUR_H: {
      RenderLayout l = buildRenderLayout();
      renderSettings.waterContourHue01 = sliderNorm(l.waterContourHSB[0], mx);
      break;
    }
    case SLIDER_RENDER_WATER_CONTOUR_S: {
      RenderLayout l = buildRenderLayout();
      renderSettings.waterContourSat01 = sliderNorm(l.waterContourHSB[1], mx);
      break;
    }
    case SLIDER_RENDER_WATER_CONTOUR_B: {
      RenderLayout l = buildRenderLayout();
      renderSettings.waterContourBri01 = sliderNorm(l.waterContourHSB[2], mx);
      break;
    }
    case SLIDER_RENDER_WATER_CONTOUR_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.waterContourCoastAlphaSlider, mx);
      renderSettings.waterCoastAlpha01 = t;
      renderSettings.waterContourAlpha01 = renderSettings.waterCoastAlpha01; // keep legacy field aligned
      break;
    }
    case SLIDER_RENDER_WATER_HATCH_ANGLE: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.waterHatchAngleSlider, mx);
      renderSettings.waterHatchAngleDeg = constrain(-90.0f + t * 180.0f, -90.0f, 90.0f);
      break;
    }
    case SLIDER_RENDER_WATER_HATCH_LENGTH: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.waterHatchLengthSlider, mx);
      renderSettings.waterHatchLengthPx = constrain(t * 400.0f, 0, 400.0f);
      break;
    }
    case SLIDER_RENDER_WATER_HATCH_SPACING: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.waterHatchSpacingSlider, mx);
      renderSettings.waterHatchSpacingPx = constrain(t * 120.0f, 0, 120.0f);
      break;
    }
    case SLIDER_RENDER_WATER_HATCH_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.waterHatchAlphaSlider, mx);
      renderSettings.waterHatchAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_WATER_RIPPLE_ALPHA_START: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.waterRippleAlphaStartSlider, mx);
      renderSettings.waterRippleAlphaStart01 = t;
      break;
    }
    case SLIDER_RENDER_WATER_RIPPLE_ALPHA_END: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.waterRippleAlphaEndSlider, mx);
      renderSettings.waterRippleAlphaEnd01 = t;
      break;
    }
    case SLIDER_RENDER_ELEV_LINES_COUNT: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.elevationLinesCountSlider, mx);
      renderSettings.elevationLinesCount = constrain(round(t * 24.0f), 0, 24);
      break;
    }
    case SLIDER_RENDER_ELEV_LINES_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.elevationLinesAlphaSlider, mx);
      renderSettings.elevationLinesAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_PATH_SAT: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.pathSatSlider, mx);
      renderSettings.pathSatScale01 = t;
      break;
    }
    case SLIDER_RENDER_PATH_BRI: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.pathBriSlider, mx);
      renderSettings.pathBriScale01 = t;
      break;
    }
    case SLIDER_RENDER_ZONE_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.zoneAlphaSlider, mx);
      renderSettings.zoneStrokeAlpha01 = t;
      renderShowZoneOutlines = t > 0.001f;
      break;
    }
    case SLIDER_RENDER_ZONE_SIZE: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.zoneSizeSlider, mx);
      renderSettings.zoneStrokeSizePx = constrain(t * 5.0f, 0, 5.0f);
      break;
    }
    case SLIDER_RENDER_ZONE_SAT: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.zoneSatSlider, mx);
      renderSettings.zoneStrokeSatScale01 = t;
      break;
    }
    case SLIDER_RENDER_ZONE_BRI: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.zoneBriSlider, mx);
      renderSettings.zoneStrokeBriScale01 = t;
      break;
    }
    case SLIDER_RENDER_LIGHT_DITHER: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.lightDitherSlider, mx);
      renderSettings.elevationLightDitherPx = constrain(t * 10.0f, 0, 10.0f);
      break;
    }
    case SLIDER_RENDER_LABEL_OUTLINE_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.labelsOutlineAlphaSlider, mx);
      renderSettings.labelOutlineAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_LABEL_OUTLINE_SIZE: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.labelsOutlineSizeSlider, mx);
      renderSettings.labelOutlineSizePx = round(constrain(t * 16.0f, 0, 16.0f));
      break;
    }
    case SLIDER_RENDER_LABEL_SIZE_ARBITRARY: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.labelsArbSizeSlider, mx);
      renderSettings.labelSizeArbPx = round(constrain(8 + t * (40 - 8), 4, 80));
      break;
    }
    case SLIDER_RENDER_LABEL_SIZE_ZONES: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.labelsZoneSizeSlider, mx);
      renderSettings.labelSizeZonePx = round(constrain(8 + t * (40 - 8), 4, 80));
      break;
    }
    case SLIDER_RENDER_LABEL_SIZE_PATHS: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.labelsPathSizeSlider, mx);
      renderSettings.labelSizePathPx = round(constrain(8 + t * (40 - 8), 4, 80));
      break;
    }
    case SLIDER_RENDER_LABEL_SIZE_STRUCTS: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.labelsStructSizeSlider, mx);
      renderSettings.labelSizeStructPx = round(constrain(8 + t * (40 - 8), 4, 80));
      break;
    }
    case SLIDER_RENDER_LABEL_FONT: {
      RenderLayout l = buildRenderLayout();
      int options = (LABEL_FONT_OPTIONS != null) ? LABEL_FONT_OPTIONS.length : 0;
      if (options < 1) break;
      float t = sliderNorm(l.labelsFontSelector, mx);
      int idx = constrain(round(t * max(1, options - 1)), 0, options - 1);
      renderSettings.labelFontIndex = idx;
      break;
    }
    case SLIDER_RENDER_BACKGROUND_NOISE: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.backgroundNoiseSlider, mx);
      renderSettings.backgroundNoiseAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_STRUCT_SHADOW_ALPHA: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.structuresShadowAlphaSlider, mx);
      renderSettings.structureShadowAlpha01 = t;
      break;
    }
    case SLIDER_RENDER_PADDING: {
      RenderLayout l = buildRenderLayout();
      float t = sliderNorm(l.exportPaddingSlider, mx);
      t = constrain(t, 0, 1);
      renderSettings.exportPaddingPct = constrain(t * 0.10f, 0, 0.10f);
      renderPaddingPct = renderSettings.exportPaddingPct;
      break;
    }
    case SLIDER_RENDER_PRESET_SELECT: {
      RenderLayout l = buildRenderLayout();
      if (renderPresets != null && renderPresets.length > 0) {
        int n = max(1, renderPresets.length - 1);
        float t = sliderNorm(l.presetSelector, mx);
        int idx = constrain(round(t * n), 0, renderPresets.length - 1);
        renderSettings.activePresetIndex = idx;
      }
      break;
    }
    case SLIDER_EXPORT_SCALE: {
      ExportLayout l = buildExportLayout();
      if (l.scaleSlider != null) {
        float t = sliderNorm(l.scaleSlider, mx);
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
      float t = sliderNorm(layout.sizeSlider, mouseX);
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
