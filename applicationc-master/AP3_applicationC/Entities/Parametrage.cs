using System;
using System.Collections.Generic;

namespace AP3_applicationC.Entities;

public partial class Parametrage
{
    public uint Idparam { get; set; }

    public string Libelleparam { get; set; } = null!;

    public string Valeurparam { get; set; } = null!;

    public string? Uniteparam { get; set; }
}
