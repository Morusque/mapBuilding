
import processing.event.MouseEvent;
import java.util.HashSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Collections;
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

boolean useDefaultStructureNames = false;
boolean useDefaultPathNames = false;

boolean structSectionGenOpen = true;
boolean structSectionSnapOpen = true;
boolean structSectionAttrOpen = true;

// Rendering configuration
RenderSettings renderSettings = new RenderSettings();
RenderPreset[] renderPresets = buildDefaultRenderPresets();
boolean renderSectionBaseOpen = false;
boolean renderSectionBiomesOpen = false;
boolean renderSectionShadingOpen = false;
boolean renderSectionCoastlinesOpen = false;
boolean renderSectionElevationOpen = false;
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
final String[] LABEL_FONT_OPTIONS = { "SansSerif", "Serif", "Monospaced", "Arial", "Georgia" };

float sliderNorm(IntRect r, int mx) {
  if (r == null) return 0;
  int padding = max(4, r.h / 2);
  float startX = r.x + padding;
  float endX = r.x + r.w - padding;
  if (endX <= startX) return 0;
  return constrain((mx - startX) / (endX - startX), 0, 1);
}

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
float renderLightAzimuthDeg = 220.0f;   // 0..360, 0 = +X (east)
float renderLightAltitudeDeg = 45.0f;   // 0..90, 90 = overhead
boolean useNewElevationShading = false;
float flattestSlopeBias = FLATTEST_BIAS_MIN; // slope penalty in PATHFIND mode (min..max, 0 = shortest)
boolean pathAvoidWater = false;
boolean pathTaperRivers = false;
boolean pathEraserMode = false;
float pathEraserRadius = 0.04f;
int PATH_MAX_EXPANSIONS = 4000; // tweakable pathfinding budget per query (per-direction if bidirectional)
boolean PATH_BIDIRECTIONAL = true; // grow paths from both ends
int ELEV_STEPS_PATHS = 6;
boolean siteDirtyDuringDrag = false;
float renderPaddingPct = 0.01f; // fraction of min(screenW, screenH) cropped from all sides
float exportScale = 2.0f; // multiplier for PNG export resolution
// Nominal initial viewport zoom (matches Viewport constructor); used as label scale reference.
final float DEFAULT_VIEW_ZOOM = 600.0f;
boolean fullGenRunning = false;
int fullGenStep = 0;
boolean fullGenPrimed = false;
Tool prevTool = Tool.EDIT_SITES;
// Render prep staging is currently disabled; flags kept for compatibility.
boolean renderPrepRunning = false;
boolean renderPrepDone = false;
boolean renderPrepPrimed = false;
String lastExportStatus = "";
boolean renderContoursDirty = true;
boolean renderForceDirtyAll = false;
boolean renderingForExport = false;
PGraphics exportPreview = null;
boolean exportPreviewDirty = true;
float[] exportPreviewRect = new float[4]; // x, y, w, h in world units
void markRenderDirty() {
  renderContoursDirty = true;
  renderPrepDone = false;
  renderForceDirtyAll = true;
  exportPreviewDirty = true;
  if (mapModel != null && mapModel.renderer != null) {
    mapModel.renderer.invalidateCoastCache();
    mapModel.renderer.invalidateBiomeCache();
    mapModel.renderer.invalidateBiomeOutlineLayer();
    mapModel.renderer.invalidateZoneCache();
    mapModel.renderer.invalidateLightCache();
    mapModel.renderer.invalidateCellBorderLayer();
  }
}

// Trigger a render rebuild without forcing contour/grid recomputation
void markRenderVisualChange() {
  renderPrepDone = false;
  exportPreviewDirty = true;
}

void markExportPreviewDirty() {
  exportPreviewDirty = true;
}

void syncLegacyWaterContourAlpha(RenderSettings target) {
  if (target == null) return;
  target.waterContourAlpha01 = target.waterCoastAlpha01;
}

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
  "Slice spot",
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
int structGenTownCount = 3;
float structGenBuildingDensity = 0.5f; // 0..1

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
  if (!info.angleMixed) structureAngleOffsetRad = info.sharedAngleRad;
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
String loadingDetail = "";
// Unified progress indicator (top bar uses this)
boolean progressActive = false;   // whether to show a bar
float progressPct = 0.0f;         // 0..1
String progressDetail = "";       // message next to bar
String progressStatusMsg = "";    // status text (shown even if bar hidden)

void setProgressStatus(String msg) {
  if (msg == null) msg = "";
  if (!msg.equals(progressStatusMsg)) progressStatusMsg = msg;
}

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
final int SLIDER_RENDER_ZONE_SIZE = 58;
final int SLIDER_RENDER_ZONE_SAT = 59;
final int SLIDER_RENDER_LABEL_OUTLINE_ALPHA = 60;
final int SLIDER_RENDER_BIOME_BRI = 62;
final int SLIDER_RENDER_ZONE_BRI = 63;
final int SLIDER_RENDER_PRESET_SELECT = 64;
final int SLIDER_RENDER_PATH_BRI = 90;
final int SLIDER_RENDER_LABEL_OUTLINE_SIZE = 91;
final int SLIDER_RENDER_LABEL_SIZE_ARBITRARY = 92;
final int SLIDER_RENDER_LABEL_SIZE_ZONES = 93;
final int SLIDER_RENDER_LABEL_SIZE_PATHS = 94;
final int SLIDER_RENDER_LABEL_SIZE_STRUCTS = 95;
final int SLIDER_RENDER_LABEL_FONT = 96;
final int SLIDER_BIOME_GEN_MODE = 65;
final int SLIDER_BIOME_GEN_VALUE = 66;
final int SLIDER_RENDER_BIOME_UNDERWATER_ALPHA = 67;
final int SLIDER_RENDER_STRUCT_SHADOW_ALPHA = 68;
final int SLIDER_BIOME_SAT = 69;
final int SLIDER_BIOME_BRI = 70;
final int SLIDER_RENDER_BACKGROUND_NOISE = 71;
final int SLIDER_RENDER_WATER_HATCH_ANGLE = 72;
final int SLIDER_RENDER_WATER_HATCH_LENGTH = 73;
final int SLIDER_RENDER_WATER_HATCH_SPACING = 74;
final int SLIDER_RENDER_WATER_HATCH_ALPHA = 75;
final int SLIDER_RENDER_LIGHT_DITHER = 76;
final int SLIDER_BIOME_PATTERN = 97;
final int SLIDER_PATH_ROUTE_MODE = 98;
final int SLIDER_STRUCT_GEN_TOWN = 99;
final int SLIDER_STRUCT_GEN_BUILDING = 100;
final int SLIDER_STRUCT_SNAP_DIV = 101;
final int SLIDER_STRUCT_SHAPE = 102;
final int SLIDER_STRUCT_ALIGNMENT = 103;
final int SLIDER_RENDER_CELL_BORDER_SIZE = 104;
final int SLIDER_RENDER_ELEV_LINES_SIZE = 105;
final int SLIDER_RENDER_WATER_COAST_SIZE = 106;
int activeSlider = SLIDER_NONE;


