using AP3_applicationC.Modele;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace AP3_applicationC
{
    public partial class FormListerUtil : Form
    {
        public FormListerUtil()
        {
            InitializeComponent();
        }


        public void FormListerUtil_Load(object sender, EventArgs e)
        {
            bsListeUtil.DataSource = ModeleUtilisateur.listeUtilisateurs().Select(static x => new
            {
                x.Idutilisateur,
                x.Nom,
                x.Prenom,
                x.Email,
                x.Idrole,
                x.IdroleNavigation.Libellerole
            });
            dgvListeUtil.DataSource = bsListeUtil;

            dgvListeUtil.Columns[0].HeaderText = "Identifiant";
            dgvListeUtil.Columns[1].HeaderText = "Nom";
            dgvListeUtil.Columns[2].HeaderText = "Prénom";
            dgvListeUtil.Columns[3].HeaderText = "Email";
            dgvListeUtil.Columns[4].HeaderText = "Id Role";
            dgvListeUtil.Columns[5].HeaderText = "Libellé Role";
        }

        private void btnFermer_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        private void modifierEmailToolStripMenuItem_Click(object sender, EventArgs e)
        {
            System.Type type = bsListeUtil.Current.GetType();
            uint idU = (uint)type.GetProperty("Idutilisateur").GetValue(bsListeUtil.Current, null);

            FormModifEmail formModifEmail = new FormModifEmail(idU);
            formModifEmail.Show();
       
        }
    }
}
