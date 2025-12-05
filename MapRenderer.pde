class MapRenderer {
  private final MapModel model;

  MapRenderer(MapModel model) {
    this.model = model;
  }

  void drawDebugWorldBounds(PApplet app) {
    app.pushStyle();
    app.noFill();
    app.stroke(0);
    app.strokeWeight(1.5f / viewport.zoom);
    app.rect(model.minX, model.minY, model.maxX - model.minX, model.maxY - model.minY);
    app.popStyle();
  }

  void drawSites(PApplet app) {
    if (model.sites == null) return;
    for (Site s : model.sites) {
      s.draw(app);
    }
  }

  void drawCells(PApplet app) {
    drawCells(app, true);
  }

  void drawCells(PApplet app, boolean showBorders) {
    if (model.cells == null) return;
    for (Cell c : model.cells) {
      c.draw(app, showBorders);
    }
  }

  void drawCellsRender(PApplet app, boolean showBorders) {
    drawCellsRender(app, showBorders, false);
  }

  void drawCellsRender(PApplet app, boolean showBorders, boolean desaturate) {
    if (model.cells == null) return;
    app.pushStyle();
    for (Cell c : model.cells) {
      if (c.vertices == null || c.vertices.size() < 3) continue;
      int col = color(230);
      if (model.biomeTypes != null && c.biomeId >= 0 && c.biomeId < model.biomeTypes.size()) {
        ZoneType zt = model.biomeTypes.get(c.biomeId);
        col = zt.col;
      }
      if (c.elevation < seaLevel) {
        // Lightly tint underwater cells darker to acknowledge seaLevel
        col = lerpColor(col, color(30, 70, 120), 0.15f);
      }
      if (desaturate) {
        float[] hsb = model.rgbToHSB(col);
        hsb[1] = constrain(hsb[1] * 0.82f, 0, 1);
        hsb[2] = constrain(hsb[2] * 1.05f, 0, 1);
        col = hsb01ToRGB(hsb[0], hsb[1], hsb[2]);
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
    if (model.structures == null) return;
    app.pushStyle();
    for (int i = 0; i < model.structures.size(); i++) {
      Structure s = model.structures.get(i);
      s.draw(app);
      if (i == selectedStructureIndex) {
        app.pushStyle();
        app.noFill();
        app.stroke(255, 180, 0, 200);
        app.strokeWeight(3.0f / viewport.zoom);
        app.rectMode(CENTER);
        float pad = s.size * 0.15f;
        app.pushMatrix();
        app.translate(s.x, s.y);
        app.rotate(s.angle);
        float w = s.size;
        float h = (s.shape == StructureShape.RECTANGLE && s.aspect != 0) ? (s.size / max(0.1f, s.aspect)) : s.size;
        switch (s.shape) {
          case RECTANGLE:
          case SQUARE:
            app.rect(0, 0, w + pad * 2, h + pad * 2);
            break;
          case CIRCLE:
            app.ellipse(0, 0, w + pad * 2, w + pad * 2);
            break;
          case TRIANGLE:
          case HEXAGON:
            app.scale(1.05f); // small inflate
            s.draw(app);
            break;
          default:
            app.rect(0, 0, w + pad * 2, w + pad * 2);
            break;
        }
        app.popMatrix();
        app.popStyle();
      }
    }
    app.popStyle();
  }

  void drawLabels(PApplet app) {
    if (model.labels == null) return;
    app.pushStyle();
    for (MapLabel l : model.labels) {
      l.draw(app);
    }
    app.popStyle();
  }

  void drawZoneOutlines(PApplet app) {
    if (model.cells == null || model.zones == null) return;
    model.ensureCellNeighborsComputed();
    int n = model.cells.size();
    if (n == 0 || model.zones.isEmpty()) return;

    // Zone memberships per cell (allow multiple zones); empty list = no zone.
    ArrayList<ArrayList<Integer>> zoneForCell = new ArrayList<ArrayList<Integer>>(n);
    for (int i = 0; i < n; i++) zoneForCell.add(new ArrayList<Integer>());
    for (int zi = 0; zi < model.zones.size(); zi++) {
      MapModel.MapZone z = model.zones.get(zi);
      if (z == null || z.cells == null) continue;
      for (int ci : z.cells) {
        if (ci < 0 || ci >= n) continue;
        ArrayList<Integer> list = zoneForCell.get(ci);
        if (!list.contains(zi)) list.add(zi);
      }
    }

    float eps2 = 1e-6f; // lenient match to avoid missing shared edges
    float baseW = 2.0f / viewport.zoom;
    float offset = 3.0f / viewport.zoom;
    float laneGap = 1.4f / viewport.zoom;
    HashSet<String> drawn = new HashSet<String>();

    app.pushStyle();
    app.noFill();

    for (int ci = 0; ci < n; ci++) {
      Cell c = model.cells.get(ci);
      if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
      ArrayList<Integer> zonesA = zoneForCell.get(ci);
      if (zonesA == null || zonesA.isEmpty()) continue; // No zone -> no outline
      int vc = c.vertices.size();
      for (int e = 0; e < vc; e++) {
        PVector a = c.vertices.get(e);
        PVector b = c.vertices.get((e + 1) % vc);
        String key = undirectedEdgeKey(a, b);
        if (drawn.contains(key)) continue;

        ArrayList<Integer> zonesB = null;
        ArrayList<Integer> nbs = (ci < model.cellNeighbors.size()) ? model.cellNeighbors.get(ci) : null;
        if (nbs != null) {
          for (int nbIdx : nbs) {
            if (nbIdx < 0 || nbIdx >= n) continue;
            Cell nb = model.cells.get(nbIdx);
            if (nb == null || nb.vertices == null) continue;
            int nv = nb.vertices.size();
            boolean matched = false;
            for (int j = 0; j < nv; j++) {
              PVector na = nb.vertices.get(j);
              PVector nbp = nb.vertices.get((j + 1) % nv);
              boolean match = model.distSq(a, na) < eps2 && model.distSq(b, nbp) < eps2;
              boolean matchRev = model.distSq(a, nbp) < eps2 && model.distSq(b, na) < eps2;
              if (match || matchRev) {
                zonesB = zoneForCell.get(nbIdx);
                matched = true;
                break;
              }
            }
            if (matched) break;
          }
        }

        HashSet<Integer> setA = new HashSet<Integer>(zonesA);
        HashSet<Integer> setB = (zonesB != null) ? new HashSet<Integer>(zonesB) : new HashSet<Integer>();
        HashSet<Integer> uniqueA = new HashSet<Integer>(setA);
        uniqueA.removeAll(setB);
        HashSet<Integer> uniqueB = new HashSet<Integer>(setB);
        uniqueB.removeAll(setA);

        // Skip pure interior edges where memberships are identical
        if (uniqueA.isEmpty() && uniqueB.isEmpty()) {
          drawn.add(key);
          continue;
        }

        PVector cenA = model.cellCentroid(c);
        PVector mid = new PVector((a.x + b.x) * 0.5f, (a.y + b.y) * 0.5f);
        PVector edgeDir = new PVector(b.x - a.x, b.y - a.y);
        PVector nrm = new PVector(-edgeDir.y, edgeDir.x);
        float nLen = max(1e-6f, sqrt(nrm.x * nrm.x + nrm.y * nrm.y));
        nrm.mult(1.0f / nLen);
        // Orient normal toward cell A
        if (cenA != null) {
          PVector toCenter = PVector.sub(cenA, mid);
          if (toCenter.dot(nrm) < 0) nrm.mult(-1);
        }

        // Draw all differing zones with small per-zone offsets so they do not overlap.
        float startA = offset;
        for (int zId : uniqueA) {
          if (zId < 0 || zId >= model.zones.size()) continue;
          app.stroke(model.zones.get(zId).col, 240);
          app.strokeWeight(baseW);
          float lane = startA;
          app.line(a.x + nrm.x * lane, a.y + nrm.y * lane, b.x + nrm.x * lane, b.y + nrm.y * lane);
          startA += laneGap;
        }

        float startB = offset;
        for (int zId : uniqueB) {
          if (zId < 0 || zId >= model.zones.size()) continue;
          app.stroke(model.zones.get(zId).col, 240);
          app.strokeWeight(baseW * 0.9f);
          float lane = startB;
          app.line(a.x - nrm.x * lane, a.y - nrm.y * lane, b.x - nrm.x * lane, b.y - nrm.y * lane);
          startB += laneGap;
        }

        drawn.add(key);
      }
    }

    app.popStyle();
  }

  void drawStructureSnapGuides(PApplet app,
                               boolean useWater, boolean useBiomes, boolean useUnderwaterBiomes, boolean useZones,
                               boolean usePaths, boolean useStructures, boolean useElevation,
                               int[] zoneMembership, int[] elevBuckets) {
    if (model.cells == null || model.cells.isEmpty()) return;
    model.ensureCellNeighborsComputed();

    app.pushStyle();
    int strokeCol = app.color(60, 120, 220, 190);
    app.stroke(strokeCol);
    app.strokeWeight(2.0f / viewport.zoom);
    app.noFill();

    if (useWater || useBiomes || useUnderwaterBiomes || useZones || useElevation) {
      int n = model.cells.size();
      for (int i = 0; i < n; i++) {
        Cell a = model.cells.get(i);
        ArrayList<Integer> nbs = model.cellNeighbors.get(i);
        if (nbs == null) continue;
        for (int nb : nbs) {
          if (nb <= i) continue;
          Cell b = model.cells.get(nb);
          if (!model.boundaryActiveForSnapping(a, b, i, nb, zoneMembership, elevBuckets,
                                               useWater, useBiomes, useUnderwaterBiomes, useZones, useElevation)) {
            continue;
          }

          ArrayList<PVector> va = a.vertices;
          ArrayList<PVector> vb = b.vertices;
          if (va == null || vb == null || va.size() < 2 || vb.size() < 2) continue;

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
              app.line(b0.x, b0.y, b1.x, b1.y);
              edgesA.remove(key);
            }
          }
        }
      }
    }

    if (usePaths && model.paths != null) {
      app.stroke(strokeCol);
      app.strokeWeight(1.0f / viewport.zoom);
      for (Path p : model.paths) {
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

    if (useStructures && model.structures != null && !model.structures.isEmpty()) {
      app.stroke(strokeCol);
      app.strokeWeight(1.1f / viewport.zoom);
      app.noFill();
      for (Structure s : model.structures) {
        app.pushMatrix();
        app.translate(s.x, s.y);
        app.rotate(s.angle);
        float r = s.size;
        switch (s.shape) {
          case RECTANGLE: {
            float w = r;
            float h = (s.aspect != 0) ? (r / max(0.1f, s.aspect)) : r;
            app.rectMode(CENTER);
            app.rect(0, 0, w, h);
            break;
          }
          case CIRCLE: {
            app.ellipse(0, 0, r, r);
            break;
          }
          case TRIANGLE: {
            float h = r * 0.866f;
            app.beginShape();
            app.vertex(-r * 0.5f, h * 0.333f);
            app.vertex(r * 0.5f, h * 0.333f);
            app.vertex(0, -h * 0.666f);
            app.endShape(CLOSE);
            break;
          }
          case HEXAGON: {
            float rad = r * 0.5f;
            app.beginShape();
            for (int i = 0; i < 6; i++) {
              float a = radians(60 * i);
              app.vertex(cos(a) * rad, sin(a) * rad);
            }
            app.endShape(CLOSE);
            break;
          }
          default: {
            float sHalf = r * 0.5f;
            app.rectMode(CENTER);
            app.rect(0, 0, sHalf * 2, sHalf * 2);
            break;
          }
        }
        app.popMatrix();
      }
    }

    app.popStyle();
  }

  MapModel.ContourGrid sampleElevationGrid(int cols, int rows, float fallback) {
    MapModel.ContourGrid g = model.new ContourGrid();
    g.cols = max(2, cols);
    g.rows = max(2, rows);
    g.v = new float[g.rows][g.cols];
    g.ox = model.minX;
    g.oy = model.minY;
    g.dx = (model.maxX - model.minX) / (g.cols - 1);
    g.dy = (model.maxY - model.minY) / (g.rows - 1);
    g.min = Float.MAX_VALUE;
    g.max = -Float.MAX_VALUE;
    for (int j = 0; j < g.rows; j++) {
      float y = g.oy + j * g.dy;
      for (int i = 0; i < g.cols; i++) {
        float x = g.ox + i * g.dx;
        float val = model.sampleElevationAt(x, y, fallback);
        g.v[j][i] = val;
        g.min = min(g.min, val);
        g.max = max(g.max, val);
      }
    }
    return g;
  }

  void drawContourSet(PApplet app, MapModel.ContourGrid g, float start, float end, float step, int strokeCol) {
    if (step == 0) return;
    if ((step > 0 && start > end) || (step < 0 && start < end)) return;
    app.pushStyle();
    app.noFill();
    app.stroke(strokeCol);
    app.strokeWeight(1.0f / viewport.zoom);

    if (step > 0) {
      for (float iso = start; iso <= end + 1e-6f; iso += step) {
        drawIsoLine(app, g, iso);
      }
    } else {
      for (float iso = start; iso >= end - 1e-6f; iso += step) {
        drawIsoLine(app, g, iso);
      }
    }
    app.popStyle();
  }

  void drawIsoLine(PApplet app, MapModel.ContourGrid g, float iso) {
    for (int j = 0; j < g.rows - 1; j++) {
      float y0 = g.oy + j * g.dy;
      float y1 = y0 + g.dy;
      for (int i = 0; i < g.cols - 1; i++) {
        float x0 = g.ox + i * g.dx;
        float x1 = x0 + g.dx;
        float v00 = g.v[j][i];
        float v10 = g.v[j][i + 1];
        float v11 = g.v[j + 1][i + 1];
        float v01 = g.v[j + 1][i];

        int caseId = 0;
        if (v00 > iso) caseId |= 1;
        if (v10 > iso) caseId |= 2;
        if (v11 > iso) caseId |= 4;
        if (v01 > iso) caseId |= 8;

        if (caseId == 0 || caseId == 15) continue;

        PVector eTop = interpIso(x0, y0, v00, x1, y0, v10, iso);
        PVector eRight = interpIso(x1, y0, v10, x1, y1, v11, iso);
        PVector eBottom = interpIso(x0, y1, v01, x1, y1, v11, iso);
        PVector eLeft = interpIso(x0, y0, v00, x0, y1, v01, iso);

        switch (caseId) {
          case 1:  drawSeg(app, eLeft, eTop); break;
          case 2:  drawSeg(app, eTop, eRight); break;
          case 3:  drawSeg(app, eLeft, eRight); break;
          case 4:  drawSeg(app, eRight, eBottom); break;
          case 5:  drawSeg(app, eTop, eRight); drawSeg(app, eLeft, eBottom); break;
          case 6:  drawSeg(app, eTop, eBottom); break;
          case 7:  drawSeg(app, eLeft, eBottom); break;
          case 8:  drawSeg(app, eBottom, eLeft); break;
          case 9:  drawSeg(app, eTop, eBottom); break;
          case 10: drawSeg(app, eTop, eLeft); drawSeg(app, eRight, eBottom); break;
          case 11: drawSeg(app, eRight, eBottom); break;
          case 12: drawSeg(app, eRight, eLeft); break;
          case 13: drawSeg(app, eRight, eTop); break;
          case 14: drawSeg(app, eTop, eLeft); break;
        }
      }
    }
  }

  void drawSeg(PApplet app, PVector a, PVector b) {
    if (a == null || b == null) return;
    app.line(a.x, a.y, b.x, b.y);
  }

  PVector interpIso(float x0, float y0, float v0, float x1, float y1, float v1, float iso) {
    float denom = (v1 - v0);
    if (abs(denom) < 1e-6f) return new PVector((x0 + x1) * 0.5f, (y0 + y1) * 0.5f);
    float t = (iso - v0) / denom;
    t = constrain(t, 0, 1);
    return new PVector(lerp(x0, x1, t), lerp(y0, y1, t));
  }

  private String undirectedEdgeKey(PVector a, PVector b) {
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
}
