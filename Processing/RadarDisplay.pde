import processing.serial.*;

Serial radarPort;

// ============================================================
// TARGET OBJECTS
// ============================================================

Target target1 = new Target();
Target target2 = new Target();
Target target3 = new Target();

// ============================================================
// RADAR SETTINGS
// ============================================================

final float MAX_RANGE_MM = 5000;
final float FIELD_OF_VIEW = 60;

final String SERIAL_PORT = "COM3";
final int SERIAL_BAUD = 115200;

float sweepPosition = -FIELD_OF_VIEW;
float sweepDirection = 1;

// ============================================================
// SYSTEM STATUS
// ============================================================

int validFrames = 0;
int lastFrameTime = 0;

int lastFpsTime = 0;
int displayedFPS = 0;
int frameCounter = 0;

boolean serialConnected = false;

// ============================================================
// SETUP
// ============================================================

void setup() {
  size(1200, 800);

  smooth(8);
  frameRate(60);

  println("Available serial ports:");
  printArray(Serial.list());

  try {
    radarPort = new Serial(
      this,
      SERIAL_PORT,
      SERIAL_BAUD
    );

    radarPort.clear();
    radarPort.bufferUntil('\n');

    serialConnected = true;

    println("Connected to " + SERIAL_PORT);
  }
  catch (Exception error) {
    serialConnected = false;

    println("Could not connect to " + SERIAL_PORT);
    println(error.getMessage());
  }
}

// ============================================================
// MAIN DRAW LOOP
// ============================================================

void draw() {
  drawFadingBackground();

  drawHeader();
  drawRadarGrid();
  drawDetectionBoundary();
  drawSweep();

  drawTargetTrail(target1, 1);
  drawTargetTrail(target2, 2);
  drawTargetTrail(target3, 3);

  drawTarget(target1, 1);
  drawTarget(target2, 2);
  drawTarget(target3, 3);

  drawTargetPanel();
  drawSystemPanel();
  drawClosestTargetWarning();

  updateSweep();
  updateFPS();
}

// ============================================================
// BACKGROUND
// ============================================================

void drawFadingBackground() {
  noStroke();

  fill(2, 13, 8, 95);

  rect(
    0,
    0,
    width,
    height
  );
}

// ============================================================
// SERIAL DATA
// ============================================================

void serialEvent(Serial port) {
  String incoming = port.readStringUntil('\n');

  if (incoming == null) {
    return;
  }

  incoming = trim(incoming);

  if (incoming.length() == 0) {
    return;
  }

  if (incoming.equals("RADAR_READY")) {
    println("Radar ready");
    return;
  }

  String[] targetSections = split(incoming, ';');

  if (targetSections == null || targetSections.length != 3) {
    println("Invalid serial line: " + incoming);
    return;
  }

  parseTarget(targetSections[0], target1);
  parseTarget(targetSections[1], target2);
  parseTarget(targetSections[2], target3);

  validFrames++;
  frameCounter++;
  lastFrameTime = millis();
}

// ============================================================
// TARGET PARSING
// ============================================================

void parseTarget(String section, Target target) {
  String[] values = split(trim(section), ',');

  if (values == null || values.length != 5) {
    println("Invalid target data: " + section);
    return;
  }

  try {
    float newX =
      Float.parseFloat(trim(values[1]));

    float newY =
      Float.parseFloat(trim(values[2]));

    float newSpeed =
      Float.parseFloat(trim(values[3]));

    float newResolution =
      Float.parseFloat(trim(values[4]));

    boolean currentlyDetected =
      !(
        newX == 0 &&
        newY == 0 &&
        newSpeed == 0 &&
        newResolution == 0
      );

    if (!currentlyDetected) {
      target.detected = false;

      target.x = 0;
      target.y = 0;
      target.speed = 0;
      target.resolution = 0;
      target.distance = 0;
      target.bearing = 0;

      return;
    }

    target.x = newX;
    target.y = newY;
    target.speed = newSpeed;
    target.resolution = newResolution;

    target.distance =
      sqrt(
        target.x * target.x +
        target.y * target.y
      );

    target.bearing =
      degrees(
        atan2(
          target.x,
          target.y
        )
      );

    target.detected = true;
    target.lastSeen = millis();

    target.addTrailPoint(
      target.x,
      target.y
    );
  }
  catch (Exception error) {
    println("Could not parse target data: " + section);
  }
}

