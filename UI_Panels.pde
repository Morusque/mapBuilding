final int PANEL_HINT_H = PANEL_SECTION_GAP + (PANEL_LABEL_H + 2) * 2 + 6;

int hintHeight(int lines) {
  if (lines <= 0) return 0;
  return PANEL_SECTION_GAP + (PANEL_LABEL_H + 2) * lines + 6;
}

// ----- SNAP SETTINGS (top of left menu) -----
class SnapSettingsLayout {
  IntRect panel;
  ArrayList<IntRect> checks = new ArrayList<IntRect>();
  IntRect elevationSlider;
}

SnapSettingsLayout buildSnapSettingsLayout() {
  SnapSettingsLayout l = new SnapSettingsLayout();
  l.panel = new IntRect(PANEL_X, snapPanelTop(), PANEL_W, snapSettingsPanelHeight());
  int innerX = l.panel.x + PANEL_PADDING;
  int curY = l.panel.y + PANEL_PADDING;
  String[] labels = {
    "Water",
    "Biomes",
    "Underwater biomes",
    "Zones",
    "Paths",
    "Other structures",
    "Elevation"
  };
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;
  for (int i = 0; i < labels.length; i++) {
    l.checks.add(new IntRect(innerX, curY, PANEL_CHECK_SIZE, PANEL_CHECK_SIZE));
    curY += PANEL_CHECK_SIZE + PANEL_ROW_GAP;
  }
  l.elevationSlider = new IntRect(innerX + PANEL_CHECK_SIZE + 8, curY + PANEL_LABEL_H, 160, PANEL_SLIDER_H);
  return l;
}

void drawSnapSettingsPanel() {
  SnapSettingsLayout l = buildSnapSettingsLayout();
  drawPanelBackground(l.panel);

  int labelX = l.panel.x + PANEL_PADDING;
  fill(0);
  textAlign(LEFT, TOP);
  text("Snap targets", labelX, l.panel.y + PANEL_PADDING);

  String[] labels = {
    "Water",
    "Biomes",
    "Underwater biomes",
    "Zones",
    "Paths",
    "Other structures",
    "Elevation"
  };
  String[] snapKeys = {
    "snap_water",
    "snap_biomes",
    "snap_underwater_biomes",
    "snap_zones",
    "snap_paths",
    "snap_structures",
    "snap_elevation"
  };
  boolean[] values = {
    snapWaterEnabled,
    snapBiomesEnabled,
    snapUnderwaterBiomesEnabled,
    snapZonesEnabled,
    snapPathsEnabled,
    snapStructuresEnabled,
    snapElevationEnabled
  };

  for (int i = 0; i < labels.length; i++) {
    IntRect b = l.checks.get(i);
    drawCheckbox(b.x, b.y, b.w, values[i], labels[i]);
    if (i < snapKeys.length) {
      int hintW = l.panel.w - 2 * PANEL_PADDING;
      registerUiTooltip(new IntRect(b.x, b.y, hintW, b.h), tooltipFor(snapKeys[i]));
    }
  }

  // Elevation divisions slider
  IntRect es = l.elevationSlider;
  stroke(160);
  fill(230);
  rect(es.x, es.y, es.w, es.h, 4);
  int divMin = 2;
  int divMax = 24;
  float t = constrain((snapElevationDivisions - divMin) / (float)(divMax - divMin), 0, 1);
  float sx = es.x + t * es.w;
  fill(40);
  noStroke();
  ellipse(sx, es.y + es.h / 2.0f, es.h * 0.9f, es.h * 0.9f);
  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Elevation divisions: " + snapElevationDivisions, es.x, es.y - 4);
  registerUiTooltip(es, tooltipFor("snap_elevation_divisions"));
}

