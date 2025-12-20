import java.util.*;
import processing.core.PConstants;

class MapRenderer {
  private final MapModel model;

  // Cached biome outline edges
  private ArrayList<PVector[]> cachedBiomeOutlineEdges = new ArrayList<PVector[]>();
  private ArrayList<Integer> cachedBiomeOutlineBiomes = new ArrayList<Integer>();
  private ArrayList<Boolean> cachedBiomeOutlineUnderwater = new ArrayList<Boolean>();
  private int cachedBiomeOutlineCellCount = -1;
  private int cachedBiomeOutlineChecksum = 0;
  private float cachedBiomeOutlineSeaLevel = Float.MAX_VALUE;
  private boolean drawRoundCaps = true;
  private PGraphics coastLayer;
  private int coastLayerHash = 0;
  private float coastLayerZoom = -1;
  private float coastLayerCenterX = Float.MAX_VALUE;
  private float coastLayerCenterY = Float.MAX_VALUE;
  private int coastLayerW = -1;
  private int coastLayerH = -1;
  private float coastLayerSeaLevel = Float.MAX_VALUE;
  private int coastLayerCellCount = -1;
  private PGraphics zoneLayer;
  private int zoneLayerHash = 0;
  private float zoneLayerZoom = -1;
  private float zoneLayerCenterX = Float.MAX_VALUE;
  private float zoneLayerCenterY = Float.MAX_VALUE;
  private int zoneLayerW = -1;
  private int zoneLayerH = -1;
  private int zoneLayerCellCount = -1;
  private int zoneLayerZoneCount = -1;
  private PGraphics biomeLayer;
  private int biomeLayerHash = 0;
  private float biomeLayerZoom = -1;
  private float biomeLayerCenterX = Float.MAX_VALUE;
  private float biomeLayerCenterY = Float.MAX_VALUE;
  private int biomeLayerW = -1;
  private int biomeLayerH = -1;
  private int biomeLayerCellCount = -1;
  private int biomeLayerBiomeCount = -1;
  private PGraphics elevationLightLayer;
  private int elevationLightHashVal = 0;
  private float elevationLightZoom = -1;
  private float elevationLightCenterX = Float.MAX_VALUE;
  private float elevationLightCenterY = Float.MAX_VALUE;
  private int elevationLightW = -1;
  private int elevationLightH = -1;
  private float elevationLightSeaLevel = Float.MAX_VALUE;
  private int elevationLightCellCount = -1;
  private PImage noiseTex;
  private final int NOISE_TEX_SIZE = 1024;

  MapRenderer(MapModel model) {
    this.model = model;
  }

  void drawDebugWorldBounds(PApplet app) {
    app.pushStyle();
    app.noFill();
    app.stroke(0);
    app.strokeCap(PConstants.ROUND);
    app.strokeJoin(PConstants.ROUND);
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
    app.strokeCap(PConstants.ROUND);
    app.strokeJoin(PConstants.ROUND);
    float biomeAlphaScale = (currentTool == Tool.EDIT_ELEVATION) ? 0.8f : 1.0f;
    float[][] biomeHSB = null;
    if (desaturate && model.biomeTypes != null && !model.biomeTypes.isEmpty()) {
      int nb = model.biomeTypes.size();
      biomeHSB = new float[nb][3];
      for (int i = 0; i < nb; i++) {
        ZoneType zt = model.biomeTypes.get(i);
        if (zt == null) continue;
        rgbToHSB01(zt.col, biomeHSB[i]);
      }
    }
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
        float[] hsb;
        if (biomeHSB != null && c.biomeId >= 0 && c.biomeId < biomeHSB.length && biomeHSB[c.biomeId] != null) {
          hsb = biomeHSB[c.biomeId];
        } else {
          hsb = new float[3];
          rgbToHSB01(col, hsb);
        }
        float sat = constrain(hsb[1] * 0.82f, 0, 1);
        float bri = constrain(hsb[2] * 1.05f, 0, 1);
        col = hsb01ToRGB(hsb[0], sat, bri);
      }

      app.fill(col, 255 * biomeAlphaScale);
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
      if (isStructureSelected(i)) {
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
            app.rect(0, 0, w + pad * 2, h + pad * 2);
            break;
          case CIRCLE: {
            float eh = s.size / max(0.1f, s.aspect);
            app.ellipse(0, 0, w + pad * 2, eh + pad * 2);
            break;
          }
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

  void drawStructuresRender(PApplet app, RenderSettings s) {
    if (model.structures == null || s == null) return;
    app.pushStyle();
    float az = radians(s.elevationLightAzimuthDeg);
    float altRad = radians(s.elevationLightAltitudeDeg);
    PVector shadowDir = new PVector(-cos(az), -sin(az));
    float tanAlt = max(0.1f, tan(altRad));
    float shadowLenFactor = constrain(0.1f / tanAlt, 0.01f, 0.5f);
    for (int i = 0; i < model.structures.size(); i++) {
      Structure st = model.structures.get(i);
      if (st == null) continue;
      float baseAlpha = st.alpha01 * s.structureAlphaScale01;
      if (baseAlpha <= 1e-4f) continue;
      float[] hsb = model.rgbToHSB(st.fillCol);
      float sat = constrain(hsb[1] * s.structureSatScale01, 0, 1);
      int col = hsb01ToRGB(hsb[0], sat, hsb[2]);

      float shadowAlpha = baseAlpha * s.structureShadowAlpha01;
      float shadowLen = st.size * shadowLenFactor;
      if (shadowAlpha > 1e-4f && shadowLen > 1e-6f) {
        PVector off = PVector.mult(shadowDir, shadowLen);
        app.pushMatrix();
        app.translate(st.x + off.x, st.y + off.y);
        app.rotate(st.angle);
        app.noStroke();
        app.fill(0, 0, 0, shadowAlpha * 255);
        drawStructureShape(app, st);
        app.popMatrix();
      }

      app.pushMatrix();
      app.translate(st.x, st.y);
      app.rotate(st.angle);
      app.stroke(0, 0, 0, baseAlpha * 255);
      app.strokeWeight(st.strokeWeightPx / viewport.zoom);
      app.fill(col, baseAlpha * 255);
      drawStructureShape(app, st);
      app.popMatrix();
    }
    app.popStyle();
  }

  private void drawStructureShape(PApplet app, Structure st) {
    if (st == null) return;
    float r = st.size;
    float aspect = max(0.1f, st.aspect);
    switch (st.shape) {
      case RECTANGLE: {
        float w = r;
        float h = r / aspect;
        app.rectMode(CENTER);
        app.rect(0, 0, w, h);
        break;
      }
      case CIRCLE: {
        float w = r;
        float h = r / aspect;
        app.ellipse(0, 0, w, h);
        break;
      }
      case TRIANGLE: {
        float h = (r / max(1e-3f, sqrt(aspect))) * 0.866f; // keep triangle area reasonable when highly squashed
        app.beginShape();
        app.vertex(-r * 0.5f, h * 0.333f);
        app.vertex(r * 0.5f, h * 0.333f);
        app.vertex(0, -h * 0.666f);
        app.endShape(CLOSE);
        break;
      }
      case HEXAGON: {
        float rad = r * 0.5f;
        float sx = 1.0f;
        float sy = 1.0f / max(1e-3f, sqrt(aspect)); // soften distortion
        app.beginShape();
        for (int v = 0; v < 6; v++) {
          float a = radians(60 * v);
          app.vertex(cos(a) * rad * sx, sin(a) * rad * sy);
        }
        app.endShape(CLOSE);
        break;
      }
      default: {
        float sHalf = r * 0.5f;
        app.rectMode(CENTER);
        app.rect(0, 0, sHalf * 2, sHalf * 2 / aspect);
        break;
      }
    }
  }

  void drawLabels(PApplet app) {
    if (model.labels == null) return;
    app.pushStyle();
    for (MapLabel l : model.labels) {
      l.draw(app);
    }
    app.popStyle();
  }

  void drawLabelsRender(PApplet app, RenderSettings s) {
    if (model.labels == null || s == null) return;
    if (!s.showLabelsArbitrary) return;
    app.pushStyle();
    app.textAlign(CENTER, CENTER);
    for (MapLabel l : model.labels) {
      if (l == null) continue;
      float ts = l.size / max(1e-6f, viewport.zoom);
      drawTextWithOutline(app, l.text, l.x, l.y, ts, s.labelOutlineAlpha01);
    }
    app.popStyle();
  }

  void drawZoneLabelsRender(PApplet app, RenderSettings s) {
    if (model == null || model.zones == null || s == null) return;
    if (!s.showLabelsZones) return;
    app.pushStyle();
    app.fill(0);
    app.textAlign(CENTER, CENTER);
    float baseSize = labelSizeDefault();
    for (MapModel.MapZone z : model.zones) {
      if (z == null || z.cells == null || z.cells.isEmpty()) continue;
      float cx = 0;
      float cy = 0;
      int count = 0;
      for (int ci : z.cells) {
        if (ci < 0 || ci >= model.cells.size()) continue;
        Cell c = model.cells.get(ci);
        if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
        PVector cen = model.cellCentroid(c);
        cx += cen.x;
        cy += cen.y;
        count++;
      }
      if (count <= 0) continue;
      cx /= count;
      cy /= count;
      float ts = baseSize / max(1e-6f, viewport.zoom);
      drawTextWithOutline(app, (z.name != null) ? z.name : "Zone", cx, cy, ts, s.labelOutlineAlpha01);
    }
    app.popStyle();
  }

  void drawPathLabelsRender(PApplet app, RenderSettings s) {
    if (model == null || model.paths == null || s == null) return;
    if (!s.showLabelsPaths) return;
    app.pushStyle();
    app.fill(0);
    app.textAlign(CENTER, CENTER);
    float baseSize = labelSizeDefault();
    for (Path p : model.paths) {
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
      float ts = baseSize / max(1e-6f, viewport.zoom);
      float angle = atan2(bestB.y - bestA.y, bestB.x - bestA.x);
      if (angle > HALF_PI || angle < -HALF_PI) angle += PI; // keep text upright
      float mx = (bestA.x + bestB.x) * 0.5f;
      float my = (bestA.y + bestB.y) * 0.5f;
      app.pushMatrix();
      app.translate(mx, my);
      app.rotate(angle);
      drawTextWithOutline(app, txt, 0, 0, ts, s.labelOutlineAlpha01);
      app.popMatrix();
    }
    app.popStyle();
  }

  void drawStructureLabelsRender(PApplet app, RenderSettings s) {
    if (model == null || model.structures == null || s == null) return;
    if (!s.showLabelsStructures) return;
    app.pushStyle();
    app.fill(0);
    app.textAlign(CENTER, CENTER);
    float baseSize = labelSizeDefault();
    for (Structure st : model.structures) {
      if (st == null) continue;
      String txt = (st.name != null && st.name.length() > 0) ? st.name : "Structure";
      float ts = baseSize / max(1e-6f, viewport.zoom);
      app.pushMatrix();
      app.translate(st.x, st.y);
      drawTextWithOutline(app, txt, 0, 0, ts, s.labelOutlineAlpha01);
      app.popMatrix();
    }
    app.popStyle();
  }

  int labelPriority(LabelTarget t) {
    switch (t) {
      case ZONE: return 4;
      case PATH: return 3;
      case STRUCTURE: return 2;
      case FREE:
      default: return 1;
    }
  }

  void drawTextWithOutline(PApplet app, String txt, float x, float y, float ts, float outlineAlpha01) {
    if (app == null || txt == null) return;
    app.textSize(ts);
    float oa = constrain(outlineAlpha01, 0, 1);
    float offsetPx = 1.0f / max(1e-6f, viewport.zoom);
    if (oa > 1e-4f) {
      app.fill(255, oa * 255);
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          if (dx == 0 && dy == 0) continue;
          app.text(txt, x + dx * offsetPx, y + dy * offsetPx);
        }
      }
    }
    app.fill(0);
    app.text(txt, x, y);
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
    float baseW = 2.0f / viewport.zoom; // base stroke for zone outlines (editing view)
    float laneGap = baseW * 0.6f;       // gap between parallel lanes
    HashSet<String> drawn = new HashSet<String>();

