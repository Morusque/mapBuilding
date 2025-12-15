
import processing.event.MouseEvent;
import java.util.HashSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.io.File;

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
StructureShape structureShape = StructureShape.RECTANGLE;
float structureAspectRatio = 1.0f; // width/height for rectangle shape
float structureHue01 = 0.0f;
float structureSat01 = 0.0f;
float structureAlpha01 = 1.0f;
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
final float FLATTEST_BIAS_MAX = 1000.0f;

// Cells (site seeds) generation config
PlacementMode[] placementModes = {
  PlacementMode.GRID,
  PlacementMode.POISSON,
  PlacementMode.HEX
};
int placementModeIndex = 1; // 0=GRID, 1=POISSON, 2=HEX
final int MAX_SITE_COUNT = 50000;
final int DEFAULT_SITE_COUNT = 10000;
int siteTargetCount = DEFAULT_SITE_COUNT; // slider maps 0..MAX_SITE_COUNT
float siteFuzz = 0.0;       // 0..1
boolean keepPropertiesOnGenerate = false;

// Zones (biomes) painting
int activeBiomeIndex = 1;                 // 0 = "None", 1..N = types
int activeZoneIndex = 1;                  // 0 = "None", 1..N = zones
ZonePaintMode currentZonePaintMode = ZonePaintMode.ZONE_PAINT;
ZonePaintMode currentBiomePaintMode = ZonePaintMode.ZONE_PAINT;
int activePathTypeIndex = 0;
int pathRouteModeIndex = 1; // 0=ENDS,1=PATHFIND
float zoneBrushRadius = 0.04f;
float seaLevel = -0.2f;
float elevationBrushRadius = 0.08f;
float elevationBrushStrength = 0.05f; // per stroke
boolean elevationBrushRaise = true;
float elevationNoiseScale = 8.0f;
float defaultElevation = 0.05f;

// Render toggles
boolean renderShowWater = true;
boolean renderShowElevation = true;
boolean renderShowPaths = true;
boolean renderShowLabels = true;
boolean renderShowStructures = true;
boolean renderShowZoneOutlines = false;
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
boolean renderContoursDirty = true;

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
boolean editingZoneComment = false;
String zoneCommentDraft = "";

// Biome generation settings
String[] biomeGenerateModes = {
  "Propagation",
  "Reset",
  "Fill gaps",
  "Replace gaps",
  "Fill under",
  "Fill above",
  "Extend",
  "Shrink",
  "Spots",
  "Vary",
  "Beaches",
  "Full"
};
int biomeGenerateModeIndex = 0;
float biomeGenerateValue01 = 0.75f;

// Label editing state
int editingLabelIndex = -1;
int selectedLabelIndex = -1;
String labelDraft = "label";
LabelTarget labelTargetMode = LabelTarget.FREE;
float labelSizeDefaultVal = 12;
int editingLabelCommentIndex = -1;
String labelCommentDraft = "";

// Path type editing state
int editingPathTypeNameIndex = -1;
String pathTypeNameDraft = "";

// Path name editing state
int editingPathNameIndex = -1;
String pathNameDraft = "";
int editingPathCommentIndex = -1;
String pathCommentDraft = "";

// Structure selection state
HashSet<Integer> selectedStructureIndices = new HashSet<Integer>();
int primaryStructureIndex = -1;
boolean editingStructureName = false;
int editingStructureNameIndex = -1;
String structureNameDraft = "";
boolean editingStructureComment = false;
String structureCommentDraft = "";

class StructureSelectionInfo {
  boolean hasSelection = false;
  boolean nameMixed = false;
  boolean sizeMixed = false;
  boolean angleMixed = false;
  boolean ratioMixed = false;
  boolean shapeMixed = false;
  boolean alignmentMixed = false;
  boolean hueMixed = false;
  boolean satMixed = false;
  boolean alphaMixed = false;
  boolean strokeMixed = false;
  boolean commentMixed = false;

  String sharedName = "";
  String sharedComment = "";
  float sharedSize = 0.02f;
  float sharedAngleRad = 0.0f;
  float sharedAngleOffsetRad = 0.0f;
  float sharedRatio = 1.0f;
  StructureShape sharedShape = StructureShape.RECTANGLE;
  StructureSnapMode sharedAlignment = StructureSnapMode.NEXT_TO_PATH;
  float sharedHue = 0.0f;
  float sharedSat = 0.0f;
  float sharedAlpha = 1.0f;
  float sharedStroke = 1.4f;
}

StructureSelectionInfo gatherStructureSelectionInfo() {
  StructureSelectionInfo info = new StructureSelectionInfo();
  info.sharedName = structureNameDraft;
  info.sharedComment = structureCommentDraft;
  info.sharedSize = structureSize;
  info.sharedAngleRad = structureAngleOffsetRad;
  info.sharedAngleOffsetRad = structureAngleOffsetRad;
  info.sharedRatio = structureAspectRatio;
  info.sharedShape = structureShape;
  info.sharedAlignment = structureSnapMode;
  info.sharedHue = structureHue01;
  info.sharedSat = structureSat01;
  info.sharedAlpha = structureAlpha01;
  info.sharedStroke = structureStrokePx;

  if (mapModel == null || mapModel.structures == null || selectedStructureIndices == null || selectedStructureIndices.isEmpty()) {
    return info;
  }

  ArrayList<Integer> invalid = new ArrayList<Integer>();
  boolean first = true;
  for (int idx : selectedStructureIndices) {
    if (idx < 0 || idx >= mapModel.structures.size()) {
      invalid.add(idx);
      continue;
    }
    Structure s = mapModel.structures.get(idx);
    if (s == null) {
      invalid.add(idx);
      continue;
    }
    if (first) {
      info.sharedName = (s.name != null) ? s.name : "";
      info.sharedComment = (s.comment != null) ? s.comment : "";
      info.sharedSize = s.size;
      info.sharedAngleRad = s.angle;
      float snapAngle = (s.snapBinding != null) ? s.snapBinding.snapAngleRad : 0.0f;
      info.sharedAngleOffsetRad = s.angle - snapAngle;
      info.sharedRatio = s.aspect;
      info.sharedShape = s.shape;
      info.sharedAlignment = s.alignment;
      info.sharedHue = s.hue01;
      info.sharedSat = s.sat01;
      info.sharedAlpha = s.alpha01;
      info.sharedStroke = s.strokeWeightPx;
      first = false;
      continue;
    }
    if (!info.nameMixed) {
      String nm = (s.name != null) ? s.name : "";
      info.nameMixed = !nm.equals(info.sharedName);
    }
    if (!info.commentMixed) {
      String cm = (s.comment != null) ? s.comment : "";
      info.commentMixed = !cm.equals(info.sharedComment);
    }
    if (!info.sizeMixed && abs(info.sharedSize - s.size) > 1e-6f) info.sizeMixed = true;
    if (!info.angleMixed && abs(info.sharedAngleRad - s.angle) > 1e-6f) info.angleMixed = true;
    if (!info.ratioMixed && abs(info.sharedRatio - s.aspect) > 1e-6f) info.ratioMixed = true;
    if (!info.shapeMixed && info.sharedShape != s.shape) info.shapeMixed = true;
    if (!info.alignmentMixed && info.sharedAlignment != s.alignment) info.alignmentMixed = true;
    if (!info.hueMixed && abs(info.sharedHue - s.hue01) > 1e-6f) info.hueMixed = true;
    if (!info.satMixed && abs(info.sharedSat - s.sat01) > 1e-6f) info.satMixed = true;
    if (!info.alphaMixed && abs(info.sharedAlpha - s.alpha01) > 1e-6f) info.alphaMixed = true;
    if (!info.strokeMixed && abs(info.sharedStroke - s.strokeWeightPx) > 1e-6f) info.strokeMixed = true;
  }

  for (int idx : invalid) {
    selectedStructureIndices.remove(idx);
  }

  if (first) return info;
  info.hasSelection = true;

  // Keep UI draft values in sync when there's a clear consensus.
  if (!info.nameMixed) structureNameDraft = info.sharedName;
  if (!info.commentMixed) structureCommentDraft = info.sharedComment;
  if (!info.sizeMixed) structureSize = info.sharedSize;
  if (!info.angleMixed) structureAngleOffsetRad = info.sharedAngleOffsetRad;
  if (!info.ratioMixed) structureAspectRatio = info.sharedRatio;
  if (!info.shapeMixed) structureShape = info.sharedShape;
  if (!info.alignmentMixed) structureSnapMode = info.sharedAlignment;
  if (!info.hueMixed) structureHue01 = info.sharedHue;
  if (!info.satMixed) structureSat01 = info.sharedSat;
  if (!info.alphaMixed) structureAlpha01 = info.sharedAlpha;
  if (!info.strokeMixed) structureStrokePx = info.sharedStroke;
  return info;
}

boolean isStructureSelected(int idx) {
  return selectedStructureIndices != null && selectedStructureIndices.contains(idx);
}

void clearStructureSelection() {
  if (selectedStructureIndices != null) selectedStructureIndices.clear();
  primaryStructureIndex = -1;
  editingStructureName = false;
  editingStructureNameIndex = -1;
  editingStructureComment = false;
}

void toggleStructureSelection(int idx) {
  if (selectedStructureIndices == null) selectedStructureIndices = new HashSet<Integer>();
  if (selectedStructureIndices.contains(idx)) {
    selectedStructureIndices.remove(idx);
    if (primaryStructureIndex == idx) {
      primaryStructureIndex = selectedStructureIndices.isEmpty() ? -1 : selectedStructureIndices.iterator().next();
    }
  } else {
    selectedStructureIndices.add(idx);
    primaryStructureIndex = idx;
  }
  if (selectedStructureIndices.isEmpty()) {
    editingStructureName = false;
    editingStructureNameIndex = -1;
  }
}

void selectStructureExclusive(int idx) {
  clearStructureSelection();
  if (selectedStructureIndices == null) selectedStructureIndices = new HashSet<Integer>();
  if (idx >= 0) {
    selectedStructureIndices.add(idx);
    primaryStructureIndex = idx;
  }
}

