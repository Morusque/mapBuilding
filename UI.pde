// ---------- UI DRAWING ----------

void drawTopBar() {
  noStroke();
  fill(230);
  rect(0, 0, width, TOP_BAR_HEIGHT);

  fill(0);
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

  String[] labels = { "Sites", "Zones", "Paths", "Struct", "Labels" };
  Tool[] tools = {
    Tool.EDIT_SITES,
    Tool.EDIT_ZONES,
    Tool.EDIT_PATHS,
    Tool.EDIT_STRUCTURES,
    Tool.EDIT_LABELS
  };

  noStroke();
  fill(240);
  rect(0, barY, width, barH);

  for (int i = 0; i < labels.length; i++) {
    int x = margin + i * (buttonW + 5);
    int y = barY + 2;

    boolean active = (currentTool == tools[i]);
    stroke(150);
    if (active) {
      fill(200, 220, 255);
    } else {
      fill(220);
    }
    rect(x, y, buttonW, barH - 4, 4);

    fill(0);
    textAlign(CENTER, CENTER);
    text(labels[i], x + buttonW / 2, y + (barH - 4) / 2);
  }
}

// ----- SITES PANEL -----

void drawSitesPanel() {
  int panelY = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
  int panelH = SITES_PANEL_HEIGHT;

  noStroke();
  fill(245);
  rect(0, panelY, width, panelH);

  fill(0);
  textAlign(LEFT, TOP);
  text("Sites generation", 10, panelY + 5);

  int sliderX = 10;
  int sliderW = 250;
  int sliderH = 16;

  // Density slider
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
  int maxRes = 40;
  int res = max(2, (int)map(siteDensity, 0, 1, minRes, maxRes));
  int approxCount = res * res;

  fill(0);
  textAlign(LEFT, TOP);
  text("Density: " + nf(siteDensity, 1, 2) + "  (~" + approxCount + " sites)",
       sliderX + sliderW + 10, densityY - 2);

  // Fuzz slider
  int fuzzY = panelY + 25 + 22;

  stroke(160);
  fill(230);
  rect(sliderX, fuzzY, sliderW, sliderH, 4);

  float fuzzHandleX = sliderX + siteFuzz * sliderW;

  fill(80);
  noStroke();
  rect(fuzzHandleX - handleW / 2, fuzzY - 2, handleW, sliderH + 4, 4);

  fill(0);
  textAlign(LEFT, TOP);
  text("Fuzz: " + nf(siteFuzz, 1, 2) + " (0 = none, 1 = strong jitter)",
       sliderX + sliderW + 10, fuzzY - 2);

  // Placement mode slider
  int modeSliderX = 10;
  int modeSliderY = panelY + 25 + 44;
  int modeSliderW = sliderW;
  int modeSliderH = 14;

  stroke(160);
  fill(230);
  rect(modeSliderX, modeSliderY, modeSliderW, modeSliderH, 4);

  int modeCount = placementModes.length;
  if (modeCount < 1) modeCount = 1;

  float stepW = (modeCount > 1) ?
    (modeSliderW / (float)(modeCount - 1)) :
    0;

  float modeHandleX;
  if (placementModeIndex <= 0) {
    modeHandleX = modeSliderX;
  } else if (placementModeIndex >= modeCount - 1) {
    modeHandleX = modeSliderX + modeSliderW;
  } else {
    modeHandleX = modeSliderX + placementModeIndex * stepW;
  }

  float modeHandleW = 10;
  fill(80);
  noStroke();
  rect(modeHandleX - modeHandleW / 2, modeSliderY - 2,
       modeHandleW, modeSliderH + 4, 4);

  String modeName = placementModeLabel(currentPlacementMode());
  fill(0);
  textAlign(LEFT, TOP);
  text("Placement: " + modeName, modeSliderX + modeSliderW + 10, modeSliderY - 2);

  // Generate button
  int genW = 100;
  int genH = 24;
  int genX = 10;
  int genY = modeSliderY + 24;

  stroke(150);
  fill(220);
  rect(genX, genY, genW, genH, 4);
  fill(0);
  textAlign(CENTER, CENTER);
  text("Generate", genX + genW / 2, genY + genH / 2);
}

// ----- ZONES PANEL -----

void drawZonesPanel() {
  int panelY = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
  int panelH = ZONES_PANEL_HEIGHT;

  noStroke();
  fill(245);
  rect(0, panelY, width, panelH);

  fill(0);
  textAlign(LEFT, TOP);
  text("Biomes (Zones)", 10, panelY + 5);

  if (mapModel == null || mapModel.biomeTypes == null) return;
  int n = mapModel.biomeTypes.size();
  if (n == 0) return;

  int swatchW = 60;
  int swatchH = 18;
  int marginX = 10;
  int gapX = 8;

  int rowY = panelY + 28;
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
