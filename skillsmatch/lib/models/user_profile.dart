class UserProfile {
  String ime;
  String priimek;
  String opis;
  String lokacija;
  String razpolozljivost;
  List<Skill> vescine;

  UserProfile({
    required this.ime,
    required this.priimek,
    required this.opis,
    required this.lokacija,
    required this.razpolozljivost,
    required this.vescine,
  });
}

class Skill {
  String naziv;
  String nivoZnanja;
  String tip;

  Skill({required this.naziv, required this.nivoZnanja, required this.tip});
}