void shiftStructureSelectionAfterRemoval(int removedIdx) {
  if (selectedStructureIndices == null || selectedStructureIndices.isEmpty()) return;
  HashSet<Integer> updated = new HashSet<Integer>();
  for (int idx : selectedStructureIndices) {
    if (idx == removedIdx) continue;
    int adjusted = (idx > removedIdx) ? idx - 1 : idx;
    if (adjusted >= 0) updated.add(adjusted);
  }
  selectedStructureIndices = updated;
  if (!selectedStructureIndices.contains(primaryStructureIndex)) {
    primaryStructureIndex = selectedStructureIndices.isEmpty() ? -1 : selectedStructureIndices.iterator().next();
  }
  if (selectedStructureIndices.isEmpty()) {
    editingStructureName = false;
    editingStructureNameIndex = -1;
  }
}

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
final int SLIDER_PATH_TYPE_SAT = 11;
final int SLIDER_PATH_TYPE_BRI = 12;
final int SLIDER_PATH_TYPE_WEIGHT = 13;
final int SLIDER_FLATTEST_BIAS = 14;
final int SLIDER_RENDER_LIGHT_AZIMUTH = 15;
final int SLIDER_RENDER_LIGHT_ALTITUDE = 16;
final int SLIDER_STRUCT_SIZE = 17;
final int SLIDER_ZONES_HUE = 18;
final int SLIDER_ZONES_BRUSH = 19;
final int SLIDER_STRUCT_ANGLE = 20;
final int SLIDER_PATH_TYPE_MIN_WEIGHT = 21;
final int SLIDER_STRUCT_RATIO = 22;
final int SLIDER_ZONES_ROW_HUE = 23;
final int SLIDER_STRUCT_SELECTED_SIZE = 24;
final int SLIDER_STRUCT_SELECTED_ANGLE = 25;
final int SLIDER_STRUCT_SELECTED_HUE = 26;
final int SLIDER_STRUCT_SELECTED_ALPHA = 27;
final int SLIDER_STRUCT_SELECTED_SAT = 28;
final int SLIDER_STRUCT_SELECTED_STROKE = 29;
final int SLIDER_RENDER_PADDING = 30;
final int SLIDER_EXPORT_SCALE = 31;
final int SLIDER_RENDER_LAND_H = 32;
final int SLIDER_RENDER_LAND_S = 33;
final int SLIDER_RENDER_LAND_B = 34;
final int SLIDER_RENDER_WATER_H = 35;
final int SLIDER_RENDER_WATER_S = 36;
final int SLIDER_RENDER_WATER_B = 37;
final int SLIDER_RENDER_CELL_BORDER_ALPHA = 38;
final int SLIDER_RENDER_BIOME_FILL_ALPHA = 39;
final int SLIDER_RENDER_BIOME_SAT = 40;
final int SLIDER_RENDER_BIOME_OUTLINE_SIZE = 41;
final int SLIDER_RENDER_BIOME_OUTLINE_ALPHA = 42;
final int SLIDER_RENDER_WATER_DEPTH_ALPHA = 43;
final int SLIDER_RENDER_LIGHT_ALPHA = 44;
final int SLIDER_RENDER_WATER_CONTOUR_SIZE = 45;
final int SLIDER_RENDER_WATER_RIPPLE_COUNT = 46;
final int SLIDER_RENDER_WATER_RIPPLE_DIST = 47;
final int SLIDER_RENDER_WATER_CONTOUR_H = 48;
final int SLIDER_RENDER_WATER_CONTOUR_S = 49;
final int SLIDER_RENDER_WATER_CONTOUR_B = 50;
final int SLIDER_RENDER_WATER_CONTOUR_ALPHA = 51;
final int SLIDER_RENDER_WATER_RIPPLE_ALPHA_START = 52;
final int SLIDER_RENDER_WATER_RIPPLE_ALPHA_END = 53;
final int SLIDER_RENDER_ELEV_LINES_COUNT = 54;
final int SLIDER_RENDER_ELEV_LINES_ALPHA = 55;
final int SLIDER_RENDER_PATH_SAT = 56;
final int SLIDER_RENDER_ZONE_ALPHA = 57;
final int SLIDER_RENDER_ZONE_SAT = 58;
final int SLIDER_RENDER_LABEL_OUTLINE_ALPHA = 59;
final int SLIDER_RENDER_ELEV_LINES_STYLE = 60;
final int SLIDER_RENDER_ZONE_BRI = 61;
final int SLIDER_RENDER_PRESET_SELECT = 62;
final int SLIDER_BIOME_GEN_MODE = 63;
final int SLIDER_BIOME_GEN_VALUE = 64;
final int SLIDER_RENDER_BIOME_UNDERWATER_ALPHA = 65;
final int SLIDER_RENDER_STRUCT_SHADOW_ALPHA = 66;
final int SLIDER_BIOME_SAT = 67;
final int SLIDER_BIOME_BRI = 68;
final int SLIDER_RENDER_BACKGROUND_NOISE = 69;
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
  renderShowLabels = renderSettings.showLabelsArbitrary;
}

void applyBiomeGeneration() {
  if (mapModel == null || mapModel.cells == null) return;
  int mode = constrain(biomeGenerateModeIndex, 0, biomeGenerateModes.length - 1);
  int targetBiome = constrain(activeBiomeIndex, 0, mapModel.biomeTypes.size() - 1);
  float val01 = constrain(biomeGenerateValue01, 0, 1);
  float threshold = lerp(-1.0f, 1.0f, val01);

  switch (mode) {
    case 0: // propagation
      mapModel.resetAllBiomesToNone();
      mapModel.generateZonesFromSeeds();
      break;
    case 1: // reset
      mapModel.setAllBiomesTo(targetBiome);
      break;
    case 2: // fill gaps
      mapModel.fillGapsFromExistingBiomes();
      break;
    case 3: // replace gaps
      mapModel.fillGapsWithNewBiomes(map(biomeGenerateValue01,0,1,160,20));
      break;
    case 4: // fill under
      mapModel.fillUnderThreshold(targetBiome, threshold);
      break;
    case 5: // fill above
      mapModel.fillAboveThreshold(targetBiome, threshold);
      break;
    case 6: // extend
      mapModel.extendBiomeOnce(targetBiome);
      break;
    case 7: // shrink
      mapModel.shrinkBiomeOnce(targetBiome);
      break;
    case 8: // spots
      mapModel.placeBiomeSpots(targetBiome, val01);
      break;
    case 9: // vary
      mapModel.varyBiomesOnce();
      break;
    case 10: // beaches
      mapModel.placeBeaches(targetBiome, val01, seaLevel);
      break;
    case 11: // full pipeline
    default:
      int forestIdx = ensureBiomeType("Forest");
      int wetIdx = ensureBiomeType("Wet");
      int sandIdx = ensureBiomeType("Sand");
      int rockIdx = ensureBiomeType("Rock");
      int snowIdx = ensureBiomeType("Snow");
      int magmaIdx = ensureBiomeType("Magma");
      int grassIdx = ensureBiomeType("Grassland");
      boolean hasNoneCell = false;
      int cellCount = mapModel.cells.size();
      for (int i = 0; i < cellCount && !hasNoneCell ; i++) if (mapModel.cells.get(i) != null) hasNoneCell = true;
      if (hasNoneCell) mapModel.resetAllBiomesToNone();
      mapModel.fillGapsWithNewBiomes(150);
      if (magmaIdx >= 0) for (int i = 0; i < 8; i++) mapModel.shrinkBiomeOnce(magmaIdx);
      if (wetIdx >= 0) for (int i = 0; i < 8; i++) mapModel.shrinkBiomeOnce(wetIdx);
      if (forestIdx >= 0) for (int i = 0; i < 5; i++) mapModel.placeBiomeSpots(forestIdx, 0.5);
      if (forestIdx >= 0) mapModel.fillAboveThreshold(forestIdx, 0.24f);
      if (rockIdx >= 0) mapModel.fillAboveThreshold(rockIdx, 0.36f);
      if (snowIdx >= 0) mapModel.fillAboveThreshold(snowIdx, 0.48f);
      if (magmaIdx >= 0) mapModel.fillAboveThreshold(magmaIdx, 0.6f);
      if (grassIdx >= 0) mapModel.extendBiomeOnce(grassIdx);
      if (forestIdx >= 0) mapModel.shrinkBiomeOnce(forestIdx);
      if (wetIdx >= 0) mapModel.fillUnderThreshold(wetIdx, seaLevel);
      if (sandIdx >= 0) for (int i = 0; i < 7; i++) mapModel.placeBeaches(sandIdx, 0.8f, seaLevel);
      mapModel.varyBiomesOnce();
      break;
  }
  mapModel.renderer.invalidateBiomeOutlineCache();
  mapModel.snapDirty = true;
}

void triggerRenderPrerequisites() {
  if (mapModel == null || renderSettings == null) return;
  if (renderSettings.waterRippleCount > 0 &&
      renderSettings.waterRippleDistancePx > 1e-4f &&
      (renderSettings.waterRippleAlphaStart01 > 1e-4f || renderSettings.waterRippleAlphaEnd01 > 1e-4f)) {
    int cols = max(80, min(200, (int)(sqrt(max(1, mapModel.cells.size())))));
    int rows = cols;
    mapModel.getCoastDistanceGrid(cols, rows, seaLevel);
  }
  if (renderSettings.elevationLinesCount > 0 && renderSettings.elevationLinesAlpha01 > 1e-4f) {
    mapModel.getElevationGridForRender(90, 90, seaLevel);
  }
}

void triggerRenderPrerequisitesIfDirty() {
  if (mapModel == null || renderSettings == null) return;
  if (!renderContoursDirty) return;
  if (mapModel.isContourJobRunning()) return;
  renderContoursDirty = false;
  triggerRenderPrerequisites();
}

int ensureBiomeType(String name) {
  if (mapModel == null || mapModel.biomeTypes == null || name == null) return -1;
  for (int i = 0; i < mapModel.biomeTypes.size(); i++) {
    ZoneType zt = mapModel.biomeTypes.get(i);
    if (zt != null && zt.name != null && zt.name.equalsIgnoreCase(name)) {
      return i;
    }
  }
  int col = color(200);
  for (ZonePreset zp : ZONE_PRESETS) {
    if (zp != null && zp.name != null && zp.name.equalsIgnoreCase(name)) {
      col = zp.col;
      break;
    }
  }
  mapModel.biomeTypes.add(new ZoneType(name, col));
  return mapModel.biomeTypes.size() - 1;
}

