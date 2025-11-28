class MapModel {
  // World bounds in world coordinates
  float minX = 0.0f;
  float minY = 0.0f;
  float maxX = 1.0f;
  float maxY = 1.0f;

  ArrayList<Site> sites = new ArrayList<Site>();
  ArrayList<Cell> cells = new ArrayList<Cell>();

  // Biomes / zone types
  ArrayList<ZoneType> biomeTypes = new ArrayList<ZoneType>();

  boolean voronoiDirty = true;

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
    for (Cell c : cells) {
      c.draw(app);
    }
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
  }

  void ensureVoronoiComputed() {
    if (voronoiDirty) {
      recomputeVoronoi();
      voronoiDirty = false;
    }
  }

  void recomputeVoronoi() {
    cells.clear();

    int n = sites.size();
    if (n == 0) return;

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
        cells.add(new Cell(i, poly, defaultBiome));
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
    int maxRes = 40;
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
    int maxRes = 30;
    int res = (int)map(density, 0, 1, minRes, maxRes);
    res = max(2, res);

    float w = maxX - minX;
    float h = maxY - minY;

    int cols = res;
    float dx = w / cols;

    float dy = dx * sqrt(3) / 2.0f;
    int rows = max(1, (int)((h / dy) + 0.5f));

    for (int j = 0; j < rows; j++) {
      float offset = (j % 2 == 0) ? 0.0f : dx * 0.5f;
      for (int i = 0; i < cols; i++) {
        float x = minX + (i + 0.5f) * dx + offset;
        if (x < minX || x > maxX) continue;
        float y = minY + (j + 0.5f) * dy;
        if (y < minY || y > maxY) continue;
        sites.add(new Site(x, y));
      }
    }
  }

  void generatePoissonSites(float density) {
    float w = maxX - minX;
    float h = maxY - minY;

    float maxR = 0.20f * min(w, h);
    float minR = 0.01f * min(w, h);
    float r = lerp(maxR, minR, density);
    if (r <= 0) r = 0.01f;

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
    int maxPoints = 3000;

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
}

// ---------- ZoneType ----------

class ZoneType {
  String name;
  int col;

  ZoneType(String name, int col) {
    this.name = name;
    this.col = col;
  }
}
