namespace AP3_applicationC
{
    partial class FormCreerUtil
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
            label1 = new Label();
            gbInfos = new GroupBox();
            cbRoles = new ComboBox();
            label5 = new Label();
            tbEmail = new TextBox();
            tbPrenom = new TextBox();
            tbNom = new TextBox();
            label4 = new Label();
            label3 = new Label();
            label2 = new Label();
            btnSave = new Button();
            btnCancel = new Button();
            gbInfos.SuspendLayout();
            SuspendLayout();
            // 
            // label1
            // 
            label1.AutoSize = true;
            label1.Font = new Font("Segoe UI", 13.8F, FontStyle.Bold, GraphicsUnit.Point, 0);
            label1.Location = new Point(46, 46);
            label1.Name = "label1";
            label1.Size = new Size(220, 31);
            label1.TabIndex = 12;
            label1.Text = "Créer un utilisateur";
            // 
            // gbInfos
            // 
            gbInfos.Controls.Add(cbRoles);
            gbInfos.Controls.Add(label5);
            gbInfos.Controls.Add(tbEmail);
            gbInfos.Controls.Add(tbPrenom);
            gbInfos.Controls.Add(tbNom);
            gbInfos.Controls.Add(label4);
            gbInfos.Controls.Add(label3);
            gbInfos.Controls.Add(label2);
            gbInfos.Font = new Font("Segoe UI", 10.2F, FontStyle.Bold, GraphicsUnit.Point, 0);
            gbInfos.Location = new Point(46, 115);
            gbInfos.Name = "gbInfos";
            gbInfos.Size = new Size(618, 252);
            gbInfos.TabIndex = 13;
            gbInfos.TabStop = false;
            gbInfos.Text = "Informations sur un utilisateur";
            // 
            // cbRoles
            // 
            cbRoles.DropDownStyle = ComboBoxStyle.DropDownList;
            cbRoles.Font = new Font("Segoe UI", 10.2F, FontStyle.Regular, GraphicsUnit.Point, 0);
            cbRoles.Location = new Point(179, 188);
            cbRoles.Name = "cbRoles";
            cbRoles.Size = new Size(354, 31);
            cbRoles.TabIndex = 7;
            // 
            // label5
            // 
            label5.AutoSize = true;
            label5.Font = new Font("Segoe UI", 10.2F, FontStyle.Regular, GraphicsUnit.Point, 0);
            label5.Location = new Point(68, 191);
            label5.Name = "label5";
            label5.Size = new Size(43, 23);
            label5.TabIndex = 6;
            label5.Text = "Role";
            // 
            // tbEmail
            // 
            tbEmail.Font = new Font("Segoe UI", 10.2F, FontStyle.Regular, GraphicsUnit.Point, 0);
            tbEmail.Location = new Point(179, 139);
            tbEmail.Name = "tbEmail";
            tbEmail.Size = new Size(354, 30);
            tbEmail.TabIndex = 5;
            // 
            // tbPrenom
            // 
            tbPrenom.Font = new Font("Segoe UI", 10.2F, FontStyle.Regular, GraphicsUnit.Point, 0);
            tbPrenom.Location = new Point(179, 88);
            tbPrenom.Name = "tbPrenom";
            tbPrenom.Size = new Size(354, 30);
            tbPrenom.TabIndex = 4;
            // 
            // tbNom
            // 
            tbNom.Font = new Font("Segoe UI", 10.2F, FontStyle.Regular, GraphicsUnit.Point, 0);
            tbNom.Location = new Point(179, 39);
            tbNom.Name = "tbNom";
            tbNom.Size = new Size(354, 30);
            tbNom.TabIndex = 3;
            // 
            // label4
            // 
            label4.AutoSize = true;
            label4.Font = new Font("Segoe UI", 10.2F, FontStyle.Regular, GraphicsUnit.Point, 0);
            label4.Location = new Point(68, 139);
            label4.Name = "label4";
            label4.Size = new Size(51, 23);
            label4.TabIndex = 2;
            label4.Text = "Email";
            // 
            // label3
            // 
            label3.AutoSize = true;
            label3.Font = new Font("Segoe UI", 10.2F, FontStyle.Regular, GraphicsUnit.Point, 0);
            label3.Location = new Point(68, 88);
            label3.Name = "label3";
            label3.Size = new Size(70, 23);
            label3.TabIndex = 1;
            label3.Text = "Prénom";
            // 
            // label2
            // 
            label2.AutoSize = true;
            label2.Font = new Font("Segoe UI", 10.2F, FontStyle.Regular, GraphicsUnit.Point, 0);
            label2.Location = new Point(68, 38);
            label2.Name = "label2";
            label2.Size = new Size(48, 23);
            label2.TabIndex = 0;
            label2.Text = "Nom";
            // 
            // btnSave
            // 
            btnSave.Location = new Point(225, 383);
            btnSave.Name = "btnSave";
            btnSave.Size = new Size(100, 36);
            btnSave.TabIndex = 14;
            btnSave.Text = "Enregistrer";
            btnSave.UseVisualStyleBackColor = true;
            btnSave.Click += btnSave_Click;
            // 
            // btnCancel
            // 
            btnCancel.Location = new Point(390, 383);
            btnCancel.Name = "btnCancel";
            btnCancel.Size = new Size(100, 36);
            btnCancel.TabIndex = 15;
            btnCancel.Text = "Annuler";
            btnCancel.UseVisualStyleBackColor = true;
            btnCancel.Click += btnCancel_Click;
            // 
            // FormCreerUtil
            // 
            AutoScaleDimensions = new SizeF(8F, 20F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(878, 773);
            Controls.Add(btnCancel);
            Controls.Add(btnSave);
            Controls.Add(gbInfos);
            Controls.Add(label1);
            FormBorderStyle = FormBorderStyle.None;
            Name = "FormCreerUtil";
            Text = "FormCreerUtil";
            Load += FormCreerUtil_Load;
            gbInfos.ResumeLayout(false);
            gbInfos.PerformLayout();
            ResumeLayout(false);
            PerformLayout();
        }

        #endregion

        private Label label1;
        private GroupBox gbInfos;
        private TextBox tbEmail;
        private TextBox tbPrenom;
        private TextBox tbNom;
        private Label label4;
        private Label label3;
        private Label label2;
        private Label label5;
        private ComboBox cbRoles;
        private Button btnSave;
        private Button btnCancel;
    }
}