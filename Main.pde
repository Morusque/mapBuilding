import processing.event.MouseEvent;

Viewport viewport;
MapModel mapModel;

// Current editing mode
Tool currentTool = Tool.EDIT_SITES;

// Panning state
boolean isPanning = false;
int lastMouseX;
int lastMouseY;

// Site dragging state
Site draggingSite = null;
boolean isDraggingSite = false;

// UI layout
final int TOP_BAR_HEIGHT = 30;
final int TOOL_BAR_HEIGHT = 26;
final int SITES_PANEL_HEIGHT = 140;  // sliders + generate

// Sites generation config
PlacementMode[] placementModes = {
  PlacementMode.GRID,
  PlacementMode.POISSON,
  PlacementMode.HEX
};
int placementModeIndex = 0; // 0 = GRID
float siteDensity = 0.5;    // 0..1
float siteFuzz = 0.0;       // 0..1

void settings() {
  size(1200, 800, P2D);
}

void setup() {
  surface.setTitle("Map Editor – Sites");
  viewport = new Viewport();
  mapModel = new MapModel();
}

void draw() {
  background(245);

  // ----- World rendering -----
  pushMatrix();
  viewport.applyTransform(this);

  mapModel.ensureVoronoiComputed();
  mapModel.drawCells(this);

  // Only show sites in Sites or Paths modes (paths not implemented yet)
  if (currentTool == Tool.EDIT_SITES || currentTool == Tool.EDIT_PATHS) {
    mapModel.drawSites(this);
  }

  mapModel.drawDebugWorldBounds(this);
  popMatrix();

  // ----- UI overlay -----
  drawTopBar();
  drawToolButtons();
  if (currentTool == Tool.EDIT_SITES) {
    drawSitesPanel();
  }
}
