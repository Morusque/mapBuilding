// ---------- UI DRAWING ----------

int panelTop() {
  return TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
}

void drawPanelBackground(IntRect frame) {
  noStroke();
  fill(232);
  rect(frame.x, frame.y, frame.w, frame.h);

  // Bevel
  stroke(255);
  line(frame.x, frame.y, frame.x + frame.w, frame.y);
  line(frame.x, frame.y, frame.x, frame.y + frame.h);
  stroke(120);
  line(frame.x, frame.y + frame.h - 1, frame.x + frame.w, frame.y + frame.h - 1);
  line(frame.x + frame.w - 1, frame.y, frame.x + frame.w - 1, frame.y + frame.h);
}

// Shared small rect helper
class IntRect {
  int x, y, w, h;
  IntRect() {}
  IntRect(int x, int y, int w, int h) { this.x = x; this.y = y; this.w = w; this.h = h; }
  boolean contains(int px, int py) { return px >= x && px <= x + w && py >= y && py <= y + h; }
}

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
  String info1 = "Tool: " + currentTool +
                 "   Zoom: " + nf(viewport.zoom, 1, 2) +
                 "   Center: (" + nf(viewport.centerX, 1, 3) + ", " +
                                nf(viewport.centerY, 1, 3) + ")";

  int siteCount = (mapModel != null && mapModel.sites != null) ? mapModel.sites.size() : 0;
  int cellCount = (mapModel != null && mapModel.cells != null) ? mapModel.cells.size() : 0;
  int pathCount = (mapModel != null && mapModel.paths != null) ? mapModel.paths.size() : 0;
  int pathSegs = 0;
  if (mapModel != null && mapModel.paths != null) {
    for (Path p : mapModel.paths) {
      if (p != null) pathSegs += p.segmentCount();
    }
  }
  String info2 = "FPS: " + nf(frameRate, 1, 1) +
                 "   Sites: " + siteCount +
                 "   Cells: " + cellCount +
                 "   Paths: " + pathCount + " (" + pathSegs + " segs)";
  if (mapModel != null) {
    info2 += "   Snap: " + mapModel.lastSnapNodeCount + "n/" + mapModel.lastSnapEdgeCount +
             "e (" + nf(mapModel.lastSnapBuildMs, 1, 1) + "ms)";
    info2 += "   Pathfind: " + nf(mapModel.lastPathfindMs, 1, 1) + "ms " +
             "[" + mapModel.lastPathfindExpanded + " expanded, len " + mapModel.lastPathfindLength +
             (mapModel.lastPathfindHit ? "" : ", miss") + "]";
  }
  text(info1, 10, TOP_BAR_HEIGHT / 2.0f - 6);
  text(info2, 10, TOP_BAR_HEIGHT / 2.0f + 8);

  // Notice (right side, above loading bar)
  if (uiNoticeFrames > 0 && uiNotice != null && uiNotice.length() > 0) {
    fill(180, 50, 50);
    textAlign(RIGHT, CENTER);
    text(uiNotice, width - 150, TOP_BAR_HEIGHT / 2.0f - 6);
    uiNoticeFrames--;
  }

  // Loading bar (top-right, small)
  boolean showLoad = isLoading || loadingHoldFrames > 0;
  if (showLoad) {
    if (isLoading) loadingPhase += 0.02f;
    else loadingHoldFrames = max(0, loadingHoldFrames - 1);
    float barW = 120;
    float barH = 10;
    float x = width - barW - 12;
    float y = (TOP_BAR_HEIGHT - barH) / 2.0f;
    stroke(80);
    fill(235);
    rect(x, y, barW, barH, 3);
    noStroke();
    float pct = constrain(loadingPct, 0, 1);
    // Keep a tiny animated pulse to show activity even if progress stalls briefly.
    if (isLoading) {
      pct = max(pct, (sin(loadingPhase) * 0.05f + 0.05f));
    }
    float w = barW * pct;
    fill(60, 140, 220);
    rect(x + 1, y + 1, w - 2, barH - 2, 2);
  }
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

    boolean active = (currentTool == tools[i]);
    drawBevelButton(x, y, buttonW, barH - 4, active);

    fill(20);
    textAlign(CENTER, CENTER);
    text(labels[i], x + buttonW / 2, y + (barH - 4) / 2);
  }
}

