
import java.util.HashMap;
import java.util.HashSet;
import java.util.ArrayDeque;
import java.util.PriorityQueue;
import java.util.Comparator;
import java.util.Collections;
import java.util.Arrays;
import java.util.Map;

// Shared contour job types (must be top-level for Processing)
enum ContourJobType {
  COAST_DISTANCE,
  ELEVATION_SAMPLE
}

class MapModel {
  // Zone style constants
  final float ZONE_BASE_SAT = 0.78f;
  final float ZONE_BASE_BRI = 0.9f;
  // World bounds in world coordinates
  float minX = 0.0f;
  float minY = 0.0f;
  float maxX = 1.0f;
  float maxY = 1.0f;

  ArrayList<Site> sites = new ArrayList<Site>();
  ArrayList<Cell> cells = new ArrayList<Cell>();
  // Coast contour cache
  ContourGrid cachedCoastGrid = null;
  CoastSpatialIndex cachedCoastIndex = null;
  float cachedCoastSeaLevel = Float.MAX_VALUE;
  int cachedCoastCols = 0;
  int cachedCoastRows = 0;
  int cachedCoastCellCount = -1;
  boolean coastCacheValid = false;
  ContourGrid cachedElevationGrid = null;
  float cachedElevationSeaLevel = Float.MAX_VALUE;
  int cachedElevationCols = 0;
  int cachedElevationRows = 0;
  int cachedElevationCellCount = -1;
  boolean elevationCacheValid = false;

  ContourJob coastJob = null;
  ContourJob elevationJob = null;

  // Paths (roads, rivers, etc.)
  ArrayList<Path> paths = new ArrayList<Path>();
  ArrayList<PathType> pathTypes = new ArrayList<PathType>();

  // Biomes / zone types
  ArrayList<ZoneType> biomeTypes = new ArrayList<ZoneType>();
  ArrayList<MapZone> zones = new ArrayList<MapZone>();

  // Cell adjacency (rebuilt when Voronoi is recomputed)
  ArrayList<ArrayList<Integer>> cellNeighbors = new ArrayList<ArrayList<Integer>>();

  ArrayList<Structure> structures = new ArrayList<Structure>();
  ArrayList<MapLabel> labels = new ArrayList<MapLabel>();

  // Lightweight instrumentation for UI display
  float lastPathfindMs = 0;
  int lastPathfindExpanded = 0;
  int lastPathfindLength = 0;
  boolean lastPathfindHit = false;
  float lastSnapBuildMs = 0;
  int lastSnapNodeCount = 0;
  int lastSnapEdgeCount = 0;

  boolean voronoiDirty = true;
  boolean snapDirty = true;
  ArrayList<Cell> preservedCells = null;
  VoronoiJob voronoiJob = null;
  float voronoiProgress = 0.0f;
  final int VORONOI_BATCH = 120; // sites per frame chunk

  HashMap<String, PVector> snapNodes = new HashMap<String, PVector>();
  HashMap<String, ArrayList<String>> snapAdj = new HashMap<String, ArrayList<String>>();

  MapRenderer renderer;

  MapModel() {
    // biomeTypes will be filled from Main.initBiomeTypes()
    renderer = new MapRenderer(this);
  }

  class MapZone {
    String name;
    int col;
    float hue01 = 0.0f;
    float sat01 = 0.5f;
    float bri01 = 0.9f;
    ArrayList<Integer> cells = new ArrayList<Integer>(); // indices into cells array

    MapZone(String name, int col) {
      this.name = name;
      float[] hsb = rgbToHSB(col);
      float[] sb = zoneBaseSatBri();
      hue01 = hsb[0];
      sat01 = sb[0];
      bri01 = sb[1];
      this.col = hsb01ToRGB(hue01, sat01, bri01);
    }

    void updateColorFromHSB() {
      col = hsb01ToRGB(hue01, ZONE_BASE_SAT, ZONE_BASE_BRI);
      sat01 = ZONE_BASE_SAT;
      bri01 = ZONE_BASE_BRI;
  }
}

  HashMap<String, Float> computeTaperWeightsForType(int typeId, float baseWeight, float minWeight) {
    HashMap<String, Float> weights = new HashMap<String, Float>();
    if (paths == null || paths.isEmpty()) return weights;
    PathType t = getPathType(typeId);
    if (t == null || !t.taperOn) return weights;

    // Per-route taper: start weight depends on start touching water, end weight on end touching water.
    // Anything not touching water uses the minimum weight.
    for (int pi = 0; pi < paths.size(); pi++) {
      Path p = paths.get(pi);
      if (p == null || p.typeId != typeId || !t.taperOn) continue;
      if (p.routes == null) continue;
      for (int ri = 0; ri < p.routes.size(); ri++) {
        ArrayList<PVector> seg = p.routes.get(ri);
        if (seg == null || seg.size() < 2) continue;
        boolean startWater = sampleElevationAt(seg.get(0).x, seg.get(0).y, seaLevel) <= seaLevel;
        boolean endWater = sampleElevationAt(seg.get(seg.size() - 1).x, seg.get(seg.size() - 1).y, seaLevel) <= seaLevel;
        float startW = startWater ? baseWeight : minWeight;
        float endW = endWater ? baseWeight : minWeight;

        // Total length for interpolation; fall back to index-based if degenerate.
        float totalLen = 0;
        float[] segLen = new float[seg.size() - 1];
        for (int si = 0; si < seg.size() - 1; si++) {
          PVector a = seg.get(si);
          PVector b = seg.get(si + 1);
          float dx = b.x - a.x;
          float dy = b.y - a.y;
          float len = sqrt(dx * dx + dy * dy);
          segLen[si] = len;
          totalLen += len;
        }
        float acc = 0;
        for (int si = 0; si < seg.size() - 1; si++) {
          float midT;
          if (totalLen > 1e-6f) {
            midT = (acc + segLen[si] * 0.5f) / totalLen;
          } else {
            midT = (seg.size() <= 1) ? 0 : (si / max(1.0f, (seg.size() - 1.0f)));
          }
          float w = lerp(startW, endW, constrain(midT, 0, 1));
          w = constrain(w, minWeight, baseWeight);
          String ek = pi + ":" + ri + ":" + si;
          weights.put(ek, w);
          acc += segLen[si];
        }
      }
    }

    return weights;
  }

  float[] rgbToHSB(int c) {
    float[] hsb = new float[3];
    rgbToHSB01(c, hsb);
    return hsb;
  }

  float[] zoneBaseSatBri() {
    float[] sb = new float[2];
    sb[0] = ZONE_BASE_SAT;
    sb[1] = ZONE_BASE_BRI;
    return sb;
  }

  int zoneColorForHue(float hue) {
    float[] sb = zoneBaseSatBri();
    return hsb01ToRGB(hue, sb[0], sb[1]);
  }

  float hueDistance01(float a, float b) {
    float d = abs(a - b);
    return min(d, 1.0f - d);
  }

  // Pick a hue on the circle that maximizes the minimum distance to all existing hues.
  float pickMaxGapHue() {
    if (zones == null || zones.isEmpty()) return 0.0f;
    ArrayList<Float> hs = new ArrayList<Float>();
    for (MapZone z : zones) {
      if (z == null) continue;
      float h = z.hue01 % 1.0f;
      if (h < 0) h += 1.0f;
      hs.add(h);
    }
    if (hs.isEmpty()) return 0.0f;

    // Sample the circle; 720 samples gives ~0.5 degree resolution.
    int samples = 720;
    float bestHue = 0.0f;
    float bestScore = -1.0f;
    for (int i = 0; i < samples; i++) {
      float h = i / (float)samples;
      float minD = 1.0f;
      for (float hz : hs) {
        minD = min(minD, hueDistance01(h, hz));
        if (minD < bestScore) break; // early exit if already worse
      }
      if (minD > bestScore) {
        bestScore = minD;
        bestHue = h;
      }
    }
    return bestHue;
  }

  // Van der Corput sequence in base 2 to spread hues: 0, 0.5, 0.25, 0.75, 0.125, ...
  float distributedHueForIndex(int idx) {
    int n = max(0, idx);
    float v = 0;
    float denom = 2.0f;
    while (n > 0) {
      v += (n & 1) * (1.0f / denom);
      denom *= 2.0f;
      n >>= 1;
    }
    return v;
  }

  // ---------- Drawing ----------

  void drawDebugWorldBounds(PApplet app) {
    renderer.drawDebugWorldBounds(app);
  }

  void drawSites(PApplet app) {
    renderer.drawSites(app);
  }

  void drawCells(PApplet app) {
    renderer.drawCells(app);
  }

  void drawCells(PApplet app, boolean showBorders) {
    renderer.drawCells(app, showBorders);
  }

  // Rendering-mode cell draw: keep underwater cells plain blue (no biome tint)
  void drawCellsRender(PApplet app, boolean showBorders) {
    renderer.drawCellsRender(app, showBorders);
  }

  void drawCellsRender(PApplet app, boolean showBorders, boolean desaturate) {
    renderer.drawCellsRender(app, showBorders, desaturate);
  }

  void drawStructures(PApplet app) {
    renderer.drawStructures(app);
  }

  void drawLabels(PApplet app) {
    renderer.drawLabels(app);
  }

  void drawLabelsRender(PApplet app, RenderSettings s) {
    renderer.drawLabelsRender(app, s);
  }

  void drawZoneOutlinesRender(PApplet app, RenderSettings s) {
    renderer.drawZoneOutlinesRender(app, s);
  }

  void drawStructuresRender(PApplet app, RenderSettings s) {
    renderer.drawStructuresRender(app, s);
  }

  void drawRenderAdvanced(PApplet app, RenderSettings settings, float seaLevel) {
    renderer.drawRenderAdvanced(app, settings, seaLevel);
  }

  void drawZoneOutlines(PApplet app) {
    renderer.drawZoneOutlines(app);
  }

  void drawCoastContourLines(PApplet app, float seaLevel, int lines, float spacingFactor) {
    if (cells == null || cells.isEmpty()) return;
    ensureCellNeighborsComputed();

    float worldW = maxX - minX;
    float worldH = maxY - minY;
    float desiredSpacing = max(1e-5f, min(worldW, worldH) * max(0.0f, spacingFactor));

    int cols = max(80, min(200, (int)(sqrt(max(1, cells.size())) * 1.0f)));
    int rows = cols;

    ContourGrid g = getCoastDistanceGrid(cols, rows, seaLevel);
    ArrayList<PVector[]> coastSegs = (cachedCoastIndex != null) ? cachedCoastIndex.segments : null;
    if (g == null) return;

    float maxWaterDist = g.max;
    if (maxWaterDist <= 1e-5f) {
      app.pushStyle();
      app.stroke(0);
      if (coastSegs != null) {
        for (PVector[] seg : coastSegs) app.line(seg[0].x, seg[0].y, seg[1].x, seg[1].y);
      }
      app.popStyle();
      return;
    }
    float spacing = min(desiredSpacing, maxWaterDist * 0.9f);
    spacing = max(spacing, maxWaterDist * 0.2f);

    app.pushStyle();
    app.stroke(0);
    app.noFill();
    float strokeW = 1.5f / max(1e-6f, viewport.zoom);
    app.strokeWeight(strokeW);

    if (coastSegs != null) {
      for (PVector[] seg : coastSegs) {
        app.line(seg[0].x, seg[0].y, seg[1].x, seg[1].y);
      }
    }

    if (lines > 1 && spacing > 1e-6f) {
      drawSignedContourSet(app, g, spacing, spacing, spacing, app.color(0), 1.5f);
    }
    app.popStyle();
  }

  void drawStructureSnapGuides(PApplet app) {
    boolean useWater = snapWaterEnabled;
    boolean useBiomes = snapBiomesEnabled;
    boolean useUnderwater = snapUnderwaterBiomesEnabled;
    boolean useZones = snapZonesEnabled;
    boolean usePaths = snapPathsEnabled;
    boolean useStructures = snapStructuresEnabled;
    boolean useElevation = snapElevationEnabled && snapElevationDivisions > 0;
    if (!useWater && !useBiomes && !useUnderwater && !useZones && !usePaths && !useStructures && !useElevation) return;

    int[] zoneMembership = useZones ? buildZoneMembershipForSnapping() : null;
    int[] elevBuckets = useElevation ? buildElevationBucketsForSnapping(snapElevationDivisions) : null;
    renderer.drawStructureSnapGuides(app, useWater, useBiomes, useUnderwater, useZones,
                                     usePaths, useStructures, useElevation, zoneMembership, elevBuckets);
  }

  float distSq(PVector a, PVector b) {
    float dx = a.x - b.x;
    float dy = a.y - b.y;
    return dx * dx + dy * dy;
  }

  int[] buildZoneMembershipForSnapping() {
    if (cells == null || cells.isEmpty() || zones == null || zones.isEmpty()) return null;
    int n = cells.size();
    int[] membership = new int[n];
    Arrays.fill(membership, -1);
    for (int zi = 0; zi < zones.size(); zi++) {
      MapZone z = zones.get(zi);
      if (z == null || z.cells == null) continue;
      for (int ci : z.cells) {
        if (ci >= 0 && ci < n) {
          membership[ci] = zi;
        }
      }
    }
    return membership;
  }

  int[] buildElevationBucketsForSnapping(int divisions) {
    if (cells == null || cells.isEmpty()) return null;
    int div = max(1, divisions);
    int n = cells.size();
    int[] buckets = new int[n];
    for (int i = 0; i < n; i++) {
      Cell c = cells.get(i);
      float t = (c != null) ? (c.elevation + 1.0f) * 0.5f : 0.5f;
      t = constrain(t, 0, 1);
      int bucket = min(div - 1, max(0, (int)floor(t * div)));
      buckets[i] = bucket;
    }
    return buckets;
  }

  boolean boundaryActiveForSnapping(Cell a, Cell b, int idxA, int idxB,
                                    int[] zoneMembership, int[] elevBuckets,
                                    boolean useWater, boolean useBiomes, boolean useUnderwaterBiomes,
                                    boolean useZones, boolean useElevation) {
    if (a == null || b == null) return false;
    boolean aWater = (a.elevation < seaLevel);
    boolean bWater = (b.elevation < seaLevel);
    if (useWater && aWater != bWater) return true;
    if (useBiomes && !aWater && !bWater && a.biomeId != b.biomeId) return true;
    if (useUnderwaterBiomes && aWater && bWater && a.biomeId != b.biomeId) return true;
    if (useZones && zoneMembership != null &&
        idxA >= 0 && idxA < zoneMembership.length &&
        idxB >= 0 && idxB < zoneMembership.length &&
        zoneMembership[idxA] >= 0 && zoneMembership[idxB] >= 0 &&
        zoneMembership[idxA] != zoneMembership[idxB]) {
      return true;
    }
    if (useElevation && elevBuckets != null &&
        idxA >= 0 && idxA < elevBuckets.length &&
        idxB >= 0 && idxB < elevBuckets.length &&
        elevBuckets[idxA] != elevBuckets[idxB]) {
      return true;
    }
    return false;
  }

