
import processing.event.MouseEvent;
import java.util.HashSet;

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
final int ZONES_PANEL_HEIGHT = 150;   // biome palette + paint/fill buttons + brush slider
final int PATH_PANEL_HEIGHT = 40;     // close/undo buttons
final int ELEV_PANEL_HEIGHT = 150;

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
float zoneBrushRadius = 0.04f;
float seaLevel = 0.0f;
float elevationBrushRadius = 0.08f;
float elevationBrushStrength = 0.05f; // per stroke
boolean elevationBrushRaise = true;
float elevationNoiseScale = 4.0f;
float defaultElevation = 0.05f;

// Slider drag state
final int SLIDER_NONE = 0;
final int SLIDER_SITES_DENSITY = 1;
final int SLIDER_SITES_FUZZ = 2;
final int SLIDER_SITES_MODE = 3;
final int SLIDER_ZONE_HUE = 4;
final int SLIDER_ZONE_BRUSH = 5;
final int SLIDER_ELEV_SEA = 6;
final int SLIDER_ELEV_RADIUS = 7;
final int SLIDER_ELEV_STRENGTH = 8;
final int SLIDER_ELEV_NOISE = 9;
int activeSlider = SLIDER_NONE;

void settings() {
  size(1200, 800, P2D);
}

void setup() {
  surface.setTitle("Map Editor - Sites + Zones + Paths");
  viewport = new Viewport();
  mapModel = new MapModel();
  initBiomeTypes();
  mapModel.generateSites(currentPlacementMode(), siteDensity);
  mapModel.ensureVoronoiComputed();
  seedDefaultZones();
}

void initBiomeTypes() {
  mapModel.biomeTypes.clear();
  mapModel.biomeTypes.add(new ZoneType("None",  color(235)));
  mapModel.biomeTypes.add(new ZoneType("Type 1", color(230, 220, 200)));
  mapModel.biomeTypes.add(new ZoneType("Type 2", color(210, 240, 210)));
  mapModel.biomeTypes.add(new ZoneType("Type 3", color(245, 225, 190)));
}

void draw() {
  background(245);

  // ----- World rendering -----
  pushMatrix();
  viewport.applyTransform(this);

  mapModel.ensureVoronoiComputed();
  boolean showBorders = !(currentTool == Tool.EDIT_PATHS || currentTool == Tool.EDIT_ELEVATION);
  mapModel.drawCells(this, showBorders);

  // Paths are visible in all modes
  if (currentTool == Tool.EDIT_ELEVATION) {
    mapModel.drawPaths(this, color(120), 1.0f / viewport.zoom);
  } else {
    mapModel.drawPaths(this);
  }

  // Sites only in Sites mode; paths use snapping dots instead
  if (currentTool == Tool.EDIT_SITES) {
    mapModel.drawSites(this);
  }

  // Current path being drawn (preview)
  if (isDrawingPath && currentPath != null && currentTool == Tool.EDIT_PATHS) {
    currentPath.drawPreview(this);
  }

  if (currentTool == Tool.EDIT_PATHS) {
    drawPathSnappingPoints();
  }

  if (currentTool == Tool.EDIT_ELEVATION) {
    mapModel.drawElevationOverlay(this, seaLevel, true);
  } else {
    mapModel.drawDebugWorldBounds(this);
  }
  popMatrix();

  // ----- UI overlay -----
  drawTopBar();
  drawToolButtons();
  if (currentTool == Tool.EDIT_SITES) {
    drawSitesPanel();
  } else if (currentTool == Tool.EDIT_ELEVATION) {
    drawElevationPanel();
  } else if (currentTool == Tool.EDIT_ZONES) {
    drawZonesPanel();
  } else if (currentTool == Tool.EDIT_PATHS) {
    drawPathsPanel();
  }
}

void drawPathSnappingPoints() {
  ArrayList<PVector> snaps = mapModel.getSnapPoints();
  if (snaps == null || snaps.isEmpty()) return;

  float nearestScreenSq = Float.MAX_VALUE;
  PVector nearest = null;
  float px = mouseX;
  float py = mouseY;

  // Find nearest to mouse in screen space
  for (PVector p : snaps) {
    PVector s = viewport.worldToScreen(p.x, p.y);
    float dx = s.x - px;
    float dy = s.y - py;
    float d2 = dx * dx + dy * dy;
    if (d2 < nearestScreenSq) {
      nearestScreenSq = d2;
      nearest = p;
    }
  }

  float baseR = 3.0f / viewport.zoom;

  pushStyle();
  noStroke();
  fill(30, 30, 30, 90);
  for (PVector p : snaps) {
    ellipse(p.x, p.y, baseR, baseR);
  }

  if (nearest != null) {
    float hr = 5.0f / viewport.zoom;
    stroke(0);
    strokeWeight(1.0f / viewport.zoom);
    fill(255, 255, 0, 180);
    ellipse(nearest.x, nearest.y, hr, hr);
  }
  popStyle();
}

PVector findNearestSnappingPoint(float wx, float wy, float maxScreenDist) {
  ArrayList<PVector> snaps = mapModel.getSnapPoints();
  if (snaps.isEmpty()) return null;

  float bestSq = maxScreenDist * maxScreenDist;
  PVector best = null;

  for (PVector p : snaps) {
    PVector s = viewport.worldToScreen(p.x, p.y);
    float dx = s.x - mouseX;
    float dy = s.y - mouseY;
    float d2 = dx * dx + dy * dy;
    if (d2 < bestSq) {
      bestSq = d2;
      best = p;
    }
  }
  return best;
}

void seedDefaultZones() {
  if (mapModel.cells == null || mapModel.cells.isEmpty()) return;
  for (Cell c : mapModel.cells) {
    c.biomeId = 0;
    c.elevation = defaultElevation;
  }
}
