// ---------- ZoneType ----------

class ZoneType {
  String name;
  int col;
  float hue01;
  float sat01;
  float bri01;
  int patternIndex = 0;

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
  new ZonePreset("Rock",        color(150, 150, 150)),
  new ZonePreset("Grassland",   color(186, 206, 140)),
  new ZonePreset("Forest",      color(110, 150, 95)),
  new ZonePreset("Sand",        color(230, 214, 160)),
  new ZonePreset("Snow",        color(235, 240, 245)),
  new ZonePreset("Wetland",     color(165, 190, 155)),
  new ZonePreset("Magma",       color(190, 70, 40)),
  new ZonePreset("Wet",         color(80, 80, 150)),
  new ZonePreset("Shrubland",   color(195, 205, 170)),
  new ZonePreset("Clay Flats",  color(198, 176, 156)),
  new ZonePreset("Savannah",    color(215, 196, 128)),
  new ZonePreset("Tundra",      color(190, 200, 205)),
  new ZonePreset("Jungle",      color(80, 130, 85)),
  new ZonePreset("Volcanic",    color(105, 95, 90)),
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
  float minWeightPx;
  boolean taperOn = false;
  PathRouteMode routeMode = PathRouteMode.PATHFIND;
  float slopeBias = 0.0f;
  boolean avoidWater = true;

  PathType(String name, int col, float weightPx, float minWeightPx, PathRouteMode routeMode, float slopeBias, boolean avoidWater, boolean taperOn) {
    this.name = name;
    this.weightPx = weightPx;
    this.minWeightPx = max(0.5f, minWeightPx);
    this.routeMode = (routeMode != null) ? routeMode : PathRouteMode.PATHFIND;
    this.slopeBias = slopeBias;
    this.avoidWater = avoidWater;
    this.taperOn = taperOn;
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
  float minWeightPx;
  PathRouteMode routeMode;
  float slopeBias;
  boolean avoidWater;
  boolean taperOn;
  PathTypePreset(String name, int col, float weightPx, float minWeightPx, PathRouteMode routeMode, float slopeBias, boolean avoidWater, boolean taperOn) {
    this.name = name;
    this.col = col;
    this.weightPx = weightPx;
    this.minWeightPx = minWeightPx;
    this.routeMode = routeMode;
    this.slopeBias = slopeBias;
    this.avoidWater = avoidWater;
    this.taperOn = taperOn;
  }
}

PathTypePreset[] PATH_TYPE_PRESETS = new PathTypePreset[] {
  new PathTypePreset("Road",    color(80, 80, 80),    3.0f, 1.2f, PathRouteMode.PATHFIND, 500.0f,  true,  false),
  new PathTypePreset("River",   color(60, 90, 180),   8.0f, 2.0f, PathRouteMode.PATHFIND, 0.0f,    false, true),
  new PathTypePreset("Bridge",  color(130, 130, 160), 2.5f, 1.0f, PathRouteMode.ENDS,     0.0f,    false, false),
  new PathTypePreset("Trail",   color(140, 100, 70),  1.6f, 0.6f, PathRouteMode.PATHFIND, 0.0f,    true,  false),
  new PathTypePreset("Wall",    color(90, 70, 50),    2.5f, 1.0f, PathRouteMode.ENDS,     0.0f,    true,  false),
  new PathTypePreset("Street",  color(110, 110, 110), 2.2f, 0.8f, PathRouteMode.ENDS,     0.0f,    false, false),
  new PathTypePreset("Highway", color(130, 130, 130), 2.5f, 1.0f, PathRouteMode.ENDS,     0.0f,    false, false),
  new PathTypePreset("Canal",   color(70, 110, 190),  2.4f, 1.0f, PathRouteMode.PATHFIND, 700.0f,  false, true),
  new PathTypePreset("Rail",    color(70, 70, 70),    2.8f, 1.2f, PathRouteMode.PATHFIND, 700.0f,  true,  false),
  new PathTypePreset("Pipeline",color(120, 120, 120), 2.0f, 0.8f, PathRouteMode.ENDS,     0.0f,    true,  false),
  new PathTypePreset("Path",    color(0, 0, 0),       2.0f, 0.8f, PathRouteMode.ENDS,     0.0f,    false, false),
};

// ---------- Color helpers for HSB<->RGB in [0..1] ----------
// The "01" suffix means values are normalized [0..1] instead of Processing's default 0..255.

void rgbToHSB01(int c, float[] outHSB) {
  int r = (c >> 16) & 0xFF;
  int g = (c >> 8) & 0xFF;
  int b = c & 0xFF;
  float rf = r / 255.0f;
  float gf = g / 255.0f;
  float bf = b / 255.0f;
  float maxc = max(rf, max(gf, bf));
  float minc = min(rf, min(gf, bf));
  float delta = maxc - minc;
  float h;
  if (delta < 1e-6f) {
    h = 0.0f;
  } else if (maxc == rf) {
    h = ((gf - bf) / delta) % 6.0f;
  } else if (maxc == gf) {
    h = ((bf - rf) / delta) + 2.0f;
  } else {
    h = ((rf - gf) / delta) + 4.0f;
  }
  h /= 6.0f;
  if (h < 0) h += 1.0f;
  float s = (maxc <= 0.0f) ? 0.0f : (delta / maxc);
  float v = maxc;

  outHSB[0] = constrain(h, 0, 1);
  outHSB[1] = constrain(s, 0, 1);
  outHSB[2] = constrain(v, 0, 1);
}

int hsb01ToRGB(float h, float s, float b) {
  h = constrain(h, 0, 1);
  s = constrain(s, 0, 1);
  b = constrain(b, 0, 1);

  float hh = (h * 6.0f) % 6.0f;
  int sector = floor(hh);
  float f = hh - sector;
  float p = b * (1 - s);
  float q = b * (1 - s * f);
  float t = b * (1 - s * (1 - f));
  float rf = 0, gf = 0, bf = 0;
  switch (sector) {
    case 0: rf = b; gf = t; bf = p; break;
    case 1: rf = q; gf = b; bf = p; break;
    case 2: rf = p; gf = b; bf = t; break;
    case 3: rf = p; gf = q; bf = b; break;
    case 4: rf = t; gf = p; bf = b; break;
    case 5: default: rf = b; gf = p; bf = q; break;
  }

  int ri = constrain(round(rf * 255.0f), 0, 255);
  int gi = constrain(round(gf * 255.0f), 0, 255);
  int bi = constrain(round(bf * 255.0f), 0, 255);
  return 0xFF000000 | (ri << 16) | (gi << 8) | bi;

}

// ---------- Structures ----------

class StructureAttributes {
  String name = "";
  String comment = "";
  float size = 0.02f;
  float angleRad = 0.0f;
  StructureShape shape = StructureShape.RECTANGLE;
  StructureSnapMode alignment = StructureSnapMode.NEXT_TO_PATH;
  float aspectRatio = 1.0f;
  float hue01 = 0.0f;
  float sat01 = 0.0f;
  float alpha01 = 1.0f;
  float strokeWeightPx = 1.4f;

