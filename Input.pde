void handlePathsMousePressed(float wx, float wy) {
  if (mapModel.paths.isEmpty()) {
    Path np = new Path();
    np.typeId = activePathTypeIndex;
    np.name = "Path " + (mapModel.paths.size() + 1);
    mapModel.paths.add(np);
    selectedPathIndex = 0;
  } else if (selectedPathIndex < 0 || selectedPathIndex >= mapModel.paths.size()) {
    selectedPathIndex = 0;
  }
  wx = constrain(wx, mapModel.minX, mapModel.maxX);
  wy = constrain(wy, mapModel.minY, mapModel.maxY);

  // Always snap to the nearest available point; skip if none
  PVector snapped = findNearestSnappingPoint(wx, wy, Float.MAX_VALUE);
  if (snapped == null) return;
  PVector target = snapped;
  println("[PATH] click at (" + wx + "," + wy + ") snapped to (" + target.x + "," + target.y + ")");

  if (pendingPathStart == null) {
    pendingPathStart = target;
    println("[PATH] start set at (" + target.x + "," + target.y + ")");
    return;
  }

  // Ignore zero-length
  if (dist(pendingPathStart.x, pendingPathStart.y, target.x, target.y) < 1e-6f) {
    pendingPathStart = null;
    return;
  }

  Path targetPath = mapModel.paths.get(selectedPathIndex);
  ArrayList<PVector> route = null;
  if (pendingPathStart != null) {
    PathRouteMode mode = currentPathRouteMode();
    if (mode == PathRouteMode.ENDS) {
      route = new ArrayList<PVector>();
      route.add(pendingPathStart.copy());
      route.add(target.copy());
      println("[PATH] route ENDS size=" + route.size());
    } else if (mode == PathRouteMode.PATHFIND) {
      ArrayList<PVector> rp = mapModel.findSnapPathFlattest(pendingPathStart, target);
      if (rp != null && rp.size() > 1) route = rp;
      println("[PATH] route PATHFIND size=" + ((route != null) ? route.size() : 0));
    }
    if (route == null) {
      route = new ArrayList<PVector>();
      route.add(pendingPathStart.copy());
      route.add(target.copy());
      println("[PATH] fallback route size=" + route.size());
    }
  }

  if (targetPath != null) {
    if (targetPath.routes.isEmpty()) {
      targetPath.typeId = activePathTypeIndex;
    }
    mapModel.appendRouteToPath(targetPath, route);
    println("[PATH] appended route points=" + route.size() + " to path#" + selectedPathIndex);
  }
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
      if (currentZonePaintMode == ZonePaintMode.ZONE_PAINT) {
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
  }
}

void mouseReleased() {
  isPanning = false;
  if (mouseButton == LEFT) {
    isDraggingSite = false;
    draggingSite = null;
    if (siteDirtyDuringDrag) {
      mapModel.markVoronoiDirty();
      siteDirtyDuringDrag = false;
    }
    activeSlider = SLIDER_NONE;
  }
}

void updateActiveSlider(int mx, int my) {
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
    case SLIDER_BIOME_BRUSH: {
      BiomesLayout l = buildBiomesLayout();
      float t = (mx - l.brushSlider.x) / (float)l.brushSlider.w;
      t = constrain(t, 0, 1);
      zoneBrushRadius = constrain(0.01f + t * (0.15f - 0.01f), 0.01f, 0.15f);
      break;
    }
    case SLIDER_ELEV_SEA: {
      ElevationLayout l = buildElevationLayout();
      float t = (mx - l.seaSlider.x) / (float)l.seaSlider.w;
      t = constrain(t, 0, 1);
      seaLevel = t * 1.0f - 0.5f;
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
    case SLIDER_STRUCT_SIZE: {
      StructuresLayout l = buildStructuresLayout();
      float t = (mx - l.sizeSlider.x) / (float)l.sizeSlider.w;
      t = constrain(t, 0, 1);
      structureSize = constrain(0.01f + t * (0.2f - 0.01f), 0.01f, 0.2f);
      break;
    }
    case SLIDER_STRUCT_ANGLE: {
      StructuresLayout l = buildStructuresLayout();
      float t = (mx - l.angleSlider.x) / (float)l.angleSlider.w;
      t = constrain(t, 0, 1);
      float angDeg = -180.0f + t * 360.0f;
      structureAngleOffsetRad = radians(angDeg);
      break;
    }
    case SLIDER_STRUCT_RATIO: {
      StructuresLayout l = buildStructuresLayout();
      float t = constrain((mx - l.ratioSlider.x) / (float)l.ratioSlider.w, 0, 1);
      structureAspectRatio = constrain(0.3f + t * (3.0f - 0.3f), 0.3f, 3.0f);
      break;
    }
    case SLIDER_RENDER_LIGHT_AZIMUTH: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.lightAzimuthSlider.x) / (float)l.lightAzimuthSlider.w, 0, 1);
      renderLightAzimuthDeg = constrain(t * 360.0f, 0, 360);
      break;
    }
    case SLIDER_RENDER_LIGHT_ALTITUDE: {
      RenderLayout l = buildRenderLayout();
      float t = constrain((mx - l.lightAltitudeSlider.x) / (float)l.lightAltitudeSlider.w, 0, 1);
      renderLightAltitudeDeg = constrain(5.0f + t * (80.0f - 5.0f), 5.0f, 80.0f);
      break;
    }
    default:
      break;
  }
}

void mouseWheel(MouseEvent event) {
  float count = event.getCount();
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