    app.pushStyle();
    app.strokeCap(PConstants.ROUND);
    app.strokeJoin(PConstants.ROUND);
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
        ArrayList<Integer> listA = new ArrayList<Integer>(uniqueA);
        ArrayList<Integer> listB = new ArrayList<Integer>(uniqueB);
        Collections.sort(listA);
        Collections.sort(listB);

        float offsetA = 0;
        for (int zId : listA) {
          if (zId < 0 || zId >= model.zones.size()) continue;
          float w = baseW;
          float lane = offsetA + w * 0.5f;
          app.stroke(model.zones.get(zId).col, 240);
          app.strokeWeight(w);
          app.line(a.x + nrm.x * lane, a.y + nrm.y * lane, b.x + nrm.x * lane, b.y + nrm.y * lane);
          offsetA += w + laneGap;
        }

        float offsetB = 0;
        for (int zId : listB) {
          if (zId < 0 || zId >= model.zones.size()) continue;
          float w = baseW;
          float lane = offsetB + w * 0.5f;
          app.stroke(model.zones.get(zId).col, 240);
          app.strokeWeight(w);
          app.line(a.x - nrm.x * lane, a.y - nrm.y * lane, b.x - nrm.x * lane, b.y - nrm.y * lane);
          offsetB += w + laneGap;
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

  // New render view pipeline driven by RenderSettings
  void drawRenderAdvanced(PApplet app, RenderSettings s, float seaLevel) {
    if (model == null || model.cells == null) return;
    app.pushStyle();
    if (s.antialiasing) app.smooth();

    int landBase = hsbColor(s.landHue01, s.landSat01, s.landBri01, 1.0f);
    int waterBase = hsbColor(s.waterHue01, s.waterSat01, s.waterBri01, 1.0f);
    int[] biomeScaledCols = buildBiomeScaledColors(s);
    HashMap<String, PImage> framePatternCache = new HashMap<String, PImage>();

    // Base fills
    app.noStroke();
    app.fill(landBase);
    app.rect(model.minX, model.minY, model.maxX - model.minX, model.maxY - model.minY);
    for (Cell c : model.cells) {
      if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
      if (c.elevation < seaLevel) {
        app.fill(waterBase);
        drawPoly(app, c.vertices);
      }
    }

    // Background noise overlay (monochrome, tiled texture cached once)
    if (s.backgroundNoiseAlpha01 > 1e-4f) {
      PImage ntex = getNoiseTexture(app);
      if (ntex != null) {
        float a = s.backgroundNoiseAlpha01;
        app.pushStyle();
        app.textureMode(PConstants.NORMAL);
        app.textureWrap(PConstants.REPEAT);
        // Land
        for (Cell c : model.cells) {
          if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
          if (c.elevation < seaLevel) continue;
          drawPatternPoly(app, c.vertices, ntex, landBase, a);
        }
        // Water
        for (Cell c : model.cells) {
          if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
          if (c.elevation >= seaLevel) continue;
          drawPatternPoly(app, c.vertices, ntex, waterBase, a);
        }
        app.popStyle();
      }
    }

    // Biome fills
    if (s.biomeFillAlpha01 > 1e-4f || s.biomeUnderwaterAlpha01 > 1e-4f) {
      app.noStroke();
      boolean usePattern = (s.biomeFillType == RenderFillType.RENDER_FILL_PATTERN || s.biomeFillType == RenderFillType.RENDER_FILL_PATTERN_BG);
      for (Cell c : model.cells) {
        if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
        boolean isWater = c.elevation < seaLevel;
        if (isWater && s.biomeUnderwaterAlpha01 <= 1e-4f) continue;
        if (!isWater && s.biomeFillAlpha01 <= 1e-4f) continue;
        int col = landBase;
        String patName = s.biomePatternName;
        if ((patName == null || patName.length() == 0) && model.biomePatternFiles != null && !model.biomePatternFiles.isEmpty()) {
          patName = model.biomePatternFiles.get(0);
        }
        if (model.biomeTypes != null && c.biomeId >= 0 && c.biomeId < model.biomeTypes.size()) {
          ZoneType zt = model.biomeTypes.get(c.biomeId);
          if (zt != null) {
            if (biomeScaledCols != null) {
              col = biomeScaledCols[c.biomeId];
            }
            patName = model.biomePatternNameForIndex(zt.patternIndex, patName);
          }
        }
        float a = isWater ? s.biomeUnderwaterAlpha01 : s.biomeFillAlpha01;
        PImage pattern = null;
        boolean canPattern = false;
        if (usePattern && patName != null) {
          if (framePatternCache.containsKey(patName)) {
            pattern = framePatternCache.get(patName);
          } else {
            pattern = getPattern(app, patName);
            framePatternCache.put(patName, pattern);
          }
          canPattern = (pattern != null);
        }
        if (usePattern && canPattern && s.biomeFillType == RenderFillType.RENDER_FILL_PATTERN) {
          drawPatternPoly(app, c.vertices, pattern, col, a);
        } else {
          app.fill(col, a * 255);
          drawPoly(app, c.vertices);
          if (usePattern && canPattern && s.biomeFillType == RenderFillType.RENDER_FILL_PATTERN_BG) {
            // Overlay black pattern on top of color
            drawPatternPoly(app, c.vertices, pattern, color(0, 0, 0), a);
          }
        }
      }
    }

    // Cell borders
    if (s.cellBorderAlpha01 > 1e-4f) {
      app.stroke(0, 0, 0, s.cellBorderAlpha01 * 255);
      app.strokeWeight(1.0f / viewport.zoom);
      app.strokeCap(PConstants.ROUND);
      app.strokeJoin(PConstants.ROUND);
      app.noFill();
      for (Cell c : model.cells) {
        if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
        drawPoly(app, c.vertices, true);
      }
    }

    // Biome outlines (boundary edges between biomes)
    if (s.biomeOutlineSizePx > 1e-4f && (s.biomeOutlineAlpha01 > 1e-4f || s.biomeUnderwaterAlpha01 > 1e-4f)) {
      ensureBiomeOutlineCache(seaLevel);
      app.noFill();
      app.strokeWeight(max(0.1f, s.biomeOutlineSizePx) / viewport.zoom);
      app.strokeCap(drawRoundCaps ? PConstants.ROUND : PConstants.SQUARE);
      HashSet<String> capsDrawn = new HashSet<String>();
      for (int i = 0; i < cachedBiomeOutlineEdges.size(); i++) {
        PVector[] seg = cachedBiomeOutlineEdges.get(i);
        int biomeId = (i < cachedBiomeOutlineBiomes.size()) ? cachedBiomeOutlineBiomes.get(i) : -1;
        boolean underwaterEdge = (i < cachedBiomeOutlineUnderwater.size()) ? cachedBiomeOutlineUnderwater.get(i) : false;
        if (underwaterEdge && s.biomeUnderwaterAlpha01 <= 1e-4f) continue;
        if (!underwaterEdge && s.biomeOutlineAlpha01 <= 1e-4f) continue;
        int col = landBase;
        if (model.biomeTypes != null && biomeId >= 0 && biomeId < model.biomeTypes.size()) {
          if (biomeScaledCols != null) {
            col = biomeScaledCols[biomeId];
          }
        }
        float outlineAlpha = underwaterEdge ? min(s.biomeOutlineAlpha01, s.biomeUnderwaterAlpha01) : s.biomeOutlineAlpha01;
        app.stroke(col, outlineAlpha * 255);
        app.line(seg[0].x, seg[0].y, seg[1].x, seg[1].y);
        if (drawRoundCaps) {
          float hw = max(0.1f, s.biomeOutlineSizePx) / viewport.zoom / 2.0f;
          app.noStroke();
          app.fill(col, outlineAlpha * 255);
          String k0 = undirectedEdgeKey(seg[0], seg[0]);
          String k1 = undirectedEdgeKey(seg[1], seg[1]);
          if (!capsDrawn.contains(k0)) { capsDrawn.add(k0); app.ellipse(seg[0].x, seg[0].y, hw * 2, hw * 2); }
          if (!capsDrawn.contains(k1)) { capsDrawn.add(k1); app.ellipse(seg[1].x, seg[1].y, hw * 2, hw * 2); }
          app.stroke(col, outlineAlpha * 255);
        }
      }
    }

    // Water depth shading
    if (s.waterDepthAlpha01 > 1e-4f) {
      app.noStroke();
      for (Cell c : model.cells) {
        if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
        if (c.elevation < seaLevel) {
          float depth = seaLevel - c.elevation;
          float t = constrain(depth, 0, 1);
          float a = s.waterDepthAlpha01 * t;
          app.fill(0, 0, 0, a * 200);
          drawPoly(app, c.vertices);
        }
      }
    }

  // Elevation shading (land only) cached to a layer
  if (s.elevationLightAlpha01 > 1e-4f) {
    ensureElevationLightLayer(app, s, seaLevel);
    if (elevationLightLayer != null) {
      app.pushStyle();
      app.pushMatrix();
      app.resetMatrix();
      app.blendMode(PConstants.MULTIPLY);
      app.image(elevationLightLayer, 0, 0);
      app.blendMode(PConstants.BLEND);
      app.popMatrix();
      app.popStyle();
    }
  } else {
    elevationLightLayer = null;
    }

  // Coast outline (draw into cached layer to avoid alpha stacking at caps)
  if (s.waterContourSizePx > 1e-4f && s.waterCoastAlpha01 > 1e-4f) {
    ensureCoastLayer(app, s, seaLevel);
    if (coastLayer != null) {
      app.pushStyle();
      app.pushMatrix();
      app.resetMatrix(); // draw in screen space to avoid double-transform
      app.tint(255, constrain(s.waterCoastAlpha01, 0, 1) * 255);
      app.image(coastLayer, 0, 0);
      app.popMatrix();
      app.popStyle();
    }
  } else {
    coastLayer = null;
  }

    // Water ripples (distance-field contours)
    if (s.waterRippleCount > 0 &&
        s.waterRippleDistancePx > 1e-4f &&
        (s.waterRippleAlphaStart01 > 1e-4f || s.waterRippleAlphaEnd01 > 1e-4f)) {
      int cols = max(80, min(200, (int)(sqrt(max(1, model.cells.size())) * 1.0f)));
      int rows = cols;
      MapModel.ContourGrid g = model.getCoastDistanceGrid(cols, rows, seaLevel);
      if (g != null) {
        float spacingWorld = s.waterRippleDistancePx / max(1e-6f, viewport.zoom);
        if (spacingWorld > 1e-6f) {
          float maxIso = spacingWorld * s.waterRippleCount;
          float strokePx = max(0.8f, s.waterContourSizePx) / max(1e-6f, viewport.zoom);
          app.pushStyle();
          app.noFill();
          app.strokeCap(PConstants.ROUND);
          app.strokeJoin(PConstants.ROUND);
          app.strokeWeight(strokePx);
          for (float iso = spacingWorld; iso <= maxIso + 1e-6f; iso += spacingWorld) {
            float t = (maxIso <= spacingWorld + 1e-6f) ? 0.0f : constrain((iso - spacingWorld) / max(1e-6f, maxIso - spacingWorld), 0, 1);
            float a = constrain(lerp(s.waterRippleAlphaStart01, s.waterRippleAlphaEnd01, t), 0, 1);
            if (a <= 1e-4f) continue;
            int strokeCol = hsbColor(s.waterContourHue01, s.waterContourSat01, s.waterContourBri01, a);
            app.stroke(strokeCol);
            drawIsoLine(app, g, iso);
          }
          app.popStyle();
        }
      }
    }

    // Water hatching (screen-like parallel lines near coast, over water)
    drawWaterHatching(app, s, seaLevel);

    // Elevation contour lines (land only)
    if (s.elevationLinesCount > 0 && s.elevationLinesAlpha01 > 1e-4f) {
      int cols = 90;
      int rows = 90;
      MapModel.ContourGrid grid = model.getElevationGridForRender(cols, rows, seaLevel);
      if (grid != null) {
        float range = max(1e-4f, grid.max - seaLevel);
        float step = range / max(1, s.elevationLinesCount);
        float start = seaLevel + step;
        int strokeCol = app.color(0, 0, 0, s.elevationLinesAlpha01 * 255);
        app.pushStyle();
        app.strokeCap(PConstants.ROUND);
        app.strokeJoin(PConstants.ROUND);
        drawContourSet(app, grid, start, grid.max, step, strokeCol);
        app.popStyle();
      }
    }

    app.popStyle();
  }

  private void drawPoly(PApplet app, ArrayList<PVector> verts) {
    drawPoly(app, verts, false);
  }

  private void drawPoly(PApplet app, ArrayList<PVector> verts, boolean outlineOnly) {
    if (verts == null || verts.size() < 3) return;
    if (outlineOnly) {
      int n = verts.size();
      for (int i = 0; i < n; i++) {
        PVector a = verts.get(i);
        PVector b = verts.get((i + 1) % n);
        app.line(a.x, a.y, b.x, b.y);
      }
      return;
    }
    app.beginShape();
    for (PVector v : verts) app.vertex(v.x, v.y);
    app.endShape(CLOSE);
  }

  // Overloads for PGraphics targets (used by cached layers)
  private void drawPoly(PGraphics g, ArrayList<PVector> verts) {
    drawPoly(g, verts, false);
  }

  private void drawPoly(PGraphics g, ArrayList<PVector> verts, boolean outlineOnly) {
    if (verts == null || verts.size() < 3 || g == null) return;
    if (outlineOnly) {
      int n = verts.size();
      for (int i = 0; i < n; i++) {
        PVector a = verts.get(i);
        PVector b = verts.get((i + 1) % n);
        g.line(a.x, a.y, b.x, b.y);
      }
      return;
    }
    g.beginShape();
    for (PVector v : verts) g.vertex(v.x, v.y);
    g.endShape(PConstants.CLOSE);
  }

  private int hsbColor(float h, float s, float b, float a) {
    int rgb = hsb01ToRGB(constrain(h, 0, 1), constrain(s, 0, 1), constrain(b, 0, 1));
    int ai = constrain(round(constrain(a, 0, 1) * 255.0f), 0, 255);
    return (ai << 24) | (rgb & 0x00FFFFFF);
  }

  private void drawPatternPoly(PApplet app, ArrayList<PVector> verts, PImage pattern, int tintCol, float alpha01) {
    if (verts == null || verts.size() < 3 || pattern == null) return;
    if (pattern.width <= 0 || pattern.height <= 0) return;
    app.pushStyle();
    app.noStroke();
    app.textureMode(PConstants.NORMAL);
    app.textureWrap(PConstants.REPEAT);
    app.tint(tintCol, constrain(alpha01, 0, 1) * 255);
    app.beginShape();
    app.texture(pattern);
    // Keep 1:1 pixel density regardless of zoom; map using screen-space coords
    float pw = max(1, pattern.width);
    float ph = max(1, pattern.height);
    for (PVector v : verts) {
      PVector s = viewport.worldToScreen(v.x, v.y);
      float u = s.x / pw;
      float vv = s.y / ph;
      app.vertex(v.x, v.y, u, vv);
    }
    app.endShape(PConstants.CLOSE);
    app.popStyle();
  }

  // ------- Pattern cache -------
  private HashMap<String, PImage> patternCache = new HashMap<String, PImage>();
  private int[] cachedBiomeScaledColors = null;
  private int[] cachedBiomeSrcCols = null;
  private float cachedBiomeSatScale = -1;
  private float cachedBiomeBriScale = -1;
  private int[] cachedZoneStrokeColors = null;
  private int[] cachedZoneSrcCols = null;
  private float cachedZoneSatScale = -1;
  private float cachedZoneBriScale = -1;
  private PImage getNoiseTexture(PApplet app) {
    if (noiseTex != null && noiseTex.width == NOISE_TEX_SIZE && noiseTex.height == NOISE_TEX_SIZE) return noiseTex;
    noiseTex = app.createImage(NOISE_TEX_SIZE, NOISE_TEX_SIZE, PConstants.ARGB);
    noiseTex.loadPixels();
    for (int i = 0; i < noiseTex.pixels.length; i++) {
      int gray = (int)app.random(0, 256);
      noiseTex.pixels[i] = app.color(gray, gray, gray, 255);
    }
    noiseTex.updatePixels();
    return noiseTex;
  }

  PImage getPattern(PApplet app, String name) {
    if (name == null || name.length() == 0) return null;
    if (patternCache.containsKey(name)) return patternCache.get(name);
    String path = "patterns/" + name;
    PImage img = app.loadImage(path);
    if (img == null || img.width <= 0 || img.height <= 0) {
      String abs = app.sketchPath(path);
      if (abs != null) {
        img = app.loadImage(abs);
      }
    }
    if ((img == null || img.width <= 0 || img.height <= 0) && app.dataPath("") != null) {
      String dataPath = app.dataPath(path);
      img = app.loadImage(dataPath);
    }
    if (img == null || img.width <= 0 || img.height <= 0) {
      patternCache.put(name, null);
      return null;
    }
    // Convert to alpha mask: black = opaque, white = transparent; keep tint-driven color.
    img.format = PConstants.ARGB;
    img.loadPixels();
    for (int i = 0; i < img.pixels.length; i++) {
      int c = img.pixels[i];
      int r = (c >> 16) & 0xFF;
      int g = (c >> 8) & 0xFF;
      int b = c & 0xFF;
      int a = (c >> 24) & 0xFF;
      int gray = (r + g + b) / 3;
      // Black -> alpha 255, white -> alpha 0
      int alpha = 255 - gray;
      alpha = (int)constrain(alpha * (a / 255.0f), 0, 255);
      img.pixels[i] = app.color(255, 255, 255, alpha);
    }
    img.updatePixels();
    patternCache.put(name, img);
    return img;
  }

  private void ensureBiomeOutlineCache(float seaLevel) {
    if (model == null || model.cells == null) return;
    model.ensureCellNeighborsComputed();
    int cellCount = model.cells.size();
    int checksum = biomeChecksum();
    if (cellCount == cachedBiomeOutlineCellCount &&
        checksum == cachedBiomeOutlineChecksum &&
        abs(cachedBiomeOutlineSeaLevel - seaLevel) < 1e-6f) {
      return;
    }

    cachedBiomeOutlineEdges.clear();
    cachedBiomeOutlineBiomes.clear();
    cachedBiomeOutlineUnderwater.clear();
    HashSet<String> drawn = new HashSet<String>();
    float eps2 = 1e-6f;

    for (int ci = 0; ci < model.cells.size(); ci++) {
      Cell c = model.cells.get(ci);
      if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
      int biomeId = c.biomeId;
      boolean cellUnderwater = c.elevation < seaLevel;
      int vc = c.vertices.size();
      for (int e = 0; e < vc; e++) {
        PVector a = c.vertices.get(e);
        PVector b = c.vertices.get((e + 1) % vc);
        String key = undirectedEdgeKey(a, b);
        if (drawn.contains(key)) continue;
        drawn.add(key);

        int nbBiome = biomeId;
        boolean nbUnderwater = cellUnderwater;
        boolean boundary = true;
        ArrayList<Integer> nbs = (ci < model.cellNeighbors.size()) ? model.cellNeighbors.get(ci) : null;
        if (nbs != null) {
          for (int nbIdx : nbs) {
            if (nbIdx < 0 || nbIdx >= model.cells.size()) continue;
            Cell nb = model.cells.get(nbIdx);
            if (nb == null || nb.vertices == null) continue;
            int nv = nb.vertices.size();
            boolean match = false;
            for (int j = 0; j < nv; j++) {
              PVector na = nb.vertices.get(j);
              PVector nbp = nb.vertices.get((j + 1) % nv);
              if ((model.distSq(a, na) < eps2 && model.distSq(b, nbp) < eps2) ||
                  (model.distSq(a, nbp) < eps2 && model.distSq(b, na) < eps2)) {
                nbBiome = nb.biomeId;
                nbUnderwater = nb.elevation < seaLevel;
                match = true;
                break;
              }
            }
            if (match) {
              if (nbBiome == biomeId) boundary = false;
              break;
            }
          }
        }

        if (boundary) {
          cachedBiomeOutlineEdges.add(new PVector[] { a.copy(), b.copy() });
          cachedBiomeOutlineBiomes.add(biomeId);
          cachedBiomeOutlineUnderwater.add(cellUnderwater || nbUnderwater);
        }
      }
    }

    cachedBiomeOutlineCellCount = cellCount;
    cachedBiomeOutlineChecksum = checksum;
    cachedBiomeOutlineSeaLevel = seaLevel;
  }

  private int biomeChecksum() {
    if (model == null || model.cells == null) return 0;
    int sum = 0;
    for (int i = 0; i < model.cells.size(); i++) {
      Cell c = model.cells.get(i);
      sum = 31 * sum + ((c != null) ? c.biomeId : -1);
    }
    return sum;
  }

  void invalidateBiomeOutlineCache() {
    cachedBiomeOutlineEdges.clear();
    cachedBiomeOutlineBiomes.clear();
    cachedBiomeOutlineUnderwater.clear();
    cachedBiomeOutlineCellCount = -1;
    cachedBiomeOutlineChecksum = 0;
    cachedBiomeOutlineSeaLevel = Float.MAX_VALUE;
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

  private float sampleGrid(MapModel.ContourGrid g, float x, float y) {
    if (g == null || g.v == null || g.cols < 2 || g.rows < 2) return 0;
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
    float a = lerp(v00, v10, tx);
    float b = lerp(v01, v11, tx);
    return lerp(a, b, ty);
  }

  void drawWaterHatching(PApplet app, RenderSettings s, float seaLevel) {
    if (s == null) return;
    if (s.waterHatchAlpha01 <= 1e-4f) return;
    if (s.waterHatchLengthPx <= 1e-4f) return;
    if (s.waterHatchSpacingPx <= 1e-4f) return;
    int cols = max(80, min(200, (int)(sqrt(max(1, model.cells.size())) * 1.0f)));
    MapModel.ContourGrid g = model.getCoastDistanceGrid(cols, cols, seaLevel);
    if (g == null) return;

    float angleRad = radians(s.waterHatchAngleDeg);
    PVector d = new PVector(cos(angleRad), sin(angleRad));
    PVector n = new PVector(-d.y, d.x);
    float spacing = s.waterHatchSpacingPx / max(1e-6f, viewport.zoom);
    float maxLen = s.waterHatchLengthPx / max(1e-6f, viewport.zoom);
    if (spacing <= 1e-6f || maxLen <= 1e-6f) return;

    float minX = model.minX;
    float minY = model.minY;
    float maxX = model.maxX;
    float maxY = model.maxY;

    // Projections of map corners onto normal
    float[] projs = new float[] {
      (minX * n.x + minY * n.y),
      (minX * n.x + maxY * n.y),
      (maxX * n.x + minY * n.y),
      (maxX * n.x + maxY * n.y)
    };
    float minProj = min(min(projs[0], projs[1]), min(projs[2], projs[3]));
    float maxProj = max(max(projs[0], projs[1]), max(projs[2], projs[3]));

    float originProj = minX * n.x + minY * n.y;
    float mapDiag = dist(minX, minY, maxX, maxY) + maxLen * 2;
    float stepT = min(spacing * 0.2f, maxLen * 0.2f);
    stepT = max(stepT, maxLen * 0.05f);

    app.pushStyle();
    int strokeCol = hsbColor(s.waterContourHue01, s.waterContourSat01, s.waterContourBri01, s.waterHatchAlpha01);
    app.stroke(strokeCol);
    app.strokeWeight(max(0.6f, s.waterContourSizePx * 0.8f) / max(1e-6f, viewport.zoom));
    app.strokeCap(PConstants.SQUARE);
    app.noFill();

    float startOff = floor((minProj - originProj) / spacing) * spacing + originProj;
    for (float off = startOff; off <= maxProj + spacing * 0.5f; off += spacing) {
      PVector base = new PVector(minX, minY);
      base.add(PVector.mult(n, off - originProj));
      PVector start = PVector.sub(base, PVector.mult(d, mapDiag));
      int segState = 0; // 0=out,1=in
      PVector segStart = null;
      PVector lastIn = null;
      for (float t = 0; t <= mapDiag * 2; t += stepT) {
        PVector p = PVector.add(start, PVector.mult(d, t));
        if (p.x < minX || p.x > maxX || p.y < minY || p.y > maxY) {
          if (segState == 1 && segStart != null && lastIn != null) {
            app.line(segStart.x, segStart.y, lastIn.x, lastIn.y);
          }
          segState = 0;
          segStart = null;
          lastIn = null;
          continue;
        }
        float distVal = sampleGrid(g, p.x, p.y);
        boolean inside = distVal > 0 && distVal <= maxLen;
        if (inside && segState == 0) {
          segState = 1;
          segStart = p.copy();
          lastIn = p.copy();
        } else if (inside && segState == 1) {
          lastIn = p.copy();
        } else if (!inside && segState == 1) {
          segState = 0;
          if (segStart != null && lastIn != null) app.line(segStart.x, segStart.y, lastIn.x, lastIn.y);
          segStart = null;
          lastIn = null;
        }
      }
      if (segState == 1 && segStart != null) {
        PVector end = (lastIn != null) ? lastIn : PVector.add(start, PVector.mult(d, mapDiag * 2));
        app.line(segStart.x, segStart.y, end.x, end.y);
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

  void drawZoneOutlinesRender(PApplet app, RenderSettings s) {
    if (s == null) return;
    boolean drawZones = s.zoneStrokeAlpha01 > 1e-4f && model.zones != null;
    boolean drawBiomes = s.biomeOutlineSizePx > 1e-4f && (s.biomeOutlineAlpha01 > 1e-4f || s.biomeUnderwaterAlpha01 > 1e-4f);
    if (!drawZones && !drawBiomes) return;

    if (drawZones) {
      ensureZoneLayer(app, s);
      if (zoneLayer != null) {
        app.pushStyle();
        app.pushMatrix();
        app.resetMatrix();
        app.tint(255, constrain(s.zoneStrokeAlpha01, 0, 1) * 255);
        app.image(zoneLayer, 0, 0);
        app.popMatrix();
        app.popStyle();
      }
    } else {
      zoneLayer = null;
    }

    if (drawBiomes) {
      ensureBiomeLayer(app, s);
      if (biomeLayer != null) {
        app.pushStyle();
        app.pushMatrix();
        app.resetMatrix();
        app.tint(255, constrain(s.biomeOutlineAlpha01, 0, 1) * 255);
        app.image(biomeLayer, 0, 0);
        app.popMatrix();
        app.popStyle();
      }
    } else {
      biomeLayer = null;
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

  private int hashArray(int[] arr) {
    if (arr == null) return 0;
    int h = 1;
    for (int v : arr) h = 31 * h + v;
    return h;
  }

  private int coastSettingsHash(RenderSettings s) {
    int h = 17;
    h = 31 * h + round(s.waterContourSizePx * 1000.0f);
    h = 31 * h + round(s.waterContourHue01 * 1000.0f);
    h = 31 * h + round(s.waterContourSat01 * 1000.0f);
    h = 31 * h + round(s.waterContourBri01 * 1000.0f);
    h = 31 * h + (drawRoundCaps ? 1 : 0);
    h = 31 * h + ((model != null && model.cells != null) ? model.cells.size() : 0);
    return h;
  }

  private void ensureCoastLayer(PApplet app, RenderSettings s, float seaLevel) {
    if (model == null || model.cells == null || model.cells.isEmpty()) {
      coastLayer = null;
      return;
    }
    if (app == null) return;
    int targetW = (app.g != null) ? app.g.width : app.width;
    int targetH = (app.g != null) ? app.g.height : app.height;
    int hash = coastSettingsHash(s);
    boolean sizeChanged = coastLayer == null || coastLayerW != targetW || coastLayerH != targetH;
    boolean viewChanged = coastLayer == null ||
                          abs(coastLayerZoom - viewport.zoom) > 1e-4f ||
                          abs(coastLayerCenterX - viewport.centerX) > 1e-4f ||
                          abs(coastLayerCenterY - viewport.centerY) > 1e-4f;
    boolean settingsChanged = coastLayer == null ||
                              coastLayerHash != hash ||
                              abs(coastLayerSeaLevel - seaLevel) > 1e-6f ||
                              coastLayerCellCount != model.cells.size();

    if (sizeChanged) {
      coastLayer = app.createGraphics(targetW, targetH, P2D);
      coastLayerW = targetW;
      coastLayerH = targetH;
      if (coastLayer != null) {
        if (s.antialiasing) coastLayer.smooth(8); else coastLayer.noSmooth();
      }
    } else {
      if (coastLayer != null) {
        if (s.antialiasing) coastLayer.smooth(8); else coastLayer.noSmooth();
      }
    }
    if (coastLayer == null) return;
    if (!(sizeChanged || viewChanged || settingsChanged)) return;

    coastLayer.beginDraw();
    coastLayer.clear();
    coastLayer.pushMatrix();
    coastLayer.pushStyle();
    viewport.applyTransform(coastLayer, coastLayer.width, coastLayer.height);
    drawCoastLayer(coastLayer, s, seaLevel);
    coastLayer.popStyle();
    coastLayer.popMatrix();
    coastLayer.endDraw();

    coastLayerHash = hash;
    coastLayerZoom = viewport.zoom;
    coastLayerCenterX = viewport.centerX;
    coastLayerCenterY = viewport.centerY;
    coastLayerSeaLevel = seaLevel;
    coastLayerCellCount = model.cells.size();
  }

  private void drawCoastLayer(PGraphics g, RenderSettings s, float seaLevel) {
    HashSet<String> drawn = new HashSet<String>();
    int strokeCol = hsbColor(s.waterContourHue01, s.waterContourSat01, s.waterContourBri01, 1.0f);
    float thisHalfWeight = max(0.1f, s.waterContourSizePx) / viewport.zoom / 2.0f;
    g.strokeWeight(thisHalfWeight * 2.0f);
    g.stroke(strokeCol);
    g.strokeCap(drawRoundCaps ? PConstants.ROUND : PConstants.SQUARE);
    g.noFill();
    HashSet<String> capsDrawn = new HashSet<String>();
    model.ensureCellNeighborsComputed();
    for (int ci = 0; ci < model.cells.size(); ci++) {
      Cell c = model.cells.get(ci);
      if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
      boolean isWater = c.elevation < seaLevel;
      int vc = c.vertices.size();
      for (int e = 0; e < vc; e++) {
        PVector a = c.vertices.get(e);
        PVector b = c.vertices.get((e + 1) % vc);
        String key = undirectedEdgeKey(a, b);
        if (drawn.contains(key)) continue;
        boolean boundary = false;
        boolean nbIsWater = false;
        ArrayList<Integer> nbs = (ci < model.cellNeighbors.size()) ? model.cellNeighbors.get(ci) : null;
        if (nbs != null) {
          for (int nbIdx : nbs) {
            if (nbIdx < 0 || nbIdx >= model.cells.size()) continue;
            Cell nb = model.cells.get(nbIdx);
            if (nb == null || nb.vertices == null) continue;
            int nv = nb.vertices.size();
            boolean match = false;
            for (int j = 0; j < nv; j++) {
              PVector na = nb.vertices.get(j);
              PVector nbp = nb.vertices.get((j + 1) % nv);
              if ((model.distSq(a, na) < 1e-6f && model.distSq(b, nbp) < 1e-6f) ||
                  (model.distSq(a, nbp) < 1e-6f && model.distSq(b, na) < 1e-6f)) {
                nbIsWater = nb.elevation < seaLevel;
                boundary = isWater != nbIsWater;
                match = true;
                break;
              }
            }
            if (match) break;
          }
        }
        if (!boundary) continue;
        drawn.add(key);
        if (isWater || nbIsWater) {
          g.line(a.x, a.y, b.x, b.y);
          if (drawRoundCaps) {
            String ka = undirectedEdgeKey(a, a);
            String kb = undirectedEdgeKey(b, b);
            g.noStroke();
            g.fill(strokeCol);
            if (!capsDrawn.contains(ka)) {
              capsDrawn.add(ka);
              g.ellipse(a.x, a.y, thisHalfWeight * 2, thisHalfWeight * 2);
            }
            if (!capsDrawn.contains(kb)) {
              capsDrawn.add(kb);
              g.ellipse(b.x, b.y, thisHalfWeight * 2, thisHalfWeight * 2);
            }
            g.stroke(strokeCol);
          }
        }
      }
    }
  }

  private int zoneSettingsHash(RenderSettings s, int[] zoneCols) {
    int h = 19;
    h = 31 * h + round(s.zoneStrokeSatScale01 * 1000.0f);
    h = 31 * h + round(s.zoneStrokeBriScale01 * 1000.0f);
    h = 31 * h + round(s.zoneStrokeSizePx * 1000.0f);
    h = 31 * h + hashArray(zoneCols);
    h = 31 * h + (drawRoundCaps ? 1 : 0);
    h = 31 * h + ((model != null && model.cells != null) ? model.cells.size() : 0);
    h = 31 * h + ((model != null && model.zones != null) ? model.zones.size() : 0);
    return h;
  }

  private void ensureZoneLayer(PApplet app, RenderSettings s) {
    if (model == null || model.cells == null || model.cells.isEmpty() || model.zones == null) {
      zoneLayer = null;
      return;
    }
    if (app == null) return;
    int[] zoneStrokeCols = buildZoneStrokeColors(s);
    int targetW = (app.g != null) ? app.g.width : app.width;
    int targetH = (app.g != null) ? app.g.height : app.height;
    int hash = zoneSettingsHash(s, zoneStrokeCols);
    boolean sizeChanged = zoneLayer == null || zoneLayerW != targetW || zoneLayerH != targetH;
    boolean viewChanged = zoneLayer == null ||
                          abs(zoneLayerZoom - viewport.zoom) > 1e-4f ||
                          abs(zoneLayerCenterX - viewport.centerX) > 1e-4f ||
                          abs(zoneLayerCenterY - viewport.centerY) > 1e-4f;
    boolean settingsChanged = zoneLayer == null ||
                              zoneLayerHash != hash ||
                              zoneLayerCellCount != model.cells.size() ||
                              zoneLayerZoneCount != model.zones.size();

    if (sizeChanged) {
      zoneLayer = app.createGraphics(targetW, targetH, P2D);
      zoneLayerW = targetW;
      zoneLayerH = targetH;
      if (zoneLayer != null) {
        if (s.antialiasing) zoneLayer.smooth(8); else zoneLayer.noSmooth();
      }
    } else {
      if (zoneLayer != null) {
        if (s.antialiasing) zoneLayer.smooth(8); else zoneLayer.noSmooth();
      }
    }
    if (zoneLayer == null) return;
    if (!(sizeChanged || viewChanged || settingsChanged)) return;

    zoneLayer.beginDraw();
    zoneLayer.clear();
    zoneLayer.pushMatrix();
    zoneLayer.pushStyle();
    viewport.applyTransform(zoneLayer, zoneLayer.width, zoneLayer.height);
    float zoneW = max(0.1f, s.zoneStrokeSizePx) / viewport.zoom;
    drawZoneLayer(zoneLayer, zoneStrokeCols, zoneW);
    zoneLayer.popStyle();
    zoneLayer.popMatrix();
    zoneLayer.endDraw();

    zoneLayerHash = hash;
    zoneLayerZoom = viewport.zoom;
    zoneLayerCenterX = viewport.centerX;
    zoneLayerCenterY = viewport.centerY;
    zoneLayerCellCount = model.cells.size();
    zoneLayerZoneCount = model.zones.size();
  }

  private void drawZoneLayer(PGraphics g, int[] zoneStrokeCols, float zoneW) {
    if (model.cells == null || model.cells.isEmpty()) return;
    model.ensureCellNeighborsComputed();
    int n = model.cells.size();

    // zone membership per cell
    ArrayList<ArrayList<Integer>> zoneForCell = new ArrayList<ArrayList<Integer>>(n);
    for (int i = 0; i < n; i++) zoneForCell.add(new ArrayList<Integer>());
    if (model.zones != null) {
      for (int zi = 0; zi < model.zones.size(); zi++) {
        MapModel.MapZone z = model.zones.get(zi);
        if (z == null || z.cells == null) continue;
        for (int ci : z.cells) {
          if (ci < 0 || ci >= n) continue;
          ArrayList<Integer> list = zoneForCell.get(ci);
          if (!list.contains(zi)) list.add(zi);
        }
      }
    }

    float eps2 = 1e-6f;
    float laneGap = max(0.2f / viewport.zoom, zoneW * 0.4f);
    HashSet<String> drawn = new HashSet<String>();
    ArrayList<Integer> listA = new ArrayList<Integer>();
    ArrayList<Integer> listB = new ArrayList<Integer>();
    HashSet<String> capsDrawn = new HashSet<String>();

    class Lane {
      float width;
      int col;
      Lane(float w, int ccol) { width = w; col = ccol; }
    }

    for (int ci = 0; ci < n; ci++) {
      Cell c = model.cells.get(ci);
      if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
      ArrayList<Integer> zonesA = zoneForCell.get(ci);
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

        HashSet<Integer> setA = (zonesA != null) ? new HashSet<Integer>(zonesA) : new HashSet<Integer>();
        HashSet<Integer> setB = (zonesB != null) ? new HashSet<Integer>(zonesB) : new HashSet<Integer>();
        HashSet<Integer> uniqueA = new HashSet<Integer>(setA);
        uniqueA.removeAll(setB);
        HashSet<Integer> uniqueB = new HashSet<Integer>(setB);
        uniqueB.removeAll(setA);

        boolean hasDiff = !uniqueA.isEmpty() || !uniqueB.isEmpty();
        if (!hasDiff) { drawn.add(key); continue; }

        PVector cenA = model.cellCentroid(c);
        PVector mid = new PVector((a.x + b.x) * 0.5f, (a.y + b.y) * 0.5f);
        PVector edgeDir = new PVector(b.x - a.x, b.y - a.y);
        PVector nrm = new PVector(-edgeDir.y, edgeDir.x);
        float nLen = max(1e-6f, sqrt(nrm.x * nrm.x + nrm.y * nrm.y));
        nrm.mult(1.0f / nLen);
        if (cenA != null) {
          PVector toCenter = PVector.sub(cenA, mid);
          if (toCenter.dot(nrm) < 0) nrm.mult(-1);
        }

        ArrayList<Lane> lanesPos = new ArrayList<Lane>();
        ArrayList<Lane> lanesNeg = new ArrayList<Lane>();

        listA.clear(); listA.addAll(uniqueA); Collections.sort(listA);
        listB.clear(); listB.addAll(uniqueB); Collections.sort(listB);
        for (int zId : listA) {
          if (zId < 0 || zId >= model.zones.size()) continue;
          int colZ = (zoneStrokeCols != null && zId < zoneStrokeCols.length) ? zoneStrokeCols[zId] : -1;
          if (colZ != -1) lanesPos.add(new Lane(zoneW, colZ));
        }
        for (int zId : listB) {
          if (zId < 0 || zId >= model.zones.size()) continue;
          int colZ = (zoneStrokeCols != null && zId < zoneStrokeCols.length) ? zoneStrokeCols[zId] : -1;
          if (colZ != -1) lanesNeg.add(new Lane(zoneW, colZ));
        }

        Comparator<Lane> cmp = new Comparator<Lane>() {
          public int compare(Lane aL, Lane bL) { return Float.compare(bL.width, aL.width); }
        };
        Collections.sort(lanesPos, cmp);
        Collections.sort(lanesNeg, cmp);

        g.strokeCap(drawRoundCaps ? PConstants.ROUND : PConstants.SQUARE);
        g.strokeJoin(PConstants.ROUND);

        float offsetPos = 0;
        for (Lane l : lanesPos) {
          if (l.width <= 1e-4f) continue;
          float laneOff = offsetPos + l.width * 0.5f;
          g.stroke(l.col, 255);
          g.strokeWeight(l.width);
          float ax = a.x + nrm.x * laneOff;
          float ay = a.y + nrm.y * laneOff;
          float bx = b.x + nrm.x * laneOff;
          float by = b.y + nrm.y * laneOff;
          g.line(ax, ay, bx, by);
          if (drawRoundCaps) {
            float hw = l.width * 0.5f;
            g.noStroke();
            g.fill(l.col, 255);
            String ka = model.keyFor(ax, ay);
            String kb = model.keyFor(bx, by);
            if (!capsDrawn.contains(ka)) { capsDrawn.add(ka); g.ellipse(ax, ay, hw * 2, hw * 2); }
            if (!capsDrawn.contains(kb)) { capsDrawn.add(kb); g.ellipse(bx, by, hw * 2, hw * 2); }
            g.stroke(l.col, 255);
          }
          offsetPos += l.width + laneGap;
        }
        float offsetNeg = 0;
        for (Lane l : lanesNeg) {
          if (l.width <= 1e-4f) continue;
          float laneOff = offsetNeg + l.width * 0.5f;
          g.stroke(l.col, 255);
          g.strokeWeight(l.width);
          float ax = a.x - nrm.x * laneOff;
          float ay = a.y - nrm.y * laneOff;
          float bx = b.x - nrm.x * laneOff;
          float by = b.y - nrm.y * laneOff;
          g.line(ax, ay, bx, by);
          if (drawRoundCaps) {
            float hw = l.width * 0.5f;
            g.noStroke();
            g.fill(l.col, 255);
            String ka = model.keyFor(ax, ay);
            String kb = model.keyFor(bx, by);
            if (!capsDrawn.contains(ka)) { capsDrawn.add(ka); g.ellipse(ax, ay, hw * 2, hw * 2); }
            if (!capsDrawn.contains(kb)) { capsDrawn.add(kb); g.ellipse(bx, by, hw * 2, hw * 2); }
            g.stroke(l.col, 255);
          }
          offsetNeg += l.width + laneGap;
        }

        drawn.add(key);
      }
    }
  }

  private int biomeSettingsHash(RenderSettings s, int[] biomeCols) {
    int h = 23;
    h = 31 * h + round(s.biomeOutlineSizePx * 1000.0f);
    h = 31 * h + hashArray(biomeCols);
    h = 31 * h + (drawRoundCaps ? 1 : 0);
    h = 31 * h + ((model != null && model.cells != null) ? model.cells.size() : 0);
    h = 31 * h + ((model != null && model.biomeTypes != null) ? model.biomeTypes.size() : 0);
    return h;
  }

  private int elevationLightSettingsHash(RenderSettings s) {
    int h = 29;
    h = 31 * h + round(s.elevationLightAzimuthDeg * 100.0f);
    h = 31 * h + round(s.elevationLightAltitudeDeg * 100.0f);
    h = 31 * h + round(s.elevationLightAlpha01 * 1000.0f);
    h = 31 * h + round(s.elevationLightDitherPx * 1000.0f);
    h = 31 * h + ((model != null && model.cells != null) ? model.cells.size() : 0);
    return h;
  }

  private void ensureBiomeLayer(PApplet app, RenderSettings s) {
    if (model == null || model.cells == null || model.cells.isEmpty() || model.biomeTypes == null) {
      biomeLayer = null;
      return;
    }
    if (app == null) return;
    int[] biomeScaledCols = buildBiomeScaledColors(s);
    int targetW = (app.g != null) ? app.g.width : app.width;
    int targetH = (app.g != null) ? app.g.height : app.height;
    int hash = biomeSettingsHash(s, biomeScaledCols);
    boolean sizeChanged = biomeLayer == null || biomeLayerW != targetW || biomeLayerH != targetH;
    boolean viewChanged = biomeLayer == null ||
                          abs(biomeLayerZoom - viewport.zoom) > 1e-4f ||
                          abs(biomeLayerCenterX - viewport.centerX) > 1e-4f ||
                          abs(biomeLayerCenterY - viewport.centerY) > 1e-4f;
    boolean settingsChanged = biomeLayer == null ||
                              biomeLayerHash != hash ||
                              biomeLayerCellCount != model.cells.size() ||
                              biomeLayerBiomeCount != model.biomeTypes.size();

    if (sizeChanged) {
      biomeLayer = app.createGraphics(targetW, targetH, P2D);
      biomeLayerW = targetW;
      biomeLayerH = targetH;
      if (biomeLayer != null) {
        if (s.antialiasing) biomeLayer.smooth(8); else biomeLayer.noSmooth();
      }
    } else {
      if (biomeLayer != null) {
        if (s.antialiasing) biomeLayer.smooth(8); else biomeLayer.noSmooth();
      }
    }
    if (biomeLayer == null) return;
    if (!(sizeChanged || viewChanged || settingsChanged)) return;

    biomeLayer.beginDraw();
    biomeLayer.clear();
    biomeLayer.pushMatrix();
    biomeLayer.pushStyle();
    viewport.applyTransform(biomeLayer, biomeLayer.width, biomeLayer.height);
    drawBiomeLayer(biomeLayer, s, biomeScaledCols);
    biomeLayer.popStyle();
    biomeLayer.popMatrix();
    biomeLayer.endDraw();

    biomeLayerHash = hash;
    biomeLayerZoom = viewport.zoom;
    biomeLayerCenterX = viewport.centerX;
    biomeLayerCenterY = viewport.centerY;
    biomeLayerCellCount = model.cells.size();
    biomeLayerBiomeCount = model.biomeTypes.size();
  }

  private void drawBiomeLayer(PGraphics g, RenderSettings s, int[] biomeScaledCols) {
    if (model.cells == null || model.cells.isEmpty()) return;
    model.ensureCellNeighborsComputed();
    int n = model.cells.size();
    float eps2 = 1e-6f;
    float biomeW = max(0.1f, s.biomeOutlineSizePx) / viewport.zoom;
    float laneGap = max(0.2f / viewport.zoom, (2.0f / viewport.zoom) * 0.4f);
    HashSet<String> drawn = new HashSet<String>();
    HashSet<String> capsDrawn = new HashSet<String>();

    class Lane {
      float width;
      int col;
      Lane(float w, int ccol) { width = w; col = ccol; }
    }

    for (int ci = 0; ci < n; ci++) {
      Cell c = model.cells.get(ci);
      if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
      int vc = c.vertices.size();
      for (int e = 0; e < vc; e++) {
        PVector a = c.vertices.get(e);
        PVector b = c.vertices.get((e + 1) % vc);
        String key = undirectedEdgeKey(a, b);
        if (drawn.contains(key)) continue;

        int biomeA = c.biomeId;
        int biomeB = biomeA;
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
                biomeB = nb.biomeId;
                matched = true;
                break;
              }
            }
            if (matched) break;
          }
        }

        boolean biomeDiff = biomeA != biomeB;
        if (!biomeDiff) { drawn.add(key); continue; }

        PVector cenA = model.cellCentroid(c);
        PVector mid = new PVector((a.x + b.x) * 0.5f, (a.y + b.y) * 0.5f);
        PVector edgeDir = new PVector(b.x - a.x, b.y - a.y);
        PVector nrm = new PVector(-edgeDir.y, edgeDir.x);
        float nLen = max(1e-6f, sqrt(nrm.x * nrm.x + nrm.y * nrm.y));
        nrm.mult(1.0f / nLen);
        if (cenA != null) {
          PVector toCenter = PVector.sub(cenA, mid);
          if (toCenter.dot(nrm) < 0) nrm.mult(-1);
        }

        ArrayList<Lane> lanesPos = new ArrayList<Lane>();
        ArrayList<Lane> lanesNeg = new ArrayList<Lane>();
        if (biomeA >= 0 && biomeScaledCols != null && biomeA < biomeScaledCols.length) {
          int col = biomeScaledCols[biomeA];
          if (col != -1) lanesPos.add(new Lane(biomeW, col));
        }
        if (biomeB >= 0 && biomeScaledCols != null && biomeB < biomeScaledCols.length) {
          int col = biomeScaledCols[biomeB];
          if (col != -1) lanesNeg.add(new Lane(biomeW, col));
        }

        Comparator<Lane> cmp = new Comparator<Lane>() {
          public int compare(Lane aL, Lane bL) { return Float.compare(bL.width, aL.width); }
        };
        Collections.sort(lanesPos, cmp);
        Collections.sort(lanesNeg, cmp);

        g.strokeCap(drawRoundCaps ? PConstants.ROUND : PConstants.SQUARE);
        g.strokeJoin(PConstants.ROUND);

        float offsetPos = 0;
        for (Lane l : lanesPos) {
          if (l.width <= 1e-4f) continue;
          float laneOff = offsetPos + l.width * 0.5f;
          g.stroke(l.col, 255);
          g.strokeWeight(l.width);
          float ax = a.x + nrm.x * laneOff;
          float ay = a.y + nrm.y * laneOff;
          float bx = b.x + nrm.x * laneOff;
          float by = b.y + nrm.y * laneOff;
          g.line(ax, ay, bx, by);
          if (drawRoundCaps) {
            float hw = l.width * 0.5f;
            g.noStroke();
            g.fill(l.col, 255);
            String ka = model.keyFor(ax, ay);
            String kb = model.keyFor(bx, by);
            if (!capsDrawn.contains(ka)) { capsDrawn.add(ka); g.ellipse(ax, ay, hw * 2, hw * 2); }
            if (!capsDrawn.contains(kb)) { capsDrawn.add(kb); g.ellipse(bx, by, hw * 2, hw * 2); }
            g.stroke(l.col, 255);
          }
          offsetPos += l.width + laneGap;
        }
        float offsetNeg = 0;
        for (Lane l : lanesNeg) {
          if (l.width <= 1e-4f) continue;
          float laneOff = offsetNeg + l.width * 0.5f;
          g.stroke(l.col, 255);
          g.strokeWeight(l.width);
          float ax = a.x - nrm.x * laneOff;
          float ay = a.y - nrm.y * laneOff;
          float bx = b.x - nrm.x * laneOff;
          float by = b.y - nrm.y * laneOff;
          g.line(ax, ay, bx, by);
          if (drawRoundCaps) {
            float hw = l.width * 0.5f;
            g.noStroke();
            g.fill(l.col, 255);
            String ka = model.keyFor(ax, ay);
            String kb = model.keyFor(bx, by);
            if (!capsDrawn.contains(ka)) { capsDrawn.add(ka); g.ellipse(ax, ay, hw * 2, hw * 2); }
            if (!capsDrawn.contains(kb)) { capsDrawn.add(kb); g.ellipse(bx, by, hw * 2, hw * 2); }
            g.stroke(l.col, 255);
          }
          offsetNeg += l.width + laneGap;
        }

        drawn.add(key);
      }
    }
  }

  private void ensureElevationLightLayer(PApplet app, RenderSettings s, float seaLevel) {
    if (model == null || model.cells == null || model.cells.isEmpty()) {
      elevationLightLayer = null;
      return;
    }
    if (app == null) return;
    int targetW = (app.g != null) ? app.g.width : app.width;
    int targetH = (app.g != null) ? app.g.height : app.height;
    int hash = elevationLightSettingsHash(s);
    boolean sizeChanged = elevationLightLayer == null || elevationLightW != targetW || elevationLightH != targetH;
    boolean viewChanged = elevationLightLayer == null ||
                          abs(elevationLightZoom - viewport.zoom) > 1e-4f ||
                          abs(elevationLightCenterX - viewport.centerX) > 1e-4f ||
                          abs(elevationLightCenterY - viewport.centerY) > 1e-4f;
    boolean settingsChanged = elevationLightLayer == null ||
                              elevationLightHashVal != hash ||
                              abs(elevationLightSeaLevel - seaLevel) > 1e-6f ||
                              elevationLightCellCount != model.cells.size() ||
                              currentTool == Tool.EDIT_ELEVATION;

    if (sizeChanged) {
      elevationLightLayer = app.createGraphics(targetW, targetH, P2D);
      elevationLightW = targetW;
      elevationLightH = targetH;
      if (elevationLightLayer != null) {
        if (s.antialiasing) elevationLightLayer.smooth(8); else elevationLightLayer.noSmooth();
      }
    } else {
      if (elevationLightLayer != null) {
        if (s.antialiasing) elevationLightLayer.smooth(8); else elevationLightLayer.noSmooth();
      }
    }
    if (elevationLightLayer == null) return;
    if (!(sizeChanged || viewChanged || settingsChanged)) return;

    elevationLightLayer.beginDraw();
    elevationLightLayer.clear();
    elevationLightLayer.background(255);
    elevationLightLayer.pushMatrix();
    elevationLightLayer.pushStyle();
    viewport.applyTransform(elevationLightLayer, elevationLightLayer.width, elevationLightLayer.height);
    drawElevationLightLayer(elevationLightLayer, s, seaLevel);
    elevationLightLayer.popStyle();
    elevationLightLayer.popMatrix();
    elevationLightLayer.endDraw();

    float dither = max(0, s.elevationLightDitherPx);
    if (dither > 1e-3f) {
      applyLightDither(elevationLightLayer, dither);
    }

    elevationLightHashVal = hash;
    elevationLightZoom = viewport.zoom;
    elevationLightCenterX = viewport.centerX;
    elevationLightCenterY = viewport.centerY;
    elevationLightSeaLevel = seaLevel;
    elevationLightCellCount = model.cells.size();
  }

  private void drawElevationLightLayer(PGraphics g, RenderSettings s, float seaLevel) {
    float az = radians(s.elevationLightAzimuthDeg);
    float alt = radians(s.elevationLightAltitudeDeg);
    PVector lightDir = new PVector(cos(alt) * cos(az), cos(alt) * sin(az), sin(alt));
    lightDir.normalize();
    g.noStroke();
    for (int ci = 0; ci < model.cells.size(); ci++) {
      Cell c = model.cells.get(ci);
      if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
      if (c.elevation < seaLevel) continue;
      float light = ElevationRenderer.computeLightForCell(model, ci, lightDir);
      float a = s.elevationLightAlpha01 * (1.0f - light);
      if (a <= 1e-4f) continue;
      float shade = constrain(255.0f - a * 255.0f, 0, 255); // 255=no change in multiply, darker when lower
      g.fill(shade);
      drawPoly(g, c.vertices);
    }
  }

  private void applyLightDither(PGraphics g, float radius) {
    if (g == null || radius <= 1e-4f) return;
    g.loadPixels();
    int w = g.width;
    int h = g.height;
    int total = w * h;
    if (total <= 0) return;
    int swaps = total / 2;
    for (int i = 0; i < swaps; i++) {
      int idx = (int)random(total);
      int x = idx % w;
      int y = idx / w;
      int dx = round(random(-radius, radius));
      int dy = round(random(-radius, radius));
      int x2 = constrain(x + dx, 0, w - 1);
      int y2 = constrain(y + dy, 0, h - 1);
      int idx2 = y2 * w + x2;
      int tmp = g.pixels[idx];
      g.pixels[idx] = g.pixels[idx2];
      g.pixels[idx2] = tmp;
    }
    g.updatePixels();
  }

  PImage generateNoiseTexture() {
    PImage im = new PImage(1000, 1000);
    im.loadPixels();
    for (int x = 0; x < im.width; x++) {
      for (int y = 0; y < im.height; y++) {
        im.pixels[y * im.width + x] = color(random(0x100));
      }
    }
    im.updatePixels();
    return im;
  }

  private int[] buildBiomeScaledColors(RenderSettings s) {
    if (model == null || model.biomeTypes == null || model.biomeTypes.isEmpty()) return null;
    int n = model.biomeTypes.size();
    float satScale = (s != null) ? s.biomeSatScale01 : 1.0f;
    float briScale = (s != null) ? s.biomeBriScale01 : 1.0f;
    boolean needRebuild = false;
    if (cachedBiomeScaledColors == null || cachedBiomeScaledColors.length != n) needRebuild = true;
    if (cachedBiomeSrcCols == null || cachedBiomeSrcCols.length != n) needRebuild = true;
    if (!needRebuild && (abs(cachedBiomeSatScale - satScale) > 1e-6f || abs(cachedBiomeBriScale - briScale) > 1e-6f)) needRebuild = true;
    if (!needRebuild) {
      for (int i = 0; i < n; i++) {
        ZoneType zt = model.biomeTypes.get(i);
        int src = (zt != null) ? zt.col : -1;
        if (cachedBiomeSrcCols[i] != src) { needRebuild = true; break; }
      }
    }
    if (!needRebuild) return cachedBiomeScaledColors;

    cachedBiomeScaledColors = new int[n];
    cachedBiomeSrcCols = new int[n];
    cachedBiomeSatScale = satScale;
    cachedBiomeBriScale = briScale;
    for (int i = 0; i < n; i++) {
      ZoneType zt = model.biomeTypes.get(i);
      if (zt == null) {
        cachedBiomeScaledColors[i] = -1;
        cachedBiomeSrcCols[i] = -1;
        continue;
      }
      cachedBiomeSrcCols[i] = zt.col;
      float[] hsb = new float[3];
      rgbToHSB01(zt.col, hsb);
      float sat = constrain(hsb[1] * satScale, 0, 1);
      float bri = constrain(hsb[2] * briScale, 0, 1);
      cachedBiomeScaledColors[i] = hsb01ToRGB(hsb[0], sat, bri);
    }
    return cachedBiomeScaledColors;
  }

  private int[] buildZoneStrokeColors(RenderSettings s) {
    if (model == null || model.zones == null || model.zones.isEmpty() || s == null) return null;
    int n = model.zones.size();
    float satScale = s.zoneStrokeSatScale01;
    float briScale = s.zoneStrokeBriScale01;
    boolean needRebuild = false;
    if (cachedZoneStrokeColors == null || cachedZoneStrokeColors.length != n) needRebuild = true;
    if (cachedZoneSrcCols == null || cachedZoneSrcCols.length != n) needRebuild = true;
    if (!needRebuild && (abs(cachedZoneSatScale - satScale) > 1e-6f || abs(cachedZoneBriScale - briScale) > 1e-6f)) needRebuild = true;
    if (!needRebuild) {
      for (int i = 0; i < n; i++) {
        MapModel.MapZone z = model.zones.get(i);
        int src = (z != null) ? z.col : -1;
        if (cachedZoneSrcCols[i] != src) { needRebuild = true; break; }
      }
    }
    if (!needRebuild) return cachedZoneStrokeColors;

    cachedZoneStrokeColors = new int[n];
    cachedZoneSrcCols = new int[n];
    cachedZoneSatScale = satScale;
    cachedZoneBriScale = briScale;
    for (int i = 0; i < n; i++) {
      MapModel.MapZone z = model.zones.get(i);
      if (z == null) {
        cachedZoneStrokeColors[i] = -1;
        cachedZoneSrcCols[i] = -1;
        continue;
      }
      cachedZoneSrcCols[i] = z.col;
      float[] hsb = new float[3];
      rgbToHSB01(z.col, hsb);
      float sat = constrain(hsb[1] * satScale, 0, 1);
      float bri = constrain(hsb[2] * briScale, 0, 1);
      cachedZoneStrokeColors[i] = hsb01ToRGB(hsb[0], sat, bri);
    }
    return cachedZoneStrokeColors;
  }

}
