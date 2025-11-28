// ---------- Input helpers ----------

boolean isInSitesPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_SITES) return false;
  int y0 = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
  int y1 = y0 + SITES_PANEL_HEIGHT;
  return (my >= y0 && my <= y1);
}

boolean isInZonesPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_ZONES) return false;
  int y0 = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
  int y1 = y0 + ZONES_PANEL_HEIGHT;
  return (my >= y0 && my <= y1);
}

boolean isInElevationPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_ELEVATION) return false;
  int y0 = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
  int y1 = y0 + ELEV_PANEL_HEIGHT;
  return (my >= y0 && my <= y1);
}

boolean isInPathsPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_PATHS) return false;
  int y0 = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
  int y1 = y0 + PATH_PANEL_HEIGHT;
  return (my >= y0 && my <= y1);
}

boolean handleToolButtonClick(int mx, int my) {
  int barY = TOP_BAR_HEIGHT;
  int barH = TOOL_BAR_HEIGHT;

  if (my < barY || my > barY + barH) {
    return false;
  }

  int margin = 10;
  int buttonW = 90;

  String[] labels = { "Sites", "Zones", "Elevation", "Paths", "Struct", "Labels" };
  Tool[] tools = {
    Tool.EDIT_SITES,
    Tool.EDIT_ZONES,
    Tool.EDIT_ELEVATION,
    Tool.EDIT_PATHS,
    Tool.EDIT_STRUCTURES,
    Tool.EDIT_LABELS
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

  int panelY = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;

  int sliderX = 10;
  int sliderW = 250;
  int sliderH = 16;

  // Density slider
  int densityY = panelY + 25;
  if (mx >= sliderX && mx <= sliderX + sliderW &&
      my >= densityY && my <= densityY + sliderH) {
    float t = (mx - sliderX) / (float)sliderW;
    siteDensity = constrain(t, 0, 1);
    return true;
  }

  // Fuzz slider (0..1 mapped to 0..0.3)
  int fuzzY = panelY + 25 + 22;
  if (mx >= sliderX && mx <= sliderX + sliderW &&
      my >= fuzzY && my <= fuzzY + sliderH) {
    float t = (mx - sliderX) / (float)sliderW;
    t = constrain(t, 0, 1);
    siteFuzz = t * 0.3f;
    return true;
  }

  // Mode slider
  int modeSliderX = 10;
  int modeSliderY = panelY + 25 + 44;
  int modeSliderW = sliderW;
  int modeSliderH = 14;

  if (mx >= modeSliderX && mx <= modeSliderX + modeSliderW &&
      my >= modeSliderY && my <= modeSliderY + modeSliderH) {
    int modeCount = placementModes.length;
    if (modeCount < 1) modeCount = 1;
    float t = (mx - modeSliderX) / (float)modeSliderW;
    t = constrain(t, 0, 1);
    int idx = round(t * (modeCount - 1));
    placementModeIndex = constrain(idx, 0, placementModes.length - 1);
    return true;
  }

  // Generate button
  int genW = 100;
  int genH = 24;
  int genX = 10;
  int genY = modeSliderY + 24;

  if (mx >= genX && mx <= genX + genW &&
      my >= genY && my <= genY + genH) {
    mapModel.generateSites(currentPlacementMode(), siteDensity);
    return true;
  }

  return false;
}

// ----- Zones panel click (tool + biome selection + add/remove + hue) -----

boolean handleZonesPanelClick(int mx, int my) {
  if (!isInZonesPanel(mx, my)) return false;
  if (mapModel == null || mapModel.biomeTypes == null) return false;

  int panelY = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;

  // Tool buttons
  int toolBtnW = 60;
  int toolBtnH = 20;
  int toolX1 = 10;
  int toolX2 = toolX1 + toolBtnW + 8;
  int toolY  = panelY + 24;

  // Paint button
  if (mx >= toolX1 && mx <= toolX1 + toolBtnW &&
      my >= toolY && my <= toolY + toolBtnH) {
    currentZonePaintMode = ZonePaintMode.ZONE_PAINT;
    return true;
  }

  // Fill button
  if (mx >= toolX2 && mx <= toolX2 + toolBtnW &&
      my >= toolY && my <= toolY + toolBtnH) {
    currentZonePaintMode = ZonePaintMode.ZONE_FILL;
    return true;
  }

  // Add / Remove biome type buttons
  int addBtnW = 24;
  int addBtnH = 20;
  int addX = toolX2 + toolBtnW + 20;
  int addY = toolY;

  int remX = addX + addBtnW + 6;
  int remY = toolY;

  int nTypes = mapModel.biomeTypes.size();

  // "+" button
  if (mx >= addX && mx <= addX + addBtnW &&
      my >= addY && my <= addY + addBtnH) {
    mapModel.addBiomeType();
    activeBiomeIndex = mapModel.biomeTypes.size() - 1;
    return true;
  }

  // "-" button
  boolean canRemove = (nTypes > 1 && activeBiomeIndex > 0);
  if (canRemove &&
      mx >= remX && mx <= remX + addBtnW &&
      my >= remY && my <= remY + addBtnH) {

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

  int swatchW = 60;
  int swatchH = 18;
  int marginX = 10;
  int gapX = 8;

  int rowY = toolY + toolBtnH + 10;

  for (int i = 0; i < n; i++) {
    int x = marginX + i * (swatchW + gapX);
    int y = rowY;
    int x2 = x + swatchW;
    int y2 = y + swatchH;

    if (mx >= x && mx <= x2 && my >= y && my <= y2) {
      activeBiomeIndex = i;
      return true;
    }
  }

  // Hue slider
  if (activeBiomeIndex >= 0 && activeBiomeIndex < n) {
    int hueSliderX = 10;
    int hueSliderW = 250;
    int hueSliderH = 14;
    int hueSliderY = rowY + swatchH + 20;

    if (mx >= hueSliderX && mx <= hueSliderX + hueSliderW &&
        my >= hueSliderY && my <= hueSliderY + hueSliderH) {

      float t = (mx - hueSliderX) / (float)hueSliderW;
      t = constrain(t, 0, 1);

      ZoneType active = mapModel.biomeTypes.get(activeBiomeIndex);
      active.hue01 = t;
      active.updateColorFromHSB();

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

  // Zones panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_ZONES) {
    if (handleZonesPanelClick(mouseX, mouseY)) return;
  }

  // Elevation panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_ELEVATION) {
    if (handleElevationPanelClick(mouseX, mouseY)) return;
  }

  // Paths panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_PATHS) {
    if (handlePathsPanelClick(mouseX, mouseY)) return;
  }

  // Ignore world interaction if inside any top UI area
  int uiBottom = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
  if (currentTool == Tool.EDIT_SITES) {
    uiBottom += SITES_PANEL_HEIGHT;
  } else if (currentTool == Tool.EDIT_ZONES) {
    uiBottom += ZONES_PANEL_HEIGHT;
  } else if (currentTool == Tool.EDIT_ELEVATION) {
    uiBottom += ELEV_PANEL_HEIGHT;
  } else if (currentTool == Tool.EDIT_PATHS) {
    uiBottom += PATH_PANEL_HEIGHT;
  }
  if (mouseY < uiBottom) return;

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
    } else if (currentTool == Tool.EDIT_ZONES) {
      if (currentZonePaintMode == ZonePaintMode.ZONE_PAINT) {
        paintBiomeAt(worldPos.x, worldPos.y);
      } else {
        fillBiomeAt(worldPos.x, worldPos.y);
      }
    } else if (currentTool == Tool.EDIT_ELEVATION) {
      float dir = elevationBrushRaise ? 1 : -1;
      mapModel.applyElevationBrush(worldPos.x, worldPos.y, elevationBrushRadius, elevationBrushStrength * dir);
    } else if (currentTool == Tool.EDIT_PATHS) {
      handlePathsMousePressed(worldPos.x, worldPos.y);
    }
  }
}

