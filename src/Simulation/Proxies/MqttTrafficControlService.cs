
using System.Globalization;
using System.Net;
using System.Security.Cryptography;

namespace Simulation.Proxies;

public class MqttTrafficControlService : ITrafficControlService
{
    private IMqttClient _client;

    private MqttTrafficControlService(IMqttClient mqttClient)
    {
        _client = mqttClient;
    }

    public static async Task<MqttTrafficControlService> CreateAsync(int camNumber)
    {
        var token = generateSasToken("rutzsco-dapr-demo-ci.azure-devices.net/devices/DEVICE001", "6auVl3V+munzWZQBLJDKdnU1+N02rwmY57cjDGmR9dA=", "device");
        var mqttHost = Environment.GetEnvironmentVariable("MQTT_HOST") ?? "rutzsco-dapr-demo-ci.azure-devices.net";
        var factory = new MqttFactory();
        var client = factory.CreateMqttClient();
        var mqttOptions = new MqttClientOptionsBuilder()
            .WithTcpServer(mqttHost, 8883)
            .WithTls()
            .WithClientId($"DEVICE001")
            .WithCredentials("rutzsco-dapr-demo-ci.azure-devices.net/DEVICE001/?api-version=2021-04-12", token)
            .Build();
        await client.ConnectAsync(mqttOptions, CancellationToken.None);
        return new MqttTrafficControlService(client);
    }

    private async Task ReConnect()
    {
        var token = generateSasToken("rutzsco-dapr-demo-ci.azure-devices.net/devices/DEVICE001", "6auVl3V+munzWZQBLJDKdnU1+N02rwmY57cjDGmR9dA=", "device");
        var mqttHost = Environment.GetEnvironmentVariable("MQTT_HOST") ?? "rutzsco-dapr-demo-ci.azure-devices.net";
        var mqttOptions = new MqttClientOptionsBuilder()
            .WithTcpServer(mqttHost, 8883)
            .WithTls()
            .WithClientId($"DEVICE001")
            .WithCredentials("rutzsco-dapr-demo-ci.azure-devices.net/DEVICE001/?api-version=2021-04-12", token)
            .Build();

        await _client.ConnectAsync(mqttOptions, CancellationToken.None);
    }

    public async Task SendVehicleEntryAsync(VehicleRegistered vehicleRegistered)
    {
        var eventJson = JsonSerializer.Serialize(vehicleRegistered);
        var message = new MqttApplicationMessageBuilder()
            .WithTopic("trafficcontrol/entrycam")
            .WithPayload(Encoding.UTF8.GetBytes(eventJson))
            .Build();

        try
        {
            if (!_client.IsConnected)
                await ReConnect();

            var result = await _client.PublishAsync(message, CancellationToken.None);
        }
        catch (Exception ex)
        {
            ex.ToString();
        }
    }

    public async Task SendVehicleExitAsync(VehicleRegistered vehicleRegistered)
    {
        var eventJson = JsonSerializer.Serialize(vehicleRegistered);
        var message = new MqttApplicationMessageBuilder()
            .WithTopic("trafficcontrol/exitcam")
            .WithPayload(Encoding.UTF8.GetBytes(eventJson))
            .Build();

        try
        {
            if (!_client.IsConnected)
                await ReConnect();

            var result = await _client.PublishAsync(message, CancellationToken.None);
        }
        catch (Exception ex)
        {
            ex.ToString();
        }
    }

    private static string generateSasToken(string resourceUri, string key, string policyName, int expiryInSeconds = 216000)
    {
        TimeSpan fromEpochStart = DateTime.UtcNow - new DateTime(1970, 1, 1);
        string expiry = Convert.ToString((int)fromEpochStart.TotalSeconds + expiryInSeconds);

        string stringToSign = WebUtility.UrlEncode(resourceUri) + "\n" + expiry;

        HMACSHA256 hmac = new HMACSHA256(Convert.FromBase64String(key));
        string signature = Convert.ToBase64String(hmac.ComputeHash(Encoding.UTF8.GetBytes(stringToSign)));

        string token = String.Format(CultureInfo.InvariantCulture, "SharedAccessSignature sr={0}&sig={1}&se={2}", WebUtility.UrlEncode(resourceUri), WebUtility.UrlEncode(signature), expiry);

        if (!String.IsNullOrEmpty(policyName))
        {
            token += "&skn=" + policyName;
        }

        return token;
    }
}
