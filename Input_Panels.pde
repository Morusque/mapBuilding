// ---------- Input helpers ----------

boolean isInSitesPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_SITES) return false;
  SitesLayout layout = buildSitesLayout();
  return layout.panel.contains(mx, my);
}

boolean isInBiomesPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_BIOMES) return false;
  BiomesLayout layout = buildBiomesLayout();
  return layout.panel.contains(mx, my);
}

boolean isInZonesPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_ZONES) return false;
  ZonesLayout layout = buildZonesLayout();
  return layout.panel.contains(mx, my);
}

boolean isInZonesListPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_ZONES) return false;
  ZonesListLayout layout = buildZonesListLayout();
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

boolean isInStructuresPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_STRUCTURES) return false;
  StructuresLayout layout = buildStructuresLayout();
  return layout.panel.contains(mx, my);
}

boolean isInStructuresListPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_STRUCTURES) return false;
  StructuresListLayout layout = buildStructuresListLayout();
  return layout.panel.contains(mx, my);
}

boolean isInLabelsPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_LABELS) return false;
  LabelsLayout layout = buildLabelsLayout();
  return layout.panel.contains(mx, my);
}

boolean isInLabelsListPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_LABELS) return false;
  LabelsListLayout layout = buildLabelsListLayout();
  return layout.panel.contains(mx, my);
}

boolean isInRenderPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_RENDER) return false;
  RenderLayout layout = buildRenderLayout();
  return layout.panel.contains(mx, my);
}

boolean isInExportPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_EXPORT) return false;
  ExportLayout layout = buildExportLayout();
  return layout.panel.contains(mx, my);
}

boolean isInActivePanel(int mx, int my) {
  IntRect panel = getActivePanelRect();
  return (panel != null && panel.contains(mx, my));
}

