using System;
using System.ComponentModel;
using System.Drawing;
using System.Windows.Forms;

namespace AP3_applicationC
{
    partial class FormReservationDetail
    {
        private IContainer components = null;
        private Label label1;
        private Label lblId;
        private Label label3;
        private Label lblUser;
        private Label label5;
        private Label lblPrestation;
        private Label label7;
        private Label lblDate;
        private Label label9;
        private Label lblHeure;
        private Label label11;
        private Label lblPresence;
        private Button btnClose;

        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        private void InitializeComponent()
        {
            components = new Container();
            label1 = new Label();
            lblId = new Label();
            label3 = new Label();
            lblUser = new Label();
            label5 = new Label();
            lblPrestation = new Label();
            label7 = new Label();
            lblDate = new Label();
            label9 = new Label();
            lblHeure = new Label();
            label11 = new Label();
            lblPresence = new Label();
            btnClose = new Button();

            SuspendLayout();
            // 
            // label1 - Id
            // 
            label1.AutoSize = true;
            label1.Location = new Point(24, 20);
            label1.Text = "ID :";
            // 
            // lblId
            // 
            lblId.AutoSize = true;
            lblId.Location = new Point(120, 20);
            lblId.Text = "-";
            // 
            // label3 - Utilisateur
            // 
            label3.AutoSize = true;
            label3.Location = new Point(24, 50);
            label3.Text = "Utilisateur :";
            // 
            // lblUser
            // 
            lblUser.AutoSize = true;
            lblUser.Location = new Point(120, 50);
            lblUser.Text = "-";
            // 
            // label5 - Prestation
            // 
            label5.AutoSize = true;
            label5.Location = new Point(24, 80);
            label5.Text = "Prestation :";
            // 
            // lblPrestation
            // 
            lblPrestation.AutoSize = true;
            lblPrestation.Location = new Point(120, 80);
            lblPrestation.Text = "-";
            // 
            // label7 - Date
            // 
            label7.AutoSize = true;
            label7.Location = new Point(24, 110);
            label7.Text = "Date :";
            // 
            // lblDate
            // 
            lblDate.AutoSize = true;
            lblDate.Location = new Point(120, 110);
            lblDate.Text = "-";
            // 
            // label9 - Heure
            // 
            label9.AutoSize = true;
            label9.Location = new Point(24, 140);
            label9.Text = "Heure :";
            // 
            // lblHeure
            // 
            lblHeure.AutoSize = true;
            lblHeure.Location = new Point(120, 140);
            lblHeure.Text = "-";
            // 
            // label11 - Présence
            // 
            label11.AutoSize = true;
            label11.Location = new Point(24, 170);
            label11.Text = "Présence :";
            // 
            // lblPresence
            // 
            lblPresence.AutoSize = true;
            lblPresence.Location = new Point(120, 170);
            lblPresence.Text = "-";
            // 
            // btnClose
            // 
            btnClose.Location = new Point(24, 210);
            btnClose.Size = new Size(100, 32);
            btnClose.Text = "Fermer";
            btnClose.Click += btnClose_Click;

            // 
            // FormReservationDetail
            // 
            AutoScaleDimensions = new SizeF(8F, 20F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(380, 260);
            Controls.Add(label1);
            Controls.Add(lblId);
            Controls.Add(label3);
            Controls.Add(lblUser);
            Controls.Add(label5);
            Controls.Add(lblPrestation);
            Controls.Add(label7);
            Controls.Add(lblDate);
            Controls.Add(label9);
            Controls.Add(lblHeure);
            Controls.Add(label11);
            Controls.Add(lblPresence);
            Controls.Add(btnClose);
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;
            Name = "FormReservationDetail";
            StartPosition = FormStartPosition.CenterParent;
            Text = "Détail réservation";
            Load += FormReservationDetail_Load;
            ResumeLayout(false);
            PerformLayout();
        }
    }
}
