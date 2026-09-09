%MQTT_comm
 
Update_map = 1;



 % subscribe(mqClient,"gps/vehicle1/location");
 % subscribe(mqClient,"gps");
subscribe(mqClient, "gps/+/location");

disp("Subscribed to topic: gps/+/location");

%% 3. Subscribe to controller messages
subscribe(mqClient, "controller/+");
disp("Subscribed to topic: controller/+");



subscribe(mqClient, "task/+");
disp("Subscribed to topic: task/+");
%% Publish a message
 

% write(mqClient,"assigment/+/task",message); %%% {'address','city','timestamp'}

disp("Message published.");

%% Read incoming messages

disp("Waiting for messages...");



% gps.lat   = 65.61640568720362;
% gps.lon  =  22.139036710109025;
gps.spd = 0;
gps.alt   = 0;
gps.sats = 0;
gps.hdop = 0;
gps.ts = 0;
message = jsonencode(gps);

write(mqClient,"gps/vehicle1/location",message);,
write(mqClient,"gps/vehicle2/location",message);
write(mqClient,"gps/vehicle3/location",message);
 

 




%%%%%%%%%%%%%% load the tasks
% Lulea_tasks
%%%%%%%%%%

%%%%%%% load tasks from google form 
Tasks_google_form
 
  
for id = 1:numTasks
    message = jsonencode(tasks(id));
    topic = "task/" + id;
    write(mqClient, topic, message);
end

task = [];
 locations =[];
for vehicleID = 1:numVehicles
    arrivalStart(vehicleID) = NaT;
    arrivalTask(vehicleID)  = 0;
    Final_Routes{vehicleID} = [];
end


% assignmentTimer = timer( ...
%     'ExecutionMode', 'fixedRate', ...
%     'Period', 20, ...
%     'TimerFcn', @(~,~) Communicate_assignment());
% 
% start(assignmentTimer);
lastAssignmentUpdate = tic;


 while true

    % Read available MQTT messages
    data = read(mqClient);

    if ~isempty(data)

        for k = 1:height(data)

            topic = string(data.Topic(k));
            payload = string(data.Data(k));

            fprintf("\nReceived Topic: %s\n", topic);
            fprintf("Message: %s\n", payload);

            % Decode JSON
            try
                msg = jsondecode(payload);
            catch
                msg = payload;
            end

            %% Store according to topic

            topicParts = split(topic, "/");


           

           if topicParts(1) == "gps"
               % Assume invalid until proven valid
                validGPS = false;
                
                try
                    % Try decoding JSON
                    msg = jsondecode(payload);
                
                    % Check expected JSON structure
                    if isstruct(msg) && ...
                       isfield(msg, 'lat') && ...
                       isfield(msg, 'lon') && ...
                       isfield(msg, 'spd') && ...
                       isfield(msg, 'alt') && ...
                       isfield(msg, 'sats') && ...
                       isfield(msg, 'hdop') && ...
                       isfield(msg, 'ts')
                
                        % Check GPS values
                        if isnumeric(msg.lat) && ...
                           isnumeric(msg.lon) && ...
                           isscalar(msg.lat) && ...
                           isscalar(msg.lon) && ...
                           isfinite(msg.lat) && ...
                           isfinite(msg.lon) && ...
                           msg.lat >= -90 && msg.lat <= 90 && ...
                           msg.lon >= -180 && msg.lon <= 180
                
                            validGPS = true;
                
                        end
                    end
                
                catch
                    % jsondecode failed -> corrupted JSON
                    validGPS = false;
                end
                 
                

                    vehicle = topicParts(2);
    
                    % Convert topic name into valid MATLAB field
                    vehicle = matlab.lang.makeValidName(vehicle);
                    vehicleID = str2double(regexp(vehicle, '\d+', 'match', 'once'));
                if validGPS
                    % aaa = jsondecode(payload) 
    
    
                   vehicles(vehicleID).gps =  jsondecode(payload);
    
                   %if isfield(msg, 'gps') && ~isempty(msg.gps)
    
                         % GPS is available
                        
    
    
    
                    mqttData.gps.(vehicle) = msg;
                    currentTask0 =  vehicles(vehicleID).currentPDTask ;
    
                    if Update_map == 1
                        visulalize_vehicle
                    end
    
                     [tasks, arrivalStart, arrivalTask,vehicles(vehicleID).currentPDTask, Final_Routes{vehicleID}, update] = ...
                            checkTaskCompletion( ...
                                vehicleID , ...
                                vehicles(vehicleID).gps, ...
                                vehicles(vehicleID).currentPDTask, ...
                                locations,...
                                tasks, ...
                                arrivalStart, ...
                                arrivalTask,Final_Routes{vehicleID} ,numTasks  );
     
                     if update(1) == 1
                        Communicate_assignment; 
                        ids = update(2:end);
                        for ii = 1:length(ids)
                            id = ids(ii);
                            if id > 0
                                message = jsonencode(tasks(id));
                                topic = "task/" + id;
                                write(mqClient, topic, message);
                            end
                        end
                     end
                %end
                else
                
                    % DO NOTHING
                    % Previous mqttData.gps value remains unchanged
                
                    fprintf("Invalid GPS from Vehicle %d - ignored.\n", ...
                        vehicleID);                
                end



            % ---------------------------------
            % TASK
            % task/1
            % ---------------------------------
            elseif topicParts(1) == "task"

                taskID = str2double(topicParts(2));

                mqttData.tasks(taskID) = msg;


            % ---------------------------------
            % CONTROLLER
            % controller/action
            % ---------------------------------    

            elseif startsWith(topic, "controller/")

                try
                    controller = jsondecode(payload);

                    if isfield(controller, "action")

                          fprintf("Controller action = %d\n",controller.action);

                        %% If action == 1
                        if controller.action == '1'

                            disp("Running Algorithm");
                            numTasks = numel(mqttData.tasks);
                            depot = 1;                              % Depot node index
                            pickupNodes = 2:numTasks+1;             % Pickup nodes  
                            dropoffNodes = numTasks+2:2*numTasks+1; % Dropoff nodes  
                            numNodes = 2*numTasks + 1;              % Total nodes

                             
                            [Final_Routes locations] = Call_CDWCP_mqtt(mqttData,baseStation) ;
                            % sol_for_mqtt
                            disp("Asignment");

                            disp(Final_Routes);
                            
                            Communicate_assignment;
                            

                        end
                    end

                catch ME
                    warning("Controller message error: %s", ...
                        ME.message);
                end
            end
        end
    end

    % Avoid continuously loading the CPU
     % pause(0.1);
    %% Run every 20 seconds
    if toc(lastAssignmentUpdate) >= 20

        fprintf("Updating assignments...\n");

        Communicate_assignment();

        % Restart counter
        lastAssignmentUpdate = tic;

    end

    % Process MATLAB events
    drawnow  ;

end
  