using Microsoft.AspNetCore.Mvc;
using System;

namespace TrafficControlService.Controllers
{
    [ApiController]
    public class StatusController : Controller
    {
        [HttpGet("status")]
        public IActionResult Get()
        {
            return new OkObjectResult("OK");
        }
    }
}