void handleSitesMousePressed(float wx, float wy) {
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

  int panelY = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
  int btnW = 120;
  int btnH = 22;
  int btnY = panelY + 12;
  int btnX1 = 120;
  int btnX2 = btnX1 + btnW + 10;

  // Close (Enter)
  if (mx >= btnX1 && mx <= btnX1 + btnW &&
      my >= btnY && my <= btnY + btnH) {
    if (currentTool == Tool.EDIT_PATHS && isDrawingPath && currentPath != null) {
      mapModel.addFinishedPath(currentPath);
      isDrawingPath = false;
      currentPath = null;
    }
    return true;
  }

  // Undo (Del)
  if (mx >= btnX2 && mx <= btnX2 + btnW &&
      my >= btnY && my <= btnY + btnH) {
    if (currentTool == Tool.EDIT_PATHS && isDrawingPath && currentPath != null) {
      if (!currentPath.points.isEmpty()) {
        currentPath.points.remove(currentPath.points.size() - 1);
      }
      if (currentPath.points.isEmpty()) {
        isDrawingPath = false;
        currentPath = null;
      }
    }
    return true;
  }

  return false;
}

// ----- Elevation panel click -----

boolean handleElevationPanelClick(int mx, int my) {
  if (!isInElevationPanel(mx, my)) return false;

  int panelY = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
  int sliderX = 10;
  int sliderW = 220;
  int sliderH = 14;
  int rowY = panelY + 24;

  // Sea level
  if (mx >= sliderX && mx <= sliderX + sliderW &&
      my >= rowY && my <= rowY + sliderH) {
    float t = constrain((mx - sliderX) / (float)sliderW, 0, 1);
    seaLevel = t * 1.0f - 0.5f;
    return true;
  }

  // Brush radius
  rowY += 22;
  if (mx >= sliderX && mx <= sliderX + sliderW &&
      my >= rowY && my <= rowY + sliderH) {
    float t = constrain((mx - sliderX) / (float)sliderW, 0, 1);
    elevationBrushRadius = constrain(0.01f + t * (0.2f - 0.01f), 0.01f, 0.2f);
    return true;
  }

  // Brush strength
  rowY += 22;
  if (mx >= sliderX && mx <= sliderX + sliderW &&
      my >= rowY && my <= rowY + sliderH) {
    float t = constrain((mx - sliderX) / (float)sliderW, 0, 1);
    elevationBrushStrength = constrain(0.005f + t * (0.2f - 0.005f), 0.005f, 0.2f);
    return true;
  }

  // Raise / Lower buttons
  int btnW = 70;
  int btnH = 22;
  int btnY = rowY + 22;
  int btnX1 = 10;
  int btnX2 = btnX1 + btnW + 8;

  if (mx >= btnX1 && mx <= btnX1 + btnW &&
      my >= btnY && my <= btnY + btnH) {
    elevationBrushRaise = true;
    return true;
  }
  if (mx >= btnX2 && mx <= btnX2 + btnW &&
      my >= btnY && my <= btnY + btnH) {
    elevationBrushRaise = false;
    return true;
  }

  // Noise scale slider
  int noiseY = btnY + btnH + 10;
  if (mx >= sliderX && mx <= sliderX + sliderW &&
      my >= noiseY && my <= noiseY + sliderH) {
    float t = constrain((mx - sliderX) / (float)sliderW, 0, 1);
    elevationNoiseScale = constrain(1.0f + t * (12.0f - 1.0f), 1.0f, 12.0f);
    return true;
  }

  // Generate button
  int genW = 120;
  int genH = 22;
  int genX = sliderX + sliderW + 90;
  int genY = noiseY - 4;
  if (mx >= genX && mx <= genX + genW &&
      my >= genY && my <= genY + genH) {
    mapModel.generateElevationNoise(elevationNoiseScale, 1.0f);
    return true;
  }

  return false;
}