  StructureAttributes copy() {
    StructureAttributes c = new StructureAttributes();
    c.name = name;
    c.comment = comment;
    c.size = size;
    c.angleRad = angleRad;
    c.shape = shape;
    c.alignment = alignment;
    c.aspectRatio = aspectRatio;
    c.hue01 = hue01;
    c.sat01 = sat01;
    c.alpha01 = alpha01;
    c.strokeWeightPx = strokeWeightPx;
    return c;
  }

  void applyTo(Structure s) {
    if (s == null) return;
    s.name = (name != null) ? name : "";
    s.comment = (comment != null) ? comment : "";
    s.size = size;
    s.angle = angleRad;
    s.shape = shape;
    s.aspect = aspectRatio;
    s.alignment = alignment;
    s.setHue(hue01);
    s.setSaturation(sat01);
    s.setAlpha(alpha01);
    s.strokeWeightPx = strokeWeightPx;
  }
}

class StructureSnapBinding {
  StructureSnapTargetType type = StructureSnapTargetType.NONE;
  int pathIndex = -1;
  int routeIndex = -1;
  int segmentIndex = -1;
  int structureIndex = -1;
  int cellA = -1;
  int cellB = -1;
  float snapAngleRad = 0.0f;
  PVector segA = null;
  PVector segB = null;
  PVector snapPoint = null;

