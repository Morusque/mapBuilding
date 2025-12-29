// Split from UI_Panels.pde: labels panel and list rendering.

// ----- LABELS PANEL -----
class LabelsLayout {
  IntRect panel;
  int titleY;
  IntRect genButton;
  IntRect commentField;
}

class LabelsListLayout {
  IntRect panel;
  int titleY;
  IntRect deselectBtn;
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
  l.genButton = new IntRect(l.panel.x + PANEL_PADDING, curY, 140, PANEL_BUTTON_H);
  curY += PANEL_BUTTON_H + PANEL_ROW_GAP;
  l.commentField = new IntRect(l.panel.x + PANEL_PADDING, curY + PANEL_LABEL_H, PANEL_W - 2 * PANEL_PADDING, PANEL_BUTTON_H);
  curY += PANEL_LABEL_H + PANEL_BUTTON_H + PANEL_ROW_GAP;
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

  // Generate button
  {
    IntRect gb = layout.genButton;
    drawBevelButton(gb.x, gb.y, gb.w, gb.h, false);
    fill(10);
    textAlign(CENTER, CENTER);
    text("Generate labels", gb.x + gb.w / 2, gb.y + gb.h / 2);
  }

  // Comment field (selected label)
  {
    IntRect cf = layout.commentField;
    fill(0);
    textAlign(LEFT, BOTTOM);
    text("Comment", cf.x, cf.y - 4);
    stroke(80);
    fill(255);
    rect(cf.x, cf.y, cf.w, cf.h);
    fill(0);
    textAlign(LEFT, CENTER);
    String shown = "";
    if (selectedLabelIndex >= 0 && selectedLabelIndex < mapModel.labels.size()) {
      MapLabel l = mapModel.labels.get(selectedLabelIndex);
      if (l != null && l.comment != null && editingLabelCommentIndex != selectedLabelIndex) shown = l.comment;
      if (editingLabelCommentIndex == selectedLabelIndex) shown = labelCommentDraft;
    }
    text(shown, cf.x + 6, cf.y + cf.h / 2);
    if (editingLabelCommentIndex == selectedLabelIndex) {
      float caretX = cf.x + 6 + textWidth(labelCommentDraft);
      stroke(0);
      line(caretX, cf.y + 4, caretX, cf.y + cf.h - 4);
    }
  }

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
  return l;
}

void populateLabelsListRows(LabelsListLayout layout) {
  layout.rows.clear();
  int labelX = layout.panel.x + PANEL_PADDING;
  int startY = layout.deselectBtn.y + layout.deselectBtn.h + PANEL_SECTION_GAP;
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
  curY = layout.deselectBtn.y + layout.deselectBtn.h + PANEL_SECTION_GAP;

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
