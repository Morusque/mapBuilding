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

// Path drawing state
boolean isDrawingPath = false;
Path currentPath = null;

// UI layout
final int TOP_BAR_HEIGHT = 30;
final int TOOL_BAR_HEIGHT = 26;
final int SITES_PANEL_HEIGHT = 140;  // sliders + generate
final int ZONES_PANEL_HEIGHT = 80;   // biome palette + paint/fill buttons

// Sites generation config
PlacementMode[] placementModes = {
  PlacementMode.GRID,
  PlacementMode.POISSON,
  PlacementMode.HEX
};
int placementModeIndex = 2; // 0=GRID, 1=POISSON, 2=HEX
float siteDensity = 0.3;    // 0..1
float siteFuzz = 0.0;       // 0..1

// Zones (biomes) painting
int activeBiomeIndex = 1;                 // 0 = "None", 1..N = types
ZonePaintMode currentZonePaintMode = ZonePaintMode.ZONE_PAINT;

void settings() {
  size(1200, 800, P2D);
}

void setup() {
  surface.setTitle("Map Editor – Sites + Zones + Paths");
  viewport = new Viewport();
  mapModel = new MapModel();
  initBiomeTypes();
}

void initBiomeTypes() {
  mapModel.biomeTypes.clear();
  mapModel.biomeTypes.add(new ZoneType("None",  color(235)));
  mapModel.biomeTypes.add(new ZoneType("Type 1", color(210, 230, 255)));
  mapModel.biomeTypes.add(new ZoneType("Type 2", color(220, 255, 220)));
  mapModel.biomeTypes.add(new ZoneType("Type 3", color(255, 240, 210)));
}

void draw() {
  background(245);

  // ----- World rendering -----
  pushMatrix();
  viewport.applyTransform(this);

  mapModel.ensureVoronoiComputed();
  mapModel.drawCells(this);

  // Paths are visible in all modes
  mapModel.drawPaths(this);

  // Sites only in Sites or Paths modes
  if (currentTool == Tool.EDIT_SITES || currentTool == Tool.EDIT_PATHS) {
    mapModel.drawSites(this);
  }

  // Current path being drawn (preview)
  if (isDrawingPath && currentPath != null && currentTool == Tool.EDIT_PATHS) {
    currentPath.drawPreview(this);
  }

  mapModel.drawDebugWorldBounds(this);
  popMatrix();

  // ----- UI overlay -----
  drawTopBar();
  drawToolButtons();
  if (currentTool == Tool.EDIT_SITES) {
    drawSitesPanel();
  } else if (currentTool == Tool.EDIT_ZONES) {
    drawZonesPanel();
  }
}