boolean handleToolButtonClick(int my) {
  int barY = TOP_BAR_TOTAL;
  int barH = TOOL_BAR_HEIGHT;

  if (mapModel.isVoronoiBuilding()) {
    showNotice("Please wait for generation to finish...");
    return true;
  }

  if (my < barY || my > barY + barH) {
    return false;
  }

  int margin = 10;
  int buttonW = 90;

  String[] labels = { "Cells", "Elevation", "Biomes", "Zones", "Paths", "Structures", "Labels", "Rendering", "Export" };
  Tool[] tools = {
    Tool.EDIT_SITES,
    Tool.EDIT_ELEVATION,
    Tool.EDIT_BIOMES,
    Tool.EDIT_ZONES,
    Tool.EDIT_PATHS,
    Tool.EDIT_STRUCTURES,
    Tool.EDIT_LABELS,
    Tool.EDIT_RENDER,
    Tool.EDIT_EXPORT
  };

  for (int i = 0; i < labels.length; i++) {
    final int idx = i;
    int x = margin + i * (buttonW + 5);
    int y = barY + 2;
    IntRect rect = new IntRect(x, y, buttonW, barH - 4);
    if (queueButtonAction(rect, new Runnable() { public void run() {
      selectedPathIndex = -1;
      pendingPathStart = null;
      selectedStructureIndex = -1;
      currentTool = tools[idx];
    }})) return true;
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
    int newCount = round(t * MAX_SITE_COUNT);
    siteTargetCount = constrain(newCount, 0, MAX_SITE_COUNT);
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
  if (queueButtonAction(layout.generateBtn, new Runnable() { public void run() {
    mapModel.generateSites(currentPlacementMode(), siteTargetCount, keepPropertiesOnGenerate);
  }})) return true;

  // Keep properties toggle
  if (layout.keepCheckbox.contains(mx, my)) {
    keepPropertiesOnGenerate = !keepPropertiesOnGenerate;
    return true;
  }

  return false;
}

// ----- Zones panel click (tool + biome selection + add/remove + hue) -----

boolean handleBiomesPanelClick(int mx, int my) {
  if (!isInBiomesPanel(mx, my)) return false;
  if (mapModel == null || mapModel.biomeTypes == null) return false;

  BiomesLayout layout = buildBiomesLayout();

  // Paint button
  if (queueButtonAction(layout.paintBtn, new Runnable() { public void run() {
    currentBiomePaintMode = ZonePaintMode.ZONE_PAINT;
  }})) return true;

  // Fill button
  if (queueButtonAction(layout.fillBtn, new Runnable() { public void run() {
    currentBiomePaintMode = ZonePaintMode.ZONE_FILL;
  }})) return true;

  // Generation selector + apply
  if (layout.genModeSelector.contains(mx, my)) {
    int modeCount = biomeGenerateModes.length;
    int maxIdx = max(1, modeCount - 1);
    float t = constrain((mx - layout.genModeSelector.x) / (float)layout.genModeSelector.w, 0, 1);
    int idx = constrain(round(t * maxIdx), 0, modeCount - 1);
    biomeGenerateModeIndex = idx;
    activeSlider = SLIDER_BIOME_GEN_MODE;
    return true;
  }
  if (queueButtonAction(layout.genApplyBtn, new Runnable() { public void run() {
    applyBiomeGeneration();
  }})) return true;

  if (queueButtonAction(layout.genValueWaterBtn, new Runnable() { public void run() {
    float clampedSea = constrain(seaLevel, -1.0f, 1.0f);
    biomeGenerateValue01 = map(clampedSea, -1.0f, 1.0f, 0.0f, 1.0f);
    activeSlider = SLIDER_BIOME_GEN_VALUE;
  }})) return true;

  int nTypes = mapModel.biomeTypes.size();

  // "+" button
  if (queueButtonAction(layout.addBtn, new Runnable() { public void run() {
    mapModel.addBiomeType();
    activeBiomeIndex = mapModel.biomeTypes.size() - 1;
  }})) return true;

  // "-" button
  boolean canRemove = (nTypes > 1 && activeBiomeIndex > 0);
  if (canRemove && queueButtonAction(layout.removeBtn, new Runnable() { public void run() {
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
  }})) return true;

  // Palette swatches
  int n = mapModel.biomeTypes.size();
  if (n == 0) return false;

  for (int i = 0; i < n; i++) {
    IntRect sw = layout.swatches.get(i);
    if (sw.contains(mx, my)) {
      activeBiomeIndex = i;
      return true;
    }
  }

  // Name field for selected biome
  if (layout.nameField.contains(mx, my) && activeBiomeIndex >= 0 && activeBiomeIndex < n) {
    editingBiomeNameIndex = activeBiomeIndex;
    biomeNameDraft = mapModel.biomeTypes.get(activeBiomeIndex).name;
    return true;
  }

  // Hue slider
  if (activeBiomeIndex >= 0 && activeBiomeIndex < n) {
    if (layout.hueSlider.contains(mx, my)) {

      float t = (mx - layout.hueSlider.x) / (float)layout.hueSlider.w;
      t = constrain(t, 0, 1);

      ZoneType active = mapModel.biomeTypes.get(activeBiomeIndex);
      active.hue01 = t;
      active.updateColorFromHSB();
      activeSlider = SLIDER_BIOME_HUE;

      return true;
    }
  }

  // Brush radius slider
  if (layout.brushSlider.contains(mx, my)) {
    float t = constrain((mx - layout.brushSlider.x) / (float)layout.brushSlider.w, 0, 1);
    zoneBrushRadius = constrain(0.01f + t * (0.15f - 0.01f), 0.01f, 0.15f);
    activeSlider = SLIDER_BIOME_BRUSH;
    return true;
  }

  if (layout.genValueSlider.contains(mx, my)) {
    float t = constrain((mx - layout.genValueSlider.x) / (float)layout.genValueSlider.w, 0, 1);
    biomeGenerateValue01 = t;
    activeSlider = SLIDER_BIOME_GEN_VALUE;
    return true;
  }

  return false;
}

// ----- Zones panel click -----
boolean handleZonesPanelClick(int mx, int my) {
  if (!isInZonesPanel(mx, my)) return false;
  if (mapModel == null || mapModel.zones == null) return false;

  ZonesLayout layout = buildZonesLayout();

  if (layout.brushSlider.contains(mx, my)) {
    float t = constrain((mx - layout.brushSlider.x) / (float)layout.brushSlider.w, 0, 1);
    zoneBrushRadius = constrain(0.01f + t * (0.15f - 0.01f), 0.01f, 0.15f);
    activeSlider = SLIDER_ZONES_BRUSH;
    return true;
  }

  if (queueButtonAction(layout.excludeWaterBtn, new Runnable() { public void run() {
    if (activeZoneIndex >= 0) {
      mapModel.removeUnderwaterCellsFromZone(activeZoneIndex, seaLevel);
    } else {
      mapModel.removeUnderwaterCellsFromZone(-1, seaLevel);
    }
  }})) return true;

  if (queueButtonAction(layout.exclusiveBtn, new Runnable() { public void run() {
    mapModel.enforceZoneExclusivity(activeZoneIndex);
  }})) return true;

  if (queueButtonAction(layout.fourColorBtn, new Runnable() { public void run() {
    mapModel.recolorZonesWithFourColors();
  }})) return true;

  if (queueButtonAction(layout.resetBtn, new Runnable() { public void run() {
    mapModel.resetAllZonesToNone();
    activeZoneIndex = -1;
    editingZoneNameIndex = -1;
  }})) return true;

  if (queueButtonAction(layout.regenerateBtn, new Runnable() { public void run() {
    int target = max(5, mapModel.zones.size());
    mapModel.regenerateRandomZones(target);
    activeZoneIndex = -1;
    editingZoneNameIndex = -1;
  }})) return true;

  return false;
}

boolean handleZonesListPanelClick(int mx, int my) {
  if (!isInZonesListPanel(mx, my)) return false;
  ZonesListLayout layout = buildZonesListLayout();
  populateZonesRows(layout);

  if (queueButtonAction(layout.deselectBtn, new Runnable() { public void run() {
    activeZoneIndex = -1;
    editingZoneNameIndex = -1;
  }})) return true;

  if (queueButtonAction(layout.newBtn, new Runnable() { public void run() {
    mapModel.addZone();
    activeZoneIndex = mapModel.zones.size() - 1;
  }})) return true;

  for (int i = 0; i < layout.rows.size(); i++) {
    ZoneRowLayout row = layout.rows.get(i);
    if (row.index < 0 || row.index >= mapModel.zones.size()) continue;
    MapModel.MapZone az = mapModel.zones.get(row.index);

    if (queueButtonAction(row.selectRect, new Runnable() { public void run() {
      activeZoneIndex = row.index;
      editingZoneNameIndex = -1;
    }})) return true;

    if (queueButtonAction(row.nameRect, new Runnable() { public void run() {
      activeZoneIndex = row.index;
      editingZoneNameIndex = row.index;
      zoneNameDraft = az.name;
    }})) return true;

    if (row.hueSlider.contains(mx, my)) {
      activeZoneIndex = row.index;
      float t = constrain((mx - row.hueSlider.x) / (float)row.hueSlider.w, 0, 1);
      az.hue01 = t;
      az.updateColorFromHSB();
      activeSlider = SLIDER_ZONES_ROW_HUE;
      return true;
    }
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
    mapModel.renderer.invalidateBiomeOutlineCache();
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
  mapModel.renderer.invalidateBiomeOutlineCache();
}

void paintZoneAt(float wx, float wy) {
  if (mapModel.zones == null || activeZoneIndex < 0 || activeZoneIndex >= mapModel.zones.size()) return;
  Cell c = mapModel.findCellContaining(wx, wy);
  if (c != null) {
    int idx = mapModel.indexOfCell(c);
    mapModel.addCellToZone(idx, activeZoneIndex);
  }
}

void fillZoneAt(float wx, float wy) {
  if (mapModel.zones == null) return;
  Cell c = mapModel.findCellContaining(wx, wy);
  if (c == null) return;
  if (activeZoneIndex < 0 || activeZoneIndex >= mapModel.zones.size()) {
    mapModel.removeCellFromAllZones(mapModel.indexOfCell(c));
  } else {
    mapModel.floodFillZone(c, activeZoneIndex);
  }
}

void paintZoneBrush(float wx, float wy) {
  if (mapModel.zones == null || mapModel.cells == null) return;
  boolean erasing = (activeZoneIndex < 0 || activeZoneIndex >= mapModel.zones.size());
  float r2 = zoneBrushRadius * zoneBrushRadius;
  for (int ci = 0; ci < mapModel.cells.size(); ci++) {
    Cell c = mapModel.cells.get(ci);
    PVector cen = mapModel.cellCentroid(c);
    float dx = cen.x - wx;
    float dy = cen.y - wy;
    float d2 = dx * dx + dy * dy;
    if (d2 <= r2) {
      if (erasing) {
        mapModel.removeCellFromAllZones(ci);
      } else {
        mapModel.addCellToZone(ci, activeZoneIndex);
      }
    }
  }
}

boolean handleSnapSettingsClick(int mx, int my) {
  SnapSettingsLayout layout = buildSnapSettingsLayout();
  if (!layout.panel.contains(mx, my)) return false;

  // Checkboxes
  for (int i = 0; i < layout.checks.size(); i++) {
    IntRect b = layout.checks.get(i);
    if (b.contains(mx, my)) {
      switch (i) {
        case 0: snapWaterEnabled = !snapWaterEnabled; break;
        case 1: snapBiomesEnabled = !snapBiomesEnabled; break;
        case 2: snapUnderwaterBiomesEnabled = !snapUnderwaterBiomesEnabled; break;
        case 3: snapZonesEnabled = !snapZonesEnabled; break;
        case 4: snapPathsEnabled = !snapPathsEnabled; break;
        case 5: snapStructuresEnabled = !snapStructuresEnabled; break;
        case 6: snapElevationEnabled = !snapElevationEnabled; break;
      }
      return true;
    }
  }

  // Elevation divisions slider
  if (layout.elevationSlider.contains(mx, my)) {
    int divMin = 2;
    int divMax = 24;
    float t = constrain((mx - layout.elevationSlider.x) / (float)layout.elevationSlider.w, 0, 1);
    snapElevationDivisions = round(lerp(divMin, divMax, t));
    return true;
  }

  return false;
}

// ---------- Mouse & keyboard callbacks ----------

void mousePressed() {
  if (mouseButton == LEFT) {
    pendingButtonAction = null;
    pressedButtonRect = null;
  }
  // Block interactions while generation is running; show notice
  if (mapModel.isVoronoiBuilding() && mouseButton == LEFT) {
    showNotice("Please wait for generation to finish...");
    return;
  }

  // Tool buttons
  if (mouseButton == LEFT) {
    if (handleToolButtonClick(mouseY)) return;
  }

  // Snap settings (Structures mode only)
  if (mouseButton == LEFT && currentTool == Tool.EDIT_STRUCTURES) {
    if (handleSnapSettingsClick(mouseX, mouseY)) return;
  }

  // Sites panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_SITES) {
    if (handleSitesPanelClick(mouseX, mouseY)) return;
  }

  // Biomes panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_BIOMES) {
    if (handleBiomesPanelClick(mouseX, mouseY)) return;
  }

  // Zones panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_ZONES) {
    if (handleZonesPanelClick(mouseX, mouseY)) return;
    if (handleZonesListPanelClick(mouseX, mouseY)) return;
    if (isInZonesListPanel(mouseX, mouseY)) return;
  }

  // Elevation panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_ELEVATION) {
    if (handleElevationPanelClick(mouseX, mouseY)) return;
  }

  // Paths panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_PATHS) {
    if (handlePathsPanelClick(mouseX, mouseY)) return;
    if (handlePathsListPanelClick(mouseX, mouseY)) return;
    if (isInPathsListPanel(mouseX, mouseY)) return;
  }

  // Structures panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_STRUCTURES) {
    if (handleStructuresPanelClick(mouseX, mouseY)) return;
    if (handleStructuresListPanelClick(mouseX, mouseY)) return;
    if (isInStructuresListPanel(mouseX, mouseY)) return;
  }

  // Labels panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_LABELS) {
    if (handleLabelsPanelClick(mouseX, mouseY)) return;
    if (handleLabelsListPanelClick(mouseX, mouseY)) return;
    if (isInLabelsListPanel(mouseX, mouseY)) return;
  }

  // Render panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_RENDER) {
    if (handleRenderPanelClick(mouseX, mouseY)) return;
  }

  // Export panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_EXPORT) {
    if (handleExportPanelClick(mouseX, mouseY)) return;
  }

  // Ignore world interaction if inside any top UI area
  if (mouseY < TOP_BAR_TOTAL + TOOL_BAR_HEIGHT) return;
  if (isInActivePanel(mouseX, mouseY)) return;
  if (currentTool == Tool.EDIT_ZONES && isInZonesListPanel(mouseX, mouseY)) return;
  if (currentTool == Tool.EDIT_PATHS && isInPathsListPanel(mouseX, mouseY)) return;
  if (currentTool == Tool.EDIT_STRUCTURES && isInStructuresListPanel(mouseX, mouseY)) return;
  if (currentTool == Tool.EDIT_LABELS && isInLabelsListPanel(mouseX, mouseY)) return;

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
      if (currentBiomePaintMode == ZonePaintMode.ZONE_PAINT) {
        paintBiomeBrush(worldPos.x, worldPos.y);
      } else {
        fillBiomeAt(worldPos.x, worldPos.y);
      }
    } else if (currentTool == Tool.EDIT_ZONES) {
      if (currentZonePaintMode == ZonePaintMode.ZONE_PAINT) {
        paintZoneBrush(worldPos.x, worldPos.y);
      } else {
        fillZoneAt(worldPos.x, worldPos.y);
      }
    } else if (currentTool == Tool.EDIT_ELEVATION) {
      float dir = elevationBrushRaise ? 1 : -1;
      mapModel.applyElevationBrush(worldPos.x, worldPos.y, elevationBrushRadius, elevationBrushStrength * dir, seaLevel);
    } else if (currentTool == Tool.EDIT_PATHS) {
      if (pathEraserMode) {
        mapModel.erasePathSegments(worldPos.x, worldPos.y, pathEraserRadius);
      } else {
        handlePathsMousePressed(worldPos.x, worldPos.y);
      }
  } else if (currentTool == Tool.EDIT_STRUCTURES) {
    Structure s = mapModel.computeSnappedStructure(worldPos.x, worldPos.y, structureSize);
    mapModel.structures.add(s);
    selectedStructureIndex = mapModel.structures.size() - 1;
  } else if (currentTool == Tool.EDIT_LABELS) {
    String baseText = "label";
    if (selectedLabelIndex >= 0 && selectedLabelIndex < mapModel.labels.size()) {
      MapLabel sel = mapModel.labels.get(selectedLabelIndex);
      if (sel != null && sel.text != null && sel.text.length() > 0) baseText = sel.text;
    }
    MapLabel lbl = new MapLabel(worldPos.x, worldPos.y, baseText, labelTargetMode);
    lbl.size = labelSizeDefault();
    mapModel.labels.add(lbl);
    selectedLabelIndex = mapModel.labels.size() - 1;
    editingLabelIndex = selectedLabelIndex;
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
    String[] modes = { "Ends", "Pathfind" };
    int modeCount = modes.length;
    float t = constrain((mx - layout.routeSlider.x) / (float)layout.routeSlider.w, 0, 1);
    int idx = round(t * (modeCount - 1));
    pathRouteModeIndex = constrain(idx, 0, modeCount - 1);
    if (activePathTypeIndex >= 0 && activePathTypeIndex < mapModel.pathTypes.size()) {
      PathType pt = mapModel.pathTypes.get(activePathTypeIndex);
      pt.routeMode = PathRouteMode.values()[pathRouteModeIndex];
    }
    activeSlider = SLIDER_NONE;
    return true;
  }

  if (layout.flattestSlider.contains(mx, my)) {
    float t = constrain((mx - layout.flattestSlider.x) / (float)layout.flattestSlider.w, 0, 1);
    flattestSlopeBias = constrain(FLATTEST_BIAS_MIN + t * (FLATTEST_BIAS_MAX - FLATTEST_BIAS_MIN),
                                  FLATTEST_BIAS_MIN, FLATTEST_BIAS_MAX);
    if (activePathTypeIndex >= 0 && activePathTypeIndex < mapModel.pathTypes.size()) {
      PathType pt = mapModel.pathTypes.get(activePathTypeIndex);
      pt.slopeBias = flattestSlopeBias;
    }
    activeSlider = SLIDER_FLATTEST_BIAS;
    return true;
  }

  if (layout.avoidWaterCheck.contains(mx, my)) {
    pathAvoidWater = !pathAvoidWater;
    if (activePathTypeIndex >= 0 && activePathTypeIndex < mapModel.pathTypes.size()) {
      PathType pt = mapModel.pathTypes.get(activePathTypeIndex);
      pt.avoidWater = pathAvoidWater;
    }
    return true;
  }

  if (queueButtonAction(layout.eraserBtn, new Runnable() { public void run() {
    pathEraserMode = !pathEraserMode;
    pendingPathStart = null;
  }})) return true;
  if (layout.taperCheck.contains(mx, my)) {
    if (activePathTypeIndex >= 0 && activePathTypeIndex < mapModel.pathTypes.size()) {
      PathType pt = mapModel.pathTypes.get(activePathTypeIndex);
      pt.taperOn = !pt.taperOn;
    }
    return true;
  }

  // Add path type
  if (queueButtonAction(layout.typeAddBtn, new Runnable() { public void run() {
    int n = mapModel.pathTypes.size();
    if (n < PATH_TYPE_PRESETS.length) {
      PathType pt = mapModel.makePathTypeFromPreset(n);
      if (pt != null) {
        mapModel.addPathType(pt);
        activePathTypeIndex = mapModel.pathTypes.size() - 1;
        syncActivePathTypeGlobals();
        selectedPathIndex = -1;
        pendingPathStart = null;
        editingPathNameIndex = -1;
      }
    }
  }})) return true;

  // Remove path type
  boolean canRemove = mapModel.pathTypes.size() > 1 && activePathTypeIndex > 0;
  if (canRemove && queueButtonAction(layout.typeRemoveBtn, new Runnable() { public void run() {
    mapModel.removePathType(activePathTypeIndex);
    activePathTypeIndex = min(activePathTypeIndex, mapModel.pathTypes.size() - 1);
    if (activePathTypeIndex < 0) activePathTypeIndex = 0;
    editingPathTypeNameIndex = -1;
    syncActivePathTypeGlobals();
    selectedPathIndex = -1;
    pendingPathStart = null;
    editingPathNameIndex = -1;
  }})) return true;

  int nTypes = mapModel.pathTypes.size();

  // Swatches and names
  for (int i = 0; i < nTypes; i++) {
    IntRect sw = layout.typeSwatches.get(i);
    if (sw.contains(mx, my)) {
      activePathTypeIndex = i;
      syncActivePathTypeGlobals();
      selectedPathIndex = -1;
      pendingPathStart = null;
      editingPathNameIndex = -1;
      return true;
    }
  }

  if (layout.nameField.contains(mx, my) && activePathTypeIndex >= 0 && activePathTypeIndex < nTypes) {
    editingPathTypeNameIndex = activePathTypeIndex;
    pathTypeNameDraft = mapModel.pathTypes.get(activePathTypeIndex).name;
    return true;
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
    if (layout.typeMinWeightSlider.contains(mx, my)) {
      float t = constrain((mx - layout.typeMinWeightSlider.x) / (float)layout.typeMinWeightSlider.w, 0, 1);
      PathType pt = mapModel.pathTypes.get(activePathTypeIndex);
      pt.minWeightPx = constrain(0.5f + t * (pt.weightPx - 0.5f), 0.5f, pt.weightPx);
      activeSlider = SLIDER_PATH_TYPE_MIN_WEIGHT;
      return true;
    }
    if (layout.taperCheck.contains(mx, my)) {
      PathType pt = mapModel.pathTypes.get(activePathTypeIndex);
      pt.taperOn = !pt.taperOn;
      return true;
    }
  }

  return false;
}

