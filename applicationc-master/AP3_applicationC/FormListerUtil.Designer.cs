namespace AP3_applicationC
{
    partial class FormListerUtil
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            components = new System.ComponentModel.Container();
            DataGridViewCellStyle dataGridViewCellStyle1 = new DataGridViewCellStyle();
            DataGridViewCellStyle dataGridViewCellStyle2 = new DataGridViewCellStyle();
            label1 = new Label();
            dgvListeUtil = new DataGridView();
            contextMenuStrip1 = new ContextMenuStrip(components);
            modifierEmailToolStripMenuItem = new ToolStripMenuItem();
            bsListeUtil = new BindingSource(components);
            btnFermer = new Button();
            label2 = new Label();
            ((System.ComponentModel.ISupportInitialize)dgvListeUtil).BeginInit();
            contextMenuStrip1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)bsListeUtil).BeginInit();
            SuspendLayout();
            // 
            // label1
            // 
            label1.AutoSize = true;
            label1.Location = new Point(29, 50);
            label1.Margin = new Padding(5, 0, 5, 0);
            label1.Name = "label1";
            label1.Size = new Size(232, 31);
            label1.TabIndex = 0;
            label1.Text = "Liste des utilisateurs";
            // 
            // dgvListeUtil
            // 
            dgvListeUtil.AllowUserToAddRows = false;
            dgvListeUtil.AllowUserToDeleteRows = false;
            dgvListeUtil.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.AllCells;
            dgvListeUtil.AutoSizeRowsMode = DataGridViewAutoSizeRowsMode.AllCells;
            dataGridViewCellStyle1.Alignment = DataGridViewContentAlignment.MiddleLeft;
            dataGridViewCellStyle1.BackColor = SystemColors.Control;
            dataGridViewCellStyle1.Font = new Font("Segoe UI", 12F, FontStyle.Bold, GraphicsUnit.Point, 0);
            dataGridViewCellStyle1.ForeColor = SystemColors.WindowText;
            dataGridViewCellStyle1.SelectionBackColor = SystemColors.Highlight;
            dataGridViewCellStyle1.SelectionForeColor = SystemColors.HighlightText;
            dataGridViewCellStyle1.WrapMode = DataGridViewTriState.True;
            dgvListeUtil.ColumnHeadersDefaultCellStyle = dataGridViewCellStyle1;
            dgvListeUtil.ColumnHeadersHeightSizeMode = DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            dgvListeUtil.ContextMenuStrip = contextMenuStrip1;
            dataGridViewCellStyle2.Alignment = DataGridViewContentAlignment.MiddleLeft;
            dataGridViewCellStyle2.BackColor = SystemColors.Window;
            dataGridViewCellStyle2.Font = new Font("Segoe UI", 10.8F, FontStyle.Regular, GraphicsUnit.Point, 0);
            dataGridViewCellStyle2.ForeColor = SystemColors.ControlText;
            dataGridViewCellStyle2.SelectionBackColor = SystemColors.Highlight;
            dataGridViewCellStyle2.SelectionForeColor = SystemColors.HighlightText;
            dataGridViewCellStyle2.WrapMode = DataGridViewTriState.False;
            dgvListeUtil.DefaultCellStyle = dataGridViewCellStyle2;
            dgvListeUtil.Location = new Point(29, 119);
            dgvListeUtil.MultiSelect = false;
            dgvListeUtil.Name = "dgvListeUtil";
            dgvListeUtil.ReadOnly = true;
            dgvListeUtil.RowHeadersWidth = 51;
            dgvListeUtil.Size = new Size(838, 412);
            dgvListeUtil.TabIndex = 1;
            // 
            // contextMenuStrip1
            // 
            contextMenuStrip1.ImageScalingSize = new Size(20, 20);
            contextMenuStrip1.Items.AddRange(new ToolStripItem[] { modifierEmailToolStripMenuItem });
            contextMenuStrip1.Name = "contextMenuStrip1";
            contextMenuStrip1.Size = new Size(177, 28);
            // 
            // modifierEmailToolStripMenuItem
            // 
            modifierEmailToolStripMenuItem.Name = "modifierEmailToolStripMenuItem";
            modifierEmailToolStripMenuItem.Size = new Size(176, 24);
            modifierEmailToolStripMenuItem.Text = "Modifier Email";
            modifierEmailToolStripMenuItem.Click += modifierEmailToolStripMenuItem_Click;
            // 
            // btnFermer
            // 
            btnFermer.Font = new Font("Segoe UI", 12F, FontStyle.Regular, GraphicsUnit.Point, 0);
            btnFermer.Location = new Point(773, 577);
            btnFermer.Name = "btnFermer";
            btnFermer.Size = new Size(94, 48);
            btnFermer.TabIndex = 2;
            btnFermer.Text = "FERMER";
            btnFermer.UseVisualStyleBackColor = true;
            btnFermer.Click += btnFermer_Click;
            // 
            // label2
            // 
            label2.AutoSize = true;
            label2.Font = new Font("Segoe UI", 12F, FontStyle.Regular, GraphicsUnit.Point, 0);
            label2.ForeColor = Color.Red;
            label2.Location = new Point(29, 585);
            label2.Name = "label2";
            label2.Size = new Size(454, 28);
            label2.TabIndex = 3;
            label2.Text = "clic-droit sur un utilisateur pour modifier son email";
            // 
            // FormListerUtil
            // 
            AutoScaleDimensions = new SizeF(14F, 31F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(914, 867);
            Controls.Add(label2);
            Controls.Add(btnFermer);
            Controls.Add(dgvListeUtil);
            Controls.Add(label1);
            Font = new Font("Segoe UI", 13.8F, FontStyle.Bold, GraphicsUnit.Point, 0);
            FormBorderStyle = FormBorderStyle.None;
            Margin = new Padding(5);
            Name = "FormListerUtil";
            Text = "FormProfil";
            Load += FormListerUtil_Load;
            ((System.ComponentModel.ISupportInitialize)dgvListeUtil).EndInit();
            contextMenuStrip1.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)bsListeUtil).EndInit();
            ResumeLayout(false);
            PerformLayout();
        }

        #endregion

        private Label label1;
        private DataGridView dgvListeUtil;
        private BindingSource bsListeUtil;
        private Button btnFermer;
        private ContextMenuStrip contextMenuStrip1;
        private ToolStripMenuItem modifierEmailToolStripMenuItem;
        private Label label2;
    }
}