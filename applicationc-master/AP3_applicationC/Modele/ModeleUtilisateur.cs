using AP3_applicationC.Entities;    
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Runtime.Intrinsics.Arm;
using System.Text;

namespace AP3_applicationC.Modele
{
    public static class ModeleUtilisateur
    {
        public static List<Utilisateur> listeUtilisateurs()
        {
            return ConnexionBD.MonModel.Utilisateurs.Include(x => x.IdroleNavigation).ToList();
        }

        public static List<Role> listeRoles()
        {
            return ConnexionBD.MonModel.Roles.ToList();
        }

        public static bool AjoutUtilisateur(string nom, string prenom, string email, int idRole)
        {
            Utilisateur unU;
            bool vretour = true;
            try
            {
                // ajout dans la table Moniteur
                unU = new Utilisateur();
                unU.Nom = nom;
                unU.Prenom = prenom;
                unU.Email = email;
                unU.Idrole = (uint)idRole;

                ConnexionBD.MonModel.Utilisateurs.Add(unU);
                ConnexionBD.MonModel.SaveChanges();

            }
            catch (Exception ex)
            {
                ConnexionBD.MonModel.ChangeTracker.Clear();
                vretour = false;
                MessageBox.Show(ex.Message.ToString());
            }
            return vretour;
        }

        public static Utilisateur RecupererUtilisateur(uint idU)
        {
            Utilisateur unU = new Utilisateur();
            try
            {
                unU = ConnexionBD.MonModel.Utilisateurs.First(x => x.Idutilisateur== idU);
            }
            catch (Exception ex)
            {
                ConnexionBD.MonModel.ChangeTracker.Clear();
                MessageBox.Show(ex.Message.ToString());
            }
            return unU;
        }

        public static bool ModifierEmailUtilisateur(uint idUtilisateur, string email)
        {
            Utilisateur unU;
            bool vretour = true;
            try
            {
                unU = RecupererUtilisateur(idUtilisateur);

                unU.Email = email;

                ConnexionBD.MonModel.SaveChanges();
            }
            catch (Exception ex)
            {
                ConnexionBD.MonModel.ChangeTracker.Clear();
                vretour = false;
                MessageBox.Show(ex.Message.ToString());
            }
            return vretour;
        }
    }
}
