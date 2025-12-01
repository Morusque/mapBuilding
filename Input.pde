// ---------- Input helpers ----------

boolean isInSitesPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_SITES) return false;
  SitesLayout layout = buildSitesLayout();
  return layout.panel.contains(mx, my);
}

boolean isInZonesPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_BIOMES) return false;
  BiomesLayout layout = buildBiomesLayout();
  return layout.panel.contains(mx, my);
}

boolean isInElevationPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_ELEVATION) return false;
  ElevationLayout layout = buildElevationLayout();
  return layout.panel.contains(mx, my);
}

boolean isInPathsPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_PATHS) return false;
  PathsLayout layout = buildPathsLayout();
  return layout.panel.contains(mx, my);
}

boolean isInPathsListPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_PATHS) return false;
  PathsListLayout layout = buildPathsListLayout();
  return layout.panel.contains(mx, my);
}

boolean isInLabelsPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_LABELS) return false;
  LabelsLayout layout = buildLabelsLayout();
  return layout.panel.contains(mx, my);
}

boolean isInRenderPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_RENDER) return false;
  RenderLayout layout = buildRenderLayout();
  return layout.panel.contains(mx, my);
}

boolean isInActivePanel(int mx, int my) {
  IntRect panel = getActivePanelRect();
  return (panel != null && panel.contains(mx, my));
}

boolean handleToolButtonClick(int mx, int my) {
  int barY = TOP_BAR_HEIGHT;
  int barH = TOOL_BAR_HEIGHT;

  if (my < barY || my > barY + barH) {
    return false;
  }

  int margin = 10;
  int buttonW = 90;

  String[] labels = { "Sites", "Elevation", "Biomes", "Zones", "Paths", "Struct", "Labels", "Rendering" };
  Tool[] tools = {
    Tool.EDIT_SITES,
    Tool.EDIT_ELEVATION,
    Tool.EDIT_BIOMES,
    Tool.EDIT_ADMIN,
    Tool.EDIT_PATHS,
    Tool.EDIT_STRUCTURES,
    Tool.EDIT_LABELS,
    Tool.EDIT_RENDER
  };

  for (int i = 0; i < labels.length; i++) {
    int x = margin + i * (buttonW + 5);
    int y = barY + 2;
    int bx1 = x;
    int by1 = y;
    int bx2 = x + buttonW;
    int by2 = y + (barH - 4);
    if (mx >= bx1 && mx <= bx2 && my >= by1 && my <= by2) {
      currentTool = tools[i];
      return true;
    }
  }
  return false;
}

// ----- Sites panel click -----

boolean handleSitesPanelClick(int mx, int my) {
  if (!isInSitesPanel(mx, my)) return false;
  SitesLayout layout = buildSitesLayout();

  // Density slider
  if (layout.densitySlider.contains(mx, my)) {
    float t = (mx - layout.densitySlider.x) / (float)layout.densitySlider.w;
    siteDensity = constrain(t, 0, 1);
    activeSlider = SLIDER_SITES_DENSITY;
    return true;
  }

  // Fuzz slider (0..1 mapped to 0..0.3)
  if (layout.fuzzSlider.contains(mx, my)) {
    float t = (mx - layout.fuzzSlider.x) / (float)layout.fuzzSlider.w;
    t = constrain(t, 0, 1);
    siteFuzz = t * 0.3f;
    activeSlider = SLIDER_SITES_FUZZ;
    return true;
  }

  // Mode slider
  if (layout.modeSlider.contains(mx, my)) {
    int modeCount = placementModes.length;
    if (modeCount < 1) modeCount = 1;
    float t = (mx - layout.modeSlider.x) / (float)layout.modeSlider.w;
    t = constrain(t, 0, 1);
    int idx = round(t * (modeCount - 1));
    placementModeIndex = constrain(idx, 0, placementModes.length - 1);
    activeSlider = SLIDER_SITES_MODE;
    return true;
  }

  // Generate button
  if (layout.generateBtn.contains(mx, my)) {
    mapModel.generateSites(currentPlacementMode(), siteDensity, keepPropertiesOnGenerate);
    return true;
  }

  // Keep properties toggle
  if (layout.keepCheckbox.contains(mx, my)) {
    keepPropertiesOnGenerate = !keepPropertiesOnGenerate;
    return true;
  }

  return false;
}

// ----- Zones panel click (tool + biome selection + add/remove + hue) -----

