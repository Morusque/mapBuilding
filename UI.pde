// ---------- UI DRAWING ----------

void drawTopBar() {
  noStroke();
  fill(230);
  rect(0, 0, width, TOP_BAR_HEIGHT);

  fill(0);
  textAlign(LEFT, CENTER);
  String toolName = currentTool.toString();
  String info = "Tool: " + toolName +
                "   Zoom: " + nf(viewport.zoom, 1, 2) +
                "   Center: (" + nf(viewport.centerX, 1, 3) + ", " +
                               nf(viewport.centerY, 1, 3) + ")";
  text(info, 10, TOP_BAR_HEIGHT / 2.0);
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

void drawSitesPanel() {
  int panelY = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
  int panelH = SITES_PANEL_HEIGHT;

  // Background
  noStroke();
  fill(245);
  rect(0, panelY, width, panelH);

  fill(0);
  textAlign(LEFT, TOP);
  text("Sites generation", 10, panelY + 5);

  // --- Density slider (first line) ---
  int sliderX = 10;
  int sliderY = panelY + 25;
  int sliderW = 250;
  int sliderH = 16;

  // Track
  stroke(160);
  fill(230);
  rect(sliderX, sliderY, sliderW, sliderH, 4);

  // Handle
  float handleX = sliderX + siteDensity * sliderW;
  float handleW = 8;

  fill(80);
  noStroke();
  rect(handleX - handleW / 2, sliderY - 2, handleW, sliderH + 4, 4);

  // Density text + approximate count (grid-based estimate)
  int minRes = 2;
  int maxRes = 40;
  int res = (int)map(siteDensity, 0, 1, minRes, maxRes);
  res = max(2, res);
  int approxCount = res * res;

  fill(0);
  textAlign(LEFT, TOP);
  text("Density: " + nf(siteDensity, 1, 2) + "  (~" + approxCount + " sites)",
       sliderX + sliderW + 10, sliderY - 2);

  // --- Placement mode slider (second line) ---
  int modeSliderX = 10;
  int modeSliderY = panelY + 25 + 25;
  int modeSliderW = 250;
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

  // --- Generate button (third line) ---
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
  return placementModes[constrain(placementModeIndex, 0, placementModes.length - 1)];
}
