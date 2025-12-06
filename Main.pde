
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
float structureAngleOffsetRad = 0.0f;
float lastStructureSnapAngle = 0.0f;
StructureSnapMode structureSnapMode = StructureSnapMode.NEXT_TO_PATH;
StructureShape structureShape = StructureShape.SQUARE;
float structureAspectRatio = 1.0f; // width/height for rectangle shape
float structureHue01 = 0.0f;
float structureSat01 = 0.0f;
float structureAlpha01 = 0.7f;
float structureStrokePx = 1.4f;
float zonesListScroll = 0;
float pathsListScroll = 0;
float structuresListScroll = 0;
float labelsListScroll = 0;

// Rendering configuration
RenderSettings renderSettings = new RenderSettings();
RenderPreset[] renderPresets = buildDefaultRenderPresets();
boolean renderSectionBaseOpen = false;
boolean renderSectionBiomesOpen = false;
boolean renderSectionShadingOpen = false;
boolean renderSectionContoursOpen = false;
boolean renderSectionPathsOpen = false;
boolean renderSectionZonesOpen = false;
boolean renderSectionStructuresOpen = false;
boolean renderSectionLabelsOpen = false;
boolean renderSectionGeneralOpen = false;

boolean snapWaterEnabled = true;
boolean snapBiomesEnabled = false;
boolean snapUnderwaterBiomesEnabled = false;
boolean snapZonesEnabled = true;
boolean snapPathsEnabled = true;
boolean snapStructuresEnabled = true;
boolean snapElevationEnabled = false;
int snapElevationDivisions = 8;

// UI layout
final int TOP_BAR_HEIGHT = 30;
final int TOP_BAR_EXTRA_PAD = 4;
final int TOP_BAR_TOTAL = TOP_BAR_HEIGHT + TOP_BAR_EXTRA_PAD;
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
final int SCROLLBAR_W = 14;
final int SCROLLBAR_THUMB_MIN = 24;
final int SCROLL_STEP_PX = 24;
final float FLATTEST_BIAS_MIN = 0.0f;
final float FLATTEST_BIAS_MAX = 500.0f;

// Cells (site seeds) generation config
PlacementMode[] placementModes = {
  PlacementMode.GRID,
  PlacementMode.POISSON,
  PlacementMode.HEX
};
int placementModeIndex = 1; // 0=GRID, 1=POISSON, 2=HEX
final int MAX_SITE_COUNT = 20000;
final int DEFAULT_SITE_COUNT = 10000;
int siteTargetCount = DEFAULT_SITE_COUNT; // slider maps 0..MAX_SITE_COUNT
float siteFuzz = 0.0;       // 0..1
boolean keepPropertiesOnGenerate = false;

// Zones (biomes) painting
int activeBiomeIndex = 1;                 // 0 = "None", 1..N = types
int activeZoneIndex = 1;                  // 0 = "None", 1..N = zones
ZonePaintMode currentZonePaintMode = ZonePaintMode.ZONE_PAINT;
int activePathTypeIndex = 0;
int pathRouteModeIndex = 1; // 0=ENDS,1=PATHFIND
float zoneBrushRadius = 0.04f;
float seaLevel = -0.2f;
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
boolean renderShowZoneOutlines = false;
boolean renderBlackWhite = false;
boolean renderWaterContours = false;
boolean renderElevationContours = false;
float renderLightAzimuthDeg = 220.0f;   // 0..360, 0 = +X (east)
float renderLightAltitudeDeg = 45.0f;   // 0..90, 90 = overhead
boolean useNewElevationShading = false;
float flattestSlopeBias = FLATTEST_BIAS_MIN; // slope penalty in PATHFIND mode (min..max, 0 = shortest)
boolean pathAvoidWater = false;
boolean pathTaperRivers = false;
boolean pathEraserMode = false;
float pathEraserRadius = 0.04f;
int PATH_MAX_EXPANSIONS = 10000; // tweakable pathfinding budget per query (per-direction if bidirectional)
boolean PATH_BIDIRECTIONAL = true; // grow paths from both ends
int ELEV_STEPS_PATHS = 6;
boolean siteDirtyDuringDrag = false;
float renderPaddingPct = 0.01f; // fraction of min(screenW, screenH) cropped from all sides
float exportScale = 2.0f; // multiplier for PNG export resolution
String lastExportStatus = "";

