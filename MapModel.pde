
import java.util.HashMap;
import java.util.HashSet;
import java.util.ArrayDeque;
import java.util.PriorityQueue;
import java.util.Collections;

class MapModel {
  // World bounds in world coordinates
  float minX = 0.0f;
  float minY = 0.0f;
  float maxX = 1.0f;
  float maxY = 1.0f;

  ArrayList<Site> sites = new ArrayList<Site>();
  ArrayList<Cell> cells = new ArrayList<Cell>();

  // Paths (roads, rivers, etc.)
  ArrayList<Path> paths = new ArrayList<Path>();
  ArrayList<PathType> pathTypes = new ArrayList<PathType>();

  // Biomes / zone types
  ArrayList<ZoneType> biomeTypes = new ArrayList<ZoneType>();

  // Cell adjacency (rebuilt when Voronoi is recomputed)
  ArrayList<ArrayList<Integer>> cellNeighbors = new ArrayList<ArrayList<Integer>>();

  ArrayList<Structure> structures = new ArrayList<Structure>();
  ArrayList<MapLabel> labels = new ArrayList<MapLabel>();

  boolean voronoiDirty = true;
  boolean snapDirty = true;
  ArrayList<Cell> preservedCells = null;

  HashMap<String, PVector> snapNodes = new HashMap<String, PVector>();
  HashMap<String, ArrayList<String>> snapAdj = new HashMap<String, ArrayList<String>>();

  MapModel() {
    // biomeTypes will be filled from Main.initBiomeTypes()
  }

  // ---------- Drawing ----------

  void drawDebugWorldBounds(PApplet app) {
    app.pushStyle();
    app.noFill();
    app.stroke(0);
    app.strokeWeight(1.5f / viewport.zoom);
    app.rect(minX, minY, maxX - minX, maxY - minY);
    app.popStyle();
  }

  void drawSites(PApplet app) {
    for (Site s : sites) {
      s.draw(app);
    }
  }

  void drawCells(PApplet app) {
    drawCells(app, true);
  }

  void drawCells(PApplet app, boolean showBorders) {
    for (Cell c : cells) {
      c.draw(app, showBorders);
    }
  }

  // Rendering-mode cell draw: keep underwater cells plain blue (no biome tint)
  void drawCellsRender(PApplet app, boolean showBorders, float seaLevel) {
    if (cells == null) return;
    app.pushStyle();
    for (Cell c : cells) {
      if (c.vertices == null || c.vertices.size() < 3) continue;
      int col = color(230);
      if (biomeTypes != null && c.biomeId >= 0 && c.biomeId < biomeTypes.size()) {
        ZoneType zt = biomeTypes.get(c.biomeId);
        col = zt.col;
      }

      app.fill(col);
      if (showBorders) {
        app.stroke(180);
        app.strokeWeight(1.0f / viewport.zoom);
      } else {
        app.noStroke();
      }

      app.beginShape();
      for (PVector v : c.vertices) {
        app.vertex(v.x, v.y);
      }
      app.endShape(CLOSE);
    }
    app.popStyle();
  }

  void drawStructures(PApplet app) {
    if (structures == null) return;
    app.pushStyle();
    for (Structure s : structures) {
      s.draw(app);
    }
    app.popStyle();
  }

  void drawLabels(PApplet app) {
    if (labels == null) return;
    app.pushStyle();
    for (MapLabel l : labels) {
      l.draw(app);
    }
    app.popStyle();
  }

