using Dapr.Client;
using FineCollectionService.Models;
using System.Threading.Tasks;

namespace FineCollectionService.DomainServices
{
    public class NotificationService
    {
        private DaprClient _daprClient;

        public NotificationService(DaprClient daprClient)
        {
            _daprClient = daprClient;
        }

        public async Task SendFineNotification(SpeedingViolation speedingViolation, string fineMessage)
        {
            var email = new
            {
                from = "noreply@cfca.gov",
                to = "<YOUR_EMAIL_ADDRESS_HERE>",
                subject = $"Speeding violation on the {speedingViolation.RoadId}",
                body = fineMessage
            };

            await _daprClient.InvokeBindingAsync("sendmail", "create", email);
        }
    }
}
