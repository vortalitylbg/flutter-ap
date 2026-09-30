import 'package:flutter/material.dart';
import 'package:resachev/theme/app_theme.dart';

// US 1.1.3 : visuel de l'organisation. Le logo est dessiné à partir de la
// palette de la page de connexion (dégradé bleu ardoise + blanc), afin qu'il
// reste cohérent avec le reste de la charte.

/// Logo SoundBox Studio : pastille en dégradé contenant l'icône d'égaliseur
/// graphique, décliné en plusieurs tailles.
class LogoSoundBox extends StatelessWidget {
  /// Diamètre de la pastille.
  final double taille;

  /// Affiche le nom du studio à droite du logo.
  final bool avecNom;

  /// Met le texte du nom en blanc, pour une utilisation sur aplat foncé.
  final bool texteBlanc;

  const LogoSoundBox({
    super.key,
    this.taille = 72,
    this.avecNom = false,
    this.texteBlanc = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color couleurNom = texteBlanc ? AppColors.blanc : AppColors.principal;

    final Widget pastille = Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.degradePrincipal,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.principal.withValues(alpha: 0.28),
            blurRadius: taille * 0.22,
            offset: Offset(0, taille * 0.08),
          ),
        ],
      ),
      child: Icon(
        Icons.graphic_eq,
        size: taille * 0.52,
        color: AppColors.blanc,
      ),
    );

    if (!avecNom) return pastille;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        pastille,
        SizedBox(width: taille * 0.22),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'SoundBox',
                style: TextStyle(
                  color: couleurNom,
                  fontSize: taille * 0.36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              Text(
                'STUDIO',
                style: TextStyle(
                  color: texteBlanc ? AppColors.principalVoile : AppColors.secondaire,
                  fontSize: taille * 0.20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