void handlePathsMousePressed(float wx, float wy) {
  if (!isDrawingPath || currentPath == null) {
    // Start new path
    currentPath = new Path();
    isDrawingPath = true;
  }
  float maxSnapPx = 14;
  PVector snapped = findNearestSnappingPoint(wx, wy, maxSnapPx);
  if (snapped != null) {
    if (currentPath.points.size() > 0) {
      PVector last = currentPath.points.get(currentPath.points.size() - 1);
      ArrayList<PVector> route = mapModel.findSnapPath(last, snapped);
      if (route != null && route.size() > 1) {
        for (int i = 1; i < route.size(); i++) {
          PVector step = route.get(i);
          currentPath.addPoint(step.x, step.y);
        }
      } else {
        currentPath.addPoint(snapped.x, snapped.y);
      }
    } else {
      currentPath.addPoint(snapped.x, snapped.y);
    }
  } else {
    currentPath.addPoint(wx, wy);
  }
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

  // Dragging sliders in Sites panel
  if (mouseButton == LEFT && currentTool == Tool.EDIT_SITES && isInSitesPanel(mouseX, mouseY)) {
    int panelY = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;

    int sliderX = 10;
    int sliderW = 250;
    int sliderH = 16;

    // Density slider
    int densityY = panelY + 25;
    if (mouseY >= densityY && mouseY <= densityY + sliderH) {
      float t = (mouseX - sliderX) / (float)sliderW;
      siteDensity = constrain(t, 0, 1);
      return;
    }

    // Fuzz slider (0..0.3)
    int fuzzY = panelY + 25 + 22;
    if (mouseY >= fuzzY && mouseY <= fuzzY + sliderH) {
      float t = (mouseX - sliderX) / (float)sliderW;
      t = constrain(t, 0, 1);
      siteFuzz = t * 0.3f;
      return;
    }

    // Mode slider
    int modeSliderX = 10;
    int modeSliderY = panelY + 25 + 44;
    int modeSliderW = sliderW;
    int modeSliderH = 14;

    if (mouseY >= modeSliderY && mouseY <= modeSliderY + modeSliderH) {
      int modeCount = placementModes.length;
      if (modeCount < 1) modeCount = 1;
      float t = (mouseX - modeSliderX) / (float)modeSliderW;
      t = constrain(t, 0, 1);
      int idx = round(t * (modeCount - 1));
      placementModeIndex = constrain(idx, 0, placementModes.length - 1);
      return;
    }

    return;
  }

  // Elevation: sliders dragging
  if (mouseButton == LEFT && currentTool == Tool.EDIT_ELEVATION && isInElevationPanel(mouseX, mouseY)) {
    int panelY = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
    int sliderX = 10;
    int sliderW = 220;
    int sliderH = 14;
    int rowY = panelY + 24;

    if (mouseY >= rowY && mouseY <= rowY + sliderH) {
      float t = constrain((mouseX - sliderX) / (float)sliderW, 0, 1);
      seaLevel = t * 1.0f - 0.5f;
      return;
    }
    rowY += 22;
    if (mouseY >= rowY && mouseY <= rowY + sliderH) {
      float t = constrain((mouseX - sliderX) / (float)sliderW, 0, 1);
      elevationBrushRadius = constrain(0.01f + t * (0.2f - 0.01f), 0.01f, 0.2f);
      return;
    }
    rowY += 22;
    if (mouseY >= rowY && mouseY <= rowY + sliderH) {
      float t = constrain((mouseX - sliderX) / (float)sliderW, 0, 1);
      elevationBrushStrength = constrain(0.005f + t * (0.2f - 0.005f), 0.005f, 0.2f);
      return;
    }
    int btnH = 22;
    int btnY = rowY + 22;
    int noiseY = btnY + btnH + 10;
    if (mouseY >= noiseY && mouseY <= noiseY + sliderH) {
      float t = constrain((mouseX - sliderX) / (float)sliderW, 0, 1);
      elevationNoiseScale = constrain(1.0f + t * (12.0f - 1.0f), 1.0f, 12.0f);
      return;
    }
  }

  // Zones: slider dragging (only for hue + paint while dragging)
  if (mouseButton == LEFT && currentTool == Tool.EDIT_ZONES && isInZonesPanel(mouseX, mouseY)) {
    int panelY = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;

    int toolBtnW = 60;
    int toolBtnH = 20;
    int toolY  = panelY + 24;

    int swatchH = 18;
    int rowY = toolY + toolBtnH + 10;

    int n = (mapModel.biomeTypes == null) ? 0 : mapModel.biomeTypes.size();

    if (n > 0 && activeBiomeIndex >= 0 && activeBiomeIndex < n) {
      int hueSliderX = 10;
      int hueSliderW = 250;
      int hueSliderH = 14;
      int hueSliderY = rowY + swatchH + 20;

      if (mouseY >= hueSliderY && mouseY <= hueSliderY + hueSliderH) {
        float t = (mouseX - hueSliderX) / (float)hueSliderW;
        t = constrain(t, 0, 1);
        ZoneType active = mapModel.biomeTypes.get(activeBiomeIndex);
        active.hue01 = t;
        active.updateColorFromHSB();
        return;
      }
    }
  }

  // Zones: paint while dragging (only for Paint mode, outside UI)
  if (mouseButton == LEFT && currentTool == Tool.EDIT_ZONES) {
    int uiBottom = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT + ZONES_PANEL_HEIGHT;
    if (mouseY >= uiBottom) {
      PVector w = viewport.screenToWorld(mouseX, mouseY);
      if (currentZonePaintMode == ZonePaintMode.ZONE_PAINT) {
        paintBiomeAt(w.x, w.y);
      }
    }
    return;
  }

  // Ignore world if dragging in UI
  int bottom = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
  if (currentTool == Tool.EDIT_SITES) {
    bottom += SITES_PANEL_HEIGHT;
  } else if (currentTool == Tool.EDIT_ZONES) {
    bottom += ZONES_PANEL_HEIGHT;
  } else if (currentTool == Tool.EDIT_ELEVATION) {
    bottom += ELEV_PANEL_HEIGHT;
  } else if (currentTool == Tool.EDIT_PATHS) {
    bottom += PATH_PANEL_HEIGHT;
  }
  if (mouseY < bottom) return;

  if (mouseButton == LEFT && currentTool == Tool.EDIT_SITES && isDraggingSite && draggingSite != null) {
    PVector worldPos = viewport.screenToWorld(mouseX, mouseY);
    draggingSite.x = worldPos.x;
    draggingSite.y = worldPos.y;
    mapModel.markVoronoiDirty();
  } else if (mouseButton == LEFT && currentTool == Tool.EDIT_ELEVATION) {
    PVector w = viewport.screenToWorld(mouseX, mouseY);
    float dir = elevationBrushRaise ? 1 : -1;
    mapModel.applyElevationBrush(w.x, w.y, elevationBrushRadius, elevationBrushStrength * dir);
  }
}

