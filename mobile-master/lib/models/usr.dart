//dataclass User

class User {
  final int idutilisateur;
  final String? nom;
  final String? prenom;
  final String? email;

  User({
    required this.idutilisateur,
    required this.nom,
    required this.prenom,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return User(
      idutilisateur: parseId(json['idutilisateur']),
      nom: json['nom']?.toString(),
      prenom: json['prenom']?.toString(),
      email: json['email']?.toString(),
    );
  }
}