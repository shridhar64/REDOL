 clc
clear all 
close all

 Spanish = 1;

 numVehicles = 3;


 gps.lat   = 65.61640568720362;
gps.lon  =  22.139036710109025;
baseStation.gps = gps ;
baseStation.address = "Betalparkering, Parking lot, 97754 Luleå" ;



csvURL = "https://docs.google.com/spreadsheets/d/1GKAgzNFCoAsGIZfuh4Hp2s4s1BzCAalriLJhb-_Q5bs/export?format=csv&gid=144840799"


try
    mqClient = mqttclient( ...
        "ssl://52d291dfe83e490885a8058b05b73161.s1.eu.hivemq.cloud", ...
        Port=8883, ...
        ClientID="Redol test", ...
        Username="ilitev", ...
        Password="ir@fKULJBjRGm8q",...
        CARootCertificate="C:\Certificates\isrgrootx1.pem"),
catch ME
    disp(ME.identifier)
    disp(ME.message)
    disp(getReport(ME,'extended'))
end

 Spanish = 1;


MQTT_comm