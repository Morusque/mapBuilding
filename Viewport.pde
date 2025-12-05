class Viewport {
  float centerX;
  float centerY;
  float zoom;

  Viewport() {
    centerX = 0.5f;
    centerY = 0.5f;
    zoom = 600.0f;  // 1x1 world fills a good part of the screen
  }

  void applyTransform(PApplet app) {
    applyTransform(app.g, app.width, app.height);
  }

  void applyTransform(PGraphics g) {
    applyTransform(g, g.width, g.height);
  }

  void applyTransform(PApplet app, float canvasWidth, float canvasHeight) {
    applyTransform(app.g, canvasWidth, canvasHeight);
  }

  void applyTransform(PGraphics g, float canvasWidth, float canvasHeight) {
    g.translate(canvasWidth * 0.5f, canvasHeight * 0.5f);
    g.scale(zoom);
    g.translate(-centerX, -centerY);
  }

  void panScreen(float dxPixels, float dyPixels) {
    centerX -= dxPixels / zoom;
    centerY -= dyPixels / zoom;
  }

  void zoomAt(float factor, float screenX, float screenY) {
    float wxBefore = (screenX - width * 0.5f) / zoom + centerX;
    float wyBefore = (screenY - height * 0.5f) / zoom + centerY;

    zoom *= factor;
    zoom = constrain(zoom, 50.0f, 5000.0f);

    float wxAfter = (screenX - width * 0.5f) / zoom + centerX;
    float wyAfter = (screenY - height * 0.5f) / zoom + centerY;

    centerX += wxBefore - wxAfter;
    centerY += wyBefore - wyAfter;
  }

  PVector screenToWorld(float sx, float sy) {
    float wx = (sx - width * 0.5f) / zoom + centerX;
    float wy = (sy - height * 0.5f) / zoom + centerY;
    return new PVector(wx, wy);
  }

  PVector worldToScreen(float wx, float wy) {
    float sx = (wx - centerX) * zoom + width * 0.5f;
    float sy = (wy - centerY) * zoom + height * 0.5f;
    return new PVector(sx, sy);
  }
}
