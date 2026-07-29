#include <Arduino.h>

HardwareSerial radarSerial(2);

constexpr int RADAR_RX_PIN = 16; // RX2
constexpr int RADAR_TX_PIN = 17; // TX2
constexpr uint32_t RADAR_BAUD = 256000;

constexpr size_t FRAME_SIZE = 30;
uint8_t frame[FRAME_SIZE];
size_t frameIndex = 0;

struct Target {
  int16_t x;
  int16_t y;
  int16_t speed;
  uint16_t resolution;
};

int16_t decodeRadarValue(uint8_t lowByte, uint8_t highByte) {
  uint16_t raw =
      static_cast<uint16_t>(lowByte) |
      (static_cast<uint16_t>(highByte) << 8);

  int16_t magnitude = raw & 0x7FFF;

  return (raw & 0x8000) ? magnitude : -magnitude;
}

Target readTarget(size_t offset) {
  Target target;

  target.x = decodeRadarValue(
      frame[offset],
      frame[offset + 1]
  );

  target.y = decodeRadarValue(
      frame[offset + 2],
      frame[offset + 3]
  );

  target.speed = decodeRadarValue(
      frame[offset + 4],
      frame[offset + 5]
  );

  target.resolution =
      static_cast<uint16_t>(frame[offset + 6]) |
      (static_cast<uint16_t>(frame[offset + 7]) << 8);

  return target;
}

bool targetExists(const Target& target) {
  return target.x != 0 ||
         target.y != 0 ||
         target.speed != 0 ||
         target.resolution != 0;
}

void printTargetData(const char* name, const Target& target) {
  Serial.print(name);
  Serial.print(",");

  if (targetExists(target)) {
    Serial.print(target.x);
    Serial.print(",");

    Serial.print(target.y);
    Serial.print(",");

    Serial.print(target.speed);
    Serial.print(",");

    Serial.print(target.resolution);
  } else {
    Serial.print("0,0,0,0");
  }
}

void processFrame() {
  bool validHeader =
      frame[0] == 0xAA &&
      frame[1] == 0xFF &&
      frame[2] == 0x03 &&
      frame[3] == 0x00;

  bool validFooter =
      frame[28] == 0x55 &&
      frame[29] == 0xCC;

  if (!validHeader || !validFooter) {
    return;
  }

  Target target1 = readTarget(4);
  Target target2 = readTarget(12);
  Target target3 = readTarget(20);

  printTargetData("T1", target1);
  Serial.print(";");

  printTargetData("T2", target2);
  Serial.print(";");

  printTargetData("T3", target3);
  Serial.println();
}

void readRadar() {
  while (radarSerial.available() > 0) {
    uint8_t incomingByte = radarSerial.read();

    if (frameIndex == 0 && incomingByte != 0xAA) {
      continue;
    }

    if (frameIndex == 1 && incomingByte != 0xFF) {
      frameIndex = 0;

      if (incomingByte == 0xAA) {
        frame[frameIndex++] = incomingByte;
      }

      continue;
    }

    frame[frameIndex++] = incomingByte;

    if (frameIndex == FRAME_SIZE) {
      processFrame();
      frameIndex = 0;
    }
  }
}

void setup() {
  Serial.begin(115200);

  radarSerial.setRxBufferSize(2048);
  radarSerial.begin(
      RADAR_BAUD,
      SERIAL_8N1,
      RADAR_RX_PIN,
      RADAR_TX_PIN
  );

  delay(1000);
  Serial.println("RADAR_READY");
}

void loop() {
  readRadar();
}