  void clear() {
    type = StructureSnapTargetType.NONE;
    pathIndex = -1;
    routeIndex = -1;
    segmentIndex = -1;
    structureIndex = -1;
    cellA = -1;
    cellB = -1;
    snapAngleRad = 0.0f;
    segA = null;
    segB = null;
    snapPoint = null;
  }
}

class Structure {
  float x;
  float y;
  int typeId = 0;
  float angle = 0;
  float size = 0.02f; // world units square side
  StructureShape shape = StructureShape.RECTANGLE;
  float aspect = 1.0f; // width / height for rectangle
  StructureSnapMode alignment = StructureSnapMode.NEXT_TO_PATH;
  String name = "";
  float hue01 = 0.0f;
  float sat01 = 0.0f;
  float bri01 = 0.9f;
  float alpha01 = 0.7f;
  float strokeWeightPx = 1.4f;
  int fillCol = color(245, 245, 235, 180);
  StructureSnapBinding snapBinding = new StructureSnapBinding();
  String comment = "";

  Structure(float x, float y) {
    this.x = x;
    this.y = y;
    setColor(color(245, 245, 235), 180.0f / 255.0f);
  }

  void setColor(int c, float alpha) {
    float[] hsb = new float[3];
    rgbToHSB01(c, hsb);
    hue01 = hsb[0];
    sat01 = hsb[1];
    bri01 = hsb[2];
    alpha01 = constrain(alpha, 0, 1);
    updateFillColor();
  }

  void setHue(float h) {
    hue01 = constrain(h, 0, 1);
    updateFillColor();
  }

  void setSaturation(float s) {
    sat01 = constrain(s, 0, 1);
    updateFillColor();
  }

  void setAlpha(float a) {
    alpha01 = constrain(a, 0, 1);
    updateFillColor();
  }

  void updateFillColor() {
    int rgb = hsb01ToRGB(hue01, sat01, bri01);
    int r = (rgb >> 16) & 0xFF;
    int g = (rgb >> 8) & 0xFF;
    int b = rgb & 0xFF;
    fillCol = color(r, g, b, alpha01 * 255.0f);
  }

  void draw(PApplet app) {
    app.pushMatrix();
    app.translate(x, y);
    app.rotate(angle);
    app.stroke(0);
    app.strokeWeight(strokeWeightPx / viewport.zoom);
    app.fill(fillCol);

    float r = size;
    float asp = max(0.1f, aspect);
    switch (shape) {
      case RECTANGLE: {
        float w = r;
        float h = r / asp;
        app.rectMode(CENTER);
        app.rect(0, 0, w, h);
        break;
      }
      case CIRCLE: {
        float w = r;
        float h = r / asp;
        app.ellipse(0, 0, w, h);
        break;
      }
      case TRIANGLE: {
        float h = (r / asp) * 0.866f; // scaled by aspect
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
          app.vertex(cos(a) * rad, sin(a) * rad / asp);
        }
        app.endShape(CLOSE);
        break;
      }
      default: {
        app.rectMode(CENTER);
        app.rect(0, 0, r, r / asp);
        break;
      }
    }
    app.popMatrix();
  }
}

StructureAttributes structureAttributesFromStructure(Structure s) {
  StructureAttributes a = new StructureAttributes();
  if (s == null) return a;
  a.name = s.name;
  a.comment = s.comment;
  a.size = s.size;
  a.angleRad = s.angle;
  a.shape = s.shape;
  a.alignment = s.alignment;
  a.aspectRatio = s.aspect;
  a.hue01 = s.hue01;
  a.sat01 = s.sat01;
  a.alpha01 = s.alpha01;
  a.strokeWeightPx = s.strokeWeightPx;
  return a;
}

// ---------- Labels ----------

class MapLabel {
  float x;
  float y;
  String text;
  LabelTarget target = LabelTarget.FREE;
  float size = labelSizeDefault();
  String comment = "";

  MapLabel(float x, float y, String text) {
    this.x = x;
    this.y = y;
    this.text = text;
  }

  MapLabel(float x, float y, String text, LabelTarget target) {
    this(x, y, text);
    this.target = target;
  }

  void draw(PApplet app) {
    if (app == null || text == null || text.length() == 0) return;
    float ts = size / max(1e-6f, viewport.zoom);
    app.pushStyle();
    app.fill(0);
    app.textAlign(CENTER, CENTER);
    app.textSize(ts);
    app.text(text, x, y);
    app.popStyle();
  }
}
