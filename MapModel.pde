
import java.util.HashMap;
import java.util.HashSet;
import java.util.ArrayDeque;

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

  // Biomes / zone types
  ArrayList<ZoneType> biomeTypes = new ArrayList<ZoneType>();

  boolean voronoiDirty = true;
  boolean snapDirty = true;

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

  void drawElevationOverlay(PApplet app, float seaLevel, boolean showContours) {
    if (cells == null) return;
    app.pushStyle();
    for (Cell c : cells) {
      if (c.vertices == null || c.vertices.size() < 3) continue;
      float h = c.elevation;
      float shade = constrain((h + 0.5f), 0, 1); // center on 0
      int col = app.color(shade * 255);
      app.noStroke();
      app.fill(col, 140);
      app.beginShape();
      for (PVector v : c.vertices) app.vertex(v.x, v.y);
      app.endShape(CLOSE);

      if (h < seaLevel) {
        int water = app.color(80, 140, 255, 110);
        app.fill(water);
        app.beginShape();
        for (PVector v : c.vertices) app.vertex(v.x, v.y);
        app.endShape(CLOSE);
      }
    }

    if (showContours) {
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

  ArrayList<PVector> findSnapPath(PVector from, PVector to2) {
    ensureSnapGraph();
    String kFrom = keyFor(from.x, from.y);
    String kTo = keyFor(to2.x, to2.y);
    if (!snapNodes.containsKey(kFrom) || !snapNodes.containsKey(kTo)) return null;
    if (kFrom.equals(kTo)) {
      ArrayList<PVector> single = new ArrayList<PVector>();
      single.add(snapNodes.get(kFrom));
      return single;
    }

    HashSet<String> visited = new HashSet<String>();
    HashMap<String, String> prev = new HashMap<String, String>();
    ArrayDeque<String> q = new ArrayDeque<String>();
    q.add(kFrom);
    visited.add(kFrom);

    while (!q.isEmpty()) {
      String cur = q.poll();
      ArrayList<String> neighbors = snapAdj.get(cur);
      if (neighbors == null) continue;
      for (String nb : neighbors) {
        if (visited.contains(nb)) continue;
        visited.add(nb);
        prev.put(nb, cur);
        if (nb.equals(kTo)) {
          return reconstructPath(prev, kFrom, kTo);
        }
        q.add(nb);
      }
    }
    return null;
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

  void drawPaths(PApplet app) {
    drawPaths(app, app.color(60, 60, 200), 2.0f / viewport.zoom);
  }

  void drawPaths(PApplet app, int strokeCol, float strokeW) {
    if (paths.isEmpty()) return;

    app.pushStyle();
    app.noFill();
    app.stroke(strokeCol);
    app.strokeWeight(strokeW);

    for (Path p : paths) {
      p.draw(app);
    }

    app.popStyle();
  }

  // ---------- Paths management ----------

  void addFinishedPath(Path p) {
    if (p == null) return;
    if (p.points.size() < 2) return; // ignore degenerate paths
    paths.add(p);
  }

  void clearAllPaths() {
    paths.clear();
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
      return;
    }

    // Keep a copy of old cells so we can inherit biomes
    ArrayList<Cell> oldCells = new ArrayList<Cell>();
    for (Cell c : cells) {
      oldCells.add(c);
    }

    cells.clear();

    int defaultBiome = 0;

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

        int biomeId;
        if (oldCells.isEmpty()) {
          biomeId = defaultBiome;
        } else {
          biomeId = sampleBiomeFromOldCells(oldCells, cx, cy, defaultBiome);
        }

        cells.add(new Cell(i, poly, biomeId));
      }
    }
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

  // ---------- Sites generation ----------

  void generateSites(PlacementMode mode, float density) {
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

  void applyElevationBrush(float cx, float cy, float radius, float delta) {
    if (cells == null || cells.isEmpty()) return;
    float r2 = radius * radius;
    for (Cell c : cells) {
      PVector cen = cellCentroid(c);
      float dx = cen.x - cx;
      float dy = cen.y - cy;
      float d2 = dx * dx + dy * dy;
      if (d2 > r2) continue;
      float t = 1.0f - sqrt(d2 / r2);
      c.elevation = constrain(c.elevation + delta * t, -1.0f, 1.0f);
    }
  }

  void generateElevationNoise(float scale, float amplitude) {
    if (cells == null) return;
    for (Cell c : cells) {
      PVector cen = cellCentroid(c);
      float n = noise(cen.x * scale, cen.y * scale);
      c.elevation = (n - 0.5f) * 2.0f * amplitude;
    }
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
    int maxRes = 100; // denser

    int res = (int)map(density, 0, 1, minRes, maxRes);
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
    int maxRes = 80; // denser

    int res = (int)map(density, 0, 1, minRes, maxRes);
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
    float targetRes = map(density, 0, 1, 4, 110); // closer to grid/hex density
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

    int k = 30;
    int maxPoints = 8000;

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
    int n = biomeTypes.size();

    // Base params if nothing to copy from
    float baseHue = 0.33f;   // green-ish
    float baseSat = 0.4f;
    float baseBri = 1.0f;

    if (n > 1) {
      // Take previous type and rotate hue
      ZoneType last = biomeTypes.get(n - 1);
      baseHue = (last.hue01 + 0.15f) % 1.0f;
      baseSat = last.sat01;
      baseBri = last.bri01;
    }

    int newIndex = n; // will become "Type newIndex"
    String name = "Type " + newIndex;
    int col = hsb01ToRGB(baseHue, baseSat, baseBri);

    biomeTypes.add(new ZoneType(name, col));
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
