# REDOL

REDOL is a MATLAB-based system for coordinating multiple vehicles for construction and demolition waste collection.

## Requirements

The following are required to run the system:

* MATLAB R2024b or later.
* Gurobi Optimizer 13.0.1.
* A stable internet connection to receive tasks, access maps, and communicate with the vehicles.
* A power supply with a USB Type-C connector for the MQTT device installed on each vehicle.

## Running the System

Open the project in MATLAB and run:

```matlab
main.m
```

## Configuration

The following variables can be configured in `main.m`.

### Number of Vehicles

Set the total number of operating vehicles:

```matlab
numVehicles = 1;
```

### Base-Station Location

Set the latitude and longitude of the base station:

```matlab
gps.lat = 65.61640568720362;
gps.lon = 22.139036710109025;
```

### Google Forms Data

Set `csvURL` to the URL used to retrieve the Google Forms response data:

```matlab
csvURL = "";
```

### Current Google Forms link
```
https://docs.google.com/forms/d/e/1FAIpQLSd4zHHYPpIE7eQPEr4AI8rSYFZiDHuxb-8a54ACYb-0KVBBnw/viewform?pli=1
```

> **Note:** The Google Forms response data is publicly viewable.

### MQTT Configuration

Configure `mqClient` with the MQTT broker details and login credentials:

```matlab
mqClient = ...;
```

> **Security warning:** Do not commit passwords, API keys, or other sensitive credentials to a public GitHub repository.

## Display Language

English is the default display language.

To display the instructions in Spanish, use:

```matlab
spanish = 1;
```

To display the instructions in English, use:

```matlab
spanish = 0;
```

## Publication

If you use REDOL in your research, please cite the following publication:

> S. Velhal, A. Saradagi, R. Sawlekar, and G. Nikolakopoulos, “Load-Constrained Multi-Vehicle Construction and Demolition Waste Collection Problem,” in *2026 34th Mediterranean Conference on Control and Automation (MED)*, pp. 412–417, 2026.

https://doi.org/10.1109/MED70602.2026.11598012

```bibtex
@inproceedings{velhal2026load,
  title        = {{Load-Constrained Multi-Vehicle Construction and Demolition Waste Collection Problem}},
  author       = {Velhal, Shridhar and Saradagi, Akshit and Sawlekar, Rucha and Nikolakopoulos, George},
  booktitle    = {2026 34th Mediterranean Conference on Control and Automation (MED)},
  pages        = {412--417},
  year         = {2026},
  organization = {IEEE},
  doi          = {10.1109/MED70602.2026.11598012}
}
```
