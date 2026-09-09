for k = 1:numVehicles

    route = Final_Routes{k};

    %% =====================================================
    % EMPTY ROUTE
    %% =====================================================
    if isempty(route)

        assignment.address   = baseStation.address;
        assignment.city      = "At Depot";
        assignment.task_id   = "At Depot";
        assignment.timestamp = char(datetime("now"));
        assignment.gps       = baseStation.gps;

    %% =====================================================
    % ROUTE EXISTS
    %% =====================================================
    else

        %% Current node
        node = route(1);

        [instruction1, address1, gps1, taskText1] = ...
            createInstruction( ...
                node, ...
                pickupNodes, ...
                dropoffNodes, ...
                mqttData.tasks, ...
                baseStation,Spanish);

        % Default: only current instruction
        instruction = instruction1;
        taskText = taskText1;


        %% =================================================
        % CHECK NEXT NODE
        %% =================================================
        if length(route) >= 2

            nextNode = route(2);

            [instruction2, address2, gps2, taskText2] = ...
                createInstruction( ...
                    nextNode, ...
                    pickupNodes, ...
                    dropoffNodes, ...
                    mqttData.tasks, ...
                    baseStation,Spanish);

            %% Check whether locations are the same
            distance = gpsDistanceMeters( ...
                gps1.lat, gps1.lon, ...
                gps2.lat, gps2.lon);

            if distance <= 10

    %% Identify operation type
    isPickup1 = ismember(node, pickupNodes);
    isPickup2 = ismember(nextNode, pickupNodes);

    isDrop1 = ismember(node, dropoffNodes);
    isDrop2 = ismember(nextNode, dropoffNodes);


    %% =====================================================
    % CASE 1: PICKUP + PICKUP
    %% =====================================================

    if isPickup1 && isPickup2

        taskID1 = find(pickupNodes == node, 1);
        taskID2 = find(pickupNodes == nextNode, 1);

        type1 = string(mqttData.tasks(taskID1).type);
        type2 = string(mqttData.tasks(taskID2).type);


        % Both empty
        if type1 == "empty" && type2 == "empty"

            totalContainers = ...
                mqttData.tasks(taskID1).capacity + ...
                mqttData.tasks(taskID2).capacity;


            instruction = sprintf( ...
                "Pick %g empty containers", ...
                totalContainers);
            if Spanish == 1
                 instruction = sprintf( ...
                "Recoger %g contenedor vacío", ...
                totalContainers);
            end


        % Both filled
        elseif type1 == "filled" && type2 == "filled"

            instruction = "Pick 2 filled containers";
            if Spanish == 1
                instruction = sprintf( ...
                 "Recoger %g contenedor vacío", ...
                totalContainers);
            end


        % Different container types
        else

            instruction = sprintf( ...
                "%s\n%s", ...
                instruction1, instruction2);

        end


    %% =====================================================
    % CASE 2: DROP + DROP
    %% =====================================================

    elseif isDrop1 && isDrop2

        taskID1 = find(dropoffNodes == node, 1);
        taskID2 = find(dropoffNodes == nextNode, 1);

        type1 = string(mqttData.tasks(taskID1).type);
        type2 = string(mqttData.tasks(taskID2).type);


        % Both empty
        if type1 == "empty" && type2 == "empty"

            totalContainers = ...
                mqttData.tasks(taskID1).capacity + ...
                mqttData.tasks(taskID2).capacity;

            instruction = sprintf( ...
                "Drop %g empty containers", ...
                totalContainers);
            if Spanish == 1
                 instruction = sprintf( ...
                "Dejar %g contenedor vacío", ...
                totalContainers);
            end


        % Both filled
        elseif type1 == "filled" && type2 == "filled"

            instruction = "Drop 2 filled containers";
             if Spanish == 1
                 instruction = sprintf( ...
                "Dejar %g contenedor lleno", ...
                totalContainers);
            end


        % Different container types
        else

            instruction = sprintf( ...
                "%s\n%s", ...
                instruction1, instruction2);

        end


    %% =====================================================
    % CASE 3: PICKUP + DROP
    %
    % Always show DROP first
    %% =====================================================

    elseif isPickup1 && isDrop2

        instruction = sprintf( ...
            "%s\n%s", ...
            instruction2, ...     % DROP first
            instruction1);        % PICKUP second


    %% =====================================================
    % CASE 4: DROP + PICKUP
    %
    % Already in correct order
    %% =====================================================

    elseif isDrop1 && isPickup2

        instruction = sprintf( ...
            "%s\n%s", ...
            instruction1, ...     % DROP first
            instruction2);        % PICKUP second


    %% =====================================================
    % Other case, e.g. depot node
    %% =====================================================

    else

        instruction = sprintf( ...
            "%s\n%s", ...
            instruction1, instruction2);

    end


    %% Both task descriptions
    taskText = sprintf( ...
        "%s + %s", ...
        taskText1, taskText2);