float labelSizeDefault() {
  return labelSizeDefaultVal;
}

void setLabelSizeDefault(float v) {
  labelSizeDefaultVal = constrain(v, 4, 72);
}

// Zone renaming state
int editingBiomeNameIndex = -1;
String biomeNameDraft = "";
int editingZoneNameIndex = -1;
String zoneNameDraft = "";

// Label editing state
int editingLabelIndex = -1;
int selectedLabelIndex = -1;
String labelDraft = "label";
LabelTarget labelTargetMode = LabelTarget.FREE;
float labelSizeDefaultVal = 12;

// Path type editing state
int editingPathTypeNameIndex = -1;
String pathTypeNameDraft = "";

// Path name editing state
int editingPathNameIndex = -1;
String pathNameDraft = "";

// Structure selection state
int selectedStructureIndex = -1;
int editingStructureNameIndex = -1;
String structureNameDraft = "";

// Loading indicator
boolean isLoading = false;
float loadingPhase = 0;
int loadingHoldFrames = 0;
float loadingPct = 0;
String uiNotice = "";
int uiNoticeFrames = 0;
final int NOTICE_DURATION_FRAMES = 150;

// Slider drag state
final int SLIDER_NONE = 0;
final int SLIDER_SITES_DENSITY = 1;
final int SLIDER_SITES_FUZZ = 2;
final int SLIDER_SITES_MODE = 3;
final int SLIDER_BIOME_HUE = 4;
final int SLIDER_BIOME_BRUSH = 5;
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
final int SLIDER_ZONES_HUE = 16;
final int SLIDER_ZONES_BRUSH = 17;
final int SLIDER_STRUCT_ANGLE = 18;
final int SLIDER_PATH_TYPE_MIN_WEIGHT = 19;
final int SLIDER_STRUCT_RATIO = 20;
final int SLIDER_ZONES_ROW_HUE = 21;
final int SLIDER_STRUCT_SELECTED_SIZE = 22;
final int SLIDER_STRUCT_SELECTED_ANGLE = 23;
final int SLIDER_STRUCT_SELECTED_HUE = 24;
final int SLIDER_STRUCT_SELECTED_ALPHA = 25;
final int SLIDER_STRUCT_SELECTED_SAT = 26;
final int SLIDER_STRUCT_SELECTED_STROKE = 27;
final int SLIDER_RENDER_PADDING = 28;
final int SLIDER_EXPORT_SCALE = 29;
final int SLIDER_RENDER_LAND_H = 30;
final int SLIDER_RENDER_LAND_S = 31;
final int SLIDER_RENDER_LAND_B = 32;
final int SLIDER_RENDER_WATER_H = 33;
final int SLIDER_RENDER_WATER_S = 34;
final int SLIDER_RENDER_WATER_B = 35;
final int SLIDER_RENDER_CELL_BORDER_ALPHA = 36;
final int SLIDER_RENDER_BIOME_FILL_ALPHA = 37;
final int SLIDER_RENDER_BIOME_SAT = 38;
final int SLIDER_RENDER_BIOME_OUTLINE_SIZE = 39;
final int SLIDER_RENDER_BIOME_OUTLINE_ALPHA = 40;
final int SLIDER_RENDER_WATER_DEPTH_ALPHA = 41;
final int SLIDER_RENDER_LIGHT_ALPHA = 42;
final int SLIDER_RENDER_WATER_CONTOUR_SIZE = 43;
final int SLIDER_RENDER_WATER_RIPPLE_COUNT = 44;
final int SLIDER_RENDER_WATER_RIPPLE_DIST = 45;
final int SLIDER_RENDER_WATER_CONTOUR_H = 46;
final int SLIDER_RENDER_WATER_CONTOUR_S = 47;
final int SLIDER_RENDER_WATER_CONTOUR_B = 48;
final int SLIDER_RENDER_WATER_CONTOUR_ALPHA = 49;
final int SLIDER_RENDER_ELEV_LINES_COUNT = 50;
final int SLIDER_RENDER_ELEV_LINES_ALPHA = 51;
final int SLIDER_RENDER_PATH_SAT = 52;
final int SLIDER_RENDER_ZONE_ALPHA = 53;
final int SLIDER_RENDER_ZONE_SAT = 54;
final int SLIDER_RENDER_LABEL_OUTLINE_ALPHA = 55;
final int SLIDER_RENDER_LABEL_MIN_SIZE = 56;
final int SLIDER_RENDER_PRESET_SELECT = 57;
int activeSlider = SLIDER_NONE;

