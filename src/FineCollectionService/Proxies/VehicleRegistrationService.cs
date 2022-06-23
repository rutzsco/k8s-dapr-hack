using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;
using Dapr.Client;
using FineCollectionService.Models;

namespace FineCollectionService.Proxies
{
    public class VehicleRegistrationService
    {
        private DaprClient _daprClient;

        public VehicleRegistrationService(DaprClient daprClient)
        {
            _daprClient = daprClient;
        }

        public async Task<VehicleInfo> GetVehicleInfo(string licenseNumber)
        {
            //var url = "http://localhost:6002/vehicleinfo/{licenseNumber";
            var url = $"http://localhost:3601/v1.0/invoke/vehicleregistrationservice/method/vehicleinfo/{licenseNumber}";
            //return await _httpClient.GetFromJsonAsync<VehicleInfo>(url);

            var request = _daprClient.CreateInvokeMethodRequest(HttpMethod.Get, $"vehicleregistrationservice", "vehicleinfo/{licenseNumber}");
            var result = await _daprClient.InvokeMethodAsync<VehicleInfo>(request);
            return result;
        }       
    }
}