void applyRenderPreset(int idx) {
  if (renderPresets == null || renderPresets.length == 0) return;
  int clamped = constrain(idx, 0, renderPresets.length - 1);
  RenderPreset p = renderPresets[clamped];
  if (p == null || p.values == null) return;
  renderSettings.applyFrom(p.values);
  renderSettings.activePresetIndex = clamped;
  syncLegacyWaterContourAlpha(renderSettings);
  // Keep legacy padding in sync until full migration
  renderPaddingPct = renderSettings.exportPaddingPct;
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
      if (mapModel.cells != null && !mapModel.cells.isEmpty()) {
        int cellCount = mapModel.cells.size();
        int minSeeds = max(1, round(cellCount / 200.0f));
        int maxSeeds = max(1, round(cellCount / 10.0f));
        int seedCount = (int)constrain(round(lerp(minSeeds, maxSeeds, val01)), 1, cellCount);
        mapModel.generateZonesFromSeeds(seedCount);
      }
      break;
    case 1: // reset
      mapModel.setAllBiomesTo(targetBiome);
      break;
    case 2: // fill gaps
      mapModel.fillGapsFromExistingBiomes();
      break;
    case 3: // replace gaps
      if (mapModel.cells != null && !mapModel.cells.isEmpty()) {
        int gapCount = 0;
        for (Cell c : mapModel.cells) {
          if (c != null && c.biomeId == 0) gapCount++;
        }
        if (gapCount > 0) {
          int minSeeds = max(1, round(gapCount / 200.0f));
          int maxSeeds = max(1, round(gapCount / 10.0f));
          int seedCount = (int)constrain(round(lerp(minSeeds, maxSeeds, val01)), 1, gapCount);
          mapModel.fillGapsWithNewBiomesByCount(seedCount);
        }
      }
      break;
    case 4: // fill under
      mapModel.fillUnderThreshold(targetBiome, threshold);
      break;
    case 5: // fill above
      mapModel.fillAboveThreshold(targetBiome, threshold);
      break;
    case 6: // extend
      {
        int steps = max(1, round(lerp(1, 30, val01)));
        for (int i = 0; i < steps; i++) mapModel.extendBiomeOnce(targetBiome);
      }
      break;
    case 7: // shrink
      {
        int steps = max(1, round(lerp(1, 30, val01)));
        for (int i = 0; i < steps; i++) mapModel.shrinkBiomeOnce(targetBiome);
      }
      break;
    case 8: // spots
      if (mapModel.cells != null && !mapModel.cells.isEmpty()) {
        int n = mapModel.cells.size();
        int maxSpots = max(1, min(30, round(n / 200.0f)));
        int spotCount = (int)constrain(round(lerp(1, maxSpots, val01)), 1, maxSpots);
        mapModel.placeBiomeSpots(targetBiome, spotCount, 0.6f);
      }
      break;
    case 9: // vary
      {
        int steps = max(1, round(lerp(1, 20, val01)));
        for (int i = 0; i < steps; i++) mapModel.varyBiomesOnce();
      }
      break;
    case 10: // slice spot
      mapModel.placeSliceSpot(targetBiome, val01, threshold);
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
      if (forestIdx >= 0) for (int i = 0; i < 5; i++) mapModel.placeBiomeSpots(forestIdx, 0.5f);
      if (forestIdx >= 0) mapModel.placeSliceSpot(forestIdx, 0.8f, 0.24f);
      if (rockIdx >= 0) mapModel.placeSliceSpot(rockIdx, 0.8f, 0.36f);
      if (snowIdx >= 0) mapModel.fillAboveThreshold(snowIdx, 0.48f);
      if (magmaIdx >= 0) mapModel.fillAboveThreshold(magmaIdx, 0.6f);
      if (grassIdx >= 0) mapModel.extendBiomeOnce(grassIdx);
      if (forestIdx >= 0) mapModel.shrinkBiomeOnce(forestIdx);
      if (wetIdx >= 0) mapModel.fillUnderThreshold(wetIdx, seaLevel);
      if (sandIdx >= 0) for (int i = 0; i < 7; i++) mapModel.placeSliceSpot(sandIdx, 0.8f, seaLevel);
      mapModel.varyBiomesOnce();
      break;
  }
  mapModel.renderer.invalidateBiomeOutlineCache();
  mapModel.snapDirty = true;
}

// Full auto-pipeline starting from existing cells
void startFullGenerateFromCells() {
  if (mapModel == null) return;
  if (fullGenRunning) return;
  fullGenRunning = true;
  fullGenStep = 0;
  fullGenPrimed = false;
  loadingPct = 0.0f;
  startLoading();
}

void resetAllMapData() {
  startLoading();
  try {
    mapModel = new MapModel();
    loadBiomePatternList();
    initBiomeTypes();
    initZones();
    initPathTypes();

    // Reset selections / drafts
    selectedPathIndex = -1;
    pendingPathStart = null;
    clearStructureSelection();
    selectedLabelIndex = -1;
    editingLabelIndex = -1;
    editingLabelCommentIndex = -1;
    labelDraft = "label";
    labelCommentDraft = "";
    editingPathNameIndex = -1;
    editingPathCommentIndex = -1;
    editingPathTypeNameIndex = -1;
    activeBiomeIndex = 1;
    activeZoneIndex = 1;
    zonesListScroll = pathsListScroll = structuresListScroll = labelsListScroll = 0;
    mapModel.snapDirty = true;
    markRenderDirty();
  } finally {
    stopLoading();
    progressActive = false;
    progressDetail = "";
    progressPct = 0;
  }
}

// Request staged render prep (used when entering heavy modes or after invalidation)
void requestRenderPrep() {
  if (mapModel == null || mapModel.renderer == null) return;
  mapModel.renderer.resetRenderPrep(renderForceDirtyAll);
  renderForceDirtyAll = false;
  renderPrepRunning = false;
  renderPrepDone = true;
  renderPrepPrimed = false;
  exportPreviewDirty = true;
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
  // Kick off staged render prep when already in heavy modes.
  if (currentTool == Tool.EDIT_RENDER || currentTool == Tool.EDIT_LABELS) {
    requestRenderPrep();
  }
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
  ZoneType z = new ZoneType(name, col);
  z.patternIndex = mapModel.defaultPatternIndexForBiome(mapModel.biomeTypes.size());
  mapModel.biomeTypes.add(z);
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
  size(1300, 800, P2D);
}

void setup() {
  surface.setTitle("map designing tool");
  viewport = new Viewport();
  mapModel = new MapModel();
  applyRenderPreset(0);
  loadBiomePatternList();
  initBiomeTypes();
  initZones();
  initPathTypes();
  // Prime label font cache early to avoid first render/label stutter.
  if (mapModel != null && mapModel.renderer != null) {
    mapModel.renderer.warmLabelFonts(this, renderSettings);
  }
  mapModel.generateSites(currentPlacementMode(), siteTargetCount);
  mapModel.ensureVoronoiComputed();
  seedDefaultZones();
  initTooltipTexts();
}