void applyRenderPreset(int idx) {
  if (renderPresets == null || renderPresets.length == 0) return;
  int clamped = constrain(idx, 0, renderPresets.length - 1);
  RenderPreset p = renderPresets[clamped];
  if (p == null || p.values == null) return;
  renderSettings.applyFrom(p.values);
  renderSettings.activePresetIndex = clamped;
  // Keep legacy padding in sync until full migration
  renderPaddingPct = renderSettings.exportPaddingPct;
  renderShowPaths = renderSettings.showPaths;
  renderShowStructures = renderSettings.showStructures;
  renderShowZoneOutlines = renderSettings.zoneStrokeAlpha01 > 0.001f;
  renderShowLabels = renderSettings.showLabelsArbitrary || renderSettings.showLabelsZones ||
                     renderSettings.showLabelsPaths || renderSettings.showLabelsStructures;
}

color hsb01ToColor(float h, float s, float b) {
  colorMode(HSB, 1.0f);
  int c = color(constrain(h, 0, 1), constrain(s, 0, 1), constrain(b, 0, 1));
  colorMode(RGB, 255);
  return c;
}

void settings() {
  size(1200, 800, P2D);
}

void setup() {
  surface.setTitle("Map Editor - Cells + Zones + Paths");
  viewport = new Viewport();
  mapModel = new MapModel();
  applyRenderPreset(0);
  initBiomeTypes();
  initZones();
  initPathTypes();
  mapModel.generateSites(currentPlacementMode(), siteTargetCount);
  mapModel.ensureVoronoiComputed();
  seedDefaultZones();
}

void initBiomeTypes() {
  mapModel.biomeTypes.clear();
  mapModel.biomeTypes.add(new ZoneType("None",  color(235)));

  // Seed with the first few presets for quick access; more can be added via "+".
  int initialCount = 5;
  for (int i = 0; i < initialCount && i < ZONE_PRESETS.length; i++) {
    ZonePreset zp = ZONE_PRESETS[i];
    mapModel.biomeTypes.add(new ZoneType(zp.name, zp.col));
  }
}

void initZones() {
  mapModel.zones.clear();
  activeZoneIndex = -1;
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
    mapModel.pathTypes.add(new PathType("Path", color(80), 2.0f, 1.0f, PathRouteMode.PATHFIND, 0.0f, true, false));
  }
  activePathTypeIndex = 0;
  syncActivePathTypeGlobals();
}

void syncActivePathTypeGlobals() {
  if (mapModel == null || mapModel.pathTypes == null || mapModel.pathTypes.isEmpty()) return;
  activePathTypeIndex = constrain(activePathTypeIndex, 0, mapModel.pathTypes.size() - 1);
  PathType pt = mapModel.pathTypes.get(activePathTypeIndex);
  if (pt == null) return;
  pathRouteModeIndex = (pt.routeMode == PathRouteMode.ENDS) ? 0 : 1;
  flattestSlopeBias = pt.slopeBias;
  pathAvoidWater = pt.avoidWater;
}

void drawExportPaddingOverlay() {
  if (mapModel == null) return;
  float worldW = mapModel.maxX - mapModel.minX;
  float worldH = mapModel.maxY - mapModel.minY;
  float padX = max(0, renderPaddingPct) * worldW;
  float padY = max(0, renderPaddingPct) * worldH;
  float innerWX = mapModel.minX + padX;
  float innerWY = mapModel.minY + padY;
  float innerWW = max(0, worldW - padX * 2);
  float innerWH = max(0, worldH - padY * 2);
  if (innerWW <= 0 || innerWH <= 0) return;

  PVector tl = viewport.worldToScreen(innerWX, innerWY);
  PVector br = viewport.worldToScreen(innerWX + innerWW, innerWY + innerWH);
  float innerX = min(tl.x, br.x);
  float innerY = min(tl.y, br.y);
  float innerW = abs(br.x - tl.x);
  float innerH = abs(br.y - tl.y);
  noStroke();
  fill(80, 80, 80, 70);
  rect(0, 0, width, innerY); // top
  rect(0, innerY, innerX, innerH); // left
  rect(innerX + innerW, innerY, width - (innerX + innerW), innerH); // right
  rect(0, innerY + innerH, width, height - (innerY + innerH)); // bottom

  noFill();
  stroke(40, 40, 40, 180);
  strokeWeight(1);
  rect(innerX, innerY, innerW, innerH);
}