boolean handleLabelsPanelClick(int mx, int my) {
  if (!isInLabelsPanel(mx, my)) return false;
  return false;
}

boolean handleLabelsListPanelClick(int mx, int my) {
  if (!isInLabelsListPanel(mx, my)) return false;
  LabelsListLayout layout = buildLabelsListLayout();
  populateLabelsListRows(layout);

  if (queueButtonAction(layout.deselectBtn, new Runnable() { public void run() {
    selectedLabelIndex = -1;
    editingLabelIndex = -1;
    labelDraft = "label";
  }})) return true;

  // Size slider
  if (layout.sizeSlider.contains(mx, my)) {
    float t = constrain((mx - layout.sizeSlider.x) / (float)layout.sizeSlider.w, 0, 1);
    float newSize = 8 + t * (40 - 8);
    setLabelSizeDefault(newSize);
    if (selectedLabelIndex >= 0 && selectedLabelIndex < mapModel.labels.size()) {
      MapLabel sel = mapModel.labels.get(selectedLabelIndex);
      if (sel != null) sel.size = newSize;
    }
    return true;
  }

  for (int i = 0; i < layout.rows.size(); i++) {
    LabelRowLayout row = layout.rows.get(i);
    if (row.index < 0 || row.index >= mapModel.labels.size()) continue;
    MapLabel lbl = mapModel.labels.get(row.index);
    if (queueButtonAction(row.selectRect, new Runnable() { public void run() {
      selectedLabelIndex = row.index;
      editingLabelIndex = -1;
      labelDraft = lbl.text;
    }})) return true;
    if (queueButtonAction(row.nameRect, new Runnable() { public void run() {
      selectedLabelIndex = row.index;
      editingLabelIndex = row.index;
      labelDraft = lbl.text;
    }})) return true;
    if (queueButtonAction(row.delRect, new Runnable() { public void run() {
      mapModel.labels.remove(row.index);
      if (selectedLabelIndex == row.index) selectedLabelIndex = -1;
      if (editingLabelIndex == row.index) editingLabelIndex = -1;
      labelDraft = "label";
    }})) return true;
  }
  return false;
}

