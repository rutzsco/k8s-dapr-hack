using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;

namespace TrafficControlService.Controllers
{
    [ApiController]
    public class StatusController : Controller
    {
        private readonly ILogger<StatusController> _logger;

        public StatusController(ILogger<StatusController> logger)
        {
            _logger = logger;
        }

        [HttpGet("status")]
        public IActionResult Get()
        {
            Console.WriteLine("Hello World!");
            _logger.LogInformation("Processing reqest - status");
            return new OkObjectResult("OK");
        }
    }
}
