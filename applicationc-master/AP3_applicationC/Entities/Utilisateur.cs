using System;
using System.Collections.Generic;

namespace AP3_applicationC.Entities;

public partial class Utilisateur
{
    public uint Idutilisateur { get; set; }

    public uint? Idrole { get; set; }

    public string Nom { get; set; } = null!;

    public string Prenom { get; set; } = null!;

    public string? Email { get; set; }

    public string? Motpasse { get; set; }

    public string? TwoFactorCode { get; set; }

    public DateTime? TwoFactorExpiresAt { get; set; }

    public string? ResetToken { get; set; }

    public DateTime? ResetTokenExpiresAt { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual Role? IdroleNavigation { get; set; }

    public virtual ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
}