  Structure computeSnappedStructure(float wx, float wy, float size) {
    Structure s = new Structure(wx, wy);
    s.name = "Struct " + (structures.size() + 1);
    s.size = size;
    s.shape = structureShape;
    s.aspect = structureAspectRatio;
    s.setHue(structureHue01);
    s.setSaturation(structureSat01);
    s.setAlpha(structureAlpha01);
    s.strokeWeightPx = structureStrokePx;
    // Keep magnetism roughly constant in screen space: smaller in world units when zoomed in.
    float snapRangePx = 20.0f;
    float snapRange = max(0.01f, snapRangePx / max(1e-3f, viewport.zoom));

    if (structureSnapMode == StructureSnapMode.NONE) {
      s.angle = lastStructureSnapAngle + structureAngleOffsetRad;
      return s;
    }

    boolean usePaths = snapPathsEnabled;
    boolean useFrontiers = snapWaterEnabled || snapBiomesEnabled || snapUnderwaterBiomesEnabled || snapZonesEnabled || (snapElevationEnabled && snapElevationDivisions > 0);
    boolean useStructures = snapStructuresEnabled;
    int[] zoneMembership = useFrontiers && snapZonesEnabled ? buildZoneMembershipForSnapping() : null;
    int[] elevBuckets = (useFrontiers && snapElevationEnabled && snapElevationDivisions > 0)
                        ? buildElevationBucketsForSnapping(snapElevationDivisions)
                        : null;

    // Snap priority: paths > frontier guides (biome/water) > other structures
    PVector[] seg = (usePaths) ? nearestPathSegment(wx, wy, snapRange) : null;
    if (seg != null) {
      PVector a = seg[0];
      PVector b = seg[1];
      PVector p = seg[2];
      float dx = b.x - a.x;
      float dy = b.y - a.y;
      float ang = atan2(dy, dx);
      if (structureSnapMode == StructureSnapMode.ON_PATH) {
        s.x = p.x;
        s.y = p.y;
      } else {
        float nx = -sin(ang);
        float ny = cos(ang);
        float offset = s.size * 0.6f;
        // Flip side based on cursor side of the segment
        float side = (wx - p.x) * nx + (wy - p.y) * ny;
        if (side < 0) offset = -offset;
        s.x = p.x + nx * offset;
        s.y = p.y + ny * offset;
      }
      lastStructureSnapAngle = ang;
      s.angle = ang + structureAngleOffsetRad;
      return s;
    }

    PVector[] guide = (useFrontiers)
      ? nearestFrontierSegment(wx, wy, snapRange,
                               snapWaterEnabled, snapBiomesEnabled, snapUnderwaterBiomesEnabled,
                               snapZonesEnabled, snapElevationEnabled && elevBuckets != null,
                               zoneMembership, elevBuckets)
      : null;
    if (guide != null) {
      PVector a = guide[0];
      PVector b = guide[1];
      PVector p = guide[2];
      float dx = b.x - a.x;
      float dy = b.y - a.y;
      float ang = atan2(dy, dx);
      if (structureSnapMode == StructureSnapMode.ON_PATH) {
        s.x = p.x;
        s.y = p.y;
      } else {
        float nx = -sin(ang);
        float ny = cos(ang);
        float offset = s.size * 0.6f;
        float side = (wx - p.x) * nx + (wy - p.y) * ny;
        if (side < 0) offset = -offset;
        s.x = p.x + nx * offset;
        s.y = p.y + ny * offset;
      }
      lastStructureSnapAngle = ang;
      s.angle = ang + structureAngleOffsetRad;
      return s;
    }

    // Next: snap to other structures (edge-to-edge)
    if (useStructures) {
      Structure closest = null;
      float bestD2 = snapRange * snapRange;
      for (Structure o : structures) {
        float dx = o.x - wx;
        float dy = o.y - wy;
        float d2 = dx * dx + dy * dy;
        if (d2 < bestD2) {
          bestD2 = d2;
          closest = o;
        }
      }
      if (closest != null) {
        // Snap edge-to-edge with a small margin so shapes don't overlap visually.
        float ang = atan2(wy - closest.y, wx - closest.x);
        float halfA = closest.size * 0.5f;
        float halfB = s.size * 0.5f;
        float margin = max(0.003f, min(halfA, halfB) * 0.12f);
        float targetDist = halfA + halfB + margin;
        s.x = closest.x + cos(ang) * targetDist;
        s.y = closest.y + sin(ang) * targetDist;
        lastStructureSnapAngle = ang;
        s.angle = ang + structureAngleOffsetRad;
        return s;
      }
    }

    s.angle = lastStructureSnapAngle + structureAngleOffsetRad;
    return s;
  }

  void drawElevationOverlay(PApplet app, float seaLevel, boolean showElevationContours, boolean drawWater, boolean drawElevation,
                            boolean showWaterContours, int quantSteps) {
    // Default: no lighting, just grayscale
    drawElevationOverlay(app, seaLevel, showElevationContours, drawWater, drawElevation, showWaterContours,
                         false, 135.0f, 45.0f, quantSteps);
  }

  void drawElevationOverlay(PApplet app, float seaLevel, boolean showElevationContours, boolean drawWater, boolean drawElevation,
                            boolean showWaterContours, boolean useLighting, float lightAzimuthDeg, float lightAltitudeDeg, int quantSteps) {
    if (useNewElevationShading) {
      ElevationRenderer.drawOverlay(this, app, seaLevel, showElevationContours, drawWater, drawElevation,
                                    showWaterContours, useLighting, lightAzimuthDeg, lightAltitudeDeg, quantSteps,
                                    renderBlackWhite);
    } else {
      drawElevationOverlayLegacy(app, seaLevel, showElevationContours, drawWater, drawElevation, showWaterContours,
                                 useLighting, lightAzimuthDeg, lightAltitudeDeg, quantSteps);
    }
  }

  void drawElevationOverlayLegacy(PApplet app, float seaLevel, boolean showElevationContours, boolean drawWater, boolean drawElevation,
                                  boolean showWaterContours, boolean useLighting, float lightAzimuthDeg, float lightAltitudeDeg, int quantSteps) {
    if (cells == null) return;
    app.pushStyle();
    app.noStroke();

    PVector lightDir = null;
    if (useLighting) {
      float az = radians(lightAzimuthDeg);
      float alt = radians(lightAltitudeDeg);
      lightDir = new PVector(cos(alt) * cos(az), cos(alt) * sin(az), sin(alt));
      lightDir.normalize();
    }

    int cellCount = cells.size();
    for (int ci = 0; ci < cellCount; ci++) {
      Cell c = cells.get(ci);
      if (c.vertices == null || c.vertices.size() < 3) continue;
      float h = c.elevation;
      if (drawElevation) {
        float shade = constrain((h + 0.5f), 0, 1); // center on 0
        float light = 1.0f;
        if (useLighting && lightDir != null) {
          light = ElevationRenderer.computeLightForCell(this, ci, lightDir);
        }
        float litShade = constrain(shade * light, 0, 1);
        if (quantSteps > 1) {
          float levels = quantSteps - 1;
          litShade = round(litShade * levels) / levels;
        }
        int col = renderBlackWhite ? app.color(litShade * 255) : app.color(litShade * 255);
        app.fill(col, 140);
        app.beginShape();
        for (PVector v : c.vertices) app.vertex(v.x, v.y);
        app.endShape(CLOSE);
      }

      if (drawWater && h < seaLevel) {
        float depth = seaLevel - h;
        float depthNorm = constrain(depth / 1.0f, 0, 1);
        float shade = drawElevation ? lerp(0.25f, 0.65f, 1.0f - depthNorm) : 0.55f;
        if (quantSteps > 1) {
          float levels = quantSteps - 1;
          shade = round(shade * levels) / levels;
        }
        float baseR = 30;
        float baseG = 70;
        float baseB = 120;
        int water;
        if (renderBlackWhite) {
          float gray = shade * 255;
          water = app.color(gray, gray, gray, 255);
        } else {
          water = app.color(baseR * shade, baseG * shade, baseB * shade, 255);
        }
        app.fill(water);
        app.beginShape();
        for (PVector v : c.vertices) app.vertex(v.x, v.y);
        app.endShape(CLOSE);
      }
    }

    if (showElevationContours || showWaterContours) {
      int cols = 90;
      int rows = 90;
      ContourGrid grid = sampleElevationGrid(cols, rows, seaLevel);
      float minElev = grid.min;
      float maxElev = grid.max;

      if (showElevationContours) {
        float range = max(1e-4f, maxElev - seaLevel);
        float step = max(0.02f, range / 10.0f);
        float start = ceil(seaLevel / step) * step;
        int strokeCol = renderBlackWhite ? app.color(40) : app.color(50, 50, 50, 180);
        drawContourSet(app, grid, start, maxElev, step, strokeCol);
      }

      if (showWaterContours && drawWater) {
        float minWater = minElev;
        if (minWater < seaLevel - 1e-4f) {
          float depthRange = seaLevel - minWater;
          float step = max(0.02f, depthRange / 5.0f);
          float start = seaLevel - step;
          int strokeCol = renderBlackWhite ? app.color(60) : app.color(30, 70, 140, 170);
          drawContourSet(app, grid, start, minWater, -step, strokeCol);
        }
      }
    }
    app.popStyle();
  }

  class ContourGrid {
    float[][] v;
    int cols;
    int rows;
    float dx;
    float dy;
    float ox;
    float oy;
    float min;
    float max;
  }

  class ContourJob {
    ContourJobType type;
    ContourGrid grid;
    CoastSpatialIndex coastIndex;
    float seaLevel;
    int cols;
    int rows;
    int nextRow = 0;
    int cellCountSnapshot = 0;
    boolean done = false;
    boolean failed = false;

    ContourJob(ContourJobType type, int cols, int rows, float seaLevel) {
      this.type = type;
      this.cols = max(2, cols);
      this.rows = max(2, rows);
      this.seaLevel = seaLevel;
      this.cellCountSnapshot = (cells != null) ? cells.size() : 0;

      grid = new ContourGrid();
      grid.cols = this.cols;
      grid.rows = this.rows;
      grid.v = new float[grid.rows][grid.cols];
      grid.ox = minX;
      grid.oy = minY;
      grid.dx = (maxX - minX) / (grid.cols - 1);
      grid.dy = (maxY - minY) / (grid.rows - 1);
      grid.min = Float.MAX_VALUE;
      grid.max = -Float.MAX_VALUE;

      if (type == ContourJobType.COAST_DISTANCE) {
        ensureCellNeighborsComputed();
        ArrayList<PVector[]> segs = collectCoastSegments(seaLevel);
        if (segs == null || segs.isEmpty()) {
          failed = true;
          done = true;
          return;
        }
        coastIndex = new CoastSpatialIndex(minX, minY, maxX, maxY, segs, 80);
      }
    }

    boolean matches(ContourJobType t, int c, int r, float sl) {
      return type == t && cols == max(2, c) && rows == max(2, r) && abs(sl - seaLevel) < 1e-6f;
    }

    float progress() {
      if (grid == null || grid.rows <= 0) return 0;
      return constrain(nextRow / max(1.0f, (float)grid.rows), 0, 1);
    }

    void step(int maxMillis) {
      if (done || grid == null) return;
      long deadline = System.nanoTime() + max(1, maxMillis) * 1_000_000L;
      while (nextRow < grid.rows && System.nanoTime() < deadline) {
        float y = grid.oy + nextRow * grid.dy;
        if (type == ContourJobType.COAST_DISTANCE) {
          if (coastIndex == null) { failed = true; done = true; break; }
          for (int i = 0; i < grid.cols; i++) {
            float x = grid.ox + i * grid.dx;
            boolean water = sampleElevationAt(x, y, seaLevel) < seaLevel;
            float d = coastIndex.nearestDist(x, y);
            float val = water ? d : -d;
            grid.v[nextRow][i] = val;
            grid.min = min(grid.min, val);
            grid.max = max(grid.max, val);
          }
        } else {
          for (int i = 0; i < grid.cols; i++) {
            float x = grid.ox + i * grid.dx;
            float val = sampleElevationAt(x, y, seaLevel);
            grid.v[nextRow][i] = val;
            grid.min = min(grid.min, val);
            grid.max = max(grid.max, val);
          }
        }
        nextRow++;
      }
      if (nextRow >= grid.rows) {
        done = true;
      }
    }
  }

  ContourGrid sampleElevationGrid(int cols, int rows, float fallback) {
    return renderer.sampleElevationGrid(cols, rows, fallback);
  }

  void drawContourSet(PApplet app, ContourGrid g, float start, float end, float step, int strokeCol) {
    renderer.drawContourSet(app, g, start, end, step, strokeCol);
  }

  void drawIsoLine(PApplet app, ContourGrid g, float iso) {
    renderer.drawIsoLine(app, g, iso);
  }

  void drawSeg(PApplet app, PVector a, PVector b) {
    renderer.drawSeg(app, a, b);
  }

  PVector interpIso(float x0, float y0, float v0, float x1, float y1, float v1, float iso) {
    return renderer.interpIso(x0, y0, v0, x1, y1, v1, iso);
  }

  HashMap<String, PVector[]> edgeMapForCell(Cell c) {
    HashMap<String, PVector[]> map = new HashMap<String, PVector[]>();
    if (c == null || c.vertices == null) return map;
    int vc = c.vertices.size();
    for (int i = 0; i < vc; i++) {
      PVector a = c.vertices.get(i);
      PVector b = c.vertices.get((i + 1) % vc);
      map.put(undirectedEdgeKey(a, b), new PVector[] { a, b });
    }
    return map;
  }

  String undirectedEdgeKey(PVector a, PVector b) {
    int scale = 100000;
    int ax = round(a.x * scale);
    int ay = round(a.y * scale);
    int bx = round(b.x * scale);
    int by = round(b.y * scale);
    if (ax < bx || (ax == bx && ay <= by)) {
      return ax + "," + ay + "-" + bx + "," + by;
    } else {
      return bx + "," + by + "-" + ax + "," + ay;
    }
  }