  Structure computeSnappedStructure(float wx, float wy, float size) {
    Structure s = new Structure(wx, wy);
    s.size = size;
    float snapRange = max(0.04f, s.size * 2.0f);

    // Snap priority: paths > other structures > land/water frontier
    PVector[] seg = nearestPathSegment(wx, wy, snapRange);
    if (seg != null) {
      PVector a = seg[0];
      PVector b = seg[1];
      PVector p = seg[2];
      float dx = b.x - a.x;
      float dy = b.y - a.y;
      float ang = atan2(dy, dx);
      float nx = -sin(ang);
      float ny = cos(ang);
      float offset = s.size * 0.6f;
      // Flip side based on cursor side of the segment
      float side = (wx - p.x) * nx + (wy - p.y) * ny;
      if (side < 0) offset = -offset;
      s.x = p.x + nx * offset;
      s.y = p.y + ny * offset;
      s.angle = ang;
      return s;
    }

    // Next: snap to other structures
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
      s.x = closest.x;
      s.y = closest.y;
      s.angle = closest.angle;
      return s;
    }

    // Finally: snap to coastline (land/water frontier) by stepping toward seaLevel contour
    Cell c = findCellContaining(wx, wy);
    if (c != null && !c.vertices.isEmpty()) {
      float targetElev = seaLevel;
      float bestEdgeD = Float.MAX_VALUE;
      PVector bestPoint = null;
      int n = c.vertices.size();
      for (int i = 0; i < n; i++) {
        PVector va = c.vertices.get(i);
        PVector vb = c.vertices.get((i + 1) % n);
        PVector proj = closestPointOnSegment(wx, wy, va, vb);
        float d = dist(wx, wy, proj.x, proj.y);
        if (d < bestEdgeD) {
          bestEdgeD = d;
          bestPoint = proj;
        }
      }
      if (bestPoint != null && bestEdgeD <= snapRange) {
        s.x = bestPoint.x;
        s.y = bestPoint.y;
        // Align angle to coastline normal (toward cell centroid)
        PVector cen = cellCentroid(c);
        float nx = cen.x - bestPoint.x;
        float ny = cen.y - bestPoint.y;
        if (nx * nx + ny * ny > 1e-8f) {
          s.angle = atan2(ny, nx);
        }
      }
    }

