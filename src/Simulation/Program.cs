int lanes = 1;
CameraSimulation[] cameras = new CameraSimulation[lanes];
for (var i = 0; i < lanes; i++)
{
    int camNumber = i + 1;
    var trafficControlService = await IotHubTrafficControlService.CreateAsync(camNumber);
    cameras[i] = new CameraSimulation(camNumber, trafficControlService);
}
Parallel.ForEach(cameras, cam => cam.Start());

Task.Run(() => Thread.Sleep(Timeout.Infinite)).Wait();