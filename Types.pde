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
  new ZonePreset("Rock",        color(150, 150, 150)),
  new ZonePreset("Grassland",   color(186, 206, 140)),
  new ZonePreset("Forest",      color(110, 150, 95)),
  new ZonePreset("Sand",        color(230, 214, 160)),
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
  new PathTypePreset("Road",    color(80, 80, 80),    3.0f, 1.2f, PathRouteMode.PATHFIND, 0.0f,   true,  false),
  new PathTypePreset("River",   color(60, 90, 180),   8.0f, 2.0f, PathRouteMode.PATHFIND, 40.0f,  false, true),
  new PathTypePreset("Street",  color(110, 110, 110), 2.2f, 0.8f, PathRouteMode.PATHFIND, 300.0f, true,  false),
  new PathTypePreset("Wall",    color(90, 70, 50),    2.5f, 1.0f, PathRouteMode.ENDS,     0.0f,   true,  false),
  new PathTypePreset("Bridge",  color(130, 130, 160), 2.5f, 1.0f, PathRouteMode.ENDS,     0.0f,   false, false),
  new PathTypePreset("Trail",   color(140, 100, 70),  1.6f, 0.6f, PathRouteMode.PATHFIND, 150.0f, true,  false),
  new PathTypePreset("Canal",   color(70, 110, 190),  2.4f, 1.0f, PathRouteMode.PATHFIND, 80.0f,  false, true),
  new PathTypePreset("Rail",    color(70, 70, 70),    2.8f, 1.2f, PathRouteMode.PATHFIND, 0.0f,   true,  false),
  new PathTypePreset("Pipeline",color(120, 120, 120), 2.0f, 0.8f, PathRouteMode.PATHFIND, 0.0f,   true,  false)
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
  StructureShape shape = StructureShape.SQUARE;
  float aspect = 1.0f; // width / height for rectangle
  String name = "";
  float hue01 = 0.0f;
  float sat01 = 0.0f;
  float bri01 = 0.9f;
  float alpha01 = 0.7f;
  float strokeWeightPx = 1.4f;
  int fillCol = color(245, 245, 235, 180);

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
    switch (shape) {
      case RECTANGLE: {
        float w = r;
        float h = (aspect != 0) ? (r / max(0.1f, aspect)) : r;
        app.rectMode(CENTER);
        app.rect(0, 0, w, h);
        break;
      }
      case CIRCLE: {
        app.ellipse(0, 0, r, r);
        break;
      }
      case TRIANGLE: {
        float h = r * 0.866f; // sqrt(3)/2 * r for equilateral, r is side
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
        app.rectMode(CENTER);
        app.rect(0, 0, r, r);
        break;
      }
    }
    app.popMatrix();
  }
}

// ---------- Labels ----------

class MapLabel {
  float x;
  float y;
  String text;
  LabelTarget target = LabelTarget.FREE;
  float size = labelSizeDefault();

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
    app.pushStyle();
    app.fill(0);
    app.textAlign(CENTER, CENTER);
    app.textSize(size / viewport.zoom);
    app.text(text, x, y);
    app.popStyle();
  }
}
