// Export/render output helpers split from Main.pde to keep the file size manageable.

String exportPng() {
  long tExportStart = millis();
  // Compute inner world rect from render padding
  float worldW = mapModel.maxX - mapModel.minX;
  float worldH = mapModel.maxY - mapModel.minY;
  if (worldW <= 0 || worldH <= 0) return "Failed: invalid world bounds";

  float safePad = constrain(renderPaddingPct, 0, 0.49f); // avoid collapsing to zero
  float padX = max(0, safePad) * worldW;
  float padY = max(0, safePad) * worldH;
  float innerWX = mapModel.minX + padX;
  float innerWY = mapModel.minY + padY;
  float innerWW = worldW - padX * 2;
  float innerWH = worldH - padY * 2;
  if (innerWW <= 1e-6f || innerWH <= 1e-6f) return "Failed: export padding too large";

  // Match export buffer aspect to the cropped world so we crop instead of showing letterbox bars.
  float innerAspect = innerWW / innerWH;
  float safeScale = constrain(exportScale, 0.1f, 8.0f);
  int pxH = max(1, round(max(1, height) * safeScale));
  int pxW = max(1, round(pxH * innerAspect));
  if (pxW <= 0 || pxH <= 0) return "Failed: export size collapsed";
  PGraphics g = null;
  try {
    g = createGraphics(pxW, pxH, P2D);
  } catch (Exception ignored) {}
  if (g == null) {
    try {
      g = createGraphics(pxW, pxH, JAVA2D);
    } catch (Exception ignored) {}
  }
  if (g == null) return "Failed to allocate buffer";

  float prevCenterX = viewport.centerX;
  float prevCenterY = viewport.centerY;
  float prevZoom = viewport.zoom;

  // Fit inner world rect to buffer while preserving aspect
  float zoomX = g.width / innerWW;
  float zoomY = g.height / innerWH;
  float newZoom = max(zoomX, zoomY); // fill buffer; slight overzoom is fine (cropped)
  viewport.centerX = innerWX + innerWW * 0.5f;
  viewport.centerY = innerWY + innerWH * 0.5f;
  viewport.zoom = newZoom;

  // Ensure distance/elevation grids are ready before rendering/exporting
  long tPrepStart = millis();
  triggerRenderPrerequisites();
  long tPrepEnd = millis();

  renderingForExport = true;
  g.beginDraw();
  g.background(245);
  // Temporarily redirect drawing to offscreen buffer
  PGraphics prev = this.g;
  this.g = g;
  pushMatrix();
  viewport.applyTransform(g, g.width, g.height);
  drawRenderView(this);
  popMatrix();
  this.g = prev;
  g.endDraw();
  long tFirstPassEnd = millis();

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
  }
  long tSecondPassEnd = millis();

  // Restore viewport
  viewport.centerX = prevCenterX;
  viewport.centerY = prevCenterY;
  viewport.zoom = prevZoom;

  String dir = "exports";
  java.io.File folder = new java.io.File(dir);
  folder.mkdirs();
  String ts = nf(year(), 4, 0) + nf(month(), 2, 0) + nf(day(), 2, 0) + "_" +
              nf(hour(), 2, 0) + nf(minute(), 2, 0) + nf(second(), 2, 0);
  String path = dir + java.io.File.separator + "map_" + ts + ".png";
  g.save(path);

  long tExportEnd = millis();
  println("Export timing ms: prep=" + (tPrepEnd - tPrepStart) +
          " firstPass=" + (tFirstPassEnd - tPrepEnd) +
          " secondPass=" + (tSecondPassEnd - tFirstPassEnd) +
          " total=" + (tExportEnd - tExportStart));
  return path;
}

