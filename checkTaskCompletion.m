function [tasks, arrivalStart, arrivalTask, currentPDTask, ...
          Final_Route, update] = checkTaskCompletion( ...
          vehicleID, vehicleGPS, taskID, locations, tasks, ...
          arrivalStart, arrivalTask, Final_Route, numTasks)

    arrivalRadius = 100;       % meters
    requiredTime = 20;         % seconds
    sameLocationRadius = 10;   % meters

    currentPDTask = taskID;
    update(1) = 0;

    %% No current task
    if isempty(taskID) || taskID <= 0

        arrivalStart(vehicleID) = NaT;
        arrivalTask(vehicleID) = 0;

        currentPDTask = [];
        return;
    end


    %% Distance to current PD task
    distance = gpsDistanceMeters( ...
        vehicleGPS.lat, vehicleGPS.lon, ...
        locations(taskID,1), locations(taskID,2));

    nowTime = datetime("now");


    %% Vehicle is at task location
    if distance <= arrivalRadius

        %% Start timer
        if arrivalTask(vehicleID) ~= taskID

            arrivalTask(vehicleID) = taskID;
            arrivalStart(vehicleID) = nowTime;

            fprintf( ...
                'Vehicle %d arrived at PD Task %d. Timer started.\n', ...
                vehicleID, taskID);

            return;
        end


        %% Check elapsed time
        elapsedTime = seconds( ...
            nowTime - arrivalStart(vehicleID));

        fprintf( ...
            'Vehicle %d at PD Task %d for %.1f sec\n', ...
            vehicleID, taskID, elapsedTime);


        %% Complete after required time
        if elapsedTime >= requiredTime

            %% =============================================
            % Check if next route node is at same location
            %% =============================================

            numberCompleted = 1;

            if length(Final_Route) >= 2

                nextPDTask = Final_Route(2);

                sameLocationDistance = gpsDistanceMeters( ...
                    locations(taskID,1), ...
                    locations(taskID,2), ...
                    locations(nextPDTask,1), ...
                    locations(nextPDTask,2));

                if sameLocationDistance <= sameLocationRadius

                    numberCompleted = 2;

                    fprintf( ...
                        'PD Tasks %d and %d completed at same location.\n', ...
                        taskID, nextPDTask);
                end
            end


            %% =============================================
            % Complete first PD task
            %% =============================================

             [tasks update] = completePDTask( ...
                taskID, tasks, numTasks,update);


            %% =============================================
            % Complete second PD task
            %% =============================================

            if numberCompleted == 2

                nextPDTask = Final_Route(2);

                [tasks update] = completePDTask( ...
                    nextPDTask, tasks, numTasks,update);

            end


            %% =============================================
            % Remove completed tasks from route
            %% =============================================

            if numberCompleted == 2

                Final_Route(1:2) = [];

            else

                Final_Route(1) = [];

            end


            %% =============================================
            % CURRENT PD TASK = first remaining route node
            %% =============================================

            if ~isempty(Final_Route)

                currentPDTask = Final_Route(1);

            else

                currentPDTask = [];

            end


            %% Assignment needs updating
            update(1) = 1;


            %% Reset timer
            arrivalStart(vehicleID) = NaT;
            arrivalTask(vehicleID) = 0;

        end


    else

        %% Vehicle left location before completion

        if arrivalTask(vehicleID) == taskID

            fprintf( ...
                'Vehicle %d left PD Task %d. Timer reset.\n', ...
                vehicleID, taskID);

        end

        arrivalStart(vehicleID) = NaT;
        arrivalTask(vehicleID) = 0;

    end

end

function [tasks update]= completePDTask(PDTaskID, tasks, numTasks,update)

    %% Depot node
    if PDTaskID == 1
        return;
    end

    %% Convert PD node to actual task ID
    actualTaskID = mod(PDTaskID - 2, numTasks) + 1;


    %% Update task status
    if tasks(actualTaskID).pickup_completed == 1

        % Pickup already done -> complete drop
        tasks(actualTaskID).task_completed = 1;
        update(1)  = 1 ;

    else

        % Complete pickup
        tasks(actualTaskID).pickup_completed = 1;
        update(1)  = 1 
    end
    update = [update actualTaskID];

end