LabelTarget nextLabelTarget(LabelTarget lt) {
  switch (lt) {
    case FREE: return LabelTarget.BIOME;
    case BIOME: return LabelTarget.ZONE;
    case ZONE: return LabelTarget.STRUCTURE;
    default: return LabelTarget.FREE;
  }
}

boolean handlePathsListPanelClick(int mx, int my) {
  if (!isInPathsListPanel(mx, my)) return false;
  PathsListLayout layout = buildPathsListLayout();
  populatePathsListRows(layout);

  if (queueButtonAction(layout.deselectBtn, new Runnable() { public void run() {
    selectedPathIndex = -1;
    pendingPathStart = null;
    editingPathNameIndex = -1;
  }})) return true;

  // New path button
  if (queueButtonAction(layout.newBtn, new Runnable() { public void run() {
    Path np = new Path();
    np.typeId = activePathTypeIndex;
    np.name = "Path " + (mapModel.paths.size() + 1);
    mapModel.paths.add(np);
    selectedPathIndex = mapModel.paths.size() - 1;
    activePathTypeIndex = (np.typeId >= 0 && np.typeId < mapModel.pathTypes.size()) ? np.typeId : activePathTypeIndex;
    syncActivePathTypeGlobals();
    editingPathNameIndex = selectedPathIndex;
    pathNameDraft = np.name;
    pendingPathStart = null;
  }})) return true;

  for (int i = 0; i < layout.rows.size(); i++) {
    PathRowLayout row = layout.rows.get(i);
    if (row.index < 0 || row.index >= mapModel.paths.size()) continue;
    Path p = mapModel.paths.get(row.index);
    if (p == null) continue;

    if (queueButtonAction(row.selectRect, new Runnable() { public void run() {
      selectedPathIndex = row.index;
      if (p.typeId >= 0 && p.typeId < mapModel.pathTypes.size()) {
        activePathTypeIndex = p.typeId;
        syncActivePathTypeGlobals();
      }
      editingPathNameIndex = -1;
      pendingPathStart = null;
    }})) return true;
    if (queueButtonAction(row.nameRect, new Runnable() { public void run() {
      selectedPathIndex = row.index;
      if (p.typeId >= 0 && p.typeId < mapModel.pathTypes.size()) {
        activePathTypeIndex = p.typeId;
        syncActivePathTypeGlobals();
      }
      editingPathNameIndex = row.index;
      pathNameDraft = (p.name != null) ? p.name : "";
    }})) return true;
    if (queueButtonAction(row.delRect, new Runnable() { public void run() {
      mapModel.paths.remove(row.index);
      if (selectedPathIndex == row.index) {
        selectedPathIndex = -1;
        pendingPathStart = null;
      } else if (selectedPathIndex > row.index) {
        selectedPathIndex -= 1;
      }
      if (editingPathNameIndex == row.index) editingPathNameIndex = -1;
    }})) return true;
    if (queueButtonAction(row.typeRect, new Runnable() { public void run() {
      if (!mapModel.pathTypes.isEmpty()) {
        p.typeId = (p.typeId + 1) % mapModel.pathTypes.size();
        activePathTypeIndex = p.typeId;
        syncActivePathTypeGlobals();
      }
    }})) return true;
  }

  return false;
}