void draw() {
  background(245);

  // Drive incremental Voronoi rebuilds; loading state follows the job
  mapModel.ensureVoronoiComputed();
  boolean building = mapModel.isVoronoiBuilding();
  if (building) {
    if (!isLoading) startLoading();
    loadingPct = mapModel.getVoronoiProgress();
  } else {
    if (isLoading) stopLoading();
    loadingPct = 1.0f;
  }

  // ----- World rendering -----
  pushMatrix();
  viewport.applyTransform(this.g);

  boolean showBorders = !(currentTool == Tool.EDIT_PATHS || currentTool == Tool.EDIT_ELEVATION || currentTool == Tool.EDIT_RENDER || currentTool == Tool.EDIT_STRUCTURES || currentTool == Tool.EDIT_LABELS || currentTool == Tool.EDIT_ZONES || currentTool == Tool.EDIT_EXPORT);
  boolean drawCellsFlag = !(currentTool == Tool.EDIT_RENDER && !renderShowZones);
  boolean renderView = (currentTool == Tool.EDIT_RENDER || currentTool == Tool.EDIT_EXPORT);
  if (renderView) {
    drawRenderView(this);
  } else if (currentTool == Tool.EDIT_PATHS) {
    mapModel.drawCellsRender(this, showBorders, true);
    mapModel.drawElevationOverlay(this, seaLevel, false, true, true, false, ELEV_STEPS_PATHS);
  } else if (currentTool == Tool.EDIT_STRUCTURES) {
    mapModel.drawCellsRender(this, showBorders, true);
    mapModel.drawElevationOverlay(this, seaLevel, false, true, true, false, ELEV_STEPS_PATHS);
  } else if (currentTool == Tool.EDIT_LABELS) {
    mapModel.drawCellsRender(this, showBorders, true);
    mapModel.drawElevationOverlay(this, seaLevel, false, true, true, false, ELEV_STEPS_PATHS);
  } else if (currentTool == Tool.EDIT_ZONES) {
    mapModel.drawCellsRender(this, showBorders, true);
    mapModel.drawElevationOverlay(this, seaLevel, false, true, true, false, ELEV_STEPS_PATHS);
  } else if (drawCellsFlag) {
    mapModel.drawCells(this, showBorders);
  }

  if (currentTool == Tool.EDIT_ZONES && !renderView) {
    mapModel.drawZoneOutlines(this);
  }

  // Paths are visible in all modes
  boolean highlightPaths = (currentTool == Tool.EDIT_PATHS);
  int pathCol = renderBlackWhite ? color(50) : color(60, 60, 200);
  int pathElevCol = renderBlackWhite ? color(90) : color(120);
  if (currentTool == Tool.EDIT_ELEVATION) {
    mapModel.drawPaths(this, pathElevCol, highlightPaths, true);
  } else if (currentTool == Tool.EDIT_RENDER) {
    if (renderShowPaths) mapModel.drawPaths(this, pathCol, highlightPaths, false);
  } else {
    mapModel.drawPaths(this, pathCol, highlightPaths, true);
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
    PVector snapped = findNearestSnappingPoint(worldPos.x, worldPos.y, Float.MAX_VALUE);
    PVector target = (snapped != null) ? snapped : pendingPathStart;

    ArrayList<PVector> route = null;
    PathRouteMode mode = currentPathRouteMode();
    if (mode == PathRouteMode.ENDS) {
      route = new ArrayList<PVector>();
      route.add(pendingPathStart);
      route.add(target);
      if (route.size() == 2) {
      }
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

    // Use Path preview renderer for consistency
    Path tmp = new Path();
    tmp.routes.add(route);
    tmp.drawPreview(this, route, col, w);

    // Start marker
    pushStyle();
    noStroke();
    fill(255, 180, 0, 200);
    float sr = 5.0f / viewport.zoom;
    ellipse(pendingPathStart.x, pendingPathStart.y, sr, sr);
    // Target marker for very short previews
    if (!route.isEmpty()) {
      PVector end = route.get(route.size() - 1);
      float tr = 4.0f / viewport.zoom;
      fill(80, 120, 240, 160);
      ellipse(end.x, end.y, tr, tr);
    }
    popStyle();
  }

  if (currentTool == Tool.EDIT_PATHS) {
    drawPathSnappingPoints();
  }

  // Structures and labels render in all modes
  if (currentTool == Tool.EDIT_STRUCTURES) {
    // Snap guides should float above everything except the structures themselves
    mapModel.drawStructureSnapGuides(this);
  }
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
    mapModel.drawElevationOverlay(this, seaLevel, false, true, true, false, 0);
    drawElevationBrushPreview();
  } else if (currentTool == Tool.EDIT_BIOMES && currentZonePaintMode == ZonePaintMode.ZONE_PAINT) {
    drawZoneBrushPreview();
  } else if (currentTool == Tool.EDIT_ZONES && currentZonePaintMode == ZonePaintMode.ZONE_PAINT) {
    drawZoneBrushPreview();
  } else if (currentTool == Tool.EDIT_PATHS && pathEraserMode) {
    drawPathEraserPreview();
  } else if (!renderView) {
    mapModel.drawDebugWorldBounds(this);
  }
  popMatrix();

  // Screen-space border for render/export view
  if (renderView) {
    pushStyle();
    noFill();
    stroke(0);
    strokeWeight(2);
    rect(1, 1, width - 2, height - 2);
    popStyle();
  }

  // Ensure UI drawing uses normal coordinate modes (world rendering can change rectMode)
  rectMode(CORNER);
  ellipseMode(CENTER);

  if (currentTool == Tool.EDIT_RENDER || currentTool == Tool.EDIT_EXPORT) {
    drawExportPaddingOverlay();
  }

  // ----- UI overlay -----
  drawTopBar();
  drawToolButtons();
  if (currentTool == Tool.EDIT_STRUCTURES) {
    drawSnapSettingsPanel();
  }
  if (currentTool == Tool.EDIT_SITES) {
    drawSitesPanel();
  } else if (currentTool == Tool.EDIT_ELEVATION) {
    drawElevationPanel();
  } else if (currentTool == Tool.EDIT_BIOMES) {
    drawBiomesPanel();
  } else if (currentTool == Tool.EDIT_ZONES) {
    drawZonesPanel();
    drawZonesListPanel();
  } else if (currentTool == Tool.EDIT_STRUCTURES) {
    drawStructuresPanelUI();
    drawStructuresListPanel();
  } else if (currentTool == Tool.EDIT_PATHS) {
    drawPathsPanel();
    drawPathsListPanel();
  } else if (currentTool == Tool.EDIT_LABELS) {
    drawLabelsPanel();
    drawLabelsListPanel();
  } else if (currentTool == Tool.EDIT_RENDER) {
    drawRenderPanel();
  } else if (currentTool == Tool.EDIT_EXPORT) {
    drawExportPanel();
  }
}

