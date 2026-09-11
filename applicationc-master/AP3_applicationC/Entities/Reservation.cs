using System;
using System.Collections.Generic;

namespace AP3_applicationC.Entities;

public partial class Reservation
{
    public uint Idreservation { get; set; }

    public uint Idutilisateur { get; set; }

    public uint Idprestation { get; set; }

    public DateOnly Datedebut { get; set; }

    public TimeOnly Heuredebut { get; set; }

    public sbyte Validationpresence { get; set; }

    public virtual Prestation IdprestationNavigation { get; set; } = null!;

    public virtual Utilisateur IdutilisateurNavigation { get; set; } = null!;
}
