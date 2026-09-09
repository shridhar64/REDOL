function [totalCost, costPerVehicle] = compute_guess_cost(costMatrix, x0)
% compute_guess_cost  Compute VRP objective from a numeric guess x0.
%
% Inputs:
%  - costMatrix: numNodes x numNodes numeric matrix (cost(i,j))
%  - x0:         numNodes x numNodes x numVehicles numeric array (0/1 expected)
%
% Outputs:
%  - totalCost:     scalar total cost = sum_{k,i,j} cost(i,j)*x0(i,j,k)
%  - costPerVehicle: 1 x numVehicles vector of per-vehicle costs
%
% Example:
%  [C, CpV] = compute_guess_cost(costMatrix, x0);

[numNodes1, numNodes2, numVehicles] = size(x0);
assert(numNodes1 == size(costMatrix,1) && numNodes2 == size(costMatrix,2), ...
    'Dimensions mismatch between x0 and costMatrix');

costPerVehicle = zeros(1, numVehicles);
for k = 1:numVehicles
    % Elementwise multiply costMatrix with x(:,:,k) and sum
    costPerVehicle(k) = sum(sum(costMatrix .* squeeze(x0(:,:,k))));
end
totalCost = sum(costPerVehicle);

end