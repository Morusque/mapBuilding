final int PANEL_HINT_H = PANEL_SECTION_GAP + (PANEL_LABEL_H + 2) * 2 + 6;

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
  curY += PANEL_HINT_H;
  l.panel.h = curY - l.panel.y;
  return l;
}

void drawSitesPanel() {
  SitesLayout layout = buildSitesLayout();
  drawPanelBackground(layout.panel);

  int labelX = layout.panel.x + PANEL_PADDING;
  fill(0);
  textAlign(LEFT, TOP);
  text("Cells generation", labelX, layout.titleY);

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
  text("Density: " + siteTargetCount + " cells", d.x, d.y - 4);

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

  drawControlsHint(layout.panel,
                   "right-click: pan; wheel: zoom.",
                   "drag: drag; DEL: remove selected.");
}

// ----- Biomes PANEL -----

class BiomesLayout {
  IntRect panel;
  int titleY;
  IntRect paintBtn;
  IntRect fillBtn;
  IntRect generateBtn;
  IntRect resetBtn;
  IntRect fillUnderwaterBtn;
  IntRect addBtn;
  IntRect removeBtn;
  ArrayList<IntRect> swatches = new ArrayList<IntRect>();
  IntRect nameField;
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
  l.fillUnderwaterBtn = new IntRect(innerX, curY, 120, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_ROW_GAP;

  l.paintBtn = new IntRect(innerX, curY, 70, PANEL_BUTTON_H);
  l.fillBtn = new IntRect(l.paintBtn.x + l.paintBtn.w + 8, curY, 70, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_SECTION_GAP;

  l.addBtn = new IntRect(innerX, curY, 24, PANEL_BUTTON_H);
  l.removeBtn = new IntRect(l.addBtn.x + l.addBtn.w + 6, curY, 24, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_SECTION_GAP;

  // Palette
  int swatchW = 70;
  int swatchH = 22;
  int gapX = 8;
  int maxPerRow = max(1, (PANEL_W - 2 * PANEL_PADDING + gapX) / (swatchW + gapX));
  int rowY = curY;
  int col = 0;
  int paletteBottom = rowY;
  if (mapModel != null && mapModel.biomeTypes != null) {
    for (int i = 0; i < mapModel.biomeTypes.size(); i++) {
      int x = innerX + col * (swatchW + gapX);
      l.swatches.add(new IntRect(x, rowY, swatchW, swatchH));
      paletteBottom = max(paletteBottom, rowY + swatchH);
      col++;
      if (col >= maxPerRow) {
        col = 0;
        rowY += swatchH + PANEL_ROW_GAP;
      }
    }
  }
  curY = paletteBottom + PANEL_ROW_GAP;

  l.nameField = new IntRect(innerX, curY + PANEL_LABEL_H, 200, PANEL_BUTTON_H);
  curY += PANEL_LABEL_H + PANEL_BUTTON_H + PANEL_SECTION_GAP;

  l.hueSlider = new IntRect(innerX, curY + PANEL_LABEL_H, 200, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;

  l.brushSlider = new IntRect(innerX, curY + PANEL_LABEL_H, 180, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_PADDING;

  curY += PANEL_HINT_H;
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

  // Fill underwater button (short label, separate row)
  drawBevelButton(layout.fillUnderwaterBtn.x, layout.fillUnderwaterBtn.y, layout.fillUnderwaterBtn.w, layout.fillUnderwaterBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Fill underwater", layout.fillUnderwaterBtn.x + layout.fillUnderwaterBtn.w * 0.5f, layout.fillUnderwaterBtn.y + layout.fillUnderwaterBtn.h * 0.5f);

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

  for (int i = 0; i < n; i++) {
    pushStyle();
    ZoneType zt = mapModel.biomeTypes.get(i);
    IntRect sw = layout.swatches.get(i);
    stroke(i == activeBiomeIndex ? 0 : 120);
    strokeWeight(i == activeBiomeIndex ? 2 : 1);
    fill(zt.col);
    rect(sw.x, sw.y, sw.w, sw.h, 4);

    // Overlay label text
    fill(20);
    textAlign(CENTER, CENTER);
    text(zt.name, sw.x + sw.w * 0.5f, sw.y + sw.h * 0.5f);
    popStyle();
  }

  // Editable name field for selected biome
  if (activeBiomeIndex >= 0 && activeBiomeIndex < n) {
    IntRect nf = layout.nameField;
    ZoneType active = mapModel.biomeTypes.get(activeBiomeIndex);
    boolean editing = (editingBiomeNameIndex == activeBiomeIndex);
    fill(0);
    textAlign(LEFT, BOTTOM);
    text("Name", nf.x, nf.y - 4);
    stroke(80);
    fill(255);
    rect(nf.x, nf.y, nf.w, nf.h);
    fill(0);
    textAlign(LEFT, CENTER);
    String shown = editing ? biomeNameDraft : active.name;
    text(shown, nf.x + 6, nf.y + nf.h / 2);
    if (editing) {
      float caretX = nf.x + 6 + textWidth(biomeNameDraft);
      stroke(0);
      line(caretX, nf.y + 4, caretX, nf.y + nf.h - 4);
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

  drawControlsHint(layout.panel,
                   "left-click: paint/fill",
                   "right-click: pan, wheel: zoom.");
}

// ----- ZONES PANEL -----
class ZonesLayout {
  IntRect panel;
  int titleY;
  IntRect resetBtn;
  IntRect regenerateBtn;
  IntRect brushSlider;
  IntRect listPanel;
}

class ZoneRowLayout {
  IntRect selectRect;
  IntRect nameRect;
  IntRect hueSlider;
}

class ZonesListLayout {
  IntRect panel;
  int titleY;
  IntRect newBtn;
  ArrayList<ZoneRowLayout> rows = new ArrayList<ZoneRowLayout>();
}

ZonesListLayout buildZonesListLayout() {
  ZonesListLayout l = new ZonesListLayout();
  int w = RIGHT_PANEL_W;
  int x = width - w - PANEL_PADDING;
  int y = panelTop();
  l.panel = new IntRect(x, y, w, height - y - PANEL_PADDING);
  l.titleY = y + PANEL_PADDING;
  int newBtnY = l.titleY + PANEL_TITLE_H + PANEL_SECTION_GAP;
  l.newBtn = new IntRect(x + PANEL_PADDING, newBtnY, 100, PANEL_BUTTON_H);
  return l;
}

void populateZonesRows(ZonesListLayout layout) {
  layout.rows.clear();
  if (mapModel == null || mapModel.zones == null) return;
  int labelX = layout.panel.x + PANEL_PADDING;
  int curY = layout.newBtn.y + layout.newBtn.h + PANEL_SECTION_GAP;
  int maxY = layout.panel.y + layout.panel.h - PANEL_SECTION_GAP;
  int rowH = 28;
  int hueW = 90;
  for (int i = 0; i < mapModel.zones.size(); i++) {
    if (curY + rowH > maxY) break;
    ZoneRowLayout row = new ZoneRowLayout();
    int selectW = 18;
    row.selectRect = new IntRect(labelX, curY, selectW, rowH);
    row.nameRect = new IntRect(labelX + selectW + 6, curY, layout.panel.w - 2 * PANEL_PADDING - selectW - 6 - hueW - 8, rowH);
    row.hueSlider = new IntRect(row.nameRect.x + row.nameRect.w + 6, curY + (rowH - PANEL_SLIDER_H) / 2, hueW, PANEL_SLIDER_H);
    layout.rows.add(row);
    curY += rowH + 6;
  }
}

void drawZonesListPanel() {
  ZonesListLayout layout = buildZonesListLayout();
  populateZonesRows(layout);
  drawPanelBackground(layout.panel);

  int labelX = layout.panel.x + PANEL_PADDING;
  int curY = layout.titleY;
  fill(0);
  textAlign(LEFT, TOP);
  text("Zones", labelX, curY);

  drawBevelButton(layout.newBtn.x, layout.newBtn.y, layout.newBtn.w, layout.newBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("New zone", layout.newBtn.x + layout.newBtn.w / 2, layout.newBtn.y + layout.newBtn.h / 2);

  if (mapModel == null || mapModel.zones == null) return;

  for (int i = 0; i < layout.rows.size(); i++) {
    MapModel.MapZone az = mapModel.zones.get(i);
    ZoneRowLayout row = layout.rows.get(i);
    boolean selected = (activeZoneIndex == i);

    drawBevelButton(row.selectRect.x, row.selectRect.y, row.selectRect.w, row.selectRect.h, selected);
    fill(10);
    textAlign(CENTER, CENTER);
    text(selected ? "*" : "", row.selectRect.x + row.selectRect.w / 2, row.selectRect.y + row.selectRect.h / 2);

    boolean editing = (editingZoneNameIndex == i);
    if (editing) {
      stroke(60);
      fill(255);
      rect(row.nameRect.x, row.nameRect.y, row.nameRect.w, row.nameRect.h);
      fill(0);
      textAlign(LEFT, CENTER);
      text(zoneNameDraft, row.nameRect.x + 6, row.nameRect.y + row.nameRect.h / 2);
      float caretX = row.nameRect.x + 6 + textWidth(zoneNameDraft);
      stroke(0);
      line(caretX, row.nameRect.y + 4, caretX, row.nameRect.y + row.nameRect.h - 4);
    } else {
      drawBevelButton(row.nameRect.x, row.nameRect.y, row.nameRect.w, row.nameRect.h, selected);
      fill(10);
      textAlign(LEFT, CENTER);
      text(az.name, row.nameRect.x + 6, row.nameRect.y + row.nameRect.h / 2);
    }

    stroke(160);
    fill(230);
    rect(row.hueSlider.x, row.hueSlider.y, row.hueSlider.w, row.hueSlider.h, 4);
    float hNorm = constrain(az.hue01, 0, 1);
    float hx = row.hueSlider.x + hNorm * row.hueSlider.w;
    float hr = row.hueSlider.h * 0.9f;
    float hy = row.hueSlider.y + row.hueSlider.h / 2.0f;
    fill(40);
    noStroke();
    ellipse(hx, hy, hr, hr);
  }
}

ZonesLayout buildZonesLayout() {
  ZonesLayout l = new ZonesLayout();
  l.panel = new IntRect(PANEL_X, panelTop(), PANEL_W, 0);
  int innerX = l.panel.x + PANEL_PADDING;
  int curY = l.panel.y + PANEL_PADDING;
  l.titleY = curY;
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;

  l.resetBtn = new IntRect(innerX, curY, 90, PANEL_BUTTON_H);
  l.regenerateBtn = new IntRect(l.resetBtn.x + l.resetBtn.w + 8, curY, 110, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_ROW_GAP;

  l.brushSlider = new IntRect(innerX, curY + PANEL_LABEL_H, 180, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_PADDING;

  // Right-side list panel reserved space
  l.listPanel = new IntRect(width - RIGHT_PANEL_W - PANEL_PADDING, panelTop(), RIGHT_PANEL_W, height - panelTop() - PANEL_PADDING);

  curY += PANEL_HINT_H;
  curY += PANEL_HINT_H;
  l.panel.h = curY - l.panel.y;
  return l;
}

void drawZonesPanel() {
  ZonesLayout layout = buildZonesLayout();
  drawPanelBackground(layout.panel);

  int labelX = layout.panel.x + PANEL_PADDING;
  fill(0);
  textAlign(LEFT, TOP);
  text("Zones", labelX, layout.titleY);

  // Reset and regenerate
  drawBevelButton(layout.resetBtn.x, layout.resetBtn.y, layout.resetBtn.w, layout.resetBtn.h, false);
  drawBevelButton(layout.regenerateBtn.x, layout.regenerateBtn.y, layout.regenerateBtn.w, layout.regenerateBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Reset", layout.resetBtn.x + layout.resetBtn.w * 0.5f, layout.resetBtn.y + layout.resetBtn.h * 0.5f);
  text("Regenerate", layout.regenerateBtn.x + layout.regenerateBtn.w * 0.5f, layout.regenerateBtn.y + layout.regenerateBtn.h * 0.5f);

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

  drawControlsHint(layout.panel,
                   "left-click: paint",
                   "right-click pan; wheel: zoom.");
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
  IntRect taperCheck;
  IntRect typeMinWeightSlider;
  ArrayList<IntRect> typeSwatches = new ArrayList<IntRect>();
  IntRect nameField;
  IntRect typeHueSlider;
  IntRect typeWeightSlider;
}

class PathsListLayout {
  IntRect panel;
  int titleY;
  IntRect newBtn;
  IntRect deselectBtn;
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
  int gapX = 8;
  int maxPerRow = max(1, (PANEL_W - 2 * PANEL_PADDING + gapX) / (swatchW + gapX));
  int rowY = curY;
  int col = 0;
  int paletteBottom = rowY;
  if (mapModel != null && mapModel.pathTypes != null) {
    for (int i = 0; i < mapModel.pathTypes.size(); i++) {
      int x = innerX + col * (swatchW + gapX);
      l.typeSwatches.add(new IntRect(x, rowY, swatchW, swatchH));
      paletteBottom = max(paletteBottom, rowY + swatchH);
      col++;
      if (col >= maxPerRow) {
        col = 0;
        rowY += swatchH + PANEL_ROW_GAP;
      }
    }
  }
  curY = paletteBottom + PANEL_ROW_GAP;

  l.nameField = new IntRect(innerX, curY + PANEL_LABEL_H, 200, PANEL_BUTTON_H);
  curY += PANEL_LABEL_H + PANEL_BUTTON_H + PANEL_SECTION_GAP;

  l.typeHueSlider = new IntRect(innerX, curY + PANEL_LABEL_H, 200, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;

  l.typeWeightSlider = new IntRect(innerX, curY + PANEL_LABEL_H, 180, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

  l.typeMinWeightSlider = new IntRect(innerX, curY + PANEL_LABEL_H, 180, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

  l.taperCheck = new IntRect(innerX, curY, PANEL_CHECK_SIZE, PANEL_CHECK_SIZE);
  curY += PANEL_CHECK_SIZE + PANEL_PADDING;

  curY += PANEL_HINT_H;
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
  int newBtnY = l.titleY + PANEL_TITLE_H + PANEL_SECTION_GAP;
  l.newBtn = new IntRect(x + PANEL_PADDING, newBtnY, 90, PANEL_BUTTON_H);
  l.deselectBtn = new IntRect(l.newBtn.x + l.newBtn.w + 8, newBtnY, 90, PANEL_BUTTON_H);
  return l;
}

void populatePathsListRows(PathsListLayout layout) {
  layout.rows.clear();
  int labelX = layout.panel.x + PANEL_PADDING;
  int curY = layout.newBtn.y + layout.newBtn.h + PANEL_SECTION_GAP;
  int maxY = layout.panel.y + layout.panel.h - PANEL_SECTION_GAP;

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
  float fNorm = constrain(map(flattestSlopeBias, FLATTEST_BIAS_MIN, FLATTEST_BIAS_MAX, 0, 1), 0, 1);
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

  for (int i = 0; i < n; i++) {
    pushStyle();
    PathType pt = mapModel.pathTypes.get(i);
    IntRect sw = layout.typeSwatches.get(i);
    stroke(i == activePathTypeIndex ? 0 : 120);
    strokeWeight(i == activePathTypeIndex ? 2 : 1);
    fill(pt.col);
    rect(sw.x, sw.y, sw.w, sw.h, 4);

    fill(20);
    textAlign(CENTER, CENTER);
    text(pt.name, sw.x + sw.w * 0.5f, sw.y + sw.h * 0.5f);
    popStyle();
  }

  // Color (hue) slider for active path type
  if (activePathTypeIndex >= 0 && activePathTypeIndex < n) {
    PathType active = mapModel.pathTypes.get(activePathTypeIndex);
    // Editable name field
    IntRect nf = layout.nameField;
    boolean editing = (editingPathTypeNameIndex == activePathTypeIndex);
    fill(0);
    textAlign(LEFT, BOTTOM);
    text("Name", nf.x, nf.y - 4);
    stroke(80);
    fill(255);
    rect(nf.x, nf.y, nf.w, nf.h);
    fill(0);
    textAlign(LEFT, CENTER);
    String shown = editing ? pathTypeNameDraft : active.name;
    text(shown, nf.x + 6, nf.y + nf.h / 2);
    if (editing) {
      float caretX = nf.x + 6 + textWidth(pathTypeNameDraft);
      stroke(0);
      line(caretX, nf.y + 4, caretX, nf.y + nf.h - 4);
    }

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

  // Min weight slider per type
  IntRect minw = layout.typeMinWeightSlider;
  stroke(160);
  fill(230);
  rect(minw.x, minw.y, minw.w, minw.h, 4);
    float minNorm = constrain(map(active.minWeightPx, 0.5f, active.weightPx, 0, 1), 0, 1);
    float minx = minw.x + minNorm * minw.w;
    fill(40);
    noStroke();
    ellipse(minx, minw.y + minw.h / 2.0f, minw.h * 0.9f, minw.h * 0.9f);
    fill(0);
    text("Min weight (px)", minw.x, minw.y - 4);

    // Taper toggle per type
  drawCheckbox(layout.taperCheck.x, layout.taperCheck.y,
               layout.taperCheck.w, active.taperOn, "Taper width (start small)");
  }

  drawControlsHint(layout.panel,
                   "left-click: start/end; DEL: cancels",
                   "right-click: pan; wheel: zoom; C: clear; use Deselect to unselect");
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
  drawBevelButton(layout.deselectBtn.x, layout.deselectBtn.y, layout.deselectBtn.w, layout.deselectBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("New Path", layout.newBtn.x + layout.newBtn.w / 2, layout.newBtn.y + layout.newBtn.h / 2);
  text("Deselect", layout.deselectBtn.x + layout.deselectBtn.w / 2, layout.deselectBtn.y + layout.deselectBtn.h / 2);
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

  curY += PANEL_HINT_H;
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

  drawControlsHint(layout.panel,
                   "left-click: raise/lower",
                   "right-click: pan; wheel: zoom.");
}

// ----- LABELS PANEL -----
class LabelsLayout {
  IntRect panel;
  int titleY;
  IntRect textBox;
  ArrayList<IntRect> targetButtons = new ArrayList<IntRect>();
}

class LabelsListLayout {
  IntRect panel;
  int titleY;
  ArrayList<LabelRowLayout> rows = new ArrayList<LabelRowLayout>();
}

class LabelRowLayout {
  IntRect selectRect;
  IntRect nameRect;
  IntRect delRect;
  IntRect targetRect;
}

LabelsLayout buildLabelsLayout() {
  LabelsLayout l = new LabelsLayout();
  l.panel = new IntRect(PANEL_X, panelTop(), PANEL_W, 0);
  int innerX = l.panel.x + PANEL_PADDING;
  int curY = l.panel.y + PANEL_PADDING;
  l.titleY = curY;
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;

  l.textBox = new IntRect(innerX, curY, PANEL_W - 2 * PANEL_PADDING - 20, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_ROW_GAP;

  String[] targets = { "Free", "Biomes", "Zones", "Struct" };
  int btnW = 60;
  int gap = 6;
  for (int i = 0; i < targets.length; i++) {
    l.targetButtons.add(new IntRect(innerX + i * (btnW + gap), curY, btnW, PANEL_BUTTON_H));
  }
  curY += PANEL_BUTTON_H + PANEL_PADDING;
  curY += PANEL_HINT_H;
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

  // Target buttons
  String[] targets = { "Free", "Biomes", "Zones", "Struct" };
  for (int i = 0; i < layout.targetButtons.size(); i++) {
    IntRect b = layout.targetButtons.get(i);
    boolean active = (labelTargetMode == LabelTarget.values()[i]);
    drawBevelButton(b.x, b.y, b.w, b.h, active);
    fill(10);
    textAlign(CENTER, CENTER);
    text(targets[i], b.x + b.w / 2, b.y + b.h / 2);
  }

  drawControlsHint(layout.panel,
                   "left-click: place",
                   "right-click pan; wheel: zoom");
}

LabelsListLayout buildLabelsListLayout() {
  LabelsListLayout l = new LabelsListLayout();
  int w = RIGHT_PANEL_W;
  int x = width - w - PANEL_PADDING;
  int y = panelTop();
  l.panel = new IntRect(x, y, w, height - y - PANEL_PADDING);
  l.titleY = y + PANEL_PADDING;
  return l;
}

void populateLabelsListRows(LabelsListLayout layout) {
  layout.rows.clear();
  int labelX = layout.panel.x + PANEL_PADDING;
  int curY = layout.titleY + PANEL_TITLE_H + PANEL_SECTION_GAP;
  int maxY = layout.panel.y + layout.panel.h - PANEL_SECTION_GAP;
  int rowH = 24;
  for (int i = 0; i < mapModel.labels.size(); i++) {
    if (curY + rowH > maxY) break;
    LabelRowLayout row = new LabelRowLayout();
    int selectW = 18;
    row.selectRect = new IntRect(labelX, curY, selectW, rowH);
    row.nameRect = new IntRect(labelX + selectW + 6, curY, layout.panel.w - 2 * PANEL_PADDING - selectW - 6 - 60, rowH);
    row.targetRect = new IntRect(row.nameRect.x + row.nameRect.w + 4, curY, 26, rowH);
    row.delRect = new IntRect(row.targetRect.x + row.targetRect.w + 4, curY, 26, rowH);
    layout.rows.add(row);
    curY += rowH + 6;
  }
}

void drawLabelsListPanel() {
  LabelsListLayout layout = buildLabelsListLayout();
  populateLabelsListRows(layout);
  drawPanelBackground(layout.panel);

  int labelX = layout.panel.x + PANEL_PADDING;
  int curY = layout.titleY;
  fill(0);
  textAlign(LEFT, TOP);
  text("Labels", labelX, curY);
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;

  for (int i = 0; i < layout.rows.size(); i++) {
    MapLabel lbl = mapModel.labels.get(i);
    LabelRowLayout row = layout.rows.get(i);
    boolean selected = (selectedLabelIndex == i);
    drawBevelButton(row.selectRect.x, row.selectRect.y, row.selectRect.w, row.selectRect.h, selected);
    fill(10);
    textAlign(CENTER, CENTER);
    text(selected ? "*" : "", row.selectRect.x + row.selectRect.w / 2, row.selectRect.y + row.selectRect.h / 2);

    boolean editing = (editingLabelIndex == i);
    if (editing) {
      stroke(60);
      fill(255);
      rect(row.nameRect.x, row.nameRect.y, row.nameRect.w, row.nameRect.h);
      fill(0);
      textAlign(LEFT, CENTER);
      text(labelDraft, row.nameRect.x + 6, row.nameRect.y + row.nameRect.h / 2);
      float caretX = row.nameRect.x + 6 + textWidth(labelDraft);
      stroke(0);
      line(caretX, row.nameRect.y + 4, caretX, row.nameRect.y + row.nameRect.h - 4);
    } else {
      drawBevelButton(row.nameRect.x, row.nameRect.y, row.nameRect.w, row.nameRect.h, selected);
      fill(10);
      textAlign(LEFT, CENTER);
      text(lbl.text, row.nameRect.x + 6, row.nameRect.y + row.nameRect.h / 2);
    }

    drawBevelButton(row.targetRect.x, row.targetRect.y, row.targetRect.w, row.targetRect.h, false);
    fill(10);
    textAlign(CENTER, CENTER);
    text(labelTargetShort(lbl.target), row.targetRect.x + row.targetRect.w / 2, row.targetRect.y + row.targetRect.h / 2);

    drawBevelButton(row.delRect.x, row.delRect.y, row.delRect.w, row.delRect.h, false);
    fill(10);
    textAlign(CENTER, CENTER);
    text("X", row.delRect.x + row.delRect.w / 2, row.delRect.y + row.delRect.h / 2);
  }
}

String labelTargetShort(LabelTarget lt) {
  switch (lt) {
    case BIOME: return "B";
    case ZONE: return "Z";
    case STRUCT: return "S";
    default: return "F";
  }
}

String structureShapeLabel(StructureShape sh) {
  switch (sh) {
    case RECTANGLE: return "Rect";
    case CIRCLE: return "Circle";
    case TRIANGLE: return "Triangle";
    case HEXAGON: return "Hex";
    default: return "Square";
  }
}

// ----- STRUCTURES PANEL -----
class StructuresLayout {
  IntRect panel;
  int titleY;
  IntRect sizeSlider;
  IntRect angleSlider;
  IntRect ratioSlider;
  ArrayList<IntRect> shapeButtons = new ArrayList<IntRect>();
  ArrayList<IntRect> snapButtons = new ArrayList<IntRect>();
}

StructuresLayout buildStructuresLayout() {
  StructuresLayout l = new StructuresLayout();
  l.panel = new IntRect(PANEL_X, panelTop(), PANEL_W, 0);
  int innerX = l.panel.x + PANEL_PADDING;
  int curY = l.panel.y + PANEL_PADDING;
  l.titleY = curY;
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;

  l.sizeSlider = new IntRect(innerX, curY + PANEL_LABEL_H, 200, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

  l.angleSlider = new IntRect(innerX, curY + PANEL_LABEL_H, 200, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_PADDING;

  l.ratioSlider = new IntRect(innerX, curY + PANEL_LABEL_H, 200, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_PADDING;

  // Shape selection buttons
  String[] shapeLabels = { "Rect", "Square", "Circle", "Triangle", "Hex" };
  int btnWShape = 58;
  int gapShape = 6;
  for (int i = 0; i < shapeLabels.length; i++) {
    l.shapeButtons.add(new IntRect(innerX + i * (btnWShape + gapShape), curY, btnWShape, PANEL_BUTTON_H));
  }
  curY += PANEL_BUTTON_H + PANEL_PADDING;

  String[] snapModes = { "None", "Next", "Center" };
  int btnW = 70;
  int gap = 6;
  for (int i = 0; i < snapModes.length; i++) {
    l.snapButtons.add(new IntRect(innerX + i * (btnW + gap), curY, btnW, PANEL_BUTTON_H));
  }
  curY += PANEL_BUTTON_H + PANEL_PADDING;

  curY += PANEL_HINT_H;
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

  // Angle offset slider (-180..180 deg)
  IntRect ang = layout.angleSlider;
  stroke(160);
  fill(230);
  rect(ang.x, ang.y, ang.w, ang.h, 4);
  float angDeg = degrees(structureAngleOffsetRad);
  float aNorm = constrain(map(angDeg, -180.0f, 180.0f, 0, 1), 0, 1);
  float ax = ang.x + aNorm * ang.w;
  fill(40);
  noStroke();
  ellipse(ax, ang.y + ang.h / 2.0f, ang.h * 0.9f, ang.h * 0.9f);
  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Angle offset (" + nf(angDeg, 1, 1) + " deg)", ang.x, ang.y - 4);

  // Rectangle ratio slider (width/height)
  IntRect ratio = layout.ratioSlider;
  stroke(160);
  fill(230);
  rect(ratio.x, ratio.y, ratio.w, ratio.h, 4);
  float rNorm = constrain(map(structureAspectRatio, 0.3f, 3.0f, 0, 1), 0, 1);
  float rx = ratio.x + rNorm * ratio.w;
  fill(40);
  noStroke();
  ellipse(rx, ratio.y + ratio.h / 2.0f, ratio.h * 0.9f, ratio.h * 0.9f);
  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Rectangle ratio (W/H): " + nf(structureAspectRatio, 1, 2), ratio.x, ratio.y - 4);

  // Shape buttons
  String[] shapeLabels = { "Rect", "Square", "Circle", "Triangle", "Hex" };
  for (int i = 0; i < layout.shapeButtons.size(); i++) {
    IntRect b = layout.shapeButtons.get(i);
    boolean active = (structureShape == StructureShape.values()[i]);
    drawBevelButton(b.x, b.y, b.w, b.h, active);
    fill(10);
    textAlign(CENTER, CENTER);
    text(shapeLabels[i], b.x + b.w / 2, b.y + b.h / 2);
  }

  // Snap mode buttons
  String[] snapModes = { "None", "Next", "Center" };
  for (int i = 0; i < layout.snapButtons.size(); i++) {
    IntRect b = layout.snapButtons.get(i);
    boolean active = (structureSnapMode == StructureSnapMode.values()[i]);
    drawBevelButton(b.x, b.y, b.w, b.h, active);
    fill(10);
    textAlign(CENTER, CENTER);
    text(snapModes[i], b.x + b.w / 2, b.y + b.h / 2);
  }

  drawControlsHint(layout.panel,
                   "left-click: place",
                   "right-click: pan; wheel: zoom; use Deselect to unselect");
}

// ----- STRUCTURES LIST (right panel) -----
class StructuresListLayout {
  IntRect panel;
  int titleY;
  IntRect deselectBtn;
  ArrayList<StructureRowLayout> rows = new ArrayList<StructureRowLayout>();
}

class StructureRowLayout {
  IntRect selectRect;
  IntRect nameRect;
  IntRect delRect;
}

StructuresListLayout buildStructuresListLayout() {
  StructuresListLayout l = new StructuresListLayout();
  int w = RIGHT_PANEL_W;
  int x = width - w - PANEL_PADDING;
  int y = panelTop();
  l.panel = new IntRect(x, y, w, height - y - PANEL_PADDING);
  l.titleY = y + PANEL_PADDING;
  int btnY = l.titleY + PANEL_TITLE_H + PANEL_SECTION_GAP;
  l.deselectBtn = new IntRect(x + PANEL_PADDING, btnY, 90, PANEL_BUTTON_H);
  return l;
}

void populateStructuresListRows(StructuresListLayout layout) {
  layout.rows.clear();
  int labelX = layout.panel.x + PANEL_PADDING;
  int curY = layout.deselectBtn.y + layout.deselectBtn.h + PANEL_SECTION_GAP;
  int maxY = layout.panel.y + layout.panel.h - PANEL_SECTION_GAP;
  int rowH = 24;
  for (int i = 0; i < mapModel.structures.size(); i++) {
    if (curY + rowH > maxY) break;
    StructureRowLayout row = new StructureRowLayout();
    int selectW = 18;
    row.selectRect = new IntRect(labelX, curY, selectW, rowH);
    row.nameRect = new IntRect(labelX + selectW + 6, curY, layout.panel.w - 2 * PANEL_PADDING - selectW - 6 - 30, rowH);
    row.delRect = new IntRect(row.nameRect.x + row.nameRect.w + 6, curY, 24, rowH);
    layout.rows.add(row);
    curY += rowH + 6;
  }
}

void drawStructuresListPanel() {
  StructuresListLayout layout = buildStructuresListLayout();
  populateStructuresListRows(layout);
  drawPanelBackground(layout.panel);

  int labelX = layout.panel.x + PANEL_PADDING;
  int curY = layout.titleY;
  fill(0);
  textAlign(LEFT, TOP);
  text("Structures", labelX, curY);
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;

  drawBevelButton(layout.deselectBtn.x, layout.deselectBtn.y, layout.deselectBtn.w, layout.deselectBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Deselect", layout.deselectBtn.x + layout.deselectBtn.w / 2, layout.deselectBtn.y + layout.deselectBtn.h / 2);

  for (int i = 0; i < layout.rows.size(); i++) {
    StructureRowLayout row = layout.rows.get(i);
    Structure s = mapModel.structures.get(i);
    boolean selected = (selectedStructureIndex == i);
    drawBevelButton(row.selectRect.x, row.selectRect.y, row.selectRect.w, row.selectRect.h, selected);
    fill(10);
    textAlign(CENTER, CENTER);
    text(selected ? "*" : "", row.selectRect.x + row.selectRect.w / 2, row.selectRect.y + row.selectRect.h / 2);

    drawBevelButton(row.nameRect.x, row.nameRect.y, row.nameRect.w, row.nameRect.h, selected);
    fill(10);
    textAlign(LEFT, CENTER);
    String label = "Struct " + (i + 1) + " - " + structureShapeLabel(s.shape);
    text(label, row.nameRect.x + 6, row.nameRect.y + row.nameRect.h / 2);

    drawBevelButton(row.delRect.x, row.delRect.y, row.delRect.w, row.delRect.h, false);
    fill(10);
    textAlign(CENTER, CENTER);
    text("X", row.delRect.x + row.delRect.w / 2, row.delRect.y + row.delRect.h / 2);
  }
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
  l.labels = new String[] {
    "Biomes", "Water", "Water contours",
    "Elevation", "Elevation contours",
    "Paths", "Labels", "Structures", "Black/White"
  };
  for (int i = 0; i < l.labels.length; i++) {
    l.checks.add(new IntRect(innerX, curY, PANEL_CHECK_SIZE, PANEL_CHECK_SIZE));
    curY += PANEL_CHECK_SIZE + PANEL_ROW_GAP;

    if (i == 3) { // after "Elevation"
      l.lightAzimuthSlider = new IntRect(innerX, curY + PANEL_LABEL_H, sliderW, PANEL_SLIDER_H);
      curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;
      l.lightAltitudeSlider = new IntRect(innerX, curY + PANEL_LABEL_H, sliderW, PANEL_SLIDER_H);
      curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;
    }
  }

  curY += PANEL_PADDING + PANEL_HINT_H;
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
  drawCheckbox(layout.checks.get(2).x, layout.checks.get(2).y, layout.checks.get(2).w, renderWaterContours, "Water contours");
  drawCheckbox(layout.checks.get(3).x, layout.checks.get(3).y, layout.checks.get(3).w, renderShowElevation, "Elevation");
  drawCheckbox(layout.checks.get(4).x, layout.checks.get(4).y, layout.checks.get(4).w, renderElevationContours, "Elevation contours");
  drawCheckbox(layout.checks.get(8).x, layout.checks.get(8).y, layout.checks.get(8).w, renderBlackWhite, "Black/White");

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

  drawCheckbox(layout.checks.get(5).x, layout.checks.get(5).y, layout.checks.get(5).w, renderShowPaths, "Paths");
  drawCheckbox(layout.checks.get(6).x, layout.checks.get(6).y, layout.checks.get(6).w, renderShowLabels, "Labels");
  drawCheckbox(layout.checks.get(7).x, layout.checks.get(7).y, layout.checks.get(7).w, renderShowStructures, "Structures");
  // Black/white toggle already drawn above with checks[8]

  drawControlsHint(layout.panel,
                   "right-click: pan",
                   "wheel: zoom");
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

void drawControlsHint(IntRect panel, String line1, String line2) {
  if (panel == null) return;
  int lines = 0;
  if (line1 != null && line1.length() > 0) lines++;
  if (line2 != null && line2.length() > 0) lines++;
  if (lines == 0) return;

  float totalH = lines * (PANEL_LABEL_H + 2);
  float yTop = panel.y + panel.h - PANEL_PADDING - totalH;
  float sepY = yTop - 4;

  // Separator to visually isolate hints from controls above
  stroke(140);
  line(panel.x + PANEL_PADDING, sepY, panel.x + panel.w - PANEL_PADDING, sepY);

  fill(40);
  textAlign(LEFT, TOP);
  float y = yTop;
  if (line1 != null && line1.length() > 0) {
    text(line1, panel.x + PANEL_PADDING, y);
    y += PANEL_LABEL_H + 2;
  }
  if (line2 != null && line2.length() > 0) {
    text(line2, panel.x + PANEL_PADDING, y);
  }
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
    case EDIT_ZONES: { ZonesLayout l = buildZonesLayout(); return l.panel; }
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
