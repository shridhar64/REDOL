% solve_vrp_gurobi.m
% Solve the provided VRP/PD MILP using Gurobi (MATLAB interface).
%
% Usage:
%   [sol, fval, exitflag, result] = solve_vrp_gurobi(costMatrix, nodeDemands, ...
%       numTasks, numVehicles, vehicleCapacity, gurobiParams)

function [sol, fval, exitflag, result] = solve_vrp_gurobi(costMatrix, nodeDemands, ...
    numTasks, numVehicles, vehicleCapacity, gurobiParams)

if nargin < 6, gurobiParams = struct(); end

% Indices and sizes
depot = 1;
pickupNodes = 2:numTasks+1;
dropoffNodes = numTasks+2:2*numTasks+1;
numNodes = 2*numTasks + 1;

% Big-M values
M_capacity = vehicleCapacity + max(nodeDemands);
M_sequence = numNodes - 1;
bigMM = numNodes;

% Variable indexing helpers (1-based)
nx = numNodes * numNodes * numVehicles;    % number of x variables
nu = numNodes * numVehicles;               % number of u variables
nuu = numNodes * numVehicles;              % number of uu variables
nvars = nx + nu + nuu;

idx_x = @(i,j,k) ((k-1)*numNodes*numNodes) + (i-1)*numNodes + j; % i and j in 1..numNodes
idx_u = @(i,k) nx + (k-1)*numNodes + i;
idx_uu = @(i,k) nx + nu + (k-1)*numNodes + i;

% Objective vector (costs on x only)
c = zeros(nvars,1);
for k = 1:numVehicles
    for i = 1:numNodes
        for j = 1:numNodes
            c(idx_x(i,j,k)) = costMatrix(i,j);
        end
    end
end

% Variable bounds and types
lb = -inf(nvars,1);
ub = inf(nvars,1);
vtype = repmat('C', nvars, 1);

% x variables: binary, bounds 0..1
for k = 1:numVehicles
    for i = 1:numNodes
        for j = 1:numNodes
            ix = idx_x(i,j,k);
            lb(ix) = 0;
            ub(ix) = 1;
            vtype(ix) = 'B';
        end
    end
end

% u variables: integer load 0..vehicleCapacity
for k = 1:numVehicles
    for i = 1:numNodes
        iu = idx_u(i,k);
        lb(iu) = 0;
        ub(iu) = vehicleCapacity;
        vtype(iu) = 'I';
    end
end

% uu variables: integer sequence 0..numNodes
for k = 1:numVehicles
    for i = 1:numNodes
        iuu = idx_uu(i,k);
        lb(iuu) = 0;
        ub(iuu) = numNodes;
        vtype(iuu) = 'I';
    end
end

% Prepare vectors for sparse constraint matrix
Irow = [];
Jcol = [];
Vval = [];
RHS = [];
SENSE = [];

% 1) Flow conservation: sum_j x(i,j,k) - sum_j x(j,i,k) == 0
for k = 1:numVehicles
    for i = 1:numNodes
        cols = zeros(1,2*numNodes);
        vals = zeros(1,2*numNodes);
        idx = 0;
        for j = 1:numNodes
            idx = idx + 1; cols(idx) = idx_x(i,j,k); vals(idx) = 1;
            idx = idx + 1; cols(idx) = idx_x(j,i,k); vals(idx) = -1;
        end
        [Irow,Jcol,Vval,RHS,SENSE] = append_row(Irow,Jcol,Vval,RHS,SENSE, cols(1:idx), vals(1:idx), 0, '=');
    end
end

% 2) Depot start/end per vehicle
for k = 1:numVehicles
    cols = arrayfun(@(j) idx_x(depot,j,k), 1:numNodes);
    vals = ones(1,numNodes);
    [Irow,Jcol,Vval,RHS,SENSE] = append_row(Irow,Jcol,Vval,RHS,SENSE, cols, vals, 1, '=');
    
    cols = arrayfun(@(i) idx_x(i,depot,k), 1:numNodes);
    vals = ones(1,numNodes);
    [Irow,Jcol,Vval,RHS,SENSE] = append_row(Irow,Jcol,Vval,RHS,SENSE, cols, vals, 1, '=');