  PVector[] sharedEdgeBetweenCells(Cell a, Cell b) {
    if (a == null || b == null || a.vertices == null || b.vertices == null) return null;
    int va = a.vertices.size();
    int vb = b.vertices.size();
    for (int i = 0; i < va; i++) {
      PVector a0 = a.vertices.get(i);
      PVector a1 = a.vertices.get((i + 1) % va);
      for (int j = 0; j < vb; j++) {
        PVector b0 = b.vertices.get(j);
        PVector b1 = b.vertices.get((j + 1) % vb);
        boolean match = (distSq(a0, b0) < 1e-10f && distSq(a1, b1) < 1e-10f) ||
                        (distSq(a0, b1) < 1e-10f && distSq(a1, b0) < 1e-10f);
        if (match) return new PVector[] { a0, a1 };
      }
    }
    return null;
  }

  float cross2d(PVector a, PVector b, PVector c) {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
  }

  boolean onSegment(PVector a, PVector b, PVector p, float eps) {
    float minx = min(a.x, b.x) - eps;
    float maxx = max(a.x, b.x) + eps;
    float miny = min(a.y, b.y) - eps;
    float maxy = max(a.y, b.y) + eps;
    return abs(cross2d(a, b, p)) <= eps && p.x >= minx && p.x <= maxx && p.y >= miny && p.y <= maxy;
  }

  boolean segmentsIntersect(PVector a1, PVector a2, PVector b1, PVector b2, float eps) {
    float o1 = cross2d(a1, a2, b1);
    float o2 = cross2d(a1, a2, b2);
    float o3 = cross2d(b1, b2, a1);
    float o4 = cross2d(b1, b2, a2);

    if ((o1 > 0 && o2 < 0 || o1 < 0 && o2 > 0) && (o3 > 0 && o4 < 0 || o3 < 0 && o4 > 0)) {
      return true;
    }

    if (abs(o1) <= eps && onSegment(a1, a2, b1, eps)) return true;
    if (abs(o2) <= eps && onSegment(a1, a2, b2, eps)) return true;
    if (abs(o3) <= eps && onSegment(b1, b2, a1, eps)) return true;
    if (abs(o4) <= eps && onSegment(b1, b2, a2, eps)) return true;

    return false;
  }

  ArrayList<PVector[]> collectCoastSegments(float seaLevel) {
    ArrayList<PVector[]> segs = new ArrayList<PVector[]>();
    if (cells == null || cells.isEmpty()) return segs;
    int n = cells.size();
    for (int ci = 0; ci < n; ci++) {
      Cell a = cells.get(ci);
      if (a == null || a.vertices == null) continue;
      boolean waterA = a.elevation < seaLevel;
      ArrayList<Integer> nbs = (ci < cellNeighbors.size()) ? cellNeighbors.get(ci) : null;
      if (nbs == null) continue;
      HashSet<String> seen = new HashSet<String>();
      for (int nb : nbs) {
        if (nb < 0 || nb >= n || nb <= ci) continue;
        Cell b = cells.get(nb);
        if (b == null || b.vertices == null) continue;
        boolean waterB = b.elevation < seaLevel;
        if (waterA == waterB) continue;

        // find shared edges
        int va = a.vertices.size();
        for (int i = 0; i < va; i++) {
          PVector p0 = a.vertices.get(i);
          PVector p1 = a.vertices.get((i + 1) % va);
          String key = undirectedEdgeKey(p0, p1);
          if (seen.contains(key)) continue;
          int vb = b.vertices.size();
          for (int j = 0; j < vb; j++) {
            PVector q0 = b.vertices.get(j);
            PVector q1 = b.vertices.get((j + 1) % vb);
            if (distSq(p0, q0) < 1e-10f && distSq(p1, q1) < 1e-10f ||
                distSq(p0, q1) < 1e-10f && distSq(p1, q0) < 1e-10f) {
              segs.add(new PVector[] { p0.copy(), p1.copy() });
              seen.add(key);
              break;
            }
          }
        }
      }
    }
    return segs;
  }

  ContourGrid sampleCoastDistanceGrid(int cols, int rows, float seaLevel, CoastSpatialIndex idx) {
    if (idx == null) return null;
    ContourGrid g = new ContourGrid();
    g.cols = max(2, cols);
    g.rows = max(2, rows);
    g.v = new float[g.rows][g.cols];
    g.ox = minX;
    g.oy = minY;
    g.dx = (maxX - minX) / (g.cols - 1);
    g.dy = (maxY - minY) / (g.rows - 1);
    g.min = Float.MAX_VALUE;
    g.max = -Float.MAX_VALUE;

    for (int j = 0; j < g.rows; j++) {
      float y = g.oy + j * g.dy;
      for (int i = 0; i < g.cols; i++) {
        float x = g.ox + i * g.dx;
        boolean water = sampleElevationAt(x, y, seaLevel) < seaLevel;
        float d = idx.nearestDist(x, y);
        float val = water ? d : -d;
        g.v[j][i] = val;
        g.min = min(g.min, val);
        g.max = max(g.max, val);
      }
    }
    return g;
  }

  ContourGrid getCoastDistanceGrid(int cols, int rows, float seaLevel) {
    if (cells == null || cells.isEmpty()) return null;
    if (coastCacheValid &&
        cachedCoastSeaLevel == seaLevel &&
        cachedCoastCols == cols &&
        cachedCoastRows == rows &&
        cachedCoastCellCount == cells.size()) {
      return cachedCoastGrid;
    }
    if (coastJob != null && coastJob.matches(ContourJobType.COAST_DISTANCE, cols, rows, seaLevel)) {
      return null;
    }
    coastJob = new ContourJob(ContourJobType.COAST_DISTANCE, cols, rows, seaLevel);
    return null;
  }

  ContourGrid getElevationGridForRender(int cols, int rows, float seaLevel) {
    if (cells == null || cells.isEmpty()) return null;
    if (elevationCacheValid &&
        cachedElevationSeaLevel == seaLevel &&
        cachedElevationCols == cols &&
        cachedElevationRows == rows &&
        cachedElevationCellCount == cells.size()) {
      return cachedElevationGrid;
    }
    if (elevationJob != null && elevationJob.matches(ContourJobType.ELEVATION_SAMPLE, cols, rows, seaLevel)) {
      return null;
    }
    elevationJob = new ContourJob(ContourJobType.ELEVATION_SAMPLE, cols, rows, seaLevel);
    return null;
  }

  void stepContourJobs(int maxMillis) {
    int budget = max(1, maxMillis);
    if (coastJob != null) {
      coastJob.step(budget);
      if (coastJob.done) finalizeCoastJob();
    }
    if (elevationJob != null) {
      elevationJob.step(budget);
      if (elevationJob.done) finalizeElevationJob();
    }
  }

  boolean isContourJobRunning() {
    return (coastJob != null && !coastJob.done) || (elevationJob != null && !elevationJob.done);
  }

  float getContourJobProgress() {
    float p = 1.0f;
    if (coastJob != null && !coastJob.done) p = min(p, coastJob.progress());
    if (elevationJob != null && !elevationJob.done) p = min(p, elevationJob.progress());
    return p;
  }

  private void finalizeCoastJob() {
    if (coastJob == null) return;
    if (coastJob.failed || coastJob.grid == null || coastJob.cellCountSnapshot != ((cells != null) ? cells.size() : 0)) {
      cachedCoastGrid = null;
      cachedCoastIndex = null;
      coastCacheValid = true;
      cachedCoastSeaLevel = coastJob.seaLevel;
      cachedCoastCols = coastJob.cols;
      cachedCoastRows = coastJob.rows;
      cachedCoastCellCount = coastJob.cellCountSnapshot;
    } else {
      cachedCoastGrid = coastJob.grid;
      cachedCoastIndex = coastJob.coastIndex;
      cachedCoastSeaLevel = coastJob.seaLevel;
      cachedCoastCols = coastJob.cols;
      cachedCoastRows = coastJob.rows;
      cachedCoastCellCount = coastJob.cellCountSnapshot;
      coastCacheValid = true;
    }
    coastJob = null;
  }

  private void finalizeElevationJob() {
    if (elevationJob == null) return;
    if (elevationJob.failed || elevationJob.grid == null || elevationJob.cellCountSnapshot != ((cells != null) ? cells.size() : 0)) {
      cachedElevationGrid = null;
      elevationCacheValid = true;
      cachedElevationSeaLevel = elevationJob.seaLevel;
      cachedElevationCols = elevationJob.cols;
      cachedElevationRows = elevationJob.rows;
      cachedElevationCellCount = elevationJob.cellCountSnapshot;
    } else {
      cachedElevationGrid = elevationJob.grid;
      cachedElevationSeaLevel = elevationJob.seaLevel;
      cachedElevationCols = elevationJob.cols;
      cachedElevationRows = elevationJob.rows;
      cachedElevationCellCount = elevationJob.cellCountSnapshot;
      elevationCacheValid = true;
    }
    elevationJob = null;
  }

  void drawSignedContourSet(PApplet app, ContourGrid g, float start, float end, float step, int strokeCol, float strokePx) {
    if (step == 0) return;
    if ((step > 0 && start > end) || (step < 0 && start < end)) return;
    app.pushStyle();
    app.noFill();
    app.stroke(strokeCol);
    app.strokeWeight(strokePx / max(1e-6f, viewport.zoom));
    if (step > 0) {
      for (float iso = start; iso <= end + 1e-6f; iso += step) {
        renderer.drawIsoLine(app, g, iso);
      }
    } else {
      for (float iso = start; iso >= end - 1e-6f; iso += step) {
        renderer.drawIsoLine(app, g, iso);
      }
    }
    app.popStyle();
  }

  class CoastSpatialIndex {
    float ox, oy, dx, dy;
    int cols, rows;
    ArrayList<ArrayList<PVector[]>> bins;
    ArrayList<PVector[]> segments;

    CoastSpatialIndex(float minX, float minY, float maxX, float maxY, ArrayList<PVector[]> segs, int targetBins) {
      ox = minX;
      oy = minY;
      float w = maxX - minX;
      float h = maxY - minY;
      float cellsPerDim = max(4, targetBins);
      cols = max(4, (int)cellsPerDim);
      rows = cols;
      dx = w / cols;
      dy = h / rows;
      bins = new ArrayList<ArrayList<PVector[]>>(cols * rows);
      for (int i = 0; i < cols * rows; i++) bins.add(new ArrayList<PVector[]>());
      segments = segs;
      indexSegments();
    }

    void indexSegments() {
      for (PVector[] seg : segments) {
        PVector a = seg[0];
        PVector b = seg[1];
        float minX = min(a.x, b.x);
        float maxX = max(a.x, b.x);
        float minY = min(a.y, b.y);
        float maxY = max(a.y, b.y);
        int ix0 = clampBin(floor((minX - ox) / dx), cols);
        int ix1 = clampBin(floor((maxX - ox) / dx), cols);
        int iy0 = clampBin(floor((minY - oy) / dy), rows);
        int iy1 = clampBin(floor((maxY - oy) / dy), rows);
        for (int iy = iy0; iy <= iy1; iy++) {
          for (int ix = ix0; ix <= ix1; ix++) {
            bin(ix, iy).add(seg);
          }
        }
      }
    }

    int clampBin(int v, int maxVal) {
      return constrain(v, 0, maxVal - 1);
    }

    ArrayList<PVector[]> bin(int x, int y) {
      return bins.get(y * cols + x);
    }

    float nearestDist(float x, float y) {
      int ix = clampBin(floor((x - ox) / dx), cols);
      int iy = clampBin(floor((y - oy) / dy), rows);
      float best = Float.MAX_VALUE;
      int maxRing = max(cols, rows);
      for (int ring = 0; ring < maxRing; ring++) {
        int x0 = max(0, ix - ring);
        int x1 = min(cols - 1, ix + ring);
        int y0 = max(0, iy - ring);
        int y1 = min(rows - 1, iy + ring);
        boolean found = false;
        for (int yy = y0; yy <= y1; yy++) {
          for (int xx = x0; xx <= x1; xx++) {
            ArrayList<PVector[]> bucket = bin(xx, yy);
            for (PVector[] seg : bucket) {
              float d = pointSegDist(x, y, seg[0], seg[1]);
              if (d < best) {
                best = d;
                found = true;
              }
            }
          }
        }
        if (found && best < max(dx, dy) * ring) break;
      }
      // Fallback if no bins
      if (best == Float.MAX_VALUE) {
        for (PVector[] seg : segments) {
          best = min(best, pointSegDist(x, y, seg[0], seg[1]));
        }
      }
      return best;
    }

    float pointSegDist(float px, float py, PVector a, PVector b) {
      float vx = b.x - a.x;
      float vy = b.y - a.y;
      float wx = px - a.x;
      float wy = py - a.y;
      float c1 = vx * wx + vy * wy;
      if (c1 <= 0) return sqrt(wx * wx + wy * wy);
      float c2 = vx * vx + vy * vy;
      if (c2 <= c1) {
        float dx = px - b.x;
        float dy = py - b.y;
        return sqrt(dx * dx + dy * dy);
      }
      float t = c1 / c2;
      float projX = a.x + t * vx;
      float projY = a.y + t * vy;
      float dx = px - projX;
      float dy = py - projY;
      return sqrt(dx * dx + dy * dy);
    }
  }

  // ---------- Snapping graph ----------

  ArrayList<PVector> getSnapPoints() {
    ensureSnapGraph();
    ArrayList<PVector> result = new ArrayList<PVector>();
    if (snapNodes.isEmpty()) return result;

    // Only keep points near the current viewport and dedupe points that are closer
    // than a small screen-space threshold to reduce overload when there are many sites.
    float marginPx = 20.0f;
    float tolPx = 4.0f;
    float tolWorld = tolPx / viewport.zoom;
    float halfW = (width * 0.5f) / viewport.zoom + marginPx / viewport.zoom;
    float halfH = (height * 0.5f) / viewport.zoom + marginPx / viewport.zoom;
    float minX = viewport.centerX - halfW;
    float maxX = viewport.centerX + halfW;
    float minY = viewport.centerY - halfH;
    float maxY = viewport.centerY + halfH;

    HashMap<String, PVector> dedup = new HashMap<String, PVector>();
    for (PVector p : snapNodes.values()) {
      if (p.x < minX || p.x > maxX || p.y < minY || p.y > maxY) continue;
      int gx = floor(p.x / tolWorld);
      int gy = floor(p.y / tolWorld);
      String key = gx + "_" + gy;
      if (!dedup.containsKey(key)) {
        dedup.put(key, p);
      }
    }
    result.addAll(dedup.values());
    return result;
  }

