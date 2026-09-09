gps_vehicle_view = vehicles(vehicleID).gps;

vehicleMarker(vehicleID).LatitudeData = gps_vehicle_view.lat;
vehicleMarker(vehicleID).LongitudeData = gps_vehicle_view.lon;

%% Refresh figure
drawnow limitrate;