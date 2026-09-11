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
    public partial class FormCreerUtil : Form
    {
        public FormCreerUtil()
        {
            InitializeComponent();
        }

        private void btnCancel_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        private void FormCreerUtil_Load(object sender, EventArgs e)
        {
            // Remplir la liste des rôles dans le ComboBox
            try
            {
                List<Role> roles = ModeleUtilisateur.listeRoles();
                cbRoles.DisplayMember = "libellerole";
                cbRoles.ValueMember = "idrole";
                cbRoles.DataSource = roles;
            }
            catch (Exception ex)
            {
                MessageBox.Show("Erreur lors du chargement des données : " + ex.Message);
            }
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            try
            {
                if (tbNom.Text == "" || tbPrenom.Text == "" || tbEmail.Text == "" || cbRoles.SelectedValue == null)
                {
                    MessageBox.Show("Veuillez saisir tous les champs.");
                }
                else
                {
                    if (!Controleur.ValidMail(tbEmail.Text))
                    {
                        MessageBox.Show("Erreur dans le format de l'adresse mail", "ERREUR", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                    else
                    {
                        if (Modele.ModeleUtilisateur.AjoutUtilisateur(tbNom.Text, tbPrenom.Text, tbEmail.Text, Convert.ToInt32(cbRoles.SelectedValue)))
                        {
                            MessageBox.Show("Utilisateur ajouté, un email lui a été envoyé pour valider son inscription.");
                            Controleur.CreationEmail(tbEmail.Text, tbNom.Text, tbPrenom.Text);
                            this.Close();
                        }
                        else
                        {
                            MessageBox.Show("Erreur dans l'ajout d'un utilisateur", "ERREUR", MessageBoxButtons.OK, MessageBoxIcon.Error);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Erreur : " + ex.Message);
            }
        }
    }
}
