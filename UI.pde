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
  String info = "Tool: " + currentTool +
                "   Zoom: " + nf(viewport.zoom, 1, 2) +
                "   Center: (" + nf(viewport.centerX, 1, 3) + ", " +
                               nf(viewport.centerY, 1, 3) + ")";
  text(info, 10, TOP_BAR_HEIGHT / 2.0f);

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
    float pct = (sin(loadingPhase) * 0.5f + 0.5f); // 0..1 animated
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

// ----- SITES PANEL -----

class SitesLayout {
  IntRect panel;
  int titleY;
  IntRect densitySlider;
  IntRect fuzzSlider;
  IntRect modeSlider;
  IntRect generateBtn;
  IntRect keepCheckbox;
}

SitesLayout buildSitesLayout() {
  SitesLayout l = new SitesLayout();
  l.panel = new IntRect(PANEL_X, panelTop(), PANEL_W, 0);
  int innerX = l.panel.x + PANEL_PADDING;
  int curY = l.panel.y + PANEL_PADDING;
  l.titleY = curY;
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;

  int sliderW = 200;
  l.densitySlider = new IntRect(innerX, curY + PANEL_LABEL_H, sliderW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

  l.fuzzSlider = new IntRect(innerX, curY + PANEL_LABEL_H, sliderW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

  l.modeSlider = new IntRect(innerX, curY + PANEL_LABEL_H, sliderW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;

  l.generateBtn = new IntRect(innerX, curY, 110, PANEL_BUTTON_H);
  l.keepCheckbox = new IntRect(l.generateBtn.x + l.generateBtn.w + 12,
                               curY + (PANEL_BUTTON_H - PANEL_CHECK_SIZE) / 2,
                               PANEL_CHECK_SIZE, PANEL_CHECK_SIZE);
  curY += PANEL_BUTTON_H + PANEL_PADDING;
  l.panel.h = curY - l.panel.y;
  return l;
}

void drawSitesPanel() {
  SitesLayout layout = buildSitesLayout();
  drawPanelBackground(layout.panel);

  int labelX = layout.panel.x + PANEL_PADDING;
  fill(0);
  textAlign(LEFT, TOP);
  text("Sites generation", labelX, layout.titleY);

  // ---------- Density slider ----------
  IntRect d = layout.densitySlider;
  stroke(160);
  fill(230);
  rect(d.x, d.y, d.w, d.h, 4);

  float density01 = constrain(siteTargetCount / (float)MAX_SITE_COUNT, 0, 1);
  float densityHandleX = d.x + density01 * d.w;
  float handleW = 8;

  fill(80);
  noStroke();
  rect(densityHandleX - handleW / 2, d.y - 2, handleW, d.h + 4, 4);

  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Density: " + siteTargetCount + " sites", d.x, d.y - 4);

  // ---------- Fuzz slider (0..0.3) ----------
  IntRect f = layout.fuzzSlider;

  stroke(160);
  fill(230);
  rect(f.x, f.y, f.w, f.h, 4);

  float fuzzNorm = (siteFuzz <= 0) ? 0 : constrain(siteFuzz / 0.3f, 0, 1);
  float fuzzHandleX = f.x + fuzzNorm * f.w;

  fill(80);
  noStroke();
  rect(fuzzHandleX - handleW / 2, f.y - 2, handleW, f.h + 4, 4);

  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Fuzz: " + nf(siteFuzz, 1, 2) + " (0 = none, 0.3 = strong jitter)",
       f.x, f.y - 4);

  // ---------- Placement mode slider (DISCRETE) ----------
  IntRect m = layout.modeSlider;

  // Track
  stroke(160);
  fill(225);
  rect(m.x, m.y, m.w, m.h, 4);

  int modeCount = placementModes.length;
  if (modeCount < 1) modeCount = 1;

  float stepW = (modeCount > 1) ?
    (m.w / (float)(modeCount - 1)) :
    0;

  // Tick marks
  stroke(120);
  for (int i = 0; i < modeCount; i++) {
    float tx = m.x + i * stepW;
    float ty0 = m.y;
    float ty1 = m.y + m.h;
    line(tx, ty0, tx, ty1);
  }

  // Handle (circle)
  float modeHandleX;
  if (placementModeIndex <= 0) {
    modeHandleX = m.x;
  } else if (placementModeIndex >= modeCount - 1) {
    modeHandleX = m.x + m.w;
  } else {
    modeHandleX = m.x + placementModeIndex * stepW;
  }

  float knobRadius = m.h * 0.9f;
  float knobY = m.y + m.h / 2.0f;

  fill(40);
  noStroke();
  ellipse(modeHandleX, knobY, knobRadius, knobRadius);

  // Mode name label
  String modeName = placementModeLabel(currentPlacementMode());
  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Placement: " + modeName, m.x, m.y - 4);

  // ---------- Generate button ----------
  IntRect g = layout.generateBtn;
  drawBevelButton(g.x, g.y, g.w, g.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Generate", g.x + g.w / 2, g.y + g.h / 2);

  // Keep properties toggle
  IntRect c = layout.keepCheckbox;
  stroke(80);
  fill(keepPropertiesOnGenerate ? 200 : 240);
  rect(c.x, c.y, c.w, c.h);
  if (keepPropertiesOnGenerate) {
    line(c.x + 3, c.y + c.h / 2, c.x + c.w / 2, c.y + c.h - 3);
    line(c.x + c.w / 2, c.y + c.h - 3, c.x + c.w - 3, c.y + 3);
  }
  fill(0);
  textAlign(LEFT, CENTER);
  text("Keep properties", c.x + c.w + 6, g.y + g.h / 2);
}

// ----- Biomes PANEL -----

class BiomesLayout {
  IntRect panel;
  int titleY;
  IntRect paintBtn;
  IntRect fillBtn;
  IntRect generateBtn;
  IntRect resetBtn;
  IntRect addBtn;
  IntRect removeBtn;
  ArrayList<IntRect> swatches = new ArrayList<IntRect>();
  ArrayList<IntRect> nameRects = new ArrayList<IntRect>();
  IntRect hueSlider;
  IntRect brushSlider;
}

BiomesLayout buildBiomesLayout() {
  BiomesLayout l = new BiomesLayout();
  l.panel = new IntRect(PANEL_X, panelTop(), PANEL_W, 0);
  int innerX = l.panel.x + PANEL_PADDING;
  int curY = l.panel.y + PANEL_PADDING;
  l.titleY = curY;
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;

  l.resetBtn = new IntRect(innerX, curY, 90, PANEL_BUTTON_H);
  l.generateBtn = new IntRect(l.resetBtn.x + l.resetBtn.w + 8, curY, 90, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_ROW_GAP;

  l.paintBtn = new IntRect(innerX, curY, 70, PANEL_BUTTON_H);
  l.fillBtn = new IntRect(l.paintBtn.x + l.paintBtn.w + 8, curY, 70, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_SECTION_GAP;

  l.addBtn = new IntRect(innerX, curY, 24, PANEL_BUTTON_H);
  l.removeBtn = new IntRect(l.addBtn.x + l.addBtn.w + 6, curY, 24, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_SECTION_GAP;

  // Palette
  int swatchW = 60;
  int swatchH = 18;
  int nameH = 18;
  int gapX = 8;
  int maxPerRow = max(1, (PANEL_W - 2 * PANEL_PADDING + gapX) / (swatchW + gapX));
  int rowY = curY;
  int col = 0;
  int paletteBottom = rowY;
  if (mapModel != null && mapModel.biomeTypes != null) {
    for (int i = 0; i < mapModel.biomeTypes.size(); i++) {
      int x = innerX + col * (swatchW + gapX);
      l.swatches.add(new IntRect(x, rowY, swatchW, swatchH));
      l.nameRects.add(new IntRect(x, rowY + swatchH + 4, swatchW, nameH));
      paletteBottom = max(paletteBottom, rowY + swatchH + 4 + nameH);
      col++;
      if (col >= maxPerRow) {
        col = 0;
        rowY += swatchH + nameH + PANEL_ROW_GAP;
      }
    }
  }
  curY = paletteBottom + PANEL_SECTION_GAP;

  l.hueSlider = new IntRect(innerX, curY + PANEL_LABEL_H, 200, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;

  l.brushSlider = new IntRect(innerX, curY + PANEL_LABEL_H, 180, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_PADDING;

  l.panel.h = curY - l.panel.y;
  return l;
}

void drawBiomesPanel() {
  BiomesLayout layout = buildBiomesLayout();
  drawPanelBackground(layout.panel);

  int labelX = layout.panel.x + PANEL_PADDING;
  fill(0);
  textAlign(LEFT, TOP);
  text("Biomes", labelX, layout.titleY);

  // Generate button (auto-fill None zones)
  drawBevelButton(layout.generateBtn.x, layout.generateBtn.y, layout.generateBtn.w, layout.generateBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  boolean hasNone = mapModel != null && mapModel.hasAnyNoneBiome();
  String genLabel = hasNone ? "Fill gaps" : "Regenerate";
  text(genLabel, layout.generateBtn.x + layout.generateBtn.w * 0.5f, layout.generateBtn.y + layout.generateBtn.h * 0.5f);

  // Reset to None button
  drawBevelButton(layout.resetBtn.x, layout.resetBtn.y, layout.resetBtn.w, layout.resetBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Reset", layout.resetBtn.x + layout.resetBtn.w * 0.5f, layout.resetBtn.y + layout.resetBtn.h * 0.5f);

  // Paint button
  drawBevelButton(layout.paintBtn.x, layout.paintBtn.y, layout.paintBtn.w, layout.paintBtn.h,
                  currentZonePaintMode == ZonePaintMode.ZONE_PAINT);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Paint", layout.paintBtn.x + layout.paintBtn.w * 0.5f, layout.paintBtn.y + layout.paintBtn.h * 0.5f);

  // Fill button
  drawBevelButton(layout.fillBtn.x, layout.fillBtn.y, layout.fillBtn.w, layout.fillBtn.h,
                  currentZonePaintMode == ZonePaintMode.ZONE_FILL);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Fill", layout.fillBtn.x + layout.fillBtn.w * 0.5f, layout.fillBtn.y + layout.fillBtn.h * 0.5f);

  // Add / Remove biome type buttons
  // "+" button
  drawBevelButton(layout.addBtn.x, layout.addBtn.y, layout.addBtn.w, layout.addBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("+", layout.addBtn.x + layout.addBtn.w * 0.5f, layout.addBtn.y + layout.addBtn.h * 0.5f);

  // "-" button (disabled if index 0 or only one type)
  boolean canRemove = (mapModel.biomeTypes != null &&
                       mapModel.biomeTypes.size() > 1 &&
                       activeBiomeIndex > 0);

  drawBevelButton(layout.removeBtn.x, layout.removeBtn.y, layout.removeBtn.w, layout.removeBtn.h, !canRemove);
  fill(10);
  textAlign(CENTER, CENTER);
  text("-", layout.removeBtn.x + layout.removeBtn.w * 0.5f, layout.removeBtn.y + layout.removeBtn.h * 0.5f);

  // Palette
  if (mapModel == null || mapModel.biomeTypes == null) return;
  int n = mapModel.biomeTypes.size();
  if (n == 0) return;

  textAlign(CENTER, TOP);

  for (int i = 0; i < n; i++) {
    ZoneType zt = mapModel.biomeTypes.get(i);
    IntRect sw = layout.swatches.get(i);
    IntRect nameRect = layout.nameRects.get(i);
    stroke(120);
    if (i == activeBiomeIndex) {
      strokeWeight(2);
    } else {
      strokeWeight(1);
    }
    fill(zt.col);
    rect(sw.x, sw.y, sw.w, sw.h, 4);

    boolean editing = (editingZoneNameIndex == i);
    if (editing) {
      stroke(60);
      fill(255);
      rect(nameRect.x, nameRect.y, nameRect.w, nameRect.h);
      fill(0);
      textAlign(LEFT, CENTER);
      String shown = zoneNameDraft;
      text(shown, nameRect.x + 6, nameRect.y + nameRect.h / 2);
      float caretX = nameRect.x + 6 + textWidth(shown);
      stroke(0);
      line(caretX, nameRect.y + 4, caretX, nameRect.y + nameRect.h - 4);
    } else {
      drawBevelButton(nameRect.x, nameRect.y, nameRect.w, nameRect.h, i == activeBiomeIndex);
      fill(10);
      textAlign(CENTER, CENTER);
      text(zt.name, nameRect.x + nameRect.w * 0.5f, nameRect.y + nameRect.h * 0.5f);
    }
  }

  // Hue slider for currently selected biome
  if (activeBiomeIndex >= 0 && activeBiomeIndex < n) {
    ZoneType active = mapModel.biomeTypes.get(activeBiomeIndex);

    IntRect hue = layout.hueSlider;

    // Track
    stroke(160);
    fill(230);
    rect(hue.x, hue.y, hue.w, hue.h, 4);

    // Handle position from active.hue01
    float hNorm = constrain(active.hue01, 0, 1);
    float handleX = hue.x + hNorm * hue.w;
    float handleR = hue.h * 0.9f;
    float handleY = hue.y + hue.h / 2.0f;

    fill(40);
    noStroke();
    ellipse(handleX, handleY, handleR, handleR);

    // Label
    fill(0);
    textAlign(LEFT, BOTTOM);
    text("Hue for \"" + active.name + "\": " + nf(active.hue01, 1, 2),
         hue.x, hue.y - 4);
  }

  // Brush radius slider
  IntRect brush = layout.brushSlider;
  stroke(160);
  fill(230);
  rect(brush.x, brush.y, brush.w, brush.h, 4);
  float bNorm = constrain(map(zoneBrushRadius, 0.01f, 0.15f, 0, 1), 0, 1);
  float bx = brush.x + bNorm * brush.w;
  fill(40);
  noStroke();
  ellipse(bx, brush.y + brush.h / 2.0f, brush.h * 0.9f, brush.h * 0.9f);
  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Brush radius", brush.x, brush.y - 4);
}

// ----- ADMIN (Zones) PANEL -----
class AdminLayout {
  IntRect panel;
  int titleY;
}

AdminLayout buildAdminLayout() {
  AdminLayout l = new AdminLayout();
  l.panel = new IntRect(PANEL_X, panelTop(), PANEL_W, PANEL_TITLE_H + 2 * PANEL_PADDING);
  l.titleY = l.panel.y + PANEL_PADDING;
  return l;
}

void drawAdminPanel() {
  // TODO later something similar to the biome panel but with outlined zones instead of colored ones
}

// ----- PATHS PANEL -----

class PathsLayout {
  IntRect panel;
  int titleY;
  IntRect typeAddBtn;
  IntRect typeRemoveBtn;
  IntRect routeSlider;
  IntRect flattestSlider;
  IntRect avoidWaterCheck;
  ArrayList<IntRect> typeSwatches = new ArrayList<IntRect>();
  ArrayList<IntRect> typeNameRects = new ArrayList<IntRect>();
  IntRect typeHueSlider;
  IntRect typeWeightSlider;
}

class PathsListLayout {
  IntRect panel;
  int titleY;
  IntRect newBtn;
  ArrayList<PathRowLayout> rows = new ArrayList<PathRowLayout>();
}

class PathRowLayout {
  IntRect selectRect;
  IntRect nameRect;
  IntRect delRect;
  IntRect typeRect;
  int statsY;
  int statsH;
}

PathsLayout buildPathsLayout() {
  PathsLayout l = new PathsLayout();
  l.panel = new IntRect(PANEL_X, panelTop(), PANEL_W, 0);
  int innerX = l.panel.x + PANEL_PADDING;
  int curY = l.panel.y + PANEL_PADDING;
  l.titleY = curY;
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;

  int sliderW = 200;
  l.routeSlider = new IntRect(innerX, curY + PANEL_LABEL_H, sliderW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;

  l.flattestSlider = new IntRect(innerX, curY + PANEL_LABEL_H, sliderW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;

  l.avoidWaterCheck = new IntRect(innerX, curY, PANEL_CHECK_SIZE, PANEL_CHECK_SIZE);
  curY += PANEL_CHECK_SIZE + PANEL_SECTION_GAP;

  // Path types controls
  l.typeAddBtn = new IntRect(innerX, curY, 24, PANEL_BUTTON_H);
  l.typeRemoveBtn = new IntRect(l.typeAddBtn.x + l.typeAddBtn.w + 6, curY, 24, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_ROW_GAP;

  int swatchW = 60;
  int swatchH = 18;
  int nameH = 18;
  int gapX = 8;
  int maxPerRow = max(1, (PANEL_W - 2 * PANEL_PADDING + gapX) / (swatchW + gapX));
  int rowY = curY;
  int col = 0;
  int paletteBottom = rowY;
  if (mapModel != null && mapModel.pathTypes != null) {
    for (int i = 0; i < mapModel.pathTypes.size(); i++) {
      int x = innerX + col * (swatchW + gapX);
      l.typeSwatches.add(new IntRect(x, rowY, swatchW, swatchH));
      l.typeNameRects.add(new IntRect(x, rowY + swatchH + 4, swatchW, nameH));
      paletteBottom = max(paletteBottom, rowY + swatchH + 4 + nameH);
      col++;
      if (col >= maxPerRow) {
        col = 0;
        rowY += swatchH + nameH + PANEL_ROW_GAP;
      }
    }
  }
  curY = paletteBottom + PANEL_SECTION_GAP;

  l.typeHueSlider = new IntRect(innerX, curY + PANEL_LABEL_H, 200, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;

  l.typeWeightSlider = new IntRect(innerX, curY + PANEL_LABEL_H, 180, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_PADDING;

  l.panel.h = curY - l.panel.y;
  return l;
}

PathsListLayout buildPathsListLayout() {
  PathsListLayout l = new PathsListLayout();
  int w = RIGHT_PANEL_W;
  int x = width - w - PANEL_PADDING;
  int y = panelTop();
  l.panel = new IntRect(x, y, w, height - y - PANEL_PADDING);
  l.titleY = y + PANEL_PADDING;
  int newBtnY = l.panel.y + l.panel.h - PANEL_PADDING - PANEL_BUTTON_H;
  l.newBtn = new IntRect(x + PANEL_PADDING, newBtnY, 90, PANEL_BUTTON_H);
  return l;
}

void populatePathsListRows(PathsListLayout layout) {
  layout.rows.clear();
  int labelX = layout.panel.x + PANEL_PADDING;
  int curY = layout.titleY + PANEL_TITLE_H + PANEL_SECTION_GAP;
  int maxY = layout.newBtn.y - PANEL_SECTION_GAP;

  int textH = ceil(textAscent() + textDescent());
  int nameH = max(PANEL_LABEL_H + 6, textH + 8);
  int typeH = max(PANEL_LABEL_H + 2, textH + 6);
  int statsH = max(PANEL_LABEL_H, textH);
  int rowGap = 10;

  for (int i = 0; i < mapModel.paths.size(); i++) {
    int rowTotal = nameH + 6 + typeH + 4 + statsH + rowGap;
    if (curY + rowTotal > maxY) break;

    int selectSize = max(16, nameH - 2);
    PathRowLayout row = new PathRowLayout();
    row.selectRect = new IntRect(labelX, curY, selectSize, selectSize);
    row.nameRect = new IntRect(row.selectRect.x + row.selectRect.w + 6, curY,
                               layout.panel.w - 2 * PANEL_PADDING - row.selectRect.w - 6 - 40,
                               nameH);
    row.delRect = new IntRect(row.nameRect.x + row.nameRect.w + 6, curY, 30, nameH);

    curY += nameH + 6;

    row.typeRect = new IntRect(labelX + selectSize + 6, curY, 160, typeH);
    curY += typeH + 4;

    row.statsY = curY;
    row.statsH = statsH;
    curY += statsH + rowGap;

    layout.rows.add(row);
  }
}

void drawPathsPanel() {
  PathsLayout layout = buildPathsLayout();
  drawPanelBackground(layout.panel);

  int labelX = layout.panel.x + PANEL_PADDING;
  fill(0);
  textAlign(LEFT, TOP);
  text("Paths", labelX, layout.titleY);

  // Route mode slider (discrete)
  IntRect rs = layout.routeSlider;
  stroke(160);
  fill(225);
  rect(rs.x, rs.y, rs.w, rs.h, 4);
  String[] modes = { "Ends", "Pathfind" };
  int modeCount = modes.length;
  float stepW = (modeCount > 1) ? (rs.w / (float)(modeCount - 1)) : 0;
  stroke(120);
  for (int i = 0; i < modeCount; i++) {
    float tx = rs.x + i * stepW;
    line(tx, rs.y, tx, rs.y + rs.h);
  }
  float handleX;
  if (pathRouteModeIndex <= 0) handleX = rs.x;
  else if (pathRouteModeIndex >= modeCount - 1) handleX = rs.x + rs.w;
  else handleX = rs.x + pathRouteModeIndex * stepW;
  float knobR = rs.h * 0.9f;
  float knobY = rs.y + rs.h / 2.0f;
  fill(40);
  noStroke();
  ellipse(handleX, knobY, knobR, knobR);
  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Route mode: " + modes[pathRouteModeIndex], rs.x, rs.y - 4);

  // Flattest bias slider (only relevant for Flattest mode)
  IntRect fs = layout.flattestSlider;
  stroke(160);
  fill(230);
  rect(fs.x, fs.y, fs.w, fs.h, 4);
  float fNorm = constrain(map(flattestSlopeBias, 0.0f, 200.0f, 0, 1), 0, 1);
  float fx = fs.x + fNorm * fs.w;
  fill(40);
  noStroke();
  ellipse(fx, fs.y + fs.h / 2.0f, fs.h * 0.9f, fs.h * 0.9f);
  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Flattest slope bias (" + nf(flattestSlopeBias, 1, 2) + ")", fs.x, fs.y - 4);

  // Avoid water checkbox
  drawCheckbox(layout.avoidWaterCheck.x, layout.avoidWaterCheck.y,
               layout.avoidWaterCheck.w, pathAvoidWater, "Avoid water");

  // Only type management on this panel

  // Path types add/remove
  drawBevelButton(layout.typeAddBtn.x, layout.typeAddBtn.y, layout.typeAddBtn.w, layout.typeAddBtn.h, false);
  drawBevelButton(layout.typeRemoveBtn.x, layout.typeRemoveBtn.y, layout.typeRemoveBtn.w, layout.typeRemoveBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("+", layout.typeAddBtn.x + layout.typeAddBtn.w / 2, layout.typeAddBtn.y + layout.typeAddBtn.h / 2);
  text("-", layout.typeRemoveBtn.x + layout.typeRemoveBtn.w / 2, layout.typeRemoveBtn.y + layout.typeRemoveBtn.h / 2);

  // Path type palette
  if (mapModel == null || mapModel.pathTypes == null) return;
  int n = mapModel.pathTypes.size();
  if (n == 0) return;

  textAlign(CENTER, TOP);
  for (int i = 0; i < n; i++) {
    PathType pt = mapModel.pathTypes.get(i);
    IntRect sw = layout.typeSwatches.get(i);
    IntRect nameRect = layout.typeNameRects.get(i);
    stroke(120);
    strokeWeight(i == activePathTypeIndex ? 2 : 1);
    fill(pt.col);
    rect(sw.x, sw.y, sw.w, sw.h, 4);

    boolean editing = (editingPathTypeNameIndex == i);
    if (editing) {
      stroke(60);
      fill(255);
      rect(nameRect.x, nameRect.y, nameRect.w, nameRect.h);
      fill(0);
      textAlign(LEFT, CENTER);
      String shown = pathTypeNameDraft;
      text(shown, nameRect.x + 6, nameRect.y + nameRect.h / 2);
      float caretX = nameRect.x + 6 + textWidth(shown);
      stroke(0);
      line(caretX, nameRect.y + 4, caretX, nameRect.y + nameRect.h - 4);
    } else {
      drawBevelButton(nameRect.x, nameRect.y, nameRect.w, nameRect.h, i == activePathTypeIndex);
      fill(10);
      textAlign(CENTER, CENTER);
      text(pt.name, nameRect.x + nameRect.w * 0.5f, nameRect.y + nameRect.h * 0.5f);
    }
  }

  // Color (hue) slider for active path type
  if (activePathTypeIndex >= 0 && activePathTypeIndex < n) {
    PathType active = mapModel.pathTypes.get(activePathTypeIndex);
    IntRect hue = layout.typeHueSlider;
    stroke(160);
    fill(230);
    rect(hue.x, hue.y, hue.w, hue.h, 4);
    float hNorm = constrain(active.hue01, 0, 1);
    handleX = hue.x + hNorm * hue.w;
    float handleR = hue.h * 0.9f;
    float handleY = hue.y + hue.h / 2.0f;
    fill(40);
    noStroke();
    ellipse(handleX, handleY, handleR, handleR);
    fill(0);
    textAlign(LEFT, BOTTOM);
    text("Hue for \"" + active.name + "\": " + nf(active.hue01, 1, 2),
         hue.x, hue.y - 4);

    // Weight slider per type
    IntRect weight = layout.typeWeightSlider;
    stroke(160);
    fill(230);
    rect(weight.x, weight.y, weight.w, weight.h, 4);
    float wNorm = constrain(map(active.weightPx, 0.5f, 8.0f, 0, 1), 0, 1);
    float wx = weight.x + wNorm * weight.w;
    fill(40);
    noStroke();
    ellipse(wx, weight.y + weight.h / 2.0f, weight.h * 0.9f, weight.h * 0.9f);
    fill(0);
    text("Weight for \"" + active.name + "\" (px)", weight.x, weight.y - 4);
  }
}

void drawPathsListPanel() {
  PathsListLayout layout = buildPathsListLayout();
  populatePathsListRows(layout);
  drawPanelBackground(layout.panel);

  int labelX = layout.panel.x + PANEL_PADDING;
  int curY = layout.titleY;
  fill(0);
  textAlign(LEFT, TOP);
  text("Paths list", labelX, curY);
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;

  if (mapModel.paths.isEmpty()) {
    fill(80);
    textAlign(LEFT, TOP);
    text("No paths yet.", labelX, curY);
  } else {
    for (int i = 0; i < layout.rows.size(); i++) {
      Path p = mapModel.paths.get(i);
      PathRowLayout row = layout.rows.get(i);

      boolean selected = (selectedPathIndex == i);
      drawBevelButton(row.selectRect.x, row.selectRect.y, row.selectRect.w, row.selectRect.h, selected);
      fill(10);
      textAlign(CENTER, CENTER);
      text(selected ? "*" : "", row.selectRect.x + row.selectRect.w / 2, row.selectRect.y + row.selectRect.h / 2 - 1);

      boolean editing = (editingPathNameIndex == i);
      if (editing) {
        stroke(60);
        fill(255);
        rect(row.nameRect.x, row.nameRect.y, row.nameRect.w, row.nameRect.h);
        fill(0);
        textAlign(LEFT, CENTER);
        String shown = pathNameDraft;
        text(shown, row.nameRect.x + 6, row.nameRect.y + row.nameRect.h / 2);
        float caretX = row.nameRect.x + 6 + textWidth(shown);
        stroke(0);
        line(caretX, row.nameRect.y + 4, caretX, row.nameRect.y + row.nameRect.h - 4);
      } else {
        drawBevelButton(row.nameRect.x, row.nameRect.y, row.nameRect.w, row.nameRect.h, selected);
        fill(10);
        textAlign(LEFT, CENTER);
        String title = (p.name != null && p.name.length() > 0 ? p.name : "Path");
        text("#" + (i + 1) + " " + title, row.nameRect.x + 6, row.nameRect.y + row.nameRect.h / 2);
      }

      drawBevelButton(row.delRect.x, row.delRect.y, row.delRect.w, row.delRect.h, false);
      fill(10);
      textAlign(CENTER, CENTER);
      text("X", row.delRect.x + row.delRect.w / 2, row.delRect.y + row.delRect.h / 2);

      PathType pt = mapModel.getPathType(p.typeId);
      String typLabel = (pt != null ? pt.name : "Type");
      drawBevelButton(row.typeRect.x, row.typeRect.y, row.typeRect.w, row.typeRect.h, false);
      fill(10);
      textAlign(LEFT, CENTER);
      text("Type: " + typLabel, row.typeRect.x + 6, row.typeRect.y + row.typeRect.h / 2);

      int segs = p.segmentCount();
      float len = p.totalLength();
      fill(40);
      textAlign(LEFT, CENTER);
      text("Segments: " + segs + "   Len: " + nf(len, 1, 3),
           labelX + row.selectRect.w + 6, row.statsY + row.statsH / 2);
    }
  }

  drawBevelButton(layout.newBtn.x, layout.newBtn.y, layout.newBtn.w, layout.newBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("New Path", layout.newBtn.x + layout.newBtn.w / 2, layout.newBtn.y + layout.newBtn.h / 2);
}

// ----- ELEVATION PANEL -----

class ElevationLayout {
  IntRect panel;
  int titleY;
  IntRect seaSlider;
  IntRect radiusSlider;
  IntRect strengthSlider;
  IntRect raiseBtn;
  IntRect lowerBtn;
  IntRect noiseSlider;
  IntRect perlinBtn;
  IntRect varyBtn;
}

ElevationLayout buildElevationLayout() {
  ElevationLayout l = new ElevationLayout();
  l.panel = new IntRect(PANEL_X, panelTop(), PANEL_W, 0);
  int innerX = l.panel.x + PANEL_PADDING;
  int curY = l.panel.y + PANEL_PADDING;
  l.titleY = curY;
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;

  int sliderW = 200;
  l.seaSlider = new IntRect(innerX, curY + PANEL_LABEL_H, sliderW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

  l.radiusSlider = new IntRect(innerX, curY + PANEL_LABEL_H, sliderW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

  l.strengthSlider = new IntRect(innerX, curY + PANEL_LABEL_H, sliderW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

  l.raiseBtn = new IntRect(innerX, curY, 80, PANEL_BUTTON_H);
  l.lowerBtn = new IntRect(l.raiseBtn.x + l.raiseBtn.w + 8, curY, 80, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_SECTION_GAP;

  l.noiseSlider = new IntRect(innerX, curY + PANEL_LABEL_H, sliderW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

  int genW = 120;
  l.perlinBtn = new IntRect(innerX, curY, genW, PANEL_BUTTON_H);
  l.varyBtn = new IntRect(l.perlinBtn.x + genW + 8, curY, genW, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_PADDING;

  l.panel.h = curY - l.panel.y;
  return l;
}

void drawElevationPanel() {
  ElevationLayout layout = buildElevationLayout();
  drawPanelBackground(layout.panel);

  int labelX = layout.panel.x + PANEL_PADDING;
  fill(0);
  textAlign(LEFT, TOP);
  text("Elevation", labelX, layout.titleY);

  // Sea level slider (-0.5 .. 0.5)
  IntRect sea = layout.seaSlider;
  stroke(160);
  fill(230);
  rect(sea.x, sea.y, sea.w, sea.h, 4);
  float seaNorm = constrain((seaLevel + 0.5f) / 1.0f, 0, 1);
  float sx = sea.x + seaNorm * sea.w;
  fill(40);
  noStroke();
  ellipse(sx, sea.y + sea.h / 2.0f, sea.h * 0.9f, sea.h * 0.9f);
  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Water level: " + nf(seaLevel, 1, 2), sea.x, sea.y - 4);

  // Brush radius slider (0.01..0.2)
  IntRect rad = layout.radiusSlider;
  stroke(160);
  fill(230);
  rect(rad.x, rad.y, rad.w, rad.h, 4);
  float rNorm = constrain(map(elevationBrushRadius, 0.01f, 0.2f, 0, 1), 0, 1);
  float rx = rad.x + rNorm * rad.w;
  fill(40);
  noStroke();
  ellipse(rx, rad.y + rad.h / 2.0f, rad.h * 0.9f, rad.h * 0.9f);
  fill(0);
  text("Brush radius", rad.x, rad.y - 4);

  // Brush strength slider (0.005..0.2)
  IntRect str = layout.strengthSlider;
  stroke(160);
  fill(230);
  rect(str.x, str.y, str.w, str.h, 4);
  float sNorm = constrain(map(elevationBrushStrength, 0.005f, 0.2f, 0, 1), 0, 1);
  float stx = str.x + sNorm * str.w;
  fill(40);
  noStroke();
  ellipse(stx, str.y + str.h / 2.0f, str.h * 0.9f, str.h * 0.9f);
  fill(0);
  text("Brush strength", str.x, str.y - 4);

  // Raise / Lower buttons
  drawBevelButton(layout.raiseBtn.x, layout.raiseBtn.y, layout.raiseBtn.w, layout.raiseBtn.h, elevationBrushRaise);
  drawBevelButton(layout.lowerBtn.x, layout.lowerBtn.y, layout.lowerBtn.w, layout.lowerBtn.h, !elevationBrushRaise);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Raise", layout.raiseBtn.x + layout.raiseBtn.w / 2, layout.raiseBtn.y + layout.raiseBtn.h / 2);
  text("Lower", layout.lowerBtn.x + layout.lowerBtn.w / 2, layout.lowerBtn.y + layout.lowerBtn.h / 2);

  // Noise controls stacked
  IntRect noise = layout.noiseSlider;
  stroke(160);
  fill(230);
  rect(noise.x, noise.y, noise.w, noise.h, 4);
  float nNorm = constrain(map(elevationNoiseScale, 1.0f, 12.0f, 0, 1), 0, 1);
  float nx = noise.x + nNorm * noise.w;
  fill(40);
  noStroke();
  ellipse(nx, noise.y + noise.h / 2.0f, noise.h * 0.9f, noise.h * 0.9f);
  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Noise scale", noise.x, noise.y - 4);

  drawBevelButton(layout.perlinBtn.x, layout.perlinBtn.y, layout.perlinBtn.w, layout.perlinBtn.h, false);
  drawBevelButton(layout.varyBtn.x, layout.varyBtn.y, layout.varyBtn.w, layout.varyBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Perlin Generate", layout.perlinBtn.x + layout.perlinBtn.w / 2, layout.perlinBtn.y + layout.perlinBtn.h / 2);
  text("Vary", layout.varyBtn.x + layout.varyBtn.w / 2, layout.varyBtn.y + layout.varyBtn.h / 2);
}

// ----- LABELS PANEL -----
class LabelsLayout {
  IntRect panel;
  int titleY;
  IntRect textBox;
}

LabelsLayout buildLabelsLayout() {
  LabelsLayout l = new LabelsLayout();
  l.panel = new IntRect(PANEL_X, panelTop(), PANEL_W, 0);
  int innerX = l.panel.x + PANEL_PADDING;
  int curY = l.panel.y + PANEL_PADDING;
  l.titleY = curY;
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;

  l.textBox = new IntRect(innerX, curY, PANEL_W - 2 * PANEL_PADDING - 20, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_PADDING;
  l.panel.h = curY - l.panel.y;
  return l;
}

void drawLabelsPanel() {
  LabelsLayout layout = buildLabelsLayout();
  drawPanelBackground(layout.panel);

  int labelX = layout.panel.x + PANEL_PADDING;
  fill(0);
  textAlign(LEFT, TOP);
  text("Labels", labelX, layout.titleY);

  stroke(80);
  fill(245);
  rect(layout.textBox.x, layout.textBox.y, layout.textBox.w, layout.textBox.h);
  fill(0);
  textAlign(LEFT, CENTER);
  text(labelDraft, layout.textBox.x + 6, layout.textBox.y + layout.textBox.h / 2);
  textAlign(LEFT, TOP);
  text("Type text then click map to place/continue editing", layout.textBox.x, layout.textBox.y - 18);
}

// ----- STRUCTURES PANEL -----
class StructuresLayout {
  IntRect panel;
  int titleY;
  IntRect sizeSlider;
}

StructuresLayout buildStructuresLayout() {
  StructuresLayout l = new StructuresLayout();
  l.panel = new IntRect(PANEL_X, panelTop(), PANEL_W, 0);
  int innerX = l.panel.x + PANEL_PADDING;
  int curY = l.panel.y + PANEL_PADDING;
  l.titleY = curY;
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;

  l.sizeSlider = new IntRect(innerX, curY + PANEL_LABEL_H, 200, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_PADDING;

  l.panel.h = curY - l.panel.y;
  return l;
}

void drawStructuresPanelUI() {
  StructuresLayout layout = buildStructuresLayout();
  drawPanelBackground(layout.panel);

  int labelX = layout.panel.x + PANEL_PADDING;
  fill(0);
  textAlign(LEFT, TOP);
  text("Structures", labelX, layout.titleY);

  // Size slider
  IntRect sz = layout.sizeSlider;
  stroke(160);
  fill(230);
  rect(sz.x, sz.y, sz.w, sz.h, 4);
  float sNorm = constrain(map(structureSize, 0.01f, 0.2f, 0, 1), 0, 1);
  float sx = sz.x + sNorm * sz.w;
  fill(40);
  noStroke();
  ellipse(sx, sz.y + sz.h / 2.0f, sz.h * 0.9f, sz.h * 0.9f);
  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Size", sz.x, sz.y - 4);
}

// ----- RENDER PANEL -----
class RenderLayout {
  IntRect panel;
  int titleY;
  ArrayList<IntRect> checks = new ArrayList<IntRect>();
  String[] labels;
  IntRect lightAzimuthSlider;
  IntRect lightAltitudeSlider;
}

RenderLayout buildRenderLayout() {
  RenderLayout l = new RenderLayout();
  l.panel = new IntRect(PANEL_X, panelTop(), PANEL_W, 0);
  int innerX = l.panel.x + PANEL_PADDING;
  int curY = l.panel.y + PANEL_PADDING;
  l.titleY = curY;
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;

  int sliderW = 200;
  l.labels = new String[] { "Biomes", "Water", "Elevation", "Paths", "Labels", "Structures" };
  for (int i = 0; i < l.labels.length; i++) {
    l.checks.add(new IntRect(innerX, curY, PANEL_CHECK_SIZE, PANEL_CHECK_SIZE));
    curY += PANEL_CHECK_SIZE + PANEL_ROW_GAP;

    if (i == 2) { // after "Elevation"
      l.lightAzimuthSlider = new IntRect(innerX, curY + PANEL_LABEL_H, sliderW, PANEL_SLIDER_H);
      curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;
      l.lightAltitudeSlider = new IntRect(innerX, curY + PANEL_LABEL_H, sliderW, PANEL_SLIDER_H);
      curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;
    }
  }

  curY += PANEL_PADDING;
  l.panel.h = curY - l.panel.y;
  return l;
}

void drawRenderPanel() {
  RenderLayout layout = buildRenderLayout();
  drawPanelBackground(layout.panel);

  int labelX = layout.panel.x + PANEL_PADDING;
  fill(0);
  textAlign(LEFT, TOP);
  text("Rendering", labelX, layout.titleY);

  drawCheckbox(layout.checks.get(0).x, layout.checks.get(0).y, layout.checks.get(0).w, renderShowZones, "Biomes");
  drawCheckbox(layout.checks.get(1).x, layout.checks.get(1).y, layout.checks.get(1).w, renderShowWater, "Water");
  drawCheckbox(layout.checks.get(2).x, layout.checks.get(2).y, layout.checks.get(2).w, renderShowElevation, "Elevation");

  // Lighting sliders (render mode only)
  if (layout.lightAzimuthSlider != null) {
    IntRect az = layout.lightAzimuthSlider;
    stroke(160);
    fill(230);
    rect(az.x, az.y, az.w, az.h, 4);
    float tAz = constrain(renderLightAzimuthDeg / 360.0f, 0, 1);
    float ax = az.x + tAz * az.w;
    fill(40);
    noStroke();
    ellipse(ax, az.y + az.h / 2.0f, az.h * 0.9f, az.h * 0.9f);
    fill(0);
    textAlign(LEFT, BOTTOM);
    text("Light azimuth (" + nf(renderLightAzimuthDeg, 1, 0) + " deg)", az.x, az.y - 4);
  }

  if (layout.lightAltitudeSlider != null) {
    IntRect alt = layout.lightAltitudeSlider;
    stroke(160);
    fill(230);
    rect(alt.x, alt.y, alt.w, alt.h, 4);
    float tAlt = constrain(map(renderLightAltitudeDeg, 5.0f, 80.0f, 0, 1), 0, 1);
    float altHandleX = alt.x + tAlt * alt.w;
    fill(40);
    noStroke();
    ellipse(altHandleX, alt.y + alt.h / 2.0f, alt.h * 0.9f, alt.h * 0.9f);
    fill(0);
    textAlign(LEFT, BOTTOM);
    text("Light altitude (" + nf(renderLightAltitudeDeg, 1, 0) + " deg)", alt.x, alt.y - 4);
    textAlign(LEFT, TOP);
  }

  drawCheckbox(layout.checks.get(3).x, layout.checks.get(3).y, layout.checks.get(3).w, renderShowPaths, "Paths");
  drawCheckbox(layout.checks.get(4).x, layout.checks.get(4).y, layout.checks.get(4).w, renderShowLabels, "Labels");
  drawCheckbox(layout.checks.get(5).x, layout.checks.get(5).y, layout.checks.get(5).w, renderShowStructures, "Structures");
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

PathRouteMode currentPathRouteMode() {
  int idx = constrain(pathRouteModeIndex, 0, 1);
  switch (idx) {
    case 0: return PathRouteMode.ENDS;
    case 1: return PathRouteMode.PATHFIND;
  }
  return PathRouteMode.PATHFIND;
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

void drawCheckbox(int x, int y, int size, boolean on, String label) {
  stroke(80);
  fill(on ? 200 : 245);
  rect(x, y, size, size);
  if (on) {
    line(x + 3, y + size / 2, x + size / 2, y + size - 3);
    line(x + size / 2, y + size - 3, x + size - 3, y + 3);
  }
  fill(0);
  textAlign(LEFT, CENTER);
  text(label, x + size + 6, y + size / 2);
}

IntRect getActivePanelRect() {
  switch (currentTool) {
    case EDIT_SITES: {
      SitesLayout l = buildSitesLayout();
      return l.panel;
    }
    case EDIT_ELEVATION: {
      ElevationLayout l = buildElevationLayout();
      return l.panel;
    }
    case EDIT_BIOMES: {
      BiomesLayout l = buildBiomesLayout();
      return l.panel;
    }
    case EDIT_ADMIN: { AdminLayout l = buildAdminLayout(); return l.panel; }
    case EDIT_STRUCTURES: {
      StructuresLayout l = buildStructuresLayout();
      return l.panel;
    }
    case EDIT_PATHS: {
      PathsLayout l = buildPathsLayout();
      return l.panel;
    }
    case EDIT_LABELS: {
      LabelsLayout l = buildLabelsLayout();
      return l.panel;
    }
    case EDIT_RENDER: {
      RenderLayout l = buildRenderLayout();
      return l.panel;
    }
  }
  return null;
}
