
static class ElevationRenderer {
  static void drawOverlay(MapModel model, PApplet app, float seaLevel, boolean showElevationContours,
                          boolean drawWater, boolean drawElevation, boolean showWaterContours,
                          boolean useLighting, float lightAzimuthDeg, float lightAltitudeDeg, int quantSteps) {
    if (model == null || model.cells == null) return;
    app.pushStyle();
    app.noStroke();

    PVector lightDir = null;
    if (useLighting) {
      float az = radians(lightAzimuthDeg);
      float alt = radians(lightAltitudeDeg);
      lightDir = new PVector(cos(alt) * cos(az), cos(alt) * sin(az), sin(alt));
      lightDir.normalize();
    }

    int cellCount = model.cells.size();
    for (int ci = 0; ci < cellCount; ci++) {
      Cell c = model.cells.get(ci);
      if (c.vertices == null || c.vertices.size() < 3) continue;
      float h = c.elevation;
      PVector slope = null;
      PVector cen = model.cellCentroid(c);
      float light = 1.0f;
      if (useLighting && lightDir != null) {
        slope = estimateCellSlope(model, ci);
        light = lightFromSlope(slope, lightDir);
      }
      if (drawElevation) {
        float shade = constrain((h + 0.5f), 0, 1); // center on 0
        float litShade = constrain(shade * light, 0, 1);
        float baseShade = litShade;
        if (quantSteps > 1) {
          float levels = quantSteps - 1;
          baseShade = round(baseShade * levels) / levels;
        }
        app.beginShape();
        for (PVector v : c.vertices) {
          float directional = 0;
          if (slope != null) {
            float hDelta = slope.x * (v.x - cen.x) + slope.y * (v.y - cen.y);
            directional = constrain(hDelta * 1.2f, -0.14f, 0.14f);
          }
          float grain = (app.noise(v.x * 18.0f, v.y * 18.0f) - 0.5f) * 0.06f;
          float vShade = constrain(baseShade + directional + grain, 0, 1);
          int col = app.color(vShade * 255);
          app.fill(col, 150);
          app.vertex(v.x, v.y);
        }
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
      MapModel.ContourGrid grid = model.sampleElevationGrid(cols, rows, seaLevel);
      float minElev = grid.min;
      float maxElev = grid.max;

      if (showElevationContours) {
        float range = max(1e-4f, maxElev - seaLevel);
        float step = max(0.02f, range / 10.0f);
        float start = ceil(seaLevel / step) * step;
        int strokeCol = app.color(50, 50, 50, 180);
        model.drawContourSet(app, grid, start, maxElev, step, strokeCol);
      }

      if (showWaterContours && drawWater) {
        float minWater = minElev;
        if (minWater < seaLevel - 1e-4f) {
          float depthRange = seaLevel - minWater;
          float step = max(0.02f, depthRange / 5.0f);
          float start = seaLevel - step;
          int strokeCol = app.color(30, 70, 140, 170);
          model.drawContourSet(app, grid, start, minWater, -step, strokeCol);
        }
      }
    }
    app.popStyle();
  }

  private static PVector estimateCellSlope(MapModel model, int idx) {
    PVector slope = new PVector(0, 0);
    if (model == null || idx < 0 || idx >= model.cells.size()) return slope;
    ArrayList<Integer> nbs = (idx < model.cellNeighbors.size()) ? model.cellNeighbors.get(idx) : null;
    if (nbs == null || nbs.isEmpty()) return slope;

    Cell c = model.cells.get(idx);
    PVector cen = model.cellCentroid(c);

    for (int nbIdx : nbs) {
      if (nbIdx < 0 || nbIdx >= model.cells.size()) continue;
      Cell nb = model.cells.get(nbIdx);
      PVector ncen = model.cellCentroid(nb);
      float dx = ncen.x - cen.x;
      float dy = ncen.y - cen.y;
      float dist = sqrt(dx * dx + dy * dy);
      if (dist < 1e-6f) continue;
      float dh = nb.elevation - c.elevation;
      float w = 1.0f / dist;
      slope.x += dh * (dx / dist) * w;
      slope.y += dh * (dy / dist) * w;
    }
    return slope;
  }

  private static float lightFromSlope(PVector slope, PVector lightDir) {
    if (lightDir == null) return 1.0f;
    PVector normal = new PVector(-slope.x, -slope.y, 1.0f);
    if (normal.magSq() < 1e-8f) normal.set(0, 0, 1);
    else normal.normalize();

    float d = max(0, normal.x * lightDir.x + normal.y * lightDir.y + normal.z * lightDir.z);
    float ambient = 0.35f;
    return constrain(ambient + (1.0f - ambient) * d, 0, 1);
  }

  static float computeLightForCell(MapModel model, int idx, PVector lightDir) {
    PVector slope = estimateCellSlope(model, idx);
    return lightFromSlope(slope, lightDir);
  }
}
