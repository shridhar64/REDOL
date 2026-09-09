% Initialize routes for each vehicle
vehicleRoutes = cell(numVehicles, 1);

for k = 1:numVehicles
    % Get the solution matrix for this vehicle (rounded to handle numerical tolerances)
    x_k = round(sol.x(:,:,k));
    
    % Find all edges used by this vehicle
    [i_vals, j_vals] = find(x_k);
    
    % Handle case where vehicle is unused
    if isempty(i_vals)
        vehicleRoutes{k} = [depot, depot]; % Starts and ends at depot
        continue;
    end
    
    % Build adjacency list
    adjList = cell(numNodes, 1);
    for m = 1:length(i_vals)
        from = i_vals(m);
        to = j_vals(m);
        adjList{from} = to;
    end
    
    % Start building route from depot
    current_node = depot;
    route = [];
    max_steps = numNodes * 2; % Prevent infinite loops
    
    while ~isempty(current_node) && max_steps > 0
        route = [route, current_node];
        next_node = adjList{current_node};
        
        % Stop if we've returned to depot or hit a dead end
        if isempty(next_node) || (current_node == depot && length(route) > 1)
            break;
        end
        
        current_node = next_node;
        max_steps = max_steps - 1;
    end
    
    % Ensure route ends at depot if it started there
    if route(1) == depot && route(end) ~= depot
        route = [route, depot];
    end
    
    
    vehicleRoutes{k} = route;
end
for k = 1:numVehicles
    first_node(k) = vehicleRoutes{k}(1);
    vehicle_pos(k) = vehicles(k).gps;
end
C_0_matrix =[];
for ii = 1:numVehicles
    for jj = 1:numVehicles
        gps1 = [vehicle_pos(ii).lat vehicle_pos(ii).lon];
        gps2 = locations(first_node(jj),:);
        C_0_matrix(ii,jj) = getRoadDistance( gps1, gps2  );
    end
end
M = matchpairs(C_0_matrix, 100)

for ii = 1:numVehicles    
    Final_Routes{M(ii,1)} = vehicleRoutes{M(ii,1)}(2:end) ;
end



% Convert node indices to task IDs
taskSequences = cell(numVehicles, 1);
for k = 1:numVehicles
    route = Final_Routes{k};
    task_seq = {};
    
    for node = route
        if node == depot
            task_seq{end+1} = 'Depot';
        elseif ismember(node, pickupNodes)
            task_id = find(pickupNodes == node);
            task_seq{end+1} = sprintf('P%d', task_id);
        elseif ismember(node, dropoffNodes)
            task_id = find(dropoffNodes == node);
            task_seq{end+1} = sprintf('D%d', task_id);
        end
    end
    
    taskSequences{k} = strjoin(task_seq, ' -> ');
end

% Display results
disp('Vehicle Routes:');
for k = 1:numVehicles
    fprintf('Vehicle %d: %s\n', k, taskSequences{k});
end


 