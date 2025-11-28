class Path {
  ArrayList<PVector> points = new ArrayList<PVector>();

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
  void drawPreview(PApplet app) {
    if (points.size() < 1) return;

    app.pushStyle();
    app.noFill();
    app.stroke(30, 30, 160);
    app.strokeWeight(2.0f / viewport.zoom);

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
}
