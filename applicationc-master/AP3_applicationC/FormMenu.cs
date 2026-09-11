using AP3_applicationC.Entities;
using AP3_applicationC.Modele;
using System;
using System.Drawing;
using System.Windows.Forms;

namespace AP3_applicationC
{
    public partial class FormMenu : Form
    {
        // menus et animation
        private bool _menuExpanded = true;
        private const int ExpandedWidth = 200;
        private const int CollapsedWidth = 60;
        private const int AnimationStep = 12;

        // Sous-menus et animation
        private bool _profileSubmenuExpanded = false;
        private bool _reservationSubmenuExpanded = false;
        private const int SubmenuExpandedHeight = 144; // 3 items * 48
        private const int SubmenuCollapsedHeight = 0;
        private const int SubmenuAnimationStep = 8;

        // paramètres de la plateforme
        private string nomPlateforme = "";
        public int heureOuverture = 9;
        public int heureFermeture = 17;
        public FormMenu()
        {
            InitializeComponent();
            ConfigureMenuInitialState();
            // Conserver la barre de titre et dessiner un contour blanc à l'intérieur du client
            this.DoubleBuffered = true;
            this.Paint += FormMenu_Paint;
            this.Resize += (s, e) => this.Invalidate();

            // récupération des infos de la table PARAMETRAGE   
            List<Parametrage> listParam = ConnexionBD.listeParametres();
            nomPlateforme = listParam[0].Valeurparam.ToString();
            this.Text = $"Administration de {nomPlateforme}";
        }

        public Form activeForm = null;

        

        /// <summary>
        /// cette méthode permet d'ouvrir un formulaire enfant dans le panelContent
        /// </summary>
        /// <param name="formEnfant"></param>
        public void openChildForm(Form formEnfant)
        {
            if (activeForm != null)
                activeForm.Close();

            activeForm = formEnfant;
            formEnfant.TopLevel = false;
            formEnfant.FormBorderStyle = FormBorderStyle.None;
            formEnfant.Dock = DockStyle.Fill;
            panelContent.Controls.Add(formEnfant);
            panelContent.Tag = formEnfant;
            formEnfant.BringToFront();
            formEnfant.Show();
        }

        private void ConfigureMenuInitialState()
        {
            // Assure l'état initial (ouvert)
            panelMenu.Width = ExpandedWidth;
            UpdateButtonsForState(_menuExpanded);

            // Submenu initial state : fermé et masqué (hauteur = 0)
            panelProfileSubMenuUtil.Height = SubmenuCollapsedHeight;
            panelProfileSubMenuUtil.Visible = false;
            _profileSubmenuExpanded = false;

            // Réservations sous-menu
            if (panelReservationSubMenu != null)
            {
                panelReservationSubMenu.Height = SubmenuCollapsedHeight;
                panelReservationSubMenu.Visible = false;
            }
            _reservationSubmenuExpanded = false;

            btnToggle.Text = "◀"; // permet de fermer
        }

        private void btnToggle_Click(object sender, EventArgs e)
        {
            // Inverse l'état et lance l'animation
            _menuExpanded = !_menuExpanded;

            // Si on ferme le menu principal, on ferme aussi le sous-menu immédiatement
            if (!_menuExpanded)
            {
                _profileSubmenuExpanded = false;
                panelProfileSubMenuUtil.Height = SubmenuCollapsedHeight;
                panelProfileSubMenuUtil.Visible = false;
                // fermer sous-menu réservations si présent
                _reservationSubmenuExpanded = false;
                if (panelReservationSubMenu != null)
                {
                    panelReservationSubMenu.Height = SubmenuCollapsedHeight;
                    panelReservationSubMenu.Visible = false;
                }
            }

            timerMenu.Start();
        }

