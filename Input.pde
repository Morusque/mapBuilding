// ---------- Input helpers ----------

boolean isInSitesPanel(int mx, int my) {
  if (currentTool != Tool.EDIT_SITES) return false;
  int y0 = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
  int y1 = y0 + SITES_PANEL_HEIGHT;
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

  String[] labels = { "Sites", "Zones", "Paths", "Struct", "Labels" };
  Tool[] tools = {
    Tool.EDIT_SITES,
    Tool.EDIT_ZONES,
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

boolean handleSitesPanelClick(int mx, int my) {
  if (!isInSitesPanel(mx, my)) return false;

  int panelY = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;

  // Density slider bounds
  int sliderX = 10;
  int sliderY = panelY + 25;
  int sliderW = 250;
  int sliderH = 16;

  // Density slider
  if (mx >= sliderX && mx <= sliderX + sliderW &&
      my >= sliderY && my <= sliderY + sliderH) {
    float t = (mx - sliderX) / (float)sliderW;
    siteDensity = constrain(t, 0, 1);
    return true;
  }

  // Mode slider bounds
  int modeSliderX = 10;
  int modeSliderY = panelY + 25 + 25;
  int modeSliderW = 250;
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

  // Ignore world interaction if inside any top UI area
  int uiBottom = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
  if (currentTool == Tool.EDIT_SITES) {
    uiBottom += SITES_PANEL_HEIGHT;
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
    }
  }
}

void handleSitesMousePressed(float wx, float wy) {
  float maxDistWorld = 10.0 / viewport.zoom; // ~10 px tolerance
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

    // Density slider
    int sliderX = 10;
    int sliderY = panelY + 25;
    int sliderW = 250;
    int sliderH = 16;

    if (mouseY >= sliderY && mouseY <= sliderY + sliderH) {
      float t = (mouseX - sliderX) / (float)sliderW;
      siteDensity = constrain(t, 0, 1);
      return;
    }

    // Mode slider
    int modeSliderX = 10;
    int modeSliderY = panelY + 25 + 25;
    int modeSliderW = 250;
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

  // Ignore world if dragging in UI
  int uiBottom = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
  if (currentTool == Tool.EDIT_SITES) {
    uiBottom += SITES_PANEL_HEIGHT;
  }
  if (mouseY < uiBottom) return;

  if (mouseButton == LEFT && currentTool == Tool.EDIT_SITES && isDraggingSite && draggingSite != null) {
    PVector worldPos = viewport.screenToWorld(mouseX, mouseY);
    draggingSite.x = worldPos.x;
    draggingSite.y = worldPos.y;
    mapModel.markVoronoiDirty();
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
  float factor = pow(1.1, -count);
  viewport.zoomAt(factor, mouseX, mouseY);
}

void keyPressed() {
  if (key == DELETE || key == BACKSPACE) {
    mapModel.deleteSelectedSites();
  }
}
