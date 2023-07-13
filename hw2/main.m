broong = ryze()

takeoff(broong)

moveforward(broong, 'Distance', 1)

turn(broong, deg2rad(-160))
pause(1)

moveleft(broong, 'Distance', 0.3)
pause(1)

turn(broong, der2rad(70))

moveleft(broong, 'Distance', 0.4)
pause(1)

cameraObj = camera(broong)
preview(cameraObj);
snapshot(cameraObj)

turn(broong, der2rad(-40))
pause(1)

moveforward(broong, 'Distance', 0.5)

land(broong)
