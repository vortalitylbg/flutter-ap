namespace AP3_applicationC
{
    partial class FormModifEmail
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
            gbInfos = new GroupBox();
            tbEmail = new TextBox();
            tbPrenom = new TextBox();
            tbNom = new TextBox();
            label4 = new Label();
            label3 = new Label();
            label2 = new Label();
            btnSave = new Button();
            button1 = new Button();
            gbInfos.SuspendLayout();
            SuspendLayout();
            // 
            // gbInfos
            // 
            gbInfos.Controls.Add(tbEmail);
            gbInfos.Controls.Add(tbPrenom);
            gbInfos.Controls.Add(tbNom);
            gbInfos.Controls.Add(label4);
            gbInfos.Controls.Add(label3);
            gbInfos.Controls.Add(label2);
            gbInfos.Font = new Font("Segoe UI", 10.2F, FontStyle.Bold, GraphicsUnit.Point, 0);
            gbInfos.Location = new Point(46, 49);
            gbInfos.Name = "gbInfos";
            gbInfos.Size = new Size(618, 201);
            gbInfos.TabIndex = 14;
            gbInfos.TabStop = false;
            gbInfos.Text = "Modifier l'email";
            // 
            // tbEmail
            // 
            tbEmail.Font = new Font("Segoe UI", 10.2F, FontStyle.Regular, GraphicsUnit.Point, 0);
            tbEmail.Location = new Point(179, 139);
            tbEmail.Name = "tbEmail";
            tbEmail.Size = new Size(354, 30);
            tbEmail.TabIndex = 0;
            // 
            // tbPrenom
            // 
            tbPrenom.Font = new Font("Segoe UI", 10.2F, FontStyle.Regular, GraphicsUnit.Point, 0);
            tbPrenom.Location = new Point(179, 88);
            tbPrenom.Name = "tbPrenom";
            tbPrenom.ReadOnly = true;
            tbPrenom.Size = new Size(354, 30);
            tbPrenom.TabIndex = 4;
            // 
            // tbNom
            // 
            tbNom.Font = new Font("Segoe UI", 10.2F, FontStyle.Regular, GraphicsUnit.Point, 0);
            tbNom.Location = new Point(179, 39);
            tbNom.Name = "tbNom";
            tbNom.ReadOnly = true;
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
            btnSave.Location = new Point(225, 265);
            btnSave.Name = "btnSave";
            btnSave.Size = new Size(100, 36);
            btnSave.TabIndex = 15;
            btnSave.Text = "Modifier";
            btnSave.UseVisualStyleBackColor = true;
            btnSave.Click += btnSave_Click;
            // 
            // button1
            // 
            button1.Location = new Point(385, 265);
            button1.Name = "button1";
            button1.Size = new Size(100, 36);
            button1.TabIndex = 16;
            button1.Text = "Annuler";
            button1.UseVisualStyleBackColor = true;
            button1.Click += button1_Click;
            // 
            // FormModifEmail
            // 
            AutoScaleDimensions = new SizeF(8F, 20F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(714, 352);
            Controls.Add(button1);
            Controls.Add(btnSave);
            Controls.Add(gbInfos);
            Name = "FormModifEmail";
            StartPosition = FormStartPosition.CenterScreen;
            Text = "UTILISATEUR : Modifier Email";
            Load += FormModifEmail_Load;
            gbInfos.ResumeLayout(false);
            gbInfos.PerformLayout();
            ResumeLayout(false);
        }

        #endregion

        private GroupBox gbInfos;
        private TextBox tbEmail;
        private TextBox tbPrenom;
        private TextBox tbNom;
        private Label label4;
        private Label label3;
        private Label label2;
        private Button btnSave;
        private Button button1;
    }
}