boolean handleZonesPanelClick(int mx, int my) {
  if (!isInZonesPanel(mx, my)) return false;
  if (mapModel == null || mapModel.biomeTypes == null) return false;

  BiomesLayout layout = buildBiomesLayout();

  // Paint button
  if (layout.paintBtn.contains(mx, my)) {
    currentZonePaintMode = ZonePaintMode.ZONE_PAINT;
    return true;
  }

  // Fill button
  if (layout.fillBtn.contains(mx, my)) {
    currentZonePaintMode = ZonePaintMode.ZONE_FILL;
    return true;
  }

  // Generate button
  if (layout.generateBtn.contains(mx, my)) {
    mapModel.generateZonesFromSeeds();
    return true;
  }

  // Reset button
  if (layout.resetBtn.contains(mx, my)) {
    mapModel.resetAllBiomesToNone();
    activeBiomeIndex = 0;
    editingZoneNameIndex = -1;
    return true;
  }

  int nTypes = mapModel.biomeTypes.size();

  // "+" button
  if (layout.addBtn.contains(mx, my)) {
    mapModel.addBiomeType();
    activeBiomeIndex = mapModel.biomeTypes.size() - 1;
    return true;
  }

  // "-" button
  boolean canRemove = (nTypes > 1 && activeBiomeIndex > 0);
  if (canRemove && layout.removeBtn.contains(mx, my)) {

    int removeIndex = activeBiomeIndex;
    mapModel.removeBiomeType(removeIndex);

    // Fix activeBiomeIndex after removal
    int newCount = mapModel.biomeTypes.size();
    if (newCount == 0) {
      activeBiomeIndex = 0;
    } else {
      activeBiomeIndex = min(removeIndex - 1, newCount - 1);
      if (activeBiomeIndex < 0) activeBiomeIndex = 0;
    }
    return true;
  }

  // Palette swatches
  int n = mapModel.biomeTypes.size();
  if (n == 0) return false;

  for (int i = 0; i < n; i++) {
    IntRect sw = layout.swatches.get(i);
    IntRect nameRect = layout.nameRects.get(i);
    if (sw.contains(mx, my)) {
      activeBiomeIndex = i;
      return true;
    }
    if (nameRect.contains(mx, my)) {
      activeBiomeIndex = i;
      editingZoneNameIndex = i;
      zoneNameDraft = mapModel.biomeTypes.get(i).name;
      return true;
    }
  }

  // Hue slider
  if (activeBiomeIndex >= 0 && activeBiomeIndex < n) {
    if (layout.hueSlider.contains(mx, my)) {

      float t = (mx - layout.hueSlider.x) / (float)layout.hueSlider.w;
      t = constrain(t, 0, 1);

      ZoneType active = mapModel.biomeTypes.get(activeBiomeIndex);
      active.hue01 = t;
      active.updateColorFromHSB();
      activeSlider = SLIDER_ZONE_HUE;

      return true;
    }
  }

  // Brush radius slider
  if (layout.brushSlider.contains(mx, my)) {
    float t = constrain((mx - layout.brushSlider.x) / (float)layout.brushSlider.w, 0, 1);
    zoneBrushRadius = constrain(0.01f + t * (0.15f - 0.01f), 0.01f, 0.15f);
    activeSlider = SLIDER_ZONE_BRUSH;
    return true;
  }

  return false;
}

// ---------- Painting helpers ----------

void paintBiomeAt(float wx, float wy) {
  Cell c = mapModel.findCellContaining(wx, wy);
  if (c != null) {
    c.biomeId = activeBiomeIndex;
  }
}

void fillBiomeAt(float wx, float wy) {
  Cell c = mapModel.findCellContaining(wx, wy);
  if (c != null) {
    mapModel.floodFillBiomeFromCell(c, activeBiomeIndex);
  }
}

void paintBiomeBrush(float wx, float wy) {
  if (mapModel.cells == null) return;
  float r2 = zoneBrushRadius * zoneBrushRadius;
  for (Cell c : mapModel.cells) {
    PVector cen = mapModel.cellCentroid(c);
    float dx = cen.x - wx;
    float dy = cen.y - wy;
    float d2 = dx * dx + dy * dy;
    if (d2 <= r2) {
      c.biomeId = activeBiomeIndex;
    }
  }
}

// ---------- Mouse & keyboard callbacks ----------

