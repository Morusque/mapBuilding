
import processing.event.MouseEvent;
import java.util.HashSet;
import java.util.ArrayList;

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

int selectedPathIndex = -1;
PVector pendingPathStart = null;
float structureSize = 0.02f; // world units

// UI layout
final int TOP_BAR_HEIGHT = 30;
final int TOOL_BAR_HEIGHT = 26;
final int PANEL_X = 0;
final int PANEL_W = 320;
final int PANEL_PADDING = 10;
final int PANEL_ROW_GAP = 8;
final int PANEL_SECTION_GAP = 12;
final int PANEL_SLIDER_H = 16;
final int PANEL_LABEL_H = 14;
final int PANEL_BUTTON_H = 22;
final int PANEL_CHECK_SIZE = 16;
final int PANEL_TITLE_H = 18;
final int RIGHT_PANEL_W = 260;

// Sites generation config
PlacementMode[] placementModes = {
  PlacementMode.GRID,
  PlacementMode.POISSON,
  PlacementMode.HEX
};
int placementModeIndex = 2; // 0=GRID, 1=POISSON, 2=HEX
final int MAX_SITE_COUNT = 20000;
final int DEFAULT_SITE_COUNT = 5000;
int siteTargetCount = DEFAULT_SITE_COUNT; // slider maps 0..MAX_SITE_COUNT
float siteFuzz = 0.07;      // 0..1
boolean keepPropertiesOnGenerate = false;

// Zones (biomes) painting
int activeBiomeIndex = 1;                 // 0 = "None", 1..N = types
ZonePaintMode currentZonePaintMode = ZonePaintMode.ZONE_PAINT;
int activePathTypeIndex = 0;
int pathRouteModeIndex = 1; // 0=ENDS,1=PATHFIND
float zoneBrushRadius = 0.04f;
float seaLevel = 0.0f;
float elevationBrushRadius = 0.08f;
float elevationBrushStrength = 0.05f; // per stroke
boolean elevationBrushRaise = true;
float elevationNoiseScale = 4.0f;
float defaultElevation = 0.05f;

// Render toggles
boolean renderShowZones = true;
boolean renderShowWater = true;
boolean renderShowElevation = true;
boolean renderShowPaths = true;
boolean renderShowLabels = true;
boolean renderShowStructures = true;
float renderLightAzimuthDeg = 135.0f;   // 0..360, 0 = +X (east)
float renderLightAltitudeDeg = 45.0f;   // 0..90, 90 = overhead
float flattestSlopeBias = 0.0f; // slope penalty in PATHFIND mode (0..200, 0 = shortest)
boolean pathAvoidWater = false;

// Zone renaming state
int editingZoneNameIndex = -1;
String zoneNameDraft = "";

// Label editing state
int editingLabelIndex = -1;
String labelDraft = "Label";

// Path type editing state
int editingPathTypeNameIndex = -1;
String pathTypeNameDraft = "";

// Path name editing state
int editingPathNameIndex = -1;
String pathNameDraft = "";

// Loading indicator
boolean isLoading = false;
float loadingPhase = 0;
int loadingHoldFrames = 0;

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
final int SLIDER_PATH_TYPE_HUE = 10;
final int SLIDER_PATH_TYPE_WEIGHT = 11;
final int SLIDER_FLATTEST_BIAS = 12;
final int SLIDER_RENDER_LIGHT_AZIMUTH = 13;
final int SLIDER_RENDER_LIGHT_ALTITUDE = 14;
final int SLIDER_STRUCT_SIZE = 15;
int activeSlider = SLIDER_NONE;

void settings() {
  size(1200, 800, P2D);
}

void setup() {
  surface.setTitle("Map Editor - Sites + Zones + Paths");
  viewport = new Viewport();
  mapModel = new MapModel();
  initBiomeTypes();
  initPathTypes();
  mapModel.generateSites(currentPlacementMode(), siteTargetCount);
  mapModel.ensureVoronoiComputed();
  seedDefaultZones();
}

