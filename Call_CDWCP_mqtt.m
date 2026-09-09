function [Final_Routes locations] = Call_CDWCP_mqtt(mqttData,baseStation)


 

  

 


%% Vehicles: [ID, X, Y, speed(units/hr), capacity]
 
vehiclenames = fieldnames(mqttData.gps);
numVehicles = numel(vehiclenames);

for ii=1:numVehicles
    vehicles(ii).id       = ii ;
    vehicleName = "vehicle" + ii;
    vehicles(ii).gps      = mqttData.gps.(vehicleName);
    vehicles(ii).speed    = 40;
    vehicles(ii).capacity = 3;
    vehicles(ii).time     = 0;       % current time (vehicle available at)
    vehicles(ii).route    = [];      % assigned task IDs in order
    vehicles(ii).load     = 0;       % number of containers currently onboard
    vehicles(ii).carry    = [];      % list of container IDs onboard
end

numTasks = numel(mqttData.tasks);

for ii=1:numTasks
     tasks(ii) = mqttData.tasks(ii);
end


 






locations =  [baseStation.gps.lat   baseStation.gps.lon   ];
veh_loc =[];
for ii = 1:numVehicles
veh_loc= [veh_loc;  vehicles(ii).gps ];
end
pickup_loc = [];
delivery_loc= [];
for ii = 1:numTasks

 
pickup_loc = [pickup_loc; tasks(ii).pickup.lat  tasks(ii).pickup.lon];
delivery_loc = [delivery_loc; tasks(ii).delivery.lat   tasks(ii).delivery.lon];

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
counter = find(isnan(costMatrix));

% pickupNodes = 1+numVehicles:1+numVehicles+numTasks

vehicleCapacity = 3;


% [distance_km ] = getRoadDistance( baseStation.gps,tasks(1).gps)

% fprintf("Driving distance: %.2f km\n", distance_km);
% 
% 
solve_CDWCP_gurobi_lulea
readble_solution_Lulea
 
end

 