boolean handleStructuresPanelClick(int mx, int my) {
  if (!isInStructuresPanel(mx, my)) return false;
  StructuresLayout layout = buildStructuresLayout();
  if (layout.sizeSlider.contains(mx, my)) {
    float t = constrain((mx - layout.sizeSlider.x) / (float)layout.sizeSlider.w, 0, 1);
    structureSize = constrain(0.01f + t * (0.2f - 0.01f), 0.01f, 0.2f);
    activeSlider = SLIDER_STRUCT_SIZE;
    return true;
  }
  if (layout.angleSlider.contains(mx, my)) {
    float t = constrain((mx - layout.angleSlider.x) / (float)layout.angleSlider.w, 0, 1);
    float angDeg = -180.0f + t * 360.0f;
    structureAngleOffsetRad = radians(angDeg);
    activeSlider = SLIDER_STRUCT_ANGLE;
    return true;
  }
  if (layout.ratioSlider.contains(mx, my)) {
    float t = constrain((mx - layout.ratioSlider.x) / (float)layout.ratioSlider.w, 0, 1);
    structureAspectRatio = constrain(0.3f + t * (3.0f - 0.3f), 0.3f, 3.0f);
    activeSlider = SLIDER_STRUCT_RATIO;
    return true;
  }
  for (int i = 0; i < layout.shapeButtons.size(); i++) {
    final int shapeIdx = i;
    IntRect b = layout.shapeButtons.get(i);
    if (queueButtonAction(b, new Runnable() { public void run() {
      structureShape = StructureShape.values()[shapeIdx];
    }})) return true;
  }
  for (int i = 0; i < layout.snapButtons.size(); i++) {
    final int snapIdx = i;
    IntRect b = layout.snapButtons.get(i);
    if (queueButtonAction(b, new Runnable() { public void run() {
      structureSnapMode = StructureSnapMode.values()[snapIdx];
    }})) return true;
  }
  return false;
}

boolean handleStructuresListPanelClick(int mx, int my) {
  if (!isInStructuresListPanel(mx, my)) return false;
  StructuresListLayout layout = buildStructuresListLayout();
  boolean hasSelection = (selectedStructureIndex >= 0 && selectedStructureIndex < mapModel.structures.size());
  int listStartY = layoutStructureDetails(layout);
  populateStructuresListRows(layout, listStartY);

  if (queueButtonAction(layout.deselectBtn, new Runnable() { public void run() {
    selectedStructureIndex = -1;
    editingStructureNameIndex = -1;
  }})) return true;

  Structure sel = hasSelection ? mapModel.structures.get(selectedStructureIndex) : null;
  if (layout.detailNameField.contains(mx, my)) {
    if (sel != null) {
      editingStructureNameIndex = selectedStructureIndex;
      structureNameDraft = (sel.name != null) ? sel.name : "";
    }
    return true;
  }
  if (layout.detailSizeSlider.contains(mx, my)) {
    float t = constrain((mx - layout.detailSizeSlider.x) / (float)layout.detailSizeSlider.w, 0, 1);
    float newSize = constrain(0.01f + t * (0.2f - 0.01f), 0.01f, 0.2f);
    if (sel != null) sel.size = newSize;
    else structureSize = newSize;
    activeSlider = SLIDER_STRUCT_SELECTED_SIZE;
    return true;
  }
  if (layout.detailAngleSlider.contains(mx, my)) {
    float t = constrain((mx - layout.detailAngleSlider.x) / (float)layout.detailAngleSlider.w, 0, 1);
    float angDeg = -180.0f + t * 360.0f;
    if (sel != null) sel.angle = radians(angDeg);
    else structureAngleOffsetRad = radians(angDeg);
    activeSlider = SLIDER_STRUCT_SELECTED_ANGLE;
    return true;
  }
  if (layout.detailHueSlider.contains(mx, my)) {
    float t = constrain((mx - layout.detailHueSlider.x) / (float)layout.detailHueSlider.w, 0, 1);
    if (sel != null) sel.setHue(t);
    else structureHue01 = t;
    activeSlider = SLIDER_STRUCT_SELECTED_HUE;
    return true;
  }
  if (layout.detailSatSlider.contains(mx, my)) {
    float t = constrain((mx - layout.detailSatSlider.x) / (float)layout.detailSatSlider.w, 0, 1);
    if (sel != null) sel.setSaturation(t);
    else structureSat01 = t;
    activeSlider = SLIDER_STRUCT_SELECTED_SAT;
    return true;
  }
  if (layout.detailAlphaSlider.contains(mx, my)) {
    float t = constrain((mx - layout.detailAlphaSlider.x) / (float)layout.detailAlphaSlider.w, 0, 1);
    if (sel != null) sel.setAlpha(t);
    else structureAlpha01 = t;
    activeSlider = SLIDER_STRUCT_SELECTED_ALPHA;
    return true;
  }
  if (layout.detailStrokeSlider.contains(mx, my)) {
    float t = constrain((mx - layout.detailStrokeSlider.x) / (float)layout.detailStrokeSlider.w, 0, 1);
    float w = constrain(0.5f + t * (4.0f - 0.5f), 0.5f, 4.0f);
    if (sel != null) sel.strokeWeightPx = w;
    else structureStrokePx = w;
    activeSlider = SLIDER_STRUCT_SELECTED_STROKE;
    return true;
  }

  for (int i = 0; i < layout.rows.size(); i++) {
    StructureRowLayout row = layout.rows.get(i);
    if (row.index < 0 || row.index >= mapModel.structures.size()) continue;
    if (queueButtonAction(row.selectRect, new Runnable() { public void run() {
      selectedStructureIndex = row.index;
      editingStructureNameIndex = -1;
    }})) return true;
    if (queueButtonAction(row.nameRect, new Runnable() { public void run() {
      selectedStructureIndex = row.index;
      editingStructureNameIndex = row.index;
      Structure target = mapModel.structures.get(row.index);
      structureNameDraft = (target != null && target.name != null) ? target.name : "";
    }})) return true;
    if (queueButtonAction(row.delRect, new Runnable() { public void run() {
      mapModel.structures.remove(row.index);
      if (selectedStructureIndex == row.index) selectedStructureIndex = -1;
      else if (selectedStructureIndex > row.index) selectedStructureIndex -= 1;
      if (editingStructureNameIndex == row.index) editingStructureNameIndex = -1;
      else if (editingStructureNameIndex > row.index) editingStructureNameIndex -= 1;
    }})) return true;
  }
  return false;
}

