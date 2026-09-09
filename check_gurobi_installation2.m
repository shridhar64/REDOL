function info = check_gurobi_installation(verbose)
% check_gurobi_installation  Check whether the Gurobi MATLAB interface is installed and callable.
%
% Usage:
%   info = check_gurobi_installation()        % quiet (default prints summary)
%   info = check_gurobi_installation(true)    % verbose: prints detailed diagnostics
%
% Returns a struct `info` with fields:
%   gurobiOnPath   - true if a 'gurobi' function is found on the MATLAB path
%   gurobiWhich    - path to the gurobi wrapper (empty if not found)
%   gurobiMex      - true if 'gurobi_mex' MEX file is found
%   canCall        - true if a simple gurobi(model) call succeeded
%   licenseOK      - true if call succeeded; false if failure message mentions license;
%                    NaN if undetermined
%   status         - Gurobi status string if call succeeded
%   x, objval      - result fields if call succeeded
%   message        - error message or success message
%
% This performs:
%  1) path checks with exist/which
%  2) a small, safe gurobi(model) call using 0 constraints and 1 variable
%     (minimize x subject to 0<=x<=1). The call will reveal license problems
%     or other runtime issues.
%
% Note: This function only checks the MATLAB interface and runtime; a valid
%       Gurobi license is still required to solve models.

if nargin < 1, verbose = true; end

info = struct();
% Check for gurobi wrapper and MEX
info.gurobiOnPath = (exist('gurobi','file') > 0);
if info.gurobiOnPath
    try
        info.gurobiWhich = which('gurobi');
    catch
        info.gurobiWhich = '';
    end
else
    info.gurobiWhich = '';
end
info.gurobiMex = (exist('gurobi_mex','file') > 0);

% Prepare a tiny, valid model: 0 constraints, 1 variable (0 <= x <= 1)
model = struct();
model.obj = 1;                % minimize 1*x
model.A = sparse(0,1);       % 0 constraints, 1 variable
model.rhs = zeros(0,1);
model.sense = '';            % empty char row for zero constraints
model.lb = 0;
model.ub = 1;
model.vtype = 'C';
model.modelsense = 'min';

params = struct();
params.OutputFlag = 0;       % keep quiet by default

% Try calling Gurobi
info.canCall = false;
info.licenseOK = NaN;
info.status = '';
info.x = [];
info.objval = [];
info.message = '';

try
    result = gurobi(model, params);
    % If we reach here, Gurobi ran and returned a result (license OK).
    info.canCall = true;
    info.licenseOK = true;
    info.status = result.status;
    if isfield(result, 'x'), info.x = result.x; end
    if isfield(result, 'objval'), info.objval = result.objval; end
    info.message = 'Gurobi callable and returned a result.';
catch ME
    info.canCall = false;
    info.message = ME.message;
    % Try to detect license-related errors from the message text
    msgLower = lower(ME.message);
    if contains(msgLower, 'license') || contains(msgLower, 'licen')
        info.licenseOK = false;
    else
        info.licenseOK = NaN;
    end
end

% Print a short summary if requested
if verbose
    fprintf('Gurobi wrapper on MATLAB path : %s\n', logical_to_onoff(info.gurobiOnPath));
    if info.gurobiOnPath, fprintf('  which(gurobi): %s\n', info.gurobiWhich); end
    fprintf('gurobi_mex MEX present       : %s\n', logical_to_onoff(info.gurobiMex));
    fprintf('Can call gurobi(model)       : %s\n', logical_to_onoff(info.canCall));
    if info.canCall
        fprintf('  Gurobi status: %s\n', info.status);
        if ~isempty(info.x), fprintf('  sample x: [%s]\n', num2str(info.x(:)')); end
        if ~isempty(info.objval), fprintf('  objval: %g\n', info.objval); end
    else
        if isnan(info.licenseOK)
            fprintf('  Call failed. Message:\n    %s\n', info.message);
        elseif info.licenseOK == false
            fprintf('  Call failed due to license issue. Message:\n    %s\n', info.message);
        end
    end
end

end

function s = logical_to_onoff(val)
if isequal(val, true)
    s = 'YES';
elseif isequal(val, false)
    s = 'NO';
else
    s = 'UNKNOWN';
end
end