void mousePressed() {
  // Tool buttons
  if (mouseButton == LEFT) {
    if (handleToolButtonClick(mouseX, mouseY)) return;
  }

  // Sites panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_SITES) {
    if (handleSitesPanelClick(mouseX, mouseY)) return;
  }

  // Biomes panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_BIOMES) {
    if (handleZonesPanelClick(mouseX, mouseY)) return;
  }

  // Elevation panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_ELEVATION) {
    if (handleElevationPanelClick(mouseX, mouseY)) return;
  }

  // Paths panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_PATHS) {
    if (handlePathsPanelClick(mouseX, mouseY)) return;
    if (handlePathsListPanelClick(mouseX, mouseY)) return;
  }

  // Labels panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_LABELS) {
    if (handleLabelsPanelClick(mouseX, mouseY)) return;
  }

  // Render panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_RENDER) {
    if (handleRenderPanelClick(mouseX, mouseY)) return;
  }

  // Ignore world interaction if inside any top UI area
  if (mouseY < TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT) return;
  if (isInActivePanel(mouseX, mouseY)) return;
  if (currentTool == Tool.EDIT_PATHS && isInPathsListPanel(mouseX, mouseY)) return;

  // Panning with right button (all modes)
  if (mouseButton == RIGHT) {
    isPanning = true;
    lastMouseX = mouseX;
    lastMouseY = mouseY;
    return;
  }

  // Left button: mode-specific actions
  if (mouseButton == LEFT) {
    PVector worldPos = viewport.screenToWorld(mouseX, mouseY);

    if (currentTool == Tool.EDIT_SITES) {
      handleSitesMousePressed(worldPos.x, worldPos.y);
    } else if (currentTool == Tool.EDIT_BIOMES) {
      if (currentZonePaintMode == ZonePaintMode.ZONE_PAINT) {
        paintBiomeBrush(worldPos.x, worldPos.y);
      } else {
        fillBiomeAt(worldPos.x, worldPos.y);
      }
    } else if (currentTool == Tool.EDIT_ELEVATION) {
      float dir = elevationBrushRaise ? 1 : -1;
      mapModel.applyElevationBrush(worldPos.x, worldPos.y, elevationBrushRadius, elevationBrushStrength * dir, seaLevel);
    } else if (currentTool == Tool.EDIT_PATHS) {
      handlePathsMousePressed(worldPos.x, worldPos.y);
    } else if (currentTool == Tool.EDIT_STRUCTURES) {
      Structure s = mapModel.computeSnappedStructure(worldPos.x, worldPos.y);
      mapModel.structures.add(s);
    } else if (currentTool == Tool.EDIT_LABELS) {
      MapLabel lbl = new MapLabel(worldPos.x, worldPos.y, labelDraft);
      mapModel.labels.add(lbl);
      editingLabelIndex = mapModel.labels.size() - 1;
      labelDraft = lbl.text;
    }
  }
}

void handleSitesMousePressed(float wx, float wy) {
  wx = constrain(wx, mapModel.minX, mapModel.maxX);
  wy = constrain(wy, mapModel.minY, mapModel.maxY);
  float maxDistWorld = 10.0f / viewport.zoom; // ~10 px tolerance
  Site s = mapModel.findSiteNear(wx, wy, maxDistWorld);

  if (s != null) {
    mapModel.clearSiteSelection();
    mapModel.selectSite(s);
    draggingSite = s;
    isDraggingSite = true;
  } else {
    Site ns = mapModel.addSite(wx, wy);
    mapModel.clearSiteSelection();
    mapModel.selectSite(ns);
    draggingSite = ns;
    isDraggingSite = true;
  }
}