// ============================================================
// HEADER
// ============================================================

void drawHeader() {
  fill(60, 255, 125);

  textAlign(CENTER);
  textSize(29);

  text(
    "RD-03D MULTI-TARGET TRACKING RADAR",
    width / 2,
    42
  );

  fill(60, 185, 105);
  textSize(14);

  text(
    "ESP32 HARDWARE UART • LIVE 3-TARGET TRACKING",
    width / 2,
    68
  );

  stroke(30, 150, 70);
  strokeWeight(1);

  line(
    20,
    82,
    width - 20,
    82
  );
}

// ============================================================
// RADAR GRID
// ============================================================

void drawRadarGrid() {
  float centerX = width / 2;
  float centerY = height - 75;

  float radarRadius =
    min(
      width * 0.46,
      height * 0.79
    );

  stroke(22, 135, 62);
  strokeWeight(1);
  noFill();

  // Distance rings
  for (int meter = 1; meter <= 5; meter++) {
    float radius =
      radarRadius *
      meter /
      5.0;

    arc(
      centerX,
      centerY,
      radius * 2,
      radius * 2,
      PI,
      TWO_PI
    );

    fill(45, 180, 85);

    textAlign(CENTER);
    textSize(13);

    text(
      meter + " m",
      centerX,
      centerY - radius + 17
    );

    noFill();
  }

  // Bearing lines
  for (
    int angle = -60;
    angle <= 60;
    angle += 10
  ) {
    float angleRadians =
      radians(angle - 90);

    float endX =
      centerX +
      cos(angleRadians) *
      radarRadius;

    float endY =
      centerY +
      sin(angleRadians) *
      radarRadius;

    line(
      centerX,
      centerY,
      endX,
      endY
    );

    float labelRadius =
      radarRadius + 18;

    fill(45, 175, 85);

    textAlign(CENTER);
    textSize(11);

    text(
      angle + "°",
      centerX +
      cos(angleRadians) *
      labelRadius,
      centerY +
      sin(angleRadians) *
      labelRadius
    );

    noFill();
  }

  stroke(70, 255, 120);
  strokeWeight(2);

  line(
    centerX,
    centerY,
    centerX,
    centerY - radarRadius
  );

  noStroke();

  fill(70, 255, 120);

  ellipse(
    centerX,
    centerY,
    15,
    15
  );

  fill(180, 255, 200);

  textAlign(CENTER);
  textSize(12);

  text(
    "SENSOR",
    centerX,
    centerY + 28
  );
}

// ============================================================
// DETECTION AREA
// ============================================================

void drawDetectionBoundary() {
  float centerX = width / 2;
  float centerY = height - 75;

  float radarRadius =
    min(
      width * 0.46,
      height * 0.79
    );

  stroke(75, 255, 125, 150);
  strokeWeight(2);
  noFill();

  float leftAngle =
    radians(
      -FIELD_OF_VIEW - 90
    );

  float rightAngle =
    radians(
      FIELD_OF_VIEW - 90
    );

  line(
    centerX,
    centerY,
    centerX +
    cos(leftAngle) *
    radarRadius,
    centerY +
    sin(leftAngle) *
    radarRadius
  );

  line(
    centerX,
    centerY,
    centerX +
    cos(rightAngle) *
    radarRadius,
    centerY +
    sin(rightAngle) *
    radarRadius
  );
}

// ============================================================
// SWEEP
// ============================================================

