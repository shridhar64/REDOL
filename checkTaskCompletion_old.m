function [tasks, arrivalStart, arrivalTask, currentTask,Final_Route,update] = checkTaskCompletion_old( ...
    vehicleID, vehicleGPS, taskID,locations, tasks, arrivalStart, arrivalTask, Final_Route,numTasks)

    arrivalRadius = 100;    % meters
    requiredTime  = 20;    % seconds

    currentTask = taskID;
    Final_Route = Final_Route;
    update = 0;
    %% No task assigned
    if isempty(taskID) || taskID <= 0
        arrivalStart(vehicleID) = NaT;
        arrivalTask(vehicleID)  = 0;
        return;
    end

   

    distance = gpsDistanceMeters( ...
        vehicleGPS.lat, vehicleGPS.lon, ...
        locations(taskID,1) , locations(taskID,2));

    nowTime = datetime("now");

    %% Vehicle is inside task location radius
    if distance <= arrivalRadius

        % Check whether this is a new task
        if arrivalTask(vehicleID) ~= taskID

            arrivalTask(vehicleID) = taskID;
            arrivalStart(vehicleID) = nowTime;

            fprintf(['Vehicle %d arrived at PD Task %d. ' ...
                     'Timer started.\n'], ...
                     vehicleID, taskID);

            return;
        end

        % Timer has not started yet
        if isnat(arrivalStart(vehicleID))

            arrivalStart(vehicleID) = nowTime;

            fprintf('Vehicle %d timer started for PD Task %d.\n', ...
                vehicleID, taskID);

            return;
        end

        %% Check elapsed time -- NO WAITING HERE

        elapsedTime = seconds( ...
            nowTime - arrivalStart(vehicleID));

        fprintf('Vehicle %d at Task %d for %.1f sec\n', ...
            vehicleID, taskID, elapsedTime);

        %% Complete task after fixed time seconds
        if elapsedTime >= requiredTime
            if taskID == 1 
                actual_taskID = 0;
            else
                actual_taskID = mod((taskID -2),numTasks) + 1;
            end

            if actual_taskID == 0
                fprintf(' Vehicle %d\n  is at Depot', ...
                      vehicleID);
                if ~isempty(Final_Route)
                    Final_Route(1) = [];
                end

                if ~isempty(Final_Route)
                    currentPDTask = Final_Route(1);
                else
                    currentPDTask = [];
                end
                update(1)  = 1 ;
                update(2)  = 0 ;

            else
                if tasks(actual_taskID).pickup_completed == 1    
                    tasks(actual_taskID).task_completed = 1;
                    update(1)  = 1 ;
                else
                    tasks(actual_taskID).pickup_completed = 1
                    update(1)  = 1 ;
                end
                update(2) = actual_taskID;

                fprintf('PD Task %d COMPLETED by Vehicle %d\n', ...
                    taskID, vehicleID);
    
                if ~isempty(Final_Route)
                    Final_Route(1) = [];
                end
                
                % Get the next task
                if ~isempty(Final_Route)
                    currentPDTask = Final_Route(1);
                else
                    currentPDTask = [];
                end

            end
            % Reset timer
            arrivalStart(vehicleID) = NaT;
            arrivalTask(vehicleID)  = 0;

        end

    else

        %% Vehicle is outside task location

        % If timer was running, reset it
        if arrivalTask(vehicleID) == taskID

            fprintf(['Vehicle %d left Task %d before completion. ' ...
                     'Timer reset.\n'], ...
                     vehicleID, taskID);

        end

        arrivalStart(vehicleID) = NaT;
        arrivalTask(vehicleID)  = 0;

    end
end