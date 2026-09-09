% Tightened parameters
addpath(genpath( 'C:\gurobi1301\win64\matlab'));
savepath
gurobi_setup
addpath(genpath('C:\Program Files\MATLAB\R2024b\YALMIP'));
savepath

vehicleCapacity = 3

bigM= vehicleCapacity - min(nodeDemands);

 depot = 1;                              % Depot node index
pickupNodes = 2:numTasks+1;             % Pickup nodes (2-6)
dropoffNodes = numTasks+2:2*numTasks+1; % Dropoff nodes (7-11)
numNodes = 2*numTasks + 1;              % Total nodes

% Optimization Problem


% Decision Variables
% % x = optimvar('x', numNodes, numNodes, numVehicles, 'Type','integer', ...
% %              'LowerBound',0, 'UpperBound',1);
% % u = optimvar('u', numNodes, numVehicles,'Type','integer',...
% %             'LowerBound',0, 'UpperBound',vehicleCapacity); % Includes depot
% % 
% % uu = optimvar('uu', numNodes, numVehicles,'Type','integer',...
% %             'LowerBound',0, 'UpperBound',numNodes); % Includes depot


% Decision variables (YALMIP)
x = binvar(numNodes, numNodes, numVehicles, 'full');   % binary arcs
u = intvar(numNodes, numVehicles, 'full');             % load
uu = intvar(numNodes, numVehicles, 'full');            % sequence index
maxDistance = sdpvar(1,1);

% Big-M constants (as in your original)
M_capacity = vehicleCapacity + max(nodeDemands);
M_sequence = numNodes - 1;
% bigMM = numNodes;

%%%%%%%% Objective
 
Objective = 0;
 Objective_sum = 0;
for k = 1:numVehicles

    % Cost/distance of vehicle k
   

    vehicleDistance(k) = sum(sum(costMatrix .* x(:,:,k)));

 
     

end
% Total distance of all vehicles  
Objective_sum = sum(vehicleDistance);

% Add maximum vehicle distance to objective
 
Objective = Objective_sum + 10*  maxDistance;




 Constraints_eq =[];
Constraints_ineq =[];
M_capacity = vehicleCapacity + max(nodeDemands);
M_sequence = numNodes - 1;

% % Vectorized objective
%  Objective = sum(costMatrix .* sum(x,3),'all');

% Build constraints
F = [];

% Variable bounds (u and uu bounds reflect original)
F = [F, 0 <= u <= vehicleCapacity];
F = [F, 0 <= uu <= numNodes];
% x is binary by construction.



% Flow conservation (vectorized)
for k = 1:numVehicles
    for h = 1:numNodes
        F = [F, sum(x(h,:,k),2) == sum(x(:,h,k),1)];
    end
end

% 2. Depot start/end
for k = 1:numVehicles
    F = [F, sum(x(depot,:,k),2) == 1];
    F = [F, sum(x(:,depot,k),1) == 1];
 end
      

% 3. Task completion
for t = 1:numTasks
    p = pickupNodes(t);
    d = dropoffNodes(t);
    F = [F, sum(sum(x(:,p,:))) == 1];
    F = [F, sum(sum(x(:,d,:))) == 1];
       
end

  
%4 Tightened capacity constraints
for k = 1:numVehicles
    for i = [pickupNodes, dropoffNodes]  % Only needed for task nodes
        incoming = sum(x(:,i,k),1); 
        F = [F, u(i,k) <= vehicleCapacity * incoming];
    end
end

%% 5 LoadFlow constraints:
for k = 1:numVehicles
    for i =  1:numNodes
        for j =  1:numNodes      
            if i == j, continue; end
            F = [F, u(j,k) >= u(i,k) + nodeDemands(j) - M_capacity*(1 - x(i,j,k))];
        end
    end
end