void mouseReleased() {
  isPanning = false;
  if (mouseButton == LEFT) {
    isDraggingSite = false;
    draggingSite = null;
  }
}

void mouseWheel(MouseEvent event) {
  float count = event.getCount();
  float factor = pow(1.1f, -count);
  viewport.zoomAt(factor, mouseX, mouseY);
}

void keyPressed() {
  // Delete selected sites or last path point
  if (key == DELETE || key == BACKSPACE) {
    if (currentTool == Tool.EDIT_SITES) {
      mapModel.deleteSelectedSites();
      return;
    }
    if (currentTool == Tool.EDIT_PATHS && isDrawingPath && currentPath != null) {
      if (!currentPath.points.isEmpty()) {
        currentPath.points.remove(currentPath.points.size() - 1);
        if (currentPath.points.isEmpty()) {
          isDrawingPath = false;
          currentPath = null;
        }
      }
      return;
    }
  }

  // Finish path with Enter / Return
  if (currentTool == Tool.EDIT_PATHS &&
      (key == ENTER || key == RETURN)) {
    if (isDrawingPath && currentPath != null) {
      mapModel.addFinishedPath(currentPath);
      isDrawingPath = false;
      currentPath = null;
    }
    return;
  }

  // Clear all paths with 'c' or 'C' in Paths mode
  if (currentTool == Tool.EDIT_PATHS &&
      (key == 'c' || key == 'C')) {
    mapModel.clearAllPaths();
    isDrawingPath = false;
    currentPath = null;
    return;
  }
}
