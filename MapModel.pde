
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
  ArrayList<AdminZone> adminZones = new ArrayList<AdminZone>();

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

  MapModel() {
    // biomeTypes will be filled from Main.initBiomeTypes()
  }

  class AdminZone {
    String name;
    int col;
    float hue01 = 0.0f;
    float sat01 = 0.5f;
    float bri01 = 0.9f;
    ArrayList<Integer> cells = new ArrayList<Integer>(); // indices into cells array

    AdminZone(String name, int col) {
      this.name = name;
      this.col = col;
      float[] hsb = rgbToHSB(col);
      hue01 = hsb[0];
      sat01 = hsb[1];
      bri01 = hsb[2];
    }

    void updateColorFromHSB() {
      col = hsb01ToRGB(hue01, sat01, bri01);
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
      if (renderBlackWhite) {
        float shade = brightness(col);
        col = color(shade);
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

  void drawAdminOutlines(PApplet app) {
    if (cells == null || adminZones == null) return;
    app.pushStyle();
    app.noFill();
    ensureCellNeighborsComputed();
    float eps2 = 1e-8f;
    int typeCount = adminZones.size();

    for (int z = 0; z < adminZones.size(); z++) {
      AdminZone zone = adminZones.get(z);
      if (zone == null || zone.cells.isEmpty()) continue;
      int col = (z >= 0 && z < typeCount) ? zone.col : color(0);
      HashSet<String> drawn = new HashSet<String>();

      for (int ci : zone.cells) {
        if (ci < 0 || ci >= cells.size()) continue;
        Cell c = cells.get(ci);
        if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
        for (int e = 0; e < c.vertices.size(); e++) {
          PVector a = c.vertices.get(e);
          PVector b = c.vertices.get((e + 1) % c.vertices.size());
          String k = undirectedEdgeKey(a, b);
          if (drawn.contains(k)) continue;

          boolean sharedWithZone = false;
          ArrayList<Integer> nbs = (ci < cellNeighbors.size()) ? cellNeighbors.get(ci) : null;
          if (nbs != null) {
            for (int nbIdx : nbs) {
              if (!zone.cells.contains(nbIdx)) continue;
              Cell nb = cells.get(nbIdx);
              if (nb == null || nb.vertices == null) continue;
              int nv = nb.vertices.size();
              for (int j = 0; j < nv; j++) {
                PVector na = nb.vertices.get(j);
                PVector nbp = nb.vertices.get((j + 1) % nv);
                boolean match = distSq(a, na) < eps2 && distSq(b, nbp) < eps2;
                boolean matchRev = distSq(a, nbp) < eps2 && distSq(b, na) < eps2;
                if (match || matchRev) {
                  sharedWithZone = true;
                  break;
                }
              }
              if (sharedWithZone) break;
            }
          }

          if (!sharedWithZone) {
            app.stroke(col);
            app.strokeWeight(2.0f / viewport.zoom);
            app.line(a.x, a.y, b.x, b.y);
          }

          drawn.add(k);
        }
      }
    }

    app.popStyle();
  }

  String undirectedEdgeKey(PVector a, PVector b) {
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

  void drawStructureSnapGuides(PApplet app, float seaLevel) {
    if (cells == null || cells.isEmpty()) return;
    ensureCellNeighborsComputed();
    float eps = 1e-4f;

    app.pushStyle();
    app.stroke(40, 80, 140, 180);
    app.strokeWeight(2.0f / viewport.zoom);
    app.noFill();

    int n = cells.size();
    for (int i = 0; i < n; i++) {
      Cell a = cells.get(i);
    ArrayList<Integer> nbs = cellNeighbors.get(i);
      if (nbs == null) continue;
      for (int nb : nbs) {
        if (nb <= i) continue; // each pair once
        Cell b = cells.get(nb);
        if (b == null) continue;

        boolean sameBiome = (a.biomeId == b.biomeId);
        boolean aWater = (a.elevation < seaLevel);
        boolean bWater = (b.elevation < seaLevel);
        boolean sameWater = (aWater == bWater);

        // Only draw guides on biome or water frontiers
        if (sameBiome && sameWater) continue;

        ArrayList<PVector> va = a.vertices;
        if (va == null || va.size() < 2) continue;
        ArrayList<PVector> vb = b.vertices;
        if (vb == null || vb.size() < 2) continue;

        // Build edge sets to avoid duplicate normals and only draw shared frontier
        HashSet<String> edgesA = new HashSet<String>();
        int ac = va.size();
        for (int ai = 0; ai < ac; ai++) {
          PVector a0 = va.get(ai);
          PVector a1 = va.get((ai + 1) % ac);
          edgesA.add(undirectedEdgeKey(a0, a1));
        }
        int bc = vb.size();
        for (int bi = 0; bi < bc; bi++) {
          PVector b0 = vb.get(bi);
          PVector b1 = vb.get((bi + 1) % bc);
          String key = undirectedEdgeKey(b0, b1);
          if (edgesA.contains(key)) {
            // Draw only once per shared edge
            app.line(b0.x, b0.y, b1.x, b1.y);
            edgesA.remove(key); // avoid drawing twice for same pair
          }
        }
      }
    }

    // Path segments are also snap targets; overdraw lightly
    if (paths != null) {
      app.stroke(60, 60, 40, 200);
      for (Path p : paths) {
        if (p == null || p.routes == null) continue;
        for (ArrayList<PVector> seg : p.routes) {
          if (seg == null || seg.size() < 2) continue;
          for (int i = 0; i < seg.size() - 1; i++) {
            PVector a = seg.get(i);
            PVector b = seg.get(i + 1);
            app.line(a.x, a.y, b.x, b.y);
          }
        }
      }
    }

    // Existing structure outlines as snap hints (outside only)
    if (structures != null && !structures.isEmpty()) {
      app.stroke(80, 80, 60, 180);
      app.strokeWeight(1.4f / viewport.zoom);
      for (Structure s : structures) {
        float r = s.size;
        app.pushMatrix();
        app.translate(s.x, s.y);
        app.rotate(s.angle);
        app.noFill();
        app.rectMode(CENTER);
        app.rect(0, 0, r, r);
        app.popMatrix();
      }
    }

    app.popStyle();
  }

  float distSq(PVector a, PVector b) {
    float dx = a.x - b.x;
    float dy = a.y - b.y;
    return dx * dx + dy * dy;
  }

  Structure computeSnappedStructure(float wx, float wy, float size) {
    Structure s = new Structure(wx, wy);
    s.size = size;
    float snapRange = max(0.04f, s.size * 2.0f);

    if (structureSnapMode == StructureSnapMode.NONE) {
      s.angle = structureAngleOffsetRad;
      return s;
    }

    // Snap priority: paths > frontier guides (biome/water) > other structures
    PVector[] seg = nearestPathSegment(wx, wy, snapRange);
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
      s.angle = ang + structureAngleOffsetRad;
      return s;
    }

    PVector[] guide = nearestFrontierSegment(wx, wy, snapRange);
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
      s.angle = ang + structureAngleOffsetRad;
      return s;
    }

    // Next: snap to other structures (edge-to-edge)
    Structure closest = null;
    float bestD2 = snapRange * snapRange;
    for (Structure o : structures) {
      float dx = o.x - wx;
      float dy = o.y - wy;
      float d2 = dx * dx + dy * dy;
      float minGap = (o.size + s.size) * 0.6f;
      if (d2 < bestD2) {
        bestD2 = d2;
        closest = o;
      }
    }
    if (closest != null) {
      float ang = atan2(closest.y - wy, closest.x - wx);
      float dist = sqrt(bestD2);
      float gap = (closest.size + s.size) * 0.6f;
      float reach = max(0, dist - gap);
      s.x = wx + cos(ang) * reach;
      s.y = wy + sin(ang) * reach;
      s.angle = ang + structureAngleOffsetRad;
      return s;
    }

    s.angle = structureAngleOffsetRad;
    return s;
  }

  void drawElevationOverlay(PApplet app, float seaLevel, boolean showContours, boolean drawWater, boolean drawElevation, int quantSteps) {
    // Default: no lighting, just grayscale
    drawElevationOverlay(app, seaLevel, showContours, drawWater, drawElevation, false, 135.0f, 45.0f, quantSteps);
  }

  void drawElevationOverlay(PApplet app, float seaLevel, boolean showContours, boolean drawWater, boolean drawElevation,
                            boolean useLighting, float lightAzimuthDeg, float lightAltitudeDeg, int quantSteps) {
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

    HashMap<String, Float> dist = new HashMap<String, Float>();
    HashMap<String, String> prev = new HashMap<String, String>();
    PriorityQueue<NodeDist> pq = new PriorityQueue<NodeDist>();
    dist.put(kFrom, 0.0f);
    // A* priority = g + h
    PVector target = snapNodes.get(kTo);
    float hStart = (target != null) ? dist2D(snapNodes.get(kFrom), target) : 0;
    pq.add(new NodeDist(kFrom, 0.0f, hStart));

    // Spatial cull to a loose bounding box around endpoints
    float minx = min(from.x, toP.x);
    float maxx = max(from.x, toP.x);
    float miny = min(from.y, toP.y);
    float maxy = max(from.y, toP.y);
    float margin = max(dist2D(from, toP) * 0.6f, 0.05f);
    minx -= margin; maxx += margin; miny -= margin; maxy += margin;

    int maxExpanded = 8000;
    int expanded = 0;
    String closest = kFrom;
    float bestH = (target != null) ? dist2D(snapNodes.get(kFrom), target) : Float.MAX_VALUE;
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
      float hCur = (target != null) ? dist2D(p, target) : Float.MAX_VALUE;
      if (hCur < bestH) {
        bestH = hCur;
        closest = nd.k;
      }
      for (String nb : neighbors) {
        PVector np = snapNodes.get(nb);
        if (np == null) continue;
        if (np.x < minx || np.x > maxx || np.y < miny || np.y > maxy) continue;
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
        float ndist = nd.g + w;
        Float curD = dist.get(nb);
        if (curD == null || ndist < curD - 1e-6f) {
          dist.put(nb, ndist);
          prev.put(nb, nd.k);
          float h = (target != null) ? dist2D(np, target) : 0;
          pq.add(new NodeDist(nb, ndist, ndist + h * 0.8f)); // heuristic weight keeps routes short
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
      int col = (pt != null) ? pt.col : strokeCol;
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

  PVector[] nearestFrontierSegment(float wx, float wy, float maxDist) {
    if (cells == null || cells.isEmpty()) return null;
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

        boolean sameBiome = (a.biomeId == b.biomeId);
        boolean aWater = (a.elevation < seaLevel);
        boolean bWater = (b.elevation < seaLevel);
        boolean sameWater = (aWater == bWater);
        if (sameBiome && sameWater) continue;

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

  int sampleAdminFromOldCells(ArrayList<Cell> oldCells, float x, float y, int fallbackAdmin) {
    return fallbackAdmin;
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

      for (int idxCandidate : candidates) {
        if (idxCandidate == i) continue;
        Site sj = sites.get(idxCandidate);
        poly = model.clipPolygonWithHalfPlane(poly, si, sj);
        if (poly.size() < 3) {
          break;
        }
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
      int needed = 32;
      int maxRing = 4;
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

  void addCellToAdminZone(int cellIdx, int zoneIdx) {
    if (adminZones == null || zoneIdx < 0 || zoneIdx >= adminZones.size()) return;
    if (cellIdx < 0 || cellIdx >= cells.size()) return;
    AdminZone az = adminZones.get(zoneIdx);
    if (az == null) return;
    if (!az.cells.contains(cellIdx)) {
      az.cells.add(cellIdx);
    }
  }

  boolean cellInAdminZone(int cellIdx, int zoneIdx) {
    if (adminZones == null || zoneIdx < 0 || zoneIdx >= adminZones.size()) return false;
    AdminZone az = adminZones.get(zoneIdx);
    if (az == null) return false;
    return az.cells.contains(cellIdx);
  }

  void floodFillAdminZone(Cell start, int zoneIdx) {
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
      addCellToAdminZone(idx, zoneIdx);
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

  void generateSites(PlacementMode mode, int targetCount) {
    generateSites(mode, targetCount, false);
  }

  void generateSites(PlacementMode mode, int targetCount, boolean preserveCellData) {
    int clampedCount = constrain(targetCount, 0, MAX_SITE_COUNT);
    preservedCells = preserveCellData ? new ArrayList<Cell>(cells) : null;
    sites.clear();
    if (!preserveCellData && adminZones != null) {
      for (AdminZone az : adminZones) {
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
    float avgBiomeSubzoneSize = random(10.0,200.0);
    int seedCount = floor(noneIndices.size()/avgBiomeSubzoneSize);
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

  void resetAllAdminsToNone() {
    if (adminZones == null) return;
    for (AdminZone az : adminZones) {
      if (az != null) az.cells.clear();
    }
  }

  boolean hasAnyNoneAdmin() {
    if (adminZones == null || adminZones.isEmpty()) return true;
    for (AdminZone az : adminZones) {
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

    float minDim = min(w, h);
    float targetRes = max(1.0f, sqrt(targetCount));
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

  void addAdminType() {
    int idx = adminZones.size();
    ZonePreset preset = (idx < ZONE_PRESETS.length) ? ZONE_PRESETS[idx] : null;
    int col = (preset != null) ? preset.col : hsb01ToRGB(0.1f * (idx + 1), 0.5f, 0.95f);
    adminZones.add(new AdminZone("Zone" + idx, col));
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

  void removeAdminType(int index) {
    if (index < 0 || index >= adminZones.size()) return;
    adminZones.remove(index);
  }
}

