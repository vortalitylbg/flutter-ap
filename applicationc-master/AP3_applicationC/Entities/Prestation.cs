using System;
using System.Collections.Generic;

namespace AP3_applicationC.Entities;

public partial class Prestation
{
    public uint Idprestation { get; set; }

    public string Libelleprestation { get; set; } = null!;

    public decimal? Montantprestation { get; set; }

    public virtual ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
}
