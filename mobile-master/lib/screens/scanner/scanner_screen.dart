import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:resachev/models/reservation.dart';
import 'package:resachev/services/api/gestionReservation/reservation_api.dart';
import 'package:resachev/theme/app_theme.dart';

// Ecran de lecture de QR code.
//
// US 2.3 : le QR code porte l'identifiant de la réservation. Il est résolu
// auprès de l'API, contrôlé (fenêtre de validité et présence déjà validée)
// puis la présence est transmise au serveur.

/// Résultat d'un scan, affiché dans le bandeau inférieur.
class _ResultatScan {
  final bool valide;
  final String message;
  final Reservation? reservation;

  const _ResultatScan({
    required this.valide,
    required this.message,
    this.reservation,
  });
}

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  // Contrôleur de la caméra
  final MobileScannerController _controller = MobileScannerController(
    returnImage: true,
  );

  Uint8List? _qrImage;
  bool _hasScanned = false;
  bool _traitement = false;
  _ResultatScan? _resultat;

  // Empêche crash si pas de webCam
  bool get _isScannerSupported {
    return defaultTargetPlatform == TargetPlatform.android;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatHeure(DateTime? heure) {
    if (heure == null) return '--:--';
    final h = heure.hour.toString().padLeft(2, '0');
    final m = heure.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'date inconnue';
    final j = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$j/$m/${date.year}';
  }

  void _afficher(_ResultatScan resultat) {
    if (!mounted) return;
    setState(() {
      _resultat = resultat;
      _traitement = false;
    });
  }

  /// Lecture d'un QR code (une seule fois par scan).
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_hasScanned) return;

    final barcode = capture.barcodes.firstOrNull;
    final String? value = barcode?.rawValue?.trim();
    if (value == null || value.isEmpty) return;

    final Uint8List? qrImage = capture.image;

    setState(() {
      _hasScanned = true;
      _qrImage = qrImage;
      _traitement = true;
      _resultat = null;
    });
    // Arrête la caméra après la lecture du QR code
    await _controller.stop();

    // Règle métier 1 : le contenu doit identifier une réservation.
    if (int.tryParse(value) == null) {
      _afficher(const _ResultatScan(
        valide: false,
        message: 'Ce QR code ne contient pas un identifiant de réservation.',
      ));
      return;
    }

    // Appel de l'API pour récupérer les infos utilisateur
    final Reservation? reservation =
        await ReservationApi.infoReservationParId(value);
    if (!mounted) return;

    if (reservation == null) {
      _afficher(const _ResultatScan(
        valide: false,
        message: 'Réservation ou utilisateur introuvable.',
      ));
      return;
    }

    // Règle métier 3 : fenêtre de validité (30 min avant, 45 min après).
    final String? motif = reservation.verifierValiditeQr(DateTime.now());
    if (motif != null) {
      _afficher(_ResultatScan(
        valide: false,
        message: motif,
        reservation: reservation,
      ));
      return;
    }

    // Règle métier 1 : la présence est transmise au serveur.
    final Map<String, dynamic> validation =
        await ReservationApi.validerPresence(value);
    if (!mounted) return;

    if (validation['ok'] == true) {
      _afficher(_ResultatScan(
        valide: true,
        message: 'Présence validée à ${_formatHeure(DateTime.now())}.',
        reservation: reservation.copyWith(
          validationpresence: true,
          presenceValideeLe: DateTime.now(),
        ),
      ));
      return;
    }

    _afficher(_ResultatScan(
      valide: false,
      message:
          validation['message']?.toString() ?? 'Validation de présence impossible.',
      reservation: reservation,
    ));
  }

  // Redémarrer le scan
  void _restartScan() {
    if (!_isScannerSupported) {
      return;
    }

    setState(() {
      _hasScanned = false;
      _traitement = false;
      _resultat = null;
      _qrImage = null;
    });
    _controller.start();
  }

  /// Bandeau de résultat : vert si la présence est validée, orange sinon.
  Widget _buildResultat() {
    final _ResultatScan? resultat = _resultat;
    if (resultat == null && _qrImage == null) {
      return Text(
        'Scannez le QR code présenté par le client.',
        style: TextStyle(color: AppColors.texte),
      );
    }

    final bool valide = resultat?.valide ?? false;
    final Color accent =
        valide ? AppColors.enregistreTexte : AppColors.nonEnregistreTexte;
    final Color fond =
        valide ? AppColors.enregistreFond : AppColors.nonEnregistreFond;
    final Reservation? reservation = resultat?.reservation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                valide ? Icons.check_circle : Icons.error_outline,
                color: accent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  valide ? 'Présence validée' : 'QR code non valide',
                  style: TextStyle(
                    color: accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (reservation != null) ...<Widget>[
            Text(
              reservation.nomClient.isEmpty
                  ? 'Client non renseigné'
                  : reservation.nomClient,
              style: TextStyle(
                color: AppColors.texte,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${reservation.prestation?.trim().isNotEmpty == true ? reservation.prestation!.trim() : 'Prestation non précisée'}'
              ' · ${_formatDate(reservation.datedebut)} à ${_formatHeure(reservation.heuredebut)}',
              style: TextStyle(
                color: AppColors.texte,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            resultat?.message ?? 'Réservation identifiée.',
            style: TextStyle(
              color: AppColors.texte,
              fontSize: 13.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppColors.suivreTheme(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Lecture QR code')),
      body: !_isScannerSupported
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'La lecture QR n\'est pas disponible sur cette plateforme.\n'
                  'Utilisez un smartphone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.texte),
                ),
              ),
            )
          : Column(
              children: <Widget>[
                Expanded(
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppColors.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (_qrImage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Image.memory(
                            _qrImage!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                      if (_traitement)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: <Widget>[
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Vérification en cours...',
                                style: TextStyle(color: AppColors.texte),
                              ),
                            ],
                          ),
                        )
                      else
                        _buildResultat(),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(180, 44),
                          ),
                          onPressed: _restartScan,
                          child: const Text('Scanner à nouveau'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