boolean handleRenderPanelClick(int mx, int my) {
  if (!isInRenderPanel(mx, my)) return false;
  RenderLayout layout = buildRenderLayout();
  // Section toggles
  if (queueButtonAction(layout.headerBase, new Runnable() { public void run() { renderSectionBaseOpen = !renderSectionBaseOpen; }})) return true;
  if (queueButtonAction(layout.headerBiomes, new Runnable() { public void run() { renderSectionBiomesOpen = !renderSectionBiomesOpen; }})) return true;
  if (queueButtonAction(layout.headerShading, new Runnable() { public void run() { renderSectionShadingOpen = !renderSectionShadingOpen; }})) return true;
  if (queueButtonAction(layout.headerContours, new Runnable() { public void run() { renderSectionContoursOpen = !renderSectionContoursOpen; }})) return true;
  if (queueButtonAction(layout.headerPaths, new Runnable() { public void run() { renderSectionPathsOpen = !renderSectionPathsOpen; }})) return true;
  if (queueButtonAction(layout.headerZones, new Runnable() { public void run() { renderSectionZonesOpen = !renderSectionZonesOpen; }})) return true;
  if (queueButtonAction(layout.headerStructures, new Runnable() { public void run() { renderSectionStructuresOpen = !renderSectionStructuresOpen; }})) return true;
  if (queueButtonAction(layout.headerLabels, new Runnable() { public void run() { renderSectionLabelsOpen = !renderSectionLabelsOpen; }})) return true;
  if (queueButtonAction(layout.headerGeneral, new Runnable() { public void run() { renderSectionGeneralOpen = !renderSectionGeneralOpen; }})) return true;

  // Base
  if (renderSectionBaseOpen) {
    if (layout.landHSB[0].contains(mx, my)) { renderSettings.landHue01 = constrain((mx - layout.landHSB[0].x) / (float)layout.landHSB[0].w, 0, 1); activeSlider = SLIDER_RENDER_LAND_H; return true; }
    if (layout.landHSB[1].contains(mx, my)) { renderSettings.landSat01 = constrain((mx - layout.landHSB[1].x) / (float)layout.landHSB[1].w, 0, 1); activeSlider = SLIDER_RENDER_LAND_S; return true; }
    if (layout.landHSB[2].contains(mx, my)) { renderSettings.landBri01 = constrain((mx - layout.landHSB[2].x) / (float)layout.landHSB[2].w, 0, 1); activeSlider = SLIDER_RENDER_LAND_B; return true; }
    if (layout.waterHSB[0].contains(mx, my)) { renderSettings.waterHue01 = constrain((mx - layout.waterHSB[0].x) / (float)layout.waterHSB[0].w, 0, 1); activeSlider = SLIDER_RENDER_WATER_H; return true; }
    if (layout.waterHSB[1].contains(mx, my)) { renderSettings.waterSat01 = constrain((mx - layout.waterHSB[1].x) / (float)layout.waterHSB[1].w, 0, 1); activeSlider = SLIDER_RENDER_WATER_S; return true; }
    if (layout.waterHSB[2].contains(mx, my)) { renderSettings.waterBri01 = constrain((mx - layout.waterHSB[2].x) / (float)layout.waterHSB[2].w, 0, 1); activeSlider = SLIDER_RENDER_WATER_B; return true; }
    if (layout.cellBordersAlphaSlider.contains(mx, my)) {
      float t = constrain((mx - layout.cellBordersAlphaSlider.x) / (float)layout.cellBordersAlphaSlider.w, 0, 1);
      renderSettings.cellBorderAlpha01 = t;
      activeSlider = SLIDER_RENDER_CELL_BORDER_ALPHA;
      return true;
    }
  }

  // Biomes
  if (renderSectionBiomesOpen) {
    if (layout.biomeFillAlphaSlider.contains(mx, my)) {
      float t = constrain((mx - layout.biomeFillAlphaSlider.x) / (float)layout.biomeFillAlphaSlider.w, 0, 1);
      renderSettings.biomeFillAlpha01 = t;
      activeSlider = SLIDER_RENDER_BIOME_FILL_ALPHA;
      return true;
    }
    if (layout.biomeSatSlider.contains(mx, my)) {
      float t = constrain((mx - layout.biomeSatSlider.x) / (float)layout.biomeSatSlider.w, 0, 1);
      renderSettings.biomeSatScale01 = t;
      activeSlider = SLIDER_RENDER_BIOME_SAT;
      return true;
    }
    for (int i = 0; i < layout.biomeFillTypeButtons.size(); i++) {
      IntRect b = layout.biomeFillTypeButtons.get(i);
      if (b.contains(mx, my)) {
        renderSettings.biomeFillType = (i == 0) ? RenderFillType.RENDER_FILL_COLOR : RenderFillType.RENDER_FILL_PATTERN;
        return true;
      }
    }
    if (layout.biomeOutlineSizeSlider.contains(mx, my)) {
      float t = constrain((mx - layout.biomeOutlineSizeSlider.x) / (float)layout.biomeOutlineSizeSlider.w, 0, 1);
      renderSettings.biomeOutlineSizePx = constrain(t * 5.0f, 0, 5.0f);
      activeSlider = SLIDER_RENDER_BIOME_OUTLINE_SIZE;
      return true;
    }
    if (layout.biomeOutlineAlphaSlider.contains(mx, my)) {
      float t = constrain((mx - layout.biomeOutlineAlphaSlider.x) / (float)layout.biomeOutlineAlphaSlider.w, 0, 1);
      renderSettings.biomeOutlineAlpha01 = t;
      activeSlider = SLIDER_RENDER_BIOME_OUTLINE_ALPHA;
      return true;
    }
    if (layout.biomeUnderwaterCheckbox.contains(mx, my)) {
      renderSettings.biomeShowUnderwater = !renderSettings.biomeShowUnderwater;
      return true;
    }
  }

  // Shading
  if (renderSectionShadingOpen) {
    if (layout.waterDepthAlphaSlider.contains(mx, my)) {
      float t = constrain((mx - layout.waterDepthAlphaSlider.x) / (float)layout.waterDepthAlphaSlider.w, 0, 1);
      renderSettings.waterDepthAlpha01 = t;
      activeSlider = SLIDER_RENDER_WATER_DEPTH_ALPHA;
      return true;
    }
    if (layout.lightAlphaSlider.contains(mx, my)) {
      float t = constrain((mx - layout.lightAlphaSlider.x) / (float)layout.lightAlphaSlider.w, 0, 1);
      renderSettings.elevationLightAlpha01 = t;
      activeSlider = SLIDER_RENDER_LIGHT_ALPHA;
      return true;
    }
    if (layout.lightAzimuthSlider.contains(mx, my)) {
      float t = constrain((mx - layout.lightAzimuthSlider.x) / (float)layout.lightAzimuthSlider.w, 0, 1);
      renderSettings.elevationLightAzimuthDeg = constrain(t * 360.0f, 0, 360.0f);
      activeSlider = SLIDER_RENDER_LIGHT_AZIMUTH;
      return true;
    }
    if (layout.lightAltitudeSlider.contains(mx, my)) {
      float t = constrain((mx - layout.lightAltitudeSlider.x) / (float)layout.lightAltitudeSlider.w, 0, 1);
      renderSettings.elevationLightAltitudeDeg = constrain(5.0f + t * (80.0f - 5.0f), 5.0f, 80.0f);
      activeSlider = SLIDER_RENDER_LIGHT_ALTITUDE;
      return true;
    }
  }

  // Contours
  if (renderSectionContoursOpen) {
    if (layout.waterContourSizeSlider.contains(mx, my)) {
      float t = constrain((mx - layout.waterContourSizeSlider.x) / (float)layout.waterContourSizeSlider.w, 0, 1);
      renderSettings.waterContourSizePx = constrain(t * 5.0f, 0, 5.0f);
      activeSlider = SLIDER_RENDER_WATER_CONTOUR_SIZE;
      return true;
    }
    if (layout.waterRippleCountSlider.contains(mx, my)) {
      float t = constrain((mx - layout.waterRippleCountSlider.x) / (float)layout.waterRippleCountSlider.w, 0, 1);
      renderSettings.waterRippleCount = constrain(round(t * 5.0f), 0, 5);
      activeSlider = SLIDER_RENDER_WATER_RIPPLE_COUNT;
      return true;
    }
    if (layout.waterRippleDistanceSlider.contains(mx, my)) {
      float t = constrain((mx - layout.waterRippleDistanceSlider.x) / (float)layout.waterRippleDistanceSlider.w, 0, 1);
      renderSettings.waterRippleDistancePx = constrain(t * 40.0f, 0.0f, 40.0f);
      activeSlider = SLIDER_RENDER_WATER_RIPPLE_DIST;
      return true;
    }
    if (layout.waterContourHSB[0].contains(mx, my)) { renderSettings.waterContourHue01 = constrain((mx - layout.waterContourHSB[0].x) / (float)layout.waterContourHSB[0].w, 0, 1); activeSlider = SLIDER_RENDER_WATER_CONTOUR_H; return true; }
    if (layout.waterContourHSB[1].contains(mx, my)) { renderSettings.waterContourSat01 = constrain((mx - layout.waterContourHSB[1].x) / (float)layout.waterContourHSB[1].w, 0, 1); activeSlider = SLIDER_RENDER_WATER_CONTOUR_S; return true; }
    if (layout.waterContourHSB[2].contains(mx, my)) { renderSettings.waterContourBri01 = constrain((mx - layout.waterContourHSB[2].x) / (float)layout.waterContourHSB[2].w, 0, 1); activeSlider = SLIDER_RENDER_WATER_CONTOUR_B; return true; }
    if (layout.waterContourAlphaSlider.contains(mx, my)) {
      float t = constrain((mx - layout.waterContourAlphaSlider.x) / (float)layout.waterContourAlphaSlider.w, 0, 1);
      renderSettings.waterContourAlpha01 = t;
      activeSlider = SLIDER_RENDER_WATER_CONTOUR_ALPHA;
      return true;
    }
    if (layout.elevationLinesCountSlider.contains(mx, my)) {
      float t = constrain((mx - layout.elevationLinesCountSlider.x) / (float)layout.elevationLinesCountSlider.w, 0, 1);
      renderSettings.elevationLinesCount = constrain(round(t * 24.0f), 0, 24);
      activeSlider = SLIDER_RENDER_ELEV_LINES_COUNT;
      return true;
    }
    if (layout.elevationLineStyleSelector.contains(mx, my)) {
      renderSettings.elevationLinesStyle = ElevationLinesStyle.ELEV_LINES_BASIC;
      activeSlider = SLIDER_RENDER_ELEV_LINES_STYLE;
      return true;
    }
    if (layout.elevationLinesAlphaSlider.contains(mx, my)) {
      float t = constrain((mx - layout.elevationLinesAlphaSlider.x) / (float)layout.elevationLinesAlphaSlider.w, 0, 1);
      renderSettings.elevationLinesAlpha01 = t;
      activeSlider = SLIDER_RENDER_ELEV_LINES_ALPHA;
      return true;
    }
  }

  // Paths
  if (renderSectionPathsOpen) {
    if (layout.pathsShowCheckbox.contains(mx, my)) {
      renderSettings.showPaths = !renderSettings.showPaths;
      renderShowPaths = renderSettings.showPaths;
      return true;
    }
    if (layout.pathSatSlider.contains(mx, my)) {
      float t = constrain((mx - layout.pathSatSlider.x) / (float)layout.pathSatSlider.w, 0, 1);
      renderSettings.pathSatScale01 = t;
      activeSlider = SLIDER_RENDER_PATH_SAT;
      return true;
    }
  }

  // Zones
  if (renderSectionZonesOpen) {
    if (layout.zoneAlphaSlider.contains(mx, my)) {
      float t = constrain((mx - layout.zoneAlphaSlider.x) / (float)layout.zoneAlphaSlider.w, 0, 1);
      renderSettings.zoneStrokeAlpha01 = t;
      renderShowZoneOutlines = t > 0.001f;
      activeSlider = SLIDER_RENDER_ZONE_ALPHA;
      return true;
    }
    if (layout.zoneSatSlider.contains(mx, my)) {
      float t = constrain((mx - layout.zoneSatSlider.x) / (float)layout.zoneSatSlider.w, 0, 1);
      renderSettings.zoneStrokeSatScale01 = t;
      activeSlider = SLIDER_RENDER_ZONE_SAT;
      return true;
    }
    if (layout.zoneBriSlider.contains(mx, my)) {
      float t = constrain((mx - layout.zoneBriSlider.x) / (float)layout.zoneBriSlider.w, 0, 1);
      renderSettings.zoneStrokeBriScale01 = t;
      activeSlider = SLIDER_RENDER_ZONE_BRI;
      return true;
    }
  }

  // Structures
  if (renderSectionStructuresOpen) {
    if (layout.structuresShowCheckbox.contains(mx, my)) {
      renderSettings.showStructures = !renderSettings.showStructures;
      renderShowStructures = renderSettings.showStructures;
      return true;
    }
    if (layout.structuresMergeCheckbox.contains(mx, my)) {
      renderSettings.mergeStructures = !renderSettings.mergeStructures;
      return true;
    }
  }

  // Labels
  if (renderSectionLabelsOpen) {
    if (layout.labelsArbitraryCheckbox.contains(mx, my)) {
      renderSettings.showLabelsArbitrary = !renderSettings.showLabelsArbitrary;
      renderShowLabels = renderSettings.showLabelsArbitrary;
      return true;
    }
    if (layout.labelsZonesCheckbox.contains(mx, my)) {
      renderSettings.showLabelsZones = !renderSettings.showLabelsZones;
      renderShowLabels = renderSettings.showLabelsArbitrary;
      return true;
    }
    if (layout.labelsPathsCheckbox.contains(mx, my)) {
      renderSettings.showLabelsPaths = !renderSettings.showLabelsPaths;
      renderShowLabels = renderSettings.showLabelsArbitrary;
      return true;
    }
    if (layout.labelsStructuresCheckbox.contains(mx, my)) {
      renderSettings.showLabelsStructures = !renderSettings.showLabelsStructures;
      renderShowLabels = renderSettings.showLabelsArbitrary;
      return true;
    }
    if (layout.labelsOutlineAlphaSlider.contains(mx, my)) {
      float t = constrain((mx - layout.labelsOutlineAlphaSlider.x) / (float)layout.labelsOutlineAlphaSlider.w, 0, 1);
      renderSettings.labelOutlineAlpha01 = t;
      activeSlider = SLIDER_RENDER_LABEL_OUTLINE_ALPHA;
      return true;
    }
  }

  // General
  if (renderSectionGeneralOpen) {
    if (layout.exportPaddingSlider.contains(mx, my)) {
      float t = constrain((mx - layout.exportPaddingSlider.x) / (float)layout.exportPaddingSlider.w, 0, 1);
      renderSettings.exportPaddingPct = constrain(t * 0.10f, 0, 0.10f);
      renderPaddingPct = renderSettings.exportPaddingPct;
      activeSlider = SLIDER_RENDER_PADDING;
      return true;
    }
    if (layout.antialiasCheckbox.contains(mx, my)) {
      renderSettings.antialiasing = !renderSettings.antialiasing;
      return true;
    }
    if (layout.presetSelector.contains(mx, my) && renderPresets != null && renderPresets.length > 0) {
      int n = max(1, renderPresets.length - 1);
      float t = constrain((mx - layout.presetSelector.x) / (float)layout.presetSelector.w, 0, 1);
      int idx = constrain(round(t * n), 0, renderPresets.length - 1);
      renderSettings.activePresetIndex = idx;
      activeSlider = SLIDER_RENDER_PRESET_SELECT;
      return true;
    }
    if (queueButtonAction(layout.presetApplyBtn, new Runnable() { public void run() {
      applyRenderPreset(renderSettings.activePresetIndex);
    }})) return true;
  }
  return false;
}