void drawSweep() {
  float centerX = width / 2;
  float centerY = height - 75;

  float radarRadius =
    min(
      width * 0.46,
      height * 0.79
    );

  // Fading sweep lines
  for (int i = 14; i >= 1; i--) {
    float trailAngle =
      sweepPosition -
      sweepDirection *
      i *
      1.2;

    float trailRadians =
      radians(
        trailAngle - 90
      );

    float alpha =
      map(
        i,
        1,
        14,
        100,
        4
      );

    stroke(
      60,
      255,
      120,
      alpha
    );

    strokeWeight(1);

    line(
      centerX,
      centerY,
      centerX +
      cos(trailRadians) *
      radarRadius,
      centerY +
      sin(trailRadians) *
      radarRadius
    );
  }

  float sweepRadians =
    radians(
      sweepPosition - 90
    );

  stroke(80, 255, 135);
  strokeWeight(3);

  line(
    centerX,
    centerY,
    centerX +
    cos(sweepRadians) *
    radarRadius,
    centerY +
    sin(sweepRadians) *
    radarRadius
  );
}

void updateSweep() {
  sweepPosition +=
    0.8 *
    sweepDirection;

  if (
    sweepPosition >=
    FIELD_OF_VIEW
  ) {
    sweepPosition =
      FIELD_OF_VIEW;

    sweepDirection = -1;
  }

  if (
    sweepPosition <=
    -FIELD_OF_VIEW
  ) {
    sweepPosition =
      -FIELD_OF_VIEW;

    sweepDirection = 1;
  }
}

// ============================================================
// TARGET COLORS
// ============================================================

color getTargetColor(int targetNumber) {
  if (targetNumber == 1) {
    return color(
      255,
      75,
      60
    );
  }

  if (targetNumber == 2) {
    return color(
      255,
      210,
      60
    );
  }

  return color(
    80,
    180,
    255
  );
}

// ============================================================
// DRAW TARGET
// ============================================================

void drawTarget(
  Target target,
  int targetNumber
) {
  if (!target.detected) {
    return;
  }

  int age =
    millis() -
    target.lastSeen;

  if (age > 1500) {
    target.detected = false;
    target.clearTrail();

    return;
  }

  PVector screenPosition =
    radarToScreen(
      target.x,
      target.y
    );

  color targetColor =
    getTargetColor(
      targetNumber
    );

  boolean moving =
    abs(target.speed) > 2;

  float pulse =
    28 +
    sin(
      frameCount * 0.18
    ) *
    5;

  // Outer pulse
  noFill();

  stroke(
    red(targetColor),
    green(targetColor),
    blue(targetColor),
    180
  );

  strokeWeight(2);

  ellipse(
    screenPosition.x,
    screenPosition.y,
    pulse,
    pulse
  );

  // Middle pulse
  stroke(
    red(targetColor),
    green(targetColor),
    blue(targetColor),
    80
  );

  ellipse(
    screenPosition.x,
    screenPosition.y,
    pulse + 14,
    pulse + 14
  );

  // Main target point
  noStroke();

  fill(targetColor);

  ellipse(
    screenPosition.x,
    screenPosition.y,
    16,
    16
  );

  // Center highlight
  fill(255);

  ellipse(
    screenPosition.x,
    screenPosition.y,
    5,
    5
  );

  // Speed direction line
  if (moving) {
    float direction =
      target.speed >= 0
      ? -1
      : 1;

    float vectorLength =
      constrain(
        abs(target.speed) * 1.5,
        15,
        65
      );

    stroke(targetColor);
    strokeWeight(2);

    line(
      screenPosition.x,
      screenPosition.y,
      screenPosition.x,
      screenPosition.y +
      vectorLength *
      direction
    );
  }

  // Label box
  noStroke();

  fill(
    0,
    20,
    10,
    220
  );

  rect(
    screenPosition.x + 14,
    screenPosition.y - 44,
    170,
    62,
    5
  );

  fill(targetColor);

  textAlign(LEFT);
  textSize(14);

  text(
    "TARGET " + targetNumber,
    screenPosition.x + 22,
    screenPosition.y - 25
  );

  fill(215, 255, 225);
  textSize(12);

  text(
    "Range: " +
    nf(
      target.distance / 1000.0,
      1,
      2
    ) +
    " m",
    screenPosition.x + 22,
    screenPosition.y - 8
  );

  text(
    "Bearing: " +
    nf(
      target.bearing,
      1,
      1
    ) +
    "°  Speed: " +
    int(target.speed) +
    " cm/s",
    screenPosition.x + 22,
    screenPosition.y + 9
  );
}

// ============================================================
// TARGET TRAIL
// ============================================================

