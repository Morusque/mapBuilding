// ---------- UI DRAWING ----------

void drawTopBar() {
  // Background
  noStroke();
  fill(202);
  rect(0, 0, width, TOP_BAR_HEIGHT);

  // Bevel edges (Win95-ish)
  stroke(255);
  line(0, 0, width, 0);
  line(0, 0, 0, TOP_BAR_HEIGHT);
  stroke(96);
  line(0, TOP_BAR_HEIGHT - 1, width, TOP_BAR_HEIGHT - 1);
  line(width - 1, 0, width - 1, TOP_BAR_HEIGHT);

  // Text
  fill(10);
  textAlign(LEFT, CENTER);
  String info = "Tool: " + currentTool +
                "   Zoom: " + nf(viewport.zoom, 1, 2) +
                "   Center: (" + nf(viewport.centerX, 1, 3) + ", " +
                               nf(viewport.centerY, 1, 3) + ")";
  text(info, 10, TOP_BAR_HEIGHT / 2.0f);
}

void drawToolButtons() {
  int barY = TOP_BAR_HEIGHT;
  int barH = TOOL_BAR_HEIGHT;
  int margin = 10;
  int buttonW = 90;

  // Background for tool bar
  noStroke();
  fill(210);
  rect(0, barY, width, barH);

  // Bevel borders
  stroke(255);
  line(0, barY, width, barY);
  line(0, barY, 0, barY + barH);
  stroke(100);
  line(0, barY + barH - 1, width, barY + barH - 1);
  line(width - 1, barY, width - 1, barY + barH);

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

    boolean active = (currentTool == tools[i]);
    drawBevelButton(x, y, buttonW, barH - 4, active);

    fill(20);
    textAlign(CENTER, CENTER);
    text(labels[i], x + buttonW / 2, y + (barH - 4) / 2);
  }
}

// ----- SITES PANEL -----