% % %6 Precompute node pairs to reduce nested loops  
% % %%%%%Sequence constraints (exclude depot)
% % [ii,jj] = meshgrid(2:numNodes, 2:numNodes);
% % valid_pairs = find(ii(:) ~= jj(:));
% % for k = 1:numVehicles
% %     for p = 1:length(valid_pairs)
% %         pair = valid_pairs(p);
% %         i = ii(pair);
% %         j = jj(pair);
% %          F = [F,  uu(j,k)  >= uu(i,k) + 1 - M_sequence*(1 - x(i,j,k))  ];
% %      end
% % end
for k = 1:numVehicles
    for i = 2:numNodes          % exclude depot (index 1)
        for j = 2:numNodes      % exclude depot
            if i == j, continue; end
            F = [F,    uu(i,k) + 1 - M_sequence*(1 - x(i,j,k)) <= uu(j,k) ];
        end
    end
end



%7 Stronger PD constraints
for t = 1:numTasks
    p = pickupNodes(t);
    d = dropoffNodes(t);
    
    for k = 1:numVehicles
        % Only need to enforce if both nodes are served by this vehicle
        % sameVehicle = sum(x(:,p,k)) + sum(x(:,d,k));
         % PD_Order: uu(p,k) <= uu(d,k) - 1 + M_sequence*(1 - sum(x(:,p,k)))
        F = [F, uu(p,k) <= uu(d,k) - 1 + M_sequence*(1 - sum(x(:,p,k)))];

        % seq_task (preserved original indexing)
        % % % % F = [F, uu(t,k) <= M_sequence * (sum(x(:,t,k)))];

        % same vehicle
        F = [F, sum(x(:,d,k)) == sum(x(:,p,k))];
    end
end

% 8. No self-loops
for k = 1:numVehicles
    for i = 1:numNodes
          F = [F, x(i,i,k) == 0];
    end
end


%%%%%%%% Maximum vehicle distance constraints

for k = 1:numVehicles
    F = [F,         maxDistance >= vehicleDistance(k)];
end



x0 = zeros(numNodes,numNodes,numVehicles);
u0 = zeros(numNodes ,numVehicles);
uu0 = 12*ones(numNodes, numVehicles);

% x0(1,2,1) = 1;
% x0(2,4,1) = 1;
% x0(numTasks+2,numTasks+4,1) = 1;
% x0(numTasks+4,5,1) = 1;
% x0(5,numTasks+5,1)= 1;
% x0( numTasks+5,1,1)= 1;
% 
% 
% x0(1,7,2) = 1;
% x0(7,numTasks+7,2) = 1;
% x0(numTasks+7, 9,2) = 1;
% x0(9,numTasks+9 ,2) = 1;
% x0( numTasks+9 ,3,2) = 1;
% x0(  3,numTasks+3,2) = 1;
% x0(  numTasks+3,1,2) = 1;
% 
% 
% x0(1, 6,3)= 1;
% x0(6, numTasks+6,3)= 1;
% x0(  numTasks+6, 8, 3)= 1;
% x0(  8, numTasks+  8, 3)= 1;
% x0(    numTasks+8,1, 3)= 1;
% 
% 
% 
% u0(2,1)=1;
% u0(4,1)=2;
% u0(11,1)=1;
% u0(5,1)=3;
% 
% u0(7,2) = 2
% u0(9,2) = 3
% u0(3,2) = 3
% 
% 
% u0(6,3) = 1
% u0(8,3) = 3
% 
% 
% uu0(2,1) = 1
% uu0(4,1) = 2
% uu0(10,1)= 3
% uu0(13,1) = 4 
% uu0(5,1) = 5
% uu0(14,1) = 6
% 
% uu0(7,2) = 1
% uu0(15,2) = 2
% uu0(9,2) = 3
% uu0(17,2) =4
% uu0(3,2) = 5
% uu0(12,2) = 6
% 
% 
% 
%  uu0(6,3) = 1
%  uu0(14,3) = 2
% uu0(8,3) = 3
% uu0(16,3) = 4

 % Ensure integrality / bounds and types are numeric doubles
