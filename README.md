# REDOL

## Running the Program

Run `main.m` in MATLAB.

## Configuration

You can modify the following variables in `main.m`:

```matlab
numVehicles = 1;  % Total number of operating vehicles

gps.lat = 65.61640568720362;   % Latitude of the base station
gps.lon = 22.139036710109025;  % Longitude of the base station

csvURL = "";  % URL used to read the Google Forms response data
```

> **Note:** The Google Forms response data is currently publicly accessible.

Configure `mqClient` with the MQTT broker details and login credentials:

```matlab
mqClient = ...;
```

For security, do not commit passwords, API keys, or other sensitive credentials to the GitHub repository.

## Display Language

English is the default display language.

To display the instructions in Spanish, set:

```matlab
spanish = 1;
```

To use English, set:

```matlab
spanish = 0;
```