end

% 3) Task completion: each pickup and dropoff visited exactly once across all vehicles
for t = 1:numTasks
    p = pickupNodes(t);
    d = dropoffNodes(t);
    cols = []; vals = [];
    for k = 1:numVehicles
        for i = 1:numNodes
            cols(end+1) = idx_x(i,p,k); vals(end+1) = 1;
        end
    end
    [Irow,Jcol,Vval,RHS,SENSE] = append_row(Irow,Jcol,Vval,RHS,SENSE, cols, vals, 1, '=');
    
    cols = []; vals = [];
    for k = 1:numVehicles
        for i = 1:numNodes
            cols(end+1) = idx_x(i,d,k); vals(end+1) = 1;
        end
    end
    [Irow,Jcol,Vval,RHS,SENSE] = append_row(Irow,Jcol,Vval,RHS,SENSE, cols, vals, 1, '=');
end

% 4) Tightened capacity constraints: u(i,k) - vehicleCapacity*sum_j x(j,i,k) <= 0
for k = 1:numVehicles
    for i = [pickupNodes, dropoffNodes]
        cols = [ idx_u(i,k), arrayfun(@(j) idx_x(j,i,k), 1:numNodes) ];
        vals = [1, -vehicleCapacity * ones(1,numNodes)];
        [Irow,Jcol,Vval,RHS,SENSE] = append_row(Irow,Jcol,Vval,RHS,SENSE, cols, vals, 0, '<');
    end
end

% 5) LoadFlow constraints:
%    u(i,k) - u(j,k) - M_capacity * x(i,j,k) <= -nodeDemands(j) - M_capacity
for k = 1:numVehicles
    for i = 1:numNodes
        for j = 1:numNodes
            if i == j, continue; end
            cols = [ idx_u(i,k), idx_u(j,k), idx_x(i,j,k) ];
            vals = [ 1, -1, -M_capacity ];
            rhs_val = -nodeDemands(j) - M_capacity;
            [Irow,Jcol,Vval,RHS,SENSE] = append_row(Irow,Jcol,Vval,RHS,SENSE, cols, vals, rhs_val, '<');
        end
    end
end

% 6) Sequence constraints for task nodes (exclude depot from sequence pairs)
for k = 1:numVehicles
    for i = 2:numNodes
        for j = 2:numNodes
            if i == j, continue; end
            cols = [ idx_uu(i,k), idx_uu(j,k), idx_x(i,j,k) ];
            vals = [ 1, -1, bigMM ];
            rhs_val = bigMM - 1;
            [Irow,Jcol,Vval,RHS,SENSE] = append_row(Irow,Jcol,Vval,RHS,SENSE, cols, vals, rhs_val, '<');
        end
    end
end

% 7) Stronger PD constraints and seq_task / same-vehicle constraints
for t = 1:numTasks
    p = pickupNodes(t);
    d = dropoffNodes(t);
    for k = 1:numVehicles
        % PD_Order: uu(p) - uu(d) + M_sequence*sum(x(:,p,k)) <= M_sequence - 1
        cols = [ idx_uu(p,k), idx_uu(d,k), arrayfun(@(i) idx_x(i,p,k), 1:numNodes) ];
        vals = [1, -1, M_sequence * ones(1,numNodes)];
        [Irow,Jcol,Vval,RHS,SENSE] = append_row(Irow,Jcol,Vval,RHS,SENSE, cols, vals, M_sequence - 1, '<');
        
        % seq_task: uu(node,k) - bigMM*sum(x(:,node,k)) <= 0
        cols = [ idx_uu(p,k), arrayfun(@(i) idx_x(i,p,k), 1:numNodes) ];
        vals = [1, -bigMM * ones(1,numNodes)];
        [Irow,Jcol,Vval,RHS,SENSE] = append_row(Irow,Jcol,Vval,RHS,SENSE, cols, vals, 0, '<');
        
        cols = [ idx_uu(d,k), arrayfun(@(i) idx_x(i,d,k), 1:numNodes) ];
        vals = [1, -bigMM * ones(1,numNodes)];
        [Irow,Jcol,Vval,RHS,SENSE] = append_row(Irow,Jcol,Vval,RHS,SENSE, cols, vals, 0, '<');
        
        % Ensure same vehicle serves pickup and delivery: sum(x(:,d,k)) - sum(x(:,p,k)) == 0
        cols = [ arrayfun(@(i) idx_x(i,d,k), 1:numNodes), arrayfun(@(i) idx_x(i,p,k), 1:numNodes) ];
        vals = [ ones(1,numNodes), -ones(1,numNodes) ];
        [Irow,Jcol,Vval,RHS,SENSE] = append_row(Irow,Jcol,Vval,RHS,SENSE, cols, vals, 0, '=');
    end