void drawTargetTrail(
  Target target,
  int targetNumber
) {
  if (
    !target.detected ||
    target.trail.size() < 2
  ) {
    return;
  }

  color targetColor =
    getTargetColor(
      targetNumber
    );

  noFill();
  strokeWeight(2);

  for (
    int i = 1;
    i < target.trail.size();
    i++
  ) {
    PVector previous =
      radarToScreen(
        target.trail
          .get(i - 1)
          .x,
        target.trail
          .get(i - 1)
          .y
      );

    PVector current =
      radarToScreen(
        target.trail
          .get(i)
          .x,
        target.trail
          .get(i)
          .y
      );

    float alpha =
      map(
        i,
        1,
        target.trail.size(),
        15,
        160
      );

    stroke(
      red(targetColor),
      green(targetColor),
      blue(targetColor),
      alpha
    );

    line(
      previous.x,
      previous.y,
      current.x,
      current.y
    );
  }

  // Trail dots
  noStroke();

  for (
    int i = 0;
    i < target.trail.size();
    i++
  ) {
    PVector trailPosition =
      radarToScreen(
        target.trail.get(i).x,
        target.trail.get(i).y
      );

    float alpha =
      map(
        i,
        0,
        target.trail.size() - 1,
        10,
        120
      );

    fill(
      red(targetColor),
      green(targetColor),
      blue(targetColor),
      alpha
    );

    ellipse(
      trailPosition.x,
      trailPosition.y,
      5,
      5
    );
  }
}

// ============================================================
// COORDINATE CONVERSION
// ============================================================

PVector radarToScreen(
  float radarX,
  float radarY
) {
  float centerX = width / 2;
  float centerY = height - 75;

  float radarRadius =
    min(
      width * 0.46,
      height * 0.79
    );

  float pixelsPerMillimeter =
    radarRadius /
    MAX_RANGE_MM;

  float screenX =
    centerX +
    radarX *
    pixelsPerMillimeter;

  float screenY =
    centerY -
    radarY *
    pixelsPerMillimeter;

  return new PVector(
    screenX,
    screenY
  );
}

// ============================================================
// TARGET STATUS PANEL
// ============================================================

void drawTargetPanel() {
  float panelX = 20;
  float panelY = 105;
  float panelWidth = 290;
  float panelHeight = 260;

  fill(
    0,
    24,
    13,
    230
  );

  stroke(
    35,
    175,
    75
  );

  strokeWeight(2);

  rect(
    panelX,
    panelY,
    panelWidth,
    panelHeight,
    8
  );

  fill(
    75,
    255,
    125
  );

  textAlign(LEFT);
  textSize(18);

  text(
    "TARGET TRACKING",
    panelX + 18,
    panelY + 30
  );

  drawTargetStatus(
    target1,
    1,
    panelX + 18,
    panelY + 68
  );

  drawTargetStatus(
    target2,
    2,
    panelX + 18,
    panelY + 133
  );

  drawTargetStatus(
    target3,
    3,
    panelX + 18,
    panelY + 198
  );
}

void drawTargetStatus(
  Target target,
  int targetNumber,
  float x,
  float y
) {
  color targetColor =
    getTargetColor(
      targetNumber
    );

  if (!target.detected) {
    fill(90, 110, 95);

    textSize(14);

    text(
      "T" +
      targetNumber +
      "   NO TARGET",
      x,
      y
    );

    return;
  }

  boolean moving =
    abs(target.speed) > 2;

  fill(targetColor);
  textSize(15);

  text(
    "T" +
    targetNumber +
    "   " +
    (
      moving
      ? "MOVING"
      : "STATIONARY"
    ),
    x,
    y
  );

  fill(
    175,
    225,
    185
  );

  textSize(12);

  text(
    "Range " +
    nf(
      target.distance / 1000.0,
      1,
      2
    ) +
    " m   Bearing " +
    nf(
      target.bearing,
      1,
      1
    ) +
    "°",
    x,
    y + 20
  );

  text(
    "X " +
    int(target.x) +
    " mm   Y " +
    int(target.y) +
    " mm",
    x,
    y + 38
  );

  text(
    "Speed " +
    int(target.speed) +
    " cm/s   Resolution " +
    int(target.resolution) +
    " mm",
    x,
    y + 56
  );
}