  ArrayList<PVector> findSnapPath(PVector from, PVector toP) {
    return findSnapPathWeighted(from, toP, false);
  }

  ArrayList<PVector> findSnapPathFlattest(PVector from, PVector toP) {
    return findSnapPathWeighted(from, toP, true);
  }

  ArrayList<PVector> findSnapPathWeighted(PVector from, PVector toP, boolean favorFlat) {
    int tStart = millis();
    ensureSnapGraph();
    String kFrom = keyFor(from.x, from.y);
    String kTo = keyFor(toP.x, toP.y);
    ArrayList<PVector> result = null;
    if (!snapNodes.containsKey(kFrom) || !snapNodes.containsKey(kTo)) {
      lastPathfindMs = millis() - tStart;
      lastPathfindExpanded = 0;
      lastPathfindLength = 0;
      lastPathfindHit = false;
      return null;
    }
    if (kFrom.equals(kTo)) {
      result = new ArrayList<PVector>();
      PVector p = snapNodes.get(kFrom);
      result.add(p);
      result.add(p.copy()); // ensure at least two points so segments can be added
      lastPathfindMs = millis() - tStart;
      lastPathfindExpanded = 0;
      lastPathfindLength = result.size();
      lastPathfindHit = (result.size() > 1);
      return result;
    }

    if (PATH_BIDIRECTIONAL) {
      result = findSnapPathBidirectional(kFrom, kTo, favorFlat, snapNodes, snapAdj);
      lastPathfindMs = millis() - tStart;
      lastPathfindHit = (result != null && result.size() > 1);
      lastPathfindLength = (result != null) ? result.size() : 0;
      return result;
    }

    HashMap<String, Float> dist = new HashMap<String, Float>();
    HashMap<String, String> prev = new HashMap<String, String>();
    PriorityQueue<NodeDist> pq = new PriorityQueue<NodeDist>();
    dist.put(kFrom, 0.0f);
    // A* priority = g + h
    PVector target = snapNodes.get(kTo);
    float hStart = (target != null) ? distSq(snapNodes.get(kFrom), target) : 0;
    pq.add(new NodeDist(kFrom, 0.0f, hStart));

    // Spatial cull to a loose bounding box around endpoints
    float minx = min(from.x, toP.x);
    float maxx = max(from.x, toP.x);
    float miny = min(from.y, toP.y);
    float maxy = max(from.y, toP.y);
    float margin = max(dist2D(from, toP) * 0.6f, 0.05f);
    minx -= margin; maxx += margin; miny -= margin; maxy += margin;

    int maxExpanded = PATH_MAX_EXPANSIONS;
    int expanded = 0;
    String closest = kFrom;
    float bestH = (target != null) ? dist2D(snapNodes.get(kFrom), target) : Float.MAX_VALUE;
    HashMap<String, Float> elevCache = new HashMap<String, Float>();

    while (!pq.isEmpty()) {
      NodeDist nd = pq.poll();
      Float bestD = dist.get(nd.k);
      if (bestD != null && nd.g > bestD + 1e-6f) continue;
      if (nd.k.equals(kTo)) break;
      if (expanded++ > maxExpanded) break;
      ArrayList<String> neighbors = snapAdj.get(nd.k);
      if (neighbors == null) continue;
      PVector p = snapNodes.get(nd.k);
      if (p == null) continue;
      float hCur = (target != null) ? distSq(p, target) : Float.MAX_VALUE;
      if (hCur < bestH) {
        bestH = hCur;
        closest = nd.k;
      }
      for (String nb : neighbors) {
        PVector np = snapNodes.get(nb);
        if (np == null) continue;
        if (np.x < minx || np.x > maxx || np.y < miny || np.y > maxy) continue;
        float w = dist2D(p, np);
        float elevA = elevCache.containsKey(nd.k) ? elevCache.get(nd.k) : sampleElevationAt(p.x, p.y, seaLevel);
        float elevB = elevCache.containsKey(nb) ? elevCache.get(nb) : sampleElevationAt(np.x, np.y, seaLevel);
        elevCache.put(nd.k, elevA);
        elevCache.put(nb, elevB);
        if (pathAvoidWater) {
          boolean aw = elevA < seaLevel;
          boolean bw = elevB < seaLevel;
          if (aw || bw) {
            // Make water extremely undesirable; only used if no land path exists
            w *= 1e6f;
          }
        }
        if (favorFlat) {
          float dh = abs(elevB - elevA);
          // Penalize steep changes; keep distance as base
          w *= (1.0f + dh * flattestSlopeBias);
        }
        float ndist = nd.g + w;
        Float curD = dist.get(nb);
        if (curD == null || ndist < curD - 1e-6f) {
          dist.put(nb, ndist);
          prev.put(nb, nd.k);
          float h = (target != null) ? distSq(np, target) : 0;
          pq.add(new NodeDist(nb, ndist, ndist + h * 0.5f)); // squared heuristic, lighter weight
        }
      }
    }

    if (!prev.containsKey(kTo) && !kFrom.equals(kTo)) {
      if (closest != null) {
        if (closest.equals(kFrom)) {
          result = new ArrayList<PVector>();
          result.add(snapNodes.get(kFrom));
        } else if (prev.containsKey(closest)) {
          result = reconstructPath(prev, kFrom, closest);
        }
      }
    } else {
      result = reconstructPath(prev, kFrom, kTo);
    }

    lastPathfindMs = millis() - tStart;
    lastPathfindExpanded = expanded;
    lastPathfindLength = (result != null) ? result.size() : 0;
    lastPathfindHit = (result != null && result.size() > 1);
    return result;
  }

  void ensureSnapGraph() {
    if (!snapDirty) return;
    recomputeSnappingGraph();
    snapDirty = false;
  }

  void recomputeSnappingGraph() {
    int tStart = millis();
    snapNodes.clear();
    snapAdj.clear();
    if (sites == null || cells == null) return;

    String[] centerKeys = new String[sites.size()];

    // Add centers
    for (int i = 0; i < sites.size(); i++) {
      Site s = sites.get(i);
      centerKeys[i] = ensureNode(s.x, s.y);
    }

    // Connect centers to vertices and polygon edges
    for (Cell c : cells) {
      if (c.vertices == null || c.vertices.size() == 0) continue;
      String centerKey = (c.siteIndex >= 0 && c.siteIndex < centerKeys.length)
        ? centerKeys[c.siteIndex]
        : ensureNode(c.vertices.get(0).x, c.vertices.get(0).y);
      int n = c.vertices.size();
      if (n < 2) continue;
      for (int i = 0; i < n; i++) {
        PVector v = c.vertices.get(i);
        PVector vn = c.vertices.get((i + 1) % n);

        String vk = ensureNode(v.x, v.y);
        String vnk = ensureNode(vn.x, vn.y);

        connectNodes(centerKey, vk);
        connectNodes(vk, vnk);
      }
    }

    // Connect neighboring centers (cells sharing edge) using the precomputed neighbor list
    ensureCellNeighborsComputed();
    int cCount = cells.size();
    for (int i = 0; i < cCount; i++) {
      ArrayList<Integer> nbs = (i < cellNeighbors.size()) ? cellNeighbors.get(i) : null;
      if (nbs == null) continue;
      Cell a = cells.get(i);
      for (int nb : nbs) {
        if (nb <= i) continue;
        Cell b = cells.get(nb);
        if (a != null && b != null &&
            a.siteIndex >= 0 && a.siteIndex < centerKeys.length &&
            b.siteIndex >= 0 && b.siteIndex < centerKeys.length) {
          connectNodes(centerKeys[a.siteIndex], centerKeys[b.siteIndex]);
        }
      }
    }

    pruneUniformFrontierSnapNodes();

    lastSnapNodeCount = snapNodes.size();
    int edgeSum = 0;
    for (ArrayList<String> adj : snapAdj.values()) {
      if (adj != null) edgeSum += adj.size();
    }
    lastSnapEdgeCount = edgeSum / 2; // undirected graph stored twice
    lastSnapBuildMs = millis() - tStart;
  }

  String ensureNode(float x, float y) {
    String k = keyFor(x, y);
    if (!snapNodes.containsKey(k)) {
      snapNodes.put(k, new PVector(x, y));
      snapAdj.put(k, new ArrayList<String>());
    }
    return k;
  }

  void connectNodes(String a, String b) {
    if (a == null || b == null) return;
    if (a.equals(b)) return;
    ArrayList<String> la = snapAdj.get(a);
    ArrayList<String> lb = snapAdj.get(b);
    if (la == null || lb == null) return;
    if (!la.contains(b)) la.add(b);
    if (!lb.contains(a)) lb.add(a);
  }

  void pruneUniformFrontierSnapNodes() {
    if (cells == null || cells.isEmpty()) return;
    ensureCellNeighborsComputed();

    // Collect which cells touch each snap node
    HashMap<String, ArrayList<Integer>> nodeCells = new HashMap<String, ArrayList<Integer>>();
    for (int ci = 0; ci < cells.size(); ci++) {
      Cell c = cells.get(ci);
      if (c.vertices == null) continue;
      for (PVector v : c.vertices) {
        String k = keyFor(v.x, v.y);
        ArrayList<Integer> list = nodeCells.get(k);
        if (list == null) {
          list = new ArrayList<Integer>();
          nodeCells.put(k, list);
        }
        if (!list.contains(ci)) list.add(ci);
      }
    }

    HashSet<String> toRemove = new HashSet<String>();
    for (String k : snapNodes.keySet()) {
      ArrayList<Integer> incident = nodeCells.get(k);
      if (incident == null || incident.isEmpty()) continue;

      int firstIdx = incident.get(0);
      Cell first = cells.get(firstIdx);
      int biome = first.biomeId;
      boolean water = first.elevation < seaLevel;
      boolean allSame = true;
      for (int i = 1; i < incident.size(); i++) {
        Cell c = cells.get(incident.get(i));
        if (c.biomeId != biome || (c.elevation < seaLevel) != water) {
          allSame = false;
          break;
        }
      }
      if (allSame) {
        toRemove.add(k);
      }
    }

    if (toRemove.isEmpty()) return;

    for (String k : toRemove) {
      snapNodes.remove(k);
      snapAdj.remove(k);
    }
    for (ArrayList<String> adj : snapAdj.values()) {
      adj.removeAll(toRemove);
    }
  }

  ArrayList<PVector> reconstructPath(HashMap<String, String> prev, String start, String goal) {
    ArrayList<PVector> out = new ArrayList<PVector>();
    String cur = goal;
    while (cur != null) {
      PVector p = snapNodes.get(cur);
      if (p != null) out.add(0, p);
      if (cur.equals(start)) break;
      cur = prev.get(cur);
    }
    return out;
  }

  String keyFor(float x, float y) {
    int xi = round(x * 10000.0f);
    int yi = round(y * 10000.0f);
    return xi + ":" + yi;
  }

  float sampleElevationAt(float x, float y, float fallback) {
    Cell c = findCellContaining(x, y);
    if (c != null) return c.elevation;
    return fallback;
  }

  float dist2D(PVector a, PVector b) {
    float dx = a.x - b.x;
    float dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }

  class NodeDist implements Comparable<NodeDist> {
    String k;
    float g;
    float f;
    NodeDist(String k, float g, float f) { this.k = k; this.g = g; this.f = f; }
    public int compareTo(NodeDist other) {
      return Float.compare(this.f, other.f);
    }
  }

  void drawPaths(PApplet app, int strokeCol, boolean highlightSelected, boolean showNodes) {
    if (paths.isEmpty()) return;

    app.pushStyle();
    app.noFill();
    HashMap<Integer, HashMap<String, Float>> taperCache = new HashMap<Integer, HashMap<String, Float>>();

    for (int i = 0; i < paths.size(); i++) {
      Path p = paths.get(i);
      if (p.routes.isEmpty()) continue;
      PathType pt = getPathType(p.typeId);
      int col = (pt != null) ? pt.col : strokeCol;
      float w = (pt != null) ? pt.weightPx : 2.0f;
      app.stroke(col);
      boolean taperOn = (pt != null && pt.taperOn);
      HashMap<String, Float> taperW = null;
      if (taperOn) {
        taperW = taperCache.get(p.typeId);
        if (taperW == null) {
          float minW = (pt != null) ? pt.minWeightPx : max(1.0f, w * 0.4f);
          taperW = computeTaperWeightsForType(p.typeId, w, minW);
          taperCache.put(p.typeId, taperW);
        }
      }
      p.draw(app, w, taperOn, taperW, i, showNodes);

      // Debug: draw small dots on all route vertices
      if (showNodes) {
        app.pushStyle();
        app.noStroke();
        app.fill(255, 120, 0, 200);
        float r = 3.0f / viewport.zoom;
        for (ArrayList<PVector> rts : p.routes) {
          if (rts == null) continue;
          for (PVector v : rts) {
            app.ellipse(v.x, v.y, r, r);
          }
        }
        app.popStyle();
      }
    }

    // Selected path highlight
    if (highlightSelected && selectedPathIndex >= 0 && selectedPathIndex < paths.size()) {
      Path sel = paths.get(selectedPathIndex);
      if (sel.routes.isEmpty()) {
        app.popStyle();
        return;
      }
      PathType pt = getPathType(sel.typeId);
      int hi = app.color(255, 230, 80, 180);
      float w = (pt != null) ? pt.weightPx : 2.0f;
      float hw = 5.0f / viewport.zoom; // constant ~5px
      app.stroke(hi);
      app.strokeWeight(hw);
      boolean taperOn = (pt != null && pt.taperOn);
      HashMap<String, Float> taperW = null;
      if (taperOn) {
        taperW = taperCache.get(sel.typeId);
        if (taperW == null) {
          float minW = (pt != null) ? pt.minWeightPx : max(1.0f, w * 0.4f);
          taperW = computeTaperWeightsForType(sel.typeId, w, minW);
          taperCache.put(sel.typeId, taperW);
        }
      }
      sel.draw(app, w, taperOn, taperW, selectedPathIndex, showNodes);
    }

    app.popStyle();
  }