void initBiomeTypes() {
  mapModel.biomeTypes.clear();
  mapModel.biomeTypes.add(new ZoneType("None",  color(235)));

  // Seed with the first few presets for quick access; more can be added via "+".
  int initialCount = 4;
  for (int i = 0; i < initialCount && i < ZONE_PRESETS.length; i++) {
    ZonePreset zp = ZONE_PRESETS[i];
    mapModel.biomeTypes.add(new ZoneType(zp.name, zp.col));
  }
}

void initPathTypes() {
  mapModel.pathTypes.clear();
  int initialCount = min(4, PATH_TYPE_PRESETS.length);
  for (int i = 0; i < initialCount; i++) {
    PathType pt = mapModel.makePathTypeFromPreset(i);
    if (pt != null) {
      mapModel.pathTypes.add(pt);
    }
  }
  if (mapModel.pathTypes.isEmpty()) {
    mapModel.pathTypes.add(new PathType("Path", color(80), 2.0f));
  }
  activePathTypeIndex = 0;
}

void draw() {
  background(245);

  // ----- World rendering -----
  pushMatrix();
  viewport.applyTransform(this);

  mapModel.ensureVoronoiComputed();
  boolean showBorders = !(currentTool == Tool.EDIT_PATHS || currentTool == Tool.EDIT_ELEVATION || currentTool == Tool.EDIT_RENDER || currentTool == Tool.EDIT_STRUCTURES || currentTool == Tool.EDIT_LABELS);
  boolean drawCellsFlag = !(currentTool == Tool.EDIT_RENDER && !renderShowZones);
  if (currentTool == Tool.EDIT_RENDER) {
    if (renderShowZones) {
      mapModel.drawCellsRender(this, showBorders, seaLevel);
    }
    if (renderShowElevation || renderShowWater) {
      mapModel.drawElevationOverlay(this, seaLevel, false, renderShowWater, renderShowElevation,
                                    true, renderLightAzimuthDeg, renderLightAltitudeDeg);
    }
  } else if (currentTool == Tool.EDIT_PATHS) {
    mapModel.drawCellsRender(this, showBorders, seaLevel);
    mapModel.drawElevationOverlay(this, seaLevel, false, true, true);
  } else if (currentTool == Tool.EDIT_STRUCTURES) {
    mapModel.drawCellsRender(this, showBorders, seaLevel);
    mapModel.drawElevationOverlay(this, seaLevel, false, true, false);
  } else if (currentTool == Tool.EDIT_LABELS) {
    mapModel.drawCellsRender(this, showBorders, seaLevel);
    mapModel.drawElevationOverlay(this, seaLevel, false, true, false);
  } else if (drawCellsFlag) {
    mapModel.drawCells(this, showBorders);
  }

  // Paths are visible in all modes
  boolean highlightPaths = (currentTool == Tool.EDIT_PATHS);
  if (currentTool == Tool.EDIT_ELEVATION) {
    mapModel.drawPaths(this, color(120), highlightPaths);
  } else if (currentTool == Tool.EDIT_RENDER) {
    if (renderShowPaths) mapModel.drawPaths(this, color(60, 60, 200), highlightPaths);
  } else {
    mapModel.drawPaths(this, color(60, 60, 200), highlightPaths);
  }

  // Sites only in Sites mode; paths use snapping dots instead
  if (currentTool == Tool.EDIT_SITES) {
    mapModel.drawSites(this);
  }

  // Path segment preview when a start point is pending
  if (currentTool == Tool.EDIT_PATHS && pendingPathStart != null) {
    PVector worldPos = viewport.screenToWorld(mouseX, mouseY);
    worldPos.x = constrain(worldPos.x, mapModel.minX, mapModel.maxX);
    worldPos.y = constrain(worldPos.y, mapModel.minY, mapModel.maxY);
    float maxSnapPx = 14;
    PVector snapped = findNearestSnappingPoint(worldPos.x, worldPos.y, maxSnapPx);
    PVector target = (snapped != null) ? snapped : worldPos;

    ArrayList<PVector> route = null;
    PathRouteMode mode = currentPathRouteMode();
    if (mode == PathRouteMode.ENDS) {
      route = new ArrayList<PVector>();
      route.add(pendingPathStart);
      route.add(target);
    } else if (mode == PathRouteMode.PATHFIND) {
      if (snapped != null) {
        route = mapModel.findSnapPathFlattest(pendingPathStart, target);
      }
    }
    if (route == null || route.size() < 2) {
      route = new ArrayList<PVector>();
      route.add(pendingPathStart);
      route.add(target);
    }

    PathType pt = null;
    if (selectedPathIndex >= 0 && selectedPathIndex < mapModel.paths.size()) {
      Path p = mapModel.paths.get(selectedPathIndex);
      pt = mapModel.getPathType(p.typeId);
    } else {
      pt = mapModel.getPathType(activePathTypeIndex);
    }
    int col = (pt != null) ? pt.col : color(30, 30, 160);
    float w = (pt != null) ? pt.weightPx : 2.0f;

    pushStyle();
    noFill();
    stroke(col);
    strokeWeight(max(0.5f, w) / viewport.zoom);
    beginShape();
    for (PVector v : route) {
      vertex(v.x, v.y);
    }
    endShape();
    popStyle();
  }

  if (currentTool == Tool.EDIT_PATHS) {
    drawPathSnappingPoints();
  }

  // Structures and labels render in all modes
  if (currentTool != Tool.EDIT_RENDER || renderShowStructures) {
    mapModel.drawStructures(this);
  }
  if (currentTool != Tool.EDIT_RENDER || renderShowLabels) {
    mapModel.drawLabels(this);
  }

  if (currentTool == Tool.EDIT_STRUCTURES) {
    drawStructurePreview();
  }

  if (currentTool == Tool.EDIT_ELEVATION) {
    mapModel.drawElevationOverlay(this, seaLevel, false, true, true);
    drawElevationBrushPreview();
  } else if (currentTool == Tool.EDIT_BIOMES && currentZonePaintMode == ZonePaintMode.ZONE_PAINT) {
    drawZoneBrushPreview();
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
  } else if (currentTool == Tool.EDIT_BIOMES) {
    drawBiomesPanel();
  } else if (currentTool == Tool.EDIT_ADMIN) {
    drawAdminPanel();
  } else if (currentTool == Tool.EDIT_STRUCTURES) {
    drawStructuresPanelUI();
  } else if (currentTool == Tool.EDIT_PATHS) {
    drawPathsPanel();
    drawPathsListPanel();
  } else if (currentTool == Tool.EDIT_LABELS) {
    drawLabelsPanel();
  } else if (currentTool == Tool.EDIT_RENDER) {
    drawRenderPanel();
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

void startLoading() {
  isLoading = true;
  loadingPhase = 0;
  loadingHoldFrames = 0;
}

void stopLoading() {
  isLoading = false;
  loadingHoldFrames = 8; // keep bar visible briefly
}

void drawZoneBrushPreview() {
  IntRect panel = getActivePanelRect();
  if (panel != null && panel.contains(mouseX, mouseY)) return;
  PVector w = viewport.screenToWorld(mouseX, mouseY);
  pushStyle();
  noFill();
  stroke(40, 120);
  strokeWeight(1.0f / viewport.zoom);
  float r = zoneBrushRadius;
  ellipse(w.x, w.y, r * 2, r * 2);
  popStyle();
}

void drawElevationBrushPreview() {
  IntRect panel = getActivePanelRect();
  if (panel != null && panel.contains(mouseX, mouseY)) return;
  PVector w = viewport.screenToWorld(mouseX, mouseY);
  pushStyle();
  noFill();
  stroke(40, 120);
  strokeWeight(1.0f / viewport.zoom);
  float r = elevationBrushRadius;
  ellipse(w.x, w.y, r * 2, r * 2);
  popStyle();
}

void drawStructurePreview() {
  int uiBottom = TOP_BAR_HEIGHT + TOOL_BAR_HEIGHT;
  if (mouseY < uiBottom) return;
  PVector w = viewport.screenToWorld(mouseX, mouseY);
  Structure tmp = mapModel.computeSnappedStructure(w.x, w.y, structureSize);
  if (tmp == null) return;
  pushStyle();
  pushMatrix();
  float r = tmp.size;
  translate(tmp.x, tmp.y);
  rotate(tmp.angle);
  stroke(80, 140);
  strokeWeight(1.0f / viewport.zoom);
  fill(200, 200, 180, 120);
  rectMode(CENTER);
  rect(0, 0, r, r);
  popMatrix();
  popStyle();
}