boolean handleExportPanelClick(int mx, int my) {
  if (!isInExportPanel(mx, my)) return false;
  ExportLayout layout = buildExportLayout();
  if (queueButtonAction(layout.pngBtn, new Runnable() { public void run() {
    String path = exportPng();
    if (path != null && path.length() > 0 && !path.startsWith("Failed")) {
      lastExportStatus = path;
      showNotice("Saved PNG: " + path);
    } else {
      lastExportStatus = (path != null) ? path : "Export failed";
      showNotice("Export failed");
    }
  }})) return true;
  if (layout.scaleSlider != null && layout.scaleSlider.contains(mx, my)) {
    float t = constrain((mx - layout.scaleSlider.x) / (float)layout.scaleSlider.w, 0, 1);
    exportScale = constrain(1.0f + t * (4.0f - 1.0f), 1.0f, 4.0f);
    activeSlider = SLIDER_EXPORT_SCALE;
    return true;
  }
  return false;
}

// ----- Elevation panel click -----

boolean handleElevationPanelClick(int mx, int my) {
  if (!isInElevationPanel(mx, my)) return false;
  ElevationLayout layout = buildElevationLayout();

  // Sea level
  if (layout.seaSlider.contains(mx, my)) {
    float t = constrain((mx - layout.seaSlider.x) / (float)layout.seaSlider.w, 0, 1);
    seaLevel = lerp(-1.2f, 1.2f, t);
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
  if (queueButtonAction(layout.raiseBtn, new Runnable() { public void run() {
    elevationBrushRaise = true;
  }})) return true;
  if (queueButtonAction(layout.lowerBtn, new Runnable() { public void run() {
    elevationBrushRaise = false;
  }})) return true;

  // Noise scale slider
  if (layout.noiseSlider.contains(mx, my)) {
    float t = constrain((mx - layout.noiseSlider.x) / (float)layout.noiseSlider.w, 0, 1);
    elevationNoiseScale = constrain(1.0f + t * (12.0f - 1.0f), 1.0f, 12.0f);
    activeSlider = SLIDER_ELEV_NOISE;
    return true;
  }

  // Generate button
  if (queueButtonAction(layout.perlinBtn, new Runnable() { public void run() {
    noiseSeed((int)random(Integer.MAX_VALUE));
    mapModel.generateElevationNoise(elevationNoiseScale, 1.0f, seaLevel);
  }})) return true;

  // Vary button
  if (queueButtonAction(layout.varyBtn, new Runnable() { public void run() {
    noiseSeed((int)random(Integer.MAX_VALUE));
    mapModel.addElevationVariation(elevationNoiseScale, 0.2f, seaLevel);
  }})) return true;

  // Plateaux button
  if (queueButtonAction(layout.plateauBtn, new Runnable() { public void run() {
    mapModel.makePlateaus(seaLevel);
  }})) return true;

  return false;
}
