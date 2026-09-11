using System;
using System.Collections.Generic;
using System.Text;
using System.Net.Mail;
using System.Text.RegularExpressions;

namespace AP3_applicationC
{
    public static class Controleur
    {
        /// <summary>
        /// méthode qui retourne vrai ou faux selon la validité du format d'un email passé en paramètres
        /// </summary>
        /// <param name="mail"></param>
        /// <returns></returns>
        public static bool ValidMail(string mail)
        {

            string pattern = @"^([a-zA-Z0-9_\.]+)@([a-zA-Z0-9_\-]+)\.([\w]{2,4})$";
            Regex r1 = new Regex(pattern);
            return r1.IsMatch(mail);
        }


        /// <summary>
        /// permet l'envoi d'un mail sur le serveur smtp mis en place pour l'AP
        /// </summary>
        /// <param name="dest"></param>
        public static void CreationEmail(string dest, string nom, string prenom)
        {
            string to = dest;
            string from = "admin.chevrollier.contact@resachev.com";
            MailMessage message = new MailMessage(from, to);
            message.Subject = "RESA CHEV : AJOUT D'UN UTILISATEUR";
            message.Body = "Bonjour " + nom + " " + prenom + ",\n\nNous validons la création de votre compte en tant que nouvel utilisateur.\n\nPour vous connecter au service de réservation web, utiliser le mot de passe oublié la première fois pour le définir.\n\nBien Cordialement,\n\nL'équipe de RésaChev'";
            SmtpClient client = new SmtpClient();

            client.Host = "mail.dombtsig.local";
            client.Port = 1025;

            // Credentials are necessary if the server requires the client
            // to authenticate before it will send email on the client's behalf.
            client.UseDefaultCredentials = true;

            try
            {
                client.Send(message);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Exception caught in CreateEmail(): {0}", ex.ToString());
            }
        }
    }
}
