// ----- Export scaffold -----

class ExportLayout {
  IntRect panel;
  int titleY;
  int bodyY;
  IntRect pngBtn;
  IntRect svgBtn;
  IntRect scaleSlider;
  IntRect mapExportBtn;
  IntRect mapImportBtn;
  int mapSectionY;
  int statusY;
}

ExportLayout buildExportLayout() {
  ExportLayout l = new ExportLayout();
  l.panel = new IntRect(PANEL_X, panelTop(), PANEL_W, 0);
  int curY = l.panel.y + PANEL_PADDING;
  l.titleY = curY;
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;
  l.pngBtn = new IntRect(l.panel.x + PANEL_PADDING, curY, 140, PANEL_BUTTON_H);
  l.svgBtn = new IntRect(l.pngBtn.x + l.pngBtn.w + PANEL_ROW_GAP, curY, 140, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_ROW_GAP;
  l.scaleSlider = new IntRect(l.panel.x + PANEL_PADDING, curY + PANEL_LABEL_H, 180, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;
  l.bodyY = curY;
  curY += PANEL_LABEL_H * 2 + PANEL_SECTION_GAP;

  l.mapSectionY = curY;
  curY += PANEL_LABEL_H + PANEL_ROW_GAP;
  l.mapExportBtn = new IntRect(l.panel.x + PANEL_PADDING, curY, 120, PANEL_BUTTON_H);
  l.mapImportBtn = new IntRect(l.mapExportBtn.x + l.mapExportBtn.w + PANEL_ROW_GAP, curY, 120, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_SECTION_GAP;

  l.statusY = curY;
  curY += PANEL_LABEL_H + PANEL_SECTION_GAP;
  l.panel.h = curY - l.panel.y;
  return l;
}

void drawExportPanel() {
  ExportLayout layout = buildExportLayout();
  drawPanelBackground(layout.panel);

  int labelX = layout.panel.x + PANEL_PADDING;
  fill(0);
  textAlign(LEFT, TOP);
  text("Export", labelX, layout.titleY);

  // Buttons
  drawBevelButton(layout.pngBtn.x, layout.pngBtn.y, layout.pngBtn.w, layout.pngBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Export PNG", layout.pngBtn.x + layout.pngBtn.w / 2, layout.pngBtn.y + layout.pngBtn.h / 2);
  registerUiTooltip(layout.pngBtn, tooltipFor("export_png"));

  drawBevelButton(layout.svgBtn.x, layout.svgBtn.y, layout.svgBtn.w, layout.svgBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Export SVG", layout.svgBtn.x + layout.svgBtn.w / 2, layout.svgBtn.y + layout.svgBtn.h / 2);
  registerUiTooltip(layout.svgBtn, tooltipFor("export_svg"));

  // Resolution scale slider
  if (layout.scaleSlider != null) {
    IntRect s = layout.scaleSlider;
    float t = constrain(map(exportScale, 1.0f, 4.0f, 0, 1), 0, 1);
    drawSlider(s, t, "Resolution scale (" + nf(exportScale, 1, 1) + "x)");
    registerUiTooltip(s, tooltipFor("export_scale"));
  }

  fill(60);
  textAlign(LEFT, TOP);
  text("Uses Rendering tab toggles (biomes, zones, paths, etc.)\nand current viewport + padding.", labelX, layout.bodyY);

  fill(0);
  textAlign(LEFT, TOP);
  text("Map data (JSON)", labelX, layout.mapSectionY);
  drawBevelButton(layout.mapExportBtn.x, layout.mapExportBtn.y, layout.mapExportBtn.w, layout.mapExportBtn.h, false);
  drawBevelButton(layout.mapImportBtn.x, layout.mapImportBtn.y, layout.mapImportBtn.w, layout.mapImportBtn.h, false);
  fill(10);
  textAlign(CENTER, CENTER);
  text("Export map", layout.mapExportBtn.x + layout.mapExportBtn.w / 2, layout.mapExportBtn.y + layout.mapExportBtn.h / 2);
  text("Import map", layout.mapImportBtn.x + layout.mapImportBtn.w / 2, layout.mapImportBtn.y + layout.mapImportBtn.h / 2);
  registerUiTooltip(layout.mapExportBtn, tooltipFor("export_map_json"));
  registerUiTooltip(layout.mapImportBtn, tooltipFor("import_map_json"));

  fill(30);
  textAlign(LEFT, TOP);
  String status = (lastExportStatus != null && lastExportStatus.length() > 0)
    ? "Last export: " + lastExportStatus
    : "No export yet.";
  text(status, labelX, layout.statusY);
}