void drawRenderView(PApplet app) {
  mapModel.drawRenderAdvanced(app, renderSettings, seaLevel);

  // Zone outlines (stroke-only, no fill)
  if (renderSettings.zoneStrokeAlpha01 > 1e-4f && renderSettings.showZones) {
    mapModel.drawZoneOutlinesRender(app, renderSettings);
  }

  // Paths
  if (renderSettings.showPaths) {
    mapModel.drawPathsRender(app, renderSettings);
  }

  // Structures
  if (renderSettings.showStructures) {
    mapModel.drawStructuresRender(app, renderSettings);
  }

  // Labels
  if (renderSettings.showLabelsArbitrary || renderSettings.showLabelsZones || renderSettings.showLabelsPaths || renderSettings.showLabelsStructures) {
    mapModel.drawLabelsRender(app, renderSettings);
  }
}

String exportPng() {
  // Compute inner world rect from render padding
  float worldW = mapModel.maxX - mapModel.minX;
  float worldH = mapModel.maxY - mapModel.minY;
  if (worldW <= 0 || worldH <= 0) return "Failed: invalid world bounds";

  float safePad = constrain(renderPaddingPct, 0, 0.49f); // avoid collapsing to zero
  float padX = max(0, safePad) * worldW;
  float padY = max(0, safePad) * worldH;
  float innerWX = mapModel.minX + padX;
  float innerWY = mapModel.minY + padY;
  float innerWW = worldW - padX * 2;
  float innerWH = worldH - padY * 2;
  if (innerWW <= 1e-6f || innerWH <= 1e-6f) return "Failed: export padding too large";

  // Match export buffer aspect to the cropped world so we crop instead of showing letterbox bars.
  float innerAspect = innerWW / innerWH;
  float safeScale = constrain(exportScale, 0.1f, 8.0f);
  int pxH = max(1, round(max(1, height) * safeScale));
  int pxW = max(1, round(pxH * innerAspect));
  if (pxW <= 0 || pxH <= 0) return "Failed: export size collapsed";
  PGraphics g = createGraphics(pxW, pxH, P2D);
  if (g == null) return "Failed to allocate buffer";

  float prevCenterX = viewport.centerX;
  float prevCenterY = viewport.centerY;
  float prevZoom = viewport.zoom;

  // Fit inner world rect to buffer while preserving aspect
  float zoomX = g.width / innerWW;
  float zoomY = g.height / innerWH;
  float newZoom = max(zoomX, zoomY); // fill buffer; slight overzoom is fine (cropped)
  viewport.centerX = innerWX + innerWW * 0.5f;
  viewport.centerY = innerWY + innerWH * 0.5f;
  viewport.zoom = newZoom;

  g.beginDraw();
  g.background(245);
  // Temporarily redirect drawing to offscreen buffer
  PGraphics prev = this.g;
  this.g = g;
  pushMatrix();
  viewport.applyTransform(g, g.width, g.height);
  drawRenderView(this);
  popMatrix();
  this.g = prev;
  g.endDraw();

  // Restore viewport
  viewport.centerX = prevCenterX;
  viewport.centerY = prevCenterY;
  viewport.zoom = prevZoom;

  String dir = "exports";
  java.io.File folder = new java.io.File(dir);
  folder.mkdirs();
  String ts = nf(year(), 4, 0) + nf(month(), 2, 0) + nf(day(), 2, 0) + "_" +
              nf(hour(), 2, 0) + nf(minute(), 2, 0) + nf(second(), 2, 0);
  String path = dir + java.io.File.separator + "map_" + ts + ".png";
  g.save(path);
  return path;
}

