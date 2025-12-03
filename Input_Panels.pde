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

boolean handleToolButtonClick(int mx, int my) {
  int barY = TOP_BAR_HEIGHT;
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

  String[] labels = { "Cells", "Elevation", "Biomes", "Zones", "Paths", "Struct", "Labels", "Rendering", "Export" };
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
    int x = margin + i * (buttonW + 5);
    int y = barY + 2;
    int bx1 = x;
    int by1 = y;
    int bx2 = x + buttonW;
    int by2 = y + (barH - 4);
    if (mx >= bx1 && mx <= bx2 && my >= by1 && my <= by2) {
      // Clear selections when switching modes
      selectedPathIndex = -1;
      pendingPathStart = null;
      selectedStructureIndex = -1;
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
  if (layout.generateBtn.contains(mx, my)) {
    mapModel.generateSites(currentPlacementMode(), siteTargetCount, keepPropertiesOnGenerate);
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

boolean handleBiomesPanelClick(int mx, int my) {
  if (!isInBiomesPanel(mx, my)) return false;
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
    boolean hasNone = mapModel.hasAnyNoneBiome();
    if (hasNone) {
      mapModel.generateZonesFromSeeds();
    } else {
      mapModel.resetAllBiomesToNone();
      mapModel.generateZonesFromSeeds();
      activeBiomeIndex = 0;
      editingBiomeNameIndex = -1;
    }
    return true;
  }

  // Reset button
  if (layout.resetBtn.contains(mx, my)) {
    mapModel.resetAllBiomesToNone();
    activeBiomeIndex = 0;
    editingBiomeNameIndex = -1;
    return true;
  }

  // Fill underwater button
  if (layout.fillUnderwaterBtn.contains(mx, my)) {
    mapModel.setUnderwaterToBiome(activeBiomeIndex, seaLevel);
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

  if (layout.resetBtn.contains(mx, my)) {
    mapModel.resetAllZonesToNone();
    activeZoneIndex = -1;
    editingZoneNameIndex = -1;
    return true;
  }

  if (layout.regenerateBtn.contains(mx, my)) {
    int target = max(3, mapModel.zones.size());
    mapModel.regenerateRandomZones(target);
    activeZoneIndex = !mapModel.zones.isEmpty() ? 0 : -1;
    editingZoneNameIndex = -1;
    return true;
  }

  return false;
}

boolean handleZonesListPanelClick(int mx, int my) {
  if (!isInZonesListPanel(mx, my)) return false;
  ZonesListLayout layout = buildZonesListLayout();
  populateZonesRows(layout);

  if (layout.deselectBtn.contains(mx, my)) {
    activeZoneIndex = -1;
    editingZoneNameIndex = -1;
    return true;
  }

  if (layout.newBtn.contains(mx, my)) {
    mapModel.addZone();
    activeZoneIndex = mapModel.zones.size() - 1;
    return true;
  }

  for (int i = 0; i < layout.rows.size(); i++) {
    MapModel.MapZone az = mapModel.zones.get(i);
    ZoneRowLayout row = layout.rows.get(i);

    if (row.selectRect.contains(mx, my)) {
      activeZoneIndex = i;
      editingZoneNameIndex = -1;
      return true;
    }

    if (row.nameRect.contains(mx, my)) {
      activeZoneIndex = i;
      editingZoneNameIndex = i;
      zoneNameDraft = az.name;
      return true;
    }

    if (row.hueSlider.contains(mx, my)) {
      activeZoneIndex = i;
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

// ---------- Mouse & keyboard callbacks ----------

void mousePressed() {
  // Block interactions while generation is running; show notice
  if (mapModel.isVoronoiBuilding() && mouseButton == LEFT) {
    showNotice("Please wait for generation to finish...");
    return;
  }

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
  if (mouseY < TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT) return;
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
      if (currentZonePaintMode == ZonePaintMode.ZONE_PAINT) {
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

  if (layout.eraserBtn.contains(mx, my)) {
    pathEraserMode = !pathEraserMode;
    pendingPathStart = null;
    return true;
  }
  if (layout.taperCheck.contains(mx, my)) {
    if (activePathTypeIndex >= 0 && activePathTypeIndex < mapModel.pathTypes.size()) {
      PathType pt = mapModel.pathTypes.get(activePathTypeIndex);
      pt.taperOn = !pt.taperOn;
    }
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
        syncActivePathTypeGlobals();
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
    syncActivePathTypeGlobals();
    return true;
  }

  int nTypes = mapModel.pathTypes.size();

  // Swatches and names
  for (int i = 0; i < nTypes; i++) {
    IntRect sw = layout.typeSwatches.get(i);
    if (sw.contains(mx, my)) {
      activePathTypeIndex = i;
      syncActivePathTypeGlobals();
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
  LabelsLayout layout = buildLabelsLayout();
  for (int i = 0; i < layout.targetButtons.size(); i++) {
    IntRect b = layout.targetButtons.get(i);
    if (b.contains(mx, my)) {
      labelTargetMode = LabelTarget.values()[i];
      return true;
    }
  }
  return false;
}

boolean handleLabelsListPanelClick(int mx, int my) {
  if (!isInLabelsListPanel(mx, my)) return false;
  LabelsListLayout layout = buildLabelsListLayout();
  populateLabelsListRows(layout);

  if (layout.deselectBtn.contains(mx, my)) {
    selectedLabelIndex = -1;
    editingLabelIndex = -1;
    labelDraft = "label";
    return true;
  }

  for (int i = 0; i < layout.rows.size(); i++) {
    LabelRowLayout row = layout.rows.get(i);
    MapLabel lbl = mapModel.labels.get(i);
    if (row.selectRect.contains(mx, my) || row.nameRect.contains(mx, my)) {
      selectedLabelIndex = i;
      if (row.nameRect.contains(mx, my)) {
        editingLabelIndex = i;
        labelDraft = lbl.text;
      } else {
        editingLabelIndex = -1;
        labelDraft = lbl.text;
      }
      return true;
    }
    if (row.delRect.contains(mx, my)) {
      mapModel.labels.remove(i);
      if (selectedLabelIndex == i) selectedLabelIndex = -1;
      if (editingLabelIndex == i) editingLabelIndex = -1;
      labelDraft = "label";
      return true;
    }
    if (row.targetRect.contains(mx, my)) {
      lbl.target = nextLabelTarget(lbl.target);
      return true;
    }
  }
  return false;
}

LabelTarget nextLabelTarget(LabelTarget lt) {
  switch (lt) {
    case FREE: return LabelTarget.BIOME;
    case BIOME: return LabelTarget.ZONE;
    case ZONE: return LabelTarget.STRUCT;
    default: return LabelTarget.FREE;
  }
}

boolean handlePathsListPanelClick(int mx, int my) {
  if (!isInPathsListPanel(mx, my)) return false;
  PathsListLayout layout = buildPathsListLayout();
  populatePathsListRows(layout);

  if (layout.deselectBtn.contains(mx, my)) {
    selectedPathIndex = -1;
    pendingPathStart = null;
    editingPathNameIndex = -1;
    return true;
  }

  // New path button
  if (layout.newBtn.contains(mx, my)) {
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
    return true;
  }

  for (int i = 0; i < layout.rows.size(); i++) {
    PathRowLayout row = layout.rows.get(i);
    Path p = mapModel.paths.get(i);

    if (row.selectRect.contains(mx, my) || row.nameRect.contains(mx, my)) {
      selectedPathIndex = i;
      if (p != null && p.typeId >= 0 && p.typeId < mapModel.pathTypes.size()) {
        activePathTypeIndex = p.typeId;
        syncActivePathTypeGlobals();
      }
      editingPathNameIndex = row.nameRect.contains(mx, my) ? i : -1;
      if (editingPathNameIndex == i) {
        pathNameDraft = (p.name != null) ? p.name : "";
      } else {
        pendingPathStart = null;
      }
      return true;
    }
    if (row.delRect.contains(mx, my)) {
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
    if (row.typeRect.contains(mx, my)) {
      if (!mapModel.pathTypes.isEmpty()) {
        p.typeId = (p.typeId + 1) % mapModel.pathTypes.size();
        activePathTypeIndex = p.typeId;
        syncActivePathTypeGlobals();
      }
      return true;
    }
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
    IntRect b = layout.shapeButtons.get(i);
    if (b.contains(mx, my)) {
      structureShape = StructureShape.values()[i];
      return true;
    }
  }
  for (int i = 0; i < layout.snapButtons.size(); i++) {
    IntRect b = layout.snapButtons.get(i);
    if (b.contains(mx, my)) {
      structureSnapMode = StructureSnapMode.values()[i];
      return true;
    }
  }
  return false;
}

boolean handleStructuresListPanelClick(int mx, int my) {
  if (!isInStructuresListPanel(mx, my)) return false;
  StructuresListLayout layout = buildStructuresListLayout();
  populateStructuresListRows(layout);

  if (layout.deselectBtn.contains(mx, my)) {
    selectedStructureIndex = -1;
    return true;
  }

  for (int i = 0; i < layout.rows.size(); i++) {
    StructureRowLayout row = layout.rows.get(i);
    if (row.selectRect.contains(mx, my) || row.nameRect.contains(mx, my)) {
      selectedStructureIndex = i;
      return true;
    }
    if (row.delRect.contains(mx, my)) {
      mapModel.structures.remove(i);
      if (selectedStructureIndex == i) selectedStructureIndex = -1;
      else if (selectedStructureIndex > i) selectedStructureIndex -= 1;
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
  if (layout.checks.get(2).contains(mx, my)) { renderWaterContours = !renderWaterContours; return true; }
  if (layout.checks.get(3).contains(mx, my)) { renderShowElevation = !renderShowElevation; return true; }
  if (layout.checks.get(4).contains(mx, my)) { renderElevationContours = !renderElevationContours; return true; }

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

  if (layout.checks.get(5).contains(mx, my)) { renderShowPaths = !renderShowPaths; return true; }
  if (layout.checks.get(6).contains(mx, my)) { renderShowLabels = !renderShowLabels; return true; }
  if (layout.checks.get(7).contains(mx, my)) { renderShowStructures = !renderShowStructures; return true; }
  if (layout.checks.size() > 8 && layout.checks.get(8).contains(mx, my)) { renderBlackWhite = !renderBlackWhite; return true; }
  return false;
}

boolean handleExportPanelClick(int mx, int my) {
  if (!isInExportPanel(mx, my)) return false;
  // Placeholder: export panel will get actionable controls later.
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
    noiseSeed((int)random(Integer.MAX_VALUE));
    mapModel.generateElevationNoise(elevationNoiseScale, 1.0f, seaLevel);
    return true;
  }

  // Vary button
  if (layout.varyBtn.contains(mx, my)) {
    noiseSeed((int)random(Integer.MAX_VALUE));
    mapModel.addElevationVariation(elevationNoiseScale, 0.2f, seaLevel);
    return true;
  }

  return false;
}