x0 = double(x0);
u0 = round(double(u0));
uu0 = round(double(uu0));
maxDistance0 = 0;
% Assign to YALMIP variables (this is the warm start)
assign(x, x0);
assign(u, u0);
assign(uu, uu0);
assign(maxDistance, maxDistance0);

cost_00 = compute_guess_cost(costMatrix, x0);
 
ops = sdpsettings('solver','gurobi','verbose',1); 
ops.gurobi.MIPGap = 0.2;
% % % Optional: speed parameters
% % 
% % % ops.gurobi.TimeLimit  = 100;
% % ops.gurobi.MIPGap = 0.52;       %   optimality gap
% % ops.gurobi.Heuristics = 0.8;    % even more emphasis on heuristics
% % ops.gurobi.Cuts = 1;            % no cutting planes
% % ops.gurobi.Presolve =  2;        % aggressive presolve
% % ops.gurobi.Threads = 4;         % use 4 threads (adjust to CPU)
% % % ops.gurobi.MIPFocus     = 1;      % focus on finding feasible solutions 
% % ops.gurobi.OutputFlag   = 1;      % show solver output
% % 
% % ops.gurobi.Aggregate = 1;        % merge similar rows for faster solves
% % ops.gurobi.VarBranch = 2;        % branching strategy
% % ops.gurobi.NodeMethod = 2;       % dual simplex at nodes


% % 
% % % Map options
% % ops.gurobi.MIPGap         = 0.52;     % RelativeGapTolerance
% % ops.gurobi.FeasibilityTol = 1e-2;     % ConstraintTolerance
% % ops.gurobi.IntFeasTol     = 1e-2;     % IntegerTolerance (check Gurobi version)
% % ops.gurobi.Cuts           = 0;        % CutGeneration = 'none'
% % ops.gurobi.Heuristics     = 0.5;      % 'advanced' heuristics (0..1). Increase to 0.8 if you want more
% % ops.gurobi.MIPFocus       = 1;        % focus on finding feasible incumbents quickly (optional)
% % ops.gurobi.Presolve       = 1;        % basic presolve
% % ops.gurobi.Method         = 1;        % dual simplex for root LP
% % ops.gurobi.OutputFlag     = 1;        % show solver log


% Map options
ops.gurobi.MIPGap         = 0.05;     % RelativeGapTolerance
ops.gurobi.OutputFlag     = 1;        % show solver log

 
sol = optimize( F,  Objective, ops);

if sol.problem == 0
    disp('Solver found a feasible solution:');
    x_val = value(x);
    u_val = value(u);
    uu_val = value(uu);
    maxDistance_val = value(maxDistance);
    fval = value(Objective);

    xx1 = x_val(:,:,1);
    xx2 = x_val(:,:,2);
    sol.x = x_val;
    fprintf('Objective value: %.2f\n', value(Objective));
else
    disp('Solver failed or problem infeasible');
end

     x_val = value(x);
    u_val = value(u);
    uu_val = value(uu);
    maxDistance_val = value(maxDistance);
    fval = value(Objective);

    xx1 = x_val(:,:,1);
    xx2 = x_val(:,:,2);
    sol.x = x_val;  
 



% Return variables to workspace for inspection
 


% % % % % [c, ceq] = infeasibility( Constraints, sol)
% % [sol, fval, exitflag] = solve(prob,'Options',opts);
% % 
% % % Display solution
% % if exitflag == 1
% %     disp(['Total cost: ', num2str(fval)]);
% %     for k = 1:numVehicles
% %         active_arcs = find(round(sol.x(:,:,k)));
% %         disp(['Vehicle ',num2str(k),' route:']);
% %         disp(active_arcs');
% %     end
% %     xx1 = sol.x(:,:,1);xx2 = sol.x(:,:,2);
% % else
% %     disp('No feasible solution found');
% % end
% % 
% % readble_solution


% save('sol_1','x_val','u_val','u_val')