boolean handlePathsPanelClick(int mx, int my) {
  if (!isInPathsPanel(mx, my)) return false;
  PathsLayout layout = buildPathsLayout();

  // Add path type
  if (layout.routeSlider.contains(mx, my)) {
    String[] modes = { "Ends", "Shortest", "Flattest" };
    int modeCount = modes.length;
    float t = constrain((mx - layout.routeSlider.x) / (float)layout.routeSlider.w, 0, 1);
    int idx = round(t * (modeCount - 1));
    pathRouteModeIndex = constrain(idx, 0, modeCount - 1);
    activeSlider = SLIDER_NONE;
    return true;
  }

  // Add path type
  if (layout.typeAddBtn.contains(mx, my)) {
    int n = mapModel.pathTypes.size();
    if (n < PATH_TYPE_PRESETS.length) {
      PathType pt = mapModel.makePathTypeFromPreset(n);
      if (pt != null) {
        mapModel.addPathType(pt);
        activePathTypeIndex = mapModel.pathTypes.size() - 1;
      }
    }
    return true;
  }

  // Remove path type
  boolean canRemove = mapModel.pathTypes.size() > 1 && activePathTypeIndex > 0;
  if (canRemove && layout.typeRemoveBtn.contains(mx, my)) {
    mapModel.removePathType(activePathTypeIndex);
    activePathTypeIndex = min(activePathTypeIndex, mapModel.pathTypes.size() - 1);
    if (activePathTypeIndex < 0) activePathTypeIndex = 0;
    editingPathTypeNameIndex = -1;
    return true;
  }

  int nTypes = mapModel.pathTypes.size();

  // Swatches and names
  for (int i = 0; i < nTypes; i++) {
    IntRect sw = layout.typeSwatches.get(i);
    IntRect nameRect = layout.typeNameRects.get(i);
    if (sw.contains(mx, my)) {
      activePathTypeIndex = i;
      editingPathTypeNameIndex = -1;
      return true;
    }
    if (nameRect.contains(mx, my)) {
      activePathTypeIndex = i;
      editingPathTypeNameIndex = i;
      pathTypeNameDraft = mapModel.pathTypes.get(i).name;
      return true;
    }
  }

  // Hue slider
  if (activePathTypeIndex >= 0 && activePathTypeIndex < nTypes) {
    if (layout.typeHueSlider.contains(mx, my)) {
      float t = (mx - layout.typeHueSlider.x) / (float)layout.typeHueSlider.w;
      t = constrain(t, 0, 1);
      PathType pt = mapModel.pathTypes.get(activePathTypeIndex);
      pt.hue01 = t;
      pt.updateColorFromHSB();
      activeSlider = SLIDER_PATH_TYPE_HUE;
      return true;
    }
    if (layout.typeWeightSlider.contains(mx, my)) {
      float t = constrain((mx - layout.typeWeightSlider.x) / (float)layout.typeWeightSlider.w, 0, 1);
      PathType pt = mapModel.pathTypes.get(activePathTypeIndex);
      pt.weightPx = constrain(0.5f + t * (8.0f - 0.5f), 0.5f, 8.0f);
      activeSlider = SLIDER_PATH_TYPE_WEIGHT;
      return true;
    }
  }

  return false;
}

boolean handleLabelsPanelClick(int mx, int my) {
  if (!isInLabelsPanel(mx, my)) return false;
  // Simple text box focus
  editingLabelIndex = (mapModel.labels.size() > 0) ? mapModel.labels.size() - 1 : -1;
  return true;
}

boolean handlePathsListPanelClick(int mx, int my) {
  if (!isInPathsListPanel(mx, my)) return false;
  PathsListLayout layout = buildPathsListLayout();

  // New path button
  if (layout.newBtn.contains(mx, my)) {
    Path np = new Path();
    np.typeId = activePathTypeIndex;
    np.name = "Path " + (mapModel.paths.size() + 1);
    mapModel.paths.add(np);
    selectedPathIndex = mapModel.paths.size() - 1;
    editingPathNameIndex = selectedPathIndex;
    pathNameDraft = np.name;
    pendingPathStart = null;
    return true;
  }

  int labelX = layout.panel.x + PANEL_PADDING;
  int curY = layout.titleY + PANEL_TITLE_H + PANEL_SECTION_GAP;
  int rowH = 44;
  int maxY = layout.newBtn.y - PANEL_SECTION_GAP;

  for (int i = 0; i < mapModel.paths.size(); i++) {
    if (curY + rowH > maxY) break;
    Path p = mapModel.paths.get(i);

    int selectSize = 16;
    IntRect selectRect = new IntRect(labelX, curY, selectSize, selectSize);
    IntRect nameRect = new IntRect(selectRect.x + selectRect.w + 6, curY,
                                   layout.panel.w - 2 * PANEL_PADDING - selectRect.w - 6 - 40,
                                   PANEL_LABEL_H + 4);
    IntRect delRect = new IntRect(nameRect.x + nameRect.w + 6, nameRect.y, 30, nameRect.h);
    curY += nameRect.h + 2;
    IntRect typeRect = new IntRect(labelX + selectSize + 6, curY, 140, PANEL_LABEL_H + 2);
    curY += rowH - 2 * PANEL_LABEL_H;

    if (selectRect.contains(mx, my) || nameRect.contains(mx, my)) {
      selectedPathIndex = i;
      editingPathNameIndex = nameRect.contains(mx, my) ? i : -1;
      if (editingPathNameIndex == i) {
        pathNameDraft = (p.name != null) ? p.name : "";
      } else {
        pendingPathStart = null;
      }
      return true;
    }
    if (delRect.contains(mx, my)) {
      mapModel.paths.remove(i);
      if (selectedPathIndex == i) {
        selectedPathIndex = -1;
        pendingPathStart = null;
      } else if (selectedPathIndex > i) {
        selectedPathIndex -= 1;
      }
      if (editingPathNameIndex == i) editingPathNameIndex = -1;
      return true;
    }
    if (typeRect.contains(mx, my)) {
      if (!mapModel.pathTypes.isEmpty()) {
        p.typeId = (p.typeId + 1) % mapModel.pathTypes.size();
      }
      return true;
    }
  }

  return false;
}