        private void timerMenu_Tick(object sender, EventArgs e)
        {
            if (_menuExpanded)
            {
                // Ouverture : augmenter la largeur jusqu'à ExpandedWidth
                if (panelMenu.Width < ExpandedWidth)
                {
                    panelMenu.Width = Math.Min(ExpandedWidth, panelMenu.Width + AnimationStep);
                }
                else
                {
                    timerMenu.Stop();
                    UpdateButtonsForState(true);
                    btnToggle.Text = "◀";
                }
            }
            else
            {
                // Fermeture : diminuer la largeur jusqu'à CollapsedWidth
                if (panelMenu.Width > CollapsedWidth)
                {
                    panelMenu.Width = Math.Max(CollapsedWidth, panelMenu.Width - AnimationStep);
                }
                else
                {
                    timerMenu.Stop();
                    UpdateButtonsForState(false);
                    btnToggle.Text = "▶";

                    // Cacher sous-menu si menu réduit
                    _profileSubmenuExpanded = false;
                    panelProfileSubMenuUtil.Height = SubmenuCollapsedHeight;
                    panelProfileSubMenuUtil.Visible = false;
                    _reservationSubmenuExpanded = false;
                    if (panelReservationSubMenu != null)
                    {
                        panelReservationSubMenu.Height = SubmenuCollapsedHeight;
                        panelReservationSubMenu.Visible = false;
                    }
                }
            }
        }

        private void timerSubMenu_Tick(object sender, EventArgs e)
        {
            if (_profileSubmenuExpanded)
            {
                // Ouvrir le sous-menu (augmenter la hauteur)
                if (panelProfileSubMenuUtil.Height < SubmenuExpandedHeight)
                {
                    panelProfileSubMenuUtil.Height = Math.Min(SubmenuExpandedHeight, panelProfileSubMenuUtil.Height + SubmenuAnimationStep);
                }
                else
                {
                    timerSubMenu.Stop();
                    panelProfileSubMenuUtil.Visible = true;
                }
            }
            else
            {
                // Fermer le sous-menu (diminuer la hauteur)
                if (panelProfileSubMenuUtil.Height > SubmenuCollapsedHeight)
                {
                    panelProfileSubMenuUtil.Height = Math.Max(SubmenuCollapsedHeight, panelProfileSubMenuUtil.Height - SubmenuAnimationStep);
                }
                else
                {
                    timerSubMenu.Stop();
                    panelProfileSubMenuUtil.Visible = false;
                }
            }
        }

        private void timerReservationSubMenu_Tick(object sender, EventArgs e)
        {
            if (panelReservationSubMenu == null) return;

            if (_reservationSubmenuExpanded)
            {
                if (panelReservationSubMenu.Height < SubmenuExpandedHeight)
                {
                    panelReservationSubMenu.Height = Math.Min(SubmenuExpandedHeight, panelReservationSubMenu.Height + SubmenuAnimationStep);
                }
                else
                {
                    timerReservationSubMenu.Stop();
                    panelReservationSubMenu.Visible = true;
                }
            }
            else
            {
                if (panelReservationSubMenu.Height > SubmenuCollapsedHeight)
                {
                    panelReservationSubMenu.Height = Math.Max(SubmenuCollapsedHeight, panelReservationSubMenu.Height - SubmenuAnimationStep);
                }
                else
                {
                    timerReservationSubMenu.Stop();
                    panelReservationSubMenu.Visible = false;
                }
            }
        }

        private void UpdateButtonsForState(bool expanded)
        {
            // Quand expanded = true, affiche "emoji + label".
            // Quand expanded = false, n'affiche que l'emoji.
            if (expanded)
            {
                btnItem1.Text = "🏠  Accueil";
                btnItem2.Text = "👤  Utilisateurs";
                btnItem3.Text = "📅  Réservations";
                btnItem4.Text = "🔒  Quitter";

                // Alignement, style et alternance des couleurs quand développé
                int idx = 0;
                foreach (Control c in panelMenu.Controls)
                {
                    if (c is Button b && b.Name.StartsWith("btnItem"))
                    {
                        b.TextAlign = ContentAlignment.MiddleLeft;
                        b.Padding = new Padding(12, 0, 0, 0);

                        // Alterner les couleurs : indices imppairs => fond blanc texte noir, pairs => fond noir texte blanc
                        if (idx % 2 == 1)
                        {
                            b.BackColor = Color.White;
                            b.ForeColor = Color.Black;
                        }
                        else
                        {
                            b.BackColor = Color.Black;
                            b.ForeColor = Color.White;
                        }

                        idx++;
                    }
                }

                // Ré-afficher le sous-menu s'il est ouvert
                if (_profileSubmenuExpanded)
                {
                    panelProfileSubMenuUtil.Visible = true;
                }
                if (_reservationSubmenuExpanded && panelReservationSubMenu != null)
                {
                    panelReservationSubMenu.Visible = true;
                }
            }
            else
            {
                btnItem1.Text = "🏠";
                btnItem2.Text = "👤";
                btnItem3.Text = "📅";
                btnItem4.Text = "🔒";

                // Alignement et alternance des couleurs quand réduit
                int idx2 = 0;
                foreach (Control c in panelMenu.Controls)
                {
                    if (c is Button b && b.Name.StartsWith("btnItem"))
                    {
                        b.TextAlign = ContentAlignment.MiddleCenter;
                        b.Padding = new Padding(0);

                        if (idx2 % 2 == 0)
                        {
                            b.BackColor = Color.White;
                            b.ForeColor = Color.Black;
                        }
                        else
                        {
                            b.BackColor = Color.Black;
                            b.ForeColor = Color.White;
                        }

                        idx2++;
                    }
                }

                // Masquer le sous-menu quand le menu principal est réduit
                panelProfileSubMenuUtil.Visible = false;
                panelProfileSubMenuUtil.Height = SubmenuCollapsedHeight;
                _profileSubmenuExpanded = false;
                if (panelReservationSubMenu != null)
                {
                    panelReservationSubMenu.Visible = false;
                    panelReservationSubMenu.Height = SubmenuCollapsedHeight;
                }
                _reservationSubmenuExpanded = false;
            }
        }

        // Exemples d'actions pour les items
        private void btnItem1_Click(object sender, EventArgs e)
        {
            ShowContent("Bienvenue dans l'espace d'administration de "+nomPlateforme);
        }

        private void btnItem2_Click(object sender, EventArgs e)
        {
            // Si le menu principal est fermé, l'ouvrir d'abord
            if (!_menuExpanded)
            {
                _menuExpanded = true;
                timerMenu.Start();
                return;
            }

            // Basculer le sous-menu Profil
            _profileSubmenuExpanded = !_profileSubmenuExpanded;
            // Rendre visible immédiatement pour permettre l'animation (si on ouvre)
            if (_profileSubmenuExpanded)
                panelProfileSubMenuUtil.Visible = true;

            timerSubMenu.Start();
        }

        private void btnItem3_Click(object sender, EventArgs e)
        {
            // Si le menu principal est fermé, l'ouvrir d'abord
            if (!_menuExpanded)
            {
                _menuExpanded = true;
                timerMenu.Start();
                return;
            }

            // Basculer le sous-menu Réservations
            _reservationSubmenuExpanded = !_reservationSubmenuExpanded;
            if (_reservationSubmenuExpanded && panelReservationSubMenu != null)
                panelReservationSubMenu.Visible = true;

            timerReservationSubMenu.Start();
        }

        private void btnItem4_Click(object sender, EventArgs e)
        {
            Application.Exit(); // Ferme l'application
        }

        // Sous-menu des utilisateurs
        private void btnProfileSubItem1_Click(object sender, EventArgs e)
        {
            openChildForm(new FormListerUtil());
        }

        private void btnProfileSubItem2_Click(object sender, EventArgs e)
        {
            openChildForm(new FormCreerUtil());
        }

        private void btnProfileSubItem3_Click(object sender, EventArgs e)
        {
            ShowContent("Utilisateurs - Modifier/supprimer");
        }

        // Réservations submenu handlers
        private void btnReservationSubItem1_Click(object sender, EventArgs e)
        {
            openChildForm(new FormSuivreResa());
        }

        private void btnReservationSubItem2_Click(object sender, EventArgs e)
        {
            openChildForm(new FormCreerResa());
        }

        private void ShowContent(string name)
        {
            panelContent.Controls.Clear();
            var lbl = new Label
            {
                Text = $"{name}",
                Dock = DockStyle.Fill,
                TextAlign = ContentAlignment.MiddleCenter,
                Font = new Font("Segoe UI", 16, FontStyle.Bold)
            };
            panelContent.Controls.Add(lbl);
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            btnItem1_Click(sender, e);
        }

        private void FormMenu_Paint(object? sender, PaintEventArgs e)
        {
            // Dessine un contour blanc autour de la fenêtre
            using (var pen = new Pen(Color.White, 4))
            {
                pen.Alignment = System.Drawing.Drawing2D.PenAlignment.Inset;
                var rect = this.ClientRectangle;
                rect.Inflate(-1, -1);
                e.Graphics.DrawRectangle(pen, rect);
            }
        }
    }
}