  void drawPathsRender(PApplet app, RenderSettings s) {
    if (paths.isEmpty() || s == null) return;
    app.pushStyle();
    app.noFill();
    HashMap<Integer, HashMap<String, Float>> taperCache = new HashMap<Integer, HashMap<String, Float>>();

    for (int i = 0; i < paths.size(); i++) {
      Path p = paths.get(i);
      if (p.routes.isEmpty()) continue;
      PathType pt = getPathType(p.typeId);
      int baseCol = (pt != null) ? pt.col : app.color(80);
      float[] hsb = rgbToHSB(baseCol);
      hsb[1] = constrain(hsb[1] * s.pathSatScale01, 0, 1);
      int col = hsb01ToRGB(hsb[0], hsb[1], hsb[2]);
      float w = (pt != null) ? pt.weightPx : 2.0f;
      if (w <= 0.01f) continue;
      app.stroke(col);
      boolean taperOn = (pt != null && pt.taperOn);
      HashMap<String, Float> taperW = null;
      if (taperOn) {
        taperW = taperCache.get(p.typeId);
        if (taperW == null) {
          float minW = (pt != null) ? pt.minWeightPx : max(1.0f, w * 0.4f);
          taperW = computeTaperWeightsForType(p.typeId, w, minW);
          taperCache.put(p.typeId, taperW);
        }
      }
      p.draw(app, w, taperOn, taperW, i, false);
    }
    app.popStyle();
  }

  // ---------- Paths management ----------

  void addFinishedPath(Path p) {
    if (p == null) return;
    if (p.routes.isEmpty()) return; // ignore degenerate paths
    if (p.name == null || p.name.length() == 0) {
      p.name = "Path " + (paths.size() + 1);
    }
    if (p.typeId < 0 || p.typeId >= pathTypes.size()) {
      p.typeId = 0;
    }
    paths.add(p);
  }

  void clearAllPaths() {
    paths.clear();
  }

  void appendRouteToPath(Path p, ArrayList<PVector> pts) {
    if (p == null || pts == null || pts.size() < 2) return;

    // Skip segments that already exist in this path to avoid double-stacking identical edges.
    ArrayList<PVector> cleaned = removeDuplicateSegments(p, pts);
    if (cleaned == null || cleaned.size() < 2) return;

    p.addRoute(cleaned);
    snapDirty = true;
  }

  ArrayList<PVector> removeDuplicateSegments(Path p, ArrayList<PVector> pts) {
    if (pts == null || pts.size() < 2) return null;
    HashSet<String> existing = collectSegmentKeys(p);

    ArrayList<PVector> out = new ArrayList<PVector>();
    out.add(pts.get(0).copy());
    for (int i = 0; i < pts.size() - 1; i++) {
      PVector a = out.get(out.size() - 1);
      PVector b = pts.get(i + 1);
      String key = segmentKey(a, b);
      if (existing.contains(key)) {
        continue;
      }
      existing.add(key);
      out.add(b.copy());
    }
    if (out.size() < 2) return null;
    return out;
  }

  HashSet<String> collectSegmentKeys(Path p) {
    HashSet<String> keys = new HashSet<String>();
    if (p == null || p.routes == null) return keys;
    for (ArrayList<PVector> seg : p.routes) {
      if (seg == null || seg.size() < 2) continue;
      for (int i = 0; i < seg.size() - 1; i++) {
        PVector a = seg.get(i);
        PVector b = seg.get(i + 1);
        keys.add(segmentKey(a, b));
      }
    }
    return keys;
  }

  String segmentKey(PVector a, PVector b) {
    // Undirected key with quantization to reduce floating noise.
    int ax = round(a.x * 10000);
    int ay = round(a.y * 10000);
    int bx = round(b.x * 10000);
    int by = round(b.y * 10000);
    if (ax < bx || (ax == bx && ay <= by)) {
      return ax + "," + ay + "-" + bx + "," + by;
    } else {
      return bx + "," + by + "-" + ax + "," + ay;
    }
  }

  ArrayList<PVector[]> collectAllPathSegments() {
    ArrayList<PVector[]> segs = new ArrayList<PVector[]>();
    if (paths == null || paths.isEmpty()) return segs;
    for (Path p : paths) {
      if (p == null || p.routes == null) continue;
      for (ArrayList<PVector> r : p.routes) {
        if (r == null || r.size() < 2) continue;
        for (int i = 0; i < r.size() - 1; i++) {
          PVector a = r.get(i);
          PVector b = r.get(i + 1);
          segs.add(new PVector[] { a, b });
        }
      }
    }
    return segs;
  }

  boolean edgeCrossesAnyPath(PVector[] edge, ArrayList<PVector[]> pathSegs) {
    if (edge == null || pathSegs == null || pathSegs.isEmpty()) return false;
    PVector e0 = edge[0];
    PVector e1 = edge[1];
    float minEx = min(e0.x, e1.x);
    float maxEx = max(e0.x, e1.x);
    float minEy = min(e0.y, e1.y);
    float maxEy = max(e0.y, e1.y);
    float eps = 1e-6f;
    for (PVector[] seg : pathSegs) {
      if (seg == null) continue;
      PVector p0 = seg[0];
      PVector p1 = seg[1];
      float minPx = min(p0.x, p1.x);
      float maxPx = max(p0.x, p1.x);
      float minPy = min(p0.y, p1.y);
      float maxPy = max(p0.y, p1.y);
      if (maxEx + eps < minPx || minEx - eps > maxPx || maxEy + eps < minPy || minEy - eps > maxPy) {
        continue; // quick reject via AABB
      }
      if (segmentsIntersect(e0, e1, p0, p1, eps)) return true;
    }
    return false;
  }

  void removePathsNear(float wx, float wy, float radius) {
    if (paths == null) return;
    float r2 = radius * radius;
    for (int i = paths.size() - 1; i >= 0; i--) {
      Path p = paths.get(i);
      boolean hit = false;
      for (ArrayList<PVector> seg : p.routes) {
        if (seg == null) continue;
        for (PVector v : seg) {
          float dx = v.x - wx;
          float dy = v.y - wy;
          if (dx * dx + dy * dy <= r2) {
            hit = true;
            break;
          }
        }
        if (hit) break;
      }
      if (hit) {
        paths.remove(i);
      }
    }
  }

  void erasePathSegments(float wx, float wy, float radius) {
    if (paths == null || paths.isEmpty()) return;
    float r2 = radius * radius;
    for (int pi = paths.size() - 1; pi >= 0; pi--) {
      Path p = paths.get(pi);
      if (p == null || p.routes == null) continue;
      ArrayList<ArrayList<PVector>> newRoutes = new ArrayList<ArrayList<PVector>>();
      boolean modified = false;
      for (ArrayList<PVector> seg : p.routes) {
        if (seg == null || seg.size() < 2) continue;
        ArrayList<PVector> cur = new ArrayList<PVector>();
        cur.add(seg.get(0).copy());
        for (int i = 0; i < seg.size() - 1; i++) {
          PVector a = seg.get(i);
          PVector b = seg.get(i + 1);
          PVector proj = closestPointOnSegment(wx, wy, a, b);
          float dx = proj.x - wx;
          float dy = proj.y - wy;
          float d2 = dx * dx + dy * dy;
          boolean hit = d2 <= r2;
          // Also treat endpoints inside radius as hits to fully remove adjacent segments
          float dxA = a.x - wx;
          float dyA = a.y - wy;
          float dxB = b.x - wx;
          float dyB = b.y - wy;
          if (dxA * dxA + dyA * dyA <= r2 || dxB * dxB + dyB * dyB <= r2) {
            hit = true;
          }
          if (hit) {
            // Cut here: close current route before this segment, start a new one after.
            if (cur.size() >= 2) newRoutes.add(cur);
            cur = new ArrayList<PVector>();
            cur.add(b.copy());
            modified = true;
          } else {
            cur.add(b.copy());
          }
        }
        if (cur.size() >= 2) newRoutes.add(cur);
      }
      if (modified) {
        p.routes = newRoutes;
        if (p.routes.isEmpty()) {
          paths.remove(pi);
        }
        snapDirty = true;
      }
    }
  }

  PVector[] nearestPathSegment(float wx, float wy, float maxDist) {
    if (paths == null || paths.isEmpty()) return null;
    float best = maxDist;
    PVector bestA = null, bestB = null, bestP = null;
    for (Path p : paths) {
      for (ArrayList<PVector> seg : p.routes) {
        if (seg == null) continue;
        for (int i = 0; i < seg.size() - 1; i++) {
          PVector a = seg.get(i);
          PVector b = seg.get(i + 1);
          PVector proj = closestPointOnSegment(wx, wy, a, b);
          float d = dist(wx, wy, proj.x, proj.y);
          if (d < best) {
            best = d;
            bestA = a;
            bestB = b;
            bestP = proj;
          }
        }
      }
    }
    if (bestP == null) return null;
    return new PVector[] { bestA, bestB, bestP };
  }

  PVector closestPointOnSegment(float px, float py, PVector a, PVector b) {
    float ax = a.x, ay = a.y;
    float bx = b.x, by = b.y;
    float abx = bx - ax;
    float aby = by - ay;
    float t = ((px - ax) * abx + (py - ay) * aby) / (abx * abx + aby * aby + 1e-9f);
    t = constrain(t, 0, 1);
    return new PVector(ax + abx * t, ay + aby * t);
  }

  PVector[] nearestFrontierSegment(float wx, float wy, float maxDist,
                                   boolean useWater, boolean useBiomes, boolean useUnderwaterBiomes,
                                   boolean useZones, boolean useElevation,
                                   int[] zoneMembership, int[] elevBuckets) {
    if (cells == null || cells.isEmpty()) return null;
    if (!useWater && !useBiomes && !useUnderwaterBiomes && !useZones && !useElevation) return null;
    ensureCellNeighborsComputed();
    float eps = 1e-4f;
    float eps2 = eps * eps;

    float best = maxDist;
    PVector bestA = null, bestB = null, bestP = null;

    int n = cells.size();
    for (int i = 0; i < n; i++) {
      Cell a = cells.get(i);
      ArrayList<Integer> nbs = cellNeighbors.get(i);
      if (nbs == null) continue;
      for (int nb : nbs) {
        if (nb <= i) continue;
        Cell b = cells.get(nb);
        if (b == null) continue;

        if (!boundaryActiveForSnapping(a, b, i, nb, zoneMembership, elevBuckets,
                                       useWater, useBiomes, useUnderwaterBiomes, useZones, useElevation)) {
          continue;
        }

        ArrayList<PVector> va = a.vertices;
        ArrayList<PVector> vb = b.vertices;
        if (va == null || vb == null || va.size() < 2 || vb.size() < 2) continue;
        int ac = va.size();
        for (int ai = 0; ai < ac; ai++) {
          PVector a0 = va.get(ai);
          PVector a1 = va.get((ai + 1) % ac);
          for (int bi = 0; bi < vb.size(); bi++) {
            PVector b0 = vb.get(bi);
            PVector b1 = vb.get((bi + 1) % vb.size());
            boolean matchForward = distSq(a0, b0) < eps2 && distSq(a1, b1) < eps2;
            boolean matchBackward = distSq(a0, b1) < eps2 && distSq(a1, b0) < eps2;
            if (!matchForward && !matchBackward) continue;

            PVector proj = closestPointOnSegment(wx, wy, a0, a1);
            float d = dist(wx, wy, proj.x, proj.y);
            if (d < best) {
              best = d;
              bestA = a0;
              bestB = a1;
              bestP = proj;
            }
            break;
          }
        }
      }
    }

    if (bestP == null) return null;
    return new PVector[] { bestA, bestB, bestP };
  }

  // ---------- Sites management ----------

  Site addSite(float x, float y) {
    Site s = new Site(x, y);
    sites.add(s);
    markVoronoiDirty();
    return s;
  }

  void deleteSelectedSites() {
    boolean changed = false;
    for (int i = sites.size() - 1; i >= 0; i--) {
      if (sites.get(i).selected) {
        sites.remove(i);
        changed = true;
      }
    }
    if (changed) {
      markVoronoiDirty();
    }
  }

  void clearSiteSelection() {
    for (Site s : sites) {
      s.selected = false;
    }
  }

  void selectSite(Site s) {
    if (s != null) {
      s.selected = true;
    }
  }

  Site findSiteNear(float wx, float wy, float maxDistWorld) {
    Site best = null;
    float bestSq = maxDistWorld * maxDistWorld;
    for (Site s : sites) {
      float dx = s.x - wx;
      float dy = s.y - wy;
      float d2 = dx * dx + dy * dy;
      if (d2 <= bestSq) {
        bestSq = d2;
        best = s;
      }
    }
    return best;
  }

  // ---------- Voronoi management ----------

  void markVoronoiDirty() {
    voronoiDirty = true;
    snapDirty = true;
    voronoiJob = null; // cancel in-flight job
    invalidateContourCaches();
    renderer.invalidateBiomeOutlineCache();
  }

  void invalidateContourCaches() {
    coastCacheValid = false;
    cachedCoastGrid = null;
    cachedCoastIndex = null;
    cachedCoastSeaLevel = Float.MAX_VALUE;
    cachedCoastCols = 0;
    cachedCoastRows = 0;
    cachedCoastCellCount = -1;
    coastJob = null;

    elevationCacheValid = false;
    cachedElevationGrid = null;
    cachedElevationSeaLevel = Float.MAX_VALUE;
    cachedElevationCols = 0;
    cachedElevationRows = 0;
    cachedElevationCellCount = -1;
    elevationJob = null;
  }

  void ensureVoronoiComputed() {
    // Kick off incremental job if needed
    if (voronoiDirty && voronoiJob == null) {
      startVoronoiJob();
    }

    // Advance current job in small batches
    if (voronoiJob != null) {
      stepVoronoiJob(VORONOI_BATCH, 10);
    }
  }

  void startVoronoiJob() {
    if (sites == null || sites.isEmpty()) {
      cells.clear();
      cellNeighbors.clear();
      preservedCells = null;
      voronoiDirty = false;
      voronoiJob = null;
      voronoiProgress = 0;
      return;
    }
    ArrayList<Cell> oldCells = (preservedCells != null) ? preservedCells : new ArrayList<Cell>();
    voronoiJob = new VoronoiJob(this, sites, oldCells, defaultElevation, preservedCells != null);
    voronoiProgress = 0;
  }

  void stepVoronoiJob(int maxSites, int maxMillis) {
    if (voronoiJob == null) return;
    voronoiJob.step(maxSites, maxMillis);
    voronoiProgress = voronoiJob.progress();
    if (voronoiJob.isDone()) {
      // Swap in the freshly built data
      cells = voronoiJob.outCells;
      preservedCells = null;
      voronoiDirty = false;
      voronoiJob = null;
      voronoiProgress = 1.0f;
      rebuildCellNeighbors();
      snapDirty = true;
    }
  }

  boolean isVoronoiBuilding() {
    return voronoiJob != null;
  }

