using System;
using System.Collections.Generic;

namespace AP3_applicationC.Entities;

public partial class Role
{
    public uint Idrole { get; set; }

    public string Libellerole { get; set; } = null!;

    public virtual ICollection<Utilisateur> Utilisateurs { get; set; } = new List<Utilisateur>();
}