    return s;
  }

  void drawElevationOverlay(PApplet app, float seaLevel, boolean showContours, boolean drawWater, boolean drawElevation) {
    // Default: no lighting, just grayscale
    drawElevationOverlay(app, seaLevel, showContours, drawWater, drawElevation, false, 135.0f, 45.0f);
  }

  void drawElevationOverlay(PApplet app, float seaLevel, boolean showContours, boolean drawWater, boolean drawElevation,
                            boolean useLighting, float lightAzimuthDeg, float lightAltitudeDeg) {
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
          light = computeLightForCell(ci, lightDir);
        }
        float litShade = constrain(shade * light, 0, 1);
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
        float baseR = 30;
        float baseG = 70;
        float baseB = 120;
        int water = app.color(baseR * shade, baseG * shade, baseB * shade, 255);
        app.fill(water);
        app.beginShape();
        for (PVector v : c.vertices) app.vertex(v.x, v.y);
        app.endShape(CLOSE);
      }
    }

    if (showContours && drawElevation) {
      float step = 0.1f;
      app.stroke(60, 60, 60, 140);
      app.strokeWeight(1.0f / viewport.zoom);
      app.noFill();
      for (Cell c : cells) {
        if (c.vertices == null || c.vertices.size() < 3) continue;
        float band = round(c.elevation / step) * step;
        if (abs(c.elevation - band) < step * 0.35f) {
          app.beginShape();
          for (PVector v : c.vertices) app.vertex(v.x, v.y);
          app.endShape(CLOSE);
        }
      }
    }
    app.popStyle();
  }

  // ---------- Snapping graph ----------

  ArrayList<PVector> getSnapPoints() {
    ensureSnapGraph();
    return new ArrayList<PVector>(snapNodes.values());
  }

  ArrayList<PVector> findSnapPath(PVector from, PVector toP) {
    return findSnapPathWeighted(from, toP, false);
  }

  ArrayList<PVector> findSnapPathFlattest(PVector from, PVector toP) {
    return findSnapPathWeighted(from, toP, true);
  }

  ArrayList<PVector> findSnapPathWeighted(PVector from, PVector toP, boolean favorFlat) {
    ensureSnapGraph();
    String kFrom = keyFor(from.x, from.y);
    String kTo = keyFor(toP.x, toP.y);
    if (!snapNodes.containsKey(kFrom) || !snapNodes.containsKey(kTo)) return null;
    if (kFrom.equals(kTo)) {
      ArrayList<PVector> single = new ArrayList<PVector>();
      single.add(snapNodes.get(kFrom));
      return single;
    }

    HashMap<String, Float> dist = new HashMap<String, Float>();
    HashMap<String, String> prev = new HashMap<String, String>();
    PriorityQueue<NodeDist> pq = new PriorityQueue<NodeDist>();
    dist.put(kFrom, 0.0f);
    pq.add(new NodeDist(kFrom, 0.0f));

    while (!pq.isEmpty()) {
      NodeDist nd = pq.poll();
      Float bestD = dist.get(nd.k);
      if (bestD != null && nd.d > bestD + 1e-6f) continue;
      if (nd.k.equals(kTo)) break;
      ArrayList<String> neighbors = snapAdj.get(nd.k);
      if (neighbors == null) continue;
      PVector p = snapNodes.get(nd.k);
      if (p == null) continue;
      for (String nb : neighbors) {
        PVector np = snapNodes.get(nb);
        if (np == null) continue;
        float w = dist2D(p, np);
        if (pathAvoidWater) {
          float elevA = sampleElevationAt(p.x, p.y, seaLevel);
          float elevB = sampleElevationAt(np.x, np.y, seaLevel);
          boolean aw = elevA < seaLevel;
          boolean bw = elevB < seaLevel;
          if (aw || bw) {
            // Make water extremely undesirable; only used if no land path exists
            w *= 1e6f;
          }
        }
        if (favorFlat) {
          float elevA = sampleElevationAt(p.x, p.y, from.z);
          float elevB = sampleElevationAt(np.x, np.y, toP.z);
          float dh = abs(elevB - elevA);
          // Penalize steep changes; keep distance as base
          w *= (1.0f + dh * flattestSlopeBias);
        }
        float ndist = nd.d + w;
        Float curD = dist.get(nb);
        if (curD == null || ndist < curD - 1e-6f) {
          dist.put(nb, ndist);
          prev.put(nb, nd.k);
          pq.add(new NodeDist(nb, ndist));
        }
      }
    }

    if (!prev.containsKey(kTo) && !kFrom.equals(kTo)) {
      return null;
    }
    return reconstructPath(prev, kFrom, kTo);
  }

  void ensureSnapGraph() {
    if (!snapDirty) return;
    recomputeSnappingGraph();
    snapDirty = false;
  }

  void recomputeSnappingGraph() {
    snapNodes.clear();
    snapAdj.clear();
    if (sites == null || cells == null) return;

    float eps = 1e-4f;
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

    // Connect neighboring centers (cells sharing edge)
    int cCount = cells.size();
    for (int i = 0; i < cCount; i++) {
      Cell a = cells.get(i);
      for (int j = i + 1; j < cCount; j++) {
        Cell b = cells.get(j);
        if (cellsAreNeighbors(a, b, eps)) {
          if (a.siteIndex >= 0 && a.siteIndex < centerKeys.length &&
              b.siteIndex >= 0 && b.siteIndex < centerKeys.length) {
            connectNodes(centerKeys[a.siteIndex], centerKeys[b.siteIndex]);
          }
        }
      }
    }
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
    float d;
    NodeDist(String k, float d) { this.k = k; this.d = d; }
    public int compareTo(NodeDist other) {
      return Float.compare(this.d, other.d);
    }
  }

  void drawPaths(PApplet app, int strokeCol, boolean highlightSelected) {
    if (paths.isEmpty()) return;

    app.pushStyle();
    app.noFill();

    for (int i = 0; i < paths.size(); i++) {
      Path p = paths.get(i);
      PathType pt = getPathType(p.typeId);
      int col = (pt != null) ? pt.col : strokeCol;
      float w = (pt != null) ? pt.weightPx : 2.0f;
      app.stroke(col);
      app.strokeWeight(max(0.5f, w) / viewport.zoom);
      p.draw(app);
    }

    // Selected path highlight
    if (highlightSelected && selectedPathIndex >= 0 && selectedPathIndex < paths.size()) {
      Path sel = paths.get(selectedPathIndex);
      PathType pt = getPathType(sel.typeId);
      int col = (pt != null) ? pt.col : strokeCol;
      int hi = app.color(255, 230, 80, 180);
      float w = (pt != null) ? pt.weightPx : 2.0f;
      float hw = 5.0f / viewport.zoom; // constant ~5px
      app.stroke(hi);
      app.strokeWeight(hw);
      sel.draw(app);
    }

    app.popStyle();
  }

  // ---------- Paths management ----------

  void addFinishedPath(Path p) {
    if (p == null) return;
    if (p.segments.isEmpty()) return; // ignore degenerate paths
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

  void appendSegmentToPath(Path p, ArrayList<PVector> pts) {
    if (p == null || pts == null || pts.size() < 2) return;
    p.addSegment(pts);
  }

  void removePathsNear(float wx, float wy, float radius) {
    if (paths == null) return;
    float r2 = radius * radius;
    for (int i = paths.size() - 1; i >= 0; i--) {
      Path p = paths.get(i);
      boolean hit = false;
      for (ArrayList<PVector> seg : p.segments) {
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

  PVector[] nearestPathSegment(float wx, float wy, float maxDist) {
    if (paths == null || paths.isEmpty()) return null;
    float best = maxDist;
    PVector bestA = null, bestB = null, bestP = null;
    for (Path p : paths) {
      for (ArrayList<PVector> seg : p.segments) {
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
  }

  void ensureVoronoiComputed() {
    if (voronoiDirty) {
      recomputeVoronoi();
      voronoiDirty = false;
      snapDirty = true;
    }
  }

  void recomputeVoronoi() {
    int n = sites.size();
    if (n == 0) {
      cells.clear();
      preservedCells = null;
      return;
    }

    ArrayList<Cell> oldCells = (preservedCells != null) ? preservedCells : new ArrayList<Cell>(cells);
    cells.clear();
    cellNeighbors.clear();
    preservedCells = null;

    int defaultBiome = 0;
    float defaultElev = defaultElevation;

    // For each site, start with the world bounding box and clip by bisectors
    for (int i = 0; i < n; i++) {
      Site si = sites.get(i);

      ArrayList<PVector> poly = new ArrayList<PVector>();
      poly.add(new PVector(minX, minY));
      poly.add(new PVector(maxX, minY));
      poly.add(new PVector(maxX, maxY));
      poly.add(new PVector(minX, maxY));

      for (int j = 0; j < n; j++) {
        if (i == j) continue;
        Site sj = sites.get(j);
        poly = clipPolygonWithHalfPlane(poly, si, sj);
        if (poly.size() < 3) {
          break;
        }
      }

      if (poly.size() >= 3) {
        // Compute centroid of the new polygon
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

        int biomeId = oldCells.isEmpty() ? defaultBiome : sampleBiomeFromOldCells(oldCells, cx, cy, defaultBiome);
        float elev = oldCells.isEmpty() ? defaultElev : sampleElevationFromOldCells(oldCells, cx, cy, defaultElev);

        Cell newCell = new Cell(i, poly, biomeId);
        newCell.elevation = elev;
        cells.add(newCell);
      }
    }

    rebuildCellNeighbors();
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

  float sampleElevationFromOldCells(ArrayList<Cell> oldCells, float x, float y, float fallback) {
    for (Cell c : oldCells) {
      if (pointInPolygon(x, y, c.vertices)) {
        return c.elevation;
      }
    }
    return fallback;
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

    stack[stackSize++] = startIndex;
    visited[startIndex] = true;

    float eps = 1e-4f;

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
    float eps = 1e-4f;
    for (int i = 0; i < n; i++) {
      Cell a = cells.get(i);
      for (int j = i + 1; j < n; j++) {
        Cell b = cells.get(j);
        if (cellsAreNeighbors(a, b, eps)) {
          cellNeighbors.get(i).add(j);
          cellNeighbors.get(j).add(i);
        }
      }
    }
  }

  float computeLightForCell(int idx, PVector lightDir) {
    if (idx < 0 || idx >= cells.size()) return 1.0f;
    ArrayList<Integer> nbs = (idx < cellNeighbors.size()) ? cellNeighbors.get(idx) : null;
    if (nbs == null || nbs.isEmpty()) return 1.0f;

    Cell c = cells.get(idx);
    PVector cen = cellCentroid(c);

    float gx = 0;
    float gy = 0;
    for (int nbIdx : nbs) {
      if (nbIdx < 0 || nbIdx >= cells.size()) continue;
      Cell nb = cells.get(nbIdx);
      PVector ncen = cellCentroid(nb);
      float dx = ncen.x - cen.x;
      float dy = ncen.y - cen.y;
      float dist = sqrt(dx * dx + dy * dy);
      if (dist < 1e-6f) continue;
      float dh = nb.elevation - c.elevation;
      float w = 1.0f / dist;
      gx += dh * (dx / dist) * w;
      gy += dh * (dy / dist) * w;
    }

    PVector normal = new PVector(-gx, -gy, 1.0f);
    if (normal.magSq() < 1e-8f) normal.set(0, 0, 1);
    else normal.normalize();

    float d = max(0, normal.x * lightDir.x + normal.y * lightDir.y + normal.z * lightDir.z);
    float ambient = 0.35f;
    return constrain(ambient + (1.0f - ambient) * d, 0, 1);
  }

  // ---------- Sites generation ----------

  void generateSites(PlacementMode mode, float density) {
    generateSites(mode, density, false);
  }

  void generateSites(PlacementMode mode, float density, boolean preserveCellData) {
    density = constrain(density, 0, 2); // density slider maps to 0..2 with 1.0 at midpoint
    preservedCells = preserveCellData ? new ArrayList<Cell>(cells) : null;
    if (!preserveCellData) {
      cells.clear(); // drop old cells so properties are not inherited
    }
    sites.clear();

    if (mode == PlacementMode.GRID) {
      generateGridSites(density);
    } else if (mode == PlacementMode.HEX) {
      generateHexSites(density);
    } else if (mode == PlacementMode.POISSON) {
      generatePoissonSites(density);
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
    normalizeElevationsIfOutOfBounds(seaLevel, preMin, preMax);
  }

  PathType getPathType(int idx) {
    if (pathTypes == null) return null;
    if (idx < 0 || idx >= pathTypes.size()) return null;
    return pathTypes.get(idx);
  }

  PathType makePathTypeFromPreset(int presetIndex) {
    if (presetIndex < 0 || presetIndex >= PATH_TYPE_PRESETS.length) return null;
    PathTypePreset p = PATH_TYPE_PRESETS[presetIndex];
    return new PathType(p.name, p.col, p.weightPx);
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
    normalizeElevationsIfOutOfBounds(seaLevel, preMin, preMax);
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
    normalizeElevationsIfOutOfBounds(seaLevel, preMin, preMax);
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

  void normalizeElevationsIfOutOfBounds(float seaLevel, float oldMin, float oldMax) {
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
    ArrayDeque<Integer> queue = new ArrayDeque<Integer>();
    ArrayList<Integer> noneIndices = new ArrayList<Integer>();

    // Existing zones become seeds for their own type
    for (int i = 0; i < n; i++) {
      Cell c = cells.get(i);
      if (c.biomeId > 0) {
        queue.add(i);
      } else {
        noneIndices.add(i);
      }
    }

    if (noneIndices.isEmpty()) return;

    // Add random seeds inside "None" cells to diversify coverage
    Collections.shuffle(noneIndices);
    int seedCount = min(typeCount, noneIndices.size());
    for (int i = 0; i < seedCount; i++) {
      int idx = noneIndices.get(i);
      Cell c = cells.get(idx);
      int biomeId = 1 + (int)random(typeCount);
      c.biomeId = biomeId;
      queue.add(idx);
    }

    // Multi-source BFS to propagate seeds into remaining None cells
    while (!queue.isEmpty()) {
      int idx = queue.removeFirst();
      if (idx < 0 || idx >= n) continue;
      Cell c = cells.get(idx);
      int biomeId = c.biomeId;
      ArrayList<Integer> nbs = (idx < cellNeighbors.size()) ? cellNeighbors.get(idx) : null;
      if (nbs == null) continue;
      for (int nb : nbs) {
        if (nb < 0 || nb >= n) continue;
        Cell nc = cells.get(nb);
        if (nc.biomeId == 0) {
          nc.biomeId = biomeId;
          queue.add(nb);
        }
      }
    }
  }

  void resetAllBiomesToNone() {
    if (cells == null || cells.isEmpty()) return;
    for (Cell c : cells) {
      c.biomeId = 0;
    }
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

  void generateGridSites(float density) {
    int minRes = 2;
    int maxRes = 60; // capped for speed

    int res = (int)map(density, 0, 2, minRes, maxRes);
    res = max(2, res);

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

  void generateHexSites(float density) {
    int minRes = 2;
    int maxRes = 80; // capped for speed

    int res = (int)map(density, 0, 2, minRes, maxRes);
    res = max(2, res);

    float w = maxX - minX;
    float h = maxY - minY;

    int cols = res;
    float dx = w / (cols - 1);

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

  void generatePoissonSites(float density) {
    float w = maxX - minX;
    float h = maxY - minY;

    float minDim = min(w, h);
    float targetRes = map(density, 0, 2, 1, 60); // cap to keep Voronoi faster
    float baseSpacing = minDim / targetRes;
    float r = baseSpacing * 0.5f;

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

    int k = 25;
    int maxPoints = 10000;

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
  }
}

// ---------- ZoneType ----------

class ZoneType {
  String name;
  int col;
  float hue01;
  float sat01;
  float bri01;

  ZoneType(String name, int col) {
    this.name = name;
    setFromColor(col);
  }

  void setFromColor(int c) {
    col = c;
    float[] hsb = new float[3];
    rgbToHSB01(c, hsb);
    hue01 = hsb[0];
    sat01 = hsb[1];
    bri01 = hsb[2];
  }

  void updateColorFromHSB() {
    col = hsb01ToRGB(hue01, sat01, bri01);
  }
}

class ZonePreset {
  String name;
  int col;
  ZonePreset(String name, int col) {
    this.name = name;
    this.col = col;
  }
}

ZonePreset[] ZONE_PRESETS = new ZonePreset[] {
  new ZonePreset("Dirt",        color(210, 180, 140)),
  new ZonePreset("Sand",        color(230, 214, 160)),
  new ZonePreset("Grassland",   color(186, 206, 140)),
  new ZonePreset("Forest",      color(110, 150, 95)),
  new ZonePreset("Rock",        color(150, 150, 150)),
  new ZonePreset("Snow",        color(235, 240, 245)),
  new ZonePreset("Wetland",     color(165, 190, 155)),
  new ZonePreset("Shrubland",   color(195, 205, 170)),
  new ZonePreset("Clay Flats",  color(198, 176, 156)),
  new ZonePreset("Savannah",    color(215, 196, 128)),
  new ZonePreset("Tundra",      color(190, 200, 205)),
  new ZonePreset("Jungle",      color(80, 130, 85)),
  new ZonePreset("Volcanic",    color(105, 95, 90)),
  new ZonePreset("Magma",       color(190, 70, 40)),
  new ZonePreset("Heath",       color(180, 160, 145)),
  new ZonePreset("Steppe",      color(190, 185, 140)),
  new ZonePreset("Delta",       color(170, 200, 175)),
  new ZonePreset("Glacier",     color(220, 230, 240)),
  new ZonePreset("Mesa",        color(205, 165, 120)),
  new ZonePreset("Moor",        color(165, 155, 145)),
  new ZonePreset("Scrub",       color(185, 175, 150))
};

// ---------- Path types ----------
class PathType {
  String name;
  int col;
  float hue01;
  float sat01;
  float bri01;
  float weightPx;

  PathType(String name, int col, float weightPx) {
    this.name = name;
    this.weightPx = weightPx;
    setFromColor(col);
  }

  void setFromColor(int c) {
    col = c;
    float[] hsb = new float[3];
    rgbToHSB01(c, hsb);
    hue01 = hsb[0];
    sat01 = hsb[1];
    bri01 = hsb[2];
  }

  void updateColorFromHSB() {
    col = hsb01ToRGB(hue01, sat01, bri01);
  }
}

class PathTypePreset {
  String name;
  int col;
  float weightPx;
  PathTypePreset(String name, int col, float weightPx) {
    this.name = name;
    this.col = col;
    this.weightPx = weightPx;
  }
}

PathTypePreset[] PATH_TYPE_PRESETS = new PathTypePreset[] {
  new PathTypePreset("Road",   color(80, 80, 80),   3.0f),
  new PathTypePreset("Street", color(110, 110, 110), 2.0f),
  new PathTypePreset("River",  color(60, 90, 180),  3.0f),
  new PathTypePreset("Wall",   color(90, 70, 50),   2.5f),
  new PathTypePreset("Trail",  color(140, 100, 70), 1.6f),
  new PathTypePreset("Canal",  color(70, 110, 190), 2.4f),
  new PathTypePreset("Rail",   color(70, 70, 70),   2.8f),
  new PathTypePreset("Pipeline", color(120, 120, 120), 2.0f)
};

// ---------- Color helpers for HSB<->RGB in [0..1] ----------

void rgbToHSB01(int c, float[] outHSB) {
  // Use Processing's HSB colorMode temporarily
  pushStyle();
  colorMode(HSB, 1, 1, 1);
  float h = hue(c);
  float s = saturation(c);
  float b = brightness(c);
  popStyle();

  outHSB[0] = h;
  outHSB[1] = s;
  outHSB[2] = b;
}

int hsb01ToRGB(float h, float s, float b) {
  h = constrain(h, 0, 1);
  s = constrain(s, 0, 1);
  b = constrain(b, 0, 1);

  pushStyle();
  colorMode(HSB, 1, 1, 1);
  int c = color(h, s, b);
  popStyle();

  return c;
}

// ---------- Structures ----------

class Structure {
  float x;
  float y;
  int typeId = 0;
  float angle = 0;
  float size = 0.02f; // world units square side

  Structure(float x, float y) {
    this.x = x;
    this.y = y;
  }

  void draw(PApplet app) {
    float r = size;
    app.pushMatrix();
    app.translate(x, y);
    app.rotate(angle);
    app.stroke(30);
    app.strokeWeight(1.0f / viewport.zoom);
    app.fill(200, 200, 180);
    app.rectMode(CENTER);
    app.rect(0, 0, r, r);
    app.popMatrix();
  }
}

// ---------- Labels ----------

class MapLabel {
  float x;
  float y;
  String text;

  MapLabel(float x, float y, String text) {
    this.x = x;
    this.y = y;
    this.text = text;
  }

  void draw(PApplet app) {
    app.pushStyle();
    app.fill(0);
    app.textAlign(CENTER, CENTER);
    app.textSize(12 / viewport.zoom);
    app.text(text, x, y);
    app.popStyle();
  }
}
