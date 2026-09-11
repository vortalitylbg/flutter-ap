using AP3_applicationC.Entities;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Text;

namespace AP3_applicationC.Modele
{
    public static class ModeleReservation
    {
        public static List<Reservation> listeReservations()
        {
            return ConnexionBD.MonModel.Reservations
                .Include(r => r.IdutilisateurNavigation)
                .Include(r => r.IdprestationNavigation)
                .ToList();
        }

        public static List<Reservation> listeReservationsPourDate(DateOnly date)
        {
            return listeReservations().Where(r => r.Datedebut == date).ToList();
        }

        /// <summary>
        /// Méthode qui permet d'ajouter une réservation à la base de données.
        /// Un déclencheur "trigger_avant_insertion_resa" est présent sur la table Reservation en BD pour vérifier que l'utilisateur n'a pas déjà une 
        /// réservation à la même date et heure.
        /// </summary>
        /// <param name="r"></param>
        /// <returns></returns>
        public static bool ajouterReservation(Reservation r)
        {
            try
            {
                ConnexionBD.MonModel.Reservations.Add(r);
                ConnexionBD.MonModel.SaveChanges();
                return true;
            }
            catch
            {
                ConnexionBD.MonModel.ChangeTracker.Clear();
                return false;
            }
        }
    }
}