  float getVoronoiProgress() {
    if (voronoiJob != null) return voronoiJob.progress();
    return voronoiDirty ? 0.0f : 1.0f;
  }

  // Keep the half-plane of points closer to si than sj
  ArrayList<PVector> clipPolygonWithHalfPlane(ArrayList<PVector> poly, Site si, Site sj) {
    ArrayList<PVector> out = new ArrayList<PVector>();
    if (poly.isEmpty()) return out;

    float ax = sj.x - si.x;
    float ay = sj.y - si.y;
    float c = 0.5f * (sj.x * sj.x + sj.y * sj.y - si.x * si.x - si.y * si.y);

    int count = poly.size();
    for (int k = 0; k < count; k++) {
      PVector current = poly.get(k);
      PVector next = poly.get((k + 1) % count);

      float fCurrent = ax * current.x + ay * current.y - c;
      float fNext = ax * next.x + ay * next.y - c;

      boolean insideCurrent = fCurrent <= 0;
      boolean insideNext = fNext <= 0;

      if (insideCurrent && insideNext) {
        out.add(next.copy());
      } else if (insideCurrent && !insideNext) {
        PVector inter = intersectSegmentWithLine(current, next, fCurrent, fNext);
        if (inter != null) out.add(inter);
      } else if (!insideCurrent && insideNext) {
        PVector inter = intersectSegmentWithLine(current, next, fCurrent, fNext);
        if (inter != null) out.add(inter);
        out.add(next.copy());
      } else {
        // both outside
      }
    }

    return out;
  }

  PVector intersectSegmentWithLine(PVector p1, PVector p2, float f1, float f2) {
    float denom = f1 - f2;
    if (abs(denom) < 1e-6f) {
      return null;
    }
    float t = f1 / (f1 - f2);
    t = constrain(t, 0.0f, 1.0f);
    float x = lerp(p1.x, p2.x, t);
    float y = lerp(p1.y, p2.y, t);
    return new PVector(x, y);
  }

  // Sample biome from old cells at (x,y); fallback if none found
  int sampleBiomeFromOldCells(ArrayList<Cell> oldCells, float x, float y, int fallbackBiome) {
    for (Cell c : oldCells) {
      if (pointInPolygon(x, y, c.vertices)) {
        return c.biomeId;
      }
    }
    return fallbackBiome;
  }

  int sampleZoneFromOldCells(int fallbackZone) {
    return fallbackZone;
  }

  float sampleElevationFromOldCells(ArrayList<Cell> oldCells, float x, float y, float fallback) {
    for (Cell c : oldCells) {
      if (pointInPolygon(x, y, c.vertices)) {
        return c.elevation;
      }
    }
    return fallback;
  }

  // Incremental Voronoi builder to keep UI responsive during generation.
  class VoronoiJob {
    MapModel model;
    ArrayList<Site> sites;
    ArrayList<Cell> oldCells;
    ArrayList<Cell> outCells = new ArrayList<Cell>();
    int idx = 0;
    int n;
    float defaultElev;
    int defaultBiome = 0;
    boolean preserveData;
    HashMap<Long, ArrayList<Integer>> bins = new HashMap<Long, ArrayList<Integer>>();
    float binSize;
    float invBin;

    VoronoiJob(MapModel model, ArrayList<Site> sites, ArrayList<Cell> oldCells, float defaultElev, boolean preserveData) {
      this.model = model;
      this.sites = new ArrayList<Site>(sites);
      this.oldCells = (oldCells != null) ? oldCells : new ArrayList<Cell>();
      this.n = this.sites.size();
      this.defaultElev = defaultElev;
      this.preserveData = preserveData;
      float area = (model.maxX - model.minX) * (model.maxY - model.minY);
      float avgSpacing = sqrt(max(1e-6f, area / max(1, n)));
      binSize = max(1e-3f, avgSpacing * 1.5f);
      invBin = 1.0f / binSize;
      buildBins();
    }

    void step(int maxSites, int maxMillis) {
      if (idx >= n) return;
      int processed = 0;
      long end = millis() + max(0, maxMillis);
      while (idx < n && processed < maxSites) {
        if (maxMillis > 0 && millis() > end) break;
        buildCell(idx);
        idx++;
        processed++;
      }
    }

    void buildCell(int i) {
      Site si = sites.get(i);
      ArrayList<PVector> poly = new ArrayList<PVector>();
      poly.add(new PVector(minX, minY));
      poly.add(new PVector(maxX, minY));
      poly.add(new PVector(maxX, maxY));
      poly.add(new PVector(minX, maxY));

      ArrayList<Integer> candidates = gatherCandidates(i);
      if (candidates == null || candidates.isEmpty()) {
        candidates = new ArrayList<Integer>();
        for (int j = 0; j < n; j++) if (j != i) candidates.add(j);
      }

      HashSet<Integer> seen = new HashSet<Integer>();
      for (int idxCandidate : candidates) {
        if (idxCandidate == i) continue;
        if (seen.contains(idxCandidate)) continue;
        seen.add(idxCandidate);
        Site sj = sites.get(idxCandidate);
        poly = model.clipPolygonWithHalfPlane(poly, si, sj);
        if (poly.size() < 3) {
          break;
        }
      }

      // Safety pass: clip with any neighbor within the cell's current radius to avoid overlaps.
      float maxDist = 0;
      for (PVector v : poly) {
        float dx = v.x - si.x;
        float dy = v.y - si.y;
        maxDist = max(maxDist, sqrt(dx * dx + dy * dy));
      }
      int extraRing = ceil(maxDist * invBin) + 2;
      ArrayList<Integer> extra = gatherNeighborsWithinRings(i, extraRing);
      for (int idxCandidate : extra) {
        if (idxCandidate == i || seen.contains(idxCandidate)) continue;
        seen.add(idxCandidate);
        Site sj = sites.get(idxCandidate);
        poly = model.clipPolygonWithHalfPlane(poly, si, sj);
        if (poly.size() < 3) break;
      }

      if (poly.size() < 3) return;

      float cx = 0;
      float cy = 0;
      int nv = poly.size();
      for (int k = 0; k < nv; k++) {
        PVector v = poly.get(k);
        cx += v.x;
        cy += v.y;
      }
      cx /= nv;
      cy /= nv;

      int biomeId = (preserveData && !oldCells.isEmpty())
        ? model.sampleBiomeFromOldCells(oldCells, cx, cy, defaultBiome)
        : defaultBiome;
      float elev = (preserveData && !oldCells.isEmpty())
        ? model.sampleElevationFromOldCells(oldCells, cx, cy, defaultElev)
        : defaultElev;

      Cell newCell = new Cell(i, poly, biomeId);
      newCell.elevation = elev;
      outCells.add(newCell);
    }

    boolean isDone() {
      return idx >= n;
    }

    float progress() {
      if (n <= 0) return 1.0f;
      return constrain(idx / (float)n, 0, 1);
    }

    void buildBins() {
      bins.clear();
      for (int i = 0; i < n; i++) {
        Site s = sites.get(i);
        int gx = floor((s.x - minX) * invBin);
        int gy = floor((s.y - minY) * invBin);
        long key = (((long)gx) << 32) ^ (gy & 0xffffffffL);
        ArrayList<Integer> bucket = bins.get(key);
        if (bucket == null) {
          bucket = new ArrayList<Integer>();
          bins.put(key, bucket);
        }
        bucket.add(i);
      }
    }

    ArrayList<Integer> gatherCandidates(int i) {
      ArrayList<Integer> out = new ArrayList<Integer>();
      Site s = sites.get(i);
      int gx = floor((s.x - minX) * invBin);
      int gy = floor((s.y - minY) * invBin);

      // Expand rings until we have a reasonable set of neighbors or reach cap
      int needed = 48;
      int maxRing = 8;
      for (int ring = 0; ring <= maxRing && out.size() < needed; ring++) {
        for (int dx = -ring; dx <= ring; dx++) {
          for (int dy = -ring; dy <= ring; dy++) {
            if (abs(dx) != ring && abs(dy) != ring) continue; // only border of ring
            long key = (((long)(gx + dx)) << 32) ^ ((gy + dy) & 0xffffffffL);
            ArrayList<Integer> bucket = bins.get(key);
            if (bucket == null) continue;
            for (int idxSite : bucket) {
              if (idxSite == i) continue;
              out.add(idxSite);
              if (out.size() >= needed) break;
            }
            if (out.size() >= needed) break;
          }
          if (out.size() >= needed) break;
        }
      }
      return out;
    }

    ArrayList<Integer> gatherNeighborsWithinRings(int i, int ringRadius) {
      ArrayList<Integer> out = new ArrayList<Integer>();
      Site s = sites.get(i);
      int gx = floor((s.x - minX) * invBin);
      int gy = floor((s.y - minY) * invBin);
      int rMax = max(0, min(ringRadius, 20)); // cap to keep work bounded
      for (int ring = 0; ring <= rMax; ring++) {
        for (int dx = -ring; dx <= ring; dx++) {
          for (int dy = -ring; dy <= ring; dy++) {
            if (abs(dx) != ring && abs(dy) != ring) continue;
            long key = (((long)(gx + dx)) << 32) ^ ((gy + dy) & 0xffffffffL);
            ArrayList<Integer> bucket = bins.get(key);
            if (bucket == null) continue;
            for (int idxSite : bucket) {
              if (idxSite == i) continue;
              out.add(idxSite);
            }
          }
        }
      }
      return out;
    }
  }

  // ---------- Zones / cells picking ----------

  Cell findCellContaining(float wx, float wy) {
    for (Cell c : cells) {
      if (pointInPolygon(wx, wy, c.vertices)) return c;
    }
    return null;
  }

