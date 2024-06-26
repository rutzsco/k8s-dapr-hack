﻿using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using Dapr;
using FineCollectionService.DomainServices;
using FineCollectionService.Helpers;
using FineCollectionService.Models;
using FineCollectionService.Proxies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace FineCollectionService.Controllers
{
    [ApiController]
    [Route("")]
    public class CollectionController : ControllerBase
    {
        private static string _fineCalculatorLicenseKey;
        private readonly ILogger<CollectionController> _logger;
        private readonly IFineCalculator _fineCalculator;
        private readonly VehicleRegistrationService _vehicleRegistrationService;
        private readonly NotificationService _notificationService;

        public CollectionController(ILogger<CollectionController> logger,
                                    IFineCalculator fineCalculator,
                                    VehicleRegistrationService vehicleRegistrationService,
                                    NotificationService notificationService)
        {
            _logger = logger;
            _fineCalculator = fineCalculator;
            _vehicleRegistrationService = vehicleRegistrationService;
            _notificationService = notificationService;

            // set finecalculator component license-key
            if (_fineCalculatorLicenseKey == null)
            {
                _fineCalculatorLicenseKey = "HX783-K2L7V-CRJ4A-5PN1G";
            }
        }

        [Topic("pubsub", "collectfine")]
        [HttpPost("collectfine")]
        public async Task<ActionResult> CollectFine(SpeedingViolation speedingViolation)
        {
            decimal fine = _fineCalculator.CalculateFine(_fineCalculatorLicenseKey, speedingViolation.ViolationInKmh);

            // get owner info
            var vehicleInfo = await _vehicleRegistrationService.GetVehicleInfo(speedingViolation.VehicleId);

            // log fine
            string fineString = fine == 0 ? "tbd by the prosecutor" : $"{fine} Euro";
            var fineMessage = $"Sent speeding ticket to {vehicleInfo.OwnerName}. " +
                $"Road: {speedingViolation.RoadId}, Licensenumber: {speedingViolation.VehicleId}, " +
                $"Vehicle: {vehicleInfo.Brand} {vehicleInfo.Model}, " +
                $"Violation: {speedingViolation.ViolationInKmh} Km/h, Fine: {fineString}, " +
                $"On: {speedingViolation.Timestamp.ToString("dd-MM-yyyy")} " +
                $"at {speedingViolation.Timestamp.ToString("hh:mm:ss")}.";

            _logger.LogInformation(fineMessage);



            await _notificationService.SendFineNotification(speedingViolation, fineMessage);

            return Ok();
        }

    }
}
