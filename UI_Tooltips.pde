class UITooltipArea {
  IntRect rect;
  String text;
  UITooltipArea(IntRect rect, String text) {
    this.rect = rect;
    this.text = text;
  }
}

ArrayList<UITooltipArea> uiTooltipAreas = new ArrayList<UITooltipArea>();
String currentUiTooltip = "";

final int TOOLTIP_PANEL_WIDTH = 480;
final int TOOLTIP_PANEL_BASE_LINES = 3;

void resetUiTooltips() {
  uiTooltipAreas.clear();
  currentUiTooltip = "";
}

void registerUiTooltip(IntRect rect, String text) {
  if (rect == null || text == null || text.length() == 0) return;
  uiTooltipAreas.add(new UITooltipArea(rect, text));
  if (currentUiTooltip == null || currentUiTooltip.length() == 0) {
    if (rect.contains(mouseX, mouseY)) {
      currentUiTooltip = text;
    }
  }
}

void refreshUiTooltip(int mx, int my) {
  currentUiTooltip = "";
  for (int i = uiTooltipAreas.size() - 1; i >= 0; i--) {
    UITooltipArea entry = uiTooltipAreas.get(i);
    if (entry != null && entry.rect != null && entry.rect.contains(mx, my)) {
      currentUiTooltip = entry.text;
      return;
    }
  }
}

void drawUiTooltipPanel() {
  if (currentUiTooltip == null || currentUiTooltip.length() == 0) return;

  int panelW = min(TOOLTIP_PANEL_WIDTH, width - PANEL_PADDING * 2);
  if (panelW < 100) return;

  String[] lines = currentUiTooltip.split("\\n");
  int lineCount = lines.length;

  float lineHeight = PANEL_LABEL_H + 2;
  int effectiveLines = max(TOOLTIP_PANEL_BASE_LINES, lineCount);
  float panelH = effectiveLines * lineHeight + PANEL_PADDING * 2;
  int x = PANEL_PADDING;
  int y = height - PANEL_PADDING - round(panelH);

  noStroke();
  fill(255, 255, 255, 230);
  rect(x, y, panelW, panelH, 6);

  fill(20);
  textAlign(LEFT, TOP);
  float ty = y + PANEL_PADDING;
  for (String line : lines) {
    text(line, x + PANEL_PADDING, ty);
    ty += lineHeight;
  }
}