end

        end


        %% =================================================
        % BUILD ASSIGNMENT
        %% =================================================

        assignment.address = address1;

        assignment.city = instruction;

        assignment.task_id = taskText;

        assignment.timestamp = ...
            char(datetime("now"));

        assignment.gps = gps1;

    end


    %% =====================================================
    % PUBLISH
    %% =====================================================

    message = jsonencode(assignment);

    topic = sprintf( ...
        "assignement/vehicle%d/task", k);

    write(mqClient, topic, message);


    %% Current route node
    if ~isempty(route)
        vehicles(k).currentPDTask = route(1);
    else
        vehicles(k).currentPDTask = [];
    end

    fprintf("Assignment of vehicle %d updated\n", k);


end   
 

function [instruction, address, gps, taskText] = ...
    createInstruction( ...
        node, pickupNodes, dropoffNodes, tasks, baseStation,Spanish)


    %% =====================================================
    % DEPOT NODE
    %% =====================================================

    if node == 1

        address = baseStation.address;
        gps = baseStation.gps;

        instruction = "Go to Depot";

        if Spanish == 1
            instruction = "Ir al depósito"
        end
        taskText = "Go to Depot";


    %% =====================================================
    % PICKUP NODE
    %% =====================================================

    elseif ismember(node, pickupNodes)

        taskID = find(pickupNodes == node, 1);

        taskType = string(tasks(taskID).type);

        if taskType == "empty"

            % Empty container is picked up from depot
            address = baseStation.address;
            gps = baseStation.gps;

            instruction = sprintf( ...
                "Pick %g empty container", ...
                tasks(taskID).capacity);
            if Spanish == 1
                 instruction = sprintf( ...
                "Recoger %g contenedor vacío", ...
                 tasks(taskID).capacity);
            end

        elseif taskType == "filled"

            % Filled container is picked up from site
            address = tasks(taskID).address;
            gps = tasks(taskID).gps;

            instruction = "Pick 1 filled container";
             if Spanish == 1
                 instruction =  "Recoger 1 contenedor lleno"
            end
            

        else

            instruction = "Unknown pickup";
            address = "";
            gps = [];

        end

        taskText = sprintf( ...
            "Pickup Task no %d", taskID);


    %% =====================================================
    % DROPOFF NODE
    %% =====================================================

    elseif ismember(node, dropoffNodes)

        taskID = find(dropoffNodes == node, 1);

        taskType = string(tasks(taskID).type);

        if taskType == "empty"

            % Empty container delivered to task site
            address = tasks(taskID).address;
            gps = tasks(taskID).gps;

            instruction = sprintf( ...
                "Drop %g empty container", ...
                tasks(taskID).capacity);
             if Spanish == 1
                 instruction = sprintf( ...
                "Dejar %g contenedor vacío", ...
                tasks(taskID).capacity);
            end

        elseif taskType == "filled"

            % Filled container returned to depot
            address = baseStation.address;
            gps = baseStation.gps;

            instruction = ...
                "Drop 1 filled container at Depot";
            if Spanish == 1
                 instruction =  "Dejar 1 contenedor llenos" 
                 
            end

        else

            instruction = "Unknown dropoff";
            address = "";
            gps = [];

        end

        taskText = sprintf( ...
            "Drop Task no %d", taskID);

    else

        error("Unknown route node: %d", node);

    end

end
 