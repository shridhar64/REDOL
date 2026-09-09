 numTasks = 7;          % Number of tasks (excluding depot)
%numVehicles =  3;            % Number of vehicles
 
 vehicleColors = [
    1.00  0.00  0.00;   % Vehicle 1 - Red
    0.00  0.45  0.74;   % Vehicle 2 - Blue
    0.00  0.65  0.20    % Vehicle 3 - Green
];

taskColor = [1.00 0.00 1.00];
baseColor = [0.7 0.7 0.7];   % Light grey




 
 %%%%%%%%%%%%%%%%% Vehicles

 for ii = 1:numVehicles
     
     vehicle.id = ii ;
     vehicle.gps = gps ;
     vehicle.currentPDTask=[];
     vehicles(ii) = vehicle;
 end

 



 


[tasks, formData] = fetchFormResponses(csvURL,baseStation);


numTasks = length(tasks);  



%% Create ONE figure and ONE geographic axes
figure('Name', 'Vehicle and Task Tracking');

gx = geoaxes;

geobasemap(gx, 'streets');

hold(gx, 'on');


%% =========================================================
%  1. VEHICLES
%% =========================================================

% Store marker handles so GPS locations can be updated later
vehicleMarker = gobjects(numVehicles,1);

for i = 1:numVehicles

    % Initially NaN until GPS data is received
    vehicleMarker(i) = geoscatter(gx, ...
        NaN, NaN, ...
        50, ...
        vehicleColors(i,:),...
        'filled', ...
        'DisplayName', "Vehicle " + i);

end


%% =========================================================
%  2. TASK LOCATIONS
%% =========================================================

for id = 1:numTasks
    shapee =[];
    % Task GPS
    lat = tasks(id).gps.lat;
    lon = tasks(id).gps.lon;

    if tasks(id).type == "filled"
         geoscatter(gx, ...
        lat, lon, ...
        50, ...
        taskColor,...
        '^', ...
        'filled', ...
        'HandleVisibility', 'off');
    else
        geoscatter(gx, ...
        lat, lon, ...
        50, ...
        taskColor,...
        '^', ...
        'HandleVisibility', 'off');
    end 


    % Plot task
    

    % Task label
    text(gx, ...
        lat, lon, ...
        "  Task " + id, ...
        'FontWeight', 'bold', ...
        'FontSize', 10);

end


%% =========================================================
%  3. BASE STATION
%% =========================================================

geoscatter(gx, ...
    baseStation.gps.lat, ...
    baseStation.gps.lon, ...
    250, ...
    baseColor, ...
    'square', ...     
    'DisplayName', 'Base Station');

% Base station label
text(gx, ...
    baseStation.gps.lat, ...
    baseStation.gps.lon, ...
    "  Base Station", ...
    'FontWeight', 'bold', ...
    'FontSize', 10);


%% =========================================================
%  MAP SETTINGS
%% =========================================================

title(gx, 'Real-Time Vehicle and Task Locations');

legend(gx, 'show', 'Location', 'best');

hold(gx, 'off'); 

 

 