boolean handleRenderPanelClick(int mx, int my) {
  if (!isInRenderPanel(mx, my)) return false;
  RenderLayout layout = buildRenderLayout();

  // zones, water, elevation, paths, labels, structures
  if (layout.checks.get(0).contains(mx, my)) { renderShowZones = !renderShowZones; return true; }
  if (layout.checks.get(1).contains(mx, my)) { renderShowWater = !renderShowWater; return true; }
  if (layout.checks.get(2).contains(mx, my)) { renderShowElevation = !renderShowElevation; return true; }

  // Lighting sliders under Elevation
  if (layout.lightAzimuthSlider != null && layout.lightAzimuthSlider.contains(mx, my)) {
    float t = constrain((mx - layout.lightAzimuthSlider.x) / (float)layout.lightAzimuthSlider.w, 0, 1);
    renderLightAzimuthDeg = constrain(t * 360.0f, 0, 360);
    activeSlider = SLIDER_RENDER_LIGHT_AZIMUTH;
    return true;
  }
  if (layout.lightAltitudeSlider != null && layout.lightAltitudeSlider.contains(mx, my)) {
    float t = constrain((mx - layout.lightAltitudeSlider.x) / (float)layout.lightAltitudeSlider.w, 0, 1);
    renderLightAltitudeDeg = constrain(5.0f + t * (80.0f - 5.0f), 5.0f, 80.0f);
    activeSlider = SLIDER_RENDER_LIGHT_ALTITUDE;
    return true;
  }

  if (layout.checks.get(3).contains(mx, my)) { renderShowPaths = !renderShowPaths; return true; }
  if (layout.checks.get(4).contains(mx, my)) { renderShowLabels = !renderShowLabels; return true; }
  if (layout.checks.get(5).contains(mx, my)) { renderShowStructures = !renderShowStructures; return true; }
  return false;
}

// ----- Elevation panel click -----

boolean handleElevationPanelClick(int mx, int my) {
  if (!isInElevationPanel(mx, my)) return false;
  ElevationLayout layout = buildElevationLayout();

  // Sea level
  if (layout.seaSlider.contains(mx, my)) {
    float t = constrain((mx - layout.seaSlider.x) / (float)layout.seaSlider.w, 0, 1);
    seaLevel = t * 1.0f - 0.5f;
    activeSlider = SLIDER_ELEV_SEA;
    return true;
  }

  // Brush radius
  if (layout.radiusSlider.contains(mx, my)) {
    float t = constrain((mx - layout.radiusSlider.x) / (float)layout.radiusSlider.w, 0, 1);
    elevationBrushRadius = constrain(0.01f + t * (0.2f - 0.01f), 0.01f, 0.2f);
    activeSlider = SLIDER_ELEV_RADIUS;
    return true;
  }

  // Brush strength
  if (layout.strengthSlider.contains(mx, my)) {
    float t = constrain((mx - layout.strengthSlider.x) / (float)layout.strengthSlider.w, 0, 1);
    elevationBrushStrength = constrain(0.005f + t * (0.2f - 0.005f), 0.005f, 0.2f);
    activeSlider = SLIDER_ELEV_STRENGTH;
    return true;
  }

  // Raise / Lower buttons
  if (layout.raiseBtn.contains(mx, my)) {
    elevationBrushRaise = true;
    return true;
  }
  if (layout.lowerBtn.contains(mx, my)) {
    elevationBrushRaise = false;
    return true;
  }

  // Noise scale slider
  if (layout.noiseSlider.contains(mx, my)) {
    float t = constrain((mx - layout.noiseSlider.x) / (float)layout.noiseSlider.w, 0, 1);
    elevationNoiseScale = constrain(1.0f + t * (12.0f - 1.0f), 1.0f, 12.0f);
    activeSlider = SLIDER_ELEV_NOISE;
    return true;
  }

  // Generate button
  if (layout.perlinBtn.contains(mx, my)) {
    mapModel.generateElevationNoise(elevationNoiseScale, 1.0f, seaLevel);
    return true;
  }

  // Vary button
  if (layout.varyBtn.contains(mx, my)) {
    mapModel.addElevationVariation(elevationNoiseScale, 0.2f, seaLevel);
    return true;
  }

  return false;
}

void handlePathsMousePressed(float wx, float wy) {
  if (selectedPathIndex < 0 || selectedPathIndex >= mapModel.paths.size()) return;
  wx = constrain(wx, mapModel.minX, mapModel.maxX);
  wy = constrain(wy, mapModel.minY, mapModel.maxY);

  float maxSnapPx = 14;
  PVector snapped = findNearestSnappingPoint(wx, wy, maxSnapPx);
  PVector target = (snapped != null) ? snapped : new PVector(wx, wy);

  if (pendingPathStart == null) {
    pendingPathStart = target;
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
    } else if (mode == PathRouteMode.SHORTEST) {
      ArrayList<PVector> rp = mapModel.findSnapPath(pendingPathStart, target);
      if (rp != null && rp.size() > 1) route = rp;
    } else if (mode == PathRouteMode.FLATTEST) {
      ArrayList<PVector> rp = mapModel.findSnapPathFlattest(pendingPathStart, target);
      if (rp != null && rp.size() > 1) route = rp;
    }
    if (route == null) {
      route = new ArrayList<PVector>();
      route.add(pendingPathStart.copy());
      route.add(target.copy());
    }
  }

  if (targetPath != null) {
    if (targetPath.segments.isEmpty()) {
      targetPath.typeId = activePathTypeIndex;
    }
    mapModel.appendSegmentToPath(targetPath, route);
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
      siteDensity = constrain(t, 0, 1);
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
  if (mouseButton == LEFT && currentTool == Tool.EDIT_BIOMES && isInZonesPanel(mouseX, mouseY)) {
    BiomesLayout layout = buildBiomesLayout();
    int n = (mapModel.biomeTypes == null) ? 0 : mapModel.biomeTypes.size();

    if (n > 0 && activeBiomeIndex >= 0 && activeBiomeIndex < n) {
      if (layout.hueSlider.contains(mouseX, mouseY)) {
        float t = (mouseX - layout.hueSlider.x) / (float)layout.hueSlider.w;
        t = constrain(t, 0, 1);
        ZoneType active = mapModel.biomeTypes.get(activeBiomeIndex);
        active.hue01 = t;
        active.updateColorFromHSB();
        activeSlider = SLIDER_ZONE_HUE;
        return;
      }
    }

    if (layout.brushSlider.contains(mouseX, mouseY)) {
      float t = constrain((mouseX - layout.brushSlider.x) / (float)layout.brushSlider.w, 0, 1);
      zoneBrushRadius = constrain(0.01f + t * (0.15f - 0.01f), 0.01f, 0.15f);
      activeSlider = SLIDER_ZONE_BRUSH;
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

  // Ignore world if dragging in UI
  if (isInActivePanel(mouseX, mouseY)) return;

  if (mouseButton == LEFT && currentTool == Tool.EDIT_SITES && isDraggingSite && draggingSite != null) {
    PVector worldPos = viewport.screenToWorld(mouseX, mouseY);
    draggingSite.x = constrain(worldPos.x, mapModel.minX, mapModel.maxX);
    draggingSite.y = constrain(worldPos.y, mapModel.minY, mapModel.maxY);
    mapModel.markVoronoiDirty();
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
    activeSlider = SLIDER_NONE;
  }
}

void updateActiveSlider(int mx, int my) {
  switch (activeSlider) {
    case SLIDER_SITES_DENSITY: {
      SitesLayout l = buildSitesLayout();
      float t = (mx - l.densitySlider.x) / (float)l.densitySlider.w;
      siteDensity = constrain(t, 0, 1);
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
    case SLIDER_ZONE_HUE: {
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
    case SLIDER_ZONE_BRUSH: {
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
  if (editingZoneNameIndex >= 0) {
    if (key == ENTER || key == RETURN) {
      if (editingZoneNameIndex < mapModel.biomeTypes.size()) {
        mapModel.biomeTypes.get(editingZoneNameIndex).name = zoneNameDraft;
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



