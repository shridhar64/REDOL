numTasks = 7;          % Number of tasks (excluding depot)
numVehicles =  3;            % Number of vehicles
 
 vehicleColors = [
    1.00  0.00  0.00;   % Vehicle 1 - Red
    0.00  0.45  0.74;   % Vehicle 2 - Blue
    0.00  0.65  0.20    % Vehicle 3 - Green
];

taskColor = [1.00 0.00 1.00];
baseColor = [0.7 0.7 0.7];   % Light grey


gps.lat   = 65.61640568720362;
gps.lon  =  22.139036710109025;
baseStation.gps = gps ;
baseStation.address = "Betalparkering, Parking lot, 97754 Luleå" ;


 
 %%%%%%%%%%%%%%%%% Vehicles

 for ii = 1:numVehicles
     
     vehicle.id = ii ;
     vehicle.gps = gps ;
     vehicle.currentPDTask=[];
     vehicles(ii) = vehicle;
 end


%%%%%%%%%%%%%%%%% Task 1 
id = 1 ;
task.id = id ;

gps =[];
gps.lat  = 65.60957679274838; 
gps.lon =  22.12684019110222;
task.gps = gps ;
task.address = "Risslan Återvinningscentral, Brandgatan 4, 97347 Luleå" ;
task.status   = 0;
task.capacity =  3;
task.type =    "filled";
task.contact_no = "123456789"
task_type_PD ;
 
tasks(id) = task ;

%%%%%%%%%%%%%%%%% Task 2 
id = 2 ;
task.id = id ;
 
gps.lat   =   65.6010015455584;  
gps.lon  = 22.14709080963571;
task.gps = gps ;
task.address = "Återvinningscentral, Hummergatan 11A, 97334 Luleå" ;
task.status   = 0;
task.capacity = 1;
task.type = "empty";
task_type_PD ;
tasks(id) = task ;


%%%%%%%%%%%%%%%%% Task 3 
id = 3 ;
task.id = id ;


gps.lat   = 65.60828420615371;
gps.lon  =   22.15022422869239;
task.gps = gps ;
task.address = "Torpslingan 36, 97347 Luleå" ;
task.status   = 0;
task.capacity = 3;
task.type = "filled";
task_type_PD ;
tasks(id) = task ;


%%%%%%%%%%%%%%%%% Task 4
id = 4 ;
task.id = id ;


gps.lat   = 65.59390492697734;  
gps.lon  =  22.15159364396064;
task.gps = gps ;
task.address = "Avgiftsfri parkering,  Gammelstadsvägen 19G, 97334 Luleå" ;
task.status   = 0; 
task.capacity =  2;
task.type =    "empty"
task_type_PD ;
tasks(id) = task ;



%%%%%%%%%%%%%%%%% Task 5
id = 5 ;
task.id = id ;


gps.lat   = 65.6191715895506;
gps.lon  =  22.045191926116843;
task.gps = gps ;
task.address = "Återvinningsstation,  Besiktningsvägen 21, 97345 Luleå" ;
task.status   = 0;
task.capacity =  1;
task.type =   "empty"
task_type_PD ;
tasks(id) = task ;
 



%%%%%%%%%%%%%%%%% Task 6 

id = 6 ;
task.id = id ;

 
gps.lat  = 65.61461871707517;
gps.lon = 22.04893885376491;
task.gps = gps ;
task.address = "Kuusakoski Sverige AB, Cementvägen 3, 97345 Luleå";
task.status   = 0;
task.capacity = 3;
task.type = "filled";
task_type_PD ;
tasks(id) = task ;

%%%%%%%%%%%%%%%%% Task 7 

id = 7;
task.id = id;

 
gps.lat = 65.62431729691197;
gps.lon = 22.14829513575248;
task.gps = gps;
task.address = "Återvinningscentral, Assistentvägen 5, 97752 Luleå";
task.status   = 0;
task.capacity = 3;
task.type = "filled";
task_type_PD ;
tasks(id) = task ;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Display all task locations on OpenStreetMap

 
%% =========================================================
%  Combined Map:
%  Vehicles + Tasks + Base Station
%% =========================================================


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