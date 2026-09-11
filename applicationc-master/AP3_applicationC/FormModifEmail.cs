using AP3_applicationC.Entities;
using AP3_applicationC.Modele;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;

namespace AP3_applicationC
{
    public partial class FormModifEmail : Form
    {
        private uint idUtilisateur;
        public FormModifEmail(uint idU)
        {
            InitializeComponent();
            this.idUtilisateur = idU;
        }

        private void button1_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        private void FormModifEmail_Load(object sender, EventArgs e)
        {
            Utilisateur U = ModeleUtilisateur.RecupererUtilisateur(idUtilisateur);

            // mise à jour des infos dans les différents champs
            tbNom.Text = U.Nom;
            tbPrenom.Text = U.Prenom;
            tbEmail.Text = U.Email;
            tbEmail.Focus();
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            if (tbEmail.Text == "" || !Controleur.ValidMail(tbEmail.Text))
            {
                MessageBox.Show("Erreur dans le format de l'adresse mail", "ERREUR", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            else
            {
                if (ModeleUtilisateur.ModifierEmailUtilisateur(idUtilisateur, tbEmail.Text))
                {
                    (System.Windows.Forms.Application.OpenForms["FormListerUtil"] as FormListerUtil).FormListerUtil_Load(sender, e);
                    this.Close();
                }
                else
                {
                    MessageBox.Show("Erreur dans la mise à jour d'un email d'utilisateur", "ERREUR", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }
    }
}
