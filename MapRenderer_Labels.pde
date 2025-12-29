// Label rendering helpers split from MapRenderer.pde

class LabelRenderer {
  private final MapModel model;
  private final HashMap<String, PFont> labelFontCache = new HashMap<String, PFont>();
  private String labelFontName = (LABEL_FONT_OPTIONS != null && LABEL_FONT_OPTIONS.length > 0) ? LABEL_FONT_OPTIONS[0] : "SansSerif";
  private PGraphics labelLayer = null;
  private int labelLayerW = 0;
  private int labelLayerH = 0;

  LabelRenderer(MapModel model) {
    this.model = model;
  }

  void drawLabels(PApplet app) {
    if (model.labels == null) return;
    app.pushStyle();
    app.textAlign(CENTER, CENTER);
    for (MapLabel l : model.labels) {
      if (l == null || l.text == null) continue;
      float ts = l.size;
      // Use a tiny default outline in edit mode (alpha 0.2) to keep consistent look
      drawTextWithOutline(app, renderSettings, l.text, l.x, l.y, ts, 0.2f, 1.0f, 0.0f, false, resolveLabelFontName(renderSettings));
    }
    app.popStyle();
  }

  void drawLabelsRender(PApplet app, RenderSettings s) {
    if (model.labels == null || s == null) return;
    if (!s.showLabelsArbitrary) return;
    app.pushStyle();
    app.textAlign(CENTER, CENTER);
    String fontName = resolveLabelFontName(s);
    boolean snap = !(currentTool == Tool.EDIT_EXPORT);
    for (MapLabel l : model.labels) {
      if (l == null) continue;
      float ts = (s.labelSizeArbPx > 0) ? s.labelSizeArbPx : l.size;
      drawTextWithOutline(app, s, l.text, l.x, l.y, ts, s.labelOutlineAlpha01, s.labelOutlineSizePx, 0.0f, snap, fontName);
    }
    app.popStyle();
  }

