using Microsoft.Azure.Devices.Client;
using System.Text;
using System.Text.Json;
using Simulation.Events;

namespace Simulation.Proxies
{
    public class IotHubTrafficControlService : ITrafficControlService
    {
        private readonly DeviceClient _client;

        public static async Task<IotHubTrafficControlService> CreateAsync(int camNumber)
        {
            return new IotHubTrafficControlService(camNumber);
        }

        public IotHubTrafficControlService(int camNumber)
        {
            _client = DeviceClient.CreateFromConnectionString("HostName=rutzsco-dapr-demo-ci.azure-devices.net;DeviceId=DEVICE001;SharedAccessKey=IH2uXrmpFVBF1opaxolUuTw74chhZmYTEzD8I4zhl5A=", TransportType.Mqtt);
        }

        public async Task SendVehicleEntryAsync(VehicleRegistered vehicleRegistered)
        {
            var eventJson = JsonSerializer.Serialize(vehicleRegistered);
            var message = new Message(Encoding.UTF8.GetBytes(eventJson));
            message.Properties.Add("trafficcontrol", "entrycam");
            await _client.SendEventAsync(message);
        }

        public async Task SendVehicleExitAsync(VehicleRegistered vehicleRegistered)
        {
            var eventJson = JsonSerializer.Serialize(vehicleRegistered);
            var message = new Message(Encoding.UTF8.GetBytes(eventJson));
            message.Properties.Add("trafficcontrol", "exitcam");
            await _client.SendEventAsync(message);
        }
    }
}