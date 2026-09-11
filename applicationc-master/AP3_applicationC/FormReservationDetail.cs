using System;
using System.Windows.Forms;
using AP3_applicationC.Entities;

namespace AP3_applicationC
{
    public partial class FormReservationDetail : Form
    {
        private Reservation _reservation;
        public FormReservationDetail(Reservation reservation)
        {
            _reservation = reservation;
            InitializeComponent();
        }

        private void FormReservationDetail_Load(object sender, EventArgs e)
        {
            if (_reservation == null) return;

            lblId.Text = _reservation.Idreservation.ToString();
            lblUser.Text = _reservation.IdutilisateurNavigation != null ? $"{_reservation.IdutilisateurNavigation.Nom} {_reservation.IdutilisateurNavigation.Prenom}" : _reservation.Idutilisateur.ToString();
            lblPrestation.Text = _reservation.IdprestationNavigation != null ? _reservation.IdprestationNavigation.Libelleprestation : _reservation.Idprestation.ToString();
            lblDate.Text = _reservation.Datedebut.ToString();
            lblHeure.Text = _reservation.Heuredebut.ToString();
            lblPresence.Text = _reservation.Validationpresence == 1 ? "Oui" : "Non";
        }

        private void btnClose_Click(object sender, EventArgs e)
        {
            this.Close();
        }
    }
}
