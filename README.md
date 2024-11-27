# Fix for Microphone LED Indicator in Linux

This script fixes the issue with the microphone LED indicator on the key, showing its state (on/off).

---

## Installation


Copy the script to a system directory:
```bash
sudo cp mic-monitor.sh /usr/local/bin/
```
Set the necessary permissions:
```bash
sudo chmod +x /usr/local/bin/mic-monitor.sh
```
### Setting Up the Service

In this case, the code is for a systemd service.

Create the service file:
```bash
sudo nano /etc/systemd/system/mic-led.service
```

Service file code:
```ini
[Unit]
Description=Monitor microphone state and control LED
After=sound.target pipewire.service pulseaudio.service
Requires=sound.target

[Service]
Type=simple
ExecStart=/usr/local/bin/mic-monitor.sh
Restart=always
User=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```
### Starting the Service

Enable the service for auto startup:
```bash
sudo systemctl enable mic-led.service
```
Start the service:
```bash
sudo systemctl start mic-led.service
```
