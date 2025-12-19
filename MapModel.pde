
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
  ArrayList<String> biomePatternFiles = new ArrayList<String>();
  int biomePatternCount = 1;

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
    String comment = "";
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
    ensureCellNeighborsComputed();

    // Collect all water-touching vertices across routes of this type (including junctions)
    HashSet<String> waterKeys = new HashSet<String>();
    for (int pi = 0; pi < paths.size(); pi++) {
      Path p = paths.get(pi);
      if (p == null || p.typeId != typeId || p.routes == null) continue;
      for (ArrayList<PVector> seg : p.routes) {
        if (seg == null) continue;
        for (PVector v : seg) {
          if (pointTouchesWater(v.x, v.y, seaLevel)) {
            waterKeys.add(keyFor(v.x, v.y));
          }
        }
      }
    }

    // Per-route taper: start weight depends on start touching water, end weight on end touching water.
    // Anything not touching water uses the minimum weight.
    for (int pi = 0; pi < paths.size(); pi++) {
      Path p = paths.get(pi);
      if (p == null || p.typeId != typeId || !t.taperOn) continue;
      if (p.routes == null) continue;
      for (int ri = 0; ri < p.routes.size(); ri++) {
        ArrayList<PVector> seg = p.routes.get(ri);
        if (seg == null || seg.size() < 2) continue;
        int n = seg.size();
        float[] prefix = new float[n];
        float[] segLen = new float[n - 1];
        for (int si = 0; si < n - 1; si++) {
          PVector a = seg.get(si);
          PVector b = seg.get(si + 1);
          float len = dist(a.x, a.y, b.x, b.y);
          segLen[si] = len;
          prefix[si + 1] = prefix[si] + len;
        }

        boolean[] water = new boolean[n];
        ArrayList<Integer> waterIdx = new ArrayList<Integer>();
        for (int vi = 0; vi < n; vi++) {
          PVector v = seg.get(vi);
          water[vi] = pointTouchesWater(v.x, v.y, seaLevel) || waterKeys.contains(keyFor(v.x, v.y));
          if (water[vi]) waterIdx.add(vi);
        }

        if (waterIdx.isEmpty()) {
          float midW = lerp(minWeight, baseWeight, 0.5f);
          for (int si = 0; si < n - 1; si++) {
            String ek = pi + ":" + ri + ":" + si;
            weights.put(ek, midW);
          }
          continue;
        }

        float maxDist = 0;
        float[] distToWater = new float[n];
        for (int vi = 0; vi < n; vi++) {
          float d = Float.MAX_VALUE;
          float pos = prefix[vi];
          for (int wi : waterIdx) {
            d = min(d, abs(pos - prefix[wi]));
          }
          distToWater[vi] = d;
          maxDist = max(maxDist, d);
        }
        if (maxDist < 1e-6f) maxDist = 1e-6f;

        for (int si = 0; si < n - 1; si++) {
          float midPos = prefix[si] + segLen[si] * 0.5f;
          float d = Float.MAX_VALUE;
          for (int wi : waterIdx) {
            d = min(d, abs(midPos - prefix[wi]));
          }
          float tNorm = constrain(d / maxDist, 0, 1);
          float w = lerp(baseWeight, minWeight, tNorm);
          w = constrain(w, minWeight, baseWeight);
          String ek = pi + ":" + ri + ":" + si;
          weights.put(ek, w);
        }
      }
    }

    return weights;
  }

  float[] rgbToHSB(int c) {
    // Convenience wrapper; both HSB helpers live in Types.pde and use 0..1 ranges.
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
    // Rendering methods take an explicit PApplet so we can target the main canvas or export buffers.
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

  void drawZoneLabelsRender(PApplet app, RenderSettings s) {
    renderer.drawZoneLabelsRender(app, s);
  }

  void drawPathLabelsRender(PApplet app, RenderSettings s) {
    renderer.drawPathLabelsRender(app, s);
  }

  void drawStructureLabelsRender(PApplet app, RenderSettings s) {
    renderer.drawStructureLabelsRender(app, s);
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

  class SegmentHit {
    PVector a;
    PVector b;
    PVector p;
    int pathIndex = -1;
    int routeIndex = -1;
    int segmentIndex = -1;
    int cellA = -1;
    int cellB = -1;
  }

  Structure computeSnappedStructure(float wx, float wy, StructureAttributes attrs) {
    StructureAttributes at = (attrs != null) ? attrs : new StructureAttributes();
    Structure s = new Structure(wx, wy);
    at.applyTo(s);
    if (s.name == null || s.name.length() == 0) {
      s.name = "Struct " + (structures.size() + 1);
    }
    if (s.snapBinding == null) s.snapBinding = new StructureSnapBinding();
    s.snapBinding.clear();
    // Keep magnetism roughly constant in screen space: smaller in world units when zoomed in.
    float snapRangePx = 20.0f;
    float snapRange = max(0.01f, snapRangePx / max(1e-3f, viewport.zoom));

    StructureSnapMode align = at.alignment;
    float angleAbs = at.angleRad;

    if (align == StructureSnapMode.NONE) {
      s.snapBinding.type = StructureSnapTargetType.NONE;
      s.snapBinding.snapAngleRad = lastStructureSnapAngle;
      s.angle = angleAbs;
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
    SegmentHit seg = (usePaths) ? nearestPathSegmentHit(wx, wy, snapRange) : null;
    if (seg != null) {
      PVector a = seg.a;
      PVector b = seg.b;
      PVector p = seg.p;
      float dx = b.x - a.x;
      float dy = b.y - a.y;
      float ang = atan2(dy, dx);
      if (align == StructureSnapMode.ON_PATH) {
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
      s.angle = ang;
      s.snapBinding.type = StructureSnapTargetType.PATH;
      s.snapBinding.pathIndex = seg.pathIndex;
      s.snapBinding.routeIndex = seg.routeIndex;
      s.snapBinding.segmentIndex = seg.segmentIndex;
      s.snapBinding.segA = a.copy();
      s.snapBinding.segB = b.copy();
      s.snapBinding.snapPoint = p.copy();
      s.snapBinding.snapAngleRad = ang;
      return s;
    }

    SegmentHit guide = (useFrontiers)
      ? nearestFrontierSegmentHit(wx, wy, snapRange,
                                  snapWaterEnabled, snapBiomesEnabled, snapUnderwaterBiomesEnabled,
                                  snapZonesEnabled, snapElevationEnabled && elevBuckets != null,
                                  zoneMembership, elevBuckets)
      : null;
    if (guide != null) {
      PVector a = guide.a;
      PVector b = guide.b;
      PVector p = guide.p;
      float dx = b.x - a.x;
      float dy = b.y - a.y;
      float ang = atan2(dy, dx);
      if (align == StructureSnapMode.ON_PATH) {
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
      s.angle = ang;
      s.snapBinding.type = StructureSnapTargetType.FRONTIER;
      s.snapBinding.cellA = guide.cellA;
      s.snapBinding.cellB = guide.cellB;
      s.snapBinding.segA = a.copy();
      s.snapBinding.segB = b.copy();
      s.snapBinding.snapPoint = p.copy();
      s.snapBinding.snapAngleRad = ang;
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
        s.angle = ang;
        s.snapBinding.type = StructureSnapTargetType.STRUCTURE;
        s.snapBinding.structureIndex = structures.indexOf(closest);
        s.snapBinding.snapAngleRad = ang;
        s.snapBinding.snapPoint = new PVector(closest.x, closest.y);
        return s;
      }
    }

    s.snapBinding.type = StructureSnapTargetType.NONE;
    s.snapBinding.snapAngleRad = lastStructureSnapAngle;
    s.angle = angleAbs;
    return s;
  }

  Structure computeSnappedStructure(float wx, float wy, float size) {
    StructureAttributes attrs = new StructureAttributes();
    attrs.size = size;
    attrs.angleRad = structureAngleOffsetRad;
    attrs.shape = structureShape;
    attrs.alignment = structureSnapMode;
    attrs.aspectRatio = structureAspectRatio;
    attrs.hue01 = structureHue01;
    attrs.sat01 = structureSat01;
    attrs.alpha01 = structureAlpha01;
    attrs.strokeWeightPx = structureStrokePx;
    attrs.name = structureNameDraft;
    return computeSnappedStructure(wx, wy, attrs);
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
                                    showWaterContours, useLighting, lightAzimuthDeg, lightAltitudeDeg, quantSteps);
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
        int col = app.color(litShade * 255);
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
        water = app.color(baseR * shade, baseG * shade, baseB * shade, 255);
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
        int strokeCol = app.color(50, 50, 50, 180);
        drawContourSet(app, grid, start, maxElev, step, strokeCol);
      }

      if (showWaterContours && drawWater) {
        float minWater = minElev;
        if (minWater < seaLevel - 1e-4f) {
          float depthRange = seaLevel - minWater;
          float step = max(0.02f, depthRange / 5.0f);
          float start = seaLevel - step;
          int strokeCol = app.color(30, 70, 140, 170);
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

  PVector parseKey(String k) {
    if (k == null) return null;
    String[] parts = split(k, ':');
    if (parts == null || parts.length != 2) return null;
    try {
      float x = Integer.parseInt(parts[0]) / 10000.0f;
      float y = Integer.parseInt(parts[1]) / 10000.0f;
      return new PVector(x, y);
    } catch (Exception e) {
      return null;
    }
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
    app.strokeCap(PConstants.ROUND);
    app.strokeJoin(PConstants.ROUND);
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
      p.draw(app, w, taperOn, taperW, i, showNodes, 1);

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
      sel.draw(app, w, taperOn, taperW, selectedPathIndex, showNodes, 1);
    }

    app.popStyle();
  }

  void drawPathsRender(PApplet app, RenderSettings s) {
    if (paths.isEmpty() || s == null) return;
    app.pushStyle();
    app.strokeCap(PConstants.ROUND);
    app.strokeJoin(PConstants.ROUND);
    app.noFill();
    HashMap<Integer, HashMap<String, Float>> taperCache = new HashMap<Integer, HashMap<String, Float>>();
    float[] hsbScratch = new float[3];

    for (int i = 0; i < paths.size(); i++) {
      Path p = paths.get(i);
      if (p.routes.isEmpty()) continue;
      PathType pt = getPathType(p.typeId);
      int baseCol = (pt != null) ? pt.col : app.color(80);
      rgbToHSB01(baseCol, hsbScratch);
      float alphaScale = constrain(s.pathSatScale01, 0, 1);
      if (alphaScale <= 1e-4f) continue;
      hsbScratch[1] = constrain(hsbScratch[1] * alphaScale, 0, 1);
      int rgb = hsb01ToRGB(hsbScratch[0], hsbScratch[1], hsbScratch[2]);
      int col = app.color((rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF, alphaScale * 255);
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
      p.draw(app, w, taperOn, taperW, i, false, 1.0f);
    }
    app.popStyle();
  }

  // ---------- Path generation ----------

  void generatePathsAuto(float seaLevel) {
    ensureCellNeighborsComputed();
    if (structures != null) {
      for (int i = structures.size() - 1; i >= 0; i--) {
        Structure st = structures.get(i);
        if (st != null && "IP".equals(st.name)) structures.remove(i);
      }
    }
    int roadType = ensurePathTypeByName("Road");
    int riverType = ensurePathTypeByName("River");
    int bridgeType = ensurePathTypeByName("Bridge");
    float worldW = maxX - minX;
    float worldH = maxY - minY;
    float stepLen = max(1e-4f, min(worldW, worldH) * 0.02f);

    // Collect coastline midpoints (land/water boundary)
    ArrayList<PVector> coastPts = new ArrayList<PVector>();
    ArrayList<PVector> coastNrm = new ArrayList<PVector>(); // normal pointing from land to water
    int n = cells.size();
    for (int ci = 0; ci < n; ci++) {
      Cell c = cells.get(ci);
      if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
      boolean aWater = c.elevation < seaLevel;
      ArrayList<Integer> nbs = (ci < cellNeighbors.size()) ? cellNeighbors.get(ci) : null;
        if (nbs == null) continue;
        int vc = c.vertices.size();
        for (int nbIdx : nbs) {
          if (nbIdx < 0 || nbIdx >= n) continue;
          if (nbIdx < ci) continue; // avoid dup
          Cell nb = cells.get(nbIdx);
          if (nb == null || nb.vertices == null || nb.vertices.size() < 3) continue;
          boolean bWater = nb.elevation < seaLevel;
          if (aWater == bWater) continue;
          PVector cenA = cellCentroid(c);
          PVector cenB = cellCentroid(nb);
          // find shared edge
          for (int e = 0; e < vc; e++) {
            PVector a = c.vertices.get(e);
            PVector b = c.vertices.get((e + 1) % vc);
            for (int je = 0; je < nb.vertices.size(); je++) {
              PVector na = nb.vertices.get(je);
              PVector nbp = nb.vertices.get((je + 1) % nb.vertices.size());
              boolean match = distSq(a, na) < 1e-6f && distSq(b, nbp) < 1e-6f;
              boolean matchRev = distSq(a, nbp) < 1e-6f && distSq(b, na) < 1e-6f;
              if (match || matchRev) {
                PVector va = a.copy();
                PVector vb = b.copy();
                coastPts.add(va);
                coastPts.add(vb);
                PVector nrm = new PVector(0, 1);
                if (cenA != null && cenB != null) {
                  PVector land = aWater ? cenB : cenA;
                  PVector water = aWater ? cenA : cenB;
                  nrm = PVector.sub(water, land);
                  if (nrm.magSq() > 1e-12f) nrm.normalize(); else nrm = new PVector(0, 1);
                }
                coastNrm.add(nrm);
                coastNrm.add(nrm.copy());
                break;
              }
            }
          }
        }
    }

    // Precompute mesh vertices for snapping
    ArrayList<PVector> meshVerts = new ArrayList<PVector>();
    HashSet<String> vertSeen = new HashSet<String>();
    for (Cell c : cells) {
      if (c == null || c.vertices == null) continue;
      for (PVector v : c.vertices) {
        String k = keyFor(v.x, v.y);
        if (vertSeen.add(k)) meshVerts.add(v);
      }
    }
    ArrayList<PVector[]> existingSegs = collectAllPathSegments();

    // Rivers
    for (int i = 0; i < 5; i++) {
      if (coastPts.isEmpty()) break;
      PVector start = coastPts.get((int)random(coastPts.size()));
      ArrayList<PVector> route = growRiver(start, seaLevel, stepLen, existingSegs);
      if (route == null || route.size() < 2) continue;
      addPathFromPoints(riverType, "River " + (paths.size() + 1), route);
      existingSegs = collectAllPathSegments();
    }
    // Interest points (snap to nearest cell vertex)
    ArrayList<PVector> interest = new ArrayList<PVector>();
    // biggest structures
    if (structures != null && !structures.isEmpty()) {
      ArrayList<Structure> sorted = new ArrayList<Structure>(structures);
      Collections.sort(sorted, new Comparator<Structure>() {
        public int compare(Structure a, Structure b) { return Float.compare(b.size, a.size); }
      });
      int take = min(5, sorted.size());
      for (int i = 0; i < take; i++) {
        Structure s = sorted.get(i);
        Cell c = findCellContaining(s.x, s.y);
        if (c != null && c.elevation > seaLevel) {
        interest.add(snapToVertices(cellCentroid(c), meshVerts));
      } else {
        PVector p = new PVector(s.x, s.y);
        interest.add(snapToVertices(p, meshVerts));
      }
    }
    }
    // border points (limit)
    float margin = min(worldW, worldH) * 0.05f;
    boolean borderTop = false, borderBottom = false, borderLeft = false, borderRight = false;
    for (Cell c : cells) {
      if (borderTop && borderBottom && borderLeft && borderRight) break;
      if (c == null || c.vertices == null || c.vertices.isEmpty()) continue;
      if (c.elevation <= seaLevel) continue;
      PVector cen = cellCentroid(c);
      if (cen == null) continue;
      if (abs(cen.x - minX) < margin && !borderLeft) { interest.add(snapToVertices(cen, meshVerts)); borderLeft = true; }
      else if (abs(cen.x - maxX) < margin && !borderRight) { interest.add(snapToVertices(cen, meshVerts)); borderRight = true; }
      else if (abs(cen.y - minY) < margin && !borderBottom) { interest.add(snapToVertices(cen, meshVerts)); borderBottom = true; }
      else if (abs(cen.y - maxY) < margin && !borderTop) { interest.add(snapToVertices(cen, meshVerts)); borderTop = true; }
    }
    // zones centers
    for (MapZone z : zones) {
      if (z == null || z.cells == null || z.cells.isEmpty()) continue;
      float sx = 0, sy = 0; int cnt = 0;
      for (int ci : z.cells) {
        if (ci < 0 || ci >= cells.size()) continue;
        Cell c = cells.get(ci);
        if (c == null) continue;
        PVector cen = cellCentroid(c);
        if (cen == null) continue;
        if (c.elevation <= seaLevel) continue;
        sx += cen.x; sy += cen.y; cnt++;
      }
      if (cnt > 0) interest.add(snapToVertices(new PVector(sx / cnt, sy / cnt), meshVerts));
    }
    // farthest from sea: pick highest elevation land cell
    float bestElev = -Float.MAX_VALUE;
    PVector bestP = null;
    for (Cell c : cells) {
      if (c == null || c.vertices == null || c.vertices.isEmpty()) continue;
      if (c.elevation <= seaLevel) continue;
      if (c.elevation > bestElev) {
        bestElev = c.elevation;
        bestP = cellCentroid(c);
      }
    }
    if (bestP != null) interest.add(snapToVertices(bestP, meshVerts));

    // Dedup interest
    ArrayList<PVector> interestUnique = new ArrayList<PVector>();
    HashSet<String> seen = new HashSet<String>();
    for (PVector p : interest) {
      if (p == null) continue;
      String k = keyFor(p.x, p.y);
      if (seen.contains(k)) continue;
      seen.add(k);
      interestUnique.add(p);
    }
    interest = interestUnique;

    // Dedup very close interest points, keep closer to center
    PVector center = new PVector((minX + maxX) * 0.5f, (minY + maxY) * 0.5f);
    float dedupThresh = min(worldW, worldH) * 0.2f;
    ArrayList<PVector> dedup = new ArrayList<PVector>();
    for (PVector p : interest) {
      if (p == null) continue;
      boolean replaced = false;
      for (int i = 0; i < dedup.size(); i++) {
        PVector q = dedup.get(i);
        if (dist2D(p, q) < dedupThresh) {
          float dp = dist2D(p, center);
          float dq = dist2D(q, center);
          if (dp < dq) dedup.set(i, p);
          replaced = true;
          break;
        }
      }
      if (!replaced) dedup.add(p);
    }
    interest = dedup;

    // Connect five closest pairs with roads (debug)
    ArrayList<ArrayList<PVector>> roadCandidates = new ArrayList<ArrayList<PVector>>();
    ArrayList<Float> roadCandidateDistSq = new ArrayList<Float>();
    boolean usePathfindingForRoads = true; // set false to skip pathfinding for debugging
    for (int i = 0; i < interest.size(); i++) {
      for (int j = i + 1; j < interest.size(); j++) {
        PVector pa = interest.get(i);
        PVector pb = interest.get(j);
        ArrayList<PVector> pathPts;
        if (usePathfindingForRoads) {
          pathPts = findSnapPath(pa, pb);
        } else {
          pathPts = new ArrayList<PVector>();
          pathPts.add(pa);
          pathPts.add(pb);
        }
        if (pathPts == null || pathPts.size() < 2) continue;
        boolean overWater = false;
        for (PVector p : pathPts) {
          if (p == null) continue;
          if (sampleElevationAt(p.x, p.y, seaLevel) < seaLevel) { overWater = true; break; }
        }
        if (overWater) continue;
        float dx = pa.x - pb.x;
        float dy = pa.y - pb.y;
        float len = dx * dx + dy * dy; // compare by squared distance for speed
        roadCandidates.add(pathPts);
        roadCandidateDistSq.add(len);
      }
    }
    ArrayList<Integer> roadOrder = new ArrayList<Integer>();
    for (int i = 0; i < roadCandidates.size(); i++) roadOrder.add(i);
    final ArrayList<Float> roadLenRef = roadCandidateDistSq;
    Collections.sort(roadOrder, new Comparator<Integer>() {
      public int compare(Integer a, Integer b) {
        return Float.compare(roadLenRef.get(a), roadLenRef.get(b));
      }
    });
    int roadLinks = 0;
    for (int idx : roadOrder) {
      if (roadLinks >= 5) break;
      ArrayList<PVector> pathPts = roadCandidates.get(idx);
      addPathFromPoints(roadType, "Road " + (paths.size() + 1), pathPts);
      roadLinks++;
    }
    // Bridges: try three times
    // Bridge generation: coastline cells with >=3 consecutive water edges
    ArrayList<Integer> coastCells = new ArrayList<Integer>();
    ArrayList<Integer> coastStartEdge = new ArrayList<Integer>();
    ArrayList<Integer> coastLenEdge = new ArrayList<Integer>();
    for (int ci = 0; ci < cells.size() && coastCells.size() < 10; ci++) {
      Cell c = cells.get(ci);
      if (c == null || c.vertices == null) continue;
      if (c.elevation < seaLevel) continue;
      int vc = c.vertices.size();
      if (vc < 3) continue;
      boolean[] waterEdge = new boolean[vc];
      ArrayList<Integer> nbs = (ci < cellNeighbors.size()) ? cellNeighbors.get(ci) : null;
      if (nbs == null) continue;
      for (int e = 0; e < vc; e++) {
        PVector a = c.vertices.get(e);
        PVector b = c.vertices.get((e + 1) % vc);
        boolean edgeWater = false;
        for (int nbIdx : nbs) {
          if (nbIdx < 0 || nbIdx >= cells.size()) continue;
          Cell nb = cells.get(nbIdx);
          if (nb == null || nb.vertices == null || nb.vertices.size() < 3) continue;
          if (nb.elevation >= seaLevel) continue;
          int nvc = nb.vertices.size();
          for (int je = 0; je < nvc; je++) {
            PVector na = nb.vertices.get(je);
            PVector nbp = nb.vertices.get((je + 1) % nvc);
            boolean match = distSq(a, na) < 1e-6f && distSq(b, nbp) < 1e-6f;
            boolean matchRev = distSq(a, nbp) < 1e-6f && distSq(b, na) < 1e-6f;
            if (match || matchRev) { edgeWater = true; break; }
          }
          if (edgeWater) break;
        }
        waterEdge[e] = edgeWater;
      }
      int bestLen = 0, bestStart = -1, curLen = 0, curStart = 0;
      for (int i = 0; i < vc * 2; i++) { // handle wrap-around by looping twice
        int idx = i % vc;
        if (waterEdge[idx]) {
          if (curLen == 0) curStart = idx;
          curLen++;
          if (curLen > bestLen) { bestLen = curLen; bestStart = curStart; }
        } else {
          curLen = 0;
        }
      }
      if (bestLen >= 3) {
        if (bestLen > vc) bestLen = vc;
        coastCells.add(ci);
        coastStartEdge.add(bestStart);
        coastLenEdge.add(bestLen);
      }
    }

    class BridgeCandidate {
      PVector a, b;
      float len;
      BridgeCandidate(PVector a, PVector b, float len) { this.a = a; this.b = b; this.len = len; }
    }
    ArrayList<BridgeCandidate> bridgeCand = new ArrayList<BridgeCandidate>();
    for (int idx = 0; idx < coastCells.size(); idx++) {
      int ci = coastCells.get(idx);
      Cell c = cells.get(ci);
      if (c == null || c.vertices == null) continue;
      PVector cen = cellCentroid(c);
      if (cen == null) continue;
      int vc = c.vertices.size();
      int start = coastStartEdge.get(idx);
      int lenEdge = coastLenEdge.get(idx);
      int midEdge = (lenEdge % 2 == 1) ? (start + lenEdge / 2) % vc : -1;
      int midVertex = (lenEdge % 2 == 0) ? (start + lenEdge / 2) % vc : -1;
      PVector target;
      if (midEdge >= 0) {
        PVector a = c.vertices.get(midEdge);
        PVector b = c.vertices.get((midEdge + 1) % vc);
        target = PVector.add(a, b).mult(0.5f);
      } else {
        target = c.vertices.get(midVertex).copy();
      }
      PVector dir = PVector.sub(target, cen);
      if (dir.magSq() < 1e-8f) continue;
      dir.normalize();
      float travelMax = min(worldW, worldH) * 0.6f;
      float step = stepLen;
      PVector probe = cen.copy();
      PVector endPoint = null;
      for (int s = 0; s < 800 && s * step < travelMax; s++) {
        probe.add(PVector.mult(dir, step));
        Cell pc = findCellContaining(probe.x, probe.y);
        if (pc == null) continue;
        if (pc == c) continue;
        if (pc.elevation < seaLevel) continue;
        // check if pc touches water
        boolean touchesWater = false;
        int pcIdx = indexOfCell(pc);
        if (pcIdx >= 0 && pc.vertices != null && pc.vertices.size() >= 3) {
          int pvc = pc.vertices.size();
          ArrayList<Integer> nbs = (pcIdx < cellNeighbors.size()) ? cellNeighbors.get(pcIdx) : null;
          if (nbs != null) {
            for (int e = 0; e < pvc && !touchesWater; e++) {
              PVector a = pc.vertices.get(e);
              PVector b = pc.vertices.get((e + 1) % pvc);
              for (int nbIdx : nbs) {
                if (nbIdx < 0 || nbIdx >= cells.size()) continue;
                Cell nb = cells.get(nbIdx);
                if (nb == null || nb.elevation >= seaLevel || nb.vertices == null) continue;
                int nvc = nb.vertices.size();
                for (int je = 0; je < nvc; je++) {
                  PVector na = nb.vertices.get(je);
                  PVector nbp = nb.vertices.get((je + 1) % nvc);
                  boolean match = distSq(a, na) < 1e-6f && distSq(b, nbp) < 1e-6f;
                  boolean matchRev = distSq(a, nbp) < 1e-6f && distSq(b, na) < 1e-6f;
                  if (match || matchRev) { touchesWater = true; break; }
                }
                if (touchesWater) break;
              }
            }
          }
        }
        if (touchesWater) {
          PVector tgt = cellCentroid(pc);
          if (tgt != null) { endPoint = tgt; break; }
        }
      }
      if (endPoint == null) continue;
      float bridgeLen = dist2D(cen, endPoint);
      ArrayList<PVector> road = findSnapPath(cen, endPoint);
      float roadLen = 0;
      if (road != null) {
        for (int i = 0; i < road.size() - 1; i++) roadLen += dist2D(road.get(i), road.get(i + 1));
      }
      if (road == null || roadLen >= bridgeLen * 2f) {
        bridgeCand.add(new BridgeCandidate(cen.copy(), endPoint.copy(), bridgeLen));
      }
    }
    Collections.sort(bridgeCand, new Comparator<BridgeCandidate>() {
      public int compare(BridgeCandidate a, BridgeCandidate b) { return Float.compare(a.len, b.len); }
    });
    int bridges = 0;
    for (BridgeCandidate bc : bridgeCand) {
      if (bridges >= 3) break;
      ArrayList<PVector> bridgePts = new ArrayList<PVector>();
      bridgePts.add(bc.a.copy());
      bridgePts.add(bc.b.copy());
      ArrayList<PVector[]> segs = segmentsFromPoints(bridgePts);
      if (segmentsCross(segs, existingSegs)) continue;
      addPathFromPoints(bridgeType, "Bridge " + (paths.size() + 1), bridgePts);
      existingSegs.addAll(segs);
      bridges++;
    }
  }


  int ensurePathTypeByName(String name) {
    if (pathTypes != null) {
      for (int i = 0; i < pathTypes.size(); i++) {
        PathType pt = pathTypes.get(i);
        if (pt != null && pt.name != null && pt.name.equalsIgnoreCase(name)) return i;
      }
    }
    int presetIdx = -1;
    for (int i = 0; i < PATH_TYPE_PRESETS.length; i++) {
      PathTypePreset p = PATH_TYPE_PRESETS[i];
      if (p != null && p.name != null && p.name.equalsIgnoreCase(name)) {
        presetIdx = i;
        break;
      }
    }
    PathType created = (presetIdx >= 0) ? makePathTypeFromPreset(presetIdx) : new PathType(name, color(60), 2.0f, 1.0f, PathRouteMode.PATHFIND, 0.0f, true, false);
    addPathType(created);
    return pathTypes.size() - 1;
  }

  ArrayList<PVector> growRiver(PVector start, float seaLevel, float stepLen, ArrayList<PVector[]> avoid) {
    if (start == null) return null;
    ArrayList<PVector> pts = new ArrayList<PVector>();
    pts.add(start.copy());
    PVector dir = new PVector(0, 1);
    float lastElev = sampleElevationAt(start.x, start.y, seaLevel);
    int maxSeg = 60;
    for (int i = 0; i < maxSeg; i++) {
      PVector cur = pts.get(pts.size() - 1);
      ArrayList<PVector> candidates = new ArrayList<PVector>();
      for (int k = 0; k < 5; k++) {
        float ang = radians(random(-30, 30));
        PVector d = dir.copy();
        d.rotate(ang);
        if (d.y < 0) d.y = abs(d.y); // push upward
        d.normalize();
        d.mult(stepLen);
        PVector np = PVector.add(cur, d);
        candidates.add(np);
      }
      PVector best = null;
      float bestElev = -Float.MAX_VALUE;
      for (PVector c : candidates) {
        float elev = sampleElevationAt(c.x, c.y, seaLevel);
        if (elev <= seaLevel) continue;
        if (elev < lastElev - 0.02f) continue; // allow small dips but mostly uphill
        if (segmentTouches(c, pts, stepLen * 0.5f)) continue;
        if (segmentsCross(segmentsFromPoints(Arrays.asList(cur, c)), avoid)) continue;
        if (elev > bestElev) { bestElev = elev; best = c; }
      }
      if (best == null) break;
      pts.add(best);
      lastElev = max(lastElev, bestElev);
      dir = PVector.sub(best, cur);
      if (pts.size() > 80) break;
    }
    if (pts.size() < 2) return pts;
    if (pts.size() > 31) {
      int mid = pts.size() / 2;
      ArrayList<PVector> branch = growBranch(pts.get(mid), pts, seaLevel, stepLen * 0.8f, avoid);
      if (branch != null && branch.size() > 1) {
        addPathFromPoints(ensurePathTypeByName("River"), "River Branch " + (paths.size() + 1), branch);
        avoid.addAll(segmentsFromPoints(branch));
      }
    }
    avoid.addAll(segmentsFromPoints(pts));
    return pts;
  }

  ArrayList<PVector> growBranch(PVector start, ArrayList<PVector> main, float seaLevel, float stepLen, ArrayList<PVector[]> avoid) {
    ArrayList<PVector> pts = new ArrayList<PVector>();
    pts.add(start.copy());
    PVector dir = new PVector(0, 1);
    for (int i = 0; i < 40; i++) {
      PVector cur = pts.get(pts.size() - 1);
      PVector best = null;
      float bestElev = -Float.MAX_VALUE;
      for (int k = 0; k < 4; k++) {
        float ang = radians(random(-40, 40));
        PVector d = dir.copy();
        d.rotate(ang);
        d.y = abs(d.y);
        d.normalize();
        d.mult(stepLen);
        PVector np = PVector.add(cur, d);
        float elev = sampleElevationAt(np.x, np.y, seaLevel);
        if (elev <= seaLevel) continue;
        if (segmentTouches(np, main, stepLen * 0.5f)) continue;
        ArrayList<PVector[]> segs = segmentsFromPoints(Arrays.asList(cur, np));
        if (segmentsCross(segs, avoid)) continue;
        if (elev > bestElev) { bestElev = elev; best = np; }
      }
      if (best == null) break;
      pts.add(best);
      dir = PVector.sub(best, cur);
    }
    return (pts.size() < 3) ? null : pts;
  }

  boolean segmentTouches(PVector p, ArrayList<PVector> poly, float minDist) {
    float md2 = minDist * minDist;
    for (int i = 0; i < poly.size(); i++) {
      if (distSq(p, poly.get(i)) < md2) return true;
      if (i < poly.size() - 1) {
        if (pointToSegmentSq(p, poly.get(i), poly.get(i + 1)) < md2) return true;
      }
    }
    return false;
  }

  ArrayList<PVector[]> segmentsFromPoints(List<PVector> pts) {
    ArrayList<PVector[]> out = new ArrayList<PVector[]>();
    if (pts == null) return out;
    for (int i = 0; i < pts.size() - 1; i++) {
      out.add(new PVector[] { pts.get(i), pts.get(i + 1) });
    }
    return out;
  }

  boolean segmentsCross(ArrayList<PVector[]> a, ArrayList<PVector[]> b) {
    if (a == null || b == null) return false;
    for (PVector[] sa : a) {
      for (PVector[] sb : b) {
        if (segmentsIntersect(sa[0], sa[1], sb[0], sb[1])) return true;
      }
    }
    return false;
  }

  ArrayList<PVector> trimAtFirstIntersection(ArrayList<PVector> pts, ArrayList<PVector[]> existing) {
    if (pts == null || pts.size() < 2) return null;
    ArrayList<PVector> out = new ArrayList<PVector>();
    out.add(pts.get(0));
    for (int i = 0; i < pts.size() - 1; i++) {
      PVector a = pts.get(i);
      PVector b = pts.get(i + 1);
      PVector hit = null;
      for (PVector[] ex : existing) {
        if (segmentsIntersect(a, b, ex[0], ex[1])) {
          hit = segmentIntersection(a, b, ex[0], ex[1]);
          break;
        }
      }
      if (hit != null) {
        out.add(hit);
        break;
      } else {
        out.add(b);
      }
    }
    return (out.size() < 2) ? null : out;
  }

  void addPathFromPoints(int typeId, String name, ArrayList<PVector> pts) {
    if (pts == null || pts.size() < 2) return;
    Path p = new Path();
    p.typeId = constrain(typeId, 0, max(0, pathTypes.size() - 1));
    p.name = name;
    p.addRoute(pts);
    paths.add(p);
    snapDirty = true;
  }

  boolean segmentsIntersect(PVector a1, PVector a2, PVector b1, PVector b2) {
    float d = (a2.x - a1.x) * (b2.y - b1.y) - (a2.y - a1.y) * (b2.x - b1.x);
    if (abs(d) < 1e-6f) return false;
    float ua = ((b1.x - a1.x) * (b2.y - b1.y) - (b1.y - a1.y) * (b2.x - b1.x)) / d;
    float ub = ((b1.x - a1.x) * (a2.y - a1.y) - (b1.y - a1.y) * (a2.x - a1.x)) / d;
    return ua >= 0 && ua <= 1 && ub >= 0 && ub <= 1;
  }

  PVector segmentIntersection(PVector a1, PVector a2, PVector b1, PVector b2) {
    float d = (a2.x - a1.x) * (b2.y - b1.y) - (a2.y - a1.y) * (b2.x - b1.x);
    if (abs(d) < 1e-6f) return null;
    float ua = ((b1.x - a1.x) * (b2.y - b1.y) - (b1.y - a1.y) * (b2.x - b1.x)) / d;
    return new PVector(a1.x + ua * (a2.x - a1.x), a1.y + ua * (a2.y - a1.y));
  }

  PVector snapToVertices(PVector p, ArrayList<PVector> meshVerts) {
    if (p == null) return null;
    if (meshVerts == null || meshVerts.isEmpty()) return p;
    float bestD = Float.MAX_VALUE;
    PVector best = p;
    for (PVector v : meshVerts) {
      float d2 = distSq(p, v);
      if (d2 < bestD) {
        bestD = d2;
        best = v;
      }
    }
    return best.copy();
  }

  float pointToSegmentSq(PVector p, PVector a, PVector b) {
    float dx = b.x - a.x;
    float dy = b.y - a.y;
    if (abs(dx) < 1e-6f && abs(dy) < 1e-6f) return distSq(p, a);
    float t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / (dx * dx + dy * dy);
    t = constrain(t, 0, 1);
    float px = a.x + t * dx;
    float py = a.y + t * dy;
    float ddx = p.x - px;
    float ddy = p.y - py;
    return ddx * ddx + ddy * ddy;
  }

  // ---------- Paths management ----------

  String defaultPathNameForType(int typeId) {
    String base = "Path";
    if (pathTypes != null && typeId >= 0 && typeId < pathTypes.size()) {
      PathType pt = pathTypes.get(typeId);
      if (pt != null && pt.name != null && pt.name.trim().length() > 0) {
        base = pt.name.trim();
      }
    }
    if (base.length() == 0) base = "Path";
    String baseLower = base.toLowerCase();
    int maxIdx = 0;
    if (paths != null) {
      for (Path p : paths) {
        if (p == null || p.name == null) continue;
        String nm = p.name.trim();
        String nmLower = nm.toLowerCase();
        if (nmLower.startsWith(baseLower)) {
          String tail = nm.substring(base.length()).trim();
          try {
            int idx = Integer.parseInt(tail);
            if (idx > maxIdx) maxIdx = idx;
          } catch (Exception e) {
            // ignore non-numeric suffix
          }
          if (tail.length() == 0 && maxIdx < 1) maxIdx = 1;
        }
      }
    }
    int next = (maxIdx <= 0) ? 1 : maxIdx + 1;
    return base + " " + next;
  }

  void addFinishedPath(Path p) {
    if (p == null) return;
    if (p.routes.isEmpty()) return; // ignore degenerate paths
    if (p.name == null || p.name.length() == 0) {
      p.name = defaultPathNameForType(p.typeId);
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

  SegmentHit nearestPathSegmentHit(float wx, float wy, float maxDist) {
    if (paths == null || paths.isEmpty()) return null;
    float best = maxDist;
    SegmentHit bestHit = null;
    for (int pi = 0; pi < paths.size(); pi++) {
      Path p = paths.get(pi);
      if (p == null || p.routes == null) continue;
      for (int ri = 0; ri < p.routes.size(); ri++) {
        ArrayList<PVector> seg = p.routes.get(ri);
        if (seg == null) continue;
        for (int si = 0; si < seg.size() - 1; si++) {
          PVector a = seg.get(si);
          PVector b = seg.get(si + 1);
          PVector proj = closestPointOnSegment(wx, wy, a, b);
          float d = dist(wx, wy, proj.x, proj.y);
          if (d < best) {
            best = d;
            bestHit = new SegmentHit();
            bestHit.a = a;
            bestHit.b = b;
            bestHit.p = proj;
            bestHit.pathIndex = pi;
            bestHit.routeIndex = ri;
            bestHit.segmentIndex = si;
          }
        }
      }
    }
    return bestHit;
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

  SegmentHit nearestFrontierSegmentHit(float wx, float wy, float maxDist,
                                       boolean useWater, boolean useBiomes, boolean useUnderwaterBiomes,
                                       boolean useZones, boolean useElevation,
                                       int[] zoneMembership, int[] elevBuckets) {
    if (cells == null || cells.isEmpty()) return null;
    if (!useWater && !useBiomes && !useUnderwaterBiomes && !useZones && !useElevation) return null;
    ensureCellNeighborsComputed();
    float eps = 1e-4f;
    float eps2 = eps * eps;

    float best = maxDist;
    SegmentHit bestHit = null;

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
              bestHit = new SegmentHit();
              bestHit.a = a0;
              bestHit.b = a1;
              bestHit.p = proj;
              bestHit.cellA = i;
              bestHit.cellB = nb;
            }
            break;
          }
        }
      }
    }
    return bestHit;
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

  void makePlateaus(float seaLevel) {
    if (cells == null || cells.isEmpty()) return;
    ensureCellNeighborsComputed();
    int nCells = cells.size();
    int targetCount = max(1, nCells / 100);
    int iterations = max(1, nCells / 1000);
    for (int iter = 0; iter < iterations; iter++) {
      int startIdx = (int)random(nCells);
      Cell start = cells.get(startIdx);
      if (start == null || start.vertices == null || start.vertices.isEmpty()) continue;
      HashSet<Integer> visited = new HashSet<Integer>();
      visited.add(startIdx);
      float sum = start.elevation;
      int count = 1;

      while (count < targetCount) {
        float avg = sum / max(1, count);
        float bestDiff = Float.MAX_VALUE;
        int bestIdx = -1;
        for (int idx : visited) {
          ArrayList<Integer> nbs = cellNeighbors.get(idx);
          if (nbs == null) continue;
          for (int nb : nbs) {
            if (nb < 0 || nb >= nCells) continue;
            if (visited.contains(nb)) continue;
            Cell nc = cells.get(nb);
            if (nc == null) continue;
            float diff = abs(nc.elevation - avg);
            if (diff < bestDiff) {
              bestDiff = diff;
              bestIdx = nb;
            }
          }
        }
        if (bestIdx < 0) break;
        visited.add(bestIdx);
        Cell added = cells.get(bestIdx);
        if (added != null) {
          sum += added.elevation;
          count++;
        }
      }

      float avg = sum / max(1, count);
      for (int idx : visited) {
        Cell c = cells.get(idx);
        if (c == null) continue;
        c.elevation = lerp(c.elevation, avg, 0.8f);
      }
    }
    normalizeElevationsIfOutOfBounds(seaLevel);
    invalidateContourCaches();
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

Cell nearestCell(float wx, float wy) {
  if (cells == null || cells.isEmpty()) return null;
  Cell best = null;
  float bestD2 = Float.MAX_VALUE;
  for (Cell c : cells) {
    if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
    PVector cen = cellCentroid(c);
    float dx = cen.x - wx;
    float dy = cen.y - wy;
    float d2 = dx * dx + dy * dy;
    if (d2 < bestD2) {
      bestD2 = d2;
      best = c;
    }
  }
  return best;
}

int findCellIndexContaining(float wx, float wy) {
  if (cells == null) return -1;
  for (int i = 0; i < cells.size(); i++) {
    Cell c = cells.get(i);
    if (c == null) continue;
    if (pointInPolygon(wx, wy, c.vertices)) return i;
  }
  return -1;
}

boolean pointTouchesWater(float wx, float wy, float sea) {
  int ci = findCellIndexContaining(wx, wy);
  if (ci < 0 || ci >= cells.size()) return false;
  Cell c = cells.get(ci);
  if (c == null) return false;
  if (c.elevation <= sea) return true;
  ensureCellNeighborsComputed();
  ArrayList<Integer> nbs = (ci < cellNeighbors.size()) ? cellNeighbors.get(ci) : null;
  if (nbs != null) {
    for (int nb : nbs) {
      if (nb < 0 || nb >= cells.size()) continue;
      Cell nc = cells.get(nb);
      if (nc == null) continue;
      if (nc.elevation <= sea) return true;
    }
  }
  return false;
}

float structureRadius(float size, float aspect) {
  return size * 0.5f * max(1.0f, aspect);
}

boolean structuresOverlap(ArrayList<Structure> list, float x, float y, float size, float aspect, float slack) {
  float r = structureRadius(size, aspect);
  for (Structure s : list) {
    if (s == null) continue;
    float ra = structureRadius(s.size, s.aspect);
    float dx = s.x - x;
    float dy = s.y - y;
    float d2 = dx * dx + dy * dy;
    float rr = r + ra;
    if (d2 < rr * rr * slack) return true;
  }
  return false;
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

  ArrayList<ArrayList<Integer>> mapCellsToZones() {
    int n = (cells != null) ? cells.size() : 0;
    ArrayList<ArrayList<Integer>> result = new ArrayList<ArrayList<Integer>>();
    for (int i = 0; i < n; i++) {
      result.add(new ArrayList<Integer>());
    }
    if (zones == null || zones.isEmpty() || n == 0) return result;
    for (int zi = 0; zi < zones.size(); zi++) {
      MapZone z = zones.get(zi);
      if (z == null || z.cells == null) continue;
      for (int ci : z.cells) {
        if (ci >= 0 && ci < n) {
          result.get(ci).add(zi);
        }
      }
    }
    return result;
  }

  void pruneZoneUnderwater(MapZone zone, float sea) {
    if (zone == null || zone.cells == null || cells == null) return;
    ArrayList<Integer> kept = new ArrayList<Integer>();
    for (int ci : zone.cells) {
      if (ci < 0 || ci >= cells.size()) continue;
      Cell c = cells.get(ci);
      if (c == null || c.elevation < sea) continue;
      kept.add(ci);
    }
    zone.cells.clear();
    zone.cells.addAll(kept);
  }

  void removeUnderwaterCellsFromZone(int zoneIdx, float sea) {
    if (zones == null || zones.isEmpty()) return;
    if (zoneIdx >= 0 && zoneIdx < zones.size()) {
      pruneZoneUnderwater(zones.get(zoneIdx), sea);
    } else {
      for (int zi = 0; zi < zones.size(); zi++) {
        pruneZoneUnderwater(zones.get(zi), sea);
      }
    }
    renderer.invalidateBiomeOutlineCache();
    snapDirty = true;
  }

  void enforceZoneExclusivity(int zoneIdx) {
    if (zones == null || zones.isEmpty()) return;
    if (zoneIdx >= 0 && zoneIdx < zones.size()) {
      MapZone target = zones.get(zoneIdx);
      HashSet<Integer> reserved = new HashSet<Integer>();
      if (target != null && target.cells != null) {
        reserved.addAll(target.cells);
      }
      for (int zi = 0; zi < zones.size(); zi++) {
        if (zi == zoneIdx) continue;
        MapZone other = zones.get(zi);
        if (other == null || other.cells == null) continue;
        ArrayList<Integer> filtered = new ArrayList<Integer>();
        for (int ci : other.cells) {
          if (!reserved.contains(ci)) filtered.add(ci);
        }
        other.cells.clear();
        other.cells.addAll(filtered);
      }
    } else {
      ArrayList<ArrayList<Integer>> cellZones = mapCellsToZones();
      int zoneCount = zones.size();
      if (cellZones.isEmpty() || zoneCount == 0) return;
      int[] counts = new int[zoneCount];
      ArrayList<ArrayList<Integer>> newZoneCells = new ArrayList<ArrayList<Integer>>();
      for (int zi = 0; zi < zoneCount; zi++) {
        newZoneCells.add(new ArrayList<Integer>());
      }
      for (int ci = 0; ci < cellZones.size(); ci++) {
        ArrayList<Integer> owners = cellZones.get(ci);
        if (owners == null || owners.isEmpty()) continue;
        int assign = -1;
        for (int owner : owners) {
          if (owner < 0 || owner >= zoneCount) continue;
          if (assign < 0 || counts[owner] < counts[assign]) {
            assign = owner;
          }
        }
        if (assign < 0) continue;
        newZoneCells.get(assign).add(ci);
        counts[assign]++;
      }
      for (int zi = 0; zi < zoneCount; zi++) {
        MapZone z = zones.get(zi);
        if (z == null) continue;
        z.cells.clear();
        z.cells.addAll(newZoneCells.get(zi));
      }
    }
    renderer.invalidateBiomeOutlineCache();
    snapDirty = true;
  }

  void recolorZonesWithFourColors() {
    if (zones == null || zones.isEmpty()) return;
    ensureCellNeighborsComputed();
    int zoneCount = zones.size();
    int[] palette = {
      color(200, 65, 65),
      color(75, 160, 90),
      color(85, 95, 190),
      color(215, 180, 80)
    };
    ArrayList<ArrayList<Integer>> cellZones = mapCellsToZones();
    final ArrayList<HashSet<Integer>> adjacency = new ArrayList<HashSet<Integer>>();
    for (int zi = 0; zi < zoneCount; zi++) {
      adjacency.add(new HashSet<Integer>());
    }
    int n = cellZones.size();
    for (int ci = 0; ci < n; ci++) {
      ArrayList<Integer> owners = cellZones.get(ci);
      if (owners == null || owners.isEmpty()) continue;
      int ownerCount = owners.size();
      for (int aIdx = 0; aIdx < ownerCount; aIdx++) {
        int a = owners.get(aIdx);
        if (a < 0 || a >= zoneCount) continue;
        for (int bIdx = aIdx + 1; bIdx < ownerCount; bIdx++) {
          int b = owners.get(bIdx);
          if (b < 0 || b >= zoneCount) continue;
          adjacency.get(a).add(b);
          adjacency.get(b).add(a);
        }
      }
      ArrayList<Integer> neighbors = (ci < cellNeighbors.size()) ? cellNeighbors.get(ci) : null;
      if (neighbors == null) continue;
      for (int nb : neighbors) {
        if (nb < 0 || nb >= cellZones.size()) continue;
        ArrayList<Integer> nbOwners = cellZones.get(nb);
        if (nbOwners == null || nbOwners.isEmpty()) continue;
        for (int a : owners) {
          if (a < 0 || a >= zoneCount) continue;
          for (int b : nbOwners) {
            if (b < 0 || b >= zoneCount || b == a) continue;
            adjacency.get(a).add(b);
            adjacency.get(b).add(a);
          }
        }
      }
    }
    int[] assignment = new int[zoneCount];
    Arrays.fill(assignment, -1);
    ArrayList<Integer> order = new ArrayList<Integer>();
    for (int zi = 0; zi < zoneCount; zi++) order.add(zi);
    Collections.sort(order, new Comparator<Integer>() {
      public int compare(Integer a, Integer b) {
        return Integer.compare(adjacency.get(b).size(), adjacency.get(a).size());
      }
    });
    for (int idx : order) {
      boolean[] used = new boolean[palette.length];
      for (int neighbor : adjacency.get(idx)) {
        if (neighbor >= 0 && neighbor < zoneCount && assignment[neighbor] >= 0) {
          int usedIdx = assignment[neighbor];
          if (usedIdx >= 0 && usedIdx < palette.length) {
            used[usedIdx] = true;
          }
        }
      }
      int pick = 0;
      for (int c = 0; c < palette.length; c++) {
        if (!used[c]) {
          pick = c;
          break;
        }
      }
      assignment[idx] = pick;
      MapZone z = zones.get(idx);
      if (z == null) continue;
      int col = palette[pick];
      float[] hsb = rgbToHSB(col);
      z.hue01 = hsb[0];
      z.sat01 = hsb[1];
      z.bri01 = hsb[2];
      z.col = col;
    }
    renderer.invalidateBiomeOutlineCache();
    snapDirty = true;
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
    if (presetIndex < 0) return null;
    int idx = min(presetIndex, PATH_TYPE_PRESETS.length - 1);
    PathTypePreset p = PATH_TYPE_PRESETS[idx];
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
    generateZonesFromSeeds(-1);
  }

  void generateZonesFromSeeds(int seedCountOverride) {
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
    int seedCount;
    if (seedCountOverride > 0) {
      seedCount = min(seedCountOverride, noneIndices.size());
    } else {
      float avgBiomeSubzoneSize = random(10.0,200.0);
      seedCount = floor(noneIndices.size()/avgBiomeSubzoneSize);
    }
    seedCount = max(1, min(seedCount, noneIndices.size()));
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
    float waterPenalty = 20.0f;
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
    renderer.invalidateBiomeOutlineCache();
    snapDirty = true;
  }

  void setAllBiomesTo(int biomeId) {
    if (cells == null || cells.isEmpty()) return;
    int bid = max(0, min(biomeId, biomeTypes.size() - 1));
    for (Cell c : cells) {
      c.biomeId = bid;
    }
    renderer.invalidateBiomeOutlineCache();
    snapDirty = true;
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

  void fillUnderThreshold(int biomeId, float threshold) {
    if (cells == null || cells.isEmpty()) return;
    for (Cell c : cells) {
      if (c.elevation < threshold) c.biomeId = biomeId;
    }
    renderer.invalidateBiomeOutlineCache();
    snapDirty = true;
  }

  void fillAboveThreshold(int biomeId, float threshold) {
    if (cells == null || cells.isEmpty()) return;
    for (Cell c : cells) {
      if (c.elevation > threshold) c.biomeId = biomeId;
    }
    renderer.invalidateBiomeOutlineCache();
    snapDirty = true;
  }

  void fillGapsFromExistingBiomes() {
    if (cells == null || cells.isEmpty()) return;
    ensureCellNeighborsComputed();
    int n = cells.size();
    int[] biomeForCell = new int[n];
    Arrays.fill(biomeForCell, -1);
    ArrayDeque<Integer> q = new ArrayDeque<Integer>();
    int seeds = 0;
    for (int i = 0; i < n; i++) {
      Cell c = cells.get(i);
      if (c.biomeId > 0) {
        biomeForCell[i] = c.biomeId;
        q.add(i);
        seeds++;
      }
    }
    if (seeds == 0) {
      generateZonesFromSeeds();
      return;
    }
    while (!q.isEmpty()) {
      int idx = q.poll();
      int bid = biomeForCell[idx];
      ArrayList<Integer> nbs = (idx < cellNeighbors.size()) ? cellNeighbors.get(idx) : null;
      if (nbs == null) continue;
      for (int nb : nbs) {
        if (nb < 0 || nb >= n) continue;
        if (biomeForCell[nb] == -1) {
          biomeForCell[nb] = bid;
          q.add(nb);
        }
      }
    }
    for (int i = 0; i < n; i++) {
      if (biomeForCell[i] > 0) cells.get(i).biomeId = biomeForCell[i];
    }
    renderer.invalidateBiomeOutlineCache();
    snapDirty = true;
  }

  void fillGapsWithNewBiomes(float avgSize) {
    fillGapsWithNewBiomesInternal(-1, avgSize);
  }

  void fillGapsWithNewBiomesByCount(int seedCount) {
    fillGapsWithNewBiomesInternal(max(1, seedCount), -1);
  }

  void fillGapsWithNewBiomesInternal(int desiredSeedCount, float avgSize) {
    if (cells == null || cells.isEmpty()) return;
    ensureCellNeighborsComputed();
    int n = cells.size();
    int typeCount = biomeTypes.size() - 1; // exclude None
    if (typeCount <= 0) return;

    ArrayList<Integer> gaps = new ArrayList<Integer>();
    for (int i = 0; i < n; i++) {
      Cell c = cells.get(i);
      if (c != null && c.biomeId == 0) {
        gaps.add(i);
      }
    }
    if (gaps.isEmpty()) return;

    Collections.shuffle(gaps);
    int[] assign = new int[n];
    Arrays.fill(assign, -1);
    ArrayDeque<Integer> q = new ArrayDeque<Integer>();

    int seedCount;
    if (desiredSeedCount > 0) {
      seedCount = min(desiredSeedCount, gaps.size());
    } else {
      seedCount = max(1, min(gaps.size(), round(gaps.size() / avgSize)));
    }
    for (int i = 0; i < seedCount; i++) {
      int idx = gaps.get(i);
      int bid = 1 + (int)random(typeCount);
      assign[idx] = bid;
      q.add(idx);
    }

    while (!q.isEmpty()) {
      int idx = q.poll();
      ArrayList<Integer> nbs = (idx < cellNeighbors.size()) ? cellNeighbors.get(idx) : null;
      if (nbs == null) continue;
      for (int nb : nbs) {
        if (nb < 0 || nb >= n) continue;
        if (assign[nb] != -1) continue;
        Cell nc = cells.get(nb);
        if (nc == null || nc.biomeId != 0) continue; // only fill previous gaps
        assign[nb] = assign[idx];
        q.add(nb);
      }
    }

    for (int i = 0; i < n; i++) {
      if (assign[i] >= 0) {
        cells.get(i).biomeId = assign[i];
      }
    }
    renderer.invalidateBiomeOutlineCache();
    snapDirty = true;
  }

  void extendBiomeOnce(int biomeId) {
    if (cells == null || cells.isEmpty()) return;
    ensureCellNeighborsComputed();
    int bid = max(0, min(biomeId, biomeTypes.size() - 1));
    HashSet<Integer> toPaint = new HashSet<Integer>();
    int n = cells.size();
    for (int i = 0; i < n; i++) {
      Cell c = cells.get(i);
      if (c == null || c.biomeId != bid) continue;
      ArrayList<Integer> nbs = cellNeighbors.get(i);
      if (nbs == null) continue;
      for (int nb : nbs) {
        if (nb < 0 || nb >= n) continue;
        Cell nc = cells.get(nb);
        if (nc == null) continue;
        if (nc.biomeId != bid) toPaint.add(nb);
      }
    }
    for (int idx : toPaint) {
      cells.get(idx).biomeId = bid;
    }
    renderer.invalidateBiomeOutlineCache();
    snapDirty = true;
  }

  void shrinkBiomeOnce(int biomeId) {
    if (cells == null || cells.isEmpty()) return;
    ensureCellNeighborsComputed();
    int bid = max(0, min(biomeId, biomeTypes.size() - 1));
    int n = cells.size();
    int[] newBiome = new int[n];
    for (int i = 0; i < n; i++) newBiome[i] = cells.get(i).biomeId;
    for (int i = 0; i < n; i++) {
      Cell c = cells.get(i);
      if (c == null || c.biomeId != bid) continue;
      ArrayList<Integer> nbs = cellNeighbors.get(i);
      if (nbs == null) continue;
      int boundary = 0;
      for (int nb : nbs) {
        if (nb < 0 || nb >= n) continue;
        Cell nc = cells.get(nb);
        if (nc == null) continue;
        if (nc.biomeId != bid) boundary++;
      }
      if (boundary > 0) {
        int bestBiome = 0;
        float bestDiff = Float.MAX_VALUE;
        for (int nb : nbs) {
          if (nb < 0 || nb >= n) continue;
          Cell nc = cells.get(nb);
          if (nc == null || nc.biomeId == bid) continue;
          float diff = abs(nc.elevation - c.elevation);
          if (diff < bestDiff) {
            bestDiff = diff;
            bestBiome = nc.biomeId;
          }
        }
        if (bestBiome != bid && bestBiome >= 0) {
          newBiome[i] = bestBiome;
        }
      }
    }
    for (int i = 0; i < n; i++) cells.get(i).biomeId = newBiome[i];
    renderer.invalidateBiomeOutlineCache();
    snapDirty = true;
  }

  boolean placeBiomeSpotOnce(int biomeId, float value01) {
    if (cells == null || cells.isEmpty()) return false;
    ensureCellNeighborsComputed();
    int n = cells.size();
    boolean[] visited = new boolean[n];
    float total = 0;
    int regions = 0;
    for (int i = 0; i < n; i++) {
      if (visited[i]) continue;
      Cell c = cells.get(i);
      if (c == null || c.biomeId <= 0) continue;
      int size = floodCountBiome(i, visited);
      if (size > 0) {
        total += size;
        regions++;
      }
    }
    float avg = (regions > 0) ? (total / regions) : 1.0f;
    int targetSize = max(1, round(avg * value01 * 2.0f));
    int startIdx = (int)random(n);
    int tries = 0;
    while (tries < 200 && (startIdx < 0 || startIdx >= n || cells.get(startIdx) == null || cells.get(startIdx).biomeId == biomeId)) {
      startIdx = (int)random(n);
      tries++;
    }
    if (startIdx < 0 || startIdx >= n) return false;
    ArrayDeque<Integer> q = new ArrayDeque<Integer>();
    HashSet<Integer> claimed = new HashSet<Integer>();
    q.add(startIdx);
    claimed.add(startIdx);
    while (!q.isEmpty() && claimed.size() < targetSize) {
      int idx = q.poll();
      ArrayList<Integer> nbs = (idx < cellNeighbors.size()) ? cellNeighbors.get(idx) : null;
      if (nbs == null) continue;
      Collections.shuffle(nbs);
      for (int nb : nbs) {
        if (nb < 0 || nb >= n) continue;
        if (claimed.contains(nb)) continue;
        claimed.add(nb);
        q.add(nb);
        if (claimed.size() >= targetSize) break;
      }
    }
    boolean changed = false;
    for (int idx : claimed) {
      Cell c = cells.get(idx);
      if (c != null && c.biomeId != biomeId) {
        c.biomeId = biomeId;
        changed = true;
      }
    }
    return changed;
  }

  void placeBiomeSpots(int biomeId, float value01) {
    boolean changed = placeBiomeSpotOnce(biomeId, value01);
    if (changed) {
      renderer.invalidateBiomeOutlineCache();
      snapDirty = true;
    }
  }

  void placeBiomeSpots(int biomeId, int spotCount, float size01) {
    int count = max(1, spotCount);
    boolean changedAny = false;
    for (int i = 0; i < count; i++) {
      if (placeBiomeSpotOnce(biomeId, size01)) changedAny = true;
    }
    if (changedAny) {
      renderer.invalidateBiomeOutlineCache();
      snapDirty = true;
    }
  }

  int floodCountBiome(int startIdx, boolean[] visited) {
    int n = cells.size();
    if (startIdx < 0 || startIdx >= n) return 0;
    int bid = cells.get(startIdx).biomeId;
    ArrayDeque<Integer> q = new ArrayDeque<Integer>();
    q.add(startIdx);
    visited[startIdx] = true;
    int count = 0;
    while (!q.isEmpty()) {
      int idx = q.poll();
      Cell c = cells.get(idx);
      if (c == null || c.biomeId != bid) continue;
      count++;
      ArrayList<Integer> nbs = cellNeighbors.get(idx);
      if (nbs == null) continue;
      for (int nb : nbs) {
        if (nb < 0 || nb >= n) continue;
        if (visited[nb]) continue;
        if (cells.get(nb) == null || cells.get(nb).biomeId != bid) continue;
        visited[nb] = true;
        q.add(nb);
      }
    }
    return count;
  }

  void varyBiomesOnce() {
    if (cells == null || cells.isEmpty()) return;
    ensureCellNeighborsComputed();
    int n = cells.size();
    int[] newBiome = new int[n];
    for (int i = 0; i < n; i++) newBiome[i] = cells.get(i).biomeId;
    for (int i = 0; i < n; i++) {
      if (random(1.0f) < 0.1f) continue; // leave some cells unchanged to break oscillations
      ArrayList<Integer> nbs = cellNeighbors.get(i);
      if (nbs == null || nbs.isEmpty()) continue;
      int[] counts = new int[biomeTypes.size()];
      for (int nb : nbs) {
        if (nb < 0 || nb >= n) continue;
        Cell nc = cells.get(nb);
        if (nc == null) continue;
        int bid = max(0, min(nc.biomeId, biomeTypes.size() - 1));
        counts[bid]++;
      }
      // Pick the most common neighbor, break ties randomly, add slight jitter to avoid cycles
      float bestScore = -1;
      int best = cells.get(i).biomeId;
      for (int b = 0; b < counts.length; b++) {
        float score = counts[b] + random(0.0f, 0.25f);
        if (score > bestScore) {
          bestScore = score;
          best = b;
        }
      }
      // Occasionally pick a random neighbor biome to keep variation alive
      if (!nbs.isEmpty() && random(1.0f) < 0.2f) {
        int nb = nbs.get((int)random(nbs.size()));
        if (nb >= 0 && nb < n && cells.get(nb) != null) {
          best = max(0, min(cells.get(nb).biomeId, biomeTypes.size() - 1));
        }
      }
      newBiome[i] = best;
    }
    for (int i = 0; i < n; i++) cells.get(i).biomeId = newBiome[i];
    renderer.invalidateBiomeOutlineCache();
    snapDirty = true;
  }

  void placeSliceSpot(int biomeId, float sizeParam, float level) {
    if (cells == null || cells.isEmpty()) return;
    ensureCellNeighborsComputed();
    int n = cells.size();
    int seedIdx = -1;
    int fallbackIdx = -1;
    float bestDiff = Float.MAX_VALUE;
    float bestAnyDiff = Float.MAX_VALUE;
    for (int i = 0; i < n; i++) {
      Cell c = cells.get(i);
      if (c == null) continue;
      float diff = abs(c.elevation - level);
      if (c.biomeId != biomeId) {
        if (diff < bestDiff) {
          bestDiff = diff;
          seedIdx = i;
        }
      }
      if (diff < bestAnyDiff) {
        bestAnyDiff = diff;
        fallbackIdx = i;
      }
    }
    if (seedIdx < 0) seedIdx = fallbackIdx;
    if (seedIdx < 0) return;

    // Map slider (0..1) to 1..100 target cells
    int targetCount = max(1, min(100, 1 + round(sizeParam * 99.0f)));
    HashSet<Integer> claimed = new HashSet<Integer>();
    PriorityQueue<Integer> frontier = new PriorityQueue<Integer>(new Comparator<Integer>() {
      public int compare(Integer a, Integer b) {
        float da = abs(cells.get(a).elevation - level);
        float db = abs(cells.get(b).elevation - level);
        return Float.compare(da, db);
      }
    });

    claimed.add(seedIdx);
    frontier.add(seedIdx);

    while (!frontier.isEmpty() && claimed.size() < targetCount) {
      int idx = frontier.poll();
      ArrayList<Integer> nbs = (idx < cellNeighbors.size()) ? cellNeighbors.get(idx) : null;
      if (nbs == null) continue;
      for (int nb : nbs) {
        if (nb < 0 || nb >= n) continue;
        if (claimed.contains(nb)) continue;
        Cell nc = cells.get(nb);
        if (nc == null) continue;
        claimed.add(nb);
        frontier.add(nb);
        if (claimed.size() >= targetCount) break;
      }
    }

    for (int idx : claimed) {
      Cell c = cells.get(idx);
      if (c != null) c.biomeId = biomeId;
    }
    renderer.invalidateBiomeOutlineCache();
    snapDirty = true;
  }

  float sampleGridDistance(ContourGrid g, float x, float y) {
    if (g == null || g.cols < 2 || g.rows < 2) return Float.MAX_VALUE;
    float fx = constrain((x - g.ox) / max(1e-6f, g.dx), 0, g.cols - 1.0001f);
    float fy = constrain((y - g.oy) / max(1e-6f, g.dy), 0, g.rows - 1.0001f);
    int ix = floor(fx);
    int iy = floor(fy);
    float tx = fx - ix;
    float ty = fy - iy;
    float v00 = g.v[iy][ix];
    float v10 = g.v[iy][ix + 1];
    float v01 = g.v[iy + 1][ix];
    float v11 = g.v[iy + 1][ix + 1];
    float v0 = lerp(v00, v10, tx);
    float v1 = lerp(v01, v11, tx);
    float v = lerp(v0, v1, ty);
    return abs(v);
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
    float waterPenalty = 70.0f;

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

  int defaultPatternIndexForBiome(int biomeIdx) {
    if (biomePatternCount <= 0) return 0;
    return ((biomeIdx % biomePatternCount) + biomePatternCount) % biomePatternCount;
  }

  void setBiomePatternFiles(ArrayList<String> files) {
    biomePatternFiles = (files != null) ? new ArrayList<String>(files) : new ArrayList<String>();
    biomePatternCount = max(1, biomePatternFiles.size());
    syncBiomePatternAssignments();
  }

  void syncBiomePatternAssignments() {
    if (biomeTypes == null) return;
    for (int i = 0; i < biomeTypes.size(); i++) {
      ZoneType z = biomeTypes.get(i);
      if (z == null) continue;
      if (z.patternIndex < 0 || z.patternIndex >= biomePatternCount) {
        z.patternIndex = defaultPatternIndexForBiome(i);
      }
    }
  }

  String biomePatternNameForIndex(int patternIdx, String fallback) {
    if (biomePatternFiles == null || biomePatternFiles.isEmpty() || biomePatternCount <= 0) return fallback;
    int idx = ((patternIdx % biomePatternFiles.size()) + biomePatternFiles.size()) % biomePatternFiles.size();
    idx = min(idx, biomePatternFiles.size() - 1);
    String name = biomePatternFiles.get(idx);
    if (name == null || name.length() == 0) return fallback;
    return name;
  }

  boolean biomeNameExists(String name) {
    if (name == null || biomeTypes == null) return false;
    for (ZoneType zt : biomeTypes) {
      if (zt != null && zt.name != null && zt.name.equalsIgnoreCase(name)) return true;
    }
    return false;
  }

  void addBiomeType() {
    int nonNoneCount = max(0, biomeTypes.size() - 1);
    ZonePreset preset = null;
    for (int pi = nonNoneCount; pi < ZONE_PRESETS.length; pi++) {
      ZonePreset cand = ZONE_PRESETS[pi];
      if (cand != null && cand.name != null && !biomeNameExists(cand.name)) {
        preset = cand;
        break;
      }
    }

    if (preset != null) {
      ZoneType z = new ZoneType(preset.name, preset.col);
      z.patternIndex = defaultPatternIndexForBiome(biomeTypes.size());
      biomeTypes.add(z);
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
      ZoneType z = new ZoneType(name, col);
      z.patternIndex = defaultPatternIndexForBiome(biomeTypes.size());
      biomeTypes.add(z);
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

  // ---------- Structure auto-generation ----------
  void generateStructuresAuto(int townCount, float buildingDensity, float sea) {
    if (townCount < 0) townCount = 0;
    buildingDensity = constrain(buildingDensity, 0, 1);
    if (structures == null) structures = new ArrayList<Structure>();

    // Base size heuristic from existing structures
    float baseSize = 0.02f;
    if (!structures.isEmpty()) {
      ArrayList<Float> sizes = new ArrayList<Float>();
      for (Structure s : structures) if (s != null && s.size > 1e-6f) sizes.add(s.size);
    if (!sizes.isEmpty()) {
      Collections.sort(sizes);
      baseSize = sizes.get(sizes.size() / 2);
    }
  }
  float townSize = baseSize * 2.5f;
  float buildingSize = baseSize * (0.4f + 0.5f * (1 - buildingDensity));

    // Collect candidate points for towns
    class Cand {
      PVector p;
      float score;
      Cand(PVector p, float s) { this.p = p; this.score = s; }
    }
    ArrayList<Cand> cands = new ArrayList<Cand>();

    // Zone centroids
    if (zones != null && !zones.isEmpty()) {
      for (MapZone z : zones) {
        if (z == null || z.cells == null || z.cells.isEmpty()) continue;
        float cx = 0, cy = 0; int count = 0;
        for (int ci : z.cells) {
          if (ci < 0 || ci >= cells.size()) continue;
          Cell c = cells.get(ci);
          if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
          PVector cen = cellCentroid(c);
          cx += cen.x; cy += cen.y; count++;
        }
        if (count > 0) {
          cx /= count; cy /= count;
          Cell nearest = nearestCell(cx, cy);
          if (nearest == null || nearest.elevation >= sea) {
            cands.add(new Cand(new PVector(cx, cy), 1.0f));
          }
        }
      }
    }

    // Path junctions (degree >= 3)
    if (paths != null) {
      HashMap<String, Integer> deg = new HashMap<String, Integer>();
      for (Path p : paths) {
        if (p == null || p.routes == null) continue;
        for (ArrayList<PVector> seg : p.routes) {
          if (seg == null || seg.size() < 2) continue;
          for (int i = 0; i < seg.size(); i++) {
            PVector v = seg.get(i);
            String key = keyFor(v.x, v.y);
            deg.put(key, deg.getOrDefault(key, 0) + 1);
          }
        }
      }
      for (Map.Entry<String, Integer> e : deg.entrySet()) {
        if (e.getValue() < 3) continue;
        PVector v = parseKey(e.getKey());
        if (v != null) {
          Cell nearest = nearestCell(v.x, v.y);
          if (nearest == null || nearest.elevation >= sea) {
            cands.add(new Cand(v, 0.8f));
          }
        }
      }
    }

    // Coastline-adjacent land cells
    if (cells != null) {
      ensureCellNeighborsComputed();
      for (int ci = 0; ci < cells.size(); ci++) {
        Cell a = cells.get(ci);
        if (a == null || a.vertices == null) continue;
        if (a.elevation < sea) continue;
        ArrayList<Integer> nbs = (ci < cellNeighbors.size()) ? cellNeighbors.get(ci) : null;
        if (nbs == null) continue;
        boolean coastal = false;
        for (int nb : nbs) {
          if (nb < 0 || nb >= cells.size()) continue;
          Cell b = cells.get(nb);
          if (b != null && b.elevation < sea) { coastal = true; break; }
        }
        if (coastal) {
          PVector cen = cellCentroid(a);
          cands.add(new Cand(cen, 0.6f));
        }
      }
    }

    // Fallback when no interesting spots are found
    if (cands.isEmpty()) {
      if (cells != null && !cells.isEmpty()) {
        for (int i = 0; i < min(8, cells.size()); i++) {
          Cell c = cells.get((i * 997) % cells.size());
          if (c == null || c.vertices == null || c.vertices.isEmpty()) continue;
          PVector cen = cellCentroid(c);
          if (cen == null) continue;
          float score = 0.4f;
          if (c.elevation >= sea) score = 0.8f;
          cands.add(new Cand(cen, score));
        }
      } else {
        cands.add(new Cand(new PVector(0, 0), 0.5f));
      }
    }

    // Prefer low/mid elevation (penalize high)
    float elevMin = sea;
    float elevMax = sea + 0.5f;
    for (Cand c : cands) {
      float e = elevMin;
      Cell nearest = nearestCell(c.p.x, c.p.y);
      if (nearest != null) e = nearest.elevation;
      float elevScore = 1.0f - constrain(map(e, elevMin, elevMax, 0, 1), 0, 1);
      c.score *= 0.4f + 0.6f * elevScore;
    }

    // Sort by score
    Collections.sort(cands, new Comparator<Cand>() {
      public int compare(Cand a, Cand b) { return Float.compare(b.score, a.score); }
    });

    // Place towns
    int placedTowns = 0;
    ArrayList<Structure> newStructs = new ArrayList<Structure>();
    ArrayList<PVector> townCenters = new ArrayList<PVector>();
    for (Cand c : cands) {
      if (placedTowns >= townCount) break;
      if (structuresOverlap(structures, c.p.x, c.p.y, townSize, 1.0f, 1.2f)) continue;
      if (structuresOverlap(newStructs, c.p.x, c.p.y, townSize, 1.0f, 1.2f)) continue;
      // Main circle
      Structure main = new Structure(c.p.x, c.p.y);
      main.shape = StructureShape.CIRCLE;
      main.aspect = 1.0f;
      main.size = townSize;
      main.setColor(color(255), 1.0f);
      main.strokeWeightPx = 1.5f;
      main.alpha01 = 1.0f;
      main.name = "Town " + (placedTowns + 1);
      newStructs.add(main);
      townCenters.add(new PVector(c.p.x, c.p.y));

      int satellites = (int)random(1, 6);
      for (int i = 0; i < satellites; i++) {
        float ang = random(TWO_PI);
        float dist = townSize * random(0.8f, 1.6f);
        float sx = c.p.x + cos(ang) * dist;
        float sy = c.p.y + sin(ang) * dist;
        if (structuresOverlap(structures, sx, sy, townSize * 0.8f, 1.0f, 1.0f)) continue;
        if (structuresOverlap(newStructs, sx, sy, townSize * 0.8f, 1.0f, 1.0f)) continue;
        Structure sat = new Structure(sx, sy);
        sat.shape = StructureShape.CIRCLE;
        sat.aspect = 1.0f;
        sat.size = townSize * random(0.5f, 0.9f);
        sat.setColor(color(255), 1.0f);
        sat.strokeWeightPx = 1.5f;
        sat.alpha01 = 1.0f;
        sat.name = main.name;
        newStructs.add(sat);
      }
      placedTowns++;
    }

    // Buildings along paths
    if (paths != null && buildingDensity > 1e-4f) {
      float spacing = buildingSize * map(1 - buildingDensity, 0, 1, 3.5f, 8.0f);
      for (int pi = 0; pi < paths.size(); pi++) {
        Path p = paths.get(pi);
        if (p == null || p.routes == null) continue;
        for (ArrayList<PVector> route : p.routes) {
          if (route == null || route.size() < 2) continue;
          for (int i = 0; i < route.size() - 1; i++) {
            PVector a = route.get(i);
            PVector b = route.get(i + 1);
            float dx = b.x - a.x;
            float dy = b.y - a.y;
            float segLen = max(1e-6f, sqrt(dx * dx + dy * dy));
            int steps = max(1, (int)floor(segLen / spacing));
            float nx = -dy / segLen;
            float ny = dx / segLen;
            for (int s = 0; s < steps; s++) {
              float t = (s + 0.5f) / steps;
              float px = lerp(a.x, b.x, t);
              float py = lerp(a.y, b.y, t);
              // Require proximity to a town to cluster buildings
              boolean nearTown = townCenters.isEmpty(); // allow some placement if no towns exist
              for (PVector tc : townCenters) {
                float dxt = tc.x - px;
                float dyt = tc.y - py;
                float d2 = dxt * dxt + dyt * dyt;
                if (d2 < sq(townSize * 4.0f)) { nearTown = true; break; }
              }
              if (!nearTown) continue;
              Cell segCell = nearestCell(px, py);
              if (segCell != null && segCell.elevation < sea) continue;
              float offset = buildingSize * random(0.6f, 1.2f);
              float sx = px + nx * offset;
              float sy = py + ny * offset;
              float asp = random(0.8f, 1.4f);
              Cell offCell = nearestCell(sx, sy);
              if (offCell != null && offCell.elevation < sea) continue;
              if (structuresOverlap(structures, sx, sy, buildingSize, asp, 0.9f)) continue;
              if (structuresOverlap(newStructs, sx, sy, buildingSize, asp, 0.9f)) continue;

              StructureAttributes at = new StructureAttributes();
              at.name = "";
              at.size = buildingSize;
              at.shape = StructureShape.RECTANGLE;
              at.aspectRatio = asp;
              at.alignment = StructureSnapMode.NEXT_TO_PATH;
              at.hue01 = 0;
              at.sat01 = 0;
              at.alpha01 = 1.0f;
              at.strokeWeightPx = 1.2f;
              Structure st = computeSnappedStructure(sx, sy, at);
              st.setColor(color(255), 1.0f);
              st.strokeWeightPx = 1.2f;
              st.alpha01 = 1.0f;
              st.aspect = asp;
              st.name = "";
              newStructs.add(st);
            }
          }
        }
      }
    }

    structures.addAll(newStructs);
  }

  // ---------- Arbitrary label auto-generation ----------
  void generateArbitraryLabels(float sea) {
    if (labels == null) labels = new ArrayList<MapLabel>();
    int target = (int)random(1, 11); // 1..10 labels
    float baseSize = labelSizeDefault();
    float worldW = maxX - minX;
    float worldH = maxY - minY;
    float spacing = max(worldW, worldH) * 0.01f;

    class LabelCand {
      PVector p;
      float score;
      boolean land;
      LabelCand(PVector p, float s, boolean land) { this.p = p; this.score = s; this.land = land; }
    }

    ArrayList<LabelCand> cands = new ArrayList<LabelCand>();
    boolean hasLand = false;
    if (cells != null && !cells.isEmpty()) {
      for (Cell c : cells) {
        if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
        PVector cen = cellCentroid(c);
        if (cen == null) continue;
        boolean land = c.elevation >= sea;
        if (land) hasLand = true;
        float elevScore = land ? 1.0f : 0.4f;
        cands.add(new LabelCand(cen, elevScore, land));
      }
    }

    // Fallback candidates if no cells
    if (cands.isEmpty()) {
      cands.add(new LabelCand(new PVector((minX + maxX) * 0.5f, (minY + maxY) * 0.5f), 1.0f, true));
      cands.add(new LabelCand(new PVector(minX + worldW * 0.25f, minY + worldH * 0.25f), 0.6f, true));
      cands.add(new LabelCand(new PVector(minX + worldW * 0.75f, minY + worldH * 0.75f), 0.6f, true));
    }

    Collections.shuffle(cands);
    Collections.sort(cands, new Comparator<LabelCand>() {
      public int compare(LabelCand a, LabelCand b) { return Float.compare(b.score, a.score); }
    });

    ArrayList<MapLabel> newLabels = new ArrayList<MapLabel>();

    for (LabelCand cand : cands) {
      if (newLabels.size() >= target) break;
      if (hasLand && !cand.land) continue; // prefer land when available

      String name = randomLabelName();
      float rad = estimateLabelRadius(name, baseSize) + spacing;
      if (!labelSpotFree(cand.p.x, cand.p.y, rad, labels)) continue;
      if (!labelSpotFree(cand.p.x, cand.p.y, rad, newLabels)) continue;

      MapLabel lbl = new MapLabel(cand.p.x, cand.p.y, name);
      lbl.size = baseSize;
      newLabels.add(lbl);
    }

    // If still nothing, drop a couple in the center area
    int fallbackAttempts = 0;
    while (newLabels.size() < target && newLabels.size() < 3 && fallbackAttempts < 200) {
      fallbackAttempts++;
      float px = random(minX + worldW * 0.25f, maxX - worldW * 0.25f);
      float py = random(minY + worldH * 0.25f, maxY - worldH * 0.25f);
      String name = randomLabelName();
      float rad = estimateLabelRadius(name, baseSize) + spacing;
      if (!labelSpotFree(px, py, rad, labels)) continue;
      if (!labelSpotFree(px, py, rad, newLabels)) continue;
      MapLabel lbl = new MapLabel(px, py, name);
      lbl.size = baseSize;
      newLabels.add(lbl);
    }

    labels.addAll(newLabels);
  }

  String randomLabelName() {
    String[] syll = {
      "an","bar","bel","cal","dun","el","fal","gal","hal","ir","jor","kel","lor","mor","nar","or","per","quil","ran","sar","tor","ur","val","wen","yor","zan","ther","lin","mon","ros","ith","del","mir","tash","glen","fen","sta","ver","dul","kri","sha"
    };
    int parts = 2 + (int)random(0, 2); // 2-3 parts
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < parts; i++) {
      sb.append(syll[(int)random(syll.length)]);
    }
    String raw = sb.toString();
    if (raw.length() == 0) return "Label";
    return raw.substring(0, 1).toUpperCase() + raw.substring(1).toLowerCase();
  }

  float estimateLabelRadius(String txt, float size) {
    if (txt == null || txt.length() == 0) return size;
    float len = txt.length();
    return max(size * 0.6f, size * 0.32f * len);
  }

  boolean labelSpotFree(float x, float y, float radius, ArrayList<MapLabel> list) {
    if (list == null) return true;
    for (MapLabel l : list) {
      if (l == null || l.text == null) continue;
      float otherR = estimateLabelRadius(l.text, l.size);
      float dx = l.x - x;
      float dy = l.y - y;
      float minDist = radius + otherR;
      if (dx * dx + dy * dy < minDist * minDist) return false;
    }
    return true;
  }
}
