using System;
using System.Collections.Generic;

namespace AP3_applicationC.Entities;

public partial class Cache
{
    public string Key { get; set; } = null!;

    public string Value { get; set; } = null!;

    public long Expiration { get; set; }
}