void initBiomeTypes() {
  mapModel.biomeTypes.clear();
  ZoneType none = new ZoneType("None",  color(235));
  none.patternIndex = mapModel.defaultPatternIndexForBiome(mapModel.biomeTypes.size());
  mapModel.biomeTypes.add(none);

  // Seed with the first few presets for quick access; more can be added via "+".
  int initialCount = 5;
  for (int i = 0; i < initialCount && i < ZONE_PRESETS.length; i++) {
    ZonePreset zp = ZONE_PRESETS[i];
    ZoneType z = new ZoneType(zp.name, zp.col);
    z.patternIndex = mapModel.defaultPatternIndexForBiome(mapModel.biomeTypes.size());
    mapModel.biomeTypes.add(z);
  }
  mapModel.syncBiomePatternAssignments();
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
  loadingDetail = "";
  if (currentTool != prevTool) {
    if (currentTool == Tool.EDIT_EXPORT) exportPreviewDirty = true;
    prevTool = currentTool;
  }

  // Drive incremental Voronoi rebuilds; loading state follows the job
  if (fullGenRunning) {
    if (!isLoading) startLoading();
    stepFullGenerateFromCells();
    // Safety: if full gen steps exceeded, clear flags.
    if (fullGenStep > 5) {
      fullGenRunning = false;
      stopLoading();
      loadingDetail = "";
      loadingPct = 1.0f;
    }
  }
  mapModel.ensureVoronoiComputed();
  mapModel.stepContourJobs(6);
  boolean buildingVoronoi = mapModel.isVoronoiBuilding();
  boolean buildingContours = mapModel.isContourJobRunning();
  boolean building = buildingVoronoi || buildingContours;
  float pctVoronoi = mapModel.getVoronoiProgress();
  float pctContours = mapModel.getContourJobProgress();
  float combinedPct = buildingContours ? min(pctVoronoi, pctContours) : pctVoronoi;
  if (!fullGenRunning) {
    if (building) {
      if (buildingVoronoi) {
        setProgressStatus("Generating cells...");
      } else if (buildingContours) {
        setProgressStatus("Generating contours...");
      }
      if (!isLoading) startLoading();
      loadingPct = combinedPct;
    } else {
      if (isLoading) {
        stopLoading();
      }
      setProgressStatus("");
      if (uiNotice != null && uiNotice.equals("Generation in progress...")) {
        uiNotice = "";
        uiNoticeFrames = 0;
      }
      loadingPct = 1.0f;
    }
  } else {
    // If full gen is running and all jobs plus steps are done, clear loading.
    if (!building && fullGenStep > 5) {
      fullGenRunning = false;
      stopLoading();
      loadingPct = 1.0f;
      loadingDetail = "";
      setProgressStatus("");
      progressActive = false;
      progressPct = 0;
      if (uiNotice != null && uiNotice.equals("Generation in progress...")) {
        uiNotice = "";
        uiNoticeFrames = 0;
      }
    }
  }
  // When generation is running, show its status in the top bar.
  if (fullGenRunning) {
    setProgressStatus((loadingDetail != null && loadingDetail.length() > 0)
      ? loadingDetail
      : "Generation in progress...");
  }

  boolean renderView = (currentTool == Tool.EDIT_RENDER || currentTool == Tool.EDIT_EXPORT);
  // Run one render-prep stage per frame when needed (before world draw so UI can update).
  if (renderView && mapModel != null && mapModel.renderer != null) {
    if (mapModel.renderer.isRenderWorkNeeded()) {
      renderPrepRunning = true;
      progressActive = true;
      progressPct = max(progressPct, mapModel.renderer.renderPrepProgress());
      progressDetail = "Rendering " + mapModel.renderer.getRenderPrepStageLabel();
      if (!fullGenRunning) setProgressStatus("Rendering...");
      boolean donePrep = mapModel.renderer.stepRenderPrep(this, renderSettings, seaLevel);
      progressPct = max(progressPct, mapModel.renderer.renderPrepProgress());
      if (donePrep || !mapModel.renderer.isRenderWorkNeeded()) {
        renderPrepRunning = false;
        progressActive = false;
        progressDetail = "";
        progressPct = 1;
        if (!fullGenRunning) setProgressStatus("");
      }
    } else {
      renderPrepRunning = false;
      progressActive = false;
      progressDetail = "";
      progressPct = 1;
      if (!fullGenRunning) setProgressStatus("");
    }
  } else {
    renderPrepRunning = false;
  }

  // ----- World rendering -----
  pushMatrix();
  viewport.applyTransform(this.g);

  boolean skipWorld = false;
  if (renderPrepRunning && (currentTool == Tool.EDIT_RENDER || currentTool == Tool.EDIT_LABELS || currentTool == Tool.EDIT_EXPORT)) {
    // While prep is running, skip world to keep UI responsive; cached view will show once ready.
    skipWorld = true;
  }

  if (renderView && !skipWorld) {
    triggerRenderPrerequisitesIfDirty();
    if (mapModel != null && mapModel.renderer != null) {
      if (mapModel.renderer.isRenderWorkNeeded()) {
        renderPrepRunning = true;
        progressActive = true;
        progressPct = max(progressPct, mapModel.renderer.renderPrepProgress());
        progressDetail = "Rendering " + mapModel.renderer.getRenderPrepStageLabel();
        if (!fullGenRunning) setProgressStatus("Rendering...");
        boolean donePrep = mapModel.renderer.stepRenderPrep(this, renderSettings, seaLevel);
        progressPct = max(progressPct, mapModel.renderer.renderPrepProgress());
        if (donePrep || !mapModel.renderer.isRenderWorkNeeded()) {
          renderPrepRunning = false;
          progressActive = false;
          progressDetail = "";
          progressPct = 1;
          if (!fullGenRunning) setProgressStatus("");
        }
      } else {
        renderPrepRunning = false;
        progressActive = false;
        progressDetail = "";
        progressPct = 0;
        if (!fullGenRunning) setProgressStatus("");
      }
    }
    if (currentTool == Tool.EDIT_EXPORT) {
      drawExportPreviewView();
    } else {
      drawRenderView(this);
    }
  } else if (!skipWorld) {
    boolean allowLabels = (renderSettings != null) ? renderSettings.showLabelsArbitrary : true;
    switch (currentTool) {
      case EDIT_SITES: {
        mapModel.drawCells(this, true);
        mapModel.drawPaths(this, color(60, 60, 200), false, true);
        mapModel.drawStructures(this);
        if (allowLabels) mapModel.drawLabels(this);
        mapModel.drawSites(this);
        break;
      }
      case EDIT_ELEVATION: {
        mapModel.drawCellsRender(this, false, true);
        mapModel.drawElevationOverlay(this, seaLevel, false, true, true, false, 128);
        mapModel.drawPaths(this, color(120), false, true);
        mapModel.drawStructures(this);
        if (allowLabels) mapModel.drawLabels(this);
        drawElevationBrushPreview();
        break;
      }
      case EDIT_BIOMES: {
        mapModel.drawCells(this, true);
        mapModel.drawPaths(this, color(60, 60, 200), false, true);
        mapModel.drawStructures(this);
        if (allowLabels) mapModel.drawLabels(this);
        if (currentBiomePaintMode == ZonePaintMode.ZONE_PAINT) drawZoneBrushPreview();
        break;
      }
      case EDIT_ZONES: {
        mapModel.drawCellsRender(this, false, true);
        mapModel.drawElevationOverlay(this, seaLevel, false, true, true, false, ELEV_STEPS_PATHS);
        mapModel.drawZoneOutlines(this);
        mapModel.drawPaths(this, color(60, 60, 200), false, true);
        mapModel.drawStructures(this);
        if (allowLabels) mapModel.drawLabels(this);
        if (currentZonePaintMode == ZonePaintMode.ZONE_PAINT) drawZoneBrushPreview();
        break;
      }
      case EDIT_PATHS: {
        mapModel.drawCellsRender(this, false, true);
        mapModel.drawElevationOverlay(this, seaLevel, false, true, true, false, ELEV_STEPS_PATHS);
        mapModel.drawPaths(this, color(60, 60, 200), true, true);
        mapModel.drawStructures(this);
        if (allowLabels) mapModel.drawLabels(this);
        drawPathSnappingPoints();
        if (pathEraserMode) drawPathEraserPreview();

        // Path preview
        if (pendingPathStart != null) {
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

          Path tmp = new Path();
          tmp.routes.add(route);
          tmp.drawPreview(this, route, col, w);

          // Start/end markers
          pushStyle();
          noStroke();
          fill(255, 180, 0, 200);
          float sr = 5.0f / viewport.zoom;
          ellipse(pendingPathStart.x, pendingPathStart.y, sr, sr);
          if (!route.isEmpty()) {
            PVector end = route.get(route.size() - 1);
            float tr = 4.0f / viewport.zoom;
            fill(80, 120, 240, 160);
            ellipse(end.x, end.y, tr, tr);
          }
          popStyle();
        }
        break;
      }
      case EDIT_STRUCTURES: {
        mapModel.drawCellsRender(this, false, true);
        mapModel.drawElevationOverlay(this, seaLevel, false, true, true, false, ELEV_STEPS_PATHS);
        mapModel.drawPaths(this, color(60, 60, 200), false, true);
        mapModel.drawStructureSnapGuides(this);
        mapModel.drawStructures(this);
        if (allowLabels) mapModel.drawLabels(this);
        drawStructurePreview();
        break;
      }
      case EDIT_LABELS: {
        mapModel.drawCellsRender(this, false, true);
        mapModel.drawElevationOverlay(this, seaLevel, false, true, true, false, ELEV_STEPS_PATHS);
        mapModel.drawPaths(this, color(60, 60, 200), false, true);
        mapModel.drawStructures(this);
        if (allowLabels) {
          RenderSettings rs = new RenderSettings();
          rs.showLabelsZones = true;
          rs.showLabelsPaths = true;
          rs.showLabelsStructures = true;
          rs.showLabelsArbitrary = true;
          rs.labelOutlineAlpha01 = 1.0f;
          rs.labelOutlineSizePx = 2.0f;
          mapModel.drawZoneLabelsRender(this, rs);
          mapModel.drawPathLabelsRender(this, rs);
          mapModel.drawStructureLabelsRender(this, rs);
          mapModel.drawLabelsRender(this, rs);
        }
        break;
      }
      default: {
        mapModel.drawCells(this, true);
        mapModel.drawPaths(this, color(60, 60, 200), false, true);
        mapModel.drawStructures(this);
        if (allowLabels) mapModel.drawLabels(this);
        mapModel.drawDebugWorldBounds(this);
        break;
      }
    }
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

  if (renderView) {
    drawExportPaddingOverlay();
  }

  // ----- UI overlay -----
  drawTopBar();
  drawToolButtons();
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

  // Coastlines overlay (optional above zones)
  if (renderSettings.waterCoastAboveZones && renderSettings.waterCoastAlpha01 > 1e-4f) {
    if (mapModel.renderer != null && mapModel.renderer.getCoastLayer() != null) {
      pushStyle();
      pushMatrix();
      resetMatrix();
      tint(255, constrain(renderSettings.waterCoastAlpha01, 0, 1) * 255);
      image(mapModel.renderer.getCoastLayer(), 0, 0);
      popMatrix();
      popStyle();
    } else if (mapModel.renderer != null) {
      mapModel.renderer.ensureCoastLayer(app, renderSettings, seaLevel);
    }
  }

  // Paths
  if (renderSettings.showPaths) {
    mapModel.drawPathsRender(app, renderSettings);
  }

  // Structures
  if (renderSettings.showStructures) {
    mapModel.drawStructuresRender(app, renderSettings);
  }

  // Labels (export: render into a dedicated layer to avoid P2D text issues)
  if (renderingForExport && mapModel != null && mapModel.renderer != null) {
    PGraphics labels = mapModel.renderer.buildLabelLayer(this, renderSettings);
    if (labels != null) {
      pushMatrix();
      resetMatrix();
      image(labels, 0, 0);
      popMatrix();
    }
  } else {
    if (renderSettings.showLabelsZones) mapModel.drawZoneLabelsRender(app, renderSettings);
    if (renderSettings.showLabelsPaths) mapModel.drawPathLabelsRender(app, renderSettings);
    if (renderSettings.showLabelsStructures) mapModel.drawStructureLabelsRender(app, renderSettings);
    if (renderSettings.showLabelsArbitrary) mapModel.drawLabelsRender(app, renderSettings);
  }
}

// Export logic moved to ExportLogic.pde (exportPng/exportSvg/exportMapJson)

ArrayList<PVector> structureOutline(Structure s) {
  ArrayList<PVector> pts = new ArrayList<PVector>();
  if (s == null) return pts;
  float r = s.size;
  float asp = max(0.1f, s.aspect);
  float cosA = cos(s.angle);
  float sinA = sin(s.angle);

  Runnable addRectangle = new Runnable() {
    public void run() {
      float w = r;
      float h = r / asp;
      float[][] corners = {
        {-w * 0.5f, -h * 0.5f},
        { w * 0.5f, -h * 0.5f},
        { w * 0.5f,  h * 0.5f},
        {-w * 0.5f,  h * 0.5f}
      };
      for (float[] c : corners) {
        float rx = c[0] * cosA - c[1] * sinA;
        float ry = c[0] * sinA + c[1] * cosA;
        pts.add(new PVector(s.x + rx, s.y + ry));
      }
    }
  };

  switch (s.shape) {
    case RECTANGLE: {
      addRectangle.run();
      break;
    }
    case CIRCLE: {
      int segments = 24;
      float rx = r * 0.5f;
      float ry = (r / asp) * 0.5f;
      for (int i = 0; i < segments; i++) {
        float a = TWO_PI * i / (float)segments;
        float cx = cos(a) * rx;
        float cy = sin(a) * ry;
        float rxp = cx * cosA - cy * sinA;
        float ryp = cx * sinA + cy * cosA;
        pts.add(new PVector(s.x + rxp, s.y + ryp));
      }
      break;
    }
    case TRIANGLE: {
      float h = (r / asp) * 0.866f;
      float[][] corners = {
        {-r * 0.5f, h * 0.333f},
        { r * 0.5f, h * 0.333f},
        { 0.0f,     -h * 0.666f}
      };
      for (float[] c : corners) {
        float rx = c[0] * cosA - c[1] * sinA;
        float ry = c[0] * sinA + c[1] * cosA;
        pts.add(new PVector(s.x + rx, s.y + ry));
      }
      break;
    }
    case HEXAGON: {
      float rad = r * 0.5f;
      for (int i = 0; i < 6; i++) {
        float a = radians(60 * i);
        float cx = cos(a) * rad;
        float cy = sin(a) * rad / asp;
        float rx = cx * cosA - cy * sinA;
        float ry = cx * sinA + cy * cosA;
        pts.add(new PVector(s.x + rx, s.y + ry));
      }
      break;
    }
    default: {
      addRectangle.run();
      break;
    }
  }
  return pts;
}

float elevationAtPoint(float x, float y) {
  if (mapModel == null) return 0;
  return mapModel.sampleElevationAt(x, y, seaLevel);
}

JSONArray ringFromVertices(ArrayList<PVector> verts) {
  return ringFromVertices(verts, false);
}

JSONArray ringFromVertices(ArrayList<PVector> verts, boolean includeZ) {
  JSONArray ring = new JSONArray();
  if (verts == null || verts.size() < 3) return ring;
  for (PVector v : verts) {
    JSONArray p = new JSONArray();
    p.append(v.x);
    p.append(v.y);
    if (includeZ) p.append(elevationAtPoint(v.x, v.y));
    ring.append(p);
  }
  PVector first = verts.get(0);
  PVector last = verts.get(verts.size() - 1);
  if (abs(first.x - last.x) > 1e-6f || abs(first.y - last.y) > 1e-6f) {
    JSONArray p = new JSONArray();
    p.append(first.x);
    p.append(first.y);
    if (includeZ) p.append(elevationAtPoint(first.x, first.y));
    ring.append(p);
  }
  return ring;
}

boolean samePoint(PVector a, PVector b) {
  if (mapModel == null) return false;
  return mapModel.keyFor(a.x, a.y).equals(mapModel.keyFor(b.x, b.y));
}

ArrayList<ArrayList<PVector>> mergedPolygonsFromCells(ArrayList<Integer> cellIdxs) {
  ArrayList<ArrayList<PVector>> rings = new ArrayList<ArrayList<PVector>>();
  if (mapModel == null || mapModel.cells == null || cellIdxs == null) return rings;
  class Edge { PVector a; PVector b; Edge(PVector a, PVector b){ this.a = a; this.b = b; } }
  HashMap<String, Edge> boundary = new HashMap<String, Edge>();
  for (int ci : cellIdxs) {
    if (ci < 0 || ci >= mapModel.cells.size()) continue;
    Cell c = mapModel.cells.get(ci);
    if (c == null || c.vertices == null || c.vertices.size() < 2) continue;
    int vn = c.vertices.size();
    for (int i = 0; i < vn; i++) {
      PVector a = c.vertices.get(i);
      PVector b = c.vertices.get((i + 1) % vn);
      String ka = mapModel.keyFor(a.x, a.y);
      String kb = mapModel.keyFor(b.x, b.y);
      String key = (ka.compareTo(kb) <= 0) ? (ka + "|" + kb) : (kb + "|" + ka);
      if (boundary.containsKey(key)) {
        boundary.remove(key); // shared edge, not part of boundary
      } else {
        boundary.put(key, new Edge(a, b));
      }
    }
  }
  ArrayList<Edge> edges = new ArrayList<Edge>(boundary.values());
  boolean[] used = new boolean[edges.size()];
  for (int ei = 0; ei < edges.size(); ei++) {
    if (used[ei]) continue;
    Edge e = edges.get(ei);
    ArrayList<PVector> ring = new ArrayList<PVector>();
    ring.add(e.a);
    ring.add(e.b);
    used[ei] = true;
    PVector start = e.a;
    PVector cur = e.b;
    boolean closed = false;
    while (!closed) {
      int nextIdx = -1;
      boolean reverse = false;
      for (int j = 0; j < edges.size(); j++) {
        if (used[j]) continue;
        Edge cand = edges.get(j);
        if (samePoint(cand.a, cur)) { nextIdx = j; reverse = false; break; }
        if (samePoint(cand.b, cur)) { nextIdx = j; reverse = true; break; }
      }
      if (nextIdx == -1) break;
      Edge ne = edges.get(nextIdx);
      used[nextIdx] = true;
      PVector nxt = reverse ? ne.a : ne.b;
      if (reverse) {
        // ensure orientation follows current -> next
        PVector tmp = ne.a; ne.a = ne.b; ne.b = tmp;
      }
      if (samePoint(nxt, start)) {
        closed = true;
      }
      ring.add(nxt);
      cur = nxt;
      if (ring.size() > 100000) break; // safety
    }
    if (ring.size() >= 4) {
      rings.add(ring);
    }
  }
  return rings;
}

float[] elevationStatsForCells(ArrayList<Integer> cellIdxs) {
  if (cellIdxs == null || mapModel == null || mapModel.cells == null) return null;
  float minV = Float.MAX_VALUE, maxV = -Float.MAX_VALUE, sum = 0;
  int count = 0;
  for (int ci : cellIdxs) {
    if (ci < 0 || ci >= mapModel.cells.size()) continue;
    Cell c = mapModel.cells.get(ci);
    if (c == null) continue;
    float ev = c.elevation;
    minV = min(minV, ev);
    maxV = max(maxV, ev);
    sum += ev;
    count++;
  }
  if (count == 0) return null;
  return new float[]{minV, maxV, sum / count};
}

float[] elevationStatsForPoints(ArrayList<PVector> pts) {
  if (pts == null || mapModel == null) return null;
  float minV = Float.MAX_VALUE, maxV = -Float.MAX_VALUE, sum = 0;
  int count = 0;
  for (PVector p : pts) {
    if (p == null) continue;
    float ev = elevationAtPoint(p.x, p.y);
    minV = min(minV, ev);
    maxV = max(maxV, ev);
    sum += ev;
    count++;
  }
  if (count == 0) return null;
  return new float[]{minV, maxV, sum / count};
}

String exportGeoJson() {
  try {
    JSONObject root = new JSONObject();
    root.setString("type", "FeatureCollection");
    JSONArray features = new JSONArray();

    // Zones as merged MultiPolygons
    if (mapModel != null && mapModel.zones != null && mapModel.cells != null) {
      for (int zi = 0; zi < mapModel.zones.size(); zi++) {
        MapModel.MapZone z = mapModel.zones.get(zi);
        if (z == null || z.cells == null || z.cells.isEmpty()) continue;
        ArrayList<ArrayList<PVector>> rings = mergedPolygonsFromCells(z.cells);
        if (rings == null || rings.isEmpty()) continue;
        JSONArray polys = new JSONArray();
        for (ArrayList<PVector> r : rings) {
          JSONArray ring = ringFromVertices(r, true);
          if (ring.size() == 0) continue;
          JSONArray poly = new JSONArray();
          poly.append(ring);
          polys.append(poly);
        }
        if (polys.size() == 0) continue;
        float[] stats = elevationStatsForCells(z.cells);
        JSONObject geom = new JSONObject();
        geom.setString("type", "MultiPolygon");
        geom.setJSONArray("coordinates", polys);

        JSONObject props = new JSONObject();
        props.setString("category", "zone");
        props.setInt("zoneIndex", zi);
        props.setString("name", z.name != null ? z.name : "");
        props.setString("comment", z.comment != null ? z.comment : "");
        if (stats != null) {
          props.setFloat("elevMin", stats[0]);
          props.setFloat("elevMax", stats[1]);
          props.setFloat("elevMean", stats[2]);
        }

        JSONObject feat = new JSONObject();
        feat.setString("type", "Feature");
        feat.setJSONObject("geometry", geom);
        feat.setJSONObject("properties", props);
        features.append(feat);
      }
    }

    // Biomes as merged MultiPolygons
    if (mapModel != null && mapModel.cells != null && mapModel.biomeTypes != null && !mapModel.biomeTypes.isEmpty()) {
      int biomeCount = mapModel.biomeTypes.size();
      for (int bid = 1; bid < biomeCount; bid++) { // skip None=0
        ArrayList<Integer> cellIdxs = new ArrayList<Integer>();
        for (int ci = 0; ci < mapModel.cells.size(); ci++) {
          Cell c = mapModel.cells.get(ci);
          if (c != null && c.biomeId == bid) cellIdxs.add(ci);
        }
        if (cellIdxs.isEmpty()) continue;
        ArrayList<ArrayList<PVector>> rings = mergedPolygonsFromCells(cellIdxs);
        if (rings == null || rings.isEmpty()) continue;
        JSONArray polys = new JSONArray();
        for (ArrayList<PVector> r : rings) {
          JSONArray ring = ringFromVertices(r, true);
          if (ring.size() == 0) continue;
          JSONArray poly = new JSONArray();
          poly.append(ring);
          polys.append(poly);
        }
        if (polys.size() == 0) continue;
        float[] stats = elevationStatsForCells(cellIdxs);
        JSONObject geom = new JSONObject();
        geom.setString("type", "MultiPolygon");
        geom.setJSONArray("coordinates", polys);

        JSONObject props = new JSONObject();
        props.setString("category", "biome");
        props.setInt("biomeIndex", bid);
        ZoneType zt = mapModel.biomeTypes.get(bid);
        props.setString("name", (zt != null && zt.name != null) ? zt.name : "");
        props.setString("comment", "");
        if (stats != null) {
          props.setFloat("elevMin", stats[0]);
          props.setFloat("elevMax", stats[1]);
          props.setFloat("elevMean", stats[2]);
        }

        JSONObject feat = new JSONObject();
        feat.setString("type", "Feature");
        feat.setJSONObject("geometry", geom);
        feat.setJSONObject("properties", props);
        features.append(feat);
      }
    }

    // Paths
    if (mapModel != null && mapModel.paths != null) {
      for (int pi = 0; pi < mapModel.paths.size(); pi++) {
        Path p = mapModel.paths.get(pi);
        if (p == null || p.routes == null) continue;
        for (int ri = 0; ri < p.routes.size(); ri++) {
          ArrayList<PVector> seg = p.routes.get(ri);
          if (seg == null || seg.size() < 2) continue;
          JSONArray coords = new JSONArray();
          for (PVector v : seg) {
            if (v == null) continue;
            JSONArray pt = new JSONArray();
            pt.append(v.x);
            pt.append(v.y);
            pt.append(elevationAtPoint(v.x, v.y));
            coords.append(pt);
          }
          JSONObject geom = new JSONObject();
          geom.setString("type", "LineString");
          geom.setJSONArray("coordinates", coords);

          JSONObject props = new JSONObject();
          props.setString("category", "path");
          props.setInt("pathIndex", pi);
          props.setInt("routeIndex", ri);
          props.setInt("pathTypeId", p.typeId);
          props.setString("name", p.name != null ? p.name : "");
          props.setString("comment", p.comment != null ? p.comment : "");
          float[] stats = elevationStatsForPoints(seg);
          if (stats != null) {
            props.setFloat("elevMin", stats[0]);
            props.setFloat("elevMax", stats[1]);
            props.setFloat("elevMean", stats[2]);
          }

          JSONObject feat = new JSONObject();
          feat.setString("type", "Feature");
          feat.setJSONObject("geometry", geom);
          feat.setJSONObject("properties", props);
          features.append(feat);
        }
      }
    }

    // Structures
    if (mapModel != null && mapModel.structures != null) {
      for (int si = 0; si < mapModel.structures.size(); si++) {
        Structure s = mapModel.structures.get(si);
        if (s == null) continue;
        ArrayList<PVector> outline = structureOutline(s);
        JSONArray ring = ringFromVertices(outline, true);
        JSONObject geom = new JSONObject();
        if (ring.size() >= 4) { // closed polygon with >=3 distinct points
          JSONArray poly = new JSONArray();
          poly.append(ring);
          geom.setString("type", "Polygon");
          geom.setJSONArray("coordinates", poly);
        } else {
          JSONArray pt = new JSONArray();
          pt.append(s.x);
          pt.append(s.y);
          geom.setString("type", "Point");
          geom.setJSONArray("coordinates", pt);
        }

        JSONObject props = new JSONObject();
        props.setString("category", "structure");
        props.setInt("structureIndex", si);
        props.setInt("typeId", s.typeId);
        props.setString("name", s.name != null ? s.name : "");
        props.setString("comment", s.comment != null ? s.comment : "");
        props.setString("shape", s.shape != null ? s.shape.name() : "RECTANGLE");
        props.setFloat("size", s.size);
        props.setFloat("aspect", s.aspect);
        props.setFloat("angleRad", s.angle);
        props.setFloat("elev", elevationAtPoint(s.x, s.y));

        JSONObject feat = new JSONObject();
        feat.setString("type", "Feature");
        feat.setJSONObject("geometry", geom);
        feat.setJSONObject("properties", props);
        features.append(feat);
      }
    }

    // Labels
    if (mapModel != null && mapModel.labels != null) {
      for (int li = 0; li < mapModel.labels.size(); li++) {
        MapLabel lbl = mapModel.labels.get(li);
        if (lbl == null || lbl.text == null) continue;
        JSONArray pt = new JSONArray();
        pt.append(lbl.x);
        pt.append(lbl.y);
        pt.append(elevationAtPoint(lbl.x, lbl.y));
        JSONObject geom = new JSONObject();
        geom.setString("type", "Point");
        geom.setJSONArray("coordinates", pt);

        JSONObject props = new JSONObject();
        props.setString("category", "label");
        props.setInt("labelIndex", li);
        props.setString("text", lbl.text);
        props.setString("comment", lbl.comment != null ? lbl.comment : "");
        props.setString("target", lbl.target != null ? lbl.target.name() : "FREE");
        props.setFloat("size", lbl.size);
        props.setFloat("elev", elevationAtPoint(lbl.x, lbl.y));

        JSONObject feat = new JSONObject();
        feat.setString("type", "Feature");
        feat.setJSONObject("geometry", geom);
        feat.setJSONObject("properties", props);
        features.append(feat);
      }
    }

    root.setJSONArray("features", features);

    File dir = new File(sketchPath("exports"));
    if (!dir.exists()) dir.mkdirs();
    String ts = nf(year(), 4, 0) + nf(month(), 2, 0) + nf(day(), 2, 0) + "_" +
                nf(hour(), 2, 0) + nf(minute(), 2, 0) + nf(second(), 2, 0);
    File target = new File(dir, "map_" + ts + ".geojson");
    File latest = new File(dir, "map_latest.geojson");
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
      mapModel.syncBiomePatternAssignments();
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
  r.setFloat("cellBorderSizePx", s.cellBorderSizePx);
  r.setBoolean("cellBorderScaleWithZoom", s.cellBorderScaleWithZoom);
  r.setFloat("cellBorderRefZoom", s.cellBorderRefZoom);
  r.setFloat("backgroundNoiseAlpha01", s.backgroundNoiseAlpha01);

  JSONObject biomes = new JSONObject();
  biomes.setFloat("fillAlpha01", s.biomeFillAlpha01);
  biomes.setFloat("satScale01", s.biomeSatScale01);
  biomes.setFloat("briScale01", s.biomeBriScale01);
  String fillType = "color";
  if (s.biomeFillType == RenderFillType.RENDER_FILL_PATTERN) fillType = "pattern";
  else if (s.biomeFillType == RenderFillType.RENDER_FILL_PATTERN_BG) fillType = "pattern_bg";
  biomes.setString("fillType", fillType);
  biomes.setString("patternName", s.biomePatternName);
  biomes.setFloat("outlineSizePx", s.biomeOutlineSizePx);
  biomes.setFloat("outlineAlpha01", s.biomeOutlineAlpha01);
  biomes.setBoolean("outlineScaleWithZoom", s.biomeOutlineScaleWithZoom);
  biomes.setFloat("outlineRefZoom", s.biomeOutlineRefZoom);
  biomes.setFloat("underwaterAlpha01", s.biomeUnderwaterAlpha01);
  r.setJSONObject("biomes", biomes);

  JSONObject shading = new JSONObject();
  shading.setFloat("waterDepthAlpha01", s.waterDepthAlpha01);
  shading.setFloat("elevationLightAlpha01", s.elevationLightAlpha01);
  shading.setFloat("elevationLightAzimuthDeg", s.elevationLightAzimuthDeg);
  shading.setFloat("elevationLightAltitudeDeg", s.elevationLightAltitudeDeg);
  shading.setFloat("elevationLightDitherPx", s.elevationLightDitherPx);
   shading.setBoolean("elevationLightDitherScaleWithZoom", s.elevationLightDitherScaleWithZoom);
   shading.setFloat("elevationLightDitherRefZoom", s.elevationLightDitherRefZoom);
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
  contours.setFloat("waterCoastSizePx", s.waterCoastSizePx);
  contours.setBoolean("waterCoastScaleWithZoom", s.waterCoastScaleWithZoom);
  contours.setBoolean("waterContourScaleWithZoom", s.waterContourScaleWithZoom);
  contours.setFloat("waterContourRefZoom", s.waterContourRefZoom);
  contours.setFloat("waterRippleAlphaStart01", s.waterRippleAlphaStart01);
  contours.setFloat("waterRippleAlphaEnd01", s.waterRippleAlphaEnd01);
  contours.setFloat("waterHatchAngleDeg", s.waterHatchAngleDeg);
  contours.setFloat("waterHatchLengthPx", s.waterHatchLengthPx);
  contours.setFloat("waterHatchSpacingPx", s.waterHatchSpacingPx);
  contours.setFloat("waterHatchAlpha01", s.waterHatchAlpha01);
  contours.setInt("elevationLinesCount", s.elevationLinesCount);
  contours.setString("elevationLinesStyle", s.elevationLinesStyle.name());
  contours.setFloat("elevationLinesAlpha01", s.elevationLinesAlpha01);
  contours.setFloat("elevationLinesSizePx", s.elevationLinesSizePx);
  contours.setBoolean("elevationLinesScaleWithZoom", s.elevationLinesScaleWithZoom);
  contours.setFloat("elevationLinesRefZoom", s.elevationLinesRefZoom);
  r.setJSONObject("contours", contours);

  JSONObject paths = new JSONObject();
  paths.setFloat("pathSatScale01", s.pathSatScale01);
  paths.setFloat("pathBriScale01", s.pathBriScale01);
  paths.setBoolean("showPaths", s.showPaths);
  paths.setBoolean("pathScaleWithZoom", s.pathScaleWithZoom);
  paths.setFloat("pathScaleRefZoom", s.pathScaleRefZoom);
  r.setJSONObject("paths", paths);

  JSONObject zones = new JSONObject();
  zones.setFloat("zoneStrokeAlpha01", s.zoneStrokeAlpha01);
  zones.setFloat("zoneStrokeSizePx", s.zoneStrokeSizePx);
  zones.setFloat("zoneStrokeSatScale01", s.zoneStrokeSatScale01);
  zones.setFloat("zoneStrokeBriScale01", s.zoneStrokeBriScale01);
  zones.setBoolean("zoneStrokeScaleWithZoom", s.zoneStrokeScaleWithZoom);
  zones.setFloat("zoneStrokeRefZoom", s.zoneStrokeRefZoom);
  r.setJSONObject("zones", zones);

  JSONObject structures = new JSONObject();
  structures.setBoolean("showStructures", s.showStructures);
  structures.setBoolean("mergeStructures", s.mergeStructures);
  structures.setFloat("structureSatScale01", s.structureSatScale01);
  structures.setFloat("structureAlphaScale01", s.structureAlphaScale01);
  structures.setFloat("structureShadowAlpha01", s.structureShadowAlpha01);
  structures.setBoolean("structureStrokeScaleWithZoom", s.structureStrokeScaleWithZoom);
  structures.setFloat("structureStrokeRefZoom", s.structureStrokeRefZoom);
  r.setJSONObject("structures", structures);

  JSONObject labels = new JSONObject();
  labels.setBoolean("showLabelsArbitrary", s.showLabelsArbitrary);
  labels.setBoolean("showLabelsZones", s.showLabelsZones);
  labels.setBoolean("showLabelsPaths", s.showLabelsPaths);
  labels.setBoolean("showLabelsStructures", s.showLabelsStructures);
  labels.setFloat("labelOutlineAlpha01", s.labelOutlineAlpha01);
  labels.setFloat("labelOutlineSizePx", s.labelOutlineSizePx);
  labels.setFloat("labelSizeArbPx", s.labelSizeArbPx);
  labels.setFloat("labelSizeZonePx", s.labelSizeZonePx);
  labels.setFloat("labelSizePathPx", s.labelSizePathPx);
  labels.setFloat("labelSizeStructPx", s.labelSizeStructPx);
  labels.setBoolean("labelOutlineScaleWithZoom", s.labelOutlineScaleWithZoom);
  labels.setInt("labelFontIndex", s.labelFontIndex);
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
  target.cellBorderSizePx = r.getFloat("cellBorderSizePx", target.cellBorderSizePx);
  target.cellBorderScaleWithZoom = r.getBoolean("cellBorderScaleWithZoom", target.cellBorderScaleWithZoom);
  target.cellBorderRefZoom = r.getFloat("cellBorderRefZoom", target.cellBorderRefZoom);
  target.backgroundNoiseAlpha01 = r.getFloat("backgroundNoiseAlpha01", target.backgroundNoiseAlpha01);

  if (r.hasKey("biomes")) {
    JSONObject b = r.getJSONObject("biomes");
    target.biomeFillAlpha01 = b.getFloat("fillAlpha01", target.biomeFillAlpha01);
    target.biomeSatScale01 = b.getFloat("satScale01", target.biomeSatScale01);
    target.biomeBriScale01 = b.getFloat("briScale01", target.biomeBriScale01);
    String ft = b.getString("fillType", "color");
    if ("pattern".equals(ft)) target.biomeFillType = RenderFillType.RENDER_FILL_PATTERN;
    else if ("pattern_bg".equals(ft)) target.biomeFillType = RenderFillType.RENDER_FILL_PATTERN_BG;
    else target.biomeFillType = RenderFillType.RENDER_FILL_COLOR;
    target.biomePatternName = b.getString("patternName", target.biomePatternName);
    target.biomeOutlineSizePx = b.getFloat("outlineSizePx", target.biomeOutlineSizePx);
    target.biomeOutlineAlpha01 = b.getFloat("outlineAlpha01", target.biomeOutlineAlpha01);
    target.biomeOutlineScaleWithZoom = b.getBoolean("outlineScaleWithZoom", target.biomeOutlineScaleWithZoom);
    target.biomeOutlineRefZoom = b.getFloat("outlineRefZoom", target.biomeOutlineRefZoom);
    target.biomeUnderwaterAlpha01 = b.getFloat("underwaterAlpha01", target.biomeUnderwaterAlpha01);
  }

  if (r.hasKey("shading")) {
    JSONObject b = r.getJSONObject("shading");
    target.waterDepthAlpha01 = b.getFloat("waterDepthAlpha01", target.waterDepthAlpha01);
    target.elevationLightAlpha01 = b.getFloat("elevationLightAlpha01", target.elevationLightAlpha01);
    target.elevationLightAzimuthDeg = b.getFloat("elevationLightAzimuthDeg", target.elevationLightAzimuthDeg);
    target.elevationLightAltitudeDeg = b.getFloat("elevationLightAltitudeDeg", target.elevationLightAltitudeDeg);
    target.elevationLightDitherPx = b.getFloat("elevationLightDitherPx", target.elevationLightDitherPx);
    target.elevationLightDitherScaleWithZoom = b.getBoolean("elevationLightDitherScaleWithZoom", target.elevationLightDitherScaleWithZoom);
    target.elevationLightDitherRefZoom = b.getFloat("elevationLightDitherRefZoom", target.elevationLightDitherRefZoom);
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
    target.waterCoastSizePx = b.getFloat("waterCoastSizePx", target.waterCoastSizePx);
    target.waterCoastScaleWithZoom = b.getBoolean("waterCoastScaleWithZoom", target.waterCoastScaleWithZoom);
    target.waterContourScaleWithZoom = b.getBoolean("waterContourScaleWithZoom", target.waterContourScaleWithZoom);
    target.waterContourRefZoom = b.getFloat("waterContourRefZoom", target.waterContourRefZoom);
    target.waterRippleAlphaStart01 = b.getFloat("waterRippleAlphaStart01", target.waterContourAlpha01);
    target.waterRippleAlphaEnd01 = b.getFloat("waterRippleAlphaEnd01", target.waterRippleAlphaStart01);
    target.waterHatchAngleDeg = b.getFloat("waterHatchAngleDeg", target.waterHatchAngleDeg);
    target.waterHatchLengthPx = b.getFloat("waterHatchLengthPx", target.waterHatchLengthPx);
    target.waterHatchSpacingPx = b.getFloat("waterHatchSpacingPx", target.waterHatchSpacingPx);
    target.waterHatchAlpha01 = b.getFloat("waterHatchAlpha01", target.waterHatchAlpha01);
    syncLegacyWaterContourAlpha(target); // keep legacy field in sync
    target.elevationLinesCount = b.getInt("elevationLinesCount", target.elevationLinesCount);
    String style = b.getString("elevationLinesStyle", target.elevationLinesStyle.name());
    target.elevationLinesStyle = "ELEV_LINES_BASIC".equals(style) ? ElevationLinesStyle.ELEV_LINES_BASIC : target.elevationLinesStyle;
    target.elevationLinesAlpha01 = b.getFloat("elevationLinesAlpha01", target.elevationLinesAlpha01);
    target.elevationLinesSizePx = b.getFloat("elevationLinesSizePx", target.elevationLinesSizePx);
    target.elevationLinesScaleWithZoom = b.getBoolean("elevationLinesScaleWithZoom", target.elevationLinesScaleWithZoom);
    target.elevationLinesRefZoom = b.getFloat("elevationLinesRefZoom", target.elevationLinesRefZoom);
  }

  if (r.hasKey("paths")) {
    JSONObject b = r.getJSONObject("paths");
    target.pathSatScale01 = b.getFloat("pathSatScale01", target.pathSatScale01);
    target.pathBriScale01 = b.getFloat("pathBriScale01", target.pathBriScale01);
    target.showPaths = b.getBoolean("showPaths", target.showPaths);
    target.pathScaleWithZoom = b.getBoolean("pathScaleWithZoom", target.pathScaleWithZoom);
    target.pathScaleRefZoom = b.getFloat("pathScaleRefZoom", target.pathScaleRefZoom);
  }

  if (r.hasKey("zones")) {
    JSONObject b = r.getJSONObject("zones");
    target.zoneStrokeAlpha01 = b.getFloat("zoneStrokeAlpha01", target.zoneStrokeAlpha01);
    target.zoneStrokeSizePx = b.getFloat("zoneStrokeSizePx", target.zoneStrokeSizePx);
    target.zoneStrokeSatScale01 = b.getFloat("zoneStrokeSatScale01", target.zoneStrokeSatScale01);
    target.zoneStrokeBriScale01 = b.getFloat("zoneStrokeBriScale01", target.zoneStrokeBriScale01);
    target.zoneStrokeScaleWithZoom = b.getBoolean("zoneStrokeScaleWithZoom", target.zoneStrokeScaleWithZoom);
    target.zoneStrokeRefZoom = b.getFloat("zoneStrokeRefZoom", target.zoneStrokeRefZoom);
  }

  if (r.hasKey("structures")) {
    JSONObject b = r.getJSONObject("structures");
    target.showStructures = b.getBoolean("showStructures", target.showStructures);
    target.mergeStructures = b.getBoolean("mergeStructures", target.mergeStructures);
    target.structureSatScale01 = b.getFloat("structureSatScale01", target.structureSatScale01);
    target.structureAlphaScale01 = b.getFloat("structureAlphaScale01", target.structureAlphaScale01);
    target.structureShadowAlpha01 = b.getFloat("structureShadowAlpha01", target.structureShadowAlpha01);
    target.structureStrokeScaleWithZoom = b.getBoolean("structureStrokeScaleWithZoom", target.structureStrokeScaleWithZoom);
    target.structureStrokeRefZoom = b.getFloat("structureStrokeRefZoom", target.structureStrokeRefZoom);
  }

  if (r.hasKey("labels")) {
    JSONObject b = r.getJSONObject("labels");
    target.showLabelsArbitrary = b.getBoolean("showLabelsArbitrary", target.showLabelsArbitrary);
    target.showLabelsZones = b.getBoolean("showLabelsZones", target.showLabelsZones);
    target.showLabelsPaths = b.getBoolean("showLabelsPaths", target.showLabelsPaths);
    target.showLabelsStructures = b.getBoolean("showLabelsStructures", target.showLabelsStructures);
    target.labelOutlineAlpha01 = b.getFloat("labelOutlineAlpha01", target.labelOutlineAlpha01);
    target.labelOutlineSizePx = b.getFloat("labelOutlineSizePx", target.labelOutlineSizePx);
    target.labelSizeArbPx = b.getFloat("labelSizeArbPx", target.labelSizeArbPx);
    target.labelSizeZonePx = b.getFloat("labelSizeZonePx", target.labelSizeZonePx);
    target.labelSizePathPx = b.getFloat("labelSizePathPx", target.labelSizePathPx);
    target.labelSizeStructPx = b.getFloat("labelSizeStructPx", target.labelSizeStructPx);
    target.labelOutlineScaleWithZoom = b.getBoolean("labelOutlineScaleWithZoom", target.labelOutlineScaleWithZoom);
    target.labelFontIndex = b.getInt("labelFontIndex", target.labelFontIndex);
    if (LABEL_FONT_OPTIONS != null && LABEL_FONT_OPTIONS.length > 0) {
      target.labelFontIndex = constrain(target.labelFontIndex, 0, LABEL_FONT_OPTIONS.length - 1);
    } else {
      target.labelFontIndex = 0;
    }
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
    o.setInt("patternIndex", z.patternIndex);
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
    int defPat = (mapModel != null) ? mapModel.defaultPatternIndexForBiome(i) : 0;
    z.patternIndex = o.getInt("patternIndex", defPat);
    list.add(z);
  }
  return list;
}

void loadBiomePatternList() {
  ArrayList<String> names = new ArrayList<String>();
  HashSet<String> seen = new HashSet<String>();
  String[] roots = { dataPath("patterns"), sketchPath("patterns") };
  for (String root : roots) {
    try {
      if (root == null) continue;
      File dir = new File(root);
      if (!dir.exists() || !dir.isDirectory()) continue;
      File[] files = dir.listFiles();
      if (files == null) continue;
      for (File f : files) {
        if (f == null || !f.isFile() || f.isHidden()) continue;
        String name = f.getName();
        if (name == null) continue;
        String low = name.toLowerCase();
        if (!low.endsWith(".png")) continue;
        if (seen.contains(name)) continue;
        seen.add(name);
        names.add(name);
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
  Collections.sort(names);
  if (!names.isEmpty()) {
    if (renderSettings != null) {
      String curPat = renderSettings.biomePatternName;
      boolean keep = (curPat != null && names.contains(curPat));
      if (!keep) renderSettings.biomePatternName = names.get(0);
    }
  } else {
    println("No biome patterns found under data/sketch patterns directories.");
  }
  if (mapModel != null) mapModel.setBiomePatternFiles(names);
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
    z.col = hsb01ToARGB(z.hue01, z.sat01, z.bri01, 1.0f);
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
  loadingHoldFrames = 0;
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
void stepFullGenerateFromCells() {
  if (!fullGenRunning || mapModel == null) return;
  String stageLabel = "";
  switch (fullGenStep) {
    case 0: stageLabel = "Full gen: elevation + plateaus"; break;
    case 1: stageLabel = "Full gen: biomes"; break;
    case 2: stageLabel = "Full gen: zones"; break;
    case 3: stageLabel = "Full gen: paths"; break;
    case 4: stageLabel = "Full gen: structures"; break;
    case 5: stageLabel = "Full gen: labels"; break;
    default: stageLabel = ""; break;
  }
  if (!fullGenPrimed) {
    loadingDetail = stageLabel;
    fullGenPrimed = true;
    return;
  }
  switch (fullGenStep) {
    case 0: {
      loadingDetail = stageLabel;
      loadingPct = 0.05f;
      noiseSeed((int)random(Integer.MAX_VALUE));
      mapModel.generateElevationNoise(elevationNoiseScale, 1.0f, seaLevel);
      for (int i = 0; i < 15; i++) {
        mapModel.makePlateaus(seaLevel);
      }
      loadingPct = 0.20f;
      fullGenPrimed = false;
      fullGenStep++;
      break;
    }
    case 1: {
      loadingDetail = stageLabel;
      biomeGenerateModeIndex = max(0, biomeGenerateModes.length - 1);
      applyBiomeGeneration();
      loadingPct = 0.35f;
      fullGenPrimed = false;
      fullGenStep++;
      break;
    }
    case 2: {
      loadingDetail = stageLabel;
      int targetZones = (mapModel.zones == null || mapModel.zones.isEmpty()) ? 5 : mapModel.zones.size();
      mapModel.regenerateRandomZones(targetZones);
      activeZoneIndex = -1;
      editingZoneNameIndex = -1;
      editingZoneComment = false;
      mapModel.removeUnderwaterCellsFromZone(-1, seaLevel);
      loadingPct = 0.45f;
      fullGenPrimed = false;
      fullGenStep++;
      break;
    }
    case 3: {
      loadingDetail = stageLabel;
      selectedPathIndex = -1;
      pendingPathStart = null;
      mapModel.generatePathsAuto(seaLevel);
      loadingPct = 0.70f;
      fullGenPrimed = false;
      fullGenStep++;
      break;
    }
    case 4: {
      loadingDetail = stageLabel;
      mapModel.generateStructuresAuto(structGenTownCount, structGenBuildingDensity, seaLevel);
      clearStructureSelection();
      loadingPct = 0.85f;
      fullGenPrimed = false;
      fullGenStep++;
      break;
    }
    case 5: {
      loadingDetail = stageLabel;
      mapModel.generateArbitraryLabels(seaLevel);
      selectedLabelIndex = -1;
      editingLabelIndex = -1;
      editingLabelCommentIndex = -1;
      loadingPct = 1.0f;
      markRenderDirty();
      fullGenPrimed = false;
      fullGenStep++;
      break;
    }
    default: {
      fullGenRunning = false;
      stopLoading();
      loadingDetail = "";
      loadingPct = 1.0f;
      fullGenPrimed = false;
      break;
    }
  }
}

// Compute inner world rect for export based on padding; returns {x, y, w, h}
float[] exportInnerRect() {
  float worldW = mapModel.maxX - mapModel.minX;
  float worldH = mapModel.maxY - mapModel.minY;
  float safePad = constrain(renderPaddingPct, 0, 0.49f); // avoid collapsing to zero
  float padX = max(0, safePad) * worldW;
  float padY = max(0, safePad) * worldH;
  float innerWX = mapModel.minX + padX;
  float innerWY = mapModel.minY + padY;
  float innerWW = worldW - padX * 2;
  float innerWH = worldH - padY * 2;
  return new float[]{ innerWX, innerWY, innerWW, innerWH };
}

boolean ensureExportPreview() {
  if (mapModel == null || mapModel.renderer == null) return false;
  if (!exportPreviewDirty && exportPreview != null) return true;
  float[] rect = exportInnerRect();
  float innerWX = rect[0], innerWY = rect[1], innerWW = rect[2], innerWH = rect[3];
  if (innerWW <= 1e-6f || innerWH <= 1e-6f) return false;

  float innerAspect = innerWW / innerWH;
  float safeScale = constrain(exportScale, 0.1f, 8.0f);
  int pxH = max(1, round(max(1, height) * safeScale));
  int pxW = max(1, round(pxH * innerAspect));
  if (pxW <= 0 || pxH <= 0) return false;

  PGraphics g = null;
  try { g = createGraphics(pxW, pxH, P2D); } catch (Exception ignored) {}
  if (g == null) {
    try { g = createGraphics(pxW, pxH, JAVA2D); } catch (Exception ignored) {}
  }
  if (g == null) return false;

  float prevCenterX = viewport.centerX;
  float prevCenterY = viewport.centerY;
  float prevZoom = viewport.zoom;

  float zoomX = g.width / innerWW;
  float zoomY = g.height / innerWH;
  float newZoom = max(zoomX, zoomY);
  viewport.centerX = innerWX + innerWW * 0.5f;
  viewport.centerY = innerWY + innerWH * 0.5f;
  viewport.zoom = newZoom;

  triggerRenderPrerequisites();

  renderingForExport = true;
  progressActive = true;
  progressDetail = "Export render";
  setProgressStatus("Exporting...");
  try {
    g.beginDraw();
    g.background(245);
    PGraphics prev = this.g;
    this.g = g;
    pushMatrix();
    viewport.applyTransform(g, g.width, g.height);
    drawRenderView(this);
    popMatrix();
    this.g = prev;
    g.endDraw();
    progressPct = 0.65f;

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
      progressPct = 0.9f;
    }
  } finally {
    // Restore viewport
    viewport.centerX = prevCenterX;
    viewport.centerY = prevCenterY;
    viewport.zoom = prevZoom;
    renderingForExport = false;
    progressActive = false;
    progressDetail = "";
    setProgressStatus("Export done");
    progressPct = 1.0f;
  }

  exportPreview = g;
  exportPreviewRect = rect;
  exportPreviewDirty = false;
  return true;
}

void drawExportPreviewView() {
  if (!ensureExportPreview()) {
    drawRenderView(this); // fallback
    return;
  }
  float wx = exportPreviewRect[0];
  float wy = exportPreviewRect[1];
  float ww = exportPreviewRect[2];
  float wh = exportPreviewRect[3];
  PVector tl = viewport.worldToScreen(wx, wy);
  PVector br = viewport.worldToScreen(wx + ww, wy + wh);
  float sx = min(tl.x, br.x);
  float sy = min(tl.y, br.y);
  float sw = abs(br.x - tl.x);
  float sh = abs(br.y - tl.y);
  pushStyle();
  pushMatrix();
  resetMatrix();
  imageMode(CORNER);
  image(exportPreview, sx, sy, sw, sh);
  popMatrix();
  popStyle();
}
