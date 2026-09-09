for k = 1:numVehicles
    route = Final_Routes{k};
    task_seq = {};
    % assignment.city = "Lulea" ;

    if isempty(route)
        node = 1;
        assignment.address = baseStation.address;
            assignment.city = "At Depot";
            assignment.task_id = "At Depot"; 
            assignment.timestamp = ...
                    char(datetime("now"));
            assignment.gps = baseStation.gps;

            message = jsonencode(assignment);
            topic = sprintf("assignement/vehicle%g/task",k );
            write(mqClient, ...
                topic, ...
                message);
     
    else
    
        for node = route(1)
            if node == 1
                assignment.address = baseStation.address;
                assignment.city = "Go to Depot";
                assignment.task_id = "Go to Depot"; 
                assignment.timestamp = ...
                        char(datetime("now"));
                assignment.gps = baseStation.gps;
    
                message = jsonencode(assignment);
                topic = sprintf("assignement/vehicle%g/task",k );
                write(mqClient, ...
                    topic, ...
                    message);
            elseif ismember(node, pickupNodes)
                task_id = find(pickupNodes == node);
                task_type = mqttData.tasks(task_id).type;
                if task_type == "empty"
                    address = baseStation.address;
                    gps = baseStation.gps
                    job = sprintf("Pick %g empty container", ...
                            mqttData.tasks(task_id).capacity); 
                end
                if task_type == "filled"
                    address = mqttData.tasks(task_id).address;
                    gps =  mqttData.tasks(task_id).gps;
                    job =  "Pick a filled container" ; 
                end
              
    
                assignment.address = address;
                assignment.city = job;
                assignment.task_id = sprintf("Drop Task no  %g  ", ...
                             task_id );
                assignment.timestamp = ...
                        char(datetime("now"));
    
                message = jsonencode(assignment);
                topic = sprintf("assignement/vehicle%g/task",k );
                write(mqClient, ...
                    topic, ...
                    message);
    
             elseif ismember(node, dropoffNodes)
                task_id = find(dropoffNodes == node);
                task_type = mqttData.tasks(task_id).type;
                if task_type == "empty"
                    address = mqttData.tasks(task_id).address;
                    gps =  mqttData.tasks(task_id).gps;
                     
                    job = sprintf("Drop %g empty container", ...
                            mqttData.tasks(task_id).capacity); 
                end
                if task_type == "filled"
                    address = baseStation.address;
                    gps = baseStation.gps
                    job =  "Drop filled container at Depot" ; 
                end
                 
                assignment.address = address;
                assignment.city = job;
                assignment.task_id = sprintf("Drop Task no  %g  ", ...
                             task_id );
                assignment.timestamp = ...
                        char(datetime("now"));
    
                message = jsonencode(assignment);
                topic = sprintf("assignement/vehicle%g/task",k );
                write(mqClient, ...
                    topic, ...
                    message);
    
                 
            elseif ismember(node, dropoffNodes)
                task_id = find(dropoffNodes == node);
                % task_seq{end+1} = sprintf('D%d', task_id);
            end
        end
    end
        if ~isempty(route)
            vehicles(k).currentPDTask  = route(1);
        else
            vehicles(k).currentPDTask  = [];
        end
    
    
        fprintf("Assignment of %d is updated\n", k);    
     
end
