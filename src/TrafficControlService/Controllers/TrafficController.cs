using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using TrafficControlService.Events;
using TrafficControlService.DomainServices;
using TrafficControlService.Models;
using System.Net.Http;
using System.Net.Http.Json;
using TrafficControlService.Repositories;
using Dapr.Client;
using System;

namespace TrafficControlService.Controllers
{
    [ApiController]
    [Route("")]
    public class TrafficController : ControllerBase
    {
        private readonly HttpClient _httpClient;
        private readonly IVehicleStateRepository _vehicleStateRepository;
        private readonly ILogger _logger;
        private readonly ISpeedingViolationCalculator _speedingViolationCalculator;
        private readonly string _roadId;

        public TrafficController(
            ILogger<TrafficController> logger,
            HttpClient httpClient,
            IVehicleStateRepository vehicleStateRepository,
            ISpeedingViolationCalculator speedingViolationCalculator)
        {
            _logger = logger;
            _httpClient = httpClient;
            _vehicleStateRepository = vehicleStateRepository;
            _speedingViolationCalculator = speedingViolationCalculator;
            _roadId = speedingViolationCalculator.GetRoadId();
        }

        [HttpPost("entrycam")]
        public async Task<ActionResult> VehicleEntry(VehicleRegistered msg)
        {
            try
            {
                // log entry
                _logger.LogInformation($"ENTRY detected in lane {msg.Lane} at {msg.Timestamp.ToString("hh:mm:ss")} of vehicle with license-number {msg.LicenseNumber}.");

                // store vehicle state
                var vehicleState = new VehicleState
                {
                    LicenseNumber = msg.LicenseNumber,
                    EntryTimestamp = msg.Timestamp
                };
                await _vehicleStateRepository.SaveVehicleStateAsync(vehicleState);

                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred while processing ENTRY");
                return StatusCode(500);
            }
        }

        [HttpPost("exitcam")]
        public async Task<ActionResult> VehicleExit(VehicleRegistered msg, [FromServices] DaprClient daprClient)
        {
            try
            {
                // log exit
                _logger.LogInformation($"EXIT detected in lane {msg.Lane} at {msg.Timestamp.ToString("hh:mm:ss")} of vehicle with license-number: {msg.LicenseNumber}.");

                if (daprClient == null)
                    throw new ArgumentOutOfRangeException("daprClient", "DaprClient is null.");

                // get vehicle state
                var vehicleState = await _vehicleStateRepository.GetVehicleStateAsync(msg.LicenseNumber);
                if (vehicleState == null)
                {
                    _logger.LogInformation($"EXIT NOT_FOUND - vehicle with license-number; {msg.LicenseNumber}.");
                    return Ok();
                }

                // update state
                vehicleState.ExitTimestamp = msg.Timestamp;
                await _vehicleStateRepository.SaveVehicleStateAsync(vehicleState);

                // handle possible speeding violation
                int violation = _speedingViolationCalculator.DetermineSpeedingViolationInKmh(vehicleState.EntryTimestamp, vehicleState.ExitTimestamp);
                if (violation > 0)
                {
                    _logger.LogInformation($"Speeding violation detected ({violation} KMh) of vehicle with license-number {vehicleState.LicenseNumber}.");

                    var speedingViolation = new SpeedingViolation
                    {
                        VehicleId = msg.LicenseNumber,
                        RoadId = _roadId,
                        ViolationInKmh = violation,
                        Timestamp = msg.Timestamp
                    };

                    // publish speedingviolation
                    //var message = JsonContent.Create<SpeedingViolation>(speedingViolation);
                    //await _httpClient.PostAsync("http://localhost:6001/collectfine", message);
                    //await _httpClient.PostAsync("http://localhost:3600/v1.0/publish/pubsub/collectfine", message);
                    await daprClient.PublishEventAsync("pubsub", "collectfine", speedingViolation);
                }

                _logger.LogInformation($"Processed vehicle with license-number {vehicleState.LicenseNumber}.");
                return Ok();
            }
            catch(Exception ex)
            {
                _logger.LogError($"An error occured - {ex.Message} - {ex.StackTrace}", ex);
                return StatusCode(500);
            }
        }
    }
}
