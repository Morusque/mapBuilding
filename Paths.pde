class Path {
  // Each route is an ordered list of points; consecutive pairs form straight segments.
  ArrayList<ArrayList<PVector>> routes = new ArrayList<ArrayList<PVector>>();
  int typeId = 0;
  String name = "";

  void addRoute(ArrayList<PVector> pts) {
    if (pts == null || pts.size() < 2) return;
    ArrayList<PVector> copy = new ArrayList<PVector>();
    for (PVector v : pts) copy.add(v.copy());
    routes.add(copy);
  }

  void draw(PApplet app) {
    if (routes.isEmpty()) return;

    for (ArrayList<PVector> seg : routes) {
      if (seg == null || seg.isEmpty()) continue;
      if (seg.size() == 1) {
        float r = 3.0f / viewport.zoom;
        app.pushStyle();
        app.noStroke();
        app.fill(app.g.strokeColor);
        PVector a = seg.get(0);
        app.ellipse(a.x, a.y, r, r);
        app.popStyle();
        println("[PATH DRAW ROUTE] single point at (" + a.x + "," + a.y + ")");
        continue;
      }

      println("[PATH DRAW ROUTE] size=" + seg.size() + " first=(" + seg.get(0).x + "," + seg.get(0).y + ") last=(" + seg.get(seg.size()-1).x + "," + seg.get(seg.size()-1).y + ")");
      for (int i = 0; i < seg.size() - 1; i++) {
        PVector a = seg.get(i);
        PVector b = seg.get(i + 1);
        app.line(a.x, a.y, b.x, b.y);
      }

      // Tiny endpoint dots to keep short segments visible
      float r = 2.0f / viewport.zoom;
      app.pushStyle();
      app.noStroke();
      app.fill(app.g.strokeColor);
      PVector a = seg.get(0);
      PVector b = seg.get(seg.size() - 1);
      app.ellipse(a.x, a.y, r, r);
      app.ellipse(b.x, b.y, r, r);
      app.popStyle();
    }
  }

  // Used to preview a segment being drawn (can have different styling if needed)
  void drawPreview(PApplet app, ArrayList<PVector> seg, int strokeCol, float weightPx) {
    if (seg == null || seg.isEmpty()) return;
    if (seg.size() == 1) {
      float r = 3.0f / viewport.zoom;
      app.pushStyle();
      app.noStroke();
      app.fill(strokeCol);
      PVector a = seg.get(0);
      app.ellipse(a.x, a.y, r, r);
      app.popStyle();
      println("[PATH PREVIEW ROUTE] single point at (" + a.x + "," + a.y + ")");
      return;
    }

    println("[PATH PREVIEW ROUTE] size=" + seg.size() + " first=(" + seg.get(0).x + "," + seg.get(0).y + ") last=(" + seg.get(seg.size()-1).x + "," + seg.get(seg.size()-1).y + ")");
    app.pushStyle();
    app.noFill();
    app.stroke(strokeCol);
    app.strokeWeight(max(2.0f, weightPx) / viewport.zoom); // keep preview visible

    for (int i = 0; i < seg.size() - 1; i++) {
      PVector a = seg.get(i);
      PVector b = seg.get(i + 1);
      app.line(a.x, a.y, b.x, b.y);
    }

    // endpoint dots for clarity
    app.pushStyle();
    app.noStroke();
    app.fill(strokeCol);
    float r = 3.0f / viewport.zoom;
    PVector start = seg.get(0);
    PVector end = seg.get(seg.size() - 1);
    app.ellipse(start.x, start.y, r, r);
    app.ellipse(end.x, end.y, r, r);
    app.popStyle();

    app.popStyle();
  }

  int routeCount() {
    return routes.size();
  }

  int segmentCount() {
    int count = 0;
    for (ArrayList<PVector> r : routes) {
      if (r == null) continue;
      count += max(0, r.size() - 1);
    }
    return count;
  }

  float totalLength() {
    float len = 0;
    for (ArrayList<PVector> seg : routes) {
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