void drawSitesPanel() {
  int panelY = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
  int panelH = SITES_PANEL_HEIGHT;

  // Panel background clearly distinct from map
  noStroke();
  fill(232);
  rect(0, panelY, width, panelH);

  // Panel bevel
  stroke(255);
  line(0, panelY, width, panelY);
  line(0, panelY, 0, panelY + panelH);
  stroke(120);
  line(0, panelY + panelH - 1, width, panelY + panelH - 1);
  line(width - 1, panelY, width - 1, panelY + panelH);

  fill(0);
  textAlign(LEFT, TOP);
  text("Sites generation", 10, panelY + 5);

  int sliderX = 10;
  int sliderW = 250;
  int sliderH = 16;

  // ---------- Density slider ----------
  int densityY = panelY + 25;

  stroke(160);
  fill(230);
  rect(sliderX, densityY, sliderW, sliderH, 4);

  float densityHandleX = sliderX + siteDensity * sliderW;
  float handleW = 8;

  fill(80);
  noStroke();
  rect(densityHandleX - handleW / 2, densityY - 2, handleW, sliderH + 4, 4);

  int minRes = 2;
  int maxRes = 100;
  int res = max(2, (int)map(siteDensity, 0, 1, minRes, maxRes));
  int approxCount = res * res;

  fill(0);
  textAlign(LEFT, TOP);
  text("Density: " + nf(siteDensity, 1, 2) + "  (~" + approxCount + " sites)",
       sliderX + sliderW + 10, densityY - 2);

  // ---------- Fuzz slider (0..0.3) ----------
  int fuzzY = panelY + 25 + 22;

  stroke(160);
  fill(230);
  rect(sliderX, fuzzY, sliderW, sliderH, 4);

  float fuzzNorm = (siteFuzz <= 0) ? 0 : constrain(siteFuzz / 0.3f, 0, 1);
  float fuzzHandleX = sliderX + fuzzNorm * sliderW;

  fill(80);
  noStroke();
  rect(fuzzHandleX - handleW / 2, fuzzY - 2, handleW, sliderH + 4, 4);

  fill(0);
  textAlign(LEFT, TOP);
  text("Fuzz: " + nf(siteFuzz, 1, 2) + " (0 = none, 0.3 = strong jitter)",
       sliderX + sliderW + 10, fuzzY - 2);

  // ---------- Placement mode slider (DISCRETE) ----------
  int modeSliderX = 10;
  int modeSliderY = panelY + 25 + 44;
  int modeSliderW = sliderW;
  int modeSliderH = 14;

  // Track
  stroke(160);
  fill(225);
  rect(modeSliderX, modeSliderY, modeSliderW, modeSliderH, 4);

  int modeCount = placementModes.length;
  if (modeCount < 1) modeCount = 1;

  float stepW = (modeCount > 1) ?
    (modeSliderW / (float)(modeCount - 1)) :
    0;

  // Tick marks
  stroke(120);
  for (int i = 0; i < modeCount; i++) {
    float tx = modeSliderX + i * stepW;
    float ty0 = modeSliderY;
    float ty1 = modeSliderY + modeSliderH;
    line(tx, ty0, tx, ty1);
  }

  // Handle (circle)
  float modeHandleX;
  if (placementModeIndex <= 0) {
    modeHandleX = modeSliderX;
  } else if (placementModeIndex >= modeCount - 1) {
    modeHandleX = modeSliderX + modeSliderW;
  } else {
    modeHandleX = modeSliderX + placementModeIndex * stepW;
  }

  float knobRadius = modeSliderH * 0.9f;
  float knobY = modeSliderY + modeSliderH / 2.0f;

  fill(40);
  noStroke();
  ellipse(modeHandleX, knobY, knobRadius, knobRadius);

  // Mode name label
  String modeName = placementModeLabel(currentPlacementMode());
  fill(0);
  textAlign(LEFT, TOP);
  text("Placement: " + modeName, modeSliderX + modeSliderW + 10, modeSliderY - 2);

  // ---------- Generate button ----------
  int genW = 100;
  int genH = 24;
  int genX = 10;
  int genY = modeSliderY + 24;

  drawBevelButton(genX, genY, genW, genH, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Generate", genX + genW / 2, genY + genH / 2);
}

// ----- ZONES PANEL -----

void drawZonesPanel() {
  int panelY = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
  int panelH = ZONES_PANEL_HEIGHT;

  // Panel background distinct from map
  noStroke();
  fill(232);
  rect(0, panelY, width, panelH);

  // Panel bevel
  stroke(255);
  line(0, panelY, width, panelY);
  line(0, panelY, 0, panelY + panelH);
  stroke(120);
  line(0, panelY + panelH - 1, width, panelY + panelH - 1);
  line(width - 1, panelY, width - 1, panelY + panelH);

  fill(0);
  textAlign(LEFT, TOP);
  text("Biomes (Zones)", 10, panelY + 5);

  // Paint / Fill buttons
  int toolBtnW = 60;
  int toolBtnH = 20;
  int toolX1 = 10;
  int toolX2 = toolX1 + toolBtnW + 8;
  int toolY  = panelY + 24;

  // Paint button
  drawBevelButton(toolX1, toolY, toolBtnW, toolBtnH,
                  currentZonePaintMode == ZonePaintMode.ZONE_PAINT);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Paint", toolX1 + toolBtnW * 0.5f, toolY + toolBtnH * 0.5f);

  // Fill button
  drawBevelButton(toolX2, toolY, toolBtnW, toolBtnH,
                  currentZonePaintMode == ZonePaintMode.ZONE_FILL);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Fill", toolX2 + toolBtnW * 0.5f, toolY + toolBtnH * 0.5f);

  // Add / Remove biome type buttons
  int addBtnW = 24;
  int addBtnH = 20;
  int addX = toolX2 + toolBtnW + 20;
  int addY = toolY;

  int remX = addX + addBtnW + 6;
  int remY = toolY;

  // "+" button
  drawBevelButton(addX, addY, addBtnW, addBtnH, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("+", addX + addBtnW * 0.5f, addY + addBtnH * 0.5f);

  // "-" button (disabled if index 0 or only one type)
  boolean canRemove = (mapModel.biomeTypes != null &&
                       mapModel.biomeTypes.size() > 1 &&
                       activeBiomeIndex > 0);

  drawBevelButton(remX, remY, addBtnW, addBtnH, !canRemove);
  fill(10);
  textAlign(CENTER, CENTER);
  text("-", remX + addBtnW * 0.5f, remY + addBtnH * 0.5f);

  // Palette
  if (mapModel == null || mapModel.biomeTypes == null) return;
  int n = mapModel.biomeTypes.size();
  if (n == 0) return;

  int swatchW = 60;
  int swatchH = 18;
  int marginX = 10;
  int gapX = 8;

  int rowY = toolY + toolBtnH + 10;
  int textY = rowY + swatchH + 2;

  textAlign(CENTER, TOP);

  for (int i = 0; i < n; i++) {
    ZoneType zt = mapModel.biomeTypes.get(i);
    int x = marginX + i * (swatchW + gapX);
    int y = rowY;

    stroke(120);
    if (i == activeBiomeIndex) {
      strokeWeight(2);
    } else {
      strokeWeight(1);
    }
    fill(zt.col);
    rect(x, y, swatchW, swatchH, 4);

    fill(0);
    text(zt.name, x + swatchW * 0.5f, textY);
  }

  // Hue slider for currently selected biome
  if (activeBiomeIndex >= 0 && activeBiomeIndex < n) {
    ZoneType active = mapModel.biomeTypes.get(activeBiomeIndex);

    int hueSliderX = 10;
    int hueSliderW = 250;
    int hueSliderH = 14;
    int hueSliderY = rowY + swatchH + 20;

    // Track
    stroke(160);
    fill(230);
    rect(hueSliderX, hueSliderY, hueSliderW, hueSliderH, 4);

    // Handle position from active.hue01
    float hNorm = constrain(active.hue01, 0, 1);
    float handleX = hueSliderX + hNorm * hueSliderW;
    float handleR = hueSliderH * 0.9f;
    float handleY = hueSliderY + hueSliderH / 2.0f;

    fill(40);
    noStroke();
    ellipse(handleX, handleY, handleR, handleR);

    // Label
    fill(0);
    textAlign(LEFT, TOP);
    text("Hue for \"" + active.name + "\": " + nf(active.hue01, 1, 2),
         hueSliderX + hueSliderW + 10, hueSliderY - 2);
  }
}

// ----- PATHS PANEL -----

void drawPathsPanel() {
  int panelY = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
  int panelH = PATH_PANEL_HEIGHT;

  noStroke();
  fill(232);
  rect(0, panelY, width, panelH);

  stroke(255);
  line(0, panelY, width, panelY);
  line(0, panelY, 0, panelY + panelH);
  stroke(120);
  line(0, panelY + panelH - 1, width, panelY + panelH - 1);
  line(width - 1, panelY, width - 1, panelY + panelH);

  fill(0);
  textAlign(LEFT, TOP);
  text("Paths", 10, panelY + 4);

  int btnW = 120;
  int btnH = 22;
  int btnY = panelY + 12;
  int btnX1 = 120;
  int btnX2 = btnX1 + btnW + 10;

  drawBevelButton(btnX1, btnY, btnW, btnH, false);
  drawBevelButton(btnX2, btnY, btnW, btnH, false);

  fill(10);
  textAlign(CENTER, CENTER);
  text("Close (Enter)", btnX1 + btnW / 2, btnY + btnH / 2);
  text("Undo (Del)",    btnX2 + btnW / 2, btnY + btnH / 2);
}

// ----- ELEVATION PANEL -----

void drawElevationPanel() {
  int panelY = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
  int panelH = ELEV_PANEL_HEIGHT;

  noStroke();
  fill(232);
  rect(0, panelY, width, panelH);

  stroke(255);
  line(0, panelY, width, panelY);
  line(0, panelY, 0, panelY + panelH);
  stroke(120);
  line(0, panelY + panelH - 1, width, panelY + panelH - 1);
  line(width - 1, panelY, width - 1, panelY + panelH);

  fill(0);
  textAlign(LEFT, TOP);
  text("Elevation", 10, panelY + 6);

  int sliderX = 10;
  int sliderW = 220;
  int sliderH = 14;
  int rowY = panelY + 24;

  // Sea level slider (-0.5 .. 0.5)
  stroke(160);
  fill(230);
  rect(sliderX, rowY, sliderW, sliderH, 4);
  float seaNorm = constrain((seaLevel + 0.5f) / 1.0f, 0, 1);
  float sx = sliderX + seaNorm * sliderW;
  fill(40);
  noStroke();
  ellipse(sx, rowY + sliderH / 2.0f, sliderH * 0.9f, sliderH * 0.9f);
  fill(0);
  textAlign(LEFT, TOP);
  text("Water level: " + nf(seaLevel, 1, 2), sliderX + sliderW + 10, rowY - 2);

  // Brush radius slider (0.01..0.2)
  rowY += 22;
  stroke(160);
  fill(230);
  rect(sliderX, rowY, sliderW, sliderH, 4);
  float rNorm = constrain(map(elevationBrushRadius, 0.01f, 0.2f, 0, 1), 0, 1);
  float rx = sliderX + rNorm * sliderW;
  fill(40);
  noStroke();
  ellipse(rx, rowY + sliderH / 2.0f, sliderH * 0.9f, sliderH * 0.9f);
  fill(0);
  text("Brush radius", sliderX + sliderW + 10, rowY - 2);

  // Brush strength slider (0.005..0.2)
  rowY += 22;
  stroke(160);
  fill(230);
  rect(sliderX, rowY, sliderW, sliderH, 4);
  float sNorm = constrain(map(elevationBrushStrength, 0.005f, 0.2f, 0, 1), 0, 1);
  float stx = sliderX + sNorm * sliderW;
  fill(40);
  noStroke();
  ellipse(stx, rowY + sliderH / 2.0f, sliderH * 0.9f, sliderH * 0.9f);
  fill(0);
  text("Brush strength", sliderX + sliderW + 10, rowY - 2);

  // Raise / Lower buttons
  int btnW = 70;
  int btnH = 22;
  int btnY = rowY + 22;
  int btnX1 = 10;
  int btnX2 = btnX1 + btnW + 8;

  drawBevelButton(btnX1, btnY, btnW, btnH, elevationBrushRaise);
  drawBevelButton(btnX2, btnY, btnW, btnH, !elevationBrushRaise);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Raise", btnX1 + btnW / 2, btnY + btnH / 2);
  text("Lower", btnX2 + btnW / 2, btnY + btnH / 2);

  // Noise scale slider
  int noiseY = btnY + btnH + 10;
  stroke(160);
  fill(230);
  rect(sliderX, noiseY, sliderW, sliderH, 4);
  float nNorm = constrain(map(elevationNoiseScale, 1.0f, 12.0f, 0, 1), 0, 1);
  float nx = sliderX + nNorm * sliderW;
  fill(40);
  noStroke();
  ellipse(nx, noiseY + sliderH / 2.0f, sliderH * 0.9f, sliderH * 0.9f);
  fill(0);
  text("Noise scale", sliderX + sliderW + 10, noiseY - 2);

  // Generate button
  int genW = 120;
  int genH = 22;
  int genX = sliderX + sliderW + 90;
  int genY = noiseY - 4;
  drawBevelButton(genX, genY, genW, genH, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Perlin Generate", genX + genW / 2, genY + genH / 2);
}

// ---------- UI helpers ----------

String placementModeLabel(PlacementMode m) {
  switch (m) {
    case GRID:    return "Grid";
    case POISSON: return "Poisson-disc";
    case HEX:     return "Hexagonal";
  }
  return "Unknown";
}

PlacementMode currentPlacementMode() {
  int idx = constrain(placementModeIndex, 0, placementModes.length - 1);
  return placementModes[idx];
}

void drawBevelButton(int x, int y, int w, int h, boolean pressed) {
  int face = pressed ? color(192) : color(224);
  int hl = color(255);
  int sh = color(96);

  noStroke();
  fill(face);
  rect(x, y, w, h);

  if (!pressed) {
    stroke(hl);
    line(x, y, x + w - 1, y);
    line(x, y, x, y + h - 1);
    stroke(sh);
    line(x, y + h - 1, x + w - 1, y + h - 1);
    line(x + w - 1, y, x + w - 1, y + h - 1);
  } else {
    stroke(sh);
    line(x, y, x + w - 1, y);
    line(x, y, x, y + h - 1);
    stroke(hl);
    line(x, y + h - 1, x + w - 1, y + h - 1);
    line(x + w - 1, y, x + w - 1, y + h - 1);
  }
}
