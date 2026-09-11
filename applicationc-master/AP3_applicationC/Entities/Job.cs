using System;
using System.Collections.Generic;

namespace AP3_applicationC.Entities;

public partial class Job
{
    public ulong Id { get; set; }

    public string Queue { get; set; } = null!;

    public string Payload { get; set; } = null!;

    public ushort Attempts { get; set; }

    public uint? ReservedAt { get; set; }

    public uint AvailableAt { get; set; }

    public uint CreatedAt { get; set; }
}