  boolean pointInPolygon(float x, float y, ArrayList<PVector> poly) {
    if (poly == null || poly.size() < 3) return false;

    boolean inside = false;
    int n = poly.size();
    for (int i = 0, j = n - 1; i < n; j = i++) {
      PVector pi = poly.get(i);
      PVector pj = poly.get(j);

      boolean intersect = ((pi.y > y) != (pj.y > y)) &&
                          (x < (pj.x - pi.x) * (y - pi.y) / (pj.y - pi.y + 1e-9f) + pi.x);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  int indexOfCell(Cell c) {
    for (int i = 0; i < cells.size(); i++) {
      if (cells.get(i) == c) return i;
    }
    return -1;
  }

  // Flood-fill contiguous region of same biome as start cell
  void floodFillBiomeFromCell(Cell start, int newBiomeId) {
    if (start == null) return;
    int startIndex = indexOfCell(start);
    if (startIndex < 0) return;

    int oldBiome = start.biomeId;
    if (oldBiome == newBiomeId) return;

    int n = cells.size();
    if (n == 0) return;

    boolean[] visited = new boolean[n];
    int[] stack = new int[n];
    int stackSize = 0;
    float eps = 1e-4f;

    stack[stackSize++] = startIndex;
    visited[startIndex] = true;

    while (stackSize > 0) {
      int idx = stack[--stackSize];
      Cell c = cells.get(idx);

      if (c.biomeId != oldBiome) continue;
      c.biomeId = newBiomeId;

      for (int j = 0; j < n; j++) {
        if (visited[j]) continue;
        Cell other = cells.get(j);

        if (!cellsAreNeighbors(c, other, eps)) continue;

        visited[j] = true;
        stack[stackSize++] = j;
      }
    }
    renderer.invalidateBiomeOutlineCache();
  }

  void addCellToZone(int cellIdx, int zoneIdx) {
    if (zones == null || zoneIdx < 0 || zoneIdx >= zones.size()) return;
    if (cellIdx < 0 || cellIdx >= cells.size()) return;
    MapZone az = zones.get(zoneIdx);
    if (az == null) return;
    if (!az.cells.contains(cellIdx)) {
      az.cells.add(cellIdx);
    }
  }

  void removeCellFromAllZones(int cellIdx) {
    if (zones == null || cellIdx < 0 || cells == null || cellIdx >= cells.size()) return;
    for (MapZone az : zones) {
      if (az == null || az.cells == null) continue;
      az.cells.remove((Integer)cellIdx);
    }
  }

  boolean cellInZone(int cellIdx, int zoneIdx) {
    if (zones == null || zoneIdx < 0 || zoneIdx >= zones.size()) return false;
    MapZone az = zones.get(zoneIdx);
    if (az == null) return false;
    return az.cells.contains(cellIdx);
  }

  void floodFillZone(Cell start, int zoneIdx) {
    if (start == null) return;
    int startIndex = indexOfCell(start);
    if (startIndex < 0) return;
    int n = cells.size();
    if (n == 0) return;
    ensureCellNeighborsComputed();
    boolean[] visited = new boolean[n];
    int[] stack = new int[n];
    int stackSize = 0;
    stack[stackSize++] = startIndex;
    visited[startIndex] = true;
    while (stackSize > 0) {
      int idx = stack[--stackSize];
      addCellToZone(idx, zoneIdx);
      ArrayList<Integer> nbs = (idx < cellNeighbors.size()) ? cellNeighbors.get(idx) : null;
      if (nbs == null) continue;
      for (int nb : nbs) {
        if (nb < 0 || nb >= n) continue;
        if (visited[nb]) continue;
        visited[nb] = true;
        stack[stackSize++] = nb;
      }
    }
  }

  boolean cellsAreNeighbors(Cell a, Cell b, float eps) {
    if (a.vertices == null || b.vertices == null) return false;
    int shared = 0;

    for (int i = 0; i < a.vertices.size(); i++) {
      PVector va = a.vertices.get(i);
      for (int j = 0; j < b.vertices.size(); j++) {
        PVector vb = b.vertices.get(j);
        float dx = va.x - vb.x;
        float dy = va.y - vb.y;
        if (dx * dx + dy * dy <= eps * eps) {
          shared++;
          if (shared >= 2) return true;
        }
      }
    }
    return false;
  }

  void rebuildCellNeighbors() {
    cellNeighbors.clear();
    int n = cells.size();
    for (int i = 0; i < n; i++) {
      cellNeighbors.add(new ArrayList<Integer>());
    }

    if (n == 0) return;

    // Spatial binning to avoid O(n^2) all-pairs comparisons when many sites are present.
    float worldW = maxX - minX;
    float worldH = maxY - minY;
    float avgCellSize = sqrt((worldW * worldH) / max(1, n));
    float binSize = max(avgCellSize, 1e-3f);
    float invBin = 1.0f / binSize;
    float eps = 1e-4f;
    float[] minXs = new float[n];
    float[] minYs = new float[n];
    float[] maxXs = new float[n];
    float[] maxYs = new float[n];

    HashMap<Long, ArrayList<Integer>> bins = new HashMap<Long, ArrayList<Integer>>();

    for (int i = 0; i < n; i++) {
      Cell c = cells.get(i);
      if (c == null || c.vertices == null || c.vertices.size() < 2) continue;
      float minx = Float.MAX_VALUE;
      float miny = Float.MAX_VALUE;
      float maxx = -Float.MAX_VALUE;
      float maxy = -Float.MAX_VALUE;
      for (PVector v : c.vertices) {
        minx = min(minx, v.x);
        miny = min(miny, v.y);
        maxx = max(maxx, v.x);
        maxy = max(maxy, v.y);
      }
      minXs[i] = minx;
      minYs[i] = miny;
      maxXs[i] = maxx;
      maxYs[i] = maxy;

      int gx0 = (int)floor((minx - minX) * invBin);
      int gx1 = (int)floor((maxx - minX) * invBin);
      int gy0 = (int)floor((miny - minY) * invBin);
      int gy1 = (int)floor((maxy - minY) * invBin);
      for (int gx = gx0; gx <= gx1; gx++) {
        for (int gy = gy0; gy <= gy1; gy++) {
          long key = (((long)gx) << 32) ^ (gy & 0xffffffffL);
          ArrayList<Integer> bucket = bins.get(key);
          if (bucket == null) {
            bucket = new ArrayList<Integer>();
            bins.put(key, bucket);
          }
          bucket.add(i);
        }
      }
    }

    int[] seen = new int[n];
    int stamp = 1;

    for (int i = 0; i < n; i++) {
      Cell a = cells.get(i);
      if (a == null || a.vertices == null || a.vertices.size() < 2) continue;

      int gx0 = (int)floor((minXs[i] - minX) * invBin) - 1;
      int gx1 = (int)floor((maxXs[i] - minX) * invBin) + 1;
      int gy0 = (int)floor((minYs[i] - minY) * invBin) - 1;
      int gy1 = (int)floor((maxYs[i] - minY) * invBin) + 1;

      for (int gx = gx0; gx <= gx1; gx++) {
        for (int gy = gy0; gy <= gy1; gy++) {
          long key = (((long)gx) << 32) ^ (gy & 0xffffffffL);
          ArrayList<Integer> bucket = bins.get(key);
          if (bucket == null) continue;
          for (int idx : bucket) {
            if (idx <= i) continue;
            if (seen[idx] == stamp) continue;
            seen[idx] = stamp;
            // Quick AABB rejection before the expensive vertex test
            if (maxXs[i] + eps < minXs[idx] || minXs[i] - eps > maxXs[idx] ||
                maxYs[i] + eps < minYs[idx] || minYs[i] - eps > maxYs[idx]) {
              continue;
            }
            Cell b = cells.get(idx);
            if (b == null) continue;
            if (cellsAreNeighbors(a, b, eps)) {
              cellNeighbors.get(i).add(idx);
              cellNeighbors.get(idx).add(i);
            }
          }
        }
      }
      stamp++;
    }
  }


  // ---------- Sites generation ----------

  void generateSites(PlacementMode mode, int targetCount) {
    generateSites(mode, targetCount, false);
  }

  void generateSites(PlacementMode mode, int targetCount, boolean preserveCellData) {
    int clampedCount = constrain(targetCount, 0, MAX_SITE_COUNT);
    preservedCells = preserveCellData ? new ArrayList<Cell>(cells) : null;
    sites.clear();
    if (!preserveCellData && zones != null) {
      for (MapZone az : zones) {
        if (az != null) az.cells.clear();
      }
    }

    if (clampedCount <= 0) {
      markVoronoiDirty();
      snapDirty = true;
      return;
    }

    if (mode == PlacementMode.GRID) {
      generateGridSites(clampedCount);
    } else if (mode == PlacementMode.HEX) {
      generateHexSites(clampedCount);
    } else if (mode == PlacementMode.POISSON) {
      generatePoissonSites(clampedCount);
    }

    applyFuzz(siteFuzz);

    clearSiteSelection();
    if (!sites.isEmpty()) {
      sites.get(0).selected = true;
    }

    markVoronoiDirty();
    snapDirty = true;
  }

  void applyElevationBrush(float cx, float cy, float radius, float delta, float seaLevel) {
    if (cells == null || cells.isEmpty()) return;
    float preMin = Float.MAX_VALUE;
    float preMax = -Float.MAX_VALUE;
    for (Cell c : cells) {
      preMin = min(preMin, c.elevation);
      preMax = max(preMax, c.elevation);
    }
    float r2 = radius * radius;
    for (Cell c : cells) {
      PVector cen = cellCentroid(c);
      float dx = cen.x - cx;
      float dy = cen.y - cy;
      float d2 = dx * dx + dy * dy;
      if (d2 > r2) continue;
      float t = 1.0f - sqrt(d2 / r2);
      c.elevation = c.elevation + delta * t;
    }
    normalizeElevationsIfOutOfBounds(seaLevel);
    invalidateContourCaches();
  }

  PathType getPathType(int idx) {
    if (pathTypes == null) return null;
    if (idx < 0 || idx >= pathTypes.size()) return null;
    return pathTypes.get(idx);
  }

  PathType makePathTypeFromPreset(int presetIndex) {
    if (presetIndex < 0 || presetIndex >= PATH_TYPE_PRESETS.length) return null;
    PathTypePreset p = PATH_TYPE_PRESETS[presetIndex];
    return new PathType(p.name, p.col, p.weightPx, p.minWeightPx, p.routeMode, p.slopeBias, p.avoidWater, p.taperOn);
  }

  void generateElevationNoise(float scale, float amplitude, float seaLevel) {
    if (cells == null) return;
    float preMin = Float.MAX_VALUE;
    float preMax = -Float.MAX_VALUE;
    for (Cell c : cells) {
      preMin = min(preMin, c.elevation);
      preMax = max(preMax, c.elevation);
    }
    for (Cell c : cells) {
      PVector cen = cellCentroid(c);
      float n = noise(cen.x * scale, cen.y * scale);
      c.elevation = (n - 0.5f) * 2.0f * amplitude;
    }
    normalizeElevationsIfOutOfBounds(seaLevel);
    invalidateContourCaches();
  }

  void addElevationVariation(float scale, float amplitude, float seaLevel) {
    if (cells == null) return;
    float preMin = Float.MAX_VALUE;
    float preMax = -Float.MAX_VALUE;
    for (Cell c : cells) {
      preMin = min(preMin, c.elevation);
      preMax = max(preMax, c.elevation);
    }
    for (Cell c : cells) {
      PVector cen = cellCentroid(c);
      float n = noise(cen.x * scale, cen.y * scale);
      float delta = (n - 0.5f) * 2.0f * amplitude;
      c.elevation = c.elevation + delta;
    }
    normalizeElevationsIfOutOfBounds(seaLevel);
    invalidateContourCaches();
  }

  PVector cellCentroid(Cell c) {
    if (c.vertices == null || c.vertices.isEmpty()) {
      return new PVector(0, 0);
    }
    float cx = 0;
    float cy = 0;
    for (PVector v : c.vertices) {
      cx += v.x;
      cy += v.y;
    }
    cx /= c.vertices.size();
    cy /= c.vertices.size();
    return new PVector(cx, cy);
  }

  void normalizeElevationsIfOutOfBounds(float seaLevel) {
    float newMin = Float.MAX_VALUE;
    float newMax = -Float.MAX_VALUE;
    for (Cell c : cells) {
      newMin = min(newMin, c.elevation);
      newMax = max(newMax, c.elevation);
    }
    // Keep elevations within [-1, 1] by re-scaling only the side that exceeds,
    // leaving the opposite side untouched relative to sea level.
    float maxLimit = 1.0f;
    float minLimit = -1.0f;

    if (newMax > maxLimit) {
      float fromRange = newMax - seaLevel;
      float toRange = maxLimit - seaLevel;
      if (fromRange > 1e-6f && toRange > 1e-6f) {
        float scale = toRange / fromRange;
        for (Cell c : cells) {
          if (c.elevation > seaLevel) {
            c.elevation = seaLevel + (c.elevation - seaLevel) * scale;
          }
        }
      }
    }
    if (newMin < minLimit) {
      float fromRange = seaLevel - newMin;
      float toRange = seaLevel - minLimit;
      if (fromRange > 1e-6f && toRange > 1e-6f) {
        float scale = toRange / fromRange;
        for (Cell c : cells) {
          if (c.elevation < seaLevel) {
            c.elevation = seaLevel - (seaLevel - c.elevation) * scale;
          }
        }
      }
    }
  }

  // Fill all "None" zones by seeding random types and expanding through neighbors.
  // Existing non-None assignments remain and act as seeds for their own type.
  void generateZonesFromSeeds() {
    if (cells == null || cells.isEmpty()) return;
    int typeCount = biomeTypes.size() - 1; // exclude "None"
    if (typeCount <= 0) return;

    ensureCellNeighborsComputed();

    int n = cells.size();
    int[] zoneMembership = null;
    if (zones != null && !zones.isEmpty()) {
      zoneMembership = new int[n];
      Arrays.fill(zoneMembership, -1);
      for (int zi = 0; zi < zones.size(); zi++) {
        MapZone z = zones.get(zi);
        if (z == null || z.cells == null) continue;
        for (int ci : z.cells) {
          if (ci >= 0 && ci < n) {
            zoneMembership[ci] = zi;
          }
        }
      }
    }

    ArrayList<PVector[]> pathSegs = collectAllPathSegments();

    int[] biomeForCell = new int[n];
    float[] biomeCost = new float[n];
    Arrays.fill(biomeForCell, -1);
    Arrays.fill(biomeCost, Float.MAX_VALUE);

    PriorityQueue<Integer> frontier = new PriorityQueue<Integer>(n, new Comparator<Integer>() {
      public int compare(Integer a, Integer b) {
        return Float.compare(biomeCost[a], biomeCost[b]);
      }
    });

    ArrayList<Integer> noneIndices = new ArrayList<Integer>();

    // Existing zones become seeds for their own type
    for (int i = 0; i < n; i++) {
      Cell c = cells.get(i);
      if (c.biomeId > 0) {
        biomeForCell[i] = c.biomeId;
        biomeCost[i] = 0.0f;
        frontier.add(i);
      } else {
        noneIndices.add(i);
      }
    }

    if (noneIndices.isEmpty()) return;

    // Add random seeds inside "None" cells to diversify coverage
    Collections.shuffle(noneIndices);
    float avgBiomeSubzoneSize = random(10.0,200.0);
    int seedCount = floor(noneIndices.size()/avgBiomeSubzoneSize);
    for (int i = 0; i < seedCount; i++) {
      int idx = noneIndices.get(i);
      Cell c = cells.get(idx);
      int biomeId = 1 + (int)random(typeCount);
      c.biomeId = biomeId;
      biomeForCell[idx] = biomeId;
      biomeCost[idx] = 0.0f;
      frontier.add(idx);
    }

    // Multi-source weighted expansion to propagate seeds into remaining None cells
    float elevationPenaltyScale = 60.0f;
    float waterPenalty = 12.0f;
    float zoneBoundaryPenalty = 6.0f;
    float pathCrossPenalty = 10.0f;

    while (!frontier.isEmpty()) {
      int idx = frontier.poll();
      if (idx < 0 || idx >= n) continue;
      int biomeId = biomeForCell[idx];
      if (biomeId <= 0) continue;
      float baseCost = biomeCost[idx];
      ArrayList<Integer> nbs = (idx < cellNeighbors.size()) ? cellNeighbors.get(idx) : null;
      if (nbs == null) continue;
      Cell c = cells.get(idx);
      for (int nb : nbs) {
        if (nb < 0 || nb >= n) continue;
        Cell nc = cells.get(nb);
        float step = 1.0f;
        if (c != null && nc != null) {
          float elevDiff = abs(c.elevation - nc.elevation);
          step += elevDiff * elevationPenaltyScale;
          boolean waterChange = (c.elevation < seaLevel) != (nc.elevation < seaLevel);
          if (waterChange) step += waterPenalty;
          if (zoneMembership != null) {
            int za = zoneMembership[idx];
            int zb = zoneMembership[nb];
            if (za >= 0 && zb >= 0 && za != zb) {
              step += zoneBoundaryPenalty;
            }
          }
          if (pathSegs != null && !pathSegs.isEmpty()) {
            PVector[] edge = sharedEdgeBetweenCells(c, nc);
            if (edge != null && edgeCrossesAnyPath(edge, pathSegs)) {
              step += pathCrossPenalty;
            }
          }
        }

        float newCost = baseCost + step;
        if (newCost < biomeCost[nb]) {
          biomeCost[nb] = newCost;
          biomeForCell[nb] = biomeId;
          frontier.add(nb);
        }
      }
    }

    // Write back propagated biomes
    for (int i = 0; i < n; i++) {
      int biomeId = biomeForCell[i];
      if (biomeId > 0) {
        cells.get(i).biomeId = biomeId;
      }
    }
  }

  void resetAllBiomesToNone() {
    if (cells == null || cells.isEmpty()) return;
    for (Cell c : cells) {
      c.biomeId = 0;
    }
  }

  void setUnderwaterToBiome(int biomeId, float sea) {
    if (cells == null || cells.isEmpty()) return;
    for (Cell c : cells) {
      if (c.elevation < sea) {
        c.biomeId = biomeId;
      }
    }
    snapDirty = true;
  }

  boolean hasAnyNoneBiome() {
    if (cells == null || cells.isEmpty()) return false;
    for (Cell c : cells) {
      if (c.biomeId == 0) return true;
    }
    return false;
  }

  void resetAllZonesToNone() {
    if (zones != null) zones.clear();
  }

  void regenerateRandomZones(int targetZones) {
    if (cells == null || cells.isEmpty()) return;
    int n = cells.size();
    int zoneCount = max(1, targetZones);
    zones.clear();

    // Create zones with random hues (shared saturation/brightness)
    for (int i = 0; i < zoneCount; i++) {
      float h = pickMaxGapHue();
      int col = zoneColorForHue(h);
      MapZone z = new MapZone("Zone" + (i + 1), col);
      z.hue01 = h;
      z.updateColorFromHSB();
      zones.add(z);
    }

    ensureCellNeighborsComputed();

    // Seed assignment (random cells become seeds)
    ArrayList<Integer> indices = new ArrayList<Integer>();
    for (int i = 0; i < n; i++) indices.add(i);
    Collections.shuffle(indices);

    int[] zoneForCell = new int[n];
    float[] zoneCost = new float[n];
    Arrays.fill(zoneForCell, -1);
    Arrays.fill(zoneCost, Float.MAX_VALUE);

    PriorityQueue<Integer> frontier = new PriorityQueue<Integer>(n, new Comparator<Integer>() {
      public int compare(Integer a, Integer b) {
        return Float.compare(zoneCost[a], zoneCost[b]);
      }
    });

    int idx = 0;
    for (int z = 0; z < zoneCount && idx < indices.size(); z++) {
      int ci = indices.get(idx++);
      zoneForCell[ci] = z;
      zoneCost[ci] = 0.0f;
      frontier.add(ci);
    }

    // Weighted expansion: discourage big elevation jumps and biome changes.
    float biomePenalty = 6.0f;
    float elevationPenaltyScale = 60.0f;
    float waterPenalty = 12.0f;

    while (!frontier.isEmpty()) {
      int ci = frontier.poll();
      float baseCost = zoneCost[ci];
      ArrayList<Integer> nbs = (ci < cellNeighbors.size()) ? cellNeighbors.get(ci) : null;
      if (nbs == null) continue;
      for (int nb : nbs) {
        if (nb < 0 || nb >= n) continue;
        float step = 1.0f;
        Cell ca = cells.get(ci);
        Cell cb = cells.get(nb);
        if (ca != null && cb != null) {
          if (ca.biomeId != cb.biomeId) step += biomePenalty;
          float elevDiff = abs(ca.elevation - cb.elevation);
          step += elevDiff * elevationPenaltyScale;
          boolean waterChange = (ca.elevation < seaLevel) != (cb.elevation < seaLevel);
          if (waterChange) step += waterPenalty;
        }

        float newCost = baseCost + step;
        if (newCost < zoneCost[nb]) {
          zoneCost[nb] = newCost;
          zoneForCell[nb] = zoneForCell[ci];
          frontier.add(nb);
        }
      }
    }

    // Write back memberships
    for (MapZone az : zones) {
      if (az != null) az.cells.clear();
    }
    for (int ci = 0; ci < n; ci++) {
      int z = zoneForCell[ci];
      if (z >= 0 && z < zones.size()) {
        zones.get(z).cells.add(ci);
      }
    }
  }

  boolean hasAnyNoneZone() {
    if (zones == null || zones.isEmpty()) return true;
    for (MapZone az : zones) {
      if (az != null && az.cells.isEmpty()) return true;
    }
    return false;
  }

  void ensureCellNeighborsComputed() {
    if (cellNeighbors == null || cellNeighbors.size() != cells.size()) {
      rebuildCellNeighbors();
    }
  }

  void applyFuzz(float fuzz) {
    if (fuzz <= 0) return;
    if (sites.isEmpty()) return;

    float w = maxX - minX;
    float h = maxY - minY;
    float d = min(w, h);

    float maxOffset = fuzz * d / 10.0f;

    for (Site s : sites) {
      float dx = random(-maxOffset, maxOffset);
      float dy = random(-maxOffset, maxOffset);
      s.x = constrain(s.x + dx, minX, maxX);
      s.y = constrain(s.y + dy, minY, maxY);
    }
  }

  void generateGridSites(int targetCount) {
    if (targetCount <= 0) return;
    int res = max(1, (int)ceil(sqrt(max(1, targetCount))));

    int cols = res;
    int rows = res;

    float w = maxX - minX;
    float h = maxY - minY;

    float dx = w / cols;
    float dy = h / rows;

    for (int j = 0; j < rows; j++) {
      for (int i = 0; i < cols; i++) {
        float x = minX + (i + 0.5f) * dx;
        float y = minY + (j + 0.5f) * dy;
        sites.add(new Site(x, y));
      }
    }
  }

  void generateHexSites(int targetCount) {
    if (targetCount <= 0) return;
    int res = max(1, (int)ceil(sqrt(max(1, targetCount))));

    float w = maxX - minX;
    float h = maxY - minY;

    int cols = res;
    float dx = (cols > 1) ? w / (cols - 1) : w;

    float dy = dx * sqrt(3) / 2.0f;
    int rows = max(1, (int)ceil(h / dy) + 1);

    for (int j = 0; j < rows; j++) {
      float offset = (j % 2 == 0) ? 0.0f : dx * 0.5f;
      for (int i = -1; i <= cols; i++) {
        float x = minX + i * dx + offset;
        if (x < minX || x > maxX) continue;
        float y = minY + j * dy;
        if (y < minY || y > maxY) continue;
        sites.add(new Site(x, y));
      }
    }
  }

  void generatePoissonSites(int targetCount) {
    if (targetCount <= 0) return;
    float w = maxX - minX;
    float h = maxY - minY;
    float area = max(1e-6f, w * h);

    // Radius tuned to aim for targetCount with comfortable spacing
    float r = sqrt(area / max(1, targetCount)) * 0.85f;

    float cellSize = r / sqrt(2);
    int gridW = (int)ceil(w / cellSize);
    int gridH = (int)ceil(h / cellSize);
    int[] grid = new int[gridW * gridH];
    for (int i = 0; i < grid.length; i++) grid[i] = -1;

    ArrayList<PVector> points = new ArrayList<PVector>();
    ArrayList<Integer> active = new ArrayList<Integer>();

    float x0 = random(minX, maxX);
    float y0 = random(minY, maxY);
      points.add(new PVector(x0, y0));
      active.add(0);

      int gx = (int)((x0 - minX) / cellSize);
      int gy = (int)((y0 - minY) / cellSize);
    if (gx >= 0 && gx < gridW && gy >= 0 && gy < gridH) {
      grid[gy * gridW + gx] = 0;
    }

    int k = 30;
    int maxPoints = max(1, min(targetCount, MAX_SITE_COUNT));

    while (!active.isEmpty() && points.size() < maxPoints) {
      int idx = active.get((int)random(active.size()));
      PVector p = points.get(idx);
      boolean found = false;

      for (int attempt = 0; attempt < k; attempt++) {
        float angle = random(TWO_PI);
        float radius = r * (1 + random(1));
        float nx = p.x + cos(angle) * radius;
        float ny = p.y + sin(angle) * radius;

        if (nx < minX || nx > maxX || ny < minY || ny > maxY) continue;

        int ngx2 = (int)((nx - minX) / cellSize);
        int ngy2 = (int)((ny - minY) / cellSize);

        boolean ok = true;
        for (int yy = max(0, ngy2 - 2); yy <= min(gridH - 1, ngy2 + 2) && ok; yy++) {
          for (int xx = max(0, ngx2 - 2); xx <= min(gridW - 1, ngx2 + 2) && ok; xx++) {
            int pi = grid[yy * gridW + xx];
            if (pi != -1) {
              PVector op = points.get(pi);
              float dx = op.x - nx;
              float dy = op.y - ny;
              if (dx * dx + dy * dy < r * r) {
                ok = false;
              }
            }
          }
        }

        if (ok) {
          int newIndex = points.size();
          points.add(new PVector(nx, ny));
          active.add(newIndex);
          grid[ngy2 * gridW + ngx2] = newIndex;
          found = true;
          break;
        }
      }

      if (!found) {
        active.remove((Integer)idx);
      }
    }

    // If generation collapses (too few points), fall back to a jittered grid to avoid empty maps.
    if (points.isEmpty()) {
      generateGridSites(targetCount);
      return;
    }

    for (int i = 0; i < points.size(); i++) {
      PVector p = points.get(i);
      sites.add(new Site(p.x, p.y));
    }
  }

  // ---------- Biome type management ----------

  void addBiomeType() {
    int nonNoneCount = max(0, biomeTypes.size() - 1);
    ZonePreset preset = (nonNoneCount < ZONE_PRESETS.length) ? ZONE_PRESETS[nonNoneCount] : null;

    if (preset != null) {
      biomeTypes.add(new ZoneType(preset.name, preset.col));
    } else {
      // Fallback: rotate hue from last type
      int n = biomeTypes.size();
      float baseHue = 0.33f;
      float baseSat = 0.4f;
      float baseBri = 1.0f;
      if (n > 1) {
        ZoneType last = biomeTypes.get(n - 1);
        baseHue = (last.hue01 + 0.15f) % 1.0f;
        baseSat = last.sat01;
        baseBri = last.bri01;
      }
      int newIndex = n;
      String name = "Type " + newIndex;
      int col = hsb01ToRGB(baseHue, baseSat, baseBri);
      biomeTypes.add(new ZoneType(name, col));
    }
  }

  void addZone() {
    int idx = zones.size();
    float baseHue = (zones.isEmpty()) ? distributedHueForIndex(0) : pickMaxGapHue();
    int col = zoneColorForHue(baseHue);
    MapZone z = new MapZone("Zone" + (idx + 1), col);
    z.hue01 = baseHue;
    z.updateColorFromHSB();
    zones.add(z);
  }

  void addPathType(PathType pt) {
    if (pt == null) return;
    pathTypes.add(pt);
  }

  void removePathType(int idx) {
    if (idx <= 0) return; // keep first as default
    if (idx < 0 || idx >= pathTypes.size()) return;
    pathTypes.remove(idx);
    for (Path p : paths) {
      if (p.typeId == idx) p.typeId = 0;
      else if (p.typeId > idx) p.typeId -= 1;
    }
  }

  void removeBiomeType(int index) {
    if (index <= 0) return; // don't remove "None"
    if (index >= biomeTypes.size()) return;

    biomeTypes.remove(index);

    // Fix biome indices in cells: shift down
    for (Cell c : cells) {
      if (c.biomeId == index) {
        c.biomeId = 0; // reset to None
      } else if (c.biomeId > index) {
        c.biomeId -= 1;
      }
    }
    renderer.invalidateBiomeOutlineCache();
  }

  void removeZone(int index) {
    if (index < 0 || index >= zones.size()) return;
    zones.remove(index);
    renderer.invalidateBiomeOutlineCache();
  }

  void markRenderCacheDirty() {
    renderer.invalidateBiomeOutlineCache();
    invalidateContourCaches();
  }

  ArrayList<PVector> findSnapPathBidirectional(String kFrom, String kTo, boolean favorFlat,
                                               HashMap<String, PVector> snapNodes,
                                               HashMap<String, ArrayList<String>> snapAdj) {
    ArrayList<PVector> result = null;
    PVector target = snapNodes.get(kTo);
    PVector startP = snapNodes.get(kFrom);
    if (startP == null || target == null) return null;

    HashMap<String, Float> distF = new HashMap<String, Float>();
    HashMap<String, Float> distB = new HashMap<String, Float>();
    HashMap<String, String> prevF = new HashMap<String, String>();
    HashMap<String, String> prevB = new HashMap<String, String>();
    HashSet<String> closedF = new HashSet<String>();
    HashSet<String> closedB = new HashSet<String>();
    PriorityQueue<NodeDist> pqF = new PriorityQueue<NodeDist>();
    PriorityQueue<NodeDist> pqB = new PriorityQueue<NodeDist>();

    distF.put(kFrom, 0.0f);
    distB.put(kTo, 0.0f);
    pqF.add(new NodeDist(kFrom, 0.0f, distSq(startP, target)));
    pqB.add(new NodeDist(kTo, 0.0f, distSq(target, startP)));

    float bestCost = Float.MAX_VALUE;
    String bestMeet = null;
    int expanded = 0;
    HashMap<String, Float> elevCache = new HashMap<String, Float>();

    while (!pqF.isEmpty() || !pqB.isEmpty()) {
      float fFront = pqF.isEmpty() ? Float.MAX_VALUE : pqF.peek().f;
      float fBack = pqB.isEmpty() ? Float.MAX_VALUE : pqB.peek().f;
      boolean expandFront = fFront <= fBack;
      PriorityQueue<NodeDist> pq = expandFront ? pqF : pqB;
      HashMap<String, Float> dist = expandFront ? distF : distB;
      HashMap<String, Float> distOther = expandFront ? distB : distF;
      HashMap<String, String> prev = expandFront ? prevF : prevB;
      HashSet<String> closed = expandFront ? closedF : closedB;

      if (pq.isEmpty()) break;
      NodeDist nd = pq.poll();
      Float bestD = dist.get(nd.k);
      if (bestD != null && nd.g > bestD + 1e-6f) continue;
      if (expanded++ > PATH_MAX_EXPANSIONS) break;
      closed.add(nd.k);

      Float otherCost = distOther.get(nd.k);
      if (otherCost != null) {
        float total = nd.g + otherCost;
        if (total < bestCost) {
          bestCost = total;
          bestMeet = nd.k;
        }
      }

      if (nd.f >= bestCost) continue;

      ArrayList<String> neighbors = snapAdj.get(nd.k);
      if (neighbors == null) continue;
      PVector p = snapNodes.get(nd.k);
      if (p == null) continue;

      for (String nb : neighbors) {
        if (closed.contains(nb)) continue;
        PVector np = snapNodes.get(nb);
        if (np == null) continue;

        float elevA = elevCache.containsKey(nd.k) ? elevCache.get(nd.k) : sampleElevationAt(p.x, p.y, seaLevel);
        float elevB = elevCache.containsKey(nb) ? elevCache.get(nb) : sampleElevationAt(np.x, np.y, seaLevel);
        elevCache.put(nd.k, elevA);
        elevCache.put(nb, elevB);

        float w = distSq(p, np);
        if (pathAvoidWater) {
          boolean aw = elevA < seaLevel;
          boolean bw = elevB < seaLevel;
          if (aw || bw) w *= 1e6f;
        }
        if (favorFlat) {
          float dh = abs(elevB - elevA);
          w *= (1.0f + dh * flattestSlopeBias);
        }

        float ng = nd.g + w;
        Float curD = dist.get(nb);
        if (curD == null || ng < curD - 1e-6f) {
          dist.put(nb, ng);
          prev.put(nb, nd.k);
          float h = expandFront ? distSq(np, target) : distSq(np, startP);
          pq.add(new NodeDist(nb, ng, ng + h * 0.5f));
        }
      }
    }

    if (bestMeet != null) {
      ArrayList<PVector> forward = reconstructPath(prevF, kFrom, bestMeet);
      ArrayList<PVector> backward = reconstructPath(prevB, kTo, bestMeet);
      if (forward != null && backward != null) {
        Collections.reverse(backward);
        if (!backward.isEmpty()) backward.remove(0); // drop duplicate meet
        forward.addAll(backward);
        result = forward;
      }
    } else {
      // fallback: try one-sided best effort
      result = reconstructPath(prevF, kFrom, kTo);
    }

    lastPathfindExpanded = expanded;
    return result;
  }
}

