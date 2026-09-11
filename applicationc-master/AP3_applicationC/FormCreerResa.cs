using System;
using System.Globalization;
using System.Windows.Forms;
using AP3_applicationC.Entities;
using AP3_applicationC.Modele;

namespace AP3_applicationC
{
    public partial class FormCreerResa : Form
    {

        public FormCreerResa()
        {
            InitializeComponent();
            // Pour remplir la comboBox des heures toutes les 30 minutes.
            PopulateHeureCombo();
        }

        private void PopulateHeureCombo()
        {
            if (cbHeure == null) return;
            int heureOuverture = (System.Windows.Forms.Application.OpenForms["FormMenu"] as FormMenu).heureOuverture;
            int heureFermeture = (System.Windows.Forms.Application.OpenForms["FormMenu"] as FormMenu).heureFermeture;
            cbHeure.Items.Clear();
            for (int h = heureOuverture; h < heureFermeture; h++)
            {
                cbHeure.Items.Add(string.Format(CultureInfo.InvariantCulture, "{0:00}:00", h));
                cbHeure.Items.Add(string.Format(CultureInfo.InvariantCulture, "{0:00}:30", h));
            }

            // Pour sélectionner la demi-heure la plus proche de l'heure actuelle
            DateTime now = DateTime.Now;
            int index = now.Hour * 2 + (now.Minute >= 30 ? 1 : 0);
            if (index < 0) index = 0;
            if (index >= cbHeure.Items.Count) index = cbHeure.Items.Count - 1;
            cbHeure.SelectedIndex = index;
        }

        // pour récupérer l'heure sélectionnée dans la comboBox et la convertir en TimeSpan
        public TimeSpan GetSelectedHeure()
        {
            if (cbHeure == null || cbHeure.SelectedItem == null)
                return TimeSpan.Zero;

            if (TimeSpan.TryParseExact(cbHeure.SelectedItem.ToString(), "hh\\:mm", CultureInfo.InvariantCulture, out TimeSpan ts))
                return ts;

            if (DateTime.TryParse(cbHeure.SelectedItem.ToString(), CultureInfo.CurrentCulture, DateTimeStyles.None, out DateTime dt))
                return dt.TimeOfDay;

            return TimeSpan.Zero;
        }

        public void SetSelectedHeure(TimeSpan ts)
        {
            if (cbHeure == null) return;
            string s = string.Format(CultureInfo.InvariantCulture, "{0:00}:{1:00}", (int)ts.TotalHours % 24, ts.Minutes >= 30 ? 30 : 0);
            int idx = cbHeure.Items.IndexOf(s);
            if (idx >= 0) cbHeure.SelectedIndex = idx;
        }

        private void FormCreerResa_Load(object sender, EventArgs e)
        {
            // Remplir les combobox
            try
            {
                List<Utilisateur> utilisateurs = ModeleUtilisateur.listeUtilisateurs();
                cbUtilisateur.DisplayMember = "Nom";
                cbUtilisateur.ValueMember = "Idutilisateur";
                cbUtilisateur.DataSource = utilisateurs;

                // Valeurs par défaut
                dtpDate.Value = DateTime.Today;
                
                chkValidation.Checked = false;
            }
            catch (Exception ex)
            {
                MessageBox.Show("Erreur lors du chargement des données : " + ex.Message);
            }
        }

        private void btnCancel_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            if (cbUtilisateur.SelectedValue == null )
            {
                MessageBox.Show("Veuillez sélectionner un utilisateur.");
                return;
            }

            try
            {
                Reservation resa = new Reservation
                {
                    Idutilisateur = Convert.ToUInt32(cbUtilisateur.SelectedValue),
                    Idprestation=99, // valeur par défaut
                    Datedebut = DateOnly.FromDateTime(dtpDate.Value.Date),
                    Heuredebut = TimeOnly.FromTimeSpan(GetSelectedHeure()),
                    Validationpresence = chkValidation.Checked ? (sbyte)1 : (sbyte)0
                };

                bool ok = ModeleReservation.ajouterReservation(resa);
                if (ok)
                {
                    MessageBox.Show("Réservation créée avec succès.");
                    this.Close();
                }
                else
                {
                    MessageBox.Show("Votre réservation n'a pas pu être ajoutée, l'utilisateur est déjà occupé sur ce créneau", "Erreur", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Erreur : " + ex.Message);
            }
        }
    }
}
