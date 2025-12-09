// ----- Export scaffold -----

class ExportLayout {
  IntRect panel;
  int titleY;
  int bodyY;
  IntRect pngBtn;
  IntRect scaleSlider;
  int statusY;
}

ExportLayout buildExportLayout() {
  ExportLayout l = new ExportLayout();
  l.panel = new IntRect(PANEL_X, panelTop(), PANEL_W, 0);
  int curY = l.panel.y + PANEL_PADDING;
  l.titleY = curY;
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;
  l.pngBtn = new IntRect(l.panel.x + PANEL_PADDING, curY, 140, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_ROW_GAP;
  l.scaleSlider = new IntRect(l.panel.x + PANEL_PADDING, curY + PANEL_LABEL_H, 180, PANEL_SLIDER_H);
  curY += PANEL_LABEL_H + PANEL_SLIDER_H + PANEL_SECTION_GAP;
  l.bodyY = curY;
  curY += PANEL_LABEL_H * 2 + PANEL_SECTION_GAP;
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

  // Resolution scale slider
  if (layout.scaleSlider != null) {
    IntRect s = layout.scaleSlider;
    stroke(160);
    fill(230);
    rect(s.x, s.y, s.w, s.h, 4);
    float t = constrain(map(exportScale, 1.0f, 4.0f, 0, 1), 0, 1);
    float hx = s.x + t * s.w;
    float hr = s.h * 0.9f;
    float hy = s.y + s.h / 2.0f;
    fill(40);
    noStroke();
    ellipse(hx, hy, hr, hr);
    fill(0);
    textAlign(LEFT, BOTTOM);
    text("Resolution scale (" + nf(exportScale, 1, 1) + "x)", s.x, s.y - 4);
    registerUiTooltip(s, tooltipFor("export_scale"));
  }

  fill(60);
  textAlign(LEFT, TOP);
  text("Uses Rendering tab toggles (biomes, zones, paths, etc.)\nand current viewport + padding.", labelX, layout.bodyY);

  fill(30);
  textAlign(LEFT, TOP);
  String status = (lastExportStatus != null && lastExportStatus.length() > 0)
    ? "Last export: " + lastExportStatus
    : "No export yet.";
  text(status, labelX, layout.statusY);
}
