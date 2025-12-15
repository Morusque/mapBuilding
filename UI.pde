// ---------- UI DRAWING ----------

int panelTop() {
  // Base panel top (top bar + tool bar).
  return snapPanelTop();
}

int snapPanelTop() {
  return TOP_BAR_TOTAL + TOOL_BAR_HEIGHT;
}

int snapSettingsPanelHeight() {
  // Title + section gap
  int h = PANEL_PADDING + PANEL_TITLE_H + PANEL_SECTION_GAP;
  // Seven checkbox rows
  int rows = 7;
  h += rows * (PANEL_CHECK_SIZE + PANEL_ROW_GAP);
  // Elevation divisions slider label + slider + padding
  h += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_PADDING;
  // Bottom padding
  h += PANEL_PADDING;
  return h;
}

void drawPanelBackground(IntRect frame) {
  rectMode(CORNER);
  ellipseMode(CENTER);
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

IntRect pressedButtonRect = null;
Runnable pendingButtonAction = null;

boolean rectEquals(IntRect a, IntRect b) {
  return a != null && b != null && a.x == b.x && a.y == b.y && a.w == b.w && a.h == b.h;
}

boolean queueButtonAction(IntRect rect, Runnable action) {
  if (rect == null || action == null) return false;
  if (!rect.contains(mouseX, mouseY)) return false;
  pressedButtonRect = new IntRect(rect.x, rect.y, rect.w, rect.h);
  pendingButtonAction = action;
  return true;
}

boolean isButtonHeld(IntRect rect) {
  if (rect == null || pressedButtonRect == null) return false;
  if (!rectEquals(rect, pressedButtonRect)) return false;
  return pressedButtonRect.contains(mouseX, mouseY);
}

void runPendingButtonAction(int mx, int my) {
  if (pendingButtonAction != null && pressedButtonRect != null && pressedButtonRect.contains(mx, my)) {
    pendingButtonAction.run();
  }
  pressedButtonRect = null;
  pendingButtonAction = null;
}

float clampScroll(float scroll, float contentH, float viewH) {
  float maxScroll = max(0, contentH - viewH);
  return constrain(scroll, 0, maxScroll);
}

void drawScrollbar(IntRect track, float contentH, float scroll) {
  if (track == null || track.h <= 0) return;
  boolean active = contentH > track.h;

  // Track
  noStroke();
  fill(active ? 214 : 200);
  rect(track.x, track.y, track.w, track.h);
  stroke(255);
  line(track.x, track.y, track.x + track.w, track.y);
  line(track.x, track.y, track.x, track.y + track.h);
  stroke(96);
  line(track.x, track.y + track.h - 1, track.x + track.w, track.y + track.h - 1);
  line(track.x + track.w - 1, track.y, track.x + track.w - 1, track.y + track.h);

  if (!active) return;

  int inset = 2;
  int thumbH = max(SCROLLBAR_THUMB_MIN, round(track.h * track.h / contentH));
  thumbH = min(thumbH, track.h - inset * 2);
  float travel = track.h - inset * 2 - thumbH;
  float maxScroll = max(1e-3f, contentH - track.h);
  int thumbY = track.y + inset + round((scroll / maxScroll) * travel);
  IntRect thumb = new IntRect(track.x + inset, thumbY, track.w - inset * 2, thumbH);

  // Thumb with Win95-ish bevel
  noStroke();
  fill(205);
  rect(thumb.x, thumb.y, thumb.w, thumb.h);
  stroke(255);
  line(thumb.x, thumb.y, thumb.x + thumb.w, thumb.y);
  line(thumb.x, thumb.y, thumb.x, thumb.y + thumb.h);
  stroke(96);
  line(thumb.x, thumb.y + thumb.h - 1, thumb.x + thumb.w, thumb.y + thumb.h - 1);
  line(thumb.x + thumb.w - 1, thumb.y, thumb.x + thumb.w - 1, thumb.y + thumb.h);
}

void drawTopBar() {
  int topBarH = TOP_BAR_TOTAL;
  // Background
  noStroke();
  fill(202);
  rect(0, 0, width, topBarH);

  // Bevel edges (Win95-ish)
  stroke(255);
  line(0, 0, width, 0);
  line(0, 0, 0, topBarH);
  stroke(96);
  line(0, topBarH - 1, width, topBarH - 1);
  line(width - 1, 0, width - 1, topBarH);

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
  text(info1, 10, topBarH / 2.0f - 7);
  text(info2, 10, topBarH / 2.0f + 7);

  // Notice (right side, above loading bar)
  if (uiNoticeFrames > 0 && uiNotice != null && uiNotice.length() > 0) {
    fill(180, 50, 50);
    textAlign(RIGHT, CENTER);
    text(uiNotice, width - 150, topBarH / 2.0f - 6);
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
    float y = (topBarH - barH) / 2.0f;
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
  int barY = TOP_BAR_TOTAL;
  int barH = TOOL_BAR_HEIGHT;
  int margin = 10;
  int buttonW = 90;

  // Background for tool bar
  noStroke();
  fill(245);
  rect(0, barY, width, barH);

  // Bevel borders (no bottom line to blend with content)
  stroke(255);
  line(0, barY, width, barY);
  line(0, barY, 0, barY + barH);
  stroke(100);
  line(width - 1, barY, width - 1, barY + barH);

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
    int x = margin + i * (buttonW + 5);
    int y = barY + 2;
    IntRect rect = new IntRect(x, y, buttonW, barH - 4);

    boolean active = (currentTool == tools[i]);
    drawTabButton(rect, active);

    fill(20);
    textAlign(CENTER, CENTER);
    text(labels[i], x + buttonW / 2, y + (barH - 4) / 2);

    String key = "tool_" + labels[i].toLowerCase();
    registerUiTooltip(rect, tooltipFor(key));
  }
}