void drawPathSnappingPoints() {
  if (pathEraserMode) return;
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

  float baseR = 2.0f / viewport.zoom;

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
  PVector cursorScreen = viewport.worldToScreen(wx, wy);

  for (PVector p : snaps) {
    PVector s = viewport.worldToScreen(p.x, p.y);
    float dx = s.x - cursorScreen.x;
    float dy = s.y - cursorScreen.y;
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
  loadingPct = 0;
}

void stopLoading() {
  isLoading = false;
  loadingHoldFrames = 30; // keep bar visible briefly
  loadingPct = 1.0f;
}

void showNotice(String msg) {
  uiNotice = msg;
  uiNoticeFrames = NOTICE_DURATION_FRAMES;
}

void drawZoneBrushPreview() {
  IntRect panel = getActivePanelRect();
  if (panel != null && panel.contains(mouseX, mouseY)) return;
  if (mouseY < TOP_BAR_TOTAL + TOOL_BAR_HEIGHT) return;
  PVector w = viewport.screenToWorld(mouseX, mouseY);
  pushStyle();
  noFill();
  stroke(40, 120);
  strokeWeight(1.0f / viewport.zoom);
  float r = zoneBrushRadius;
  ellipse(w.x, w.y, r * 2, r * 2);
  popStyle();
}

void drawPathEraserPreview() {
  IntRect panel = getActivePanelRect();
  if (panel != null && panel.contains(mouseX, mouseY)) return;
  if (mouseY < TOP_BAR_TOTAL + TOOL_BAR_HEIGHT) return;
  PVector w = viewport.screenToWorld(mouseX, mouseY);
  pushStyle();
  noFill();
  stroke(200, 40, 40, 160);
  strokeWeight(1.0f / viewport.zoom);
  ellipse(w.x, w.y, pathEraserRadius * 2, pathEraserRadius * 2);
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
  int uiBottom = TOP_BAR_TOTAL + TOOL_BAR_HEIGHT;
  if (mouseY < uiBottom) return;
  PVector w = viewport.screenToWorld(mouseX, mouseY);
  Structure tmp = mapModel.computeSnappedStructure(w.x, w.y, structureSize);
  if (tmp == null) return;
  pushStyle();
  stroke(80, 140);
  strokeWeight(1.0f / viewport.zoom);
  fill(200, 200, 180, 120);
  tmp.draw(this);
  popStyle();
}
