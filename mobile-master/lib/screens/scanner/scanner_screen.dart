import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:resachev/services/api/gestionReservation/reservation_api.dart';

// Ecran de lecture de QR code
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
  // Résultat du scan 
  String? _qrValue;
  Uint8List? _qrImage;  
  bool _hasScanned = false;  

  //Empêche crash si pas de webCam
  bool get _isScannerSupported {
      return defaultTargetPlatform == TargetPlatform.android;
  }   

  @override  
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  //Méthode permettant la lecture du QR code
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_hasScanned) {
      return;
    }
    //Récupération de la valeur du QR code scanné
    final barcode = capture.barcodes.firstOrNull;        
    final value = barcode?.rawValue;
   
    //gestion si Qr code vide ou non lu
    if (value == null || value.isEmpty) {
      return;
    }

     final Uint8List? qrImage = capture.image;

    setState(() {
      _hasScanned = true;
      _qrValue = value;    
      _qrImage = qrImage;  
    });
    // Arrête la caméra après la lecture du QR code
    await _controller.stop();
  
    //Appel de l'API pour récupérer les infos utilisateurs
    final reservation = await ReservationApi.infoReservationParId(value);

    // Vérifie que l'écran est toujours ouvert après l'appel asynchrone (Bonne pratique)
    if (!mounted) {
      return;
    }


   if (reservation == null) {
      setState(() {
        _qrValue = 'Réservation ou utilisateur introuvable.';
      });
      return;
    }

    // Récupère les informations de l'utilisateur 
    final utilisateur = reservation.utilisateur;
    final nom = utilisateur?.nom ?? '';
    final prenom = utilisateur?.prenom ?? '';

    setState(() {
      // Affiche le nom complet de l'utilisateur si ces informations sont disponibles.
      _qrValue = nom.isEmpty && prenom.isEmpty
          ? 'Utilisateur non renseigné.'
          : 'Nom : $nom, Prénom : $prenom';
    });
  } 
  
  // Redémarrer le scan 
  void _restartScan() {
    if (!_isScannerSupported) {
      return;
    }

    setState(() {
      _hasScanned = false;
      _qrValue = null;
      _qrImage = null;
    });
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecture QR code'),
      ),
      body: !_isScannerSupported
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'La lecture QR n\'est pas disponible sur cette plateforme.\nUtilisez un smartphone.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.black87,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [   
                      if (_qrImage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Image.memory(
                          _qrImage!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                      ),                  
                      Text(
                        _qrValue == null
                            ? 'Scannez un QR code...'
                            : 'Valeurs lues: $_qrValue',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _restartScan,
                          child: const Text('Scanner a nouveau'),
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