  void drawZoneLabelsRender(PApplet app, RenderSettings s) {
    if (model == null || model.zones == null || s == null) return;
    if (!s.showLabelsZones) return;
    app.pushStyle();
    app.fill(0);
    app.textAlign(CENTER, CENTER);
    float baseSize = (s.labelSizeZonePx > 0) ? s.labelSizeZonePx : labelSizeDefault();
    String fontName = resolveLabelFontName(s);
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
      float ts = baseSize;
      boolean snap = !(currentTool == Tool.EDIT_EXPORT);
      drawTextWithOutline(app, s, (z.name != null) ? z.name : "Zone", cx, cy, ts, s.labelOutlineAlpha01, s.labelOutlineSizePx, 0.0f, snap, fontName);
    }
    app.popStyle();
  }

  void drawPathLabelsRender(PApplet app, RenderSettings s) {
    if (model == null || model.paths == null || s == null) return;
    if (!s.showLabelsPaths) return;
    app.pushStyle();
    app.fill(0);
    app.textAlign(CENTER, CENTER);
    float baseSize = (s.labelSizePathPx > 0) ? s.labelSizePathPx : labelSizeDefault();
    String fontName = resolveLabelFontName(s);
    for (Path p : model.paths) {
      if (p == null || p.routes == null || p.routes.isEmpty()) continue;
      String txt = (p.name != null && p.name.length() > 0) ? p.name : "";
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
      float ts = baseSize;
      float angle = atan2(bestB.y - bestA.y, bestB.x - bestA.x);
      if (angle > HALF_PI || angle < -HALF_PI) angle += PI; // keep text upright
      float mx = (bestA.x + bestB.x) * 0.5f;
      float my = (bestA.y + bestB.y) * 0.5f;
      boolean snap = !(currentTool == Tool.EDIT_EXPORT);
      drawTextWithOutline(app, s, txt, mx, my, ts, s.labelOutlineAlpha01, s.labelOutlineSizePx, angle, snap, fontName);
    }
    app.popStyle();
  }

  void drawStructureLabelsRender(PApplet app, RenderSettings s) {
    if (model == null || model.structures == null || s == null) return;
    if (!s.showLabelsStructures) return;
    app.pushStyle();
    app.fill(0);
    app.textAlign(CENTER, CENTER);
    float baseSize = (s.labelSizeStructPx > 0) ? s.labelSizeStructPx : labelSizeDefault();
    String fontName = resolveLabelFontName(s);
    boolean snap = !(currentTool == Tool.EDIT_EXPORT);
    for (Structure st : model.structures) {
      if (st == null) continue;
      String txt = (st.name != null && st.name.length() > 0) ? st.name : "";
      float ts = baseSize;
      drawTextWithOutline(app, s, txt, st.x, st.y, ts, s.labelOutlineAlpha01, s.labelOutlineSizePx, 0.0f, snap, fontName);
    }
    app.popStyle();
  }

  // Build an offscreen label layer (JAVA2D preferred) and draw all render labels into it.
  PGraphics buildLabelLayer(PApplet app, RenderSettings s) {
    PGraphics lg = ensureLabelLayer(app);
    if (lg == null) return null;
    try {
      lg.beginDraw();
      lg.clear();
      if (s != null && s.antialiasing) lg.smooth(); else lg.noSmooth();
      PGraphics prev = app.g;
      app.g = lg;
      if (s != null) {
        if (s.showLabelsZones) model.drawZoneLabelsRender(app, s);
        if (s.showLabelsPaths) model.drawPathLabelsRender(app, s);
        if (s.showLabelsStructures) model.drawStructureLabelsRender(app, s);
        if (s.showLabelsArbitrary) model.drawLabelsRender(app, s);
      }
      app.g = prev;
      lg.endDraw();
    } catch (Exception ex) {
      println("Label layer build failed: " + ex);
      lg = null;
    }
    return lg;
  }

  // Pre-load likely label fonts/sizes so entering render/labels modes does not stutter.
  void warmLabelFonts(PApplet app, RenderSettings s) {
    if (app == null) return;
    String fontName = resolveLabelFontName(s);
    HashSet<Integer> sizes = new HashSet<Integer>();
    sizes.add(max(1, round(labelSizeDefault())));
    if (s != null) {
      sizes.add(max(1, round((s.labelSizeArbPx > 0) ? s.labelSizeArbPx : labelSizeDefault())));
      sizes.add(max(1, round((s.labelSizeZonePx > 0) ? s.labelSizeZonePx : labelSizeDefault())));
      sizes.add(max(1, round((s.labelSizePathPx > 0) ? s.labelSizePathPx : labelSizeDefault())));
      sizes.add(max(1, round((s.labelSizeStructPx > 0) ? s.labelSizeStructPx : labelSizeDefault())));
    }
    for (int sz : sizes) {
      labelFont(app, sz, fontName);
    }
  }

  private String resolveLabelFontName(RenderSettings s) {
    if (LABEL_FONT_OPTIONS != null && LABEL_FONT_OPTIONS.length > 0) {
      int idx = 0;
      if (s != null) idx = constrain(s.labelFontIndex, 0, LABEL_FONT_OPTIONS.length - 1);
      return LABEL_FONT_OPTIONS[idx];
    }
    return "SansSerif";
  }

  private PFont labelFont(PApplet app, int sizePx, String desiredFont) {
    int key = max(1, sizePx);
    String fontKey = (desiredFont != null && desiredFont.length() > 0) ? desiredFont : labelFontName;
    String cacheKey = fontKey + "|" + key;
    PFont f = labelFontCache.get(cacheKey);
    if (f == null) {
      String chosen = fontKey;
      try {
        f = app.createFont(chosen, key, true);
      } catch (Exception ignored) {
      }
      if (f == null) {
        String[] fonts = PFont.list();
        if (fonts != null && fonts.length > 0) {
          chosen = fonts[0];
          try {
            f = app.createFont(chosen, key, true);
          } catch (Exception ignored) {
          }
        }
      }
      if (f == null) {
        f = app.createFont("SansSerif", key, true);
      }
      labelFontCache.put(cacheKey, f);
      labelFontName = chosen;
    }
    return f;
  }

  void drawTextWithOutline(PApplet app, RenderSettings rs, String txt, float x, float y, float ts, float outlineAlpha01, float outlineSizePx, float angleRad, boolean snapToPixel, String fontName) {
    if (app == null || txt == null) return;
    try {
      RenderSettings s = (rs != null) ? rs : renderSettings;
      ensureFontMapReady(app.g);
      float finalSize = ts;
      float outlineSize = outlineSizePx;
      float canvasW = (app.g != null) ? app.g.width : app.width;
      float canvasH = (app.g != null) ? app.g.height : app.height;
      float resolutionScale = 1.0f;
      if (renderingForExport) {
        float baseW = max(1, width);
        float baseH = max(1, height);
        resolutionScale = max(canvasW / baseW, canvasH / baseH);
      }
      if (s != null && s.labelScaleWithZoom) {
        float ref = (s.labelScaleRefZoom > 1e-6f) ? s.labelScaleRefZoom : DEFAULT_VIEW_ZOOM;
        finalSize = ts * (max(1e-6f, viewport.zoom) / ref) * resolutionScale;
      }
      if (s != null && s.labelOutlineScaleWithZoom) {
        float ref = (s.labelScaleRefZoom > 1e-6f) ? s.labelScaleRefZoom : DEFAULT_VIEW_ZOOM;
        outlineSize = outlineSizePx * (max(1e-6f, viewport.zoom) / ref) * resolutionScale;
      }
      // Prevent runaway font allocations for huge zoom/export scales.
      finalSize = constrain(finalSize, 4.0f, 128.0f);
      outlineSize = constrain(outlineSize, 0, 64.0f);
      PVector screen = viewport.worldToScreen(x, y, canvasW, canvasH);
      if (snapToPixel && !renderingForExport) {
        screen.x = round(screen.x);
        screen.y = round(screen.y);
      }
      app.pushMatrix();
      app.resetMatrix();
      app.translate(screen.x, screen.y);
      app.rotate(angleRad);
      int fontSize = max(1, round(finalSize));
      PFont font = labelFont(app, fontSize, fontName);
      if (font != null) {
        app.textFont(font);
        app.textSize(fontSize);
      } else {
        app.textSize(fontSize);
      }
      float oa = constrain(outlineAlpha01, 0, 1);
      int radius = max(0, round(outlineSize));
      if (oa > 1e-4f) {
        app.fill(255, oa * 255);
        for (int dx = -radius; dx <= radius; dx++) {
          for (int dy = -radius; dy <= radius; dy++) {
            if (dx == 0 && dy == 0) continue;
            app.text(txt, dx, dy);
          }
        }
      }
      app.fill(0);
      app.text(txt, 0, 0);
      app.popMatrix();
    } catch (Exception ex) {
      println("Label draw skipped due to error: " + ex);
    }
  }

  // Some Processing builds leave fontMap null on offscreen P2D buffers; seed it so text works in exports.
  private void ensureFontMapReady(PGraphics pg) {
    if (pg == null) return;
    try {
      if (pg instanceof processing.opengl.PGraphicsOpenGL) {
        processing.opengl.PGraphicsOpenGL ogl = (processing.opengl.PGraphicsOpenGL)pg;
        Field fontField = findFontMapField(ogl.getClass());
        if (fontField == null) return;
        fontField.setAccessible(true);
        Object map = fontField.get(ogl);

        Object primary = null;
        Field primaryFontField = null;
        try {
          Method primaryMeth = ogl.getClass().getMethod("getPrimaryPG");
          primary = primaryMeth.invoke(ogl);
          if (primary != null) {
            primaryFontField = findFontMapField(primary.getClass());
            if (primaryFontField != null) primaryFontField.setAccessible(true);
          }
        } catch (Exception ignored) {}

        if (primary != null && primaryFontField != null) {
          Object pMap = primaryFontField.get(primary);
          if (pMap == null) {
            pMap = (map != null) ? map : new java.util.WeakHashMap();
            primaryFontField.set(primary, pMap);
          }
          if (map == null) {
            map = pMap;
            fontField.set(ogl, map);
          }
        }

        if (map == null) {
          map = new java.util.WeakHashMap();
          fontField.set(ogl, map);
          if (primary != null && primaryFontField != null && primaryFontField.get(primary) == null) {
            primaryFontField.set(primary, map);
          }
        }
      }
    } catch (Exception ex) {
      println("Font map init skipped: " + ex);
    }
  }

  // Locate the fontMap field up the class hierarchy.
  private Field findFontMapField(Class<?> cls) {
    Class<?> cur = cls;
    while (cur != null) {
      try {
        return cur.getDeclaredField("fontMap");
      } catch (NoSuchFieldException ignored) {
      }
      cur = cur.getSuperclass();
    }
    return null;
  }

  private PGraphics ensureLabelLayer(PApplet app) {
    if (app == null) return null;
    int targetW = (app.g != null) ? app.g.width : app.width;
    int targetH = (app.g != null) ? app.g.height : app.height;
    boolean sizeChanged = (labelLayer == null) || labelLayerW != targetW || labelLayerH != targetH;
    if (sizeChanged) {
      labelLayerW = targetW;
      labelLayerH = targetH;
      labelLayer = null;
      try {
        labelLayer = app.createGraphics(targetW, targetH, JAVA2D);
      } catch (Exception ignored) {}
      if (labelLayer == null) {
        try {
          labelLayer = app.createGraphics(targetW, targetH, P2D);
        } catch (Exception ignored) {}
      }
    }
    return labelLayer;
  }
}