end

% 8) No self-loops: x(i,i,k) == 0
for k = 1:numVehicles
    for i = 1:numNodes
        [Irow,Jcol,Vval,RHS,SENSE] = append_row(Irow,Jcol,Vval,RHS,SENSE, idx_x(i,i,k), 1, 0, '=');
    end
end

% Build model
if isempty(RHS)
    model.A = sparse([], [], [], 0, nvars);
    model.rhs = zeros(0,1);
    model.sense = '';
else
    model.A = sparse(Irow, Jcol, Vval, numel(RHS), nvars);
    model.rhs = RHS(:);
    model.sense = SENSE(:).';
end

model.obj = c;
model.modelsense = 'min';
model.lb = lb;
model.ub = ub;
model.vtype = vtype;

% Gurobi params
params = struct();
params.OutputFlag = 0;
if isfield(gurobiParams, 'OutputFlag'), params.OutputFlag = gurobiParams.OutputFlag; end
if isfield(gurobiParams, 'TimeLimit'), params.TimeLimit = gurobiParams.TimeLimit; end
if isfield(gurobiParams, 'MIPGap'), params.MIPGap = gurobiParams.MIPGap; end
fn = fieldnames(gurobiParams);
for kk = 1:numel(fn)
    params.(fn{kk}) = gurobiParams.(fn{kk});
end

% Solve
try
    result = gurobi(model, params);
catch ME
    sol = [];
    fval = [];
    exitflag = -1;
    result = struct('message', ME.message);
    warning('Gurobi call failed: %s', ME.message);
    return;
end

% Map status
switch upper(result.status)
    case 'OPTIMAL', exitflag = 1;
    case {'SUBOPTIMAL','TIME_LIMIT'}, exitflag = 0;
    case 'INFEASIBLE', exitflag = -2;
    otherwise, exitflag = -1;
end

% Extract solution
if isfield(result,'x') && ~isempty(result.x)
    xvec = result.x;
else
    xvec = zeros(nvars,1);
end

sol = struct();
sol.x = zeros(numNodes, numNodes, numVehicles);
sol.u = zeros(numNodes, numVehicles);
sol.uu = zeros(numNodes, numVehicles);

for k = 1:numVehicles
    for i = 1:numNodes
        for j = 1:numNodes
            sol.x(i,j,k) = xvec(idx_x(i,j,k));
        end
    end
    for i = 1:numNodes
        sol.u(i,k) = xvec(idx_u(i,k));
        sol.uu(i,k) = xvec(idx_uu(i,k));
    end
end

sol.x = round(sol.x);
sol.u = round(sol.u);
sol.uu = round(sol.uu);

if isfield(result,'objval'), fval = result.objval; else fval = c' * xvec; end

end

% -------------------------------------------------------------------------
% Helper subfunction (not nested) to append a row to the constraint triples.
function [Irow,Jcol,Vval,RHS,SENSE] = append_row(Irow,Jcol,Vval,RHS,SENSE, cols, values, rhs_val, s)
    % Allow single scalar cols/values
    if isscalar(cols)
        cols = cols(:);
        values = values(:);
    end
    r = numel(RHS) + 1;
    if ~isempty(cols)
        Irow = [Irow; repmat(r, numel(cols), 1)];
        Jcol = [Jcol; cols(:)];
        Vval = [Vval; values(:)];
    end
    RHS(r,1) = rhs_val;
    SENSE(r,1) = s;
end