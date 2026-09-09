% Lulea_city_experiment
 
% clc
% clear all
% close all
% 
% 
% 
% 
% 
% 
% Lulea_tasks





  

 


%% Vehicles: [ID, X, Y, speed(units/hr), capacity]
vehicleData = [
    1      40 3;
    2      40 3 ;
    3      40 3 ];

for i=1:size(vehicleData,1)
    vehicles(i).id       = vehicleData(i,1);
    vehicles(i).gps      = baseStation.gps;
    vehicles(i).speed    = vehicleData(i,2);
    vehicles(i).capacity = vehicleData(i,3);
    vehicles(i).time     = 0;       % current time (vehicle available at)
    vehicles(i).route    = [];      % assigned task IDs in order
    vehicles(i).load     = 0;       % number of containers currently onboard
    vehicles(i).carry    = [];      % list of container IDs onboard
end




locations =  [baseStation.gps.latitude   baseStation.gps.longitude   ];
veh_loc =[];
for ii = 1:numVehicles
veh_loc= [veh_loc;  vehicles(ii).gps ];
end
pickup_loc = [];
delivery_loc= [];
for ii = 1:numTasks
pickup_loc = [pickup_loc; tasks(ii).pickup.latitude  tasks(ii).pickup.longitude];
delivery_loc = [delivery_loc; tasks(ii).delivery.latitude   tasks(ii).delivery.longitude];

end

locations = [locations; pickup_loc; delivery_loc];

tassk_capacity = []
for ii = 1:numTasks
    tassk_capacity(ii) = tasks(ii).capacity;
end
taskDemands =  tassk_capacity ;

nodeDemands = [0 taskDemands -taskDemands];
numNodes = size(locations, 1);
costMatrix = zeros(numNodes);
counter = 0 
for i = 1:numNodes-1
    for j = i+1:numNodes
        if locations(i,:) ~= locations(j,:)
            counter = counter + 1 ;
            costMatrix(i,j) = getRoadDistance( locations(i,:), locations(j,:) );
        else
            costMatrix(i,j) = 0;
        end

        costMatrix(j,i) = costMatrix(i,j);
    end
end
counter

find(isnan(costMatrix))

% pickupNodes = 1+numVehicles:1+numVehicles+numTasks

vehicleCapacity = 3;


% [distance_km ] = getRoadDistance( baseStation.gps,tasks(1).gps)

% fprintf("Driving distance: %.2f km\n", distance_km);
% 
% 
solve_CDWCP_gurobi_lulea

 