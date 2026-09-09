model.obj = 1;
model.A = 1;
model.rhs = 1;
model.sense = '>';       % CHAR
model.vtype = 'I';       % CHAR
model.modelsense = 'min';% CHAR

params.OutputFlag = 1;
result = gurobi(model, params);

disp(result.x)
disp(result.objval)