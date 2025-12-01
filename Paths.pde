class Path {
  ArrayList<ArrayList<PVector>> segments = new ArrayList<ArrayList<PVector>>();
  int typeId = 0;
  String name = "";

  void addSegment(ArrayList<PVector> pts) {
    if (pts == null || pts.size() < 2) return;
    ArrayList<PVector> copy = new ArrayList<PVector>();
    for (PVector v : pts) copy.add(v.copy());
    segments.add(copy);
  }

  void draw(PApplet app) {
    if (segments.isEmpty()) return;

    for (ArrayList<PVector> seg : segments) {
      if (seg == null || seg.size() < 2) continue;
      app.beginShape();
      for (PVector p : seg) {
        app.vertex(p.x, p.y);
      }
      app.endShape();
    }
  }

  // Used to preview a segment being drawn (can have different styling if needed)
  void drawPreview(PApplet app, ArrayList<PVector> seg, int strokeCol, float weightPx) {
    if (seg == null || seg.size() < 2) return;

    app.pushStyle();
    app.noFill();
    app.stroke(strokeCol);
    app.strokeWeight(max(0.5f, weightPx) / viewport.zoom);

    app.beginShape();
    for (PVector p : seg) {
      app.vertex(p.x, p.y);
    }
    app.endShape();

    app.popStyle();
  }

  int segmentCount() {
    return segments.size();
  }

  float totalLength() {
    float len = 0;
    for (ArrayList<PVector> seg : segments) {
      if (seg == null) continue;
      for (int i = 0; i < seg.size() - 1; i++) {
        PVector a = seg.get(i);
        PVector b = seg.get(i + 1);
        float dx = b.x - a.x;
        float dy = b.y - a.y;
        len += sqrt(dx * dx + dy * dy);
      }
    }
    return len;
  }
}
