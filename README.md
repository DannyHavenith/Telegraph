This mini engine order telegraph is intended to set a home automation system in a specific "mode". 
The device has 5 positions; the actual position will be sent through mqtt, 
where it can be picked up by home automation systems.

The positions on the dial are populated with 6x6 3.1mm-13mm SPST switches. The switches are monitored by a Wemos d1 mini, 
which updates an mqtt topic when the lever position changes.
