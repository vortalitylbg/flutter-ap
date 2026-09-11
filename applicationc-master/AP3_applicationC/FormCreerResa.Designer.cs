using System;
using System.ComponentModel;
using System.Drawing;
using System.Windows.Forms;

namespace AP3_applicationC
{
    partial class FormCreerResa
    {
        private IContainer components = null;
        private Label lblUtilisateur;
        private ComboBox cbUtilisateur;
        private Label lblDate;
        private DateTimePicker dtpDate;
        private Label lblHeure;
        private ComboBox cbHeure;
        private CheckBox chkValidation;
        private Button btnSave;
        private Button btnCancel;

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
            lblUtilisateur = new Label();
            cbUtilisateur = new ComboBox();
            lblDate = new Label();
            dtpDate = new DateTimePicker();
            lblHeure = new Label();
            cbHeure = new ComboBox();
            chkValidation = new CheckBox();
            btnSave = new Button();
            btnCancel = new Button();
            label1 = new Label();
            groupBox1 = new GroupBox();
            groupBox1.SuspendLayout();
            SuspendLayout();
            // 
            // lblUtilisateur
            // 
            lblUtilisateur.AutoSize = true;
            lblUtilisateur.Font = new Font("Segoe UI", 10.2F, FontStyle.Regular, GraphicsUnit.Point, 0);
            lblUtilisateur.Location = new Point(77, 53);
            lblUtilisateur.Name = "lblUtilisateur";
            lblUtilisateur.Size = new Size(87, 23);
            lblUtilisateur.TabIndex = 0;
            lblUtilisateur.Text = "Utilisateur";
            // 
            // cbUtilisateur
            // 
            cbUtilisateur.DropDownStyle = ComboBoxStyle.DropDownList;
            cbUtilisateur.Location = new Point(231, 45);
            cbUtilisateur.Name = "cbUtilisateur";
            cbUtilisateur.Size = new Size(320, 31);
            cbUtilisateur.TabIndex = 1;
            // 
            // lblDate
            // 
            lblDate.AutoSize = true;
            lblDate.Font = new Font("Segoe UI", 10.2F, FontStyle.Regular, GraphicsUnit.Point, 0);
            lblDate.Location = new Point(77, 157);
            lblDate.Name = "lblDate";
            lblDate.Size = new Size(46, 23);
            lblDate.TabIndex = 4;
            lblDate.Text = "Date";
            // 
            // dtpDate
            // 
            dtpDate.Font = new Font("Segoe UI", 10.2F, FontStyle.Regular, GraphicsUnit.Point, 0);
            dtpDate.Format = DateTimePickerFormat.Short;
            dtpDate.Location = new Point(147, 150);
            dtpDate.Name = "dtpDate";
            dtpDate.Size = new Size(150, 30);
            dtpDate.TabIndex = 5;
            // 
            // lblHeure
            // 
            lblHeure.AutoSize = true;
            lblHeure.Font = new Font("Segoe UI", 10.2F);
            lblHeure.Location = new Point(331, 157);
            lblHeure.Name = "lblHeure";
            lblHeure.Size = new Size(56, 23);
            lblHeure.TabIndex = 6;
            lblHeure.Text = "Heure";
            // 
            // cbHeure
            // 
            cbHeure.DropDownStyle = ComboBoxStyle.DropDownList;
            cbHeure.Font = new Font("Segoe UI", 10.2F);
            cbHeure.Location = new Point(407, 150);
            cbHeure.Name = "cbHeure";
            cbHeure.Size = new Size(144, 31);
            cbHeure.TabIndex = 7;
            // 
            // chkValidation
            // 
            chkValidation.AutoSize = true;
            chkValidation.Font = new Font("Segoe UI", 10.2F);
            chkValidation.Location = new Point(77, 203);
            chkValidation.Name = "chkValidation";
            chkValidation.Size = new Size(181, 27);
            chkValidation.TabIndex = 8;
            chkValidation.Text = "Validation présence";
            chkValidation.UseVisualStyleBackColor = true;
            // 
            // btnSave
            // 
            btnSave.Font = new Font("Segoe UI", 10.2F, FontStyle.Regular, GraphicsUnit.Point, 0);
            btnSave.Location = new Point(308, 369);
            btnSave.Name = "btnSave";
            btnSave.Size = new Size(100, 36);
            btnSave.TabIndex = 9;
            btnSave.Text = "Enregistrer";
            btnSave.UseVisualStyleBackColor = true;
            btnSave.Click += btnSave_Click;
            // 
            // btnCancel
            // 
            btnCancel.Font = new Font("Segoe UI", 10.2F, FontStyle.Regular, GraphicsUnit.Point, 0);
            btnCancel.Location = new Point(492, 369);
            btnCancel.Name = "btnCancel";
            btnCancel.Size = new Size(100, 36);
            btnCancel.TabIndex = 10;
            btnCancel.Text = "Annuler";
            btnCancel.UseVisualStyleBackColor = true;
            btnCancel.Click += btnCancel_Click;
            // 
            // label1
            // 
            label1.AutoSize = true;
            label1.Font = new Font("Segoe UI", 13.8F, FontStyle.Bold, GraphicsUnit.Point, 0);
            label1.Location = new Point(161, 35);
            label1.Name = "label1";
            label1.Size = new Size(243, 31);
            label1.TabIndex = 11;
            label1.Text = "Créer une réservation";
            // 
            // groupBox1
            // 
            groupBox1.Controls.Add(cbUtilisateur);
            groupBox1.Controls.Add(lblDate);
            groupBox1.Controls.Add(lblUtilisateur);
            groupBox1.Controls.Add(cbHeure);
            groupBox1.Controls.Add(dtpDate);
            groupBox1.Controls.Add(lblHeure);
            groupBox1.Controls.Add(chkValidation);
            groupBox1.Font = new Font("Segoe UI", 10.2F, FontStyle.Bold, GraphicsUnit.Point, 0);
            groupBox1.Location = new Point(161, 91);
            groupBox1.Name = "groupBox1";
            groupBox1.Size = new Size(584, 249);
            groupBox1.TabIndex = 12;
            groupBox1.TabStop = false;
            groupBox1.Text = "Ma réservation";
            // 
            // FormCreerResa
            // 
            AutoScaleDimensions = new SizeF(8F, 20F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(896, 820);
            Controls.Add(groupBox1);
            Controls.Add(label1);
            Controls.Add(btnSave);
            Controls.Add(btnCancel);
            FormBorderStyle = FormBorderStyle.None;
            MaximizeBox = false;
            MinimizeBox = false;
            Name = "FormCreerResa";
            StartPosition = FormStartPosition.Manual;
            Text = "Créer réservation";
            Load += FormCreerResa_Load;
            groupBox1.ResumeLayout(false);
            groupBox1.PerformLayout();
            ResumeLayout(false);
            PerformLayout();
        }

        private Label label1;
        private GroupBox groupBox1;
    }
}
