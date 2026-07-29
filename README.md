# RD03D-Multi-Target-Radar

Real-time 24GHz mmWave radar visualization using an ESP32, Ai-Thinker RD-03D, and Processing (Java) with live multi-target tracking.

---

## Features

- Live detection of up to three human targets
- Real-time radar visualization using Processing (Java)
- Displays target position, distance, speed, and tracking information
- Custom radar interface with animated sweep and target trails
- Communication between ESP32 and PC over USB Serial

---

## Hardware Required

- ESP32 DevKit V1
- Ai-Thinker RD-03D 24GHz mmWave Radar
- Micro USB cable
- Jumper wires
- Windows PC (or any computer capable of running Processing)

---

## Wiring Diagram

Connect the RD-03D to the ESP32 as follows:

| RD-03D | ESP32 |
|--------|-------|
| VCC | VIN (5V) |
| GND | GND |
| TX | RX2 (GPIO16) |
| RX | TX2 (GPIO17) |

> **Note:** The RD-03D communicates at **256000 baud**, which is why an ESP32 hardware serial port is used instead of SoftwareSerial.

---

## Arduino Setup

1. Install the Arduino IDE.
2. Install the ESP32 Board Package.
3. Open `RD03D_ESP32.ino`.
4. Select your ESP32 board.
5. Upload the sketch.
6. Open the Serial Monitor if you want to view the decoded radar data.

The ESP32 will continuously decode incoming radar frames and send formatted target information to the PC over USB.

---

## Processing Setup

1. Install Processing 4.
2. Open `RadarDisplay.pde`.
3. Change the COM port if necessary:

```java
new Serial(this, "COM3", 115200);
```

Replace `COM3` with your ESP32's serial port.

4. Run the sketch.

The radar display should immediately begin showing detected targets.

---

## Project Structure

```
RD03D-Multi-Target-Radar
│
├── RD03D_ESP32.ino
├── RadarDisplay.pde
└── README.md
```

---

## Technologies Used

- ESP32
- Arduino C++
- Processing (Java)
- UART Serial Communication
- 24GHz mmWave Radar
- Embedded Systems

---

## Future Improvements

- Detection zone configuration
- Logging target history
- Multiple radar support
- Occupancy heat map
- Bluetooth / Wi-Fi support
- Data recording and playback

---

## Author

**Kenneth Dandrow**

GitHub:
https://github.com/ktdshock
