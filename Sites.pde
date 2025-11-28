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

    // size in pixels, converted to world units
    float rPixels = 6.0f;
    float rWorld = rPixels / viewport.zoom;

    if (selected) {
      app.stroke(0);
      app.strokeWeight(1.0f / viewport.zoom);
      app.fill(240, 80, 80);
    } else {
      app.noStroke();
      app.fill(40);
    }

    app.ellipse(x, y, rWorld, rWorld);
    app.popStyle();
  }
}