boolean isInSnapSettingsPanel(int mx, int my) {
  SnapSettingsLayout l = buildSnapSettingsLayout();
  return l.panel.contains(mx, my);
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

  // Generate controls up top
  l.generateBtn = new IntRect(innerX, curY, 110, PANEL_BUTTON_H);
  l.keepCheckbox = new IntRect(l.generateBtn.x + l.generateBtn.w + 12,
                               curY + (PANEL_BUTTON_H - PANEL_CHECK_SIZE) / 2,
                               PANEL_CHECK_SIZE, PANEL_CHECK_SIZE);
  curY += PANEL_BUTTON_H + PANEL_ROW_GAP;

  int sliderW = 200;
  l.densitySlider = new IntRect(innerX, curY + PANEL_LABEL_H, sliderW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

  l.fuzzSlider = new IntRect(innerX, curY + PANEL_LABEL_H, sliderW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

  l.modeSlider = new IntRect(innerX, curY + PANEL_LABEL_H, sliderW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;

  curY += PANEL_PADDING + hintHeight(4);
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
  registerUiTooltip(d, tooltipFor("site_density"));

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
  registerUiTooltip(f, tooltipFor("site_fuzz"));

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
  registerUiTooltip(m, tooltipFor("site_mode"));

  // ---------- Generate button ----------
  IntRect g = layout.generateBtn;
  drawBevelButton(g.x, g.y, g.w, g.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Generate", g.x + g.w / 2, g.y + g.h / 2);
  registerUiTooltip(g, tooltipFor("sites_generate"));

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
  registerUiTooltip(new IntRect(c.x, c.y, c.w + 120, c.h), tooltipFor("sites_keep"));

  drawControlsHint(layout.panel,
                   "right-click: pan",
                   "wheel: zoom",
                   "drag: drag",
                   "DEL: remove selected");
}

// ----- Biomes PANEL -----

class BiomesLayout {
  IntRect panel;
  int titleY;
  IntRect paintBtn;
  IntRect fillBtn;
  IntRect genModeSelector;
  IntRect genApplyBtn;
  IntRect genValueSlider;
  IntRect genValueWaterBtn;
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

  int selectorW = 200;
  l.genModeSelector = new IntRect(innerX, curY + PANEL_LABEL_H, selectorW, PANEL_SLIDER_H);
  l.genApplyBtn = new IntRect(l.genModeSelector.x + l.genModeSelector.w + 10, curY + PANEL_LABEL_H - 2, 90, PANEL_BUTTON_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;
  l.genValueSlider = new IntRect(innerX, curY + PANEL_LABEL_H, selectorW, PANEL_SLIDER_H);
  l.genValueWaterBtn = new IntRect(l.genValueSlider.x + l.genValueSlider.w + 10, curY + PANEL_LABEL_H - 2, 80, PANEL_BUTTON_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;

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

  curY += hintHeight(3);
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

  // Generation mode selector + apply
  IntRect gsel = layout.genModeSelector;
  int modeCount = biomeGenerateModes.length;
  int maxIdx = max(1, modeCount - 1);
  float tMode = constrain(biomeGenerateModeIndex / (float)maxIdx, 0, 1);
  String modeName = biomeGenerateModes[constrain(biomeGenerateModeIndex, 0, modeCount - 1)];
  drawSelectorSlider(gsel, tMode, "Generation mode: " + modeName, modeCount);
  registerUiTooltip(gsel, tooltipFor("biome_gen_mode"));

  if (layout.genApplyBtn != null) {
    drawBevelButton(layout.genApplyBtn.x, layout.genApplyBtn.y, layout.genApplyBtn.w, layout.genApplyBtn.h, false);
    fill(10);
    textAlign(CENTER, CENTER);
    text("Generate", layout.genApplyBtn.x + layout.genApplyBtn.w / 2, layout.genApplyBtn.y + layout.genApplyBtn.h / 2);
    registerUiTooltip(layout.genApplyBtn, tooltipFor("biome_gen_apply"));
  }

  // Generation value slider (0..1 displayed)
  IntRect gv = layout.genValueSlider;
  stroke(160);
  fill(230);
  rect(gv.x, gv.y, gv.w, gv.h, 4);
  float gvx = gv.x + constrain(biomeGenerateValue01, 0, 1) * gv.w;
  fill(40);
  noStroke();
  ellipse(gvx, gv.y + gv.h / 2.0f, gv.h * 0.9f, gv.h * 0.9f);
  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Value (" + nf(biomeGenerateValue01, 1, 2) + ")", gv.x, gv.y - 4);
  registerUiTooltip(gv, tooltipFor("biome_gen_value"));

  // "Set to water level" helper
  if (layout.genValueWaterBtn != null) {
    drawBevelButton(layout.genValueWaterBtn.x, layout.genValueWaterBtn.y, layout.genValueWaterBtn.w, layout.genValueWaterBtn.h, false);
    fill(10);
    textAlign(CENTER, CENTER);
    text("Set to water", layout.genValueWaterBtn.x + layout.genValueWaterBtn.w / 2, layout.genValueWaterBtn.y + layout.genValueWaterBtn.h / 2);
    registerUiTooltip(layout.genValueWaterBtn, tooltipFor("biome_value_water"));
  }

  // Paint button
  drawBevelButton(layout.paintBtn.x, layout.paintBtn.y, layout.paintBtn.w, layout.paintBtn.h,
                  currentBiomePaintMode == ZonePaintMode.ZONE_PAINT);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Paint", layout.paintBtn.x + layout.paintBtn.w * 0.5f, layout.paintBtn.y + layout.paintBtn.h * 0.5f);
  registerUiTooltip(layout.paintBtn, tooltipFor("biome_paint"));

  // Fill button
  drawBevelButton(layout.fillBtn.x, layout.fillBtn.y, layout.fillBtn.w, layout.fillBtn.h,
                  currentBiomePaintMode == ZonePaintMode.ZONE_FILL);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Fill", layout.fillBtn.x + layout.fillBtn.w * 0.5f, layout.fillBtn.y + layout.fillBtn.h * 0.5f);
  registerUiTooltip(layout.fillBtn, tooltipFor("biome_fill"));

  // Add / Remove biome type buttons
  // "+" button
  drawBevelButton(layout.addBtn.x, layout.addBtn.y, layout.addBtn.w, layout.addBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("+", layout.addBtn.x + layout.addBtn.w * 0.5f, layout.addBtn.y + layout.addBtn.h * 0.5f);
  registerUiTooltip(layout.addBtn, tooltipFor("biome_add"));

  // "-" button (disabled if index 0 or only one type)
  boolean canRemove = (mapModel.biomeTypes != null &&
                       mapModel.biomeTypes.size() > 1 &&
                       activeBiomeIndex > 0);

  drawBevelButton(layout.removeBtn.x, layout.removeBtn.y, layout.removeBtn.w, layout.removeBtn.h, !canRemove);
  fill(10);
  textAlign(CENTER, CENTER);
  text("-", layout.removeBtn.x + layout.removeBtn.w * 0.5f, layout.removeBtn.y + layout.removeBtn.h * 0.5f);
  registerUiTooltip(layout.removeBtn, tooltipFor("biome_remove"));

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
    registerUiTooltip(sw, tooltipFor("biome_palette"));
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
    registerUiTooltip(nf, tooltipFor("biome_name"));
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
    registerUiTooltip(hue, tooltipFor("biome_hue"));
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
                   "right-click: pan",
                   "wheel: zoom.");
}

// ----- ZONES PANEL -----
class ZonesLayout {
  IntRect panel;
  int titleY;
  IntRect resetBtn;
  IntRect regenerateBtn;
  IntRect brushSlider;
  IntRect excludeWaterBtn;
  IntRect exclusiveBtn;
  IntRect fourColorBtn;
  IntRect listPanel;
}

class ZoneRowLayout {
  int index;
  IntRect selectRect;
  IntRect nameRect;
  IntRect hueSlider;
  IntRect colorRect;
}

class ZonesListLayout {
  IntRect panel;
  int titleY;
  IntRect deselectBtn;
  IntRect newBtn;
  ArrayList<ZoneRowLayout> rows = new ArrayList<ZoneRowLayout>();
  int rowsStartY;
  int rowsViewH;
  float contentH;
  IntRect scrollbar;
}

ZonesListLayout buildZonesListLayout() {
  ZonesListLayout l = new ZonesListLayout();
  int w = RIGHT_PANEL_W;
  int x = width - w - PANEL_PADDING;
  int y = panelTop();
  l.panel = new IntRect(x, y, w, height - y - PANEL_PADDING);
  l.titleY = y + PANEL_PADDING;
  int btnY = l.titleY + PANEL_TITLE_H + PANEL_SECTION_GAP;
  l.deselectBtn = new IntRect(x + PANEL_PADDING, btnY, 90, PANEL_BUTTON_H);
  l.newBtn = new IntRect(l.deselectBtn.x + l.deselectBtn.w + 8, btnY, 90, PANEL_BUTTON_H);
  return l;
}

void populateZonesRows(ZonesListLayout layout) {
  layout.rows.clear();
  if (mapModel == null || mapModel.zones == null) return;
  int labelX = layout.panel.x + PANEL_PADDING;
  int startY = layout.newBtn.y + layout.newBtn.h + PANEL_SECTION_GAP;
  int maxY = layout.panel.y + layout.panel.h - PANEL_SECTION_GAP;
  int viewH = max(0, maxY - startY);
  int rowH = 28;
  int rowGap = 6;
  int hueW = 90;
  int totalRows = mapModel.zones.size();
  int contentH = (totalRows > 0) ? totalRows * (rowH + rowGap) - rowGap : 0;
  layout.rowsStartY = startY;
  layout.rowsViewH = viewH;
  layout.contentH = contentH;
  layout.scrollbar = new IntRect(layout.panel.x + layout.panel.w - SCROLLBAR_W, startY, SCROLLBAR_W, viewH);
  zonesListScroll = clampScroll(zonesListScroll, contentH, viewH);
  int curY = startY - round(zonesListScroll);

  for (int i = 0; i < totalRows; i++) {
    if (curY > maxY) break;
    if (curY + rowH < startY) {
      curY += rowH + rowGap;
      continue;
    }
    ZoneRowLayout row = new ZoneRowLayout();
    row.index = i;
    int selectW = 18;
    row.selectRect = new IntRect(labelX, curY, selectW, rowH);
    row.nameRect = new IntRect(labelX + selectW + 6, curY, layout.panel.w - 2 * PANEL_PADDING - SCROLLBAR_W - selectW - 6 - hueW - 8, rowH);
    int colorH = 6;
    row.colorRect = new IntRect(row.nameRect.x, row.nameRect.y + row.nameRect.h - colorH - 2, row.nameRect.w, colorH);
    row.hueSlider = new IntRect(row.nameRect.x + row.nameRect.w + 6, curY + (rowH - PANEL_SLIDER_H) / 2, hueW, PANEL_SLIDER_H);
    layout.rows.add(row);
    curY += rowH + rowGap;
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
  registerUiTooltip(layout.newBtn, tooltipFor("zones_list_new"));

  drawBevelButton(layout.deselectBtn.x, layout.deselectBtn.y, layout.deselectBtn.w, layout.deselectBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Deselect", layout.deselectBtn.x + layout.deselectBtn.w / 2, layout.deselectBtn.y + layout.deselectBtn.h / 2);
  registerUiTooltip(layout.deselectBtn, tooltipFor("structures_deselect"));
  registerUiTooltip(layout.deselectBtn, tooltipFor("zones_list_deselect"));

  if (mapModel == null || mapModel.zones == null) return;

  for (int i = 0; i < layout.rows.size(); i++) {
    ZoneRowLayout row = layout.rows.get(i);
    if (row.index < 0 || row.index >= mapModel.zones.size()) continue;
    MapModel.MapZone az = mapModel.zones.get(row.index);
    boolean selected = (activeZoneIndex == row.index);

    drawRadioButton(row.selectRect, selected);

    boolean editing = (editingZoneNameIndex == row.index);
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
      stroke(80);
      fill(az.col);
      rect(row.nameRect.x, row.nameRect.y, row.nameRect.w, row.nameRect.h, 4);
      float br = brightness(az.col);
      int txtCol = (br > 60) ? color(15) : color(245);
      fill(txtCol);
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

  drawScrollbar(layout.scrollbar, layout.contentH, zonesListScroll);
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

  l.excludeWaterBtn = new IntRect(innerX, curY, 110, PANEL_BUTTON_H);
  l.exclusiveBtn = new IntRect(l.excludeWaterBtn.x + l.excludeWaterBtn.w + 8, curY, 140, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_ROW_GAP;
  l.fourColorBtn = new IntRect(innerX, curY, 150, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_SECTION_GAP;

  // Right-side list panel reserved space
  l.listPanel = new IntRect(width - RIGHT_PANEL_W - PANEL_PADDING, panelTop(), RIGHT_PANEL_W, height - panelTop() - PANEL_PADDING);

  curY += hintHeight(3);
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
  // Use explicit rectMode(CORNER) to avoid bleed from world draw state
  rectMode(CORNER);
  drawBevelButton(layout.resetBtn.x, layout.resetBtn.y, layout.resetBtn.w, layout.resetBtn.h, false);
  drawBevelButton(layout.regenerateBtn.x, layout.regenerateBtn.y, layout.regenerateBtn.w, layout.regenerateBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Reset", layout.resetBtn.x + layout.resetBtn.w * 0.5f, layout.resetBtn.y + layout.resetBtn.h * 0.5f);
  text("Regenerate", layout.regenerateBtn.x + layout.regenerateBtn.w * 0.5f, layout.regenerateBtn.y + layout.regenerateBtn.h * 0.5f);
  registerUiTooltip(layout.resetBtn, tooltipFor("zones_reset"));
  registerUiTooltip(layout.regenerateBtn, tooltipFor("zones_regenerate"));

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
  registerUiTooltip(brush, tooltipFor("zones_brush"));

  drawControlsHint(layout.panel,
                   "left-click: paint or erase",
                   "right-click pan",
                   "wheel: zoom");

  // Zone helper buttons
  if (layout.excludeWaterBtn != null) {
    drawBevelButton(layout.excludeWaterBtn.x, layout.excludeWaterBtn.y, layout.excludeWaterBtn.w, layout.excludeWaterBtn.h, false);
    fill(10);
    textAlign(CENTER, CENTER);
    text("Exclude water", layout.excludeWaterBtn.x + layout.excludeWaterBtn.w / 2, layout.excludeWaterBtn.y + layout.excludeWaterBtn.h / 2);
    registerUiTooltip(layout.excludeWaterBtn, tooltipFor("zones_exclude_water"));
  }
  if (layout.exclusiveBtn != null) {
    drawBevelButton(layout.exclusiveBtn.x, layout.exclusiveBtn.y, layout.exclusiveBtn.w, layout.exclusiveBtn.h, false);
    fill(10);
    textAlign(CENTER, CENTER);
    text("Make exclusive", layout.exclusiveBtn.x + layout.exclusiveBtn.w / 2, layout.exclusiveBtn.y + layout.exclusiveBtn.h / 2);
    registerUiTooltip(layout.exclusiveBtn, tooltipFor("zones_exclusive"));
  }
  if (layout.fourColorBtn != null) {
    drawBevelButton(layout.fourColorBtn.x, layout.fourColorBtn.y, layout.fourColorBtn.w, layout.fourColorBtn.h, false);
    fill(10);
    textAlign(CENTER, CENTER);
    text("Four-color map", layout.fourColorBtn.x + layout.fourColorBtn.w / 2, layout.fourColorBtn.y + layout.fourColorBtn.h / 2);
    registerUiTooltip(layout.fourColorBtn, tooltipFor("zones_four_color"));
  }
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
  IntRect eraserBtn;
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
  int rowsStartY;
  int rowsViewH;
  float contentH;
  IntRect scrollbar;
}

class PathRowLayout {
  int index;
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

  int sliderW = 200;
  l.routeSlider = new IntRect(innerX, curY + PANEL_LABEL_H, sliderW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;

  l.flattestSlider = new IntRect(innerX, curY + PANEL_LABEL_H, sliderW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;

  l.avoidWaterCheck = new IntRect(innerX, curY, PANEL_CHECK_SIZE, PANEL_CHECK_SIZE);
  curY += PANEL_CHECK_SIZE + PANEL_ROW_GAP;

  l.eraserBtn = new IntRect(innerX, curY, 90, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_SECTION_GAP;

  curY += hintHeight(5);
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
  int startY = layout.newBtn.y + layout.newBtn.h + PANEL_SECTION_GAP;
  int maxY = layout.panel.y + layout.panel.h - PANEL_SECTION_GAP;
  int viewH = max(0, maxY - startY);

  int textH = ceil(textAscent() + textDescent());
  int nameH = max(PANEL_LABEL_H + 6, textH + 8);
  int typeH = max(PANEL_LABEL_H + 2, textH + 6);
  int statsH = max(PANEL_LABEL_H, textH);
  int rowGap = 10;
  int rowTotal = nameH + 6 + typeH + 4 + statsH + rowGap;
  int totalRows = (mapModel != null && mapModel.paths != null) ? mapModel.paths.size() : 0;
  int contentH = (totalRows > 0) ? totalRows * rowTotal : 0;

  layout.rowsStartY = startY;
  layout.rowsViewH = viewH;
  layout.contentH = contentH;
  layout.scrollbar = new IntRect(layout.panel.x + layout.panel.w - SCROLLBAR_W, startY, SCROLLBAR_W, viewH);
  pathsListScroll = clampScroll(pathsListScroll, contentH, viewH);

  int curY = startY - round(pathsListScroll);

  for (int i = 0; i < totalRows; i++) {
    if (curY > maxY) break;
    if (curY + rowTotal < startY) {
      curY += rowTotal;
      continue;
    }

    int selectSize = max(16, nameH - 2);
    PathRowLayout row = new PathRowLayout();
    row.index = i;
    row.selectRect = new IntRect(labelX, curY, selectSize, selectSize);
    row.nameRect = new IntRect(row.selectRect.x + row.selectRect.w + 6, curY,
                               layout.panel.w - 2 * PANEL_PADDING - SCROLLBAR_W - row.selectRect.w - 6 - 40,
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
  registerUiTooltip(rs, tooltipFor("paths_route_mode"));

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
  registerUiTooltip(fs, tooltipFor("paths_flattest"));

  // Avoid water checkbox
  drawCheckbox(layout.avoidWaterCheck.x, layout.avoidWaterCheck.y,
               layout.avoidWaterCheck.w, pathAvoidWater, "Avoid water");
  registerUiTooltip(layout.avoidWaterCheck, tooltipFor("paths_avoid_water"));
  drawBevelButton(layout.eraserBtn.x, layout.eraserBtn.y, layout.eraserBtn.w, layout.eraserBtn.h, pathEraserMode);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Eraser", layout.eraserBtn.x + layout.eraserBtn.w / 2, layout.eraserBtn.y + layout.eraserBtn.h / 2);
  registerUiTooltip(layout.eraserBtn, tooltipFor("paths_eraser"));

  // Only type management on this panel

  // Path types add/remove
  drawBevelButton(layout.typeAddBtn.x, layout.typeAddBtn.y, layout.typeAddBtn.w, layout.typeAddBtn.h, false);
  drawBevelButton(layout.typeRemoveBtn.x, layout.typeRemoveBtn.y, layout.typeRemoveBtn.w, layout.typeRemoveBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("+", layout.typeAddBtn.x + layout.typeAddBtn.w / 2, layout.typeAddBtn.y + layout.typeAddBtn.h / 2);
  text("-", layout.typeRemoveBtn.x + layout.typeRemoveBtn.w / 2, layout.typeRemoveBtn.y + layout.typeRemoveBtn.h / 2);
  registerUiTooltip(layout.typeAddBtn, tooltipFor("paths_type_add"));
  registerUiTooltip(layout.typeRemoveBtn, tooltipFor("paths_type_remove"));

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
    registerUiTooltip(sw, tooltipFor("paths_palette"));
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
    registerUiTooltip(nf, tooltipFor("paths_type_name"));

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
    registerUiTooltip(weight, tooltipFor("paths_type_weight"));

  // Min weight slider per type
  IntRect minw = layout.typeMinWeightSlider;
  stroke(160);
  fill(230);
  rect(minw.x, minw.y, minw.w, minw.h, 4);
    float minNorm;
    if (abs(active.weightPx - 0.5f) < 1e-6f) {
      minNorm = 0; // avoid map() divide-by-zero when range collapses
    } else {
      minNorm = constrain(map(active.minWeightPx, 0.5f, active.weightPx, 0, 1), 0, 1);
    }
    float minx = minw.x + minNorm * minw.w;
    fill(40);
    noStroke();
    ellipse(minx, minw.y + minw.h / 2.0f, minw.h * 0.9f, minw.h * 0.9f);
    fill(0);
    text("Min weight (px)", minw.x, minw.y - 4);
    registerUiTooltip(minw, tooltipFor("paths_min_weight"));

  // Taper toggle per type
  drawCheckbox(layout.taperCheck.x, layout.taperCheck.y,
               layout.taperCheck.w, active.taperOn, "Taper water");
  registerUiTooltip(layout.taperCheck, tooltipFor("paths_taper"));
  }

  drawControlsHint(layout.panel,
                   "left-click: start/end",
                   "DEL: cancels",
                   "right-click: pan",
                   "wheel: zoom",
                   "C: clear");
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
    PathRowLayout row = layout.rows.get(i);
    if (row.index < 0 || row.index >= mapModel.paths.size()) continue;
    Path p = mapModel.paths.get(row.index);

    boolean selected = (selectedPathIndex == row.index);
    drawRadioButton(row.selectRect, selected);

      boolean editing = (editingPathNameIndex == row.index);
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
        text("#" + (row.index + 1) + " " + title, row.nameRect.x + 6, row.nameRect.y + row.nameRect.h / 2);
      }

      drawBevelButton(row.delRect.x, row.delRect.y, row.delRect.w, row.delRect.h, false);
      fill(10);
      textAlign(CENTER, CENTER);
      text("X", row.delRect.x + row.delRect.w / 2, row.delRect.y + row.delRect.h / 2);

      PathType pt = mapModel.getPathType(p.typeId);
      String typLabel = (pt != null ? pt.name : "Type");
      int typeCol = (pt != null) ? pt.col : color(180);
      stroke(80);
      fill(typeCol);
      rect(row.typeRect.x, row.typeRect.y, row.typeRect.w, row.typeRect.h, 4);
      fill(255);
      textAlign(CENTER, CENTER);
      text(typLabel, row.typeRect.x + row.typeRect.w * 0.5f, row.typeRect.y + row.typeRect.h * 0.5f);

      int segs = p.segmentCount();
      float len = p.totalLength();
      fill(40);
      textAlign(LEFT, CENTER);
      text("Segments: " + segs + "   Len: " + nf(len, 1, 3),
           labelX + row.selectRect.w + 6, row.statsY + row.statsH / 2);
    }
  }

  drawScrollbar(layout.scrollbar, layout.contentH, pathsListScroll);

  drawBevelButton(layout.newBtn.x, layout.newBtn.y, layout.newBtn.w, layout.newBtn.h, false);
  drawBevelButton(layout.deselectBtn.x, layout.deselectBtn.y, layout.deselectBtn.w, layout.deselectBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("New Path", layout.newBtn.x + layout.newBtn.w / 2, layout.newBtn.y + layout.newBtn.h / 2);
  text("Deselect", layout.deselectBtn.x + layout.deselectBtn.w / 2, layout.deselectBtn.y + layout.deselectBtn.h / 2);
  registerUiTooltip(layout.newBtn, tooltipFor("paths_list_new"));
  registerUiTooltip(layout.deselectBtn, tooltipFor("paths_list_deselect"));
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
  IntRect plateauBtn;
}

ElevationLayout buildElevationLayout() {
  ElevationLayout l = new ElevationLayout();
  l.panel = new IntRect(PANEL_X, panelTop(), PANEL_W, 0);
  int innerX = l.panel.x + PANEL_PADDING;
  int curY = l.panel.y + PANEL_PADDING;
  l.titleY = curY;
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;

  int genW = 120;
  l.perlinBtn = new IntRect(innerX, curY, genW, PANEL_BUTTON_H);
  l.varyBtn = new IntRect(l.perlinBtn.x + genW + 8, curY, genW, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_ROW_GAP;
  l.plateauBtn = new IntRect(innerX, curY, genW, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_SECTION_GAP;

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
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_PADDING;

  curY += hintHeight(3);
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
  float seaNorm = constrain(map(seaLevel, -1.2f, 1.2f, 0, 1), 0, 1);
  drawSlider(sea, seaNorm, "Water level: " + nf(seaLevel, 1, 2), true);
  registerUiTooltip(sea, tooltipFor("elevation_water_level"));

  // Brush radius slider (0.01..0.2)
  IntRect rad = layout.radiusSlider;
  float rNorm = constrain(map(elevationBrushRadius, 0.01f, 0.2f, 0, 1), 0, 1);
  drawSlider(rad, rNorm, "Brush radius");
  registerUiTooltip(rad, tooltipFor("elevation_brush_radius"));

  // Brush strength slider (0.005..0.2)
  IntRect str = layout.strengthSlider;
  float sNorm = constrain(map(elevationBrushStrength, 0.005f, 0.2f, 0, 1), 0, 1);
  drawSlider(str, sNorm, "Brush strength");
  registerUiTooltip(str, tooltipFor("elevation_brush_strength"));

  // Raise / Lower buttons
  drawBevelButton(layout.raiseBtn.x, layout.raiseBtn.y, layout.raiseBtn.w, layout.raiseBtn.h, elevationBrushRaise);
  drawBevelButton(layout.lowerBtn.x, layout.lowerBtn.y, layout.lowerBtn.w, layout.lowerBtn.h, !elevationBrushRaise);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Raise", layout.raiseBtn.x + layout.raiseBtn.w / 2, layout.raiseBtn.y + layout.raiseBtn.h / 2);
  text("Lower", layout.lowerBtn.x + layout.lowerBtn.w / 2, layout.lowerBtn.y + layout.lowerBtn.h / 2);
  registerUiTooltip(layout.raiseBtn, tooltipFor("elevation_raise"));
  registerUiTooltip(layout.lowerBtn, tooltipFor("elevation_lower"));

  // Noise controls stacked
  IntRect noise = layout.noiseSlider;
  stroke(160);
  fill(230);
  rect(noise.x, noise.y, noise.w, noise.h, 4);
  float nNorm = constrain(map(elevationNoiseScale, 1.0f, 12.0f, 0, 1), 0, 1);
  drawSlider(noise, nNorm, "Noise scale");
  registerUiTooltip(noise, tooltipFor("elevation_noise"));

  drawBevelButton(layout.perlinBtn.x, layout.perlinBtn.y, layout.perlinBtn.w, layout.perlinBtn.h, false);
  drawBevelButton(layout.varyBtn.x, layout.varyBtn.y, layout.varyBtn.w, layout.varyBtn.h, false);
  drawBevelButton(layout.plateauBtn.x, layout.plateauBtn.y, layout.plateauBtn.w, layout.plateauBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Generate", layout.perlinBtn.x + layout.perlinBtn.w / 2, layout.perlinBtn.y + layout.perlinBtn.h / 2);
  text("Vary", layout.varyBtn.x + layout.varyBtn.w / 2, layout.varyBtn.y + layout.varyBtn.h / 2);
  text("Make plateaux", layout.plateauBtn.x + layout.plateauBtn.w / 2, layout.plateauBtn.y + layout.plateauBtn.h / 2);
  registerUiTooltip(layout.perlinBtn, tooltipFor("elevation_generate_perlin"));
  registerUiTooltip(layout.varyBtn, tooltipFor("elevation_vary"));
  registerUiTooltip(layout.plateauBtn, tooltipFor("elevation_plateau"));

  drawControlsHint(layout.panel,
                   "left-click: raise/lower",
                   "right-click: pan",
                   "wheel: zoom");
}

// ----- LABELS PANEL -----
class LabelsLayout {
  IntRect panel;
  int titleY;
}

class LabelsListLayout {
  IntRect panel;
  int titleY;
  IntRect deselectBtn;
  IntRect sizeSlider;
  ArrayList<LabelRowLayout> rows = new ArrayList<LabelRowLayout>();
  int rowsStartY;
  int rowsViewH;
  float contentH;
  IntRect scrollbar;
}

class LabelRowLayout {
  int index;
  IntRect selectRect;
  IntRect nameRect;
  IntRect delRect;
}

LabelsLayout buildLabelsLayout() {
  LabelsLayout l = new LabelsLayout();
  l.panel = new IntRect(PANEL_X, panelTop(), PANEL_W, 0);
  int curY = l.panel.y + PANEL_PADDING;
  l.titleY = curY;
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;
  curY += hintHeight(3);
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

  drawControlsHint(layout.panel,
                   "left-click: place",
                   "right-click pan",
                   "wheel: zoom");
}

LabelsListLayout buildLabelsListLayout() {
  LabelsListLayout l = new LabelsListLayout();
  int w = RIGHT_PANEL_W;
  int x = width - w - PANEL_PADDING;
  int y = panelTop();
  l.panel = new IntRect(x, y, w, height - y - PANEL_PADDING);
  l.titleY = y + PANEL_PADDING;
  int btnY = l.titleY + PANEL_TITLE_H + PANEL_SECTION_GAP;
  l.deselectBtn = new IntRect(x + PANEL_PADDING, btnY, 90, PANEL_BUTTON_H);
  l.sizeSlider = new IntRect(l.deselectBtn.x + l.deselectBtn.w + 10, btnY + 4, 140, PANEL_SLIDER_H);
  return l;
}

void populateLabelsListRows(LabelsListLayout layout) {
  layout.rows.clear();
  int labelX = layout.panel.x + PANEL_PADDING;
  int startY = layout.deselectBtn.y + layout.deselectBtn.h + PANEL_SECTION_GAP + 6;
  int maxY = layout.panel.y + layout.panel.h - PANEL_SECTION_GAP;
  int viewH = max(0, maxY - startY);
  int rowH = 24;
  int rowGap = 6;
  int totalRows = (mapModel != null && mapModel.labels != null) ? mapModel.labels.size() : 0;
  int contentH = (totalRows > 0) ? totalRows * (rowH + rowGap) - rowGap : 0;
  layout.rowsStartY = startY;
  layout.rowsViewH = viewH;
  layout.contentH = contentH;
  layout.scrollbar = new IntRect(layout.panel.x + layout.panel.w - SCROLLBAR_W, startY, SCROLLBAR_W, viewH);
  labelsListScroll = clampScroll(labelsListScroll, contentH, viewH);
  int curY = startY - round(labelsListScroll);

  for (int i = 0; i < totalRows; i++) {
    if (curY > maxY) break;
    if (curY + rowH < startY) {
      curY += rowH + rowGap;
      continue;
    }
    LabelRowLayout row = new LabelRowLayout();
    row.index = i;
    int selectW = 18;
    row.selectRect = new IntRect(labelX, curY, selectW, rowH);
    row.nameRect = new IntRect(labelX + selectW + 6, curY, layout.panel.w - 2 * PANEL_PADDING - SCROLLBAR_W - selectW - 6 - 30, rowH);
    row.delRect = new IntRect(row.nameRect.x + row.nameRect.w + 4, curY, 24, rowH);
    layout.rows.add(row);
    curY += rowH + rowGap;
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

  drawBevelButton(layout.deselectBtn.x, layout.deselectBtn.y, layout.deselectBtn.w, layout.deselectBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Deselect", layout.deselectBtn.x + layout.deselectBtn.w / 2, layout.deselectBtn.y + layout.deselectBtn.h / 2);
  registerUiTooltip(layout.deselectBtn, tooltipFor("labels_deselect"));

  // Size slider
  IntRect ss = layout.sizeSlider;
  stroke(160);
  fill(230);
  rect(ss.x, ss.y, ss.w, ss.h, 4);
  float sizeNorm = map(labelSizeDefault(), 8, 40, 0, 1);
  sizeNorm = constrain(sizeNorm, 0, 1);
  float sx = ss.x + sizeNorm * ss.w;
  fill(40);
  noStroke();
  ellipse(sx, ss.y + ss.h / 2.0f, ss.h * 0.9f, ss.h * 0.9f);
  fill(10);
  textAlign(LEFT, BOTTOM);
  text("Size " + nf(labelSizeDefault(), 1, 0), ss.x, ss.y - 4);
  registerUiTooltip(ss, tooltipFor("labels_size"));
  curY = ss.y + ss.h + PANEL_SECTION_GAP;

  for (int i = 0; i < layout.rows.size(); i++) {
    LabelRowLayout row = layout.rows.get(i);
    if (row.index < 0 || row.index >= mapModel.labels.size()) continue;
    MapLabel lbl = mapModel.labels.get(row.index);
    boolean selected = (selectedLabelIndex == row.index);
    drawRadioButton(row.selectRect, selected);

    boolean editing = (editingLabelIndex == row.index);
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

    drawBevelButton(row.delRect.x, row.delRect.y, row.delRect.w, row.delRect.h, false);
    fill(10);
    textAlign(CENTER, CENTER);
    text("X", row.delRect.x + row.delRect.w / 2, row.delRect.y + row.delRect.h / 2);
  }

  drawScrollbar(layout.scrollbar, layout.contentH, labelsListScroll);
}

String labelTargetShort(LabelTarget lt) {
  switch (lt) {
    case BIOME: return "B";
    case ZONE: return "Z";
    case STRUCTURE: return "S";
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
  int yTop = snapPanelTop() + snapSettingsPanelHeight(); // leave space for snap settings block
  l.panel = new IntRect(PANEL_X, yTop, PANEL_W, 0);
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
    int row = i / 3;
    int col = i % 3;
    int x = innerX + col * (btnWShape + gapShape);
    int y = curY + row * (PANEL_BUTTON_H + PANEL_ROW_GAP);
    l.shapeButtons.add(new IntRect(x, y, btnWShape, PANEL_BUTTON_H));
  }
  curY += (PANEL_BUTTON_H + PANEL_ROW_GAP) * 2; // two rows of shape buttons
  curY += PANEL_PADDING - PANEL_ROW_GAP;

  String[] snapModes = { "None", "Next", "Center" };
  int btnW = 70;
  int gap = 6;
  for (int i = 0; i < snapModes.length; i++) {
    l.snapButtons.add(new IntRect(innerX + i * (btnW + gap), curY, btnW, PANEL_BUTTON_H));
  }
  curY += PANEL_BUTTON_H + PANEL_PADDING;

  curY += hintHeight(3);
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
  registerUiTooltip(sz, tooltipFor("structures_size"));

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
  registerUiTooltip(ang, tooltipFor("structures_angle"));

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
  registerUiTooltip(ratio, tooltipFor("structures_ratio"));

  // Shape buttons
  String[] shapeLabels = { "Rect", "Square", "Circle", "Triangle", "Hex" };
  for (int i = 0; i < layout.shapeButtons.size(); i++) {
    IntRect b = layout.shapeButtons.get(i);
    boolean active = (structureShape == StructureShape.values()[i]);
    drawBevelButton(b.x, b.y, b.w, b.h, active);
    fill(10);
    textAlign(CENTER, CENTER);
    text(shapeLabels[i], b.x + b.w / 2, b.y + b.h / 2);
    registerUiTooltip(b, tooltipFor("structures_shape"));
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
    registerUiTooltip(b, tooltipFor("structures_snap_mode"));
  }

  drawControlsHint(layout.panel,
                   "left-click: place",
                   "right-click: pan",
                   "wheel: zoom");
}

// ----- STRUCTURES LIST (right panel) -----
class StructuresListLayout {
  IntRect panel;
  int titleY;
  IntRect deselectBtn;
  IntRect detailNameField;
  IntRect detailSizeSlider;
  IntRect detailAngleSlider;
  IntRect detailHueSlider;
  IntRect detailAlphaSlider;
  IntRect detailSatSlider;
  IntRect detailStrokeSlider;
  ArrayList<StructureRowLayout> rows = new ArrayList<StructureRowLayout>();
  int rowsStartY;
  int rowsViewH;
  float contentH;
  IntRect scrollbar;
}

class StructureRowLayout {
  int index;
  IntRect selectRect;
  IntRect nameRect;
  IntRect delRect;
}

StructuresListLayout buildStructuresListLayout() {
  StructuresListLayout l = new StructuresListLayout();
  int w = RIGHT_PANEL_W;
  int x = width - w - PANEL_PADDING;
  int y = snapPanelTop(); // keep right panel pinned to the top
  l.panel = new IntRect(x, y, w, height - y - PANEL_PADDING);
  l.titleY = y + PANEL_PADDING;
  int btnY = l.titleY + PANEL_TITLE_H + PANEL_SECTION_GAP;
  l.deselectBtn = new IntRect(x + PANEL_PADDING, btnY, 90, PANEL_BUTTON_H);
  return l;
}

int layoutStructureDetails(StructuresListLayout layout) {
  int labelX = layout.panel.x + PANEL_PADDING;
  int curY = layout.deselectBtn.y + layout.deselectBtn.h + PANEL_SECTION_GAP;
  int fullW = layout.panel.w - 2 * PANEL_PADDING;
  layout.detailNameField = new IntRect(labelX, curY + PANEL_LABEL_H, fullW, PANEL_BUTTON_H);
  curY += PANEL_LABEL_H + PANEL_BUTTON_H + PANEL_ROW_GAP;
  layout.detailSizeSlider = new IntRect(labelX, curY + PANEL_LABEL_H, fullW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;
  layout.detailAngleSlider = new IntRect(labelX, curY + PANEL_LABEL_H, fullW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;
  layout.detailHueSlider = new IntRect(labelX, curY + PANEL_LABEL_H, fullW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;
  layout.detailAlphaSlider = new IntRect(labelX, curY + PANEL_LABEL_H, fullW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;
  layout.detailSatSlider = new IntRect(labelX, curY + PANEL_LABEL_H, fullW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;
  layout.detailStrokeSlider = new IntRect(labelX, curY + PANEL_LABEL_H, fullW, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;
  return curY;
}

void populateStructuresListRows(StructuresListLayout layout, int startY) {
  layout.rows.clear();
  int labelX = layout.panel.x + PANEL_PADDING;
  int maxY = layout.panel.y + layout.panel.h - PANEL_SECTION_GAP;
  int viewH = max(0, maxY - startY);
  int curY = startY - round(structuresListScroll);
  int rowH = 24;
  int rowGap = 6;
  int totalRows = (mapModel != null && mapModel.structures != null) ? mapModel.structures.size() : 0;
  int contentH = (totalRows > 0) ? totalRows * (rowH + rowGap) - rowGap : 0;
  layout.rowsStartY = startY;
  layout.rowsViewH = viewH;
  layout.contentH = contentH;
  layout.scrollbar = new IntRect(layout.panel.x + layout.panel.w - SCROLLBAR_W, startY, SCROLLBAR_W, viewH);
  structuresListScroll = clampScroll(structuresListScroll, contentH, viewH);
  curY = startY - round(structuresListScroll);

  for (int i = 0; i < totalRows; i++) {
    if (curY > maxY) break;
    if (curY + rowH < startY) {
      curY += rowH + rowGap;
      continue;
    }
    StructureRowLayout row = new StructureRowLayout();
    row.index = i;
    int selectW = 18;
    row.selectRect = new IntRect(labelX, curY, selectW, rowH);
    row.nameRect = new IntRect(labelX + selectW + 6, curY, layout.panel.w - 2 * PANEL_PADDING - SCROLLBAR_W - selectW - 6 - 30, rowH);
    row.delRect = new IntRect(row.nameRect.x + row.nameRect.w + 6, curY, 24, rowH);
    layout.rows.add(row);
    curY += rowH + rowGap;
  }
}

void drawStructuresListPanel() {
  StructuresListLayout layout = buildStructuresListLayout();
  int listStartY = layoutStructureDetails(layout);
  populateStructuresListRows(layout, listStartY);
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

  Structure target = (selectedStructureIndex >= 0 && selectedStructureIndex < mapModel.structures.size()) ?
    mapModel.structures.get(selectedStructureIndex) : null;

  // Name field (selected struct only)
  {
    IntRect nf = layout.detailNameField;
    boolean editingName = (target != null && editingStructureNameIndex == selectedStructureIndex);
    fill(0);
    textAlign(LEFT, BOTTOM);
    text(target != null ? "Name" : "Next name", nf.x, nf.y - 4);
    stroke(80);
    fill(255);
    rect(nf.x, nf.y, nf.w, nf.h);
    fill(0);
    textAlign(LEFT, CENTER);
    String shownName;
    if (target != null) {
      shownName = editingName ? structureNameDraft : target.name;
    } else {
      shownName = "Struct " + (mapModel.structures.size() + 1);
    }
    text(shownName, nf.x + 6, nf.y + nf.h / 2);
    if (editingName) {
      float caretX = nf.x + 6 + textWidth(structureNameDraft);
      stroke(0);
      line(caretX, nf.y + 4, caretX, nf.y + nf.h - 4);
    }
    registerUiTooltip(nf, tooltipFor("structures_detail_name"));
  }

  float baseSize = (target != null) ? target.size : structureSize;
  float baseAngDeg = (target != null) ? degrees(target.angle) : degrees(structureAngleOffsetRad);
  float baseHue = (target != null) ? target.hue01 : structureHue01;
  float baseSat = (target != null) ? target.sat01 : structureSat01;
  float baseAlpha = (target != null) ? target.alpha01 : structureAlpha01;
  float baseStroke = (target != null) ? target.strokeWeightPx : structureStrokePx;

  // Size slider
  IntRect ss = layout.detailSizeSlider;
  stroke(160);
  fill(230);
  rect(ss.x, ss.y, ss.w, ss.h, 4);
  float sNorm = constrain(map(baseSize, 0.01f, 0.2f, 0, 1), 0, 1);
  float sx = ss.x + sNorm * ss.w;
  fill(40);
  noStroke();
  ellipse(sx, ss.y + ss.h / 2.0f, ss.h * 0.9f, ss.h * 0.9f);
  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Size", ss.x, ss.y - 4);
  registerUiTooltip(ss, tooltipFor("structures_detail_size"));

  // Angle slider
  IntRect ang = layout.detailAngleSlider;
  stroke(160);
  fill(230);
  rect(ang.x, ang.y, ang.w, ang.h, 4);
  float aNorm = constrain(map(baseAngDeg, -180.0f, 180.0f, 0, 1), 0, 1);
  float ax = ang.x + aNorm * ang.w;
  fill(40);
  noStroke();
  ellipse(ax, ang.y + ang.h / 2.0f, ang.h * 0.9f, ang.h * 0.9f);
  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Angle (" + nf(baseAngDeg, 1, 1) + " deg)", ang.x, ang.y - 4);
  registerUiTooltip(ang, tooltipFor("structures_detail_angle"));

  // Hue slider
  IntRect hue = layout.detailHueSlider;
  stroke(160);
  fill(230);
  rect(hue.x, hue.y, hue.w, hue.h, 4);
  float hNorm = constrain(baseHue, 0, 1);
  float hx = hue.x + hNorm * hue.w;
  fill(40);
  noStroke();
  ellipse(hx, hue.y + hue.h / 2.0f, hue.h * 0.9f, hue.h * 0.9f);
  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Hue", hue.x, hue.y - 4);
  registerUiTooltip(hue, tooltipFor("structures_detail_hue"));

  // Saturation slider
  IntRect sat = layout.detailSatSlider;
  stroke(160);
  fill(230);
  rect(sat.x, sat.y, sat.w, sat.h, 4);
  float satNorm = constrain(baseSat, 0, 1);
  float satx = sat.x + satNorm * sat.w;
  fill(40);
  noStroke();
  ellipse(satx, sat.y + sat.h / 2.0f, sat.h * 0.9f, sat.h * 0.9f);
  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Saturation", sat.x, sat.y - 4);
  registerUiTooltip(sat, tooltipFor("structures_detail_sat"));

  // Alpha slider (fill only)
  IntRect alp = layout.detailAlphaSlider;
  stroke(160);
  fill(230);
  rect(alp.x, alp.y, alp.w, alp.h, 4);
  float aNorm2 = constrain(baseAlpha, 0, 1);
  float apx = alp.x + aNorm2 * alp.w;
  fill(40);
  noStroke();
  ellipse(apx, alp.y + alp.h / 2.0f, alp.h * 0.9f, alp.h * 0.9f);
  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Alpha (" + nf(baseAlpha * 100.0f, 1, 0) + "%)", alp.x, alp.y - 4);
  registerUiTooltip(alp, tooltipFor("structures_detail_alpha"));

  // Stroke weight slider
  IntRect st = layout.detailStrokeSlider;
  stroke(160);
  fill(230);
  rect(st.x, st.y, st.w, st.h, 4);
  float stNorm = constrain(map(baseStroke, 0.5f, 4.0f, 0, 1), 0, 1);
  float stx = st.x + stNorm * st.w;
  fill(40);
  noStroke();
  ellipse(stx, st.y + st.h / 2.0f, st.h * 0.9f, st.h * 0.9f);
  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Stroke weight (px)", st.x, st.y - 4);
  registerUiTooltip(st, tooltipFor("structures_detail_stroke"));

  for (int i = 0; i < layout.rows.size(); i++) {
    StructureRowLayout row = layout.rows.get(i);
    Structure s = (row.index >= 0 && row.index < mapModel.structures.size()) ? mapModel.structures.get(row.index) : null;
    if (s == null) continue;
    boolean selected = (selectedStructureIndex == row.index);
    drawRadioButton(row.selectRect, selected);

    drawBevelButton(row.nameRect.x, row.nameRect.y, row.nameRect.w, row.nameRect.h, selected);
    fill(10);
    textAlign(LEFT, CENTER);
    String base = (s.name != null && s.name.length() > 0) ? s.name : "Struct " + (row.index + 1);
    text(base + " - " + structureShapeLabel(s.shape), row.nameRect.x + 6, row.nameRect.y + row.nameRect.h / 2);

    drawBevelButton(row.delRect.x, row.delRect.y, row.delRect.w, row.delRect.h, false);
    fill(10);
    textAlign(CENTER, CENTER);
    text("X", row.delRect.x + row.delRect.w / 2, row.delRect.y + row.delRect.h / 2);
  }

  drawScrollbar(layout.scrollbar, layout.contentH, structuresListScroll);
}

// ----- RENDER PANEL -----
class RenderLayout {
  IntRect panel;
  int titleY;
  IntRect headerBase;
  IntRect headerBiomes;
  IntRect headerShading;
  IntRect headerContours;
  IntRect headerPaths;
  IntRect headerZones;
  IntRect headerStructures;
  IntRect headerLabels;
  IntRect headerGeneral;

  IntRect[] landHSB = new IntRect[3];
  IntRect[] waterHSB = new IntRect[3];
  IntRect cellBordersAlphaSlider;

  IntRect biomeFillAlphaSlider;
  IntRect biomeSatSlider;
  ArrayList<IntRect> biomeFillTypeButtons = new ArrayList<IntRect>();
  IntRect biomeOutlineSizeSlider;
  IntRect biomeOutlineAlphaSlider;
  IntRect biomeUnderwaterCheckbox;

  IntRect waterDepthAlphaSlider;
  IntRect lightAlphaSlider;
  IntRect lightAzimuthSlider;
  IntRect lightAltitudeSlider;

  IntRect waterContourSizeSlider;
  IntRect waterRippleCountSlider;
  IntRect waterRippleDistanceSlider;
  IntRect[] waterContourHSB = new IntRect[3];
  IntRect waterContourAlphaSlider;
  IntRect elevationLinesCountSlider;
  IntRect elevationLineStyleSelector;
  IntRect elevationLinesAlphaSlider;

  IntRect pathsShowCheckbox;
  IntRect pathSatSlider;

  IntRect zoneAlphaSlider;
  IntRect zoneSatSlider;
  IntRect zoneBriSlider;

  IntRect structuresShowCheckbox;
  IntRect structuresMergeCheckbox;

  IntRect labelsArbitraryCheckbox;
  IntRect labelsZonesCheckbox;
  IntRect labelsPathsCheckbox;
  IntRect labelsStructuresCheckbox;
  IntRect labelsOutlineAlphaSlider;

  IntRect exportPaddingSlider;
  IntRect antialiasCheckbox;
  IntRect presetSelector;
  IntRect presetApplyBtn;
}

RenderLayout buildRenderLayout() {
  RenderLayout l = new RenderLayout();
  l.panel = new IntRect(PANEL_X, panelTop(), PANEL_W, 0);
  int innerX = l.panel.x + PANEL_PADDING;
  int curY = l.panel.y + PANEL_PADDING;
  l.titleY = curY;
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;

  int headerW = PANEL_W - 2 * PANEL_PADDING;
  int shortSliderW = 90;
  int longSliderW = 200;
  int hsbGap = 8;

  // ----- Base -----
  l.headerBase = new IntRect(innerX, curY, headerW, PANEL_TITLE_H);
  curY += PANEL_TITLE_H + PANEL_ROW_GAP;
  if (renderSectionBaseOpen) {
    int yHue = curY + PANEL_LABEL_H;
    l.landHSB[0] = new IntRect(innerX, yHue + PANEL_LABEL_H, shortSliderW, PANEL_SLIDER_H);
    l.landHSB[1] = new IntRect(innerX + (shortSliderW + hsbGap), yHue + PANEL_LABEL_H, shortSliderW, PANEL_SLIDER_H);
    l.landHSB[2] = new IntRect(innerX + 2 * (shortSliderW + hsbGap), yHue + PANEL_LABEL_H, shortSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H*2 + PANEL_SLIDER_H + PANEL_ROW_GAP;

    curY += PANEL_LABEL_H;
    int yWater = curY;
    l.waterHSB[0] = new IntRect(innerX, yWater + PANEL_LABEL_H, shortSliderW, PANEL_SLIDER_H);
    l.waterHSB[1] = new IntRect(innerX + (shortSliderW + hsbGap), yWater + PANEL_LABEL_H, shortSliderW, PANEL_SLIDER_H);
    l.waterHSB[2] = new IntRect(innerX + 2 * (shortSliderW + hsbGap), yWater + PANEL_LABEL_H, shortSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H*2 + PANEL_SLIDER_H + PANEL_ROW_GAP;

    l.cellBordersAlphaSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;
  }

  // ----- Biomes -----
  l.headerBiomes = new IntRect(innerX, curY, headerW, PANEL_TITLE_H);
  curY += PANEL_TITLE_H + PANEL_ROW_GAP;
  if (renderSectionBiomesOpen) {
    l.biomeFillAlphaSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

    l.biomeSatSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

    int btnW = 90;
    for (int i = 0; i < 2; i++) {
      l.biomeFillTypeButtons.add(new IntRect(innerX + i * (btnW + 8), curY, btnW, PANEL_BUTTON_H));
    }
    curY += PANEL_BUTTON_H + PANEL_ROW_GAP;

    l.biomeOutlineSizeSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

    l.biomeOutlineAlphaSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

    l.biomeUnderwaterCheckbox = new IntRect(innerX, curY, PANEL_CHECK_SIZE, PANEL_CHECK_SIZE);
    curY += PANEL_CHECK_SIZE + PANEL_SECTION_GAP;
  }

  // ----- Shading -----
  l.headerShading = new IntRect(innerX, curY, headerW, PANEL_TITLE_H);
  curY += PANEL_TITLE_H + PANEL_ROW_GAP;
  if (renderSectionShadingOpen) {
    l.waterDepthAlphaSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

    l.lightAlphaSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

    l.lightAzimuthSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

    l.lightAltitudeSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;
  }

  // ----- Contours -----
  l.headerContours = new IntRect(innerX, curY, headerW, PANEL_TITLE_H);
  curY += PANEL_TITLE_H + PANEL_ROW_GAP;
  if (renderSectionContoursOpen) {
    l.waterContourSizeSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

    l.waterRippleCountSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

    l.waterRippleDistanceSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

    int yColor = curY+PANEL_LABEL_H;
    l.waterContourHSB[0] = new IntRect(innerX, yColor + PANEL_LABEL_H, shortSliderW, PANEL_SLIDER_H);
    l.waterContourHSB[1] = new IntRect(innerX + (shortSliderW + hsbGap), yColor + PANEL_LABEL_H, shortSliderW, PANEL_SLIDER_H);
    l.waterContourHSB[2] = new IntRect(innerX + 2 * (shortSliderW + hsbGap), yColor + PANEL_LABEL_H, shortSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H*2 + PANEL_SLIDER_H + PANEL_ROW_GAP;

    l.waterContourAlphaSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

    l.elevationLinesCountSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

    l.elevationLineStyleSelector = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;

    l.elevationLinesAlphaSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;
  }

  // ----- Paths -----
  l.headerPaths = new IntRect(innerX, curY, headerW, PANEL_TITLE_H);
  curY += PANEL_TITLE_H + PANEL_ROW_GAP;
  if (renderSectionPathsOpen) {
    l.pathsShowCheckbox = new IntRect(innerX, curY, PANEL_CHECK_SIZE, PANEL_CHECK_SIZE);
    curY += PANEL_CHECK_SIZE + PANEL_ROW_GAP;
    l.pathSatSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;
  }

  // ----- Zones -----
  l.headerZones = new IntRect(innerX, curY, headerW, PANEL_TITLE_H);
  curY += PANEL_TITLE_H + PANEL_ROW_GAP;
  if (renderSectionZonesOpen) {
    l.zoneAlphaSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;
    l.zoneSatSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;
    l.zoneBriSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;
  }

  // ----- Structures -----
  l.headerStructures = new IntRect(innerX, curY, headerW, PANEL_TITLE_H);
  curY += PANEL_TITLE_H + PANEL_ROW_GAP;
  if (renderSectionStructuresOpen) {
    l.structuresShowCheckbox = new IntRect(innerX, curY, PANEL_CHECK_SIZE, PANEL_CHECK_SIZE);
    curY += PANEL_CHECK_SIZE + PANEL_ROW_GAP;
    l.structuresMergeCheckbox = new IntRect(innerX, curY, PANEL_CHECK_SIZE, PANEL_CHECK_SIZE);
    curY += PANEL_CHECK_SIZE + PANEL_SECTION_GAP;
  }

  // ----- Labels -----
  l.headerLabels = new IntRect(innerX, curY, headerW, PANEL_TITLE_H);
  curY += PANEL_TITLE_H + PANEL_ROW_GAP;
  if (renderSectionLabelsOpen) {
    l.labelsArbitraryCheckbox = new IntRect(innerX, curY, PANEL_CHECK_SIZE, PANEL_CHECK_SIZE);
    curY += PANEL_CHECK_SIZE + PANEL_ROW_GAP;
    l.labelsZonesCheckbox = new IntRect(innerX, curY, PANEL_CHECK_SIZE, PANEL_CHECK_SIZE);
    curY += PANEL_CHECK_SIZE + PANEL_ROW_GAP;
    l.labelsPathsCheckbox = new IntRect(innerX, curY, PANEL_CHECK_SIZE, PANEL_CHECK_SIZE);
    curY += PANEL_CHECK_SIZE + PANEL_ROW_GAP;
    l.labelsStructuresCheckbox = new IntRect(innerX, curY, PANEL_CHECK_SIZE, PANEL_CHECK_SIZE);
    curY += PANEL_CHECK_SIZE + PANEL_ROW_GAP;
    l.labelsOutlineAlphaSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;
  }

  // ----- General -----
  l.headerGeneral = new IntRect(innerX, curY, headerW, PANEL_TITLE_H);
  curY += PANEL_TITLE_H + PANEL_ROW_GAP;
  if (renderSectionGeneralOpen) {
    l.exportPaddingSlider = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;
    l.antialiasCheckbox = new IntRect(innerX, curY, PANEL_CHECK_SIZE, PANEL_CHECK_SIZE);
    curY += PANEL_CHECK_SIZE + PANEL_ROW_GAP;
    l.presetSelector = new IntRect(innerX, curY + PANEL_LABEL_H, longSliderW, PANEL_SLIDER_H);
    curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_ROW_GAP;
    l.presetApplyBtn = new IntRect(innerX, curY, 110, PANEL_BUTTON_H);
    curY += PANEL_BUTTON_H + PANEL_SECTION_GAP;
  }

  curY += PANEL_PADDING + hintHeight(2);
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
  textAlign(LEFT, CENTER);
  drawControlsHint(layout.panel, "right-click: pan", "wheel: zoom");

  drawSectionHeader(layout.headerBase, "Base", renderSectionBaseOpen);
  if (renderSectionBaseOpen) {
    drawHSBRow(layout.landHSB, "Land base", renderSettings.landHue01, renderSettings.landSat01, renderSettings.landBri01);
    drawHSBRow(layout.waterHSB, "Water base", renderSettings.waterHue01, renderSettings.waterSat01, renderSettings.waterBri01);
    drawSlider(layout.cellBordersAlphaSlider, renderSettings.cellBorderAlpha01, "Cell borders alpha (" + nf(renderSettings.cellBorderAlpha01 * 100, 1, 0) + "%)");
  }

  drawSectionHeader(layout.headerBiomes, "Biomes", renderSectionBiomesOpen);
  if (renderSectionBiomesOpen) {
    drawSlider(layout.biomeFillAlphaSlider, renderSettings.biomeFillAlpha01, "Biomes fill alpha (" + nf(renderSettings.biomeFillAlpha01 * 100, 1, 0) + "%)");
    drawSlider(layout.biomeSatSlider, renderSettings.biomeSatScale01, "Biomes saturation (" + nf(renderSettings.biomeSatScale01 * 100, 1, 0) + "%)");
    String[] fillLabels = { "Color", "Pattern" };
    for (int i = 0; i < layout.biomeFillTypeButtons.size(); i++) {
      IntRect b = layout.biomeFillTypeButtons.get(i);
      boolean active = (renderSettings.biomeFillType == ((i == 0) ? RenderFillType.RENDER_FILL_COLOR : RenderFillType.RENDER_FILL_PATTERN));
      drawBevelButton(b.x, b.y, b.w, b.h, active);
      fill(10);
      textAlign(CENTER, CENTER);
      text(fillLabels[i], b.x + b.w / 2, b.y + b.h / 2);
    }
    drawSlider(layout.biomeOutlineSizeSlider, constrain(renderSettings.biomeOutlineSizePx / 5.0f, 0, 1), "Biomes outlines size (" + nf(renderSettings.biomeOutlineSizePx, 1, 1) + " px)");
    drawSlider(layout.biomeOutlineAlphaSlider, renderSettings.biomeOutlineAlpha01, "Biomes outlines alpha (" + nf(renderSettings.biomeOutlineAlpha01 * 100, 1, 0) + "%)");
    drawCheckbox(layout.biomeUnderwaterCheckbox.x, layout.biomeUnderwaterCheckbox.y, layout.biomeUnderwaterCheckbox.w, renderSettings.biomeShowUnderwater, "Show underwater biomes");
  }

  drawSectionHeader(layout.headerShading, "Shading", renderSectionShadingOpen);
  if (renderSectionShadingOpen) {
    drawSlider(layout.waterDepthAlphaSlider, renderSettings.waterDepthAlpha01, "Water depth alpha (" + nf(renderSettings.waterDepthAlpha01 * 100, 1, 0) + "%)");
    drawSlider(layout.lightAlphaSlider, renderSettings.elevationLightAlpha01, "Elevation light alpha (" + nf(renderSettings.elevationLightAlpha01 * 100, 1, 0) + "%)");
    float tAz = constrain(renderSettings.elevationLightAzimuthDeg / 360.0f, 0, 1);
    drawSlider(layout.lightAzimuthSlider, tAz, "Light azimuth (" + nf(renderSettings.elevationLightAzimuthDeg, 1, 0) + " deg)");
    float tAlt = constrain(map(renderSettings.elevationLightAltitudeDeg, 5.0f, 80.0f, 0, 1), 0, 1);
    drawSlider(layout.lightAltitudeSlider, tAlt, "Light altitude (" + nf(renderSettings.elevationLightAltitudeDeg, 1, 0) + " deg)");
  }

  drawSectionHeader(layout.headerContours, "Contours", renderSectionContoursOpen);
  if (renderSectionContoursOpen) {
    drawSlider(layout.waterContourSizeSlider, constrain(renderSettings.waterContourSizePx / 5.0f, 0, 1), "Water contour size (" + nf(renderSettings.waterContourSizePx, 1, 1) + " px)");
    drawSlider(layout.waterRippleCountSlider, constrain(renderSettings.waterRippleCount / 5.0f, 0, 1), "Number of ripples (" + renderSettings.waterRippleCount + ")");
    drawSlider(layout.waterRippleDistanceSlider, constrain(renderSettings.waterRippleDistancePx / 40.0f, 0, 1), "Ripple distance (" + nf(renderSettings.waterRippleDistancePx, 1, 1) + " px)");
    drawHSBRow(layout.waterContourHSB, "Water contours", renderSettings.waterContourHue01, renderSettings.waterContourSat01, renderSettings.waterContourBri01);
    drawSlider(layout.waterContourAlphaSlider, renderSettings.waterContourAlpha01, "Water contours alpha (" + nf(renderSettings.waterContourAlpha01 * 100, 1, 0) + "%)");
    registerUiTooltip(layout.waterContourAlphaSlider, tooltipFor("render_contours"));
    float elevCountNorm = constrain(renderSettings.elevationLinesCount / 24.0f, 0, 1);
    drawSlider(layout.elevationLinesCountSlider, elevCountNorm, "Elevation lines (" + renderSettings.elevationLinesCount + ")");
    if (layout.elevationLineStyleSelector != null) {
      IntRect b = layout.elevationLineStyleSelector;
      stroke(160);
      fill(230);
      rect(b.x, b.y, b.w, b.h, 4);
      float knobX = b.x;
      float knobY = b.y + b.h / 2.0f;
      float knobR = b.h * 0.9f;
      fill(40);
      noStroke();
      ellipse(knobX, knobY, knobR, knobR);
      fill(0);
      textAlign(LEFT, BOTTOM);
      text("Style: Basic", b.x, b.y - 4);
    }
    drawSlider(layout.elevationLinesAlphaSlider, renderSettings.elevationLinesAlpha01, "Elevation lines alpha (" + nf(renderSettings.elevationLinesAlpha01 * 100, 1, 0) + "%)");
  }

  drawSectionHeader(layout.headerPaths, "Paths", renderSectionPathsOpen);
  if (renderSectionPathsOpen) {
    drawCheckbox(layout.pathsShowCheckbox.x, layout.pathsShowCheckbox.y, layout.pathsShowCheckbox.w, renderSettings.showPaths, "Show paths");
    drawSlider(layout.pathSatSlider, renderSettings.pathSatScale01, "Paths saturation (" + nf(renderSettings.pathSatScale01 * 100, 1, 0) + "%)");
  }

  drawSectionHeader(layout.headerZones, "Zones", renderSectionZonesOpen);
  if (renderSectionZonesOpen) {
    drawSlider(layout.zoneAlphaSlider, renderSettings.zoneStrokeAlpha01, "Zone lines alpha (" + nf(renderSettings.zoneStrokeAlpha01 * 100, 1, 0) + "%)"); 
    drawSlider(layout.zoneSatSlider, renderSettings.zoneStrokeSatScale01, "Zone lines saturation (" + nf(renderSettings.zoneStrokeSatScale01 * 100, 1, 0) + "%)");
    drawSlider(layout.zoneBriSlider, renderSettings.zoneStrokeBriScale01, "Zone lines brightness (" + nf(renderSettings.zoneStrokeBriScale01 * 100, 1, 0) + "%)");
  }

  drawSectionHeader(layout.headerStructures, "Structures", renderSectionStructuresOpen);
  if (renderSectionStructuresOpen) {
    drawCheckbox(layout.structuresShowCheckbox.x, layout.structuresShowCheckbox.y, layout.structuresShowCheckbox.w, renderSettings.showStructures, "Show structures");
    drawCheckbox(layout.structuresMergeCheckbox.x, layout.structuresMergeCheckbox.y, layout.structuresMergeCheckbox.w, renderSettings.mergeStructures, "Merge structures");
  }

  drawSectionHeader(layout.headerLabels, "Labels", renderSectionLabelsOpen);
  if (renderSectionLabelsOpen) {
    drawCheckbox(layout.labelsArbitraryCheckbox.x, layout.labelsArbitraryCheckbox.y, layout.labelsArbitraryCheckbox.w, renderSettings.showLabelsArbitrary, "Show arbitrary");
    registerUiTooltip(layout.labelsArbitraryCheckbox, tooltipFor("render_labels_arbitrary"));
    drawCheckbox(layout.labelsZonesCheckbox.x, layout.labelsZonesCheckbox.y, layout.labelsZonesCheckbox.w, renderSettings.showLabelsZones, "Show zones");
    drawCheckbox(layout.labelsPathsCheckbox.x, layout.labelsPathsCheckbox.y, layout.labelsPathsCheckbox.w, renderSettings.showLabelsPaths, "Show paths");
    drawCheckbox(layout.labelsStructuresCheckbox.x, layout.labelsStructuresCheckbox.y, layout.labelsStructuresCheckbox.w, renderSettings.showLabelsStructures, "Show structures");
    drawSlider(layout.labelsOutlineAlphaSlider, renderSettings.labelOutlineAlpha01, "Label outline alpha (" + nf(renderSettings.labelOutlineAlpha01 * 100, 1, 0) + "%)");
  }

  drawSectionHeader(layout.headerGeneral, "General", renderSectionGeneralOpen);
  if (renderSectionGeneralOpen) {
    drawSlider(layout.exportPaddingSlider, constrain(renderSettings.exportPaddingPct / 0.10f, 0, 1), "Export padding (" + nf(renderSettings.exportPaddingPct * 100.0f, 1, 1) + "%)");
    drawCheckbox(layout.antialiasCheckbox.x, layout.antialiasCheckbox.y, layout.antialiasCheckbox.w, renderSettings.antialiasing, "Antialiasing");

    // Preset selector
    if (renderPresets != null && renderPresets.length > 0) {
      IntRect ps = layout.presetSelector;
      int n = renderPresets.length;
      int maxIdx = max(1, n - 1);
      float t = constrain(renderSettings.activePresetIndex / (float)maxIdx, 0, 1);
      String presetName = renderPresets[renderSettings.activePresetIndex].name;
      drawSelectorSlider(ps, t, "Preset: " + presetName, n);
      registerUiTooltip(ps, tooltipFor("render_preset"));
    }

    if (layout.presetApplyBtn != null) {
      drawBevelButton(layout.presetApplyBtn.x, layout.presetApplyBtn.y, layout.presetApplyBtn.w, layout.presetApplyBtn.h, false);
      fill(10);
      textAlign(CENTER, CENTER);
      text("Apply preset", layout.presetApplyBtn.x + layout.presetApplyBtn.w / 2, layout.presetApplyBtn.y + layout.presetApplyBtn.h / 2);
    }
  }
}

void drawSectionHeader(IntRect header, String label, boolean isOpen) {
  if (header == null) return;
  drawBevelButton(header.x, header.y, header.w, header.h, false);
  fill(10);
  textAlign(LEFT, CENTER);
  String caret = isOpen ? "-" : "+";
  text(caret + " " + label, header.x + 8, header.y + header.h / 2);
}

void drawSlider(IntRect r, float tNorm, String label) {
  drawSlider(r, tNorm, label, false);
}

void drawSlider(IntRect r, float tNorm, String label, boolean zeroTick) {
  if (r == null) return;
  float t = constrain(tNorm, 0, 1);
  int trackY = r.y + r.h / 2;
  int padding = max(4, r.h / 2);
  int startX = r.x + padding;
  int endX = r.x + r.w - padding;

  // Track
  stroke(120);
  line(startX, trackY, endX, trackY);
  if (zeroTick) {
    int zx = startX + (endX - startX) / 2;
    stroke(80);
    line(zx, trackY - r.h / 2, zx, trackY - r.h / 2 + 6);
  }

  // Cursor with pointy tip
  int cursorX = round(lerp(startX, endX, t));
  int cursorW = max(8, round(r.h * 0.55f));
  int cursorH = round(r.h * 0.8f);
  int cursorY = r.y + (r.h - cursorH) / 2;
  noStroke();
  fill(236);
  rect(cursorX - cursorW / 2, cursorY, cursorW, cursorH);
  beginShape();
  fill(200);
  vertex(cursorX - cursorW / 2, cursorY + cursorH);
  vertex(cursorX + cursorW / 2, cursorY + cursorH);
  vertex(cursorX, cursorY + cursorH + max(3, cursorH / 3));
  endShape(CLOSE);
  stroke(255);
  line(cursorX - cursorW / 2, cursorY, cursorX + cursorW / 2, cursorY);
  line(cursorX - cursorW / 2, cursorY, cursorX - cursorW / 2, cursorY + cursorH);
  stroke(96);
  line(cursorX - cursorW / 2, cursorY + cursorH, cursorX + cursorW / 2, cursorY + cursorH);
  line(cursorX + cursorW / 2, cursorY, cursorX + cursorW / 2, cursorY + cursorH);

  fill(0);
  textAlign(LEFT, BOTTOM);
  text(label, r.x, r.y - 4);
}

void drawSelectorSlider(IntRect r, float tNorm, String label, int divisions) {
  if (r == null) return;
  int steps = max(2, divisions);
  float t = constrain(tNorm, 0, 1);
  int trackY = r.y + r.h / 2;
  int padding = max(4, r.h / 2);
  int startX = r.x + padding;
  int endX = r.x + r.w - padding;

  stroke(120);
  line(startX, trackY, endX, trackY);

  stroke(60);
  for (int i = 0; i < steps; i++) {
    float tt = (float)i / (float)(steps - 1);
    int tx = round(lerp(startX, endX, tt));
    line(tx, trackY - r.h / 2, tx, trackY - r.h / 2 + 6);
  }

  // Same pointer as sliders
  int cursorX = round(lerp(startX, endX, t));
  int cursorW = max(8, round(r.h * 0.55f));
  int cursorH = round(r.h * 0.8f);
  int cursorY = r.y + (r.h - cursorH) / 2;
  noStroke();
  fill(236);
  rect(cursorX - cursorW / 2, cursorY, cursorW, cursorH);
  beginShape();
  fill(200);
  vertex(cursorX - cursorW / 2, cursorY + cursorH);
  vertex(cursorX + cursorW / 2, cursorY + cursorH);
  vertex(cursorX, cursorY + cursorH + max(3, cursorH / 3));
  endShape(CLOSE);
  stroke(255);
  line(cursorX - cursorW / 2, cursorY, cursorX + cursorW / 2, cursorY);
  line(cursorX - cursorW / 2, cursorY, cursorX - cursorW / 2, cursorY + cursorH);
  stroke(96);
  line(cursorX - cursorW / 2, cursorY + cursorH, cursorX + cursorW / 2, cursorY + cursorH);
  line(cursorX + cursorW / 2, cursorY, cursorX + cursorW / 2, cursorY + cursorH);

  fill(0);
  textAlign(LEFT, BOTTOM);
  text(label, r.x, r.y - 4);
}

void drawHSBRow(IntRect[] sliders, String label, float h, float s, float b) {
  if (sliders == null || sliders.length < 3) return;
  fill(0);
  textAlign(LEFT, BOTTOM);
  text(label, sliders[0].x, sliders[0].y - 16);
  String[] names = { "hue", "saturation", "brightness" };
  float[] vals = { h, s, b };
  for (int i = 0; i < 3; i++) {
    IntRect r = sliders[i];
    if (r == null) continue;
    drawSlider(r, vals[i], names[i]);
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

PathRouteMode currentPathRouteMode() {
  PathRouteMode fromType = null;
  if (mapModel != null && mapModel.pathTypes != null && activePathTypeIndex >= 0 && activePathTypeIndex < mapModel.pathTypes.size()) {
    PathType pt = mapModel.pathTypes.get(activePathTypeIndex);
    if (pt != null) fromType = pt.routeMode;
  }
  if (fromType != null) return fromType;
  int idx = constrain(pathRouteModeIndex, 0, 1);
  if (idx == 0) return PathRouteMode.ENDS;
  return PathRouteMode.PATHFIND;
}

void drawTabButton(IntRect r, boolean active) {
  if (r == null) return;
  rectMode(CORNER);
  boolean held = isButtonHeld(r);
  int baseBg = color(245);
  int face = active ? baseBg : color(216);
  if (held) face = color(200);
  noStroke();
  fill(face);
  rect(r.x, r.y, r.w, r.h);
  stroke(255);
  line(r.x, r.y, r.x + r.w - 1, r.y);
  line(r.x, r.y, r.x, r.y + r.h - 1);
  stroke(active ? baseBg : color(160));
  // Skip bottom line so tab blends into panel
  stroke(96);
  line(r.x + r.w - 1, r.y, r.x + r.w - 1, r.y + r.h - 1);
}

void drawBevelButton(int x, int y, int w, int h, boolean pressed) {
  // Guard against world draw state leaking (e.g., rectMode(CENTER))
  rectMode(CORNER);
  IntRect r = new IntRect(x, y, w, h);
  boolean held = isButtonHeld(r);
  boolean pressState = pressed || held;
  int face = pressState ? color(192) : color(224);
  int hl = color(255);
  int sh = color(96);

  noStroke();
  fill(face);
  rect(x, y, w, h);

  if (!pressState) {
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

void drawRadioButton(IntRect r, boolean selected) {
  // Checkbox-like bevel
  drawBevelButton(r.x, r.y, r.w, r.h, false);
  // Radio dot
  float cx = r.x + r.w * 0.5f;
  float cy = r.y + r.h * 0.5f;
  float inner = min(r.w, r.h) * 0.4f;
  if (selected) {
    noStroke();
    fill(0);
    ellipse(cx, cy, inner, inner);
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

void drawControlsHint(IntRect panel, String... linesArr) {
  if (panel == null || linesArr == null) return;
  ArrayList<String> lines = new ArrayList<String>();
  for (String s : linesArr) {
    if (s != null && s.length() > 0) lines.add(s);
  }
  if (lines.isEmpty()) return;

  float totalH = lines.size() * (PANEL_LABEL_H + 2);
  float yTop = panel.y + panel.h - PANEL_PADDING - totalH;
  float sepY = yTop - 4;

  // Separator to visually isolate hints from controls above
  stroke(140);
  line(panel.x + PANEL_PADDING, sepY, panel.x + panel.w - PANEL_PADDING, sepY);

  fill(40);
  textAlign(LEFT, TOP);
  float y = yTop;
  for (String s : lines) {
    text(s, panel.x + PANEL_PADDING, y);
    y += PANEL_LABEL_H + 2;
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
    case EDIT_EXPORT: {
      ExportLayout l = buildExportLayout();
      return l.panel;
    }
  }
  return null;
}