// ============================================================
// SYSTEM PANEL
// ============================================================

void drawSystemPanel() {
  float panelWidth = 255;
  float panelX =
    width -
    panelWidth -
    20;

  float panelY = 105;

  fill(
    0,
    24,
    13,
    230
  );

  stroke(
    35,
    175,
    75
  );

  strokeWeight(2);

  rect(
    panelX,
    panelY,
    panelWidth,
    180,
    8
  );

  fill(
    75,
    255,
    125
  );

  textAlign(LEFT);
  textSize(18);

  text(
    "SYSTEM STATUS",
    panelX + 18,
    panelY + 30
  );

  boolean receiving =
    serialConnected &&
    millis() -
    lastFrameTime <
    1000;

  fill(
    receiving
    ? color(80, 255, 125)
    : color(255, 90, 70)
  );

  textSize(14);

  text(
    "UART: " +
    (
      receiving
      ? "RECEIVING"
      : "NO DATA"
    ),
    panelX + 18,
    panelY + 63
  );

  fill(
    175,
    225,
    185
  );

  text(
    "Port: " +
    SERIAL_PORT,
    panelX + 18,
    panelY + 90
  );

  text(
    "USB baud: " +
    SERIAL_BAUD,
    panelX + 18,
    panelY + 113
  );

  text(
    "Display FPS: " +
    displayedFPS,
    panelX + 18,
    panelY + 136
  );

  text(
    "Frames received: " +
    validFrames,
    panelX + 18,
    panelY + 159
  );
}

// ============================================================
// PROXIMITY WARNING
// ============================================================

void drawClosestTargetWarning() {
  Target closest = null;
  int closestNumber = 0;

  Target[] targets = {
    target1,
    target2,
    target3
  };

  for (
    int i = 0;
    i < targets.length;
    i++
  ) {
    Target target =
      targets[i];

    if (
      target.detected &&
      (
        closest == null ||
        target.distance <
        closest.distance
      )
    ) {
      closest = target;
      closestNumber = i + 1;
    }
  }

  if (
    closest == null ||
    closest.distance > 1000
  ) {
    return;
  }

  float warningWidth = 350;
  float warningX =
    width / 2 -
    warningWidth / 2;

  fill(
    120,
    15,
    5,
    225
  );

  stroke(
    255,
    85,
    45
  );

  strokeWeight(2);

  rect(
    warningX,
    95,
    warningWidth,
    48,
    7
  );

  fill(
    255,
    150,
    100
  );

  textAlign(CENTER);
  textSize(16);

  text(
    "PROXIMITY ALERT • TARGET " +
    closestNumber +
    " • " +
    nf(
      closest.distance / 1000.0,
      1,
      2
    ) +
    " m",
    width / 2,
    126
  );
}

// ============================================================
// FPS COUNTER
// ============================================================

void updateFPS() {
  if (
    millis() -
    lastFpsTime >=
    1000
  ) {
    displayedFPS =
      frameCounter;

    frameCounter = 0;
    lastFpsTime = millis();
  }
}

// ============================================================
// TARGET CLASS
// ============================================================

class Target {
  float x = 0;
  float y = 0;

  float speed = 0;
  float resolution = 0;

  float distance = 0;
  float bearing = 0;

  boolean detected = false;

  int lastSeen = 0;

  ArrayList<PVector> trail =
    new ArrayList<PVector>();

  void addTrailPoint(
    float newX,
    float newY
  ) {
    if (trail.size() > 0) {
      PVector previous =
        trail.get(
          trail.size() - 1
        );

      float movement =
        dist(
          previous.x,
          previous.y,
          newX,
          newY
        );

      if (movement < 25) {
        return;
      }

      // Ignore impossible jumps caused by bad readings
      if (movement > 2000) {
        trail.clear();
      }
    }

    trail.add(
      new PVector(
        newX,
        newY
      )
    );

    while (trail.size() > 30) {
      trail.remove(0);
    }
  }

  void clearTrail() {
    trail.clear();
  }
}
