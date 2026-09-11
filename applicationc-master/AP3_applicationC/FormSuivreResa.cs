using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using AP3_applicationC.Entities;
using AP3_applicationC.Modele;
using System.Linq;

namespace AP3_applicationC
{
    public partial class FormSuivreResa : Form
    {
        public FormSuivreResa()
        {
            InitializeComponent();
        }

        private void FormSuivreResa_Load(object sender, EventArgs e)
        {
            LoadCalendar();
        }

        private void LoadCalendar()
        {
            try
            {
                List<Reservation> all = ModeleReservation.listeReservations();

                // Bold dates that have reservations
                var dates = all.Select(r => r.Datedebut.ToDateTime(new TimeOnly(0, 0))).Distinct().Select(d => (DateTime?)d).Where(d => d.HasValue).Select(d => d.Value).ToArray();
                mcCalendar.RemoveAllBoldedDates();
                foreach (var dt in dates)
                    mcCalendar.AddBoldedDate(dt);
                mcCalendar.UpdateBoldedDates();

                // Load reservations for selected date (today by default)
                var sel = mcCalendar.SelectionStart;
                LoadReservationsForDate(DateOnly.FromDateTime(sel));
            }
            catch (Exception ex)
            {
                MessageBox.Show("Erreur lors du chargement du calendrier : " + ex.Message);
            }
        }

        private void mcCalendar_DateSelected(object sender, DateRangeEventArgs e)
        {
            var date = DateOnly.FromDateTime(e.Start);
            LoadReservationsForDate(date);
        }

        private void LoadReservationsForDate(DateOnly date)
        {
            List<Reservation> list = ModeleReservation.listeReservationsPourDate(date);
            dgvReservations.Rows.Clear();
            foreach (var r in list.OrderBy(r => r.Heuredebut))
            {
                var time = r.Heuredebut.ToString("HH:mm");
                var user = r.IdutilisateurNavigation != null ? $"{r.IdutilisateurNavigation.Nom} {r.IdutilisateurNavigation.Prenom}" : r.Idutilisateur.ToString();
                var prest = r.IdprestationNavigation != null ? r.IdprestationNavigation.Libelleprestation : r.Idprestation.ToString();
                var presence = r.Validationpresence == 1 ? "Oui" : "Non";
                var idx = dgvReservations.Rows.Add(time, user, prest, presence);
                // Stocker l'objet Reservation dans la ligne pour y accéder au double-clic
                dgvReservations.Rows[idx].Tag = r;
            }
            lblSelectedDate.Text = $"Réservations pour le {date.ToString("d")} : {list.Count}";
        }

        private void dgvReservations_CellDoubleClick(object sender, DataGridViewCellEventArgs e)
        {
            if (e.RowIndex < 0) return;
            var row = dgvReservations.Rows[e.RowIndex];
            if (row?.Tag is Reservation r)
            {
                using var dlg = new FormReservationDetail(r);
                dlg.ShowDialog(this);
            }
        }


    }
}
