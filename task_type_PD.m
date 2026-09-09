

    if task.type == "empty"  %% base to site
        task.pickup = baseStation.gps ;
        task.delivery =  task.gps;
    end
    
    if task.type == "filled"   %%%% site to  base
        task.pickup =  task.gps; 
        task.delivery =  baseStation.gps ;
    end
    task.pickup_completed = 0
    task.task_completed = 0