using System;
using System.ComponentModel;
using System.Drawing;
using System.Windows.Forms;

namespace AP3_applicationC
{
    partial class FormSuivreResa
    {
        private IContainer components = null;
        private SplitContainer splitContainer1;
        private MonthCalendar mcCalendar;
        private DataGridView dgvReservations;
        private Label lblSelectedDate;
        private Label lblStatus;

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
            splitContainer1 = new SplitContainer();
            mcCalendar = new MonthCalendar();
            dgvReservations = new DataGridView();
            dataGridViewTextBoxColumn1 = new DataGridViewTextBoxColumn();
            dataGridViewTextBoxColumn2 = new DataGridViewTextBoxColumn();
            dataGridViewTextBoxColumn3 = new DataGridViewTextBoxColumn();
            dataGridViewTextBoxColumn4 = new DataGridViewTextBoxColumn();
            lblSelectedDate = new Label();
            lblStatus = new Label();
            ((ISupportInitialize)splitContainer1).BeginInit();
            splitContainer1.Panel1.SuspendLayout();
            splitContainer1.Panel2.SuspendLayout();
            splitContainer1.SuspendLayout();
            ((ISupportInitialize)dgvReservations).BeginInit();
            SuspendLayout();
            // 
            // splitContainer1
            // 
            splitContainer1.Dock = DockStyle.Fill;
            splitContainer1.Location = new Point(0, 0);
            splitContainer1.Name = "splitContainer1";
            // 
            // splitContainer1.Panel1
            // 
            splitContainer1.Panel1.Controls.Add(mcCalendar);
            // 
            // splitContainer1.Panel2
            // 
            splitContainer1.Panel2.Controls.Add(dgvReservations);
            splitContainer1.Panel2.Controls.Add(lblSelectedDate);
            splitContainer1.Panel2.Controls.Add(lblStatus);
            splitContainer1.Size = new Size(1218, 583);
            splitContainer1.SplitterDistance = 387;
            splitContainer1.TabIndex = 0;
            // 
            // mcCalendar
            // 
            mcCalendar.CalendarDimensions = new Size(1, 3);
            mcCalendar.Dock = DockStyle.Fill;
            mcCalendar.Location = new Point(0, 0);
            mcCalendar.MaxSelectionCount = 1;
            mcCalendar.Name = "mcCalendar";
            mcCalendar.TabIndex = 0;
            mcCalendar.DateSelected += mcCalendar_DateSelected;
            // 
            // dgvReservations
            // 
            dgvReservations.AllowUserToAddRows = false;
            dgvReservations.AllowUserToDeleteRows = false;
            dgvReservations.Anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right;
            dgvReservations.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
            dgvReservations.ColumnHeadersHeightSizeMode = DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            dgvReservations.Columns.AddRange(new DataGridViewColumn[] { dataGridViewTextBoxColumn1, dataGridViewTextBoxColumn2, dataGridViewTextBoxColumn3, dataGridViewTextBoxColumn4 });
            dgvReservations.Location = new Point(0, 43);
            dgvReservations.Name = "dgvReservations";
            dgvReservations.ReadOnly = true;
            dgvReservations.RowHeadersWidth = 51;
            dgvReservations.Size = new Size(827, 620);
            dgvReservations.TabIndex = 0;
            dgvReservations.CellDoubleClick += dgvReservations_CellDoubleClick;
            // 
            // dataGridViewTextBoxColumn1
            // 
            dataGridViewTextBoxColumn1.HeaderText = "Heure";
            dataGridViewTextBoxColumn1.MinimumWidth = 6;
            dataGridViewTextBoxColumn1.Name = "dataGridViewTextBoxColumn1";
            dataGridViewTextBoxColumn1.ReadOnly = true;
            // 
            // dataGridViewTextBoxColumn2
            // 
            dataGridViewTextBoxColumn2.HeaderText = "Utilisateur";
            dataGridViewTextBoxColumn2.MinimumWidth = 6;
            dataGridViewTextBoxColumn2.Name = "dataGridViewTextBoxColumn2";
            dataGridViewTextBoxColumn2.ReadOnly = true;
            // 
            // dataGridViewTextBoxColumn3
            // 
            dataGridViewTextBoxColumn3.HeaderText = "Prestation";
            dataGridViewTextBoxColumn3.MinimumWidth = 6;
            dataGridViewTextBoxColumn3.Name = "dataGridViewTextBoxColumn3";
            dataGridViewTextBoxColumn3.ReadOnly = true;
            // 
            // dataGridViewTextBoxColumn4
            // 
            dataGridViewTextBoxColumn4.HeaderText = "Présence";
            dataGridViewTextBoxColumn4.MinimumWidth = 6;
            dataGridViewTextBoxColumn4.Name = "dataGridViewTextBoxColumn4";
            dataGridViewTextBoxColumn4.ReadOnly = true;
            // 
            // lblSelectedDate
            // 
            lblSelectedDate.Dock = DockStyle.Top;
            lblSelectedDate.Location = new Point(0, 0);
            lblSelectedDate.Name = "lblSelectedDate";
            lblSelectedDate.Padding = new Padding(8, 0, 0, 0);
            lblSelectedDate.Size = new Size(827, 43);
            lblSelectedDate.TabIndex = 1;
            lblSelectedDate.Text = "Réservations";
            lblSelectedDate.TextAlign = ContentAlignment.MiddleLeft;
            // 
            // lblStatus
            // 
            lblStatus.Anchor = AnchorStyles.Left | AnchorStyles.Right;
            lblStatus.ForeColor = Color.Red;
            lblStatus.Location = new Point(0, 554);
            lblStatus.Name = "lblStatus";
            lblStatus.Size = new Size(827, 23);
            lblStatus.TabIndex = 2;
            lblStatus.Text = "Double-Cliquer sur une réservation pour avoir le détail.";
            lblStatus.TextAlign = ContentAlignment.MiddleLeft;
            // 
            // FormSuivreResa
            // 
            AutoScaleDimensions = new SizeF(8F, 20F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(1218, 583);
            Controls.Add(splitContainer1);
            FormBorderStyle = FormBorderStyle.None;
            Name = "FormSuivreResa";
            StartPosition = FormStartPosition.Manual;
            Text = "Suivre réservations";
            Load += FormSuivreResa_Load;
            splitContainer1.Panel1.ResumeLayout(false);
            splitContainer1.Panel2.ResumeLayout(false);
            ((ISupportInitialize)splitContainer1).EndInit();
            splitContainer1.ResumeLayout(false);
            ((ISupportInitialize)dgvReservations).EndInit();
            ResumeLayout(false);
        }

        private DataGridViewTextBoxColumn dataGridViewTextBoxColumn1;
        private DataGridViewTextBoxColumn dataGridViewTextBoxColumn2;
        private DataGridViewTextBoxColumn dataGridViewTextBoxColumn3;
        private DataGridViewTextBoxColumn dataGridViewTextBoxColumn4;
    }
}
