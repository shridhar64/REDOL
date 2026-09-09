function [tasks, formData] = fetchFormResponses(csvURL,baseStation)

%% Download latest responses
temporaryFile = string(tempname) + ".csv";
fileCleanup = onCleanup(@() delete(temporaryFile));

% Prevent cached CSV data
cacheValue = string(round(posixtime(datetime("now")) * 1000));

if contains(csvURL, "?")
    freshURL = csvURL + "&cacheBust=" + cacheValue;
else
    freshURL = csvURL + "?cacheBust=" + cacheValue;
end

downloadedFile = websave(temporaryFile, freshURL);

%% Verify that Google returned CSV
rawContent = fileread(downloadedFile);
firstPart = lower(rawContent(1:min(numel(rawContent), 500)));

if contains(firstPart, "<html") || contains(firstPart, "<!doctype")
    error("Google returned a webpage instead of CSV. Check sharing permissions.");
end

%% Exact Google Form column names
companyColumn = "Company name";
contactColumn = "Contact number";

locationColumn = ...
    "Site GPS location.";
dateColumn = "When";
timestampColumn = "Timestamp";

emptyColumn = ...
    "How many empty containers are needed";

filledColumn = ...
    "How many containers are filled and should be take away";

requiredColumns = [ ...
    timestampColumn, companyColumn, contactColumn, ...
    locationColumn, dateColumn, emptyColumn, filledColumn];

%% Import CSV
opts = detectImportOptions(downloadedFile, ...
    VariableNamingRule="preserve");

availableColumns = string(opts.VariableNames);
availableColumns2 = availableColumns;
str = availableColumns(4);
firstFew = extractBetween(str, 1, min(18, strlength(str)));
availableColumns2(4) = firstFew;
missingColumns = setdiff(requiredColumns, availableColumns2);

locationColumn = availableColumns(4) ;

if ~isempty(missingColumns)
    error("Missing form column(s): %s", ...
        strjoin(missingColumns, ", "));
end

opts = setvartype(opts, ...
    [companyColumn, contactColumn, locationColumn], ...
    "string");

formData = readtable(downloadedFile, opts);

%% Extract form values
companyNames = string(formData.(companyColumn));
contactNumbers = string(formData.(contactColumn));
locations = string(formData.(locationColumn));

requestDates = formData.(dateColumn);
formTimestamps = formData.(timestampColumn);

emptyRequired = str2double(string(formData.(emptyColumn)));
filledTakeaway = str2double(string(formData.(filledColumn)));

% Blank quantity means zero
emptyRequired(isnan(emptyRequired)) = 0;
filledTakeaway(isnan(filledTakeaway)) = 0;

%% Generate tasks
%tasks = struct();
id = 0;

 
for row = 1:height(formData)

    %% Split "latitude, longitude"
    coordinateParts = split(locations(row), ",");

    if numel(coordinateParts) ~= 2
        warning("Row %d skipped: incorrect location format.", row);
        continue;
    end

    lat = str2double(strtrim(coordinateParts(1)));
    lon = str2double(strtrim(coordinateParts(2)));

    if isnan(lat) || isnan(lon) || ...
            lat < -90 || lat > 90 || ...
            lon < -180 || lon > 180

        warning("Row %d skipped: invalid GPS coordinates.", row);
        continue;
    end

    %% Validate quantities
    quantities = [emptyRequired(row), filledTakeaway(row)];

    if any(quantities < 0) || any(mod(quantities, 1) ~= 0)
        warning("Row %d skipped: invalid container quantity.", row);
        continue;
    end

    %% Empty-container task
    if emptyRequired(row) > 0

        id = id + 1;

        task = makeTask( ...
            id, lat, lon, ...
            companyNames(row), ...
            contactNumbers(row), ...
            requestDates(row), ...
            formTimestamps(row), ...
            emptyRequired(row), ...
            "empty", row);

        % Your existing pickup/drop task script
        task_type_PD;

        tasks(id) = task;
    end

    %% Filled-container task
    if filledTakeaway(row) > 0

        id = id + 1;

        task = makeTask( ...
            id, lat, lon, ...
            companyNames(row), ...
            contactNumbers(row), ...
            requestDates(row), ...
            formTimestamps(row), ...
            filledTakeaway(row), ...
            "filled", row);

        task_type_PD;

        tasks(id) = task;
    end
end

fprintf("Downloaded %d form responses.\n", height(formData));
fprintf("Generated %d tasks.\n", numel(tasks));

end


function task = makeTask( ...
        id, lat, lon, companyName, contactNumber, ...
        requestDate, timestamp, capacity, taskType, formRow)

task = struct();

task.id = id;

task.gps = struct();
task.gps.lat = lat;
task.gps.lon = lon;

task.address = companyName;
%task.company_name = companyName;
task.status = 0;
task.capacity = capacity;
task.type = taskType;
task.contact_no = contactNumber;
%task.requested_date = requestDate;
%task.form_timestamp = timestamp;
%task.form_row = formRow;

end