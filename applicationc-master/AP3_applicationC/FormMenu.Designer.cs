using System.ComponentModel;
using System.Drawing;
using System.Windows.Forms;

namespace AP3_applicationC
{
    partial class FormMenu
    {
        private IContainer components = null;
        private Panel panelMenu;
        private Panel panelContent;
        private Button btnToggle;
        private Button btnItem1;
        private Button btnItem2;
        private Button btnItem3;
        private Button btnItem4;
        private Panel panelReservationSubMenu;
        private Button btnReservationSubItem1;
        private Button btnReservationSubItem2;
        private System.Windows.Forms.Timer timerMenu;
        private System.Windows.Forms.Timer timerReservationSubMenu;

        // Submenu controls
        private Panel panelProfileSubMenuUtil;

        private Button btnProfileSubItem1;
        private Button btnProfileSubItem2;
        private Button btnProfileSubItem3;
        private System.Windows.Forms.Timer timerSubMenu;

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
            panelMenu = new Panel();
            btnItem4 = new Button();
            panelReservationSubMenu = new Panel();
            btnReservationSubItem2 = new Button();
            btnReservationSubItem1 = new Button();
            btnItem3 = new Button();
            panelProfileSubMenuUtil = new Panel();
            btnProfileSubItem3 = new Button();
            btnProfileSubItem2 = new Button();
            btnProfileSubItem1 = new Button();
            btnItem2 = new Button();
            btnItem1 = new Button();
            btnToggle = new Button();
            panelContent = new Panel();
            timerMenu = new System.Windows.Forms.Timer(components);
            timerSubMenu = new System.Windows.Forms.Timer(components);
            timerReservationSubMenu = new System.Windows.Forms.Timer(components);
            panelMenu.SuspendLayout();
            panelReservationSubMenu.SuspendLayout();
            panelProfileSubMenuUtil.SuspendLayout();
            SuspendLayout();
            // 
            // panelMenu
            // 
            panelMenu.BackColor = Color.FromArgb(33, 37, 43);
            panelMenu.Controls.Add(btnItem4);
            panelMenu.Controls.Add(panelReservationSubMenu);
            panelMenu.Controls.Add(btnItem3);
            panelMenu.Controls.Add(panelProfileSubMenuUtil);
            panelMenu.Controls.Add(btnItem2);
            panelMenu.Controls.Add(btnItem1);
            panelMenu.Controls.Add(btnToggle);
            panelMenu.Dock = DockStyle.Left;
            panelMenu.Location = new Point(0, 0);
            panelMenu.Margin = new Padding(3, 4, 3, 4);
            panelMenu.Name = "panelMenu";
            panelMenu.Size = new Size(229, 867);
            panelMenu.TabIndex = 1;
          //  panelMenu.Paint += this.panelMenu_Paint;
            // 
            // btnItem4
            // 
            btnItem4.BackColor = Color.FromArgb(33, 37, 43);
            btnItem4.Dock = DockStyle.Top;
            btnItem4.FlatAppearance.BorderSize = 0;
            btnItem4.FlatStyle = FlatStyle.Flat;
            btnItem4.Font = new Font("Segoe UI", 10F);
            btnItem4.ForeColor = Color.White;
            btnItem4.Location = new Point(0, 256);
            btnItem4.Margin = new Padding(3, 4, 3, 4);
            btnItem4.Name = "btnItem4";
            btnItem4.Padding = new Padding(14, 0, 0, 0);
            btnItem4.Size = new Size(229, 64);
            btnItem4.TabIndex = 0;
            btnItem4.Text = "🔒  Quitter";
            btnItem4.TextAlign = ContentAlignment.MiddleLeft;
            btnItem4.UseVisualStyleBackColor = false;
            btnItem4.Click += btnItem4_Click;
            // 
            // panelReservationSubMenu
            // 
            panelReservationSubMenu.BackColor = Color.FromArgb(45, 49, 56);
            panelReservationSubMenu.Controls.Add(btnReservationSubItem2);
            panelReservationSubMenu.Controls.Add(btnReservationSubItem1);
            panelReservationSubMenu.Dock = DockStyle.Top;
            panelReservationSubMenu.Location = new Point(0, 256);
            panelReservationSubMenu.Margin = new Padding(0);
            panelReservationSubMenu.Name = "panelReservationSubMenu";
            panelReservationSubMenu.Size = new Size(229, 0);
            panelReservationSubMenu.TabIndex = 11;
            panelReservationSubMenu.Visible = false;
            // 
            // btnReservationSubItem2
            // 
            btnReservationSubItem2.BackColor = Color.FromArgb(45, 49, 56);
            btnReservationSubItem2.Dock = DockStyle.Top;
            btnReservationSubItem2.FlatAppearance.BorderSize = 0;
            btnReservationSubItem2.FlatStyle = FlatStyle.Flat;
            btnReservationSubItem2.Font = new Font("Segoe UI", 9F);
            btnReservationSubItem2.ForeColor = Color.White;
            btnReservationSubItem2.Location = new Point(0, 48);
            btnReservationSubItem2.Margin = new Padding(3, 4, 3, 4);
            btnReservationSubItem2.Name = "btnReservationSubItem2";
            btnReservationSubItem2.Padding = new Padding(40, 0, 0, 0);
            btnReservationSubItem2.Size = new Size(229, 48);
            btnReservationSubItem2.TabIndex = 1;
            btnReservationSubItem2.Text = "Créer";
            btnReservationSubItem2.TextAlign = ContentAlignment.MiddleLeft;
            btnReservationSubItem2.UseVisualStyleBackColor = false;
            btnReservationSubItem2.Click += btnReservationSubItem2_Click;
            // 
            // btnReservationSubItem1
            // 
            btnReservationSubItem1.BackColor = Color.FromArgb(45, 49, 56);
            btnReservationSubItem1.Dock = DockStyle.Top;
            btnReservationSubItem1.FlatAppearance.BorderSize = 0;
            btnReservationSubItem1.FlatStyle = FlatStyle.Flat;
            btnReservationSubItem1.Font = new Font("Segoe UI", 9F);
            btnReservationSubItem1.ForeColor = Color.White;
            btnReservationSubItem1.Location = new Point(0, 0);
            btnReservationSubItem1.Margin = new Padding(3, 4, 3, 4);
            btnReservationSubItem1.Name = "btnReservationSubItem1";
            btnReservationSubItem1.Padding = new Padding(40, 0, 0, 0);
            btnReservationSubItem1.Size = new Size(229, 48);
            btnReservationSubItem1.TabIndex = 0;
            btnReservationSubItem1.Text = "Suivre";
            btnReservationSubItem1.TextAlign = ContentAlignment.MiddleLeft;
            btnReservationSubItem1.UseVisualStyleBackColor = false;
            btnReservationSubItem1.Click += btnReservationSubItem1_Click;
            // 
            // btnItem3
            // 
            btnItem3.BackColor = Color.FromArgb(33, 37, 43);
            btnItem3.Dock = DockStyle.Top;
            btnItem3.FlatAppearance.BorderSize = 0;
            btnItem3.FlatStyle = FlatStyle.Flat;
            btnItem3.Font = new Font("Segoe UI", 10F);
            btnItem3.ForeColor = Color.White;
            btnItem3.Location = new Point(0, 192);
            btnItem3.Margin = new Padding(3, 4, 3, 4);
            btnItem3.Name = "btnItem3";
            btnItem3.Padding = new Padding(14, 0, 0, 0);
            btnItem3.Size = new Size(229, 64);
            btnItem3.TabIndex = 1;
            btnItem3.Text = "📅  Réservations";
            btnItem3.TextAlign = ContentAlignment.MiddleLeft;
            btnItem3.UseVisualStyleBackColor = false;
            btnItem3.Click += btnItem3_Click;
            // 
            // panelProfileSubMenuUtil
            // 
            panelProfileSubMenuUtil.BackColor = Color.FromArgb(45, 49, 56);
            panelProfileSubMenuUtil.Controls.Add(btnProfileSubItem3);
            panelProfileSubMenuUtil.Controls.Add(btnProfileSubItem2);
            panelProfileSubMenuUtil.Controls.Add(btnProfileSubItem1);
            panelProfileSubMenuUtil.Dock = DockStyle.Top;
            panelProfileSubMenuUtil.Location = new Point(0, 192);
            panelProfileSubMenuUtil.Margin = new Padding(0);
            panelProfileSubMenuUtil.Name = "panelProfileSubMenuUtil";
            panelProfileSubMenuUtil.Size = new Size(229, 0);
            panelProfileSubMenuUtil.TabIndex = 10;
            panelProfileSubMenuUtil.Visible = false;
            // 
            // btnProfileSubItem3
            // 
            btnProfileSubItem3.BackColor = Color.FromArgb(45, 49, 56);
            btnProfileSubItem3.Dock = DockStyle.Top;
            btnProfileSubItem3.FlatAppearance.BorderSize = 0;
            btnProfileSubItem3.FlatStyle = FlatStyle.Flat;
            btnProfileSubItem3.Font = new Font("Segoe UI", 9F);
            btnProfileSubItem3.ForeColor = Color.White;
            btnProfileSubItem3.Location = new Point(0, 96);
            btnProfileSubItem3.Margin = new Padding(3, 4, 3, 4);
            btnProfileSubItem3.Name = "btnProfileSubItem3";
            btnProfileSubItem3.Padding = new Padding(40, 0, 0, 0);
            btnProfileSubItem3.Size = new Size(229, 48);
            btnProfileSubItem3.TabIndex = 2;
            btnProfileSubItem3.Text = "Modifier/Supprimer";
            btnProfileSubItem3.TextAlign = ContentAlignment.MiddleLeft;
            btnProfileSubItem3.UseVisualStyleBackColor = false;
            btnProfileSubItem3.Click += btnProfileSubItem3_Click;
            // 
            // btnProfileSubItem2
            // 
            btnProfileSubItem2.BackColor = Color.FromArgb(45, 49, 56);
            btnProfileSubItem2.Dock = DockStyle.Top;
            btnProfileSubItem2.FlatAppearance.BorderSize = 0;
            btnProfileSubItem2.FlatStyle = FlatStyle.Flat;
            btnProfileSubItem2.Font = new Font("Segoe UI", 9F);
            btnProfileSubItem2.ForeColor = Color.White;
            btnProfileSubItem2.Location = new Point(0, 48);
            btnProfileSubItem2.Margin = new Padding(3, 4, 3, 4);
            btnProfileSubItem2.Name = "btnProfileSubItem2";
            btnProfileSubItem2.Padding = new Padding(40, 0, 0, 0);
            btnProfileSubItem2.Size = new Size(229, 48);
            btnProfileSubItem2.TabIndex = 1;
            btnProfileSubItem2.Text = "Créer";
            btnProfileSubItem2.TextAlign = ContentAlignment.MiddleLeft;
            btnProfileSubItem2.UseVisualStyleBackColor = false;
            btnProfileSubItem2.Click += btnProfileSubItem2_Click;
            // 
            // btnProfileSubItem1
            // 
            btnProfileSubItem1.BackColor = Color.FromArgb(45, 49, 56);
            btnProfileSubItem1.Dock = DockStyle.Top;
            btnProfileSubItem1.FlatAppearance.BorderSize = 0;
            btnProfileSubItem1.FlatStyle = FlatStyle.Flat;
            btnProfileSubItem1.Font = new Font("Segoe UI", 9F);
            btnProfileSubItem1.ForeColor = Color.White;
            btnProfileSubItem1.Location = new Point(0, 0);
            btnProfileSubItem1.Margin = new Padding(3, 4, 3, 4);
            btnProfileSubItem1.Name = "btnProfileSubItem1";
            btnProfileSubItem1.Padding = new Padding(40, 0, 0, 0);
            btnProfileSubItem1.Size = new Size(229, 48);
            btnProfileSubItem1.TabIndex = 0;
            btnProfileSubItem1.Text = "Lister";
            btnProfileSubItem1.TextAlign = ContentAlignment.MiddleLeft;
            btnProfileSubItem1.UseVisualStyleBackColor = false;
            btnProfileSubItem1.Click += btnProfileSubItem1_Click;
            // 
            // btnItem2
            // 
            btnItem2.BackColor = Color.FromArgb(33, 37, 43);
            btnItem2.Dock = DockStyle.Top;
            btnItem2.FlatAppearance.BorderSize = 0;
            btnItem2.FlatStyle = FlatStyle.Flat;
            btnItem2.Font = new Font("Segoe UI", 10F);
            btnItem2.ForeColor = Color.White;
            btnItem2.Location = new Point(0, 128);
            btnItem2.Margin = new Padding(3, 4, 3, 4);
            btnItem2.Name = "btnItem2";
            btnItem2.Padding = new Padding(14, 0, 0, 0);
            btnItem2.Size = new Size(229, 64);
            btnItem2.TabIndex = 2;
            btnItem2.Text = "👤  Utilisateurs";
            btnItem2.TextAlign = ContentAlignment.MiddleLeft;
            btnItem2.UseVisualStyleBackColor = false;
            btnItem2.Click += btnItem2_Click;
            // 
            // btnItem1
            // 
            btnItem1.BackColor = Color.FromArgb(33, 37, 43);
            btnItem1.Dock = DockStyle.Top;
            btnItem1.FlatAppearance.BorderSize = 0;
            btnItem1.FlatStyle = FlatStyle.Flat;
            btnItem1.Font = new Font("Segoe UI", 10F);
            btnItem1.ForeColor = Color.White;
            btnItem1.Location = new Point(0, 64);
            btnItem1.Margin = new Padding(3, 4, 3, 4);
            btnItem1.Name = "btnItem1";
            btnItem1.Padding = new Padding(14, 0, 0, 0);
            btnItem1.Size = new Size(229, 64);
            btnItem1.TabIndex = 3;
            btnItem1.Text = "🏠  Accueil";
            btnItem1.TextAlign = ContentAlignment.MiddleLeft;
            btnItem1.UseVisualStyleBackColor = false;
            btnItem1.Click += btnItem1_Click;
            // 
            // btnToggle
            // 
            btnToggle.BackColor = Color.FromArgb(45, 49, 56);
            btnToggle.Dock = DockStyle.Top;
            btnToggle.FlatAppearance.BorderSize = 0;
            btnToggle.FlatStyle = FlatStyle.Flat;
            btnToggle.Font = new Font("Segoe UI", 11F);
            btnToggle.ForeColor = Color.White;
            btnToggle.Location = new Point(0, 0);
            btnToggle.Margin = new Padding(3, 4, 3, 4);
            btnToggle.Name = "btnToggle";
            btnToggle.Size = new Size(229, 64);
            btnToggle.TabIndex = 4;
            btnToggle.Text = "◀";
            btnToggle.UseVisualStyleBackColor = false;
            btnToggle.Click += btnToggle_Click;
            // 
            // panelContent
            // 
            panelContent.BackColor = Color.WhiteSmoke;
            panelContent.Dock = DockStyle.Fill;
            panelContent.Location = new Point(229, 0);
            panelContent.Margin = new Padding(3, 4, 3, 4);
            panelContent.Name = "panelContent";
            panelContent.Size = new Size(914, 867);
            panelContent.TabIndex = 0;
            // 
            // timerMenu
            // 
            timerMenu.Interval = 15;
            timerMenu.Tick += timerMenu_Tick;
            // 
            // timerSubMenu
            // 
            timerSubMenu.Interval = 15;
            timerSubMenu.Tick += timerSubMenu_Tick;
            // 
            // timerReservationSubMenu
            // 
            timerReservationSubMenu.Interval = 15;
            timerReservationSubMenu.Tick += timerReservationSubMenu_Tick;
            // 
            // FormMenu
            // 
            AutoScaleDimensions = new SizeF(8F, 20F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(1143, 867);
            Controls.Add(panelContent);
            Controls.Add(panelMenu);
            Margin = new Padding(3, 4, 3, 4);
            Name = "FormMenu";
            StartPosition = FormStartPosition.CenterScreen;
            Text = "Resa'Chev";
            Load += Form1_Load;
            panelMenu.ResumeLayout(false);
            panelReservationSubMenu.ResumeLayout(false);
            panelProfileSubMenuUtil.ResumeLayout(false);
            ResumeLayout(false);
        }
    }
}