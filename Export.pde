// ----- Export scaffold -----

class ExportLayout {
  IntRect panel;
  int titleY;
  int bodyY;
}

ExportLayout buildExportLayout() {
  ExportLayout l = new ExportLayout();
  l.panel = new IntRect(PANEL_X, panelTop(), PANEL_W, 0);
  int curY = l.panel.y + PANEL_PADDING;
  l.titleY = curY;
  curY += PANEL_TITLE_H + PANEL_SECTION_GAP;
  l.bodyY = curY;
  curY += PANEL_HINT_H;
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

  fill(60);
  textAlign(LEFT, TOP);
  text("Export setup coming soon.\nAdd formats, layers, and paths here.", labelX, layout.bodyY);
}