float sliderFromElevation(float elev) {
  return constrain(map(elev, -1.0f, 1.0f, 0, 1), 0, 1);
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
  surface.setTitle("map designing tool");
  viewport = new Viewport();
  mapModel = new MapModel();
  applyRenderPreset(0);
  initBiomeTypes();
  initZones();
  initPathTypes();
  mapModel.generateSites(currentPlacementMode(), siteTargetCount);
  mapModel.ensureVoronoiComputed();
  seedDefaultZones();
  initTooltipTexts();
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
  mapModel.stepContourJobs(6);
  boolean buildingVoronoi = mapModel.isVoronoiBuilding();
  boolean buildingContours = mapModel.isContourJobRunning();
  boolean building = buildingVoronoi || buildingContours;
  float pctVoronoi = mapModel.getVoronoiProgress();
  float pctContours = mapModel.getContourJobProgress();
  float combinedPct = buildingContours ? min(pctVoronoi, pctContours) : pctVoronoi;
  if (building) {
    if (!isLoading) startLoading();
    loadingPct = combinedPct;
  } else {
    if (isLoading) stopLoading();
    loadingPct = 1.0f;
  }

  // ----- World rendering -----
  pushMatrix();
  viewport.applyTransform(this.g);

  boolean showBorders = !(currentTool == Tool.EDIT_PATHS || currentTool == Tool.EDIT_ELEVATION || currentTool == Tool.EDIT_RENDER || currentTool == Tool.EDIT_STRUCTURES || currentTool == Tool.EDIT_LABELS || currentTool == Tool.EDIT_ZONES || currentTool == Tool.EDIT_EXPORT);
  boolean drawCellsFlag = !(currentTool == Tool.EDIT_RENDER);
  boolean renderView = (currentTool == Tool.EDIT_RENDER || currentTool == Tool.EDIT_EXPORT);
  if (renderView) {
    triggerRenderPrerequisitesIfDirty();
    drawRenderView(this);
  } else if (currentTool == Tool.EDIT_PATHS) {
    mapModel.drawCellsRender(this, showBorders, true);
    mapModel.drawElevationOverlay(this, seaLevel, false, true, true, false, ELEV_STEPS_PATHS);
  } else if (currentTool == Tool.EDIT_ELEVATION) {
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
  int pathCol = color(60, 60, 200);
  int pathElevCol = color(120);
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
  if (currentTool != Tool.EDIT_RENDER && renderShowLabels) {
    mapModel.drawLabels(this);
    if (currentTool == Tool.EDIT_LABELS) {
      if (renderSettings.showLabelsZones) mapModel.drawZoneLabelsRender(this, renderSettings);
      if (renderSettings.showLabelsPaths) mapModel.drawPathLabelsRender(this, renderSettings);
      if (renderSettings.showLabelsStructures) mapModel.drawStructureLabelsRender(this, renderSettings);
    }
  }

  if (currentTool == Tool.EDIT_STRUCTURES) {
    drawStructurePreview();
  }

  if (currentTool == Tool.EDIT_ELEVATION) {
    mapModel.drawElevationOverlay(this, seaLevel, false, true, true, false, 0);
    drawElevationBrushPreview();
  } else if (currentTool == Tool.EDIT_BIOMES && currentBiomePaintMode == ZonePaintMode.ZONE_PAINT) {
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

  resetUiTooltips();

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

  refreshUiTooltip(mouseX, mouseY);
  drawUiTooltipPanel();
}

void drawRenderView(PApplet app) {
  mapModel.drawRenderAdvanced(app, renderSettings, seaLevel);

  // Zone outlines (stroke-only, no fill)
  if (renderSettings.zoneStrokeAlpha01 > 1e-4f) {
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
  if (renderSettings.showLabelsZones) mapModel.drawZoneLabelsRender(app, renderSettings);
  if (renderSettings.showLabelsPaths) mapModel.drawPathLabelsRender(app, renderSettings);
  if (renderSettings.showLabelsStructures) mapModel.drawStructureLabelsRender(app, renderSettings);
  if (renderSettings.showLabelsArbitrary) mapModel.drawLabelsRender(app, renderSettings);
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

  // Ensure distance/elevation grids are ready before rendering/exporting
  triggerRenderPrerequisites();

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

  // If contour jobs were triggered during the first pass, finish them and redraw
  if (mapModel.isContourJobRunning()) {
    int safety = 0;
    while (mapModel.isContourJobRunning() && safety < 80) {
      mapModel.stepContourJobs(16);
      safety++;
    }
    g.beginDraw();
    g.background(245);
    PGraphics prev2 = this.g;
    this.g = g;
    pushMatrix();
    viewport.applyTransform(g, g.width, g.height);
    drawRenderView(this);
    popMatrix();
    this.g = prev2;
    g.endDraw();
  }

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

String exportSvg() {
  // Compute inner world rect from render padding
  float worldW = mapModel.maxX - mapModel.minX;
  float worldH = mapModel.maxY - mapModel.minY;
  if (worldW <= 0 || worldH <= 0) return "Failed: invalid world bounds";

  float safePad = constrain(renderPaddingPct, 0, 0.49f);
  float padX = max(0, safePad) * worldW;
  float padY = max(0, safePad) * worldH;
  float innerWX = mapModel.minX + padX;
  float innerWY = mapModel.minY + padY;
  float innerWW = worldW - padX * 2;
  float innerWH = worldH - padY * 2;
  if (innerWW <= 1e-6f || innerWH <= 1e-6f) return "Failed: export padding too large";

  float innerAspect = innerWW / innerWH;
  float safeScale = constrain(exportScale, 0.1f, 8.0f);
  int pxH = max(1, round(max(1, height) * safeScale));
  int pxW = max(1, round(pxH * innerAspect));
  if (pxW <= 0 || pxH <= 0) return "Failed: export size collapsed";

  // Helpers
  float scaleX = pxW / innerWW;
  float scaleY = pxH / innerWH;
  java.text.DecimalFormat df = new java.text.DecimalFormat("0.###");
  java.util.function.Function<Float, String> fmt = (Float v) -> df.format(v);
  java.util.function.Function<String, String> esc = (String v) -> {
    if (v == null) return "";
    return v.replace("&", "&amp;").replace("<", "&lt;").replace("\"", "&quot;");
  };
  java.util.function.Function<Integer, String> toHex = (Integer rgb) -> {
    int r = (rgb >> 16) & 0xFF;
    int g = (rgb >> 8) & 0xFF;
    int b = rgb & 0xFF;
    return String.format("#%02X%02X%02X", r, g, b);
  };
  java.util.function.Function<PVector, PVector> worldToSvg = (PVector w) -> {
    return new PVector((w.x - innerWX) * scaleX, (w.y - innerWY) * scaleY);
  };

  RenderSettings s = renderSettings;
  int landRgb = hsb01ToRGB(s.landHue01, s.landSat01, s.landBri01);
  int waterRgb = hsb01ToRGB(s.waterHue01, s.waterSat01, s.waterBri01);
  String landHex = toHex.apply(landRgb);
  String waterHex = toHex.apply(waterRgb);

  StringBuilder sb = new StringBuilder();
  sb.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
  sb.append("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"").append(pxW)
    .append("\" height=\"").append(pxH).append("\" viewBox=\"0 0 ")
    .append(pxW).append(" ").append(pxH).append("\">\n");
  sb.append("  <style>text{font-family:sans-serif;fill:#000;} .water{fill:")
    .append(waterHex).append(";}</style>\n");

  // Background layer
  sb.append("  <g id=\"background\">\n");
  sb.append("    <rect width=\"").append(pxW).append("\" height=\"").append(pxH)
    .append("\" fill=\"").append(landHex).append("\" />\n");
  sb.append("  </g>\n");

  // Water fill (no stroke)
  sb.append("  <g id=\"water\">\n");
  if (mapModel.cells != null) {
    for (int ci = 0; ci < mapModel.cells.size(); ci++) {
      Cell c = mapModel.cells.get(ci);
      if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
      if (c.elevation >= seaLevel) continue;
      StringBuilder path = new StringBuilder();
      for (int i = 0; i < c.vertices.size(); i++) {
        PVector v = worldToSvg.apply(c.vertices.get(i));
        path.append((i == 0) ? "M " : " L ");
        path.append(fmt.apply(v.x)).append(" ").append(fmt.apply(v.y));
      }
      path.append(" Z");
      sb.append("    <path d=\"").append(path.toString()).append("\" fill=\"").append(waterHex)
        .append("\" stroke=\"none\" class=\"water\" data-cell-id=\"").append(ci).append("\"/>\n");
    }
  }
  sb.append("  </g>\n");

  // Biome fills (no stroke)
  sb.append("  <g id=\"biomes\">\n");
  boolean drawBiomes = mapModel.cells != null && mapModel.biomeTypes != null && mapModel.biomeTypes.size() > 0 &&
                       (s.biomeFillAlpha01 > 1e-4f || s.biomeUnderwaterAlpha01 > 1e-4f);
  if (drawBiomes) {
    for (int ci = 0; ci < mapModel.cells.size(); ci++) {
      Cell c = mapModel.cells.get(ci);
      if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
      boolean isWater = c.elevation < seaLevel;
      float alpha = isWater ? s.biomeUnderwaterAlpha01 : s.biomeFillAlpha01;
      if (alpha <= 1e-4f) continue;
      if (c.biomeId < 0 || c.biomeId >= mapModel.biomeTypes.size()) continue;
      ZoneType zt = mapModel.biomeTypes.get(c.biomeId);
      if (zt == null) continue;
      float[] hsb = mapModel.rgbToHSB(zt.col);
      hsb[1] = constrain(hsb[1] * s.biomeSatScale01, 0, 1);
      int rgb = hsb01ToRGB(hsb[0], hsb[1], hsb[2]);
      String fill = toHex.apply(rgb);
      StringBuilder path = new StringBuilder();
      for (int i = 0; i < c.vertices.size(); i++) {
        PVector v = worldToSvg.apply(c.vertices.get(i));
        path.append((i == 0) ? "M " : " L ");
        path.append(fmt.apply(v.x)).append(" ").append(fmt.apply(v.y));
      }
      path.append(" Z");
      sb.append("    <path d=\"").append(path.toString()).append("\" fill=\"").append(fill)
        .append("\" fill-opacity=\"").append(fmt.apply(alpha)).append("\" stroke=\"none\" class=\"biome biome-")
        .append(c.biomeId).append("\" data-biome-id=\"").append(c.biomeId).append("\" data-cell-id=\"")
        .append(ci).append("\"/>\n");
    }
  }
  sb.append("  </g>\n");

  // Borders layer (world bounds box)
  sb.append("  <g id=\"borders\">\n");
  sb.append("    <rect x=\"0\" y=\"0\" width=\"").append(pxW).append("\" height=\"").append(pxH)
    .append("\" fill=\"none\" stroke=\"#000\" stroke-width=\"1\"/>\n");
  sb.append("  </g>\n");

  // Zones (stroke-only along zone boundaries) when enabled
  sb.append("  <g id=\"zones\">\n");
  if (s.zoneStrokeAlpha01 > 1e-4f && mapModel.zones != null && mapModel.cells != null) {
    for (int zi = 0; zi < mapModel.zones.size(); zi++) {
      MapModel.MapZone z = mapModel.zones.get(zi);
      if (z == null || z.cells == null) continue;
      float[] hsb = mapModel.rgbToHSB(z.col);
      hsb[1] = constrain(hsb[1] * s.zoneStrokeSatScale01, 0, 1);
      hsb[2] = constrain(hsb[2] * s.zoneStrokeBriScale01, 0, 1);
      String stroke = toHex.apply(hsb01ToRGB(hsb[0], hsb[1], hsb[2]));
      for (int ci : z.cells) {
        if (ci < 0 || ci >= mapModel.cells.size()) continue;
        Cell c = mapModel.cells.get(ci);
        if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
        StringBuilder path = new StringBuilder();
        for (int i = 0; i < c.vertices.size(); i++) {
          PVector v = worldToSvg.apply(c.vertices.get(i));
          path.append((i == 0) ? "M " : " L ");
          path.append(fmt.apply(v.x)).append(" ").append(fmt.apply(v.y));
        }
        path.append(" Z");
        sb.append("    <path d=\"").append(path.toString()).append("\" fill=\"none\" stroke=\"").append(stroke)
          .append("\" stroke-width=\"1\" stroke-linejoin=\"round\" stroke-linecap=\"round\" stroke-opacity=\"")
          .append(fmt.apply(s.zoneStrokeAlpha01)).append("\" class=\"zone zone-").append(zi)
          .append("\" data-zone-id=\"").append(zi).append("\" data-comment=\"").append(esc.apply(z.comment != null ? z.comment : "")).append("\"/>\n");
      }
    }
  }
  sb.append("  </g>\n");

  // Coastline stroke (immediate coast)
  sb.append("  <g id=\"coast\">\n");
  ArrayList<PVector[]> coastSegs = mapModel.collectCoastSegments(seaLevel);
  for (PVector[] seg : coastSegs) {
    if (seg == null || seg.length != 2) continue;
    PVector a = worldToSvg.apply(seg[0]);
    PVector b = worldToSvg.apply(seg[1]);
    sb.append("    <line x1=\"").append(fmt.apply(a.x)).append("\" y1=\"").append(fmt.apply(a.y))
      .append("\" x2=\"").append(fmt.apply(b.x)).append("\" y2=\"").append(fmt.apply(b.y))
      .append("\" stroke=\"").append(waterHex).append("\" stroke-width=\"1\" stroke-linecap=\"round\" class=\"coast\"/>\n");
  }
  sb.append("  </g>\n");

  // Paths layer
  sb.append("  <g id=\"paths\">\n");
  if (s.showPaths && mapModel.paths != null) {
    for (int pi = 0; pi < mapModel.paths.size(); pi++) {
      Path p = mapModel.paths.get(pi);
      if (p == null || p.routes == null || p.routes.isEmpty()) continue;
      int typeCount = (mapModel.pathTypes != null) ? mapModel.pathTypes.size() : 0;
      int typeId = constrain(p.typeId, 0, max(0, typeCount - 1));
      int col = (mapModel.pathTypes != null && typeId >= 0 && typeId < typeCount)
        ? mapModel.pathTypes.get(typeId).col : color(80);
      float wPx = (mapModel.pathTypes != null && typeId >= 0 && typeId < typeCount)
        ? mapModel.pathTypes.get(typeId).weightPx : 2.0f;
      String stroke = toHex.apply(col);
      String name = (p.name != null && p.name.length() > 0) ? p.name : "Path";
      for (int ri = 0; ri < p.routes.size(); ri++) {
        ArrayList<PVector> route = p.routes.get(ri);
        if (route == null || route.size() < 2) continue;
        StringBuilder pts = new StringBuilder();
        for (PVector v : route) {
          PVector spt = worldToSvg.apply(v);
          if (pts.length() > 0) pts.append(" ");
          pts.append(fmt.apply(spt.x)).append(",").append(fmt.apply(spt.y));
        }
        sb.append("    <polyline points=\"").append(pts.toString()).append("\" fill=\"none\" stroke=\"")
          .append(stroke).append("\" stroke-width=\"").append(fmt.apply(wPx))
          .append("\" stroke-linecap=\"round\" stroke-linejoin=\"round\" class=\"path type-")
          .append(typeId).append("\" data-type-id=\"").append(typeId)
          .append("\" data-path-id=\"").append(pi).append("\" data-name=\"")
          .append(esc.apply(name)).append("\" data-comment=\"").append(esc.apply(p.comment != null ? p.comment : ""))
          .append("\"/>\n");
      }
    }
  }
  sb.append("  </g>\n");

  // Structures layer
  sb.append("  <g id=\"structures\">\n");
  if (s.showStructures && mapModel.structures != null) {
    for (int si = 0; si < mapModel.structures.size(); si++) {
      Structure st = mapModel.structures.get(si);
      if (st == null) continue;
      PVector sp = worldToSvg.apply(new PVector(st.x, st.y));
      float sizePx = st.size * scaleX;
      float strokePx = st.strokeWeightPx;
      int rgb = st.fillCol;
      String fill = toHex.apply(rgb);
      String name = (st.name != null && st.name.length() > 0) ? st.name : "Structure";
      float angleDeg = degrees(st.angle);
      sb.append("    <g transform=\"translate(").append(fmt.apply(sp.x)).append(",").append(fmt.apply(sp.y))
        .append(") rotate(").append(fmt.apply(angleDeg)).append(")\" class=\"structure type-")
        .append(st.typeId).append("\" data-type-id=\"").append(st.typeId)
        .append("\" data-structure-id=\"").append(si).append("\" data-name=\"").append(esc.apply(name))
        .append("\" data-comment=\"").append(esc.apply(st.comment != null ? st.comment : "")).append("\">");
      switch (st.shape) {
        case RECTANGLE: {
          float w = sizePx;
          float h = (st.aspect != 0) ? (sizePx / max(0.1f, st.aspect)) : sizePx;
          sb.append("<rect x=\"").append(fmt.apply(-w * 0.5f)).append("\" y=\"").append(fmt.apply(-h * 0.5f))
            .append("\" width=\"").append(fmt.apply(w)).append("\" height=\"").append(fmt.apply(h))
            .append("\" fill=\"").append(fill).append("\" fill-opacity=\"").append(fmt.apply(st.alpha01))
            .append("\" stroke=\"#000\" stroke-width=\"").append(fmt.apply(strokePx)).append("\"/>");
          break;
        }
        case CIRCLE: {
          sb.append("<circle cx=\"0\" cy=\"0\" r=\"").append(fmt.apply(sizePx * 0.5f))
            .append("\" fill=\"").append(fill).append("\" fill-opacity=\"").append(fmt.apply(st.alpha01))
            .append("\" stroke=\"#000\" stroke-width=\"").append(fmt.apply(strokePx)).append("\"/>");
          break;
        }
        case TRIANGLE: {
          float r = sizePx;
          float h = r * 0.866f;
          sb.append("<polygon points=\"")
            .append(fmt.apply(-r * 0.5f)).append(",").append(fmt.apply(h * 0.333f)).append(" ")
            .append(fmt.apply(r * 0.5f)).append(",").append(fmt.apply(h * 0.333f)).append(" ")
            .append(fmt.apply(0f)).append(",").append(fmt.apply(-h * 0.666f))
            .append("\" fill=\"").append(fill).append("\" fill-opacity=\"").append(fmt.apply(st.alpha01))
            .append("\" stroke=\"#000\" stroke-width=\"").append(fmt.apply(strokePx)).append("\"/>");
          break;
        }
        case HEXAGON: {
          float rad = sizePx * 0.5f;
          StringBuilder pts = new StringBuilder();
          for (int v = 0; v < 6; v++) {
            float a = radians(60 * v);
            float vx = cos(a) * rad;
            float vy = sin(a) * rad;
            if (pts.length() > 0) pts.append(" ");
            pts.append(fmt.apply(vx)).append(",").append(fmt.apply(vy));
          }
          sb.append("<polygon points=\"").append(pts.toString()).append("\" fill=\"").append(fill)
            .append("\" fill-opacity=\"").append(fmt.apply(st.alpha01))
            .append("\" stroke=\"#000\" stroke-width=\"").append(fmt.apply(strokePx)).append("\"/>");
          break;
        }
        default: {
          float w = sizePx;
          float h = sizePx;
          sb.append("<rect x=\"").append(fmt.apply(-w * 0.5f)).append("\" y=\"").append(fmt.apply(-h * 0.5f))
            .append("\" width=\"").append(fmt.apply(w)).append("\" height=\"").append(fmt.apply(h))
            .append("\" fill=\"").append(fill).append("\" fill-opacity=\"").append(fmt.apply(st.alpha01))
            .append("\" stroke=\"#000\" stroke-width=\"").append(fmt.apply(strokePx)).append("\"/>");
          break;
        }
      }
      sb.append("</g>\n");
    }
  }
  sb.append("  </g>\n");

  // Labels layer
  sb.append("  <g id=\"labels\">\n");
  float baseLabelSize = labelSizeDefault();
  if (s.showLabelsZones && mapModel.zones != null) {
    for (MapModel.MapZone z : mapModel.zones) {
      if (z == null || z.cells == null || z.cells.isEmpty()) continue;
      float cx = 0, cy = 0; int count = 0;
      for (int ci : z.cells) {
        if (ci < 0 || ci >= mapModel.cells.size()) continue;
        Cell c = mapModel.cells.get(ci);
        if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
        PVector cen = mapModel.cellCentroid(c);
        cx += cen.x; cy += cen.y; count++;
      }
      if (count <= 0) continue;
      cx /= count; cy /= count;
      PVector sp = worldToSvg.apply(new PVector(cx, cy));
      String name = (z.name != null && z.name.length() > 0) ? z.name : "Zone";
      sb.append("    <text x=\"").append(fmt.apply(sp.x)).append("\" y=\"").append(fmt.apply(sp.y))
        .append("\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-size=\"")
        .append(fmt.apply(baseLabelSize)).append("\" class=\"label zone\" data-name=\"")
        .append(esc.apply(name)).append("\" data-comment=\"").append(esc.apply(z.comment != null ? z.comment : ""))
        .append("\">").append(esc.apply(name)).append("</text>\n");
    }
  }
  if (s.showLabelsPaths && mapModel.paths != null) {
    for (int pi = 0; pi < mapModel.paths.size(); pi++) {
      Path p = mapModel.paths.get(pi);
      if (p == null || p.routes == null || p.routes.isEmpty()) continue;
      String txt = (p.name != null && p.name.length() > 0) ? p.name : "Path";
      PVector bestA = null, bestB = null;
      float bestLenSq = -1;
      for (ArrayList<PVector> route : p.routes) {
        if (route == null || route.size() < 2) continue;
        for (int i = 0; i < route.size() - 1; i++) {
          PVector a = route.get(i);
          PVector b = route.get(i + 1);
          float dx = b.x - a.x;
          float dy = b.y - a.y;
          float lenSq = dx * dx + dy * dy;
          if (lenSq > bestLenSq) {
            bestLenSq = lenSq;
            bestA = a;
            bestB = b;
          }
        }
      }
      if (bestA == null || bestB == null || bestLenSq <= 1e-8f) continue;
      float angle = degrees(atan2(bestB.y - bestA.y, bestB.x - bestA.x));
      if (angle > 90 || angle < -90) angle += 180;
      float mx = (bestA.x + bestB.x) * 0.5f;
      float my = (bestA.y + bestB.y) * 0.5f;
      PVector sp = worldToSvg.apply(new PVector(mx, my));
      sb.append("    <text x=\"").append(fmt.apply(sp.x)).append("\" y=\"").append(fmt.apply(sp.y))
        .append("\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-size=\"")
        .append(fmt.apply(baseLabelSize)).append("\" transform=\"rotate(").append(fmt.apply(angle))
        .append(" ").append(fmt.apply(sp.x)).append(" ").append(fmt.apply(sp.y))
        .append(")\" class=\"label path\" data-path-id=\"").append(pi).append("\" data-name=\"")
        .append(esc.apply(txt)).append("\" data-comment=\"").append(esc.apply(p.comment != null ? p.comment : ""))
        .append("\">").append(esc.apply(txt)).append("</text>\n");
    }
  }
  if (s.showLabelsStructures && mapModel.structures != null) {
    for (int si = 0; si < mapModel.structures.size(); si++) {
      Structure st = mapModel.structures.get(si);
      if (st == null) continue;
      String txt = (st.name != null && st.name.length() > 0) ? st.name : "Structure";
      PVector sp = worldToSvg.apply(new PVector(st.x, st.y));
      sb.append("    <text x=\"").append(fmt.apply(sp.x)).append("\" y=\"").append(fmt.apply(sp.y))
        .append("\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-size=\"")
        .append(fmt.apply(baseLabelSize)).append("\" class=\"label structure\" data-structure-id=\"")
        .append(si).append("\" data-name=\"").append(esc.apply(txt)).append("\" data-comment=\"")
        .append(esc.apply(st.comment != null ? st.comment : "")).append("\">")
        .append(esc.apply(txt)).append("</text>\n");
    }
  }
  if (s.showLabelsArbitrary && mapModel.labels != null) {
    for (int li = 0; li < mapModel.labels.size(); li++) {
      MapLabel l = mapModel.labels.get(li);
      if (l == null || l.text == null || l.text.length() == 0) continue;
      PVector sp = worldToSvg.apply(new PVector(l.x, l.y));
      sb.append("    <text x=\"").append(fmt.apply(sp.x)).append("\" y=\"").append(fmt.apply(sp.y))
        .append("\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-size=\"")
        .append(fmt.apply(l.size)).append("\" class=\"label arbitrary\" data-label-id=\"")
        .append(li).append("\" data-comment=\"").append(esc.apply(l.comment != null ? l.comment : ""))
        .append("\">").append(esc.apply(l.text)).append("</text>\n");
    }
  }
  sb.append("  </g>\n");

  // Legend layer (simple text lists)
  sb.append("  <g id=\"legend\">\n");
  float legendX = 12;
  float legendY = 18;
  sb.append("    <text x=\"").append(fmt.apply(legendX)).append("\" y=\"").append(fmt.apply(legendY))
    .append("\" font-size=\"12\" text-anchor=\"start\" dominant-baseline=\"hanging\">Legend</text>\n");
  legendY += 16;
  if (mapModel.pathTypes != null) {
    for (int i = 0; i < mapModel.pathTypes.size(); i++) {
      PathType pt = mapModel.pathTypes.get(i);
      if (pt == null) continue;
      sb.append("    <text x=\"").append(fmt.apply(legendX)).append("\" y=\"").append(fmt.apply(legendY))
        .append("\" font-size=\"11\" text-anchor=\"start\" dominant-baseline=\"hanging\" class=\"legend-path type-")
        .append(i).append("\" data-type-id=\"").append(i).append("\">Path type ").append(i).append(": ")
        .append(esc.apply(pt.name != null ? pt.name : "")).append("</text>\n");
      legendY += 14;
    }
  }
  if (mapModel.structures != null && !mapModel.structures.isEmpty()) {
    sb.append("    <text x=\"").append(fmt.apply(legendX)).append("\" y=\"").append(fmt.apply(legendY))
      .append("\" font-size=\"12\" text-anchor=\"start\" dominant-baseline=\"hanging\">Structures</text>\n");
    legendY += 14;
    for (int i = 0; i < mapModel.structures.size(); i++) {
      Structure st = mapModel.structures.get(i);
      if (st == null) continue;
      sb.append("    <text x=\"").append(fmt.apply(legendX)).append("\" y=\"").append(fmt.apply(legendY))
        .append("\" font-size=\"11\" text-anchor=\"start\" dominant-baseline=\"hanging\" class=\"legend-structure type-")
        .append(st.typeId).append("\" data-type-id=\"").append(st.typeId).append("\" data-structure-id=\"")
        .append(i).append("\">").append(esc.apply(st.name != null ? st.name : "Structure")).append("</text>\n");
      legendY += 14;
    }
  }
  sb.append("  </g>\n");

  sb.append("</svg>\n");

  String dir = "exports";
  java.io.File folder = new java.io.File(dir);
  folder.mkdirs();
  String ts = nf(year(), 4, 0) + nf(month(), 2, 0) + nf(day(), 2, 0) + "_" +
              nf(hour(), 2, 0) + nf(minute(), 2, 0) + nf(second(), 2, 0);
  String path = dir + java.io.File.separator + "map_" + ts + ".svg";
  PrintWriter writer = createWriter(path);
  writer.print(sb.toString());
  writer.flush();
  writer.close();
  return path;
}

String exportMapJson() {
  try {
    JSONObject root = new JSONObject();

    JSONObject meta = new JSONObject();
    meta.setInt("schemaVersion", 1);
    meta.setString("savedAt", new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(new java.util.Date()));
    root.setJSONObject("meta", meta);

    JSONObject view = new JSONObject();
    view.setFloat("centerX", viewport.centerX);
    view.setFloat("centerY", viewport.centerY);
    view.setFloat("zoom", viewport.zoom);
    root.setJSONObject("view", view);

    JSONObject settings = new JSONObject();
    settings.setJSONObject("render", serializeRenderSettings(renderSettings));
    root.setJSONObject("settings", settings);

    JSONObject types = new JSONObject();
    types.setJSONArray("pathTypes", serializePathTypes(mapModel.pathTypes));
    types.setJSONArray("biomeTypes", serializeZoneTypes(mapModel.biomeTypes));
    root.setJSONObject("types", types);

    root.setJSONArray("sites", serializeSites(mapModel.sites));
    root.setJSONArray("cells", serializeCells(mapModel.cells));
    root.setJSONArray("zones", serializeZones(mapModel.zones));
    root.setJSONArray("paths", serializePaths(mapModel.paths));
    root.setJSONArray("structures", serializeStructures(mapModel.structures));
    root.setJSONArray("labels", serializeLabels(mapModel.labels));

    File dir = new File(sketchPath("exports"));
    if (!dir.exists()) dir.mkdirs();
    String ts = nf(year(), 4, 0) + nf(month(), 2, 0) + nf(day(), 2, 0) + "_" +
                nf(hour(), 2, 0) + nf(minute(), 2, 0) + nf(second(), 2, 0);
    File target = new File(dir, "map_" + ts + ".json");
    File latest = new File(dir, "map_latest.json");
    saveJSONObject(root, target.getAbsolutePath());
    saveJSONObject(root, latest.getAbsolutePath());
    return target.getAbsolutePath();
  } catch (Exception e) {
    e.printStackTrace();
    return "Failed: " + e.getMessage();
  }
}

String importMapJson() {
  try {
    File latest = new File(sketchPath("exports"), "map_latest.json");
    if (!latest.exists()) return "Failed: exports/map_latest.json not found";
    JSONObject root = loadJSONObject(latest.getAbsolutePath());
    if (root == null) return "Failed: invalid JSON";

    if (root.hasKey("types")) {
      JSONObject types = root.getJSONObject("types");
      mapModel.pathTypes = deserializePathTypes(types.getJSONArray("pathTypes"));
      mapModel.biomeTypes = deserializeZoneTypes(types.getJSONArray("biomeTypes"));
    }

    if (root.hasKey("sites")) mapModel.sites = deserializeSites(root.getJSONArray("sites"));
    if (root.hasKey("cells")) mapModel.cells = deserializeCells(root.getJSONArray("cells"));
    if (root.hasKey("zones")) mapModel.zones = deserializeZones(root.getJSONArray("zones"));
    if (root.hasKey("paths")) mapModel.paths = deserializePaths(root.getJSONArray("paths"));
    if (root.hasKey("structures")) mapModel.structures = deserializeStructures(root.getJSONArray("structures"));
    if (root.hasKey("labels")) mapModel.labels = deserializeLabels(root.getJSONArray("labels"));
    mapModel.cellNeighbors = new ArrayList<ArrayList<Integer>>();
    mapModel.snapNodes = new HashMap<String, PVector>();
    mapModel.snapAdj = new HashMap<String, ArrayList<String>>();

    if (root.hasKey("settings")) {
      JSONObject settings = root.getJSONObject("settings");
      if (settings.hasKey("render")) applyRenderSettingsFromJson(settings.getJSONObject("render"), renderSettings);
    }

    if (root.hasKey("view")) {
      JSONObject view = root.getJSONObject("view");
      viewport.centerX = view.getFloat("centerX", viewport.centerX);
      viewport.centerY = view.getFloat("centerY", viewport.centerY);
      viewport.zoom = view.getFloat("zoom", viewport.zoom);
    }

    recomputeWorldBoundsFromData();
    mapModel.snapDirty = true;
    mapModel.voronoiDirty = false;
    selectedPathIndex = -1;
    return latest.getAbsolutePath();
  } catch (Exception e) {
    e.printStackTrace();
    return "Failed: " + e.getMessage();
  }
}

JSONObject serializeRenderSettings(RenderSettings s) {
  JSONObject r = new JSONObject();
  r.setFloat("landHue01", s.landHue01);
  r.setFloat("landSat01", s.landSat01);
  r.setFloat("landBri01", s.landBri01);
  r.setFloat("waterHue01", s.waterHue01);
  r.setFloat("waterSat01", s.waterSat01);
  r.setFloat("waterBri01", s.waterBri01);
  r.setFloat("cellBorderAlpha01", s.cellBorderAlpha01);
  r.setFloat("backgroundNoiseAlpha01", s.backgroundNoiseAlpha01);

  JSONObject biomes = new JSONObject();
  biomes.setFloat("fillAlpha01", s.biomeFillAlpha01);
  biomes.setFloat("satScale01", s.biomeSatScale01);
  biomes.setString("fillType", (s.biomeFillType == RenderFillType.RENDER_FILL_PATTERN) ? "pattern" : "color");
  biomes.setString("patternName", s.biomePatternName);
  biomes.setFloat("outlineSizePx", s.biomeOutlineSizePx);
  biomes.setFloat("outlineAlpha01", s.biomeOutlineAlpha01);
  biomes.setFloat("underwaterAlpha01", s.biomeUnderwaterAlpha01);
  r.setJSONObject("biomes", biomes);

  JSONObject shading = new JSONObject();
  shading.setFloat("waterDepthAlpha01", s.waterDepthAlpha01);
  shading.setFloat("elevationLightAlpha01", s.elevationLightAlpha01);
  shading.setFloat("elevationLightAzimuthDeg", s.elevationLightAzimuthDeg);
  shading.setFloat("elevationLightAltitudeDeg", s.elevationLightAltitudeDeg);
  r.setJSONObject("shading", shading);

  JSONObject contours = new JSONObject();
  contours.setFloat("waterContourSizePx", s.waterContourSizePx);
  contours.setInt("waterRippleCount", s.waterRippleCount);
  contours.setFloat("waterRippleDistancePx", s.waterRippleDistancePx);
  contours.setFloat("waterContourHue01", s.waterContourHue01);
  contours.setFloat("waterContourSat01", s.waterContourSat01);
  contours.setFloat("waterContourBri01", s.waterContourBri01);
  contours.setFloat("waterContourAlpha01", s.waterCoastAlpha01);
  contours.setFloat("waterCoastAlpha01", s.waterCoastAlpha01);
  contours.setFloat("waterRippleAlphaStart01", s.waterRippleAlphaStart01);
  contours.setFloat("waterRippleAlphaEnd01", s.waterRippleAlphaEnd01);
  contours.setInt("elevationLinesCount", s.elevationLinesCount);
  contours.setString("elevationLinesStyle", s.elevationLinesStyle.name());
  contours.setFloat("elevationLinesAlpha01", s.elevationLinesAlpha01);
  r.setJSONObject("contours", contours);

  JSONObject paths = new JSONObject();
  paths.setFloat("pathSatScale01", s.pathSatScale01);
  paths.setBoolean("showPaths", s.showPaths);
  r.setJSONObject("paths", paths);

  JSONObject zones = new JSONObject();
  zones.setFloat("zoneStrokeAlpha01", s.zoneStrokeAlpha01);
  zones.setFloat("zoneStrokeSatScale01", s.zoneStrokeSatScale01);
  zones.setFloat("zoneStrokeBriScale01", s.zoneStrokeBriScale01);
  r.setJSONObject("zones", zones);

  JSONObject structures = new JSONObject();
  structures.setBoolean("showStructures", s.showStructures);
  structures.setBoolean("mergeStructures", s.mergeStructures);
  structures.setFloat("structureSatScale01", s.structureSatScale01);
  structures.setFloat("structureAlphaScale01", s.structureAlphaScale01);
  structures.setFloat("structureShadowAlpha01", s.structureShadowAlpha01);
  r.setJSONObject("structures", structures);

  JSONObject labels = new JSONObject();
  labels.setBoolean("showLabelsArbitrary", s.showLabelsArbitrary);
  labels.setBoolean("showLabelsZones", s.showLabelsZones);
  labels.setBoolean("showLabelsPaths", s.showLabelsPaths);
  labels.setBoolean("showLabelsStructures", s.showLabelsStructures);
  labels.setFloat("labelOutlineAlpha01", s.labelOutlineAlpha01);
  r.setJSONObject("labels", labels);

  JSONObject general = new JSONObject();
  general.setFloat("exportPaddingPct", s.exportPaddingPct);
  general.setBoolean("antialiasing", s.antialiasing);
  general.setInt("activePresetIndex", s.activePresetIndex);
  r.setJSONObject("general", general);

  return r;
}

void applyRenderSettingsFromJson(JSONObject r, RenderSettings target) {
  if (r == null || target == null) return;
  target.landHue01 = r.getFloat("landHue01", target.landHue01);
  target.landSat01 = r.getFloat("landSat01", target.landSat01);
  target.landBri01 = r.getFloat("landBri01", target.landBri01);
  target.waterHue01 = r.getFloat("waterHue01", target.waterHue01);
  target.waterSat01 = r.getFloat("waterSat01", target.waterSat01);
  target.waterBri01 = r.getFloat("waterBri01", target.waterBri01);
  target.cellBorderAlpha01 = r.getFloat("cellBorderAlpha01", target.cellBorderAlpha01);
  target.backgroundNoiseAlpha01 = r.getFloat("backgroundNoiseAlpha01", target.backgroundNoiseAlpha01);

  if (r.hasKey("biomes")) {
    JSONObject b = r.getJSONObject("biomes");
    target.biomeFillAlpha01 = b.getFloat("fillAlpha01", target.biomeFillAlpha01);
    target.biomeSatScale01 = b.getFloat("satScale01", target.biomeSatScale01);
    target.biomeFillType = "pattern".equals(b.getString("fillType", "color"))
      ? RenderFillType.RENDER_FILL_PATTERN
      : RenderFillType.RENDER_FILL_COLOR;
    target.biomePatternName = b.getString("patternName", target.biomePatternName);
    target.biomeOutlineSizePx = b.getFloat("outlineSizePx", target.biomeOutlineSizePx);
    target.biomeOutlineAlpha01 = b.getFloat("outlineAlpha01", target.biomeOutlineAlpha01);
    target.biomeUnderwaterAlpha01 = b.getFloat("underwaterAlpha01", target.biomeUnderwaterAlpha01);
  }

  if (r.hasKey("shading")) {
    JSONObject b = r.getJSONObject("shading");
    target.waterDepthAlpha01 = b.getFloat("waterDepthAlpha01", target.waterDepthAlpha01);
    target.elevationLightAlpha01 = b.getFloat("elevationLightAlpha01", target.elevationLightAlpha01);
    target.elevationLightAzimuthDeg = b.getFloat("elevationLightAzimuthDeg", target.elevationLightAzimuthDeg);
    target.elevationLightAltitudeDeg = b.getFloat("elevationLightAltitudeDeg", target.elevationLightAltitudeDeg);
  }

  if (r.hasKey("contours")) {
    JSONObject b = r.getJSONObject("contours");
    target.waterContourSizePx = b.getFloat("waterContourSizePx", target.waterContourSizePx);
    target.waterRippleCount = b.getInt("waterRippleCount", target.waterRippleCount);
    target.waterRippleDistancePx = b.getFloat("waterRippleDistancePx", target.waterRippleDistancePx);
    target.waterContourHue01 = b.getFloat("waterContourHue01", target.waterContourHue01);
    target.waterContourSat01 = b.getFloat("waterContourSat01", target.waterContourSat01);
    target.waterContourBri01 = b.getFloat("waterContourBri01", target.waterContourBri01);
    target.waterContourAlpha01 = b.getFloat("waterContourAlpha01", target.waterContourAlpha01);
    target.waterCoastAlpha01 = b.getFloat("waterCoastAlpha01", target.waterContourAlpha01);
    target.waterRippleAlphaStart01 = b.getFloat("waterRippleAlphaStart01", target.waterContourAlpha01);
    target.waterRippleAlphaEnd01 = b.getFloat("waterRippleAlphaEnd01", target.waterRippleAlphaStart01);
    target.waterContourAlpha01 = target.waterCoastAlpha01; // keep legacy field in sync
    target.elevationLinesCount = b.getInt("elevationLinesCount", target.elevationLinesCount);
    String style = b.getString("elevationLinesStyle", target.elevationLinesStyle.name());
    target.elevationLinesStyle = "ELEV_LINES_BASIC".equals(style) ? ElevationLinesStyle.ELEV_LINES_BASIC : target.elevationLinesStyle;
    target.elevationLinesAlpha01 = b.getFloat("elevationLinesAlpha01", target.elevationLinesAlpha01);
  }

  if (r.hasKey("paths")) {
    JSONObject b = r.getJSONObject("paths");
    target.pathSatScale01 = b.getFloat("pathSatScale01", target.pathSatScale01);
    target.showPaths = b.getBoolean("showPaths", target.showPaths);
  }

  if (r.hasKey("zones")) {
    JSONObject b = r.getJSONObject("zones");
    target.zoneStrokeAlpha01 = b.getFloat("zoneStrokeAlpha01", target.zoneStrokeAlpha01);
    target.zoneStrokeSatScale01 = b.getFloat("zoneStrokeSatScale01", target.zoneStrokeSatScale01);
    target.zoneStrokeBriScale01 = b.getFloat("zoneStrokeBriScale01", target.zoneStrokeBriScale01);
  }

  if (r.hasKey("structures")) {
    JSONObject b = r.getJSONObject("structures");
    target.showStructures = b.getBoolean("showStructures", target.showStructures);
    target.mergeStructures = b.getBoolean("mergeStructures", target.mergeStructures);
    target.structureSatScale01 = b.getFloat("structureSatScale01", target.structureSatScale01);
    target.structureAlphaScale01 = b.getFloat("structureAlphaScale01", target.structureAlphaScale01);
    target.structureShadowAlpha01 = b.getFloat("structureShadowAlpha01", target.structureShadowAlpha01);
  }

  if (r.hasKey("labels")) {
    JSONObject b = r.getJSONObject("labels");
    target.showLabelsArbitrary = b.getBoolean("showLabelsArbitrary", target.showLabelsArbitrary);
    target.showLabelsZones = b.getBoolean("showLabelsZones", target.showLabelsZones);
    target.showLabelsPaths = b.getBoolean("showLabelsPaths", target.showLabelsPaths);
    target.showLabelsStructures = b.getBoolean("showLabelsStructures", target.showLabelsStructures);
    target.labelOutlineAlpha01 = b.getFloat("labelOutlineAlpha01", target.labelOutlineAlpha01);
  }

  if (r.hasKey("general")) {
    JSONObject b = r.getJSONObject("general");
    target.exportPaddingPct = b.getFloat("exportPaddingPct", target.exportPaddingPct);
    target.antialiasing = b.getBoolean("antialiasing", target.antialiasing);
    target.activePresetIndex = b.getInt("activePresetIndex", target.activePresetIndex);
    renderPaddingPct = target.exportPaddingPct;
  }
}

JSONArray serializePathTypes(ArrayList<PathType> list) {
  JSONArray arr = new JSONArray();
  if (list == null) return arr;
  for (int i = 0; i < list.size(); i++) {
    PathType t = list.get(i);
    if (t == null) continue;
    JSONObject o = new JSONObject();
    o.setInt("id", i);
    o.setString("name", t.name);
    o.setInt("col", t.col);
    o.setFloat("hue01", t.hue01);
    o.setFloat("sat01", t.sat01);
    o.setFloat("bri01", t.bri01);
    o.setFloat("weightPx", t.weightPx);
    o.setFloat("minWeightPx", t.minWeightPx);
    o.setString("routeMode", t.routeMode.name());
    o.setFloat("slopeBias", t.slopeBias);
    o.setBoolean("avoidWater", t.avoidWater);
    o.setBoolean("taperOn", t.taperOn);
    arr.append(o);
  }
  return arr;
}

JSONArray serializeZoneTypes(ArrayList<ZoneType> list) {
  JSONArray arr = new JSONArray();
  if (list == null) return arr;
  for (int i = 0; i < list.size(); i++) {
    ZoneType z = list.get(i);
    if (z == null) continue;
    JSONObject o = new JSONObject();
    o.setInt("id", i);
    o.setString("name", z.name);
    o.setInt("col", z.col);
    o.setFloat("hue01", z.hue01);
    o.setFloat("sat01", z.sat01);
    o.setFloat("bri01", z.bri01);
    arr.append(o);
  }
  return arr;
}

JSONArray serializeSites(ArrayList<Site> list) {
  JSONArray arr = new JSONArray();
  if (list == null) return arr;
  for (int i = 0; i < list.size(); i++) {
    Site s = list.get(i);
    if (s == null) continue;
    JSONObject o = new JSONObject();
    o.setInt("id", i);
    o.setFloat("x", s.x);
    o.setFloat("y", s.y);
    o.setBoolean("selected", s.selected);
    arr.append(o);
  }
  return arr;
}

JSONArray serializeCells(ArrayList<Cell> list) {
  JSONArray arr = new JSONArray();
  if (list == null) return arr;
  for (int i = 0; i < list.size(); i++) {
    Cell c = list.get(i);
    if (c == null) continue;
    JSONObject o = new JSONObject();
    o.setInt("id", i);
    o.setInt("siteIndex", c.siteIndex);
    o.setInt("biomeId", c.biomeId);
    o.setFloat("elevation", c.elevation);
    JSONArray verts = new JSONArray();
    if (c.vertices != null) {
      for (PVector v : c.vertices) {
        JSONObject pv = new JSONObject();
        pv.setFloat("x", v.x);
        pv.setFloat("y", v.y);
        verts.append(pv);
      }
    }
    o.setJSONArray("vertices", verts);
    arr.append(o);
  }
  return arr;
}

JSONArray serializeZones(ArrayList<MapModel.MapZone> list) {
  JSONArray arr = new JSONArray();
  if (list == null) return arr;
  for (int i = 0; i < list.size(); i++) {
    MapModel.MapZone z = list.get(i);
    if (z == null) continue;
    JSONObject o = new JSONObject();
    o.setInt("id", i);
    o.setString("name", z.name);
    o.setString("comment", (z.comment != null) ? z.comment : "");
    o.setInt("col", z.col);
    o.setFloat("hue01", z.hue01);
    o.setFloat("sat01", z.sat01);
    o.setFloat("bri01", z.bri01);
    JSONArray cellsArr = new JSONArray();
    if (z.cells != null) {
      for (Integer ci : z.cells) cellsArr.append(ci);
    }
    o.setJSONArray("cells", cellsArr);
    arr.append(o);
  }
  return arr;
}

JSONArray serializePaths(ArrayList<Path> list) {
  JSONArray arr = new JSONArray();
  if (list == null) return arr;
  for (int i = 0; i < list.size(); i++) {
    Path p = list.get(i);
    if (p == null) continue;
    JSONObject o = new JSONObject();
    o.setInt("id", i);
    o.setInt("typeId", p.typeId);
    o.setString("name", p.name);
    o.setString("comment", (p.comment != null) ? p.comment : "");
    JSONArray routes = new JSONArray();
    if (p.routes != null) {
      for (ArrayList<PVector> seg : p.routes) {
        JSONArray pts = new JSONArray();
        if (seg != null) {
          for (PVector v : seg) {
            JSONObject pv = new JSONObject();
            pv.setFloat("x", v.x);
            pv.setFloat("y", v.y);
            pts.append(pv);
          }
        }
        routes.append(pts);
      }
    }
    o.setJSONArray("routes", routes);
    arr.append(o);
  }
  return arr;
}

JSONArray serializeStructures(ArrayList<Structure> list) {
  JSONArray arr = new JSONArray();
  if (list == null) return arr;
  for (int i = 0; i < list.size(); i++) {
    Structure s = list.get(i);
    if (s == null) continue;
    JSONObject o = new JSONObject();
    o.setInt("id", i);
    o.setInt("typeId", s.typeId);
    o.setString("name", s.name);
    o.setString("comment", (s.comment != null) ? s.comment : "");
    o.setFloat("x", s.x);
    o.setFloat("y", s.y);
    o.setFloat("angle", s.angle);
    o.setFloat("size", s.size);
    o.setString("shape", s.shape.name());
    o.setString("alignment", s.alignment.name());
    o.setFloat("aspect", s.aspect);
    o.setFloat("hue01", s.hue01);
    o.setFloat("sat01", s.sat01);
    o.setFloat("bri01", s.bri01);
    o.setFloat("alpha01", s.alpha01);
    o.setFloat("strokeWeightPx", s.strokeWeightPx);
    o.setInt("fillCol", s.fillCol);
    if (s.snapBinding != null) {
      o.setString("snapTargetType", s.snapBinding.type.name());
      o.setInt("snapPathIndex", s.snapBinding.pathIndex);
      o.setInt("snapRouteIndex", s.snapBinding.routeIndex);
      o.setInt("snapSegmentIndex", s.snapBinding.segmentIndex);
      o.setInt("snapStructureIndex", s.snapBinding.structureIndex);
      o.setInt("snapCellA", s.snapBinding.cellA);
      o.setInt("snapCellB", s.snapBinding.cellB);
      o.setFloat("snapAngleRad", s.snapBinding.snapAngleRad);
      if (s.snapBinding.snapPoint != null) {
        o.setFloat("snapPointX", s.snapBinding.snapPoint.x);
        o.setFloat("snapPointY", s.snapBinding.snapPoint.y);
      }
      if (s.snapBinding.segA != null) {
        o.setFloat("snapSegAx", s.snapBinding.segA.x);
        o.setFloat("snapSegAy", s.snapBinding.segA.y);
      }
      if (s.snapBinding.segB != null) {
        o.setFloat("snapSegBx", s.snapBinding.segB.x);
        o.setFloat("snapSegBy", s.snapBinding.segB.y);
      }
    }
    arr.append(o);
  }
  return arr;
}

JSONArray serializeLabels(ArrayList<MapLabel> list) {
  JSONArray arr = new JSONArray();
  if (list == null) return arr;
  for (int i = 0; i < list.size(); i++) {
    MapLabel l = list.get(i);
    if (l == null) continue;
    JSONObject o = new JSONObject();
    o.setInt("id", i);
    o.setFloat("x", l.x);
    o.setFloat("y", l.y);
    o.setString("text", (l.text != null) ? l.text : "");
    o.setString("target", l.target.name());
    o.setFloat("size", l.size);
    o.setString("comment", (l.comment != null) ? l.comment : "");
    arr.append(o);
  }
  return arr;
}

ArrayList<PathType> deserializePathTypes(JSONArray arr) {
  ArrayList<PathType> list = new ArrayList<PathType>();
  if (arr == null) return list;
  for (int i = 0; i < arr.size(); i++) {
    JSONObject o = arr.getJSONObject(i);
    if (o == null) continue;
    String name = o.getString("name", "Path");
    int col = o.getInt("col", color(80));
    float weight = o.getFloat("weightPx", 2.0f);
    float minWeight = o.getFloat("minWeightPx", weight * 0.6f);
    String mode = o.getString("routeMode", PathRouteMode.PATHFIND.name());
    PathRouteMode rm = mode.equals(PathRouteMode.ENDS.name()) ? PathRouteMode.ENDS : PathRouteMode.PATHFIND;
    float slope = o.getFloat("slopeBias", 0.0f);
    boolean avoidWater = o.getBoolean("avoidWater", true);
    boolean taper = o.getBoolean("taperOn", false);
    PathType pt = new PathType(name, col, weight, minWeight, rm, slope, avoidWater, taper);
    list.add(pt);
  }
  return list;
}

ArrayList<ZoneType> deserializeZoneTypes(JSONArray arr) {
  ArrayList<ZoneType> list = new ArrayList<ZoneType>();
  if (arr == null) return list;
  for (int i = 0; i < arr.size(); i++) {
    JSONObject o = arr.getJSONObject(i);
    if (o == null) continue;
    String name = o.getString("name", "Zone");
    int col = o.getInt("col", color(200));
    ZoneType z = new ZoneType(name, col);
    z.hue01 = o.getFloat("hue01", z.hue01);
    z.sat01 = o.getFloat("sat01", z.sat01);
    z.bri01 = o.getFloat("bri01", z.bri01);
    z.updateColorFromHSB();
    list.add(z);
  }
  return list;
}

ArrayList<Site> deserializeSites(JSONArray arr) {
  ArrayList<Site> list = new ArrayList<Site>();
  if (arr == null) return list;
  for (int i = 0; i < arr.size(); i++) {
    JSONObject o = arr.getJSONObject(i);
    if (o == null) continue;
    float x = o.getFloat("x", 0);
    float y = o.getFloat("y", 0);
    Site s = new Site(x, y);
    s.selected = o.getBoolean("selected", false);
    list.add(s);
  }
  return list;
}

ArrayList<Cell> deserializeCells(JSONArray arr) {
  ArrayList<Cell> list = new ArrayList<Cell>();
  if (arr == null) return list;
  for (int i = 0; i < arr.size(); i++) {
    JSONObject o = arr.getJSONObject(i);
    if (o == null) continue;
    int siteIdx = o.getInt("siteIndex", -1);
    int biomeId = o.getInt("biomeId", 0);
    JSONArray vertsArr = o.getJSONArray("vertices");
    ArrayList<PVector> verts = new ArrayList<PVector>();
    if (vertsArr != null) {
      for (int vi = 0; vi < vertsArr.size(); vi++) {
        JSONObject pv = vertsArr.getJSONObject(vi);
        if (pv == null) continue;
        verts.add(new PVector(pv.getFloat("x", 0), pv.getFloat("y", 0)));
      }
    }
    Cell c = new Cell(siteIdx, verts, biomeId);
    c.elevation = o.getFloat("elevation", 0.0f);
    list.add(c);
  }
  return list;
}

ArrayList<MapModel.MapZone> deserializeZones(JSONArray arr) {
  ArrayList<MapModel.MapZone> list = new ArrayList<MapModel.MapZone>();
  if (arr == null) return list;
  for (int i = 0; i < arr.size(); i++) {
    JSONObject o = arr.getJSONObject(i);
    if (o == null) continue;
    String name = o.getString("name", "Zone");
    int col = o.getInt("col", color(200));
    MapModel.MapZone z = mapModel.new MapZone(name, col);
    z.hue01 = o.getFloat("hue01", z.hue01);
    z.sat01 = o.getFloat("sat01", z.sat01);
    z.bri01 = o.getFloat("bri01", z.bri01);
    z.col = hsb01ToRGB(z.hue01, z.sat01, z.bri01);
    z.cells.clear();
    JSONArray cellsArr = o.getJSONArray("cells");
    if (cellsArr != null) {
      for (int ci = 0; ci < cellsArr.size(); ci++) {
        z.cells.add(cellsArr.getInt(ci));
      }
    }
    list.add(z);
  }
  return list;
}

ArrayList<Path> deserializePaths(JSONArray arr) {
  ArrayList<Path> list = new ArrayList<Path>();
  if (arr == null) return list;
  for (int i = 0; i < arr.size(); i++) {
    JSONObject o = arr.getJSONObject(i);
    if (o == null) continue;
    Path p = new Path();
    p.typeId = o.getInt("typeId", 0);
    p.name = o.getString("name", "Path");
    p.comment = o.getString("comment", "");
    JSONArray routesArr = o.getJSONArray("routes");
    if (routesArr != null) {
      for (int ri = 0; ri < routesArr.size(); ri++) {
        JSONArray ptsArr = routesArr.getJSONArray(ri);
        ArrayList<PVector> seg = new ArrayList<PVector>();
        if (ptsArr != null) {
          for (int pi = 0; pi < ptsArr.size(); pi++) {
            JSONObject pv = ptsArr.getJSONObject(pi);
            if (pv == null) continue;
            seg.add(new PVector(pv.getFloat("x", 0), pv.getFloat("y", 0)));
          }
        }
        p.routes.add(seg);
      }
    }
    list.add(p);
  }
  return list;
}

ArrayList<Structure> deserializeStructures(JSONArray arr) {
  ArrayList<Structure> list = new ArrayList<Structure>();
  if (arr == null) return list;
  for (int i = 0; i < arr.size(); i++) {
    JSONObject o = arr.getJSONObject(i);
    if (o == null) continue;
    float x = o.getFloat("x", 0);
    float y = o.getFloat("y", 0);
    Structure s = new Structure(x, y);
    s.typeId = o.getInt("typeId", 0);
    s.name = o.getString("name", "");
    s.comment = o.getString("comment", "");
    s.angle = o.getFloat("angle", 0);
    s.size = o.getFloat("size", s.size);
    try {
      String sh = o.getString("shape", s.shape.name());
      if ("SQUARE".equals(sh)) sh = StructureShape.RECTANGLE.name();
      s.shape = StructureShape.valueOf(sh);
    } catch (Exception e) {}
    try { s.alignment = StructureSnapMode.valueOf(o.getString("alignment", s.alignment.name())); } catch (Exception e) {}
    s.aspect = o.getFloat("aspect", s.aspect);
    s.hue01 = o.getFloat("hue01", s.hue01);
    s.sat01 = o.getFloat("sat01", s.sat01);
    s.bri01 = o.getFloat("bri01", s.bri01);
    s.alpha01 = o.getFloat("alpha01", s.alpha01);
    s.strokeWeightPx = o.getFloat("strokeWeightPx", s.strokeWeightPx);
    s.fillCol = o.getInt("fillCol", s.fillCol);
    s.updateFillColor();
    if (s.snapBinding == null) s.snapBinding = new StructureSnapBinding();
    s.snapBinding.clear();
    try { s.snapBinding.type = StructureSnapTargetType.valueOf(o.getString("snapTargetType", s.snapBinding.type.name())); } catch (Exception e) {}
    s.snapBinding.pathIndex = o.getInt("snapPathIndex", s.snapBinding.pathIndex);
    s.snapBinding.routeIndex = o.getInt("snapRouteIndex", s.snapBinding.routeIndex);
    s.snapBinding.segmentIndex = o.getInt("snapSegmentIndex", s.snapBinding.segmentIndex);
    s.snapBinding.structureIndex = o.getInt("snapStructureIndex", s.snapBinding.structureIndex);
    s.snapBinding.cellA = o.getInt("snapCellA", s.snapBinding.cellA);
    s.snapBinding.cellB = o.getInt("snapCellB", s.snapBinding.cellB);
    s.snapBinding.snapAngleRad = o.getFloat("snapAngleRad", s.snapBinding.snapAngleRad);
    if (o.hasKey("snapPointX") && o.hasKey("snapPointY")) {
      s.snapBinding.snapPoint = new PVector(o.getFloat("snapPointX", 0), o.getFloat("snapPointY", 0));
    }
    if (o.hasKey("snapSegAx") && o.hasKey("snapSegAy")) {
      s.snapBinding.segA = new PVector(o.getFloat("snapSegAx", 0), o.getFloat("snapSegAy", 0));
    }
    if (o.hasKey("snapSegBx") && o.hasKey("snapSegBy")) {
      s.snapBinding.segB = new PVector(o.getFloat("snapSegBx", 0), o.getFloat("snapSegBy", 0));
    }
    list.add(s);
  }
  return list;
}

ArrayList<MapLabel> deserializeLabels(JSONArray arr) {
  ArrayList<MapLabel> list = new ArrayList<MapLabel>();
  if (arr == null) return list;
  for (int i = 0; i < arr.size(); i++) {
    JSONObject o = arr.getJSONObject(i);
    if (o == null) continue;
    float x = o.getFloat("x", 0);
    float y = o.getFloat("y", 0);
    String text = o.getString("text", "");
    String targetStr = o.getString("target", LabelTarget.FREE.name());
    LabelTarget target = LabelTarget.FREE;
    try { target = LabelTarget.valueOf(targetStr); } catch (Exception e) {}
    MapLabel l = new MapLabel(x, y, text, target);
    l.size = o.getFloat("size", l.size);
    l.comment = o.getString("comment", "");
    list.add(l);
  }
  return list;
}

void recomputeWorldBoundsFromData() {
  float minXLocal = Float.MAX_VALUE;
  float minYLocal = Float.MAX_VALUE;
  float maxXLocal = -Float.MAX_VALUE;
  float maxYLocal = -Float.MAX_VALUE;

  if (mapModel.cells != null) {
    for (Cell c : mapModel.cells) {
      if (c == null || c.vertices == null) continue;
      for (PVector v : c.vertices) {
        if (v == null) continue;
        minXLocal = min(minXLocal, v.x);
        minYLocal = min(minYLocal, v.y);
        maxXLocal = max(maxXLocal, v.x);
        maxYLocal = max(maxYLocal, v.y);
      }
    }
  }
  if (mapModel.sites != null) {
    for (Site s : mapModel.sites) {
      if (s == null) continue;
      minXLocal = min(minXLocal, s.x);
      minYLocal = min(minYLocal, s.y);
      maxXLocal = max(maxXLocal, s.x);
      maxYLocal = max(maxYLocal, s.y);
    }
  }

  if (minXLocal == Float.MAX_VALUE || maxXLocal == -Float.MAX_VALUE) {
    mapModel.minX = 0;
    mapModel.maxX = 1;
    mapModel.minY = 0;
    mapModel.maxY = 1;
  } else {
    mapModel.minX = minXLocal;
    mapModel.maxX = maxXLocal;
    mapModel.minY = minYLocal;
    mapModel.maxY = maxYLocal;
  }
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
  if (selectedStructureIndices != null && !selectedStructureIndices.isEmpty()) return;
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
