using AP3_applicationC.Entities;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace AP3_applicationC.Modele
{
    public class ConnexionBD
    {
          private static Ap3DemoContext monModel;

        public static Ap3DemoContext MonModel { get => monModel; set => monModel = value; }

        public static void init()
          {
              monModel = new Ap3DemoContext();
          }

        // récupération des informations de la table PARAMETRAGE
        public static List<Parametrage> listeParametres()
        {
            return ConnexionBD.MonModel.Parametrages.ToList();
        }
    }
}
