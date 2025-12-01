class Path {
  ArrayList<PVector> points = new ArrayList<PVector>();
  int typeId = 0;
  String name = "";

  void addPoint(float x, float y) {
    points.add(new PVector(x, y));
  }

  void draw(PApplet app) {
    if (points.size() < 2) return;

    app.beginShape();
    for (int i = 0; i < points.size(); i++) {
      PVector p = points.get(i);
      app.vertex(p.x, p.y);
    }
    app.endShape();
  }

  // Used to preview the path being drawn (can have different styling if needed)
  void drawPreview(PApplet app, int strokeCol, float weightPx) {
    if (points.size() < 1) return;

    app.pushStyle();
    app.noFill();
    app.stroke(strokeCol);
    app.strokeWeight(max(0.5f, weightPx) / viewport.zoom);

    app.beginShape();
    for (int i = 0; i < points.size(); i++) {
      PVector p = points.get(i);
      app.vertex(p.x, p.y);
    }
    app.endShape();

    // Optionally draw nodes as small dots
    for (int i = 0; i < points.size(); i++) {
      PVector p = points.get(i);
      float rWorld = 3.0f / viewport.zoom;
      app.fill(30, 30, 160);
      app.noStroke();
      app.ellipse(p.x, p.y, rWorld, rWorld);
    }

    app.popStyle();
  }

  int segmentCount() {
    return max(0, points.size() - 1);
  }

  float totalLength() {
    float len = 0;
    for (int i = 0; i < points.size() - 1; i++) {
      PVector a = points.get(i);
      PVector b = points.get(i + 1);
      float dx = b.x - a.x;
      float dy = b.y - a.y;
      len += sqrt(dx * dx + dy * dy);
    }
    return len;
  }
}