String exportSvg() {
  // Compute inner world rect from render padding
  float worldW = mapModel.maxX - mapModel.minX;
  float worldH = mapModel.maxY - mapModel.minY;
  if (worldW <= 0 || worldH <= 0) return "Failed: invalid world bounds";

  float safePad = constrain(renderPaddingPct, 0, 0.49f);
  float padX = max(0, safePad) * worldW;
  float padY = max(0, safePad) * worldH;
  float innerWX = mapModel.minX + padX;
  float innerWY = mapModel.minY + padY;
  float innerWW = worldW - padX * 2;
  float innerWH = worldH - padY * 2;
  if (innerWW <= 1e-6f || innerWH <= 1e-6f) return "Failed: export padding too large";

  float innerAspect = innerWW / innerWH;
  float safeScale = constrain(exportScale, 0.1f, 8.0f);
  int pxH = max(1, round(max(1, height) * safeScale));
  int pxW = max(1, round(pxH * innerAspect));
  if (pxW <= 0 || pxH <= 0) return "Failed: export size collapsed";

  // Helpers
  float scaleX = pxW / innerWW;
  float scaleY = pxH / innerWH;
  java.text.DecimalFormat df = new java.text.DecimalFormat("0.###");
  java.util.function.Function<Float, String> fmt = (Float v) -> df.format(v);
  java.util.function.Function<String, String> esc = (String v) -> {
    if (v == null) return "";
    return v.replace("&", "&amp;").replace("<", "&lt;").replace("\"", "&quot;");
  };
  java.util.function.Function<Integer, String> toHex = (Integer rgb) -> {
    int r = (rgb >> 16) & 0xFF;
    int g = (rgb >> 8) & 0xFF;
    int b = rgb & 0xFF;
    return String.format("#%02X%02X%02X", r, g, b);
  };
  java.util.function.Function<PVector, PVector> worldToSvg = (PVector w) -> {
    return new PVector((w.x - innerWX) * scaleX, (w.y - innerWY) * scaleY);
  };
  float[] hsbScratch = new float[3];

  RenderSettings s = renderSettings;
  int landRgb = hsb01ToARGB(s.landHue01, s.landSat01, s.landBri01, 1.0f);
  int waterRgb = hsb01ToARGB(s.waterHue01, s.waterSat01, s.waterBri01, 1.0f);
  String landHex = toHex.apply(landRgb);
  String waterHex = toHex.apply(waterRgb);

  StringBuilder sb = new StringBuilder();
  sb.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
  sb.append("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"").append(pxW)
    .append("\" height=\"").append(pxH).append("\" viewBox=\"0 0 ")
    .append(pxW).append(" ").append(pxH).append("\">\n");
  sb.append("  <style>text{font-family:sans-serif;fill:#000;} .water{fill:")
    .append(waterHex).append(";}</style>\n");

  // Background layer
  sb.append("  <g id=\"background\">\n");
  sb.append("    <rect width=\"").append(pxW).append("\" height=\"").append(pxH)
    .append("\" fill=\"").append(landHex).append("\" />\n");
  sb.append("  </g>\n");

  // Water fill (no stroke)
  sb.append("  <g id=\"water\">\n");
  if (mapModel.cells != null) {
    for (int ci = 0; ci < mapModel.cells.size(); ci++) {
      Cell c = mapModel.cells.get(ci);
      if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
      if (c.elevation >= seaLevel) continue;
      StringBuilder path = new StringBuilder();
      for (int i = 0; i < c.vertices.size(); i++) {
        PVector v = worldToSvg.apply(c.vertices.get(i));
        path.append((i == 0) ? "M " : " L ");
        path.append(fmt.apply(v.x)).append(" ").append(fmt.apply(v.y));
      }
      path.append(" Z");
      sb.append("    <path d=\"").append(path.toString()).append("\" fill=\"").append(waterHex)
        .append("\" stroke=\"none\" class=\"water\" data-cell-id=\"").append(ci).append("\"/>\n");
    }
  }
  sb.append("  </g>\n");

  // Biome fills (no stroke)
  sb.append("  <g id=\"biomes\">\n");
  boolean drawBiomes = mapModel.cells != null && mapModel.biomeTypes != null && mapModel.biomeTypes.size() > 0 &&
                       (s.biomeFillAlpha01 > 1e-4f || s.biomeUnderwaterAlpha01 > 1e-4f);
  if (drawBiomes) {
    for (int ci = 0; ci < mapModel.cells.size(); ci++) {
      Cell c = mapModel.cells.get(ci);
      if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
      boolean isWater = c.elevation < seaLevel;
      float alpha = isWater ? s.biomeUnderwaterAlpha01 : s.biomeFillAlpha01;
      if (alpha <= 1e-4f) continue;
      if (c.biomeId < 0 || c.biomeId >= mapModel.biomeTypes.size()) continue;
      ZoneType zt = mapModel.biomeTypes.get(c.biomeId);
      if (zt == null) continue;
      rgbToHSB01(zt.col, hsbScratch);
      hsbScratch[1] = constrain(hsbScratch[1] * s.biomeSatScale01, 0, 1);
      hsbScratch[2] = constrain(hsbScratch[2] * s.biomeBriScale01, 0, 1);
      int rgb = hsb01ToARGB(hsbScratch[0], hsbScratch[1], hsbScratch[2], 1.0f);
      String fill = toHex.apply(rgb);
      StringBuilder path = new StringBuilder();
      for (int i = 0; i < c.vertices.size(); i++) {
        PVector v = worldToSvg.apply(c.vertices.get(i));
        path.append((i == 0) ? "M " : " L ");
        path.append(fmt.apply(v.x)).append(" ").append(fmt.apply(v.y));
      }
      path.append(" Z");
      sb.append("    <path d=\"").append(path.toString()).append("\" fill=\"").append(fill)
        .append("\" fill-opacity=\"").append(fmt.apply(alpha)).append("\" stroke=\"none\" class=\"biome biome-")
        .append(c.biomeId).append("\" data-biome-id=\"").append(c.biomeId).append("\" data-cell-id=\"")
        .append(ci).append("\"/>\n");
    }
  }
  sb.append("  </g>\n");

  // Borders layer (world bounds box)
  sb.append("  <g id=\"borders\">\n");
  sb.append("    <rect x=\"0\" y=\"0\" width=\"").append(pxW).append("\" height=\"").append(pxH)
    .append("\" fill=\"none\" stroke=\"#000\" stroke-width=\"1\"/>\n");
  sb.append("  </g>\n");

  // Zones (stroke-only along zone boundaries) when enabled
  sb.append("  <g id=\"zones\">\n");
  if (s.zoneStrokeAlpha01 > 1e-4f && mapModel.zones != null && mapModel.cells != null) {
    for (int zi = 0; zi < mapModel.zones.size(); zi++) {
      MapModel.MapZone z = mapModel.zones.get(zi);
      if (z == null || z.cells == null) continue;
      rgbToHSB01(z.col, hsbScratch);
      hsbScratch[1] = constrain(hsbScratch[1] * s.zoneStrokeSatScale01, 0, 1);
      hsbScratch[2] = constrain(hsbScratch[2] * s.zoneStrokeBriScale01, 0, 1);
      String stroke = toHex.apply(hsb01ToARGB(hsbScratch[0], hsbScratch[1], hsbScratch[2], 1.0f));
      for (int ci : z.cells) {
        if (ci < 0 || ci >= mapModel.cells.size()) continue;
        Cell c = mapModel.cells.get(ci);
        if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
        StringBuilder path = new StringBuilder();
        for (int i = 0; i < c.vertices.size(); i++) {
          PVector v = worldToSvg.apply(c.vertices.get(i));
          path.append((i == 0) ? "M " : " L ");
          path.append(fmt.apply(v.x)).append(" ").append(fmt.apply(v.y));
        }
        path.append(" Z");
        sb.append("    <path d=\"").append(path.toString()).append("\" fill=\"none\" stroke=\"").append(stroke)
          .append("\" stroke-width=\"1\" stroke-linejoin=\"round\" stroke-linecap=\"round\" stroke-opacity=\"")
          .append(fmt.apply(s.zoneStrokeAlpha01)).append("\" class=\"zone zone-").append(zi)
          .append("\" data-zone-id=\"").append(zi).append("\" data-comment=\"").append(esc.apply(z.comment != null ? z.comment : "")).append("\"/>\n");
      }
    }
  }
  sb.append("  </g>\n");

  // Coastline stroke (immediate coast)
  sb.append("  <g id=\"coast\">\n");
  ArrayList<PVector[]> coastSegs = mapModel.collectCoastSegments(seaLevel);
  for (PVector[] seg : coastSegs) {
    if (seg == null || seg.length != 2) continue;
    PVector a = worldToSvg.apply(seg[0]);
    PVector b = worldToSvg.apply(seg[1]);
    sb.append("    <line x1=\"").append(fmt.apply(a.x)).append("\" y1=\"").append(fmt.apply(a.y))
      .append("\" x2=\"").append(fmt.apply(b.x)).append("\" y2=\"").append(fmt.apply(b.y))
      .append("\" stroke=\"").append(waterHex).append("\" stroke-width=\"1\" stroke-linecap=\"round\" class=\"coast\"/>\n");
  }
  sb.append("  </g>\n");

  // Paths layer
  sb.append("  <g id=\"paths\">\n");
  if (s.showPaths && mapModel.paths != null) {
    for (int pi = 0; pi < mapModel.paths.size(); pi++) {
      Path p = mapModel.paths.get(pi);
      if (p == null || p.routes == null || p.routes.isEmpty()) continue;
      int typeCount = (mapModel.pathTypes != null) ? mapModel.pathTypes.size() : 0;
      int typeId = constrain(p.typeId, 0, max(0, typeCount - 1));
      int col = (mapModel.pathTypes != null && typeId >= 0 && typeId < typeCount)
        ? mapModel.pathTypes.get(typeId).col : color(80);
      float wPx = (mapModel.pathTypes != null && typeId >= 0 && typeId < typeCount)
        ? mapModel.pathTypes.get(typeId).weightPx : 2.0f;
      String stroke = toHex.apply(col);
      String name = (p.name != null && p.name.length() > 0) ? p.name : "Path";
      for (int ri = 0; ri < p.routes.size(); ri++) {
        ArrayList<PVector> route = p.routes.get(ri);
        if (route == null || route.size() < 2) continue;
        StringBuilder pts = new StringBuilder();
        for (PVector v : route) {
          PVector spt = worldToSvg.apply(v);
          if (pts.length() > 0) pts.append(" ");
          pts.append(fmt.apply(spt.x)).append(",").append(fmt.apply(spt.y));
        }
        sb.append("    <polyline points=\"").append(pts.toString()).append("\" fill=\"none\" stroke=\"")
          .append(stroke).append("\" stroke-width=\"").append(fmt.apply(wPx))
          .append("\" stroke-linecap=\"round\" stroke-linejoin=\"round\" class=\"path type-")
          .append(typeId).append("\" data-type-id=\"").append(typeId)
          .append("\" data-path-id=\"").append(pi).append("\" data-name=\"")
          .append(esc.apply(name)).append("\" data-comment=\"").append(esc.apply(p.comment != null ? p.comment : ""))
          .append("\"/>\n");
      }
    }
  }
  sb.append("  </g>\n");

  // Structures layer
  sb.append("  <g id=\"structures\">\n");
  if (s.showStructures && mapModel.structures != null) {
    for (int si = 0; si < mapModel.structures.size(); si++) {
      Structure st = mapModel.structures.get(si);
      if (st == null) continue;
      PVector sp = worldToSvg.apply(new PVector(st.x, st.y));
      float sizePx = st.size * scaleX;
      float strokePx = st.strokeWeightPx;
      int rgb = st.fillCol;
      String fill = toHex.apply(rgb);
      String name = (st.name != null && st.name.length() > 0) ? st.name : "Structure";
      float angleDeg = degrees(st.angle);
      sb.append("    <g transform=\"translate(").append(fmt.apply(sp.x)).append(",").append(fmt.apply(sp.y))
        .append(") rotate(").append(fmt.apply(angleDeg)).append(")\" class=\"structure type-")
        .append(st.typeId).append("\" data-type-id=\"").append(st.typeId)
        .append("\" data-structure-id=\"").append(si).append("\" data-name=\"").append(esc.apply(name))
        .append("\" data-comment=\"").append(esc.apply(st.comment != null ? st.comment : "")).append("\">");
      switch (st.shape) {
        case RECTANGLE: {
          float w = sizePx;
          float h = (st.aspect != 0) ? (sizePx / max(0.1f, st.aspect)) : sizePx;
          sb.append("<rect x=\"").append(fmt.apply(-w * 0.5f)).append("\" y=\"").append(fmt.apply(-h * 0.5f))
            .append("\" width=\"").append(fmt.apply(w)).append("\" height=\"").append(fmt.apply(h))
            .append("\" fill=\"").append(fill).append("\" fill-opacity=\"").append(fmt.apply(st.alpha01))
            .append("\" stroke=\"#000\" stroke-width=\"").append(fmt.apply(strokePx)).append("\"/>");
          break;
        }
        case CIRCLE: {
          sb.append("<circle cx=\"0\" cy=\"0\" r=\"").append(fmt.apply(sizePx * 0.5f))
            .append("\" fill=\"").append(fill).append("\" fill-opacity=\"").append(fmt.apply(st.alpha01))
            .append("\" stroke=\"#000\" stroke-width=\"").append(fmt.apply(strokePx)).append("\"/>");
          break;
        }
        case TRIANGLE: {
          float r = sizePx;
          float h = r * 0.866f;
          sb.append("<polygon points=\"")
            .append(fmt.apply(-r * 0.5f)).append(",").append(fmt.apply(h * 0.333f)).append(" ")
            .append(fmt.apply(r * 0.5f)).append(",").append(fmt.apply(h * 0.333f)).append(" ")
            .append(fmt.apply(0f)).append(",").append(fmt.apply(-h * 0.666f))
            .append("\" fill=\"").append(fill).append("\" fill-opacity=\"").append(fmt.apply(st.alpha01))
            .append("\" stroke=\"#000\" stroke-width=\"").append(fmt.apply(strokePx)).append("\"/>");
          break;
        }
        case HEXAGON: {
          float rad = sizePx * 0.5f;
          StringBuilder pts = new StringBuilder();
          for (int v = 0; v < 6; v++) {
            float a = radians(60 * v);
            float vx = cos(a) * rad;
            float vy = sin(a) * rad;
            if (pts.length() > 0) pts.append(" ");
            pts.append(fmt.apply(vx)).append(",").append(fmt.apply(vy));
          }
          sb.append("<polygon points=\"").append(pts.toString()).append("\" fill=\"").append(fill)
            .append("\" fill-opacity=\"").append(fmt.apply(st.alpha01))
            .append("\" stroke=\"#000\" stroke-width=\"").append(fmt.apply(strokePx)).append("\"/>");
          break;
        }
        default: {
          float w = sizePx;
          float h = sizePx;
          sb.append("<rect x=\"").append(fmt.apply(-w * 0.5f)).append("\" y=\"").append(fmt.apply(-h * 0.5f))
            .append("\" width=\"").append(fmt.apply(w)).append("\" height=\"").append(fmt.apply(h))
            .append("\" fill=\"").append(fill).append("\" fill-opacity=\"").append(fmt.apply(st.alpha01))
            .append("\" stroke=\"#000\" stroke-width=\"").append(fmt.apply(strokePx)).append("\"/>");
          break;
        }
      }
      sb.append("</g>\n");
    }
  }
  sb.append("  </g>\n");

  // Labels layer
  sb.append("  <g id=\"labels\">\n");
  float baseLabelSize = (renderSettings != null && renderSettings.labelSizeZonePx > 0) ? renderSettings.labelSizeZonePx : labelSizeDefault();
  float pathLabelSize = (renderSettings != null && renderSettings.labelSizePathPx > 0) ? renderSettings.labelSizePathPx : baseLabelSize;
  float structLabelSize = (renderSettings != null && renderSettings.labelSizeStructPx > 0) ? renderSettings.labelSizeStructPx : baseLabelSize;
  float arbLabelSize = (renderSettings != null && renderSettings.labelSizeArbPx > 0) ? renderSettings.labelSizeArbPx : labelSizeDefault();
  if (s.showLabelsZones && mapModel.zones != null) {
    for (MapModel.MapZone z : mapModel.zones) {
      if (z == null || z.cells == null || z.cells.isEmpty()) continue;
      float cx = 0, cy = 0; int count = 0;
      for (int ci : z.cells) {
        if (ci < 0 || ci >= mapModel.cells.size()) continue;
        Cell c = mapModel.cells.get(ci);
        if (c == null || c.vertices == null || c.vertices.size() < 3) continue;
        PVector cen = mapModel.cellCentroid(c);
        cx += cen.x; cy += cen.y; count++;
      }
      if (count <= 0) continue;
      cx /= count; cy /= count;
      PVector sp = worldToSvg.apply(new PVector(cx, cy));
      String name = (z.name != null && z.name.length() > 0) ? z.name : "Zone";
      sb.append("    <text x=\"").append(fmt.apply(sp.x)).append("\" y=\"").append(fmt.apply(sp.y))
        .append("\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-size=\"")
        .append(fmt.apply(baseLabelSize)).append("\" class=\"label zone\" data-name=\"")
        .append(esc.apply(name)).append("\" data-comment=\"").append(esc.apply(z.comment != null ? z.comment : ""))
        .append("\">").append(esc.apply(name)).append("</text>\n");
    }
  }
  if (s.showLabelsPaths && mapModel.paths != null) {
    for (int pi = 0; pi < mapModel.paths.size(); pi++) {
      Path p = mapModel.paths.get(pi);
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
      float angle = degrees(atan2(bestB.y - bestA.y, bestB.x - bestA.x));
      if (angle > 90 || angle < -90) angle += 180;
      float mx = (bestA.x + bestB.x) * 0.5f;
      float my = (bestA.y + bestB.y) * 0.5f;
      PVector sp = worldToSvg.apply(new PVector(mx, my));
      sb.append("    <text x=\"").append(fmt.apply(sp.x)).append("\" y=\"").append(fmt.apply(sp.y))
        .append("\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-size=\"")
        .append(fmt.apply(pathLabelSize)).append("\" transform=\"rotate(").append(fmt.apply(angle))
        .append(" ").append(fmt.apply(sp.x)).append(" ").append(fmt.apply(sp.y))
        .append(")\" class=\"label path\" data-path-id=\"").append(pi).append("\" data-name=\"")
        .append(esc.apply(txt)).append("\" data-comment=\"").append(esc.apply(p.comment != null ? p.comment : ""))
        .append("\">").append(esc.apply(txt)).append("</text>\n");
    }
  }
  if (s.showLabelsStructures && mapModel.structures != null) {
    for (int si = 0; si < mapModel.structures.size(); si++) {
      Structure st = mapModel.structures.get(si);
      if (st == null) continue;
      String txt = (st.name != null && st.name.length() > 0) ? st.name : "Structure";
      PVector sp = worldToSvg.apply(new PVector(st.x, st.y));
      sb.append("    <text x=\"").append(fmt.apply(sp.x)).append("\" y=\"").append(fmt.apply(sp.y))
        .append("\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-size=\"")
        .append(fmt.apply(structLabelSize)).append("\" class=\"label structure\" data-structure-id=\"")
        .append(si).append("\" data-name=\"").append(esc.apply(txt)).append("\" data-comment=\"")
        .append(esc.apply(st.comment != null ? st.comment : "")).append("\">")
        .append(esc.apply(txt)).append("</text>\n");
    }
  }
  if (s.showLabelsArbitrary && mapModel.labels != null) {
    for (int li = 0; li < mapModel.labels.size(); li++) {
      MapLabel l = mapModel.labels.get(li);
      if (l == null || l.text == null || l.text.length() == 0) continue;
      PVector sp = worldToSvg.apply(new PVector(l.x, l.y));
      sb.append("    <text x=\"").append(fmt.apply(sp.x)).append("\" y=\"").append(fmt.apply(sp.y))
        .append("\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-size=\"")
        .append(fmt.apply(arbLabelSize)).append("\" class=\"label arbitrary\" data-label-id=\"")
        .append(li).append("\" data-comment=\"").append(esc.apply(l.comment != null ? l.comment : ""))
        .append("\">").append(esc.apply(l.text)).append("</text>\n");
    }
  }
  sb.append("  </g>\n");

  // Legend layer (simple text lists)
  sb.append("  <g id=\"legend\">\n");
  float legendX = 12;
  float legendY = 18;
  sb.append("    <text x=\"").append(fmt.apply(legendX)).append("\" y=\"").append(fmt.apply(legendY))
    .append("\" font-size=\"12\" text-anchor=\"start\" dominant-baseline=\"hanging\">Legend</text>\n");
  legendY += 16;
  if (mapModel.pathTypes != null) {
    for (int i = 0; i < mapModel.pathTypes.size(); i++) {
      PathType pt = mapModel.pathTypes.get(i);
      if (pt == null) continue;
      sb.append("    <text x=\"").append(fmt.apply(legendX)).append("\" y=\"").append(fmt.apply(legendY))
        .append("\" font-size=\"11\" text-anchor=\"start\" dominant-baseline=\"hanging\" class=\"legend-path type-")
        .append(i).append("\" data-type-id=\"").append(i).append("\">Path type ").append(i).append(": ")
        .append(esc.apply(pt.name != null ? pt.name : "")).append("</text>\n");
      legendY += 14;
    }
  }
  if (mapModel.structures != null && !mapModel.structures.isEmpty()) {
    sb.append("    <text x=\"").append(fmt.apply(legendX)).append("\" y=\"").append(fmt.apply(legendY))
      .append("\" font-size=\"12\" text-anchor=\"start\" dominant-baseline=\"hanging\">Structures</text>\n");
    legendY += 14;
    for (int i = 0; i < mapModel.structures.size(); i++) {
      Structure st = mapModel.structures.get(i);
      if (st == null) continue;
      sb.append("    <text x=\"").append(fmt.apply(legendX)).append("\" y=\"").append(fmt.apply(legendY))
        .append("\" font-size=\"11\" text-anchor=\"start\" dominant-baseline=\"hanging\" class=\"legend-structure type-")
        .append(st.typeId).append("\" data-type-id=\"").append(st.typeId).append("\" data-structure-id=\"")
        .append(i).append("\">").append(esc.apply(st.name != null ? st.name : "Structure")).append("</text>\n");
      legendY += 14;
    }
  }
  sb.append("  </g>\n");

  sb.append("</svg>\n");

  String dir = "exports";
  java.io.File folder = new java.io.File(dir);
  folder.mkdirs();
  String ts = nf(year(), 4, 0) + nf(month(), 2, 0) + nf(day(), 2, 0) + "_" +
              nf(hour(), 2, 0) + nf(minute(), 2, 0) + nf(second(), 2, 0);
  String path = dir + java.io.File.separator + "map_" + ts + ".svg";
  PrintWriter writer = createWriter(path);
  writer.print(sb.toString());
  writer.flush();
  writer.close();
  return path;
}

String exportMapJson() {
  try {
    JSONObject root = new JSONObject();

    JSONObject meta = new JSONObject();
    meta.setInt("schemaVersion", 1);
    meta.setString("savedAt", new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(new java.util.Date()));
    root.setJSONObject("meta", meta);

    JSONObject view = new JSONObject();
    view.setFloat("centerX", viewport.centerX);
    view.setFloat("centerY", viewport.centerY);
    view.setFloat("zoom", viewport.zoom);
    root.setJSONObject("view", view);

    JSONObject settings = new JSONObject();
    settings.setJSONObject("render", serializeRenderSettings(renderSettings));
    root.setJSONObject("settings", settings);

    JSONObject types = new JSONObject();
    types.setJSONArray("pathTypes", serializePathTypes(mapModel.pathTypes));
    types.setJSONArray("biomeTypes", serializeZoneTypes(mapModel.biomeTypes));
    root.setJSONObject("types", types);

    root.setJSONArray("sites", serializeSites(mapModel.sites));
    root.setJSONArray("cells", serializeCells(mapModel.cells));
    root.setJSONArray("zones", serializeZones(mapModel.zones));
    root.setJSONArray("paths", serializePaths(mapModel.paths));
    root.setJSONArray("structures", serializeStructures(mapModel.structures));
    root.setJSONArray("labels", serializeLabels(mapModel.labels));

    File dir = new File(sketchPath("exports"));
    if (!dir.exists()) dir.mkdirs();
    String ts = nf(year(), 4, 0) + nf(month(), 2, 0) + nf(day(), 2, 0) + "_" +
                nf(hour(), 2, 0) + nf(minute(), 2, 0) + nf(second(), 2, 0);
    File target = new File(dir, "map_" + ts + ".json");
    File latest = new File(dir, "map_latest.json");
    saveJSONObject(root, target.getAbsolutePath());
    saveJSONObject(root, latest.getAbsolutePath());
    return target.getAbsolutePath();
  } catch (Exception e) {
    e.printStackTrace();
    return "Failed: " + e.getMessage();
  }
}
