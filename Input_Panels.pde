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

boolean isInAdminPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_ADMIN) return false;
  AdminLayout layout = buildAdminLayout();
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

  if (mapModel.isVoronoiBuilding()) {
    showNotice("Please wait for generation to finish...");
    return true;
  }

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
    boolean hasNone = mapModel.hasAnyNoneBiome();
    if (hasNone) {
      mapModel.generateZonesFromSeeds();
    } else {
      mapModel.resetAllBiomesToNone();
      mapModel.generateZonesFromSeeds();
      activeBiomeIndex = 0;
      editingZoneNameIndex = -1;
    }
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
    if (sw.contains(mx, my)) {
      activeBiomeIndex = i;
      return true;
    }
  }

  // Name field for selected biome
  if (layout.nameField.contains(mx, my) && activeBiomeIndex >= 0 && activeBiomeIndex < n) {
    editingZoneNameIndex = activeBiomeIndex;
    zoneNameDraft = mapModel.biomeTypes.get(activeBiomeIndex).name;
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

// ----- Admin panel click -----
boolean handleAdminPanelClick(int mx, int my) {
  if (!isInAdminPanel(mx, my)) return false;
  if (mapModel == null || mapModel.adminZones == null) return false;

  AdminLayout layout = buildAdminLayout();

  if (layout.paintBtn.contains(mx, my)) {
    currentZonePaintMode = ZonePaintMode.ZONE_PAINT;
    return true;
  }
  if (layout.fillBtn.contains(mx, my)) {
    currentZonePaintMode = ZonePaintMode.ZONE_FILL;
    return true;
  }

  if (layout.generateBtn.contains(mx, my)) {
    // Fill all "None" admin cells with the currently selected admin type (or first non-None)
    int target = (activeAdminIndex >= 0) ? activeAdminIndex : 0;
    if (target >= 0 && target < mapModel.adminZones.size() && mapModel.cells != null) {
      for (Cell c : mapModel.cells) {
        int idx = mapModel.indexOfCell(c);
        mapModel.addCellToAdminZone(idx, target);
      }
    }
    return true;
  }

  if (layout.resetBtn.contains(mx, my)) {
    mapModel.resetAllAdminsToNone();
    activeAdminIndex = 0;
    editingAdminNameIndex = -1;
    return true;
  }

  int nTypes = mapModel.adminZones.size();

  if (layout.addBtn.contains(mx, my)) {
    mapModel.addAdminType();
    activeAdminIndex = mapModel.adminZones.size() - 1;
    return true;
  }

  boolean canRemove = nTypes > 1 && activeAdminIndex > 0;
  if (canRemove && layout.removeBtn.contains(mx, my)) {
    mapModel.removeAdminType(activeAdminIndex);
    activeAdminIndex = constrain(activeAdminIndex - 1, 0, mapModel.adminZones.size() - 1);
    editingAdminNameIndex = -1;
    return true;
  }

  for (int i = 0; i < nTypes; i++) {
    IntRect sw = layout.swatches.get(i);
    if (sw.contains(mx, my)) {
      activeAdminIndex = i;
      return true;
    }
  }

  if (layout.nameField.contains(mx, my) && activeAdminIndex >= 0 && activeAdminIndex < nTypes) {
    editingAdminNameIndex = activeAdminIndex;
    adminNameDraft = mapModel.adminZones.get(activeAdminIndex).name;
    return true;
  }

  if (layout.hueSlider.contains(mx, my) && activeAdminIndex >= 0 && activeAdminIndex < nTypes) {
    float t = (mx - layout.hueSlider.x) / (float)layout.hueSlider.w;
    t = constrain(t, 0, 1);
    MapModel.AdminZone zt = mapModel.adminZones.get(activeAdminIndex);
    zt.hue01 = t;
    zt.updateColorFromHSB();
    activeSlider = SLIDER_ADMIN_HUE;
    return true;
  }

  if (layout.brushSlider.contains(mx, my)) {
    float t = constrain((mx - layout.brushSlider.x) / (float)layout.brushSlider.w, 0, 1);
    zoneBrushRadius = constrain(0.01f + t * (0.15f - 0.01f), 0.01f, 0.15f);
    activeSlider = SLIDER_ADMIN_BRUSH;
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

void paintAdminAt(float wx, float wy) {
  Cell c = mapModel.findCellContaining(wx, wy);
  if (c != null) {
    int idx = mapModel.indexOfCell(c);
    mapModel.addCellToAdminZone(idx, activeAdminIndex);
  }
}

void fillAdminAt(float wx, float wy) {
  Cell c = mapModel.findCellContaining(wx, wy);
  if (c != null) {
    mapModel.floodFillAdminZone(c, activeAdminIndex);
  }
}

void paintAdminBrush(float wx, float wy) {
  if (mapModel.cells == null) return;
  float r2 = zoneBrushRadius * zoneBrushRadius;
  for (Cell c : mapModel.cells) {
    PVector cen = mapModel.cellCentroid(c);
    float dx = cen.x - wx;
    float dy = cen.y - wy;
    float d2 = dx * dx + dy * dy;
    if (d2 <= r2) {
      int idx = mapModel.indexOfCell(c);
      mapModel.addCellToAdminZone(idx, activeAdminIndex);
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
    if (handleZonesPanelClick(mouseX, mouseY)) return;
  }

  // Admin panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_ADMIN) {
    if (handleAdminPanelClick(mouseX, mouseY)) return;
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
    } else if (currentTool == Tool.EDIT_ADMIN) {
      if (currentZonePaintMode == ZonePaintMode.ZONE_PAINT) {
        paintAdminBrush(worldPos.x, worldPos.y);
      } else {
        fillAdminAt(worldPos.x, worldPos.y);
      }
    } else if (currentTool == Tool.EDIT_ELEVATION) {
      float dir = elevationBrushRaise ? 1 : -1;
      mapModel.applyElevationBrush(worldPos.x, worldPos.y, elevationBrushRadius, elevationBrushStrength * dir, seaLevel);
    } else if (currentTool == Tool.EDIT_PATHS) {
      handlePathsMousePressed(worldPos.x, worldPos.y);
    } else if (currentTool == Tool.EDIT_STRUCTURES) {
      Structure s = mapModel.computeSnappedStructure(worldPos.x, worldPos.y, structureSize);
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
    String[] modes = { "Ends", "Pathfind" };
    int modeCount = modes.length;
    float t = constrain((mx - layout.routeSlider.x) / (float)layout.routeSlider.w, 0, 1);
    int idx = round(t * (modeCount - 1));
    pathRouteModeIndex = constrain(idx, 0, modeCount - 1);
    activeSlider = SLIDER_NONE;
    return true;
  }

  if (layout.flattestSlider.contains(mx, my)) {
    float t = constrain((mx - layout.flattestSlider.x) / (float)layout.flattestSlider.w, 0, 1);
    flattestSlopeBias = constrain(FLATTEST_BIAS_MIN + t * (FLATTEST_BIAS_MAX - FLATTEST_BIAS_MIN),
                                  FLATTEST_BIAS_MIN, FLATTEST_BIAS_MAX);
    activeSlider = SLIDER_FLATTEST_BIAS;
    return true;
  }

  if (layout.avoidWaterCheck.contains(mx, my)) {
    pathAvoidWater = !pathAvoidWater;
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
    if (sw.contains(mx, my)) {
      activePathTypeIndex = i;
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
  populatePathsListRows(layout);

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

  for (int i = 0; i < layout.rows.size(); i++) {
    PathRowLayout row = layout.rows.get(i);
    Path p = mapModel.paths.get(i);

    if (row.selectRect.contains(mx, my) || row.nameRect.contains(mx, my)) {
      selectedPathIndex = i;
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

