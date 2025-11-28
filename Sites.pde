class Site {
  float x;
  float y;
  boolean selected;

  Site(float x, float y) {
    this.x = x;
    this.y = y;
    this.selected = false;
  }

  void draw(PApplet app) {
    app.pushStyle();

    // Selected site: larger, like before
    if (selected) {
      float rPixels = 6.0f;
      float rWorld = rPixels / viewport.zoom;

      app.stroke(0);
      app.strokeWeight(1.0f / viewport.zoom);
      app.fill(240, 80, 80);
      app.ellipse(x, y, rWorld, rWorld);
    } else {
      // Non-selected: tiny, ~1 px dot
      float rPixels = 1.0f;
      float rWorld = max(1.0f / viewport.zoom, rPixels / viewport.zoom);

      app.noStroke();
      app.fill(40);
      app.ellipse(x, y, rWorld, rWorld);
    }

    app.popStyle();
  }
}
