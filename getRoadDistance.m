function [distance_km ] = getRoadDistance(gps1, gps2)

    % OSRM requires coordinates in:
    % longitude,latitude order

 url = sprintf( ...
        ['http://router.project-osrm.org/route/v1/driving/' ...
         '%.15f,%.15f;%.15f,%.15f?overview=false'], ...
         gps1(2), gps1(1), ...
         gps2(2), gps2(1));

    fprintf("Requesting:\n%s\n", url);

    try
        options = weboptions("Timeout", 30);

        data = webread(url, options);

        if strcmpi(string(data.code), "Ok")

            distance_km = data.routes(1).distance / 1000;
             

            fprintf("Road distance : %.3f km\n", distance_km);
             
        else
            distance_km = NaN;
             
            warning("OSRM returned: %s", string(data.code));
        end

    catch ME

        distance_km = NaN;
         

        fprintf("Routing failed:\n%s\n", ME.message);

    end
end