import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

enum TipoPeca { peao, torre, cavalo, bispo, rainha, rei }
enum CorPeca { branco, preto }

enum ModoSelecao {
  nenhum,
  protecaoTemporaria,
  protecaoPermanenteMenor,
  protecaoPeaoPermanente,
  paralisia2Rodadas,
  corvee,
  ferroviaOrigem,
  ferroviaDestino,
  suborno,
  canhoneiras,
  protetoradoFantoche,
  conferenciaPartilha,
  decretoPromocao,
  drenarPiche,
  prospeccaoCarvao,
  aprimorarCarvao,
  sabotagemTerreno,
  corridaOuro,
  abrirPicheInimigo,
}

enum TipoTerrenoEspecial {
  pocoDePiche,
  minaCarvao,
  fundicaoAco,
  minaOuro,
}

extension TipoTerrenoEspecialX on TipoTerrenoEspecial {
  int get renda {
    switch (this) {
      case TipoTerrenoEspecial.pocoDePiche:
        return -3;
      case TipoTerrenoEspecial.minaCarvao:
        return 4;
      case TipoTerrenoEspecial.fundicaoAco:
        return 8;
      case TipoTerrenoEspecial.minaOuro:
        return 14;
    }
  }

  String get nome {
    switch (this) {
      case TipoTerrenoEspecial.pocoDePiche:
        return 'Poço de Piche';
      case TipoTerrenoEspecial.minaCarvao:
        return 'Mina de Carvão';
      case TipoTerrenoEspecial.fundicaoAco:
        return 'Fundição de Aço';
      case TipoTerrenoEspecial.minaOuro:
        return 'Mina de Ouro';
    }
  }

  String get textoRenda {
    final int r = renda;
    return r >= 0 ? '+£$r' : '-£${r.abs()}';
  }
}

/// Paleta Envelhecida (Século XIX): Nogueira Gasta, Pergaminho Manchado, Latão Oxidado e Lacre de Cera
class EstiloImperial {
  static const Color fundoSala = Color(0xFF0C0704);
  static const Color mognoEscuro = Color(0xFF1B0F08);
  static const Color mognoMedio = Color(0xFF2B180D);
  static const Color feltroVerde = Color(0xFF13241B);
  static const Color feltroVerdeEscuro = Color(0xFF0B1610);

  static const Color pergaminhoClaro = Color(0xFFDCC698);
  static const Color pergaminhoMedio = Color(0xFFC4A974);
  static const Color pergaminhoEscuro = Color(0xFF9E8150);

  static const Color casaClara = Color(0xFFD2BA8A);
  static const Color casaEscura = Color(0xFF4F2B17);

  static const Color lataoOuro = Color(0xFF9C7628);
  static const Color lataoClaro = Color(0xFFC49E48);
  static const Color lataoEscuro = Color(0xFF5C4214);

  static const Color carmesimImperial = Color(0xFF6E1418);
  static const Color azulPrussia = Color(0xFF17344A);
  static const Color verdeTesouro = Color(0xFF163825);
  static const Color tintaSepia = Color(0xFF1E1108);

  static const List<String> _fallbackSerif = [
    'Times New Roman',
    'Palatino',
    'Baskerville',
    'serif',
  ];

  static TextStyle titulo({
    double size = 18,
    Color color = pergaminhoClaro,
    FontWeight weight = FontWeight.bold,
    double letterSpacing = 1.3,
  }) {
    return TextStyle(
      fontFamily: 'Georgia',
      fontFamilyFallback: _fallbackSerif,
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle corpo({
    double size = 13,
    Color color = pergaminhoClaro,
    FontWeight weight = FontWeight.normal,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return TextStyle(
      fontFamily: 'Georgia',
      fontFamilyFallback: _fallbackSerif,
      fontSize: size,
      color: color,
      fontWeight: weight,
      fontStyle: fontStyle,
    );
  }
}

extension CorPecaX on CorPeca {
  CorPeca get oposta => this == CorPeca.branco ? CorPeca.preto : CorPeca.branco;
  String get nome => this == CorPeca.branco ? 'Branco' : 'Preto';
}

extension TipoPecaX on TipoPeca {
  String get nome {
    switch (this) {
      case TipoPeca.peao:
        return 'Peão';
      case TipoPeca.torre:
        return 'Torre';
      case TipoPeca.cavalo:
        return 'Cavalo';
      case TipoPeca.bispo:
        return 'Bispo';
      case TipoPeca.rainha:
        return 'Rainha';
      case TipoPeca.rei:
        return 'Rei';
    }
  }

  int get custoBase {
    switch (this) {
      case TipoPeca.peao:
        return 20;
      case TipoPeca.cavalo:
        return 50;
      case TipoPeca.bispo:
        return 50;
      case TipoPeca.torre:
        return 80;
      case TipoPeca.rainha:
        return 150;
      case TipoPeca.rei:
        return 0;
    }
  }
}

Color corRaridade(String raridade) {
  switch (raridade) {
    case 'Rara':
      return EstiloImperial.azulPrussia;
    case 'Épica':
      return EstiloImperial.carmesimImperial;
    case 'Comum':
    default:
      return EstiloImperial.lataoEscuro;
  }
}

// ============================================================================
// COMPONENTES DE TEXTURA E ESTÉTICA ENVELHECIDA (PERGAMINHO, MADEIRA, LACRE)
// ============================================================================

class PergaminhoEnvelhecido extends StatelessWidget {
  final Widget child;
  final int seed;
  final Color corBorda;
  final double larguraBorda;
  final EdgeInsetsGeometry padding;
  final bool destacado;

  const PergaminhoEnvelhecido({
    super.key,
    required this.child,
    this.seed = 42,
    this.corBorda = EstiloImperial.lataoEscuro,
    this.larguraBorda = 1.6,
    this.padding = const EdgeInsets.all(8),
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: corBorda, width: larguraBorda),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.68),
            blurRadius: destacado ? 10 : 5,
            offset: const Offset(1.5, 3),
          ),
          if (destacado)
            BoxShadow(
              color: EstiloImperial.lataoClaro.withOpacity(0.45),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: CustomPaint(
          painter: _PergaminhoPainter(seed: seed, destacado: destacado),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PergaminhoPainter extends CustomPainter {
  final int seed;
  final bool destacado;

  _PergaminhoPainter({required this.seed, required this.destacado});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    final Paint basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: destacado
            ? const [
                Color(0xFFE7D3A6),
                Color(0xFFD2B782),
                Color(0xFFB8985E),
              ]
            : const [
                Color(0xFFD9C293),
                Color(0xFFC5A974),
                Color(0xFFA98B56),
              ],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    final Random rng = Random(seed);
    for (int i = 0; i < 6; i++) {
      final double cx = rng.nextDouble() * size.width;
      final double cy = rng.nextDouble() * size.height;
      final double r = (size.shortestSide * (0.18 + rng.nextDouble() * 0.25));
      final Paint mancha = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF6B481E).withOpacity(0.11 + rng.nextDouble() * 0.08),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, mancha);
    }

    final Paint sarda = Paint()..color = const Color(0xFF4A2E12).withOpacity(0.18);
    for (int i = 0; i < 24; i++) {
      final double px = rng.nextDouble() * size.width;
      final double py = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(px, py), 0.6 + rng.nextDouble() * 0.9, sarda);
    }

    final Paint vinheta = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.92,
        colors: [
          Colors.transparent,
          const Color(0xFF2B180A).withOpacity(0.32),
        ],
        stops: const [0.58, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vinheta);

    if (size.width > 36 && size.height > 36) {
      final Paint linhaGravura = Paint()
        ..color = const Color(0xFF4B2E14).withOpacity(0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.85;
      final Rect interna = rect.deflate(3.5);
      canvas.drawRect(interna, linhaGravura);

      final Paint canto = Paint()
        ..color = const Color(0xFF4B2E14).withOpacity(0.55)
        ..style = PaintingStyle.fill;
      for (final pt in [
        interna.topLeft,
        interna.topRight,
        interna.bottomLeft,
        interna.bottomRight,
      ]) {
        canvas.drawRect(Rect.fromCenter(center: pt, width: 3.0, height: 3.0), canto);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PergaminhoPainter oldDelegate) {
    return oldDelegate.seed != seed || oldDelegate.destacado != destacado;
  }
}

class MadeiraEnvelhecida extends StatelessWidget {
  final Widget child;
  final Color corBorda;
  final double larguraBorda;
  final EdgeInsetsGeometry padding;
  final int seed;

  const MadeiraEnvelhecida({
    super.key,
    required this.child,
    this.corBorda = EstiloImperial.lataoOuro,
    this.larguraBorda = 1.8,
    this.padding = EdgeInsets.zero,
    this.seed = 7,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: corBorda, width: larguraBorda),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.78),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _MadeiraEnvelhecidaPainter(seed: seed),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class _MadeiraEnvelhecidaPainter extends CustomPainter {
  final int seed;

  _MadeiraEnvelhecidaPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF23130A),
            Color(0xFF170C06),
            Color(0xFF211108),
          ],
        ).createShader(rect),
    );

    final Random rng = Random(seed);
    final Paint veio = Paint()
      ..color = const Color(0xFF0A0502).withOpacity(0.35)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      final double y = (size.height / 8) * i + rng.nextDouble() * 4;
      final Path p = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(
          size.width * 0.5,
          y + (rng.nextDouble() - 0.5) * 4,
          size.width,
          y,
        );
      canvas.drawPath(p, veio);
    }

    if (size.width > 40 && size.height > 24) {
      final Paint rebiteSombra = Paint()..color = Colors.black.withOpacity(0.7);
      final Paint rebite = Paint()..color = EstiloImperial.lataoOuro;
      const double inset = 4.5;
      final offsets = [
        const Offset(inset, inset),
        Offset(size.width - inset, inset),
        Offset(inset, size.height - inset),
        Offset(size.width - inset, size.height - inset),
      ];
      for (final o in offsets) {
        canvas.drawCircle(o + const Offset(0.5, 0.7), 1.7, rebiteSombra);
        canvas.drawCircle(o, 1.5, rebite);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MadeiraEnvelhecidaPainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}

class SeloCeraBadge extends StatelessWidget {
  final String texto;
  final Color corCera;
  final Color corTexto;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const SeloCeraBadge({
    super.key,
    required this.texto,
    required this.corCera,
    this.corTexto = EstiloImperial.pergaminhoClaro,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SeloCeraPainter(corCera: corCera),
      child: Padding(
        padding: padding,
        child: Text(
          texto,
          style: EstiloImperial.titulo(
            size: fontSize,
            color: corTexto,
            letterSpacing: 0.7,
          ),
        ),
      ),
    );
  }
}

class _SeloCeraPainter extends CustomPainter {
  final Color corCera;

  _SeloCeraPainter({required this.corCera});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect base = RRect.fromRectAndRadius(rect, const Radius.circular(3));

    canvas.drawRRect(
      base.shift(const Offset(0.8, 1.4)),
      Paint()..color = Colors.black.withOpacity(0.65),
    );

    canvas.drawRRect(
      base,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(corCera, Colors.white, 0.14)!,
            corCera,
            Color.lerp(corCera, Colors.black, 0.35)!,
          ],
        ).createShader(rect),
    );

    canvas.drawRRect(
      base,
      Paint()
        ..color = EstiloImperial.lataoOuro.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1.6), const Radius.circular(2)),
      Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
  }

  @override
  bool shouldRepaint(covariant _SeloCeraPainter oldDelegate) {
    return oldDelegate.corCera != corCera;
  }
}

class BotaoAntigo extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color corFundo;
  final IconData? icone;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const BotaoAntigo({
    super.key,
    required this.label,
    required this.onPressed,
    this.corFundo = EstiloImperial.carmesimImperial,
    this.icone,
    this.fontSize = 11.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
  });

  @override
  Widget build(BuildContext context) {
    final bool habilitado = onPressed != null;
    final Color fundoEfetivo =
        habilitado ? corFundo : const Color(0xFF261A13);

    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: habilitado ? 1.0 : 0.55,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(fundoEfetivo, Colors.white, 0.10)!,
                fundoEfetivo,
                Color.lerp(fundoEfetivo, Colors.black, 0.35)!,
              ],
            ),
            border: Border.all(
              color: EstiloImperial.lataoOuro,
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 4,
                offset: Offset(1, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icone != null) ...[
                Icon(icone, size: 15, color: EstiloImperial.lataoClaro),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: EstiloImperial.titulo(
                  size: fontSize,
                  color: EstiloImperial.pergaminhoClaro,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatinaTabuleiroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.96,
          colors: [
            Colors.transparent,
            const Color(0xFF1A0D05).withOpacity(0.28),
          ],
          stops: const [0.62, 1.0],
        ).createShader(rect),
    );

    final Random rng = Random(1884);
    for (int i = 0; i < 14; i++) {
      final double cx = rng.nextDouble() * size.width;
      final double cy = rng.nextDouble() * size.height;
      final double r = size.width * (0.05 + rng.nextDouble() * 0.09);
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFF2E180A).withOpacity(0.11),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      );
    }

    final Paint fissura = Paint()
      ..color = const Color(0xFF231106).withOpacity(0.16)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 9; i++) {
      final double x1 = rng.nextDouble() * size.width;
      final double y1 = rng.nextDouble() * size.height;
      final double dx = (rng.nextDouble() - 0.5) * 42;
      final double dy = (rng.nextDouble() - 0.5) * 42;
      canvas.drawLine(Offset(x1, y1), Offset(x1 + dx, y1 + dy), fissura);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BrasaoProtecaoWidget extends StatelessWidget {
  final bool permanente;

  const BrasaoProtecaoWidget({super.key, required this.permanente});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 15,
      height: 16,
      child: CustomPaint(
        painter: _BrasaoProtecaoPainter(permanente: permanente),
      ),
    );
  }
}

class _BrasaoProtecaoPainter extends CustomPainter {
  final bool permanente;

  _BrasaoProtecaoPainter({required this.permanente});

  @override
  void paint(Canvas canvas, Size size) {
    final Path escudo = Path()
      ..moveTo(size.width * 0.12, size.height * 0.10)
      ..lineTo(size.width * 0.88, size.height * 0.10)
      ..lineTo(size.width * 0.85, size.height * 0.56)
      ..quadraticBezierTo(
          size.width * 0.5, size.height * 0.96, size.width * 0.5, size.height * 0.96)
      ..quadraticBezierTo(
          size.width * 0.5, size.height * 0.96, size.width * 0.15, size.height * 0.56)
      ..close();

    canvas.drawPath(
      escudo.shift(const Offset(0.7, 1.0)),
      Paint()..color = Colors.black.withOpacity(0.7),
    );
    canvas.drawPath(
      escudo,
      Paint()
        ..color = permanente
            ? EstiloImperial.carmesimImperial
            : EstiloImperial.azulPrussia,
    );
    canvas.drawPath(
      escudo,
      Paint()
        ..color = EstiloImperial.lataoClaro
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    final Paint cruz = Paint()
      ..color = EstiloImperial.pergaminhoClaro
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.24),
      Offset(size.width * 0.5, size.height * 0.72),
      cruz,
    );
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.44),
      Offset(size.width * 0.72, size.height * 0.44),
      cruz,
    );
  }

  @override
  bool shouldRepaint(covariant _BrasaoProtecaoPainter oldDelegate) {
    return oldDelegate.permanente != permanente;
  }
}

class CorrentesParalisiaWidget extends StatelessWidget {
  const CorrentesParalisiaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CorrentesParalisiaPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _CorrentesParalisiaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint ferroSombra = Paint()
      ..color = Colors.black.withOpacity(0.75)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;

    final Paint ferro = Paint()
      ..color = const Color(0xFF7D746B)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.16, size.height * 0.20),
      Offset(size.width * 0.84, size.height * 0.80),
      ferroSombra,
    );
    canvas.drawLine(
      Offset(size.width * 0.84, size.height * 0.20),
      Offset(size.width * 0.16, size.height * 0.80),
      ferroSombra,
    );
    canvas.drawLine(
      Offset(size.width * 0.16, size.height * 0.20),
      Offset(size.width * 0.84, size.height * 0.80),
      ferro,
    );
    canvas.drawLine(
      Offset(size.width * 0.84, size.height * 0.20),
      Offset(size.width * 0.16, size.height * 0.80),
      ferro,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TerrenoEspecialWidget extends StatelessWidget {
  final TipoTerrenoEspecial terreno;

  const TerrenoEspecialWidget({
    super.key,
    required this.terreno,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TerrenoEspecialPainter(terreno: terreno),
      child: const SizedBox.expand(),
    );
  }
}

class _TerrenoEspecialPainter extends CustomPainter {
  final TipoTerrenoEspecial terreno;

  _TerrenoEspecialPainter({required this.terreno});

  @override
  void paint(Canvas canvas, Size size) {
    final double sx = size.width / 100.0;
    final double sy = size.height / 100.0;
    canvas.save();
    canvas.scale(sx, sy);

    switch (terreno) {
      case TipoTerrenoEspecial.pocoDePiche:
        _desenharPocoDePiche(canvas);
        break;
      case TipoTerrenoEspecial.minaCarvao:
        _desenharMinaCarvao(canvas);
        break;
      case TipoTerrenoEspecial.fundicaoAco:
        _desenharFundicaoAco(canvas);
        break;
      case TipoTerrenoEspecial.minaOuro:
        _desenharMinaOuro(canvas);
        break;
    }

    canvas.restore();
  }

  void _desenharPocoDePiche(Canvas canvas) {
    final Path lamaExterna = Path()
      ..moveTo(22, 34)
      ..quadraticBezierTo(48, 12, 78, 28)
      ..quadraticBezierTo(92, 52, 76, 78)
      ..quadraticBezierTo(46, 92, 20, 74)
      ..quadraticBezierTo(8, 52, 22, 34)
      ..close();

    canvas.drawPath(
      lamaExterna,
      Paint()..color = const Color(0xFF38291D).withOpacity(0.88),
    );

    final Path piche = Path()
      ..moveTo(28, 38)
      ..quadraticBezierTo(50, 20, 72, 34)
      ..quadraticBezierTo(83, 54, 70, 72)
      ..quadraticBezierTo(48, 84, 26, 68)
      ..quadraticBezierTo(16, 52, 28, 38)
      ..close();

    canvas.drawPath(
      piche,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.2, -0.2),
          radius: 0.85,
          colors: [
            Color(0xFF211B18),
            Color(0xFF0E0B0A),
            Color(0xFF050404),
          ],
        ).createShader(const Rect.fromLTWH(16, 20, 68, 64)),
    );

    final Paint ondaPiche = Paint()
      ..color = const Color(0xFF544333).withOpacity(0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawOval(const Rect.fromLTWH(31, 36, 36, 26), ondaPiche);

    canvas.drawCircle(
      const Offset(42, 46),
      4.5,
      Paint()..color = const Color(0xFF2E2620),
    );
    canvas.drawCircle(
      const Offset(40.5, 44.5),
      1.5,
      Paint()..color = const Color(0xFF8C7358).withOpacity(0.70),
    );
    canvas.drawCircle(
      const Offset(60, 56),
      3.2,
      Paint()..color = const Color(0xFF2E2620),
    );
  }

  void _desenharMinaCarvao(Canvas canvas) {
    final Paint vigaMadeira = Paint()
      ..color = const Color(0xFF331D0F).withOpacity(0.88)
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(const Offset(14, 16), const Offset(86, 16), vigaMadeira);
    canvas.drawLine(const Offset(20, 16), const Offset(20, 34), vigaMadeira);
    canvas.drawLine(const Offset(80, 16), const Offset(80, 34), vigaMadeira);

    final Paint carvaoEscuro = Paint()..color = const Color(0xFF15181C);
    final Paint carvaoBrilho = Paint()..color = const Color(0xFF363E47);

    final Path bloco1 = Path()
      ..moveTo(26, 68)
      ..lineTo(35, 46)
      ..lineTo(52, 48)
      ..lineTo(56, 70)
      ..close();
    final Path bloco2 = Path()
      ..moveTo(48, 70)
      ..lineTo(55, 44)
      ..lineTo(74, 50)
      ..lineTo(76, 68)
      ..close();

    canvas.drawPath(bloco1, carvaoEscuro);
    canvas.drawPath(bloco2, carvaoEscuro);
    canvas.drawLine(
      const Offset(36, 49),
      const Offset(49, 51),
      carvaoBrilho..strokeWidth = 2.0,
    );
    canvas.drawLine(
      const Offset(57, 48),
      const Offset(70, 53),
      carvaoBrilho..strokeWidth = 2.0,
    );

    final Paint cabo = Paint()
      ..color = const Color(0xFF6E431E)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(34, 24), const Offset(66, 44), cabo);
    canvas.drawLine(const Offset(66, 24), const Offset(34, 44), cabo);
  }

  void _desenharFundicaoAco(Canvas canvas) {
    final Paint placaMetal = Paint()
      ..color = const Color(0xFF1E2933).withOpacity(0.45)
      ..style = PaintingStyle.fill;
    canvas.drawRect(const Rect.fromLTWH(12, 12, 76, 76), placaMetal);

    final Paint rebite = Paint()..color = const Color(0xFFB38B36);
    for (final pt in const [
      Offset(18, 18),
      Offset(82, 18),
      Offset(18, 82),
      Offset(82, 82),
    ]) {
      canvas.drawCircle(pt, 2.2, rebite);
    }

    canvas.drawCircle(
      const Offset(50, 50),
      21,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0xFFE08A2E),
            Color(0xFF9E2B0E),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: const Offset(50, 50), radius: 21)),
    );

    final Paint engrenagem = Paint()
      ..color = const Color(0xFFB8892D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(const Offset(50, 50), 15, engrenagem);
    for (int i = 0; i < 8; i++) {
      final double ang = i * pi / 4;
      final Offset p1 = Offset(50 + cos(ang) * 15, 50 + sin(ang) * 15);
      final Offset p2 = Offset(50 + cos(ang) * 20.5, 50 + sin(ang) * 20.5);
      canvas.drawLine(p1, p2, engrenagem);
    }
  }

  void _desenharMinaOuro(Canvas canvas) {
    final Paint veioOuro = Paint()
      ..color = const Color(0xFFC29A38).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final Path veios = Path()
      ..moveTo(14, 24)
      ..lineTo(36, 40)
      ..lineTo(64, 34)
      ..lineTo(86, 18)
      ..moveTo(20, 74)
      ..lineTo(44, 58)
      ..lineTo(78, 72);
    canvas.drawPath(veios, veioOuro);

    void desenharLingote(Rect r) {
      final RRect rr = RRect.fromRectAndRadius(r, const Radius.circular(1.5));
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE6C86E),
              Color(0xFFB58222),
              Color(0xFF734F0D),
            ],
          ).createShader(r),
      );
      canvas.drawRRect(
        rr,
        Paint()
          ..color = const Color(0xFF331D04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }

    desenharLingote(const Rect.fromLTWH(25, 53, 24, 12));
    desenharLingote(const Rect.fromLTWH(51, 53, 24, 12));
    desenharLingote(const Rect.fromLTWH(38, 40, 24, 12));

    final Paint brilho = Paint()
      ..color = const Color(0xFFF5E6B3)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(50, 21), const Offset(50, 31), brilho);
    canvas.drawLine(const Offset(45, 26), const Offset(55, 26), brilho);
  }

  @override
  bool shouldRepaint(covariant _TerrenoEspecialPainter oldDelegate) {
    return oldDelegate.terreno != terreno;
  }
}

class PecaImperialWidget extends StatelessWidget {
  final TipoPeca tipo;
  final CorPeca cor;
  final double tamanho;

  const PecaImperialWidget({
    super.key,
    required this.tipo,
    required this.cor,
    this.tamanho = 36,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamanho,
      height: tamanho,
      child: CustomPaint(
        painter: _PecaStauntonPainter(tipo: tipo, cor: cor),
      ),
    );
  }
}

class _PecaStauntonPainter extends CustomPainter {
  final TipoPeca tipo;
  final CorPeca cor;

  _PecaStauntonPainter({required this.tipo, required this.cor});

  @override
  void paint(Canvas canvas, Size size) {
    final double sx = size.width / 100.0;
    final double sy = size.height / 100.0;
    canvas.save();
    canvas.scale(sx, sy);

    final bool eBranco = cor == CorPeca.branco;

    final Gradient gradienteCorpo = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: eBranco
          ? const [
              Color(0xFFE7D3A6),
              Color(0xFFC5A870),
              Color(0xFF947642),
            ]
          : const [
              Color(0xFF332B26),
              Color(0xFF191310),
              Color(0xFF0A0705),
            ],
    );

    final Paint paintSombra = Paint()
      ..color = Colors.black.withOpacity(0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    final Paint paintCorpo = Paint()
      ..shader = gradienteCorpo.createShader(const Rect.fromLTWH(15, 5, 70, 90))
      ..style = PaintingStyle.fill;

    final Paint paintContorno = Paint()
      ..color = eBranco ? const Color(0xFF241308) : const Color(0xFFA67E32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = eBranco ? 2.6 : 2.3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final Paint paintDetalheOuro = Paint()
      ..color = eBranco ? const Color(0xFF946A1E) : const Color(0xFFB58E3C)
      ..style = PaintingStyle.fill;

    final Path corpo = _construirSilhueta(tipo);

    canvas.save();
    canvas.translate(2.2, 3.2);
    canvas.drawPath(corpo, paintSombra);
    canvas.restore();

    canvas.drawPath(corpo, paintCorpo);
    canvas.drawPath(corpo, paintContorno);

    final RRect baseInferior = RRect.fromRectAndRadius(
      const Rect.fromLTWH(20, 84, 60, 8),
      const Radius.circular(1.5),
    );
    final RRect baseSuperior = RRect.fromRectAndRadius(
      const Rect.fromLTWH(25, 77, 50, 7),
      const Radius.circular(1.5),
    );

    canvas.drawRRect(baseSuperior, paintCorpo);
    canvas.drawRRect(baseSuperior, paintContorno);
    canvas.drawRRect(baseInferior, paintCorpo);
    canvas.drawRRect(baseInferior, paintContorno);

    canvas.drawLine(
      const Offset(26, 84),
      const Offset(74, 84),
      Paint()
        ..color = paintDetalheOuro.color
        ..strokeWidth = 1.6,
    );

    _desenharDetalhesInternos(
        canvas, paintCorpo, paintContorno, paintDetalheOuro, eBranco);

    canvas.restore();
  }

  Path _construirSilhueta(TipoPeca tipo) {
    final Path p = Path();
    switch (tipo) {
      case TipoPeca.peao:
        p.moveTo(31, 77);
        p.quadraticBezierTo(34, 58, 41, 47);
        p.lineTo(59, 47);
        p.quadraticBezierTo(66, 58, 69, 77);
        p.close();
        p.addOval(Rect.fromCircle(center: const Offset(50, 31), radius: 13.5));
        break;

      case TipoPeca.torre:
        p.moveTo(29, 77);
        p.lineTo(33, 36);
        p.lineTo(26, 36);
        p.lineTo(26, 19);
        p.lineTo(37, 19);
        p.lineTo(37, 26);
        p.lineTo(44, 26);
        p.lineTo(44, 19);
        p.lineTo(56, 19);
        p.lineTo(56, 26);
        p.lineTo(63, 26);
        p.lineTo(63, 19);
        p.lineTo(74, 19);
        p.lineTo(74, 36);
        p.lineTo(67, 36);
        p.lineTo(71, 77);
        p.close();
        break;

      case TipoPeca.cavalo:
        p.moveTo(30, 77);
        p.quadraticBezierTo(32, 60, 44, 44);
        p.quadraticBezierTo(33, 47, 26, 40);
        p.quadraticBezierTo(26, 33, 35, 25);
        p.quadraticBezierTo(43, 18, 48, 16);
        p.lineTo(54, 10);
        p.lineTo(57, 18);
        p.quadraticBezierTo(68, 25, 71, 42);
        p.quadraticBezierTo(73, 60, 69, 77);
        p.close();
        break;

      case TipoPeca.bispo:
        p.moveTo(31, 77);
        p.quadraticBezierTo(34, 58, 41, 46);
        p.lineTo(59, 46);
        p.quadraticBezierTo(66, 58, 69, 77);
        p.close();

        final Path mitra = Path();
        mitra.moveTo(50, 15);
        mitra.quadraticBezierTo(68, 28, 59, 45);
        mitra.lineTo(41, 45);
        mitra.quadraticBezierTo(32, 28, 50, 15);
        mitra.close();
        p.addPath(mitra, Offset.zero);
        p.addOval(Rect.fromCircle(center: const Offset(50, 11.5), radius: 4.0));
        break;

      case TipoPeca.rainha:
        p.moveTo(29, 77);
        p.quadraticBezierTo(37, 56, 35, 38);
        p.lineTo(26, 20);
        p.lineTo(36, 28);
        p.lineTo(39, 16);
        p.lineTo(46, 27);
        p.lineTo(50, 14);
        p.lineTo(54, 27);
        p.lineTo(61, 16);
        p.lineTo(64, 28);
        p.lineTo(74, 20);
        p.lineTo(65, 38);
        p.quadraticBezierTo(63, 56, 71, 77);
        p.close();
        break;

      case TipoPeca.rei:
        p.moveTo(28, 77);
        p.quadraticBezierTo(36, 56, 33, 38);
        p.quadraticBezierTo(27, 26, 38, 21);
        p.lineTo(62, 21);
        p.quadraticBezierTo(73, 26, 67, 38);
        p.quadraticBezierTo(64, 56, 72, 77);
        p.close();
        p.addRect(const Rect.fromLTWH(46.5, 6, 7, 15));
        p.addRect(const Rect.fromLTWH(41.5, 10, 17, 5.5));
        break;
    }
    return p;
  }

  void _desenharDetalhesInternos(
    Canvas canvas,
    Paint paintCorpo,
    Paint paintContorno,
    Paint paintOuro,
    bool eBranco,
  ) {
    final Paint paintTracoInterno = Paint()
      ..color = eBranco ? const Color(0xFF3A2212) : const Color(0xFFB58E3C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    switch (tipo) {
      case TipoPeca.peao:
        final RRect colar = RRect.fromRectAndRadius(
          const Rect.fromLTWH(35, 44, 30, 5),
          const Radius.circular(1.5),
        );
        canvas.drawRRect(colar, paintOuro);
        canvas.drawRRect(colar, paintContorno);
        break;

      case TipoPeca.torre:
        canvas.drawLine(
            const Offset(33, 36), const Offset(67, 36), paintTracoInterno);
        canvas.drawLine(
            const Offset(32, 41), const Offset(68, 41), paintTracoInterno);
        break;

      case TipoPeca.cavalo:
        canvas.drawCircle(
          const Offset(45, 25),
          2.1,
          Paint()..color = paintTracoInterno.color,
        );
        canvas.drawCircle(
          const Offset(31, 37),
          1.4,
          Paint()..color = paintTracoInterno.color,
        );
        final Path crina = Path()
          ..moveTo(57, 22)
          ..quadraticBezierTo(65, 34, 65, 56);
        canvas.drawPath(crina, paintTracoInterno);
        break;

      case TipoPeca.bispo:
        final RRect colar = RRect.fromRectAndRadius(
          const Rect.fromLTWH(35, 43, 30, 5),
          const Radius.circular(1.5),
        );
        canvas.drawRRect(colar, paintOuro);
        canvas.drawRRect(colar, paintContorno);
        canvas.drawLine(
          const Offset(52, 23),
          const Offset(60, 31),
          paintTracoInterno..strokeWidth = 2.4,
        );
        break;

      case TipoPeca.rainha:
        final RRect colar = RRect.fromRectAndRadius(
          const Rect.fromLTWH(32, 35, 36, 5),
          const Radius.circular(1.5),
        );
        canvas.drawRRect(colar, paintOuro);
        canvas.drawRRect(colar, paintContorno);
        const pontos = [
          Offset(26, 19),
          Offset(39, 15),
          Offset(50, 13),
          Offset(61, 15),
          Offset(74, 19),
        ];
        for (final pt in pontos) {
          canvas.drawCircle(pt, 2.3, paintOuro);
        }
        break;

      case TipoPeca.rei:
        final RRect colar = RRect.fromRectAndRadius(
          const Rect.fromLTWH(30, 35, 40, 5.5),
          const Radius.circular(1.5),
        );
        canvas.drawRRect(colar, paintOuro);
        canvas.drawRRect(colar, paintContorno);
        canvas.drawLine(
            const Offset(35, 29), const Offset(65, 29), paintTracoInterno);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _PecaStauntonPainter oldDelegate) {
    return oldDelegate.tipo != tipo || oldDelegate.cor != cor;
  }
}

class Peca {
  final TipoPeca tipo;
  CorPeca cor;
  int posicao;
  bool capturado;

  /// 0 = sem proteção, -1 = proteção permanente, > 0 = rodadas restantes
  int rodadasProtegida;

  /// 0 = livre, > 0 = rodadas restantes paralisada
  int rodadasParalisada;

  Peca(
    this.tipo,
    this.cor, {
    this.posicao = 0,
    this.capturado = false,
    this.rodadasProtegida = 0,
    this.rodadasParalisada = 0,
  });

  bool get protegida => rodadasProtegida != 0;
  bool get protecaoPermanente => rodadasProtegida == -1;
  bool get paralisada => rodadasParalisada > 0;
}

class Carta {
  final TipoPeca tipoPeca;
  final int custo;

  Carta(this.tipoPeca, this.custo);
}

class CartaEfeito {
  final String titulo;
  final String descricao;
  final String raridade;
  final bool Function(_TabuleiroXadrezState state)? podeUsar;
  final void Function(_TabuleiroXadrezState state) aplicarEfeito;

  CartaEfeito({
    required this.titulo,
    required this.descricao,
    required this.raridade,
    this.podeUsar,
    required this.aplicarEfeito,
  });
}

class JogadorStatus {
  /// £50 iniciais permitem comprar pelo menos 1 Bispo (£50) ou 1 Cavalo (£50)
  int dinheiro = 50;
  List<Carta> mao = [];
  double descontoPercentualProximaPeca = 0.0;
  int descontoFixoProximaPeca = 0;
  int descontoPeaoProximaCompra = 0;
  int taxaExtraProximaPeca = 0;
  int bonusProximaRodada = 0;
  int comercioRodadas = 0;
  int companhiaMonopolistaRodadas = 0;
  int impostoSeloCargas = 0;
  int inflacaoRodadas = 0;
  int bloqueioNavalRodadas = 0;
  bool mobilizacaoRapidaAtiva = false;
  bool refinariaBetumeAtiva = false;

  void resetar() {
    dinheiro = 50;
    mao.clear();
    descontoPercentualProximaPeca = 0.0;
    descontoFixoProximaPeca = 0;
    descontoPeaoProximaCompra = 0;
    taxaExtraProximaPeca = 0;
    bonusProximaRodada = 0;
    comercioRodadas = 0;
    companhiaMonopolistaRodadas = 0;
    impostoSeloCargas = 0;
    inflacaoRodadas = 0;
    bloqueioNavalRodadas = 0;
    mobilizacaoRapidaAtiva = false;
    refinariaBetumeAtiva = false;
  }
}

void main() {
  runApp(MaterialApp(
    home: const TabuleiroXadrez(),
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Georgia',
      scaffoldBackgroundColor: EstiloImperial.fundoSala,
      dialogTheme: DialogThemeData(
        backgroundColor: EstiloImperial.mognoEscuro,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: const BorderSide(color: EstiloImperial.lataoOuro, width: 2),
        ),
      ),
    ),
  ));
}

class TabuleiroXadrez extends StatefulWidget {
  const TabuleiroXadrez({super.key});

  @override
  State<TabuleiroXadrez> createState() => _TabuleiroXadrezState();
}

class _TabuleiroXadrezState extends State<TabuleiroXadrez> {
  final Random _random = Random();
  final Map<int, Peca> tabuleiro = {};

  /// 16 casas especiais iniciais (8 pares espelhados com simetria rotacional de 180°)
  final Map<int, TipoTerrenoEspecial> terrenosEspeciais = {};

  final JogadorStatus statusBranco = JogadorStatus();
  final JogadorStatus statusPreto = JogadorStatus();

  CorPeca turnoAtual = CorPeca.branco;
  int numeroRodada = 1;
  int acoesRestantes = 2;
  bool jaMoveuPecaNesteTurno = false;

  Carta? cartaSelecionada;
  int? indiceCartaSelecionada;
  int? indicePecaSelecionada;

  bool exibeEscolhaDeCarta = false;
  bool escolhendoEfeito = false;
  bool escolhendoPromocaoPeao = false;
  int? indicePromocaoPeao;
  bool promocaoPorDecreto = false;

  ModoSelecao modoSelecao = ModoSelecao.nenhum;
  int? indiceOrigemFerrovia;

  List<Carta> opcoesEscolhaAtual = [];
  List<CartaEfeito> opcoesEfeitoAtual = [];

  int ultimoSubsidioBase = 0;
  int ultimaRendaTerritorios = 0;
  int ultimosTerrenosDominados = 0;

  String? mensagemNotificacao;
  Timer? _timerNotificacao;

  bool _mostrarAvisoTurno = false;
  Timer? _timerAvisoTurno;

  final List<Carta> deckDisponivel = [
    Carta(TipoPeca.peao, 20),
    Carta(TipoPeca.cavalo, 50),
    Carta(TipoPeca.bispo, 50),
    Carta(TipoPeca.torre, 80),
    Carta(TipoPeca.rainha, 150),
  ];

  late final List<CartaEfeito> deckEfeitosDisponiveis = [
    // ==================== COMUNS (~£20 de impacto) ====================
    CartaEfeito(
      titulo: 'Investimento',
      descricao: 'Receba 20 moedas extras imediatamente.',
      raridade: 'Comum',
      aplicarEfeito: (s) => s._status(s.turnoAtual).dinheiro += 20,
    ),
    CartaEfeito(
      titulo: 'Salário Extra',
      descricao:
          'Receba 15 moedas agora e mais 5 moedas no início da sua próxima rodada.',
      raridade: 'Comum',
      aplicarEfeito: (s) {
        final st = s._status(s.turnoAtual);
        st.dinheiro += 15;
        st.bonusProximaRodada += 5;
      },
    ),
    CartaEfeito(
      titulo: 'Tesouro Escondido',
      descricao: 'Ganhe entre 15 e 25 moedas aleatórias extras.',
      raridade: 'Comum',
      aplicarEfeito: (s) {
        final int extra = 15 + s._random.nextInt(11);
        s._status(s.turnoAtual).dinheiro += extra;
      },
    ),
    CartaEfeito(
      titulo: 'Economia de Tempo',
      descricao: 'Sua próxima compra de peça tem desconto de 15 moedas.',
      raridade: 'Comum',
      aplicarEfeito: (s) {
        s._status(s.turnoAtual).descontoFixoProximaPeca += 15;
      },
    ),
    CartaEfeito(
      titulo: 'Promoção',
      descricao: 'Sua próxima peça custa 25% menos.',
      raridade: 'Comum',
      aplicarEfeito: (s) {
        final st = s._status(s.turnoAtual);
        st.descontoPercentualProximaPeca =
            max(st.descontoPercentualProximaPeca, 0.25);
      },
    ),
    CartaEfeito(
      titulo: 'Poupança',
      descricao:
          'Guarde 15 moedas agora e receba 35 moedas no início da sua próxima rodada.',
      raridade: 'Comum',
      podeUsar: (s) => s._status(s.turnoAtual).dinheiro >= 15,
      aplicarEfeito: (s) {
        final st = s._status(s.turnoAtual);
        if (st.dinheiro >= 15) {
          st.dinheiro -= 15;
          st.bonusProximaRodada += 35;
        }
      },
    ),
    CartaEfeito(
      titulo: 'Comércio',
      descricao:
          'Receba 5 moedas agora e ganhe +10 moedas por captura inimiga nas próximas 2 rodadas.',
      raridade: 'Comum',
      aplicarEfeito: (s) {
        final st = s._status(s.turnoAtual);
        st.dinheiro += 5;
        st.comercioRodadas = max(st.comercioRodadas, 2);
      },
    ),
    CartaEfeito(
      titulo: 'Proteção',
      descricao:
          'Escolha uma peça sua para ficar protegida contra captura por 1 rodada.',
      raridade: 'Comum',
      podeUsar: (s) => s._existeAlvoParaModo(ModoSelecao.protecaoTemporaria),
      aplicarEfeito: (s) => s._iniciarModoSelecao(ModoSelecao.protecaoTemporaria),
    ),
    CartaEfeito(
      titulo: 'Extração Colonial',
      descricao:
          'Receba 15 moedas agora, mais 10 moedas extras se já ocupar ao menos 1 terreno especial.',
      raridade: 'Comum',
      aplicarEfeito: (s) {
        final dominio = s._calcularDominioTerritorial(s.turnoAtual);
        final int bonus = dominio.terrenos > 0 ? 25 : 15;
        s._status(s.turnoAtual).dinheiro += bonus;
      },
    ),
    CartaEfeito(
      titulo: 'Corvée',
      descricao:
          'Sacrifique um Peão seu no tabuleiro para receber 35 moedas imediatamente.',
      raridade: 'Comum',
      podeUsar: (s) => s._existeAlvoParaModo(ModoSelecao.corvee),
      aplicarEfeito: (s) => s._iniciarModoSelecao(ModoSelecao.corvee),
    ),
    CartaEfeito(
      titulo: 'Tarifa Alfandegária',
      descricao:
          'A próxima peça invocada pelo adversário custa 15 moedas a mais.',
      raridade: 'Comum',
      aplicarEfeito: (s) {
        s._status(s.turnoAtual.oposta).taxaExtraProximaPeca += 15;
      },
    ),
    CartaEfeito(
      titulo: 'Alistamento das Colônias',
      descricao: 'Sua próxima invocação de Peão custa 15 moedas a menos.',
      raridade: 'Comum',
      aplicarEfeito: (s) {
        s._status(s.turnoAtual).descontoPeaoProximaCompra += 15;
      },
    ),
    CartaEfeito(
      titulo: 'Concessão Ferroviária',
      descricao:
          'Reposicione uma peça sua (exceto o Rei) 1 casa para o lado ou para trás (casa vazia), sem gastar ações.',
      raridade: 'Comum',
      podeUsar: (s) => s._existeAlvoParaModo(ModoSelecao.ferroviaOrigem),
      aplicarEfeito: (s) => s._iniciarModoSelecao(ModoSelecao.ferroviaOrigem),
    ),
    CartaEfeito(
      titulo: 'Imposto do Selo',
      descricao:
          'Receba 10 moedas agora e mais 10 moedas na próxima vez que o adversário invocar uma peça.',
      raridade: 'Comum',
      aplicarEfeito: (s) {
        final st = s._status(s.turnoAtual);
        st.dinheiro += 10;
        st.impostoSeloCargas += 1;
      },
    ),
    CartaEfeito(
      titulo: 'Refinaria de Betume',
      descricao:
          'Receba 10 moedas; sempre que uma peça sua cair em um Poço de Piche, há 10% de chance de extrair petróleo e ganhar £20.',
      raridade: 'Comum',
      podeUsar: (s) => !s._status(s.turnoAtual).refinariaBetumeAtiva,
      aplicarEfeito: (s) {
        final st = s._status(s.turnoAtual);
        st.dinheiro += 10;
        st.refinariaBetumeAtiva = true;
      },
    ),
    CartaEfeito(
      titulo: 'Drenagem de Piche',
      descricao:
          'Receba 10 moedas e escolha um Poço de Piche no tabuleiro para aterrá-lo permanentemente.',
      raridade: 'Comum',
      podeUsar: (s) => s._existeAlvoParaModo(ModoSelecao.drenarPiche),
      aplicarEfeito: (s) {
        s._status(s.turnoAtual).dinheiro += 10;
        s._iniciarModoSelecao(ModoSelecao.drenarPiche);
      },
    ),
    CartaEfeito(
      titulo: 'Prospecção Geológica',
      descricao:
          'Escolha uma casa comum vazia do mapa para abrir uma nova Mina de Carvão (+£4/ciclo).',
      raridade: 'Comum',
      podeUsar: (s) => s._existeAlvoParaModo(ModoSelecao.prospeccaoCarvao),
      aplicarEfeito: (s) => s._iniciarModoSelecao(ModoSelecao.prospeccaoCarvao),
    ),

    // ==================== RARAS (~£35–£40 de impacto) ====================
    CartaEfeito(
      titulo: 'Rei do Mercado',
      descricao: 'Receba 35 moedas extras imediatamente.',
      raridade: 'Rara',
      aplicarEfeito: (s) => s._status(s.turnoAtual).dinheiro += 35,
    ),
    CartaEfeito(
      titulo: 'Contrato Especial',
      descricao:
          'Receba 20 moedas agora e mais 20 moedas no início da sua próxima rodada.',
      raridade: 'Rara',
      aplicarEfeito: (s) {
        final st = s._status(s.turnoAtual);
        st.dinheiro += 20;
        st.bonusProximaRodada += 20;
      },
    ),
    CartaEfeito(
      titulo: 'Roubo',
      descricao: 'Roube 20 moedas do adversário (ou todo o saldo disponível).',
      raridade: 'Rara',
      aplicarEfeito: (s) => s._roubarDinheiro(20),
    ),
    CartaEfeito(
      titulo: 'Recrutamento',
      descricao: 'Compre sua próxima peça com 40% de desconto.',
      raridade: 'Rara',
      aplicarEfeito: (s) {
        final st = s._status(s.turnoAtual);
        st.descontoPercentualProximaPeca =
            max(st.descontoPercentualProximaPeca, 0.40);
      },
    ),
    CartaEfeito(
      titulo: 'Inflação',
      descricao:
          'Os preços das peças do adversário aumentam 30% durante 1 rodada.',
      raridade: 'Rara',
      aplicarEfeito: (s) {
        final op = s._status(s.turnoAtual.oposta);
        op.inflacaoRodadas = max(op.inflacaoRodadas, 1);
      },
    ),
    CartaEfeito(
      titulo: 'Reforço Militar',
      descricao:
          'Escolha um Peão, Cavalo ou Bispo seu para receber proteção permanente contra captura.',
      raridade: 'Rara',
      podeUsar: (s) =>
          s._existeAlvoParaModo(ModoSelecao.protecaoPermanenteMenor),
      aplicarEfeito: (s) =>
          s._iniciarModoSelecao(ModoSelecao.protecaoPermanenteMenor),
    ),
    CartaEfeito(
      titulo: 'Companhia Monopolista',
      descricao:
          'Receba 25 moedas agora e ganhe 10 moedas extras a cada peça inimiga capturada nas próximas 3 rodadas.',
      raridade: 'Rara',
      aplicarEfeito: (s) {
        final st = s._status(s.turnoAtual);
        st.dinheiro += 25;
        st.companhiaMonopolistaRodadas = 3;
      },
    ),
    CartaEfeito(
      titulo: 'Tratado Desigual',
      descricao:
          'Roube 15 moedas do adversário e reduza o custo da sua próxima peça em 15 moedas.',
      raridade: 'Rara',
      aplicarEfeito: (s) {
        s._roubarDinheiro(15);
        s._status(s.turnoAtual).descontoFixoProximaPeca += 15;
      },
    ),
    CartaEfeito(
      titulo: 'Suborno de Guarnição',
      descricao:
          'Escolha um Peão adversário no tabuleiro e converta-o para a sua cor (paralisado por 1 rodada).',
      raridade: 'Rara',
      podeUsar: (s) => s._existeAlvoParaModo(ModoSelecao.suborno),
      aplicarEfeito: (s) => s._iniciarModoSelecao(ModoSelecao.suborno),
    ),
    CartaEfeito(
      titulo: 'Diplomacia das Canhoneiras',
      descricao:
          'Escolha 1 peça adversária (exceto o Rei) nas 4 fileiras centrais para paralisar por 1 rodada.',
      raridade: 'Rara',
      podeUsar: (s) => s._existeAlvoParaModo(ModoSelecao.canhoneiras),
      aplicarEfeito: (s) => s._iniciarModoSelecao(ModoSelecao.canhoneiras),
    ),
    CartaEfeito(
      titulo: 'Protetorado Fantoche',
      descricao:
          'Receba 15 moedas e proteja um Peão, Cavalo ou Bispo seu contra captura por 2 rodadas.',
      raridade: 'Rara',
      podeUsar: (s) => s._existeAlvoParaModo(ModoSelecao.protetoradoFantoche),
      aplicarEfeito: (s) {
        s._status(s.turnoAtual).dinheiro += 15;
        s._iniciarModoSelecao(ModoSelecao.protetoradoFantoche);
      },
    ),
    CartaEfeito(
      titulo: 'Mobilização Rápida',
      descricao:
          'Receba 10 moedas e, neste turno, invocar um Cavalo ou Bispo custa apenas 1 ação em vez de 2.',
      raridade: 'Rara',
      aplicarEfeito: (s) {
        final st = s._status(s.turnoAtual);
        st.dinheiro += 10;
        st.mobilizacaoRapidaAtiva = true;
      },
    ),
    CartaEfeito(
      titulo: 'Siderurgia Imperial',
      descricao:
          'Receba 10 moedas e aprimore uma Mina de Carvão (+£4) do mapa para Fundição de Aço (+£8/ciclo).',
      raridade: 'Rara',
      podeUsar: (s) => s._existeAlvoParaModo(ModoSelecao.aprimorarCarvao),
      aplicarEfeito: (s) {
        s._status(s.turnoAtual).dinheiro += 10;
        s._iniciarModoSelecao(ModoSelecao.aprimorarCarvao);
      },
    ),
    CartaEfeito(
      titulo: 'Sabotagem Industrial',
      descricao:
          'Escolha uma peça inimiga (exceto o Rei) sobre um terreno lucrativo; paralise-a por 1 rodada e saqueie 2x a renda do terreno.',
      raridade: 'Rara',
      podeUsar: (s) => s._existeAlvoParaModo(ModoSelecao.sabotagemTerreno),
      aplicarEfeito: (s) => s._iniciarModoSelecao(ModoSelecao.sabotagemTerreno),
    ),

    // ==================== ÉPICAS (~£60–£70 de impacto) ====================
    CartaEfeito(
      titulo: 'Fortuna Real',
      descricao: 'Receba 65 moedas imediatamente.',
      raridade: 'Épica',
      aplicarEfeito: (s) => s._status(s.turnoAtual).dinheiro += 65,
    ),
    CartaEfeito(
      titulo: 'Poder Absoluto',
      descricao:
          'Escolha 1 peça adversária (não o Rei) para congelar por 2 rodadas.',
      raridade: 'Épica',
      podeUsar: (s) => s._existeAlvoParaModo(ModoSelecao.paralisia2Rodadas),
      aplicarEfeito: (s) => s._iniciarModoSelecao(ModoSelecao.paralisia2Rodadas),
    ),
    CartaEfeito(
      titulo: 'Tesouro da Coroa',
      descricao:
          'Receba 45 moedas imediatamente e mais 25 moedas no início da sua próxima rodada.',
      raridade: 'Épica',
      aplicarEfeito: (s) {
        final st = s._status(s.turnoAtual);
        st.dinheiro += 45;
        st.bonusProximaRodada += 25;
      },
    ),
    CartaEfeito(
      titulo: 'Conferência de Partilha',
      descricao:
          'Escolha 1 peça adversária (exceto Rei e Rainha); ela é removida e devolvida como carta à mão do oponente.',
      raridade: 'Épica',
      podeUsar: (s) => s._existeAlvoParaModo(ModoSelecao.conferenciaPartilha),
      aplicarEfeito: (s) =>
          s._iniciarModoSelecao(ModoSelecao.conferenciaPartilha),
    ),
    CartaEfeito(
      titulo: 'Decreto de Promoção',
      descricao:
          'Escolha 1 Peão seu que já tenha cruzado a metade do tabuleiro e promova-o para Cavalo, Bispo ou Torre.',
      raridade: 'Épica',
      podeUsar: (s) => s._existeAlvoParaModo(ModoSelecao.decretoPromocao),
      aplicarEfeito: (s) => s._iniciarModoSelecao(ModoSelecao.decretoPromocao),
    ),
    CartaEfeito(
      titulo: 'Bloqueio Naval',
      descricao:
          'Receba 15 moedas e, durante 1 rodada, impeça o adversário de invocar peças que custem 50 moedas ou mais.',
      raridade: 'Épica',
      aplicarEfeito: (s) {
        s._status(s.turnoAtual).dinheiro += 15;
        final op = s._status(s.turnoAtual.oposta);
        op.bloqueioNavalRodadas = max(op.bloqueioNavalRodadas, 1);
      },
    ),
    CartaEfeito(
      titulo: 'Hegemonia Imperial',
      descricao:
          'Roube 25 moedas do adversário e conceda proteção permanente contra captura a 1 Peão seu.',
      raridade: 'Épica',
      aplicarEfeito: (s) {
        s._roubarDinheiro(25);
        if (s._existeAlvoParaModo(ModoSelecao.protecaoPeaoPermanente)) {
          s._iniciarModoSelecao(ModoSelecao.protecaoPeaoPermanente);
        }
      },
    ),
    CartaEfeito(
      titulo: 'Corrida do Ouro',
      descricao:
          'Receba 15 moedas e converta uma Fundição de Aço ou casa central vazia em uma Mina de Ouro (+£14/ciclo).',
      raridade: 'Épica',
      podeUsar: (s) => s._existeAlvoParaModo(ModoSelecao.corridaOuro),
      aplicarEfeito: (s) {
        s._status(s.turnoAtual).dinheiro += 15;
        s._iniciarModoSelecao(ModoSelecao.corridaOuro);
      },
    ),
    CartaEfeito(
      titulo: 'Catástrofe Petrolífera',
      descricao:
          'Escolha 1 peça inimiga (exceto o Rei) em casa comum para abrir um Poço de Piche (-£3/ciclo) sob ela e imobilizá-la por 1 rodada.',
      raridade: 'Épica',
      podeUsar: (s) => s._existeAlvoParaModo(ModoSelecao.abrirPicheInimigo),
      aplicarEfeito: (s) => s._iniciarModoSelecao(ModoSelecao.abrirPicheInimigo),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iniciarJogo(comSetState: false);
  }

  @override
  void dispose() {
    _timerNotificacao?.cancel();
    _timerAvisoTurno?.cancel();
    super.dispose();
  }

  JogadorStatus _status(CorPeca cor) =>
      cor == CorPeca.branco ? statusBranco : statusPreto;

  List<Carta> _getMao(CorPeca cor) => _status(cor).mao;

  /// Balanceamento estratégico do mapa (16 casas = 8 pares espelhados 180°)
  void _gerarTerrenosEspeciais() {
    terrenosEspeciais.clear();
    final Set<int> escolhidos = {};

    int? sortearCasa(
      bool Function(int r, int c) filtro, {
      int distMinimaMesmoTipo = 3,
      int distMinimaQualquer = 2,
      List<int> jaDoMesmoTipo = const [],
    }) {
      final List<int> candidatos = [];
      for (int i = 0; i < 32; i++) {
        if (i == 4 || i == 3) continue;
        if (escolhidos.contains(i)) continue;
        final int r = i ~/ 8;
        final int c = i % 8;
        if (filtro(r, c)) {
          candidatos.add(i);
        }
      }
      candidatos.shuffle(_random);

      int distanciaManhattan(int a, int b) {
        return ((a ~/ 8) - (b ~/ 8)).abs() + ((a % 8) - (b % 8)).abs();
      }

      for (final cand in candidatos) {
        final bool longeMesmoTipo = jaDoMesmoTipo
            .every((outro) => distanciaManhattan(cand, outro) >= distMinimaMesmoTipo);
        final bool longeQualquer = escolhidos
            .every((outro) => distanciaManhattan(cand, outro) >= distMinimaQualquer);
        if (longeMesmoTipo && longeQualquer) {
          return cand;
        }
      }

      for (final cand in candidatos) {
        final bool longeMesmoTipo = jaDoMesmoTipo
            .every((outro) => distanciaManhattan(cand, outro) >= distMinimaMesmoTipo);
        if (longeMesmoTipo) {
          return cand;
        }
      }

      return candidatos.isNotEmpty ? candidatos.first : null;
    }

    void registrarPar(int idxSuperior, TipoTerrenoEspecial tipo) {
      escolhidos.add(idxSuperior);
      terrenosEspeciais[idxSuperior] = tipo;
      terrenosEspeciais[63 - idxSuperior] = tipo;
    }

    // 1) MINA DE OURO (+£14): próxima ao centro
    final int? ouro = sortearCasa(
      (r, c) => r == 3 && c >= 2 && c <= 5,
      distMinimaQualquer: 1,
    );
    if (ouro != null) {
      registrarPar(ouro, TipoTerrenoEspecial.minaOuro);
    }

    // 2) POÇO DE PICHE (-£3): espelhado por todo o mapa
    final List<int> piches = [];
    final List<bool Function(int r, int c)> faixasPiche = [
      (r, c) => r <= 1,
      (r, c) => r == 2,
      (r, c) => r == 3,
    ];
    for (final faixa in faixasPiche) {
      final int? piche = sortearCasa(
        faixa,
        distMinimaMesmoTipo: 3,
        distMinimaQualquer: 2,
        jaDoMesmoTipo: piches,
      );
      if (piche != null) {
        piches.add(piche);
        registrarPar(piche, TipoTerrenoEspecial.pocoDePiche);
      }
    }

    // 3) FUNDIÇÃO DE AÇO (+£8): espalhada
    final List<int> fundicoes = [];
    for (int k = 0; k < 2; k++) {
      final int? fundicao = sortearCasa(
        (r, c) => r >= 1 && !(r == 3 && (c == 3 || c == 4)),
        distMinimaMesmoTipo: 4,
        distMinimaQualquer: 2,
        jaDoMesmoTipo: fundicoes,
      );
      if (fundicao != null) {
        fundicoes.add(fundicao);
        registrarPar(fundicao, TipoTerrenoEspecial.fundicaoAco);
      }
    }

    // 4) MINA DE CARVÃO (+£4): espalhada
    final List<int> carvoes = [];
    for (int k = 0; k < 2; k++) {
      final int? carvao = sortearCasa(
        (r, c) => !(r == 3 && (c == 3 || c == 4)),
        distMinimaMesmoTipo: 4,
        distMinimaQualquer: 2,
        jaDoMesmoTipo: carvoes,
      );
      if (carvao != null) {
        carvoes.add(carvao);
        registrarPar(carvao, TipoTerrenoEspecial.minaCarvao);
      }
    }
  }

  ({int total, int terrenos}) _calcularDominioTerritorial(CorPeca cor) {
    int total = 0;
    int terrenos = 0;
    for (final entry in tabuleiro.entries) {
      if (entry.value.cor == cor) {
        final TipoTerrenoEspecial? t = terrenosEspeciais[entry.key];
        if (t != null) {
          terrenos += 1;
          total += t.renda;
        }
      }
    }
    return (total: total, terrenos: terrenos);
  }

  void _roubarDinheiro(int quantia) {
    final atual = _status(turnoAtual);
    final oponente = _status(turnoAtual.oposta);
    final int roubo = min(quantia, oponente.dinheiro);
    oponente.dinheiro -= roubo;
    atual.dinheiro += roubo;
  }

  void _iniciarModoSelecao(ModoSelecao modo) {
    if (!_existeAlvoParaModo(modo)) {
      _mostrarSnackBar('Nenhum alvo válido disponível no mapa!');
      return;
    }
    modoSelecao = modo;
    indiceOrigemFerrovia = null;
  }

  List<int> _destinosValidosFerrovia(int origem) {
    final Peca? peca = tabuleiro[origem];
    if (peca == null || peca.cor != turnoAtual || peca.tipo == TipoPeca.rei) {
      return [];
    }
    final int origRow = origem ~/ 8;
    final int origCol = origem % 8;
    final int rowTras =
        (turnoAtual == CorPeca.branco) ? origRow + 1 : origRow - 1;

    final List<List<int>> candidatos = [
      [origRow, origCol - 1],
      [origRow, origCol + 1],
      [rowTras, origCol],
    ];

    final List<int> validos = [];
    for (final pos in candidatos) {
      final int r = pos[0];
      final int c = pos[1];
      if (r >= 0 && r < 8 && c >= 0 && c < 8) {
        final int idx = r * 8 + c;
        if (!tabuleiro.containsKey(idx)) {
          validos.add(idx);
        }
      }
    }
    return validos;
  }

  bool _existeAlvoParaModo(ModoSelecao modo) {
    for (int i = 0; i < 64; i++) {
      if (_casaValidaParaModo(i, modo)) return true;
    }
    return false;
  }

  bool _casaValidaParaModo(int index, ModoSelecao modo) {
    final Peca? p = tabuleiro[index];
    final TipoTerrenoEspecial? terreno = terrenosEspeciais[index];
    final int linha = index ~/ 8;

    switch (modo) {
      case ModoSelecao.nenhum:
        return false;
      case ModoSelecao.protecaoTemporaria:
        return p != null && p.cor == turnoAtual && !p.protecaoPermanente;
      case ModoSelecao.protecaoPermanenteMenor:
      case ModoSelecao.protetoradoFantoche:
        return p != null &&
            p.cor == turnoAtual &&
            !p.protecaoPermanente &&
            (p.tipo == TipoPeca.peao ||
                p.tipo == TipoPeca.cavalo ||
                p.tipo == TipoPeca.bispo);
      case ModoSelecao.protecaoPeaoPermanente:
        return p != null &&
            p.cor == turnoAtual &&
            p.tipo == TipoPeca.peao &&
            !p.protecaoPermanente;
      case ModoSelecao.paralisia2Rodadas:
        return p != null &&
            p.cor == turnoAtual.oposta &&
            p.tipo != TipoPeca.rei;
      case ModoSelecao.corvee:
        return p != null && p.cor == turnoAtual && p.tipo == TipoPeca.peao;
      case ModoSelecao.ferroviaOrigem:
        return p != null &&
            p.cor == turnoAtual &&
            p.tipo != TipoPeca.rei &&
            _destinosValidosFerrovia(index).isNotEmpty;
      case ModoSelecao.ferroviaDestino:
        if (indiceOrigemFerrovia == null) return false;
        return _destinosValidosFerrovia(indiceOrigemFerrovia!).contains(index);
      case ModoSelecao.suborno:
        return p != null &&
            p.cor == turnoAtual.oposta &&
            p.tipo == TipoPeca.peao;
      case ModoSelecao.canhoneiras:
        return p != null &&
            p.cor == turnoAtual.oposta &&
            p.tipo != TipoPeca.rei &&
            linha >= 2 &&
            linha <= 5;
      case ModoSelecao.conferenciaPartilha:
        return p != null &&
            p.cor == turnoAtual.oposta &&
            p.tipo != TipoPeca.rei &&
            p.tipo != TipoPeca.rainha;
      case ModoSelecao.decretoPromocao:
        if (p == null || p.cor != turnoAtual || p.tipo != TipoPeca.peao) {
          return false;
        }
        return (turnoAtual == CorPeca.branco && linha <= 3) ||
            (turnoAtual == CorPeca.preto && linha >= 4);
      case ModoSelecao.drenarPiche:
        return terreno == TipoTerrenoEspecial.pocoDePiche;
      case ModoSelecao.prospeccaoCarvao:
        return terreno == null && p == null;
      case ModoSelecao.aprimorarCarvao:
        return terreno == TipoTerrenoEspecial.minaCarvao;
      case ModoSelecao.sabotagemTerreno:
        return p != null &&
            p.cor == turnoAtual.oposta &&
            p.tipo != TipoPeca.rei &&
            terreno != null &&
            terreno.renda > 0;
      case ModoSelecao.corridaOuro:
        if (terreno == TipoTerrenoEspecial.fundicaoAco) return true;
        return terreno == null && p == null && linha >= 2 && linha <= 5;
      case ModoSelecao.abrirPicheInimigo:
        return p != null &&
            p.cor == turnoAtual.oposta &&
            p.tipo != TipoPeca.rei &&
            terreno == null;
    }
  }

  String _textoBannerSelecao() {
    switch (modoSelecao) {
      case ModoSelecao.protecaoTemporaria:
        return 'GUARNIÇÃO: Selecione uma peça aliada para protegê-la por 1 rodada.';
      case ModoSelecao.protecaoPermanenteMenor:
        return 'REFORÇO MILITAR: Selecione Peão, Cavalo ou Bispo aliado para proteção permanente.';
      case ModoSelecao.protecaoPeaoPermanente:
        return 'HEGEMONIA IMPERIAL: Selecione 1 Peão aliado para proteção permanente.';
      case ModoSelecao.paralisia2Rodadas:
        return 'PODER ABSOLUTO: Selecione uma peça inimiga (exceto o Rei) para imobilizar por 2 rodadas.';
      case ModoSelecao.corvee:
        return 'CORVÉE: Selecione um Peão aliado para sacrificá-lo por 35 moedas.';
      case ModoSelecao.ferroviaOrigem:
        return 'CONCESSÃO FERROVIÁRIA: Selecione uma peça aliada (exceto o Rei) para reposicionar.';
      case ModoSelecao.ferroviaDestino:
        return 'CONCESSÃO FERROVIÁRIA: Selecione a casa demarcada ao lado ou à retaguarda.';
      case ModoSelecao.suborno:
        return 'SUBORNO DE GUARNIÇÃO: Selecione um Peão inimigo para convertê-lo.';
      case ModoSelecao.canhoneiras:
        return 'CANHONEIRAS: Selecione peça inimiga (exceto o Rei) nas 4 fileiras centrais.';
      case ModoSelecao.protetoradoFantoche:
        return 'PROTETORADO FANTOCHE: Selecione Peão, Cavalo ou Bispo aliado para guarnecer por 2 rodadas.';
      case ModoSelecao.conferenciaPartilha:
        return 'CONFERÊNCIA DE PARTILHA: Selecione peça inimiga (exceto Rei/Rainha) para recuar à mão.';
      case ModoSelecao.decretoPromocao:
        return 'DECRETO DE PROMOÇÃO: Selecione um Peão aliado além da linha central.';
      case ModoSelecao.drenarPiche:
        return 'DRENAGEM DE PICHE: Selecione um Poço de Piche para aterrá-lo permanentemente.';
      case ModoSelecao.prospeccaoCarvao:
        return 'PROSPECÇÃO GEOLÓGICA: Selecione uma casa comum vazia para abrir uma Mina de Carvão.';
      case ModoSelecao.aprimorarCarvao:
        return 'SIDERURGIA IMPERIAL: Selecione uma Mina de Carvão para evoluí-la em Fundição de Aço.';
      case ModoSelecao.sabotagemTerreno:
        return 'SABOTAGEM INDUSTRIAL: Selecione peça inimiga em terreno lucrativo para paralisar e saquear.';
      case ModoSelecao.corridaOuro:
        return 'CORRIDA DO OURO: Selecione uma Fundição de Aço ou casa central vazia para criar Mina de Ouro.';
      case ModoSelecao.abrirPicheInimigo:
        return 'CATÁSTROFE PETROLÍFERA: Selecione peça inimiga em casa comum para abrir Poço de Piche sob ela.';
      case ModoSelecao.nenhum:
        return '';
    }
  }

  void _exibirAvisoDeTurno({bool comSetState = true}) {
    _timerAvisoTurno?.cancel();
    if (comSetState) {
      setState(() {
        _mostrarAvisoTurno = true;
      });
    } else {
      _mostrarAvisoTurno = true;
    }
    _timerAvisoTurno = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _mostrarAvisoTurno = false;
        });
      }
    });
  }

  void _iniciarJogo({bool comSetState = true}) {
    void acao() {
      tabuleiro.clear();
      _gerarTerrenosEspeciais();
      statusBranco.resetar();
      statusPreto.resetar();
      numeroRodada = 1;
      acoesRestantes = 2;
      jaMoveuPecaNesteTurno = false;
      turnoAtual = CorPeca.branco;
      cartaSelecionada = null;
      indiceCartaSelecionada = null;
      indicePecaSelecionada = null;
      exibeEscolhaDeCarta = false;
      escolhendoEfeito = false;
      escolhendoPromocaoPeao = false;
      indicePromocaoPeao = null;
      promocaoPorDecreto = false;
      modoSelecao = ModoSelecao.nenhum;
      indiceOrigemFerrovia = null;
      mensagemNotificacao = null;
      ultimoSubsidioBase = 0;
      ultimaRendaTerritorios = 0;
      ultimosTerrenosDominados = 0;

      tabuleiro[4] = Peca(TipoPeca.rei, CorPeca.preto, posicao: 4);
      tabuleiro[60] = Peca(TipoPeca.rei, CorPeca.branco, posicao: 60);

      _abrirTelaEscolhaCartas(comSetState: false);
      _exibirAvisoDeTurno(comSetState: false);
    }

    if (comSetState) {
      setState(acao);
    } else {
      acao();
    }
  }

  void _mostrarSnackBar(String mensagem) {
    _timerNotificacao?.cancel();
    setState(() {
      mensagemNotificacao = mensagem;
    });
    _timerNotificacao = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          mensagemNotificacao = null;
        });
      }
    });
  }

  void _abrirTelaEscolhaCartas({bool comSetState = true}) {
    final List<Carta> poolCartas = numeroRodada == 1
        ? deckDisponivel
            .where((carta) =>
                carta.tipoPeca == TipoPeca.peao ||
                carta.tipoPeca == TipoPeca.bispo ||
                carta.tipoPeca == TipoPeca.cavalo)
            .toList()
        : deckDisponivel;

    opcoesEscolhaAtual = List.generate(
        2, (_) => poolCartas[_random.nextInt(poolCartas.length)]);

    void acao() {
      if (numeroRodada > 1) {
        final dominio = _calcularDominioTerritorial(turnoAtual);
        ultimoSubsidioBase = 30;
        ultimaRendaTerritorios = dominio.total;
        ultimosTerrenosDominados = dominio.terrenos;
        final int ganhoLiquido =
            max(0, ultimoSubsidioBase + ultimaRendaTerritorios);
        _status(turnoAtual).dinheiro += ganhoLiquido;
      } else {
        ultimoSubsidioBase = 0;
        ultimaRendaTerritorios = 0;
        ultimosTerrenosDominados = 0;
      }
      escolhendoEfeito = false;
      exibeEscolhaDeCarta = true;
    }

    if (comSetState) {
      setState(acao);
    } else {
      acao();
    }
  }

  void _escolherCarta(Carta cartaEscolhida) {
    setState(() {
      _getMao(turnoAtual).add(cartaEscolhida);
      _abrirTelaEscolhaEfeitos();
    });
  }

  CartaEfeito _sortearCartaPorRaridade({bool apenasComum = false}) {
    List<CartaEfeito> elegiveis(String raridade) {
      return deckEfeitosDisponiveis
          .where((e) =>
              e.raridade == raridade && (e.podeUsar == null || e.podeUsar!(this)))
          .toList();
    }

    if (apenasComum) {
      final comuns = elegiveis('Comum');
      return comuns[_random.nextInt(comuns.length)];
    }

    final roll = _random.nextInt(100);
    String raridadeAlvo;

    if (roll < 70) {
      raridadeAlvo = 'Comum';
    } else if (roll < 95) {
      raridadeAlvo = 'Rara';
    } else {
      raridadeAlvo = 'Épica';
    }

    var cartasFiltradas = elegiveis(raridadeAlvo);
    if (cartasFiltradas.isEmpty) {
      cartasFiltradas = elegiveis('Comum');
    }

    return cartasFiltradas[_random.nextInt(cartasFiltradas.length)];
  }

  void _abrirTelaEscolhaEfeitos() {
    final apenasComum = numeroRodada == 1;
    final primeira = _sortearCartaPorRaridade(apenasComum: apenasComum);
    CartaEfeito segunda = _sortearCartaPorRaridade(apenasComum: apenasComum);

    for (int tentativa = 0; tentativa < 6; tentativa++) {
      if (segunda.titulo != primeira.titulo) break;
      segunda = _sortearCartaPorRaridade(apenasComum: apenasComum);
    }

    opcoesEfeitoAtual = [primeira, segunda];

    setState(() {
      escolhendoEfeito = true;
    });
  }

  void _escolherEfeito(CartaEfeito efeitoEscolhido) {
    setState(() {
      efeitoEscolhido.aplicarEfeito(this);
      exibeEscolhaDeCarta = false;
      escolhendoEfeito = false;

      if (modoSelecao == ModoSelecao.nenhum && !escolhendoPromocaoPeao) {
        _verificarEstadoFimDeJogo();
      }
    });
  }

  void _promoverPeao(TipoPeca novoTipo) {
    if (indicePromocaoPeao == null) return;
    setState(() {
      final int pos = indicePromocaoPeao!;
      final Peca? peaoAtual = tabuleiro[pos];
      tabuleiro[pos] = Peca(
        novoTipo,
        turnoAtual,
        posicao: pos,
        rodadasProtegida: peaoAtual?.rodadasProtegida ?? 0,
      );
      final bool foiPorDecreto = promocaoPorDecreto;
      escolhendoPromocaoPeao = false;
      indicePromocaoPeao = null;
      promocaoPorDecreto = false;

      if (foiPorDecreto) {
        _mostrarSnackBar('Peão promovido a ${novoTipo.nome} por Decreto!');
        _verificarEstadoFimDeJogo();
        return;
      }

      bool temCartaJogavel = _getMao(turnoAtual)
          .any((c) => _custoAcaoCarta(c, turnoAtual) <= acoesRestantes);

      if (acoesRestantes <= 0 || !temCartaJogavel) {
        _finalizarTurno();
      } else {
        _mostrarSnackBar(
            'Peão promovido a ${novoTipo.nome}! Resta $acoesRestantes ação neste turno.');
      }
    });
  }

  void _verificarEstadoFimDeJogo() {
    if (_estaEmXequeMate(turnoAtual)) {
      Future.microtask(
          () => _mostrarFimDeJogo(turnoAtual.oposta, motivo: 'por Xeque-Mate!'));
    } else if (!_estaEmXeque(turnoAtual) &&
        !_temMovimentosValidos(turnoAtual) &&
        !_podeInvocarAlgumaCarta(turnoAtual)) {
      Future.microtask(() => _mostrarEmpateAfogamento(turnoAtual));
    }
  }

  void _iniciarTurnoJogador(CorPeca jogador) {
    final st = _status(jogador);

    if (st.bonusProximaRodada > 0) {
      st.dinheiro += st.bonusProximaRodada;
      st.bonusProximaRodada = 0;
    }

    for (final p in tabuleiro.values) {
      if (p.cor == jogador && p.rodadasProtegida > 0) {
        p.rodadasProtegida -= 1;
      }
    }
  }

  void _finalizarTurno() {
    setState(() {
      final stAtual = _status(turnoAtual);
      stAtual.mobilizacaoRapidaAtiva = false;

      if (stAtual.comercioRodadas > 0) {
        stAtual.comercioRodadas -= 1;
      }
      if (stAtual.companhiaMonopolistaRodadas > 0) {
        stAtual.companhiaMonopolistaRodadas -= 1;
      }
      if (stAtual.inflacaoRodadas > 0) {
        stAtual.inflacaoRodadas -= 1;
      }
      if (stAtual.bloqueioNavalRodadas > 0) {
        stAtual.bloqueioNavalRodadas -= 1;
      }

      for (final p in tabuleiro.values) {
        if (p.cor == turnoAtual && p.rodadasParalisada > 0) {
          p.rodadasParalisada -= 1;
        }
      }

      acoesRestantes = 2;
      jaMoveuPecaNesteTurno = false;
      cartaSelecionada = null;
      indiceCartaSelecionada = null;
      indicePecaSelecionada = null;
      escolhendoPromocaoPeao = false;
      indicePromocaoPeao = null;
      promocaoPorDecreto = false;
      modoSelecao = ModoSelecao.nenhum;
      indiceOrigemFerrovia = null;

      if (turnoAtual == CorPeca.branco) {
        turnoAtual = CorPeca.preto;
        _iniciarTurnoJogador(CorPeca.preto);
        if (numeroRodada == 1 || numeroRodada % 3 == 0) {
          _abrirTelaEscolhaCartas();
        }
      } else {
        numeroRodada++;
        turnoAtual = CorPeca.branco;
        _iniciarTurnoJogador(CorPeca.branco);
        if (numeroRodada % 3 == 0) {
          _abrirTelaEscolhaCartas();
        }
      }

      _exibirAvisoDeTurno(comSetState: false);

      if (!exibeEscolhaDeCarta) {
        _verificarEstadoFimDeJogo();
      } else if (_estaEmXequeMate(turnoAtual)) {
        Future.microtask(() =>
            _mostrarFimDeJogo(turnoAtual.oposta, motivo: 'por Xeque-Mate!'));
      }
    });
  }

  bool _caminhoLivre(int origem, int destino) {
    int origRow = origem ~/ 8;
    int origCol = origem % 8;
    int destRow = destino ~/ 8;
    int destCol = destino % 8;

    int rowStep = destRow.compareTo(origRow);
    int colStep = destCol.compareTo(origCol);

    int currentRow = origRow + rowStep;
    int currentCol = origCol + colStep;

    while (currentRow != destRow || currentCol != destCol) {
      int index = currentRow * 8 + currentCol;
      if (tabuleiro.containsKey(index)) return false;
      currentRow += rowStep;
      currentCol += colStep;
    }
    return true;
  }

  bool _movimentoValido(int origem, int destino, TipoPeca tipo, CorPeca cor) {
    int origRow = origem ~/ 8;
    int origCol = origem % 8;
    int destRow = destino ~/ 8;
    int destCol = destino % 8;

    int diffRow = (origRow - destRow).abs();
    int diffCol = (origCol - destCol).abs();

    Peca? pecaDestino = tabuleiro[destino];
    if (pecaDestino != null && pecaDestino.cor == cor) return false;

    switch (tipo) {
      case TipoPeca.peao:
        int direcao = (cor == CorPeca.branco) ? -1 : 1;
        if (origCol == destCol &&
            destRow == origRow + direcao &&
            pecaDestino == null) return true;
        if (diffCol == 1 &&
            destRow == origRow + direcao &&
            pecaDestino != null) return true;
        return false;
      case TipoPeca.cavalo:
        return (diffRow == 2 && diffCol == 1) ||
            (diffRow == 1 && diffCol == 2);
      case TipoPeca.bispo:
        return diffRow == diffCol && _caminhoLivre(origem, destino);
      case TipoPeca.torre:
        return (origRow == destRow || origCol == destCol) &&
            _caminhoLivre(origem, destino);
      case TipoPeca.rainha:
        return ((origRow == destRow || origCol == destCol) ||
                (diffRow == diffCol)) &&
            _caminhoLivre(origem, destino);
      case TipoPeca.rei:
        return diffRow <= 1 && diffCol <= 1;
    }
  }

  bool _casaAtacadaPorPeca(
      int origem, int destino, TipoPeca tipo, CorPeca cor) {
    int origRow = origem ~/ 8;
    int origCol = origem % 8;
    int destRow = destino ~/ 8;
    int destCol = destino % 8;

    int diffRow = (origRow - destRow).abs();
    int diffCol = (origCol - destCol).abs();

    switch (tipo) {
      case TipoPeca.peao:
        int direcao = (cor == CorPeca.branco) ? -1 : 1;
        return diffCol == 1 && destRow == origRow + direcao;
      case TipoPeca.cavalo:
        return (diffRow == 2 && diffCol == 1) ||
            (diffRow == 1 && diffCol == 2);
      case TipoPeca.bispo:
        return diffRow == diffCol &&
            diffRow > 0 &&
            _caminhoLivre(origem, destino);
      case TipoPeca.torre:
        return ((origRow == destRow && diffCol > 0) ||
                (origCol == destCol && diffRow > 0)) &&
            _caminhoLivre(origem, destino);
      case TipoPeca.rainha:
        return ((origRow == destRow && diffCol > 0) ||
                (origCol == destCol && diffRow > 0) ||
                (diffRow == diffCol && diffRow > 0)) &&
            _caminhoLivre(origem, destino);
      case TipoPeca.rei:
        return diffRow <= 1 && diffCol <= 1 && (diffRow > 0 || diffCol > 0);
    }
  }

  bool _casaSobAtaque(int indiceCasa, CorPeca corAtacante) {
    for (var entry in tabuleiro.entries) {
      Peca p = entry.value;
      if (p.cor == corAtacante) {
        if (_casaAtacadaPorPeca(entry.key, indiceCasa, p.tipo, p.cor)) {
          return true;
        }
      }
    }
    return false;
  }

  int? _encontrarRei(CorPeca cor) {
    for (var entry in tabuleiro.entries) {
      if (entry.value.tipo == TipoPeca.rei && entry.value.cor == cor) {
        return entry.key;
      }
    }
    return null;
  }

  bool _estaEmXeque(CorPeca cor) {
    int? posRei = _encontrarRei(cor);
    if (posRei == null) return false;
    return _casaSobAtaque(posRei, cor.oposta);
  }

  bool _temMovimentosValidos(CorPeca cor) {
    final entradas = Map<int, Peca>.from(tabuleiro).entries.toList();
    for (var entry in entradas) {
      int origem = entry.key;
      Peca p = entry.value;

      if (p.cor != cor || p.paralisada) continue;

      for (int destino = 0; destino < 64; destino++) {
        if (origem == destino) continue;
        if (!_movimentoValido(origem, destino, p.tipo, p.cor)) continue;

        Peca? pecaDestino = tabuleiro[destino];
        if (pecaDestino != null && pecaDestino.protegida) continue;

        if (p.tipo == TipoPeca.rei && _casaSobAtaque(destino, cor.oposta)) {
          continue;
        }

        tabuleiro.remove(origem);
        tabuleiro[destino] = p;
        p.posicao = destino;

        int? posRei = _encontrarRei(cor);
        bool aindaEmXeque =
            posRei != null && _casaSobAtaque(posRei, cor.oposta);

        tabuleiro.remove(destino);
        tabuleiro[origem] = p;
        p.posicao = origem;
        if (pecaDestino != null) {
          tabuleiro[destino] = pecaDestino;
        }

        if (!aindaEmXeque) {
          return true;
        }
      }
    }
    return false;
  }

  int _custoAcaoCarta(Carta carta, CorPeca cor) {
    if (carta.tipoPeca == TipoPeca.peao) return 1;
    if (_status(cor).mobilizacaoRapidaAtiva &&
        (carta.tipoPeca == TipoPeca.cavalo ||
            carta.tipoPeca == TipoPeca.bispo)) {
      return 1;
    }
    return 2;
  }

  int _calcularCustoCarta(Carta carta, CorPeca cor, {bool consumir = false}) {
    final st = _status(cor);
    int custo = carta.custo;

    if (st.inflacaoRodadas > 0) {
      custo = (custo * 1.3).round();
    }
    custo += st.taxaExtraProximaPeca;

    if (st.descontoPercentualProximaPeca > 0) {
      custo = (custo * (1.0 - st.descontoPercentualProximaPeca)).round();
    }
    custo -= st.descontoFixoProximaPeca;

    if (carta.tipoPeca == TipoPeca.peao) {
      custo -= st.descontoPeaoProximaCompra;
    }

    if (consumir) {
      st.taxaExtraProximaPeca = 0;
      st.descontoPercentualProximaPeca = 0.0;
      st.descontoFixoProximaPeca = 0;
      if (carta.tipoPeca == TipoPeca.peao) {
        st.descontoPeaoProximaCompra = 0;
      }
    }

    return max(0, custo);
  }

  bool _podeInvocarAlgumaCarta(CorPeca cor) {
    final st = _status(cor);
    if (st.mao.isEmpty) return false;

    final int dinheiro = st.dinheiro;
    bool podePagarAlguma = st.mao.any((c) {
      if (st.bloqueioNavalRodadas > 0 && c.custo >= 50) return false;
      return _calcularCustoCarta(c, cor, consumir: false) <= dinheiro;
    });
    if (!podePagarAlguma) return false;

    int linhaInicio = (cor == CorPeca.branco) ? 6 : 0;
    int linhaFim = (cor == CorPeca.branco) ? 7 : 1;
    for (int l = linhaInicio; l <= linhaFim; l++) {
      for (int c = 0; c < 8; c++) {
        if (!tabuleiro.containsKey(l * 8 + c)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _estaEmXequeMate(CorPeca cor) {
    return _estaEmXeque(cor) && !_temMovimentosValidos(cor);
  }

  void _mostrarFimDeJogo(CorPeca vencedor,
      {String motivo = 'ao capturar o Soberano adversário!'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: PergaminhoEnvelhecido(
          seed: 99,
          corBorda: EstiloImperial.lataoOuro,
          larguraBorda: 2.5,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SeloCeraBadge(
                texto: '✦ VITÓRIA IMPERIAL ✦',
                corCera: EstiloImperial.carmesimImperial,
                fontSize: 13,
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              ),
              const SizedBox(height: 14),
              Text(
                'O Império ${vencedor.nome} triunfou $motivo',
                textAlign: TextAlign.center,
                style: EstiloImperial.corpo(
                  size: 15,
                  color: EstiloImperial.tintaSepia,
                  weight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              BotaoAntigo(
                label: 'NOVA CAMPANHA',
                corFundo: EstiloImperial.carmesimImperial,
                onPressed: () {
                  Navigator.of(context).pop();
                  _iniciarJogo();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarEmpateAfogamento(CorPeca jogadorSemMovimentos) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: PergaminhoEnvelhecido(
          seed: 77,
          corBorda: EstiloImperial.lataoOuro,
          larguraBorda: 2.5,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SeloCeraBadge(
                texto: '✦ ARMISTÍCIO POR AFOGAMENTO ✦',
                corCera: EstiloImperial.azulPrussia,
                fontSize: 12,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              ),
              const SizedBox(height: 14),
              Text(
                'O Império ${jogadorSemMovimentos.nome} não está em xeque, mas não dispõe de manobras válidas. Assinou-se o armistício!',
                textAlign: TextAlign.center,
                style: EstiloImperial.corpo(
                  size: 14,
                  color: EstiloImperial.tintaSepia,
                ),
              ),
              const SizedBox(height: 18),
              BotaoAntigo(
                label: 'NOVA CAMPANHA',
                corFundo: EstiloImperial.carmesimImperial,
                onPressed: () {
                  Navigator.of(context).pop();
                  _iniciarJogo();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Avalia efeitos ao pisar ou desembarcar em um terreno especial (ex.: 10% de £20 no Poço de Piche)
  String? _avaliarEntradaEmTerreno(int index, JogadorStatus stAtual) {
    final TipoTerrenoEspecial? terreno = terrenosEspeciais[index];
    if (terreno == null) return null;

    if (terreno == TipoTerrenoEspecial.pocoDePiche) {
      if (stAtual.refinariaBetumeAtiva) {
        final bool achouPetroleo = _random.nextInt(100) < 10;
        if (achouPetroleo) {
          stAtual.dinheiro += 20;
          return 'Refinaria de Betume! Petróleo encontrado no piche (+£20)!';
        }
        return 'Poço de Piche (-£3/ciclo). Nenhum petróleo desta vez (10%).';
      }
      return 'Atoleiro! Poço de Piche (-£3/ciclo).';
    }

    return '${terreno.nome} (${terreno.textoRenda}/ciclo) ocupado!';
  }

  void _processarSelecaoCartaEfeito(int index) {
    final Peca? pecaNaCasa = tabuleiro[index];

    if (!_casaValidaParaModo(index, modoSelecao)) {
      _mostrarSnackBar('Alvo inválido para o decreto!');
      return;
    }

    switch (modoSelecao) {
      case ModoSelecao.protecaoTemporaria:
        pecaNaCasa!.rodadasProtegida = 1;
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('Guarnição protegida até o seu próximo turno.');
        break;

      case ModoSelecao.protetoradoFantoche:
        pecaNaCasa!.rodadasProtegida = 2;
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('Protetorado estabelecido por 2 rodadas.');
        break;

      case ModoSelecao.protecaoPermanenteMenor:
      case ModoSelecao.protecaoPeaoPermanente:
        pecaNaCasa!.rodadasProtegida = -1;
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('Fortificação permanente estabelecida.');
        break;

      case ModoSelecao.paralisia2Rodadas:
        pecaNaCasa!.rodadasParalisada = 2;
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('Unidade inimiga imobilizada por 2 rodadas.');
        break;

      case ModoSelecao.canhoneiras:
        pecaNaCasa!.rodadasParalisada = 1;
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('Guarnição inimiga bloqueada por 1 rodada.');
        break;

      case ModoSelecao.corvee:
        tabuleiro.remove(index);
        _status(turnoAtual).dinheiro += 35;
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('Peão sacrificado: +35 moedas à tesouraria.');
        break;

      case ModoSelecao.ferroviaOrigem:
        indiceOrigemFerrovia = index;
        modoSelecao = ModoSelecao.ferroviaDestino;
        _mostrarSnackBar('Selecione a casa livre ao lado ou à retaguarda.');
        return;

      case ModoSelecao.ferroviaDestino:
        final Peca peca = tabuleiro.remove(indiceOrigemFerrovia!)!;
        peca.posicao = index;
        tabuleiro[index] = peca;
        indiceOrigemFerrovia = null;
        modoSelecao = ModoSelecao.nenhum;
        final String? msgTerreno =
            _avaliarEntradaEmTerreno(index, _status(turnoAtual));
        _mostrarSnackBar(
            msgTerreno ?? 'Unidade transportada pela ferrovia.');
        break;

      case ModoSelecao.suborno:
        pecaNaCasa!.cor = turnoAtual;
        pecaNaCasa.rodadasParalisada = 1;
        pecaNaCasa.rodadasProtegida = 0;
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('Peão inimigo cooptado para o seu exército.');
        break;

      case ModoSelecao.conferenciaPartilha:
        final TipoPeca tipoDevolvido = pecaNaCasa!.tipo;
        tabuleiro.remove(index);
        _status(turnoAtual.oposta)
            .mao
            .add(Carta(tipoDevolvido, tipoDevolvido.custoBase));
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('${tipoDevolvido.nome} recuado à mão do oponente.');
        break;

      case ModoSelecao.decretoPromocao:
        modoSelecao = ModoSelecao.nenhum;
        indicePromocaoPeao = index;
        promocaoPorDecreto = true;
        escolhendoPromocaoPeao = true;
        return;

      case ModoSelecao.drenarPiche:
        terrenosEspeciais.remove(index);
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('Poço de Piche aterrado com sucesso!');
        break;

      case ModoSelecao.prospeccaoCarvao:
        terrenosEspeciais[index] = TipoTerrenoEspecial.minaCarvao;
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('Nova Mina de Carvão (+£4/ciclo) inaugurada!');
        break;

      case ModoSelecao.aprimorarCarvao:
        terrenosEspeciais[index] = TipoTerrenoEspecial.fundicaoAco;
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('Mina aprimorada para Fundição de Aço (+£8/ciclo)!');
        break;

      case ModoSelecao.sabotagemTerreno:
        final int saque = terrenosEspeciais[index]!.renda * 2;
        pecaNaCasa!.rodadasParalisada = 1;
        _status(turnoAtual).dinheiro += saque;
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar(
            'Sabotagem concluída! Unidade paralisada e +£$saque saqueados.');
        break;

      case ModoSelecao.corridaOuro:
        terrenosEspeciais[index] = TipoTerrenoEspecial.minaOuro;
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('Mina de Ouro (+£14/ciclo) estabelecida!');
        break;

      case ModoSelecao.abrirPicheInimigo:
        terrenosEspeciais[index] = TipoTerrenoEspecial.pocoDePiche;
        pecaNaCasa!.rodadasParalisada = 1;
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar(
            'Poço de Piche aberto! Unidade inimiga atolada por 1 rodada.');
        break;

      case ModoSelecao.nenhum:
        return;
    }

    _verificarEstadoFimDeJogo();
  }

  void _cliqueCasa(int index) {
    if (exibeEscolhaDeCarta || escolhendoPromocaoPeao) return;

    setState(() {
      if (modoSelecao != ModoSelecao.nenhum) {
        _processarSelecaoCartaEfeito(index);
        return;
      }

      final Peca? pecaNaCasa = tabuleiro[index];
      final stAtual = _status(turnoAtual);

      if (cartaSelecionada != null) {
        if (_estaEmXeque(turnoAtual)) {
          _mostrarSnackBar('Soberano em xeque! Proteja o Rei!');
          return;
        }

        if (stAtual.bloqueioNavalRodadas > 0 && cartaSelecionada!.custo >= 50) {
          _mostrarSnackBar('Bloqueio Naval ativo! Apenas Peões permitidos.');
          return;
        }

        final int custoAcao = _custoAcaoCarta(cartaSelecionada!, turnoAtual);
        if (acoesRestantes < custoAcao) {
          _mostrarSnackBar('Esta unidade exige o turno completo.');
          return;
        }

        final int linha = index ~/ 8;
        bool ladoValido = (turnoAtual == CorPeca.branco && linha >= 6) ||
            (turnoAtual == CorPeca.preto && linha <= 1);

        if (!ladoValido) {
          _mostrarSnackBar(
              'Mobilize apenas nas 2 fileiras de sua retaguarda!');
          return;
        }

        int custoFinal =
            _calcularCustoCarta(cartaSelecionada!, turnoAtual, consumir: false);

        if (stAtual.dinheiro < custoFinal) {
          _mostrarSnackBar('Fundos insuficientes na tesouraria!');
          return;
        }

        if (pecaNaCasa != null) {
          _mostrarSnackBar('Posição já ocupada!');
          return;
        }

        _calcularCustoCarta(cartaSelecionada!, turnoAtual, consumir: true);
        stAtual.dinheiro -= custoFinal;
        stAtual.mao.removeAt(indiceCartaSelecionada!);
        tabuleiro[index] =
            Peca(cartaSelecionada!.tipoPeca, turnoAtual, posicao: index);

        final String? msgTerrenoInvocacao =
            _avaliarEntradaEmTerreno(index, stAtual);

        final stOponente = _status(turnoAtual.oposta);
        if (stOponente.impostoSeloCargas > 0) {
          stOponente.dinheiro += 10;
          stOponente.impostoSeloCargas -= 1;
        }

        acoesRestantes -= custoAcao;
        cartaSelecionada = null;
        indiceCartaSelecionada = null;

        bool temCartaJogavel = stAtual.mao.any((c) {
          if (stAtual.bloqueioNavalRodadas > 0 && c.custo >= 50) return false;
          return _custoAcaoCarta(c, turnoAtual) <= acoesRestantes;
        });
        bool podeMover = !jaMoveuPecaNesteTurno;

        if (msgTerrenoInvocacao != null) {
          _mostrarSnackBar(msgTerrenoInvocacao);
        }

        if (acoesRestantes <= 0 || (!temCartaJogavel && !podeMover)) {
          _finalizarTurno();
        } else if (msgTerrenoInvocacao == null) {
          if (podeMover && temCartaJogavel) {
            _mostrarSnackBar(
                'Resta 1 ação: mobilize carta de 1 ação ou mova 1 unidade.');
          } else if (podeMover) {
            _mostrarSnackBar('Resta 1 ação: mova 1 unidade no mapa.');
          } else if (temCartaJogavel) {
            _mostrarSnackBar('Resta 1 ação: mobilize outra carta de 1 ação.');
          }
        }
        return;
      }

      if (indicePecaSelecionada == null) {
        if (pecaNaCasa != null && pecaNaCasa.cor == turnoAtual) {
          if (jaMoveuPecaNesteTurno) {
            _mostrarSnackBar('Você já manobrou uma unidade neste turno.');
            return;
          }
          if (pecaNaCasa.paralisada) {
            _mostrarSnackBar('Esta unidade está imobilizada!');
            return;
          }
          indicePecaSelecionada = index;
        }
        return;
      }

      if (indicePecaSelecionada == index) {
        indicePecaSelecionada = null;
        return;
      }

      if (pecaNaCasa != null && pecaNaCasa.cor == turnoAtual) {
        if (pecaNaCasa.paralisada) {
          _mostrarSnackBar('Esta unidade está imobilizada!');
          return;
        }
        indicePecaSelecionada = index;
        return;
      }

      Peca pecaMovendo = tabuleiro[indicePecaSelecionada!]!;

      if (!_movimentoValido(indicePecaSelecionada!, index, pecaMovendo.tipo,
          pecaMovendo.cor)) {
        _mostrarSnackBar('Manobra inválida!');
        return;
      }

      Peca? pecaDestinoAnterior = tabuleiro[index];
      int origemAntiga = pecaMovendo.posicao;

      tabuleiro.remove(indicePecaSelecionada);
      tabuleiro[index] = pecaMovendo;
      pecaMovendo.posicao = index;

      int? posReiAposMovimento = _encontrarRei(turnoAtual);
      bool aindaEmXeque = posReiAposMovimento != null &&
          _casaSobAtaque(posReiAposMovimento, turnoAtual.oposta);

      tabuleiro.remove(index);
      tabuleiro[origemAntiga] = pecaMovendo;
      pecaMovendo.posicao = origemAntiga;
      if (pecaDestinoAnterior != null) {
        tabuleiro[index] = pecaDestinoAnterior;
      }

      if (aindaEmXeque) {
        _mostrarSnackBar('O Soberano permaneceria em xeque!');
        return;
      }

      if (pecaMovendo.tipo == TipoPeca.rei &&
          _casaSobAtaque(index, turnoAtual.oposta)) {
        _mostrarSnackBar('Setor sob fogo inimigo!');
        return;
      }

      if (pecaNaCasa != null && pecaNaCasa.protegida) {
        _mostrarSnackBar('Guarnição inimiga fortificada!');
        return;
      }

      if (pecaNaCasa != null) {
        int bonusCaptura = 0;
        if (stAtual.comercioRodadas > 0) bonusCaptura += 10;
        if (stAtual.companhiaMonopolistaRodadas > 0) bonusCaptura += 10;
        if (bonusCaptura > 0) {
          stAtual.dinheiro += bonusCaptura;
        }
      }

      if (pecaNaCasa != null && pecaNaCasa.tipo == TipoPeca.rei) {
        tabuleiro.remove(indicePecaSelecionada);
        tabuleiro[index] = Peca(
          pecaMovendo.tipo,
          pecaMovendo.cor,
          posicao: index,
          rodadasProtegida: pecaMovendo.rodadasProtegida,
        );
        _mostrarFimDeJogo(turnoAtual);
        return;
      }

      tabuleiro.remove(indicePecaSelecionada);
      tabuleiro[index] = Peca(
        pecaMovendo.tipo,
        pecaMovendo.cor,
        posicao: index,
        rodadasProtegida: pecaMovendo.rodadasProtegida,
      );
      indicePecaSelecionada = null;

      jaMoveuPecaNesteTurno = true;
      acoesRestantes -= 1;

      final String? msgTerrenoMovimento =
          _avaliarEntradaEmTerreno(index, stAtual);

      final int linhaDestino = index ~/ 8;
      final bool chegouUltimaCasa = pecaMovendo.tipo == TipoPeca.peao &&
          ((pecaMovendo.cor == CorPeca.branco && linhaDestino == 0) ||
              (pecaMovendo.cor == CorPeca.preto && linhaDestino == 7));

      if (chegouUltimaCasa) {
        if (msgTerrenoMovimento != null) {
          _mostrarSnackBar(msgTerrenoMovimento);
        }
        escolhendoPromocaoPeao = true;
        indicePromocaoPeao = index;
        promocaoPorDecreto = false;
        return;
      }

      bool temCartaJogavel = stAtual.mao.any((c) {
        if (stAtual.bloqueioNavalRodadas > 0 && c.custo >= 50) return false;
        return _custoAcaoCarta(c, turnoAtual) <= acoesRestantes;
      });

      if (acoesRestantes <= 0 || !temCartaJogavel) {
        if (msgTerrenoMovimento != null) {
          _mostrarSnackBar(msgTerrenoMovimento);
        }
        _finalizarTurno();
      } else {
        if (msgTerrenoMovimento != null) {
          _mostrarSnackBar('$msgTerrenoMovimento Resta 1 ação.');
        } else {
          _mostrarSnackBar('Resta 1 ação: mobilize 1 carta de 1 ação.');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Carta> maoAtual = _getMao(turnoAtual);
    final bool estaEmXeque = _estaEmXeque(turnoAtual);
    final int? posReiEmXeque = estaEmXeque ? _encontrarRei(turnoAtual) : null;
    final bool emModoSelecao = modoSelecao != ModoSelecao.nenhum;

    final dominioBranco = _calcularDominioTerritorial(CorPeca.branco);
    final dominioPreto = _calcularDominioTerritorial(CorPeca.preto);

    return Scaffold(
      backgroundColor: EstiloImperial.fundoSala,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: EstiloImperial.lataoOuro, width: 2),
            ),
          ),
          child: CustomPaint(
            painter: _MadeiraEnvelhecidaPainter(seed: 11),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: turnoAtual == CorPeca.branco
                            ? EstiloImperial.pergaminhoClaro
                            : const Color(0xFF140D09),
                        border: Border.all(
                          color: EstiloImperial.lataoOuro,
                          width: 1.6,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '✦',
                          style: TextStyle(
                            fontSize: 12,
                            color: turnoAtual == CorPeca.branco
                                ? EstiloImperial.tintaSepia
                                : EstiloImperial.lataoClaro,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ANO ${1870 + numeroRodada} • IMPÉRIO ${turnoAtual.nome.toUpperCase()} ($acoesRestantes/2)',
                        overflow: TextOverflow.ellipsis,
                        style: EstiloImperial.titulo(
                          size: 13.5,
                          color: EstiloImperial.pergaminhoClaro,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: PergaminhoEnvelhecido(
                              seed: 33,
                              corBorda: EstiloImperial.lataoOuro,
                              larguraBorda: 2.2,
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '✦ REINICIAR CAMPANHA ✦',
                                    style: EstiloImperial.titulo(
                                      size: 16,
                                      color: EstiloImperial.carmesimImperial,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Deseja encerrar os registros desta campanha e iniciar uma nova partida?',
                                    textAlign: TextAlign.center,
                                    style: EstiloImperial.corpo(
                                      size: 13.5,
                                      color: EstiloImperial.tintaSepia,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      BotaoAntigo(
                                        label: 'CANCELAR',
                                        corFundo: EstiloImperial.mognoMedio,
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                      BotaoAntigo(
                                        label: 'REINICIAR',
                                        corFundo:
                                            EstiloImperial.carmesimImperial,
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          _iniciarJogo();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: EstiloImperial.lataoOuro.withOpacity(0.75),
                            width: 1.1,
                          ),
                          color: Colors.black.withOpacity(0.35),
                        ),
                        child: Text(
                          'REINICIAR',
                          style: EstiloImperial.titulo(
                            size: 10,
                            color: EstiloImperial.lataoClaro,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.05,
            colors: [
              Color(0xFF1F120A),
              Color(0xFF0A0603),
            ],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Placa da Tesouraria & Renda Territorial em Madeira Gasta
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: MadeiraEnvelhecida(
                    seed: 19,
                    padding:
                        const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatusJogador(
                              'BRANCO',
                              statusBranco.dinheiro,
                              dominioBranco.total,
                              turnoAtual == CorPeca.branco,
                              EstiloImperial.pergaminhoClaro,
                            ),
                            Text(
                              '❖',
                              style: TextStyle(
                                color: EstiloImperial.lataoOuro.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                            _buildStatusJogador(
                              'PRETO',
                              statusPreto.dinheiro,
                              dominioPreto.total,
                              turnoAtual == CorPeca.preto,
                              EstiloImperial.lataoClaro,
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // Legenda Cartográfica dos Terrenos Especiais
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.38),
                            border: Border.all(
                              color: EstiloImperial.lataoEscuro.withOpacity(0.6),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildLegendaTerreno(
                                'Piche',
                                '-£3',
                                const Color(0xFFB5A394),
                                const Color(0xFF171310),
                              ),
                              _buildLegendaTerreno(
                                'Carvão',
                                '+£4',
                                const Color(0xFFB0C4D8),
                                const Color(0xFF212B36),
                              ),
                              _buildLegendaTerreno(
                                'Fundição',
                                '+£8',
                                EstiloImperial.lataoClaro,
                                EstiloImperial.azulPrussia,
                              ),
                              _buildLegendaTerreno(
                                'Ouro',
                                '+£14',
                                EstiloImperial.lataoClaro,
                                EstiloImperial.carmesimImperial,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tabuleiro Cartográfico Envelhecido em Nogueira e Marfim
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 6.0),
                        padding: const EdgeInsets.all(5.0),
                        decoration: BoxDecoration(
                          color: EstiloImperial.mognoEscuro,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            if (estaEmXeque)
                              BoxShadow(
                                  color: EstiloImperial.carmesimImperial
                                      .withOpacity(0.85),
                                  blurRadius: 18,
                                  spreadRadius: 3)
                            else if (emModoSelecao)
                              BoxShadow(
                                  color: EstiloImperial.azulPrussia
                                      .withOpacity(0.85),
                                  blurRadius: 18,
                                  spreadRadius: 3)
                            else
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.88),
                                  blurRadius: 14,
                                  spreadRadius: 3),
                          ],
                          border: Border.all(
                            color: estaEmXeque
                                ? const Color(0xFFC43235)
                                : emModoSelecao
                                    ? const Color(0xFF3E78A3)
                                    : EstiloImperial.lataoOuro,
                            width: 3.5,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: EstiloImperial.lataoEscuro,
                              width: 1.5,
                            ),
                          ),
                          child: Stack(
                            children: [
                              GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 8),
                                itemCount: 64,
                                itemBuilder: (context, gridIndex) {
                                  final int index =
                                      (turnoAtual == CorPeca.preto)
                                          ? (63 - gridIndex)
                                          : gridIndex;
                                  final int linha = index ~/ 8;
                                  final int coluna = index % 8;
                                  final bool eCasaBranca =
                                      (linha + coluna) % 2 == 0;
                                  final Peca? peca = tabuleiro[index];
                                  final TipoTerrenoEspecial? terrenoEspecial =
                                      terrenosEspeciais[index];

                                  final bool mostrarRank = gridIndex % 8 == 0;
                                  final bool mostrarFile = gridIndex >= 56;
                                  final String textoRank = '${8 - linha}';
                                  final String textoFile =
                                      String.fromCharCode(65 + coluna);

                                  bool podeInvocarAqui =
                                      cartaSelecionada != null &&
                                          !tabuleiro.containsKey(index) &&
                                          ((turnoAtual == CorPeca.branco &&
                                                  linha >= 6) ||
                                              (turnoAtual == CorPeca.preto &&
                                                  linha <= 1));

                                  bool movimentoValidoParaCasa = false;
                                  bool casaAmeacadaParaRei = false;

                                  if (indicePecaSelecionada != null) {
                                    Peca pecaSelecionadaNoTabuleiro =
                                        tabuleiro[indicePecaSelecionada!]!;
                                    movimentoValidoParaCasa = _movimentoValido(
                                      indicePecaSelecionada!,
                                      index,
                                      pecaSelecionadaNoTabuleiro.tipo,
                                      pecaSelecionadaNoTabuleiro.cor,
                                    );

                                    if (pecaSelecionadaNoTabuleiro.tipo ==
                                            TipoPeca.rei &&
                                        movimentoValidoParaCasa) {
                                      if (_casaSobAtaque(
                                          index, turnoAtual.oposta)) {
                                        casaAmeacadaParaRei = true;
                                      }
                                    }
                                  }

                                  bool estaMovendo =
                                      indicePecaSelecionada == index;
                                  bool eOReiEmXeque = index == posReiEmXeque;
                                  bool alvoValidoEfeito = emModoSelecao &&
                                      _casaValidaParaModo(index, modoSelecao);

                                  Color corCasa = eCasaBranca
                                      ? EstiloImperial.casaClara
                                      : EstiloImperial.casaEscura;
                                  BoxBorder? bordaCasa = Border.all(
                                    color: Colors.black.withOpacity(0.18),
                                    width: 0.4,
                                  );

                                  if (terrenoEspecial != null) {
                                    switch (terrenoEspecial) {
                                      case TipoTerrenoEspecial.pocoDePiche:
                                        corCasa = Color.lerp(corCasa,
                                            const Color(0xFF211912), 0.38)!;
                                        bordaCasa = Border.all(
                                            color: const Color(0xFF473729),
                                            width: 1.0);
                                        break;
                                      case TipoTerrenoEspecial.minaCarvao:
                                        corCasa = Color.lerp(corCasa,
                                            const Color(0xFF2D3640), 0.28)!;
                                        bordaCasa = Border.all(
                                            color: const Color(0xFF4E5E70),
                                            width: 1.0);
                                        break;
                                      case TipoTerrenoEspecial.fundicaoAco:
                                        corCasa = Color.lerp(corCasa,
                                            const Color(0xFF80471B), 0.28)!;
                                        bordaCasa = Border.all(
                                            color: EstiloImperial.lataoOuro,
                                            width: 1.1);
                                        break;
                                      case TipoTerrenoEspecial.minaOuro:
                                        corCasa = Color.lerp(corCasa,
                                            const Color(0xFFB88825), 0.34)!;
                                        bordaCasa = Border.all(
                                            color:
                                                EstiloImperial.carmesimImperial,
                                            width: 1.4);
                                        break;
                                    }
                                  }

                                  if (alvoValidoEfeito) {
                                    corCasa = const Color(0xFF204866);
                                    bordaCasa = Border.all(
                                        color: EstiloImperial.lataoClaro,
                                        width: 2.2);
                                  } else if (eOReiEmXeque) {
                                    corCasa = const Color(0xFF691418);
                                    bordaCasa = Border.all(
                                        color: const Color(0xFFD43D42),
                                        width: 2.6);
                                  } else if (podeInvocarAqui) {
                                    corCasa = const Color(0xFF21472E);
                                    bordaCasa = Border.all(
                                        color: EstiloImperial.lataoClaro,
                                        width: 1.6);
                                  } else if (casaAmeacadaParaRei) {
                                    corCasa = EstiloImperial.carmesimImperial
                                        .withOpacity(0.65);
                                  }

                                  if (estaMovendo) {
                                    corCasa = const Color(0xFF9C7222);
                                    bordaCasa = Border.all(
                                        color: EstiloImperial.pergaminhoClaro,
                                        width: 2.2);
                                  }

                                  final Color corCoordenada = eCasaBranca
                                      ? EstiloImperial.casaEscura
                                          .withOpacity(0.82)
                                      : EstiloImperial.casaClara
                                          .withOpacity(0.82);

                                  return GestureDetector(
                                    onTap: () => _cliqueCasa(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: corCasa,
                                        border: bordaCasa,
                                      ),
                                      child: Stack(
                                        children: [
                                          if (terrenoEspecial != null)
                                            Positioned.fill(
                                              child: TerrenoEspecialWidget(
                                                terreno: terrenoEspecial,
                                              ),
                                            ),
                                          if (mostrarRank)
                                            Positioned(
                                              top: 1.5,
                                              left: 2.5,
                                              child: Text(
                                                textoRank,
                                                style: EstiloImperial.titulo(
                                                  size: 8.5,
                                                  color: corCoordenada,
                                                  letterSpacing: 0,
                                                ),
                                              ),
                                            ),
                                          if (mostrarFile)
                                            Positioned(
                                              bottom: 1,
                                              right: 2.5,
                                              child: Text(
                                                textoFile,
                                                style: EstiloImperial.titulo(
                                                  size: 8.5,
                                                  color: corCoordenada,
                                                  letterSpacing: 0,
                                                ),
                                              ),
                                            ),
                                          if (terrenoEspecial != null)
                                            Positioned(
                                              bottom: 1.5,
                                              left: 2,
                                              child: _buildBadgeTerrenoEspecial(
                                                  terrenoEspecial),
                                            ),
                                          if (peca != null)
                                            Center(
                                              child: LayoutBuilder(
                                                builder:
                                                    (context, constraints) {
                                                  return PecaImperialWidget(
                                                    tipo: peca.tipo,
                                                    cor: peca.cor,
                                                    tamanho:
                                                        constraints.maxWidth *
                                                            0.80,
                                                  );
                                                },
                                              ),
                                            ),
                                          if (peca != null && peca.protegida)
                                            Positioned(
                                              top: 2,
                                              right: 2,
                                              child: BrasaoProtecaoWidget(
                                                permanente:
                                                    peca.protecaoPermanente,
                                              ),
                                            ),
                                          if (peca != null && peca.paralisada)
                                            const Positioned.fill(
                                              child: CorrentesParalisiaWidget(),
                                            ),
                                          if (movimentoValidoParaCasa &&
                                              !casaAmeacadaParaRei)
                                            Center(
                                              child: Transform.rotate(
                                                angle: pi / 4,
                                                child: Container(
                                                  width: 11,
                                                  height: 11,
                                                  decoration: BoxDecoration(
                                                    color: EstiloImperial
                                                        .carmesimImperial
                                                        .withOpacity(0.45),
                                                    border: Border.all(
                                                      color: EstiloImperial
                                                          .lataoClaro,
                                                      width: 1.4,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _PatinaTabuleiroPainter(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Mesa de Feltro Antigo Escurecido e Moldura de Latão (Mão de Cartas)
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.3,
                      colors: [
                        EstiloImperial.feltroVerde,
                        EstiloImperial.feltroVerdeEscuro,
                        Color(0xFF070E0A),
                      ],
                    ),
                    border: const Border(
                      top: BorderSide(
                        color: EstiloImperial.lataoOuro,
                        width: 2.5,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.85),
                        blurRadius: 14,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  height: 162,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '✦ ORDENS DE MOBILIZAÇÃO ✦',
                            style: EstiloImperial.titulo(
                              size: 12,
                              color: EstiloImperial.pergaminhoClaro,
                              letterSpacing: 1.2,
                            ),
                          ),
                          BotaoAntigo(
                            label: 'PASSAR TURNO',
                            icone: Icons.double_arrow,
                            corFundo: EstiloImperial.carmesimImperial,
                            onPressed: (exibeEscolhaDeCarta ||
                                    escolhendoPromocaoPeao ||
                                    emModoSelecao)
                                ? null
                                : _finalizarTurno,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: maoAtual.length,
                          itemBuilder: (context, index) {
                            final carta = maoAtual[index];
                            final bool estaSelecionada =
                                indiceCartaSelecionada == index;
                            final int custoAtual = _calcularCustoCarta(
                                carta, turnoAtual,
                                consumir: false);
                            final bool bloqueada =
                                _status(turnoAtual).bloqueioNavalRodadas > 0 &&
                                    carta.custo >= 50;

                            Color corLacre = EstiloImperial.verdeTesouro;
                            if (bloqueada) {
                              corLacre = const Color(0xFF3A332D);
                            } else if (custoAtual < carta.custo) {
                              corLacre = EstiloImperial.azulPrussia;
                            } else if (custoAtual > carta.custo) {
                              corLacre = EstiloImperial.carmesimImperial;
                            }

                            return GestureDetector(
                              onTap: () {
                                if (exibeEscolhaDeCarta ||
                                    escolhendoPromocaoPeao ||
                                    emModoSelecao) {
                                  return;
                                }
                                setState(() {
                                  if (estaSelecionada) {
                                    cartaSelecionada = null;
                                    indiceCartaSelecionada = null;
                                  } else {
                                    cartaSelecionada = carta;
                                    indiceCartaSelecionada = index;
                                    indicePecaSelecionada = null;
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 96,
                                margin: EdgeInsets.only(
                                  right: 10,
                                  top: estaSelecionada ? 0 : 5,
                                  bottom: estaSelecionada ? 6 : 2,
                                ),
                                child: PergaminhoEnvelhecido(
                                  seed: 100 + index * 17 + carta.custo,
                                  destacado: estaSelecionada,
                                  corBorda: estaSelecionada
                                      ? EstiloImperial.carmesimImperial
                                      : EstiloImperial.lataoEscuro,
                                  larguraBorda: estaSelecionada ? 2.4 : 1.5,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 4),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      PecaImperialWidget(
                                        tipo: carta.tipoPeca,
                                        cor: turnoAtual,
                                        tamanho: 33,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        carta.tipoPeca.nome.toUpperCase(),
                                        style: EstiloImperial.titulo(
                                          size: 10,
                                          color: EstiloImperial.tintaSepia,
                                          letterSpacing: 0.7,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      SeloCeraBadge(
                                        texto: bloqueada
                                            ? 'BLOQ.'
                                            : '£ $custoAtual',
                                        corCera: corLacre,
                                        fontSize: 9.8,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 1.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Faixa de Alerta de XEQUE (Lacre Carmesim & Latão)
            if (estaEmXeque &&
                !exibeEscolhaDeCarta &&
                !escolhendoPromocaoPeao &&
                !emModoSelecao)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
                  decoration: const BoxDecoration(
                    color: EstiloImperial.carmesimImperial,
                    border: Border(
                      bottom: BorderSide(
                          color: EstiloImperial.lataoClaro, width: 1.8),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black87,
                          blurRadius: 6,
                          offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          '✦ ALERTA MÁXIMO: SOBERANO EM XEQUE! DEFENDA O TRONO! ✦',
                          textAlign: TextAlign.center,
                          style: EstiloImperial.titulo(
                            size: 11.5,
                            color: EstiloImperial.pergaminhoClaro,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Faixa de Ordem Tática (Azul Prússia & Latão)
            if (emModoSelecao && !exibeEscolhaDeCarta && !escolhendoPromocaoPeao)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
                  decoration: const BoxDecoration(
                    color: EstiloImperial.azulPrussia,
                    border: Border(
                      bottom: BorderSide(
                          color: EstiloImperial.lataoClaro, width: 1.8),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black87,
                          blurRadius: 6,
                          offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _textoBannerSelecao(),
                          textAlign: TextAlign.center,
                          style: EstiloImperial.titulo(
                            size: 11.5,
                            color: EstiloImperial.pergaminhoClaro,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Despacho Telegráfico em Pergaminho Manchado (Notificação)
            if (mensagemNotificacao != null)
              Positioned(
                top: (emModoSelecao || estaEmXeque) ? 42 : 10,
                left: 12,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: mensagemNotificacao != null ? 1.0 : 0.0,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 270),
                    child: PergaminhoEnvelhecido(
                      seed: 55,
                      corBorda: EstiloImperial.carmesimImperial,
                      larguraBorda: 1.8,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '❖ ',
                            style: TextStyle(
                              color: EstiloImperial.carmesimImperial,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              mensagemNotificacao!,
                              style: EstiloImperial.corpo(
                                size: 12,
                                color: EstiloImperial.tintaSepia,
                                weight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Modal de Promoção / Patente Militar em Madeira e Pergaminho Antigo
            if (escolhendoPromocaoPeao)
              Container(
                color: Colors.black.withOpacity(0.84),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: MadeiraEnvelhecida(
                      seed: 44,
                      larguraBorda: 2.5,
                      padding: const EdgeInsets.all(20.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              promocaoPorDecreto
                                  ? '✦ DECRETO DE PROMOÇÃO ✦'
                                  : '✦ PATENTE DE OFICIAL ✦',
                              style: EstiloImperial.titulo(
                                size: 18,
                                color: EstiloImperial.lataoClaro,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Selecione a patente para promover seu Peão:',
                              textAlign: TextAlign.center,
                              style: EstiloImperial.corpo(
                                size: 13.5,
                                color: EstiloImperial.pergaminhoMedio,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: (promocaoPorDecreto
                                      ? [
                                          TipoPeca.cavalo,
                                          TipoPeca.bispo,
                                          TipoPeca.torre,
                                        ]
                                      : [
                                          TipoPeca.rainha,
                                          TipoPeca.torre,
                                          TipoPeca.bispo,
                                          TipoPeca.cavalo,
                                        ])
                                  .map((tipo) {
                                return GestureDetector(
                                  onTap: () => _promoverPeao(tipo),
                                  child: SizedBox(
                                    width: 112,
                                    child: PergaminhoEnvelhecido(
                                      seed: 200 + tipo.index * 13,
                                      corBorda: EstiloImperial.lataoOuro,
                                      larguraBorda: 2.0,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 10),
                                      child: Column(
                                        children: [
                                          PecaImperialWidget(
                                            tipo: tipo,
                                            cor: turnoAtual,
                                            tamanho: 44,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            tipo.nome.toUpperCase(),
                                            style: EstiloImperial.titulo(
                                              size: 12,
                                              color: EstiloImperial.tintaSepia,
                                              letterSpacing: 0.9,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Modal de Conselho de Guerra (Escolha de Peça & Decreto/Efeito)
            if (exibeEscolhaDeCarta)
              Container(
                color: Colors.black.withOpacity(0.84),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: MadeiraEnvelhecida(
                      seed: 61,
                      larguraBorda: 2.5,
                      padding: const EdgeInsets.all(20.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              escolhendoEfeito
                                  ? '✦ DECRETO DO CONSELHO ✦'
                                  : '✦ RECRUTAMENTO DE UNIDADE ✦',
                              textAlign: TextAlign.center,
                              style: EstiloImperial.titulo(
                                size: 17,
                                color: EstiloImperial.lataoClaro,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '— ❖ —',
                              style: EstiloImperial.corpo(
                                size: 13,
                                color: EstiloImperial.lataoOuro,
                              ),
                            ),

                            if (numeroRodada > 1) ...[
                              const SizedBox(height: 10),
                              PergaminhoEnvelhecido(
                                seed: 88 + numeroRodada,
                                corBorda: EstiloImperial.lataoOuro,
                                larguraBorda: 1.3,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Column(
                                  children: [
                                    Text(
                                      'LIVRO-CAIXA DO CICLO',
                                      style: EstiloImperial.titulo(
                                        size: 10.5,
                                        color: EstiloImperial.carmesimImperial,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Subsídio: +£$ultimoSubsidioBase  •  Terrenos ($ultimosTerrenosDominados): ${ultimaRendaTerritorios >= 0 ? "+£$ultimaRendaTerritorios" : "-£${ultimaRendaTerritorios.abs()}"}',
                                      textAlign: TextAlign.center,
                                      style: EstiloImperial.corpo(
                                        size: 12,
                                        color: EstiloImperial.tintaSepia,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'TOTAL ARRECADADO: +£${max(0, ultimoSubsidioBase + ultimaRendaTerritorios)}',
                                      style: EstiloImperial.titulo(
                                        size: 12,
                                        color: EstiloImperial.verdeTesouro,
                                        letterSpacing: 0.9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),
                            if (!escolhendoEfeito)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: opcoesEscolhaAtual
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final int idx = entry.key;
                                  final Carta carta = entry.value;
                                  return GestureDetector(
                                    onTap: () => _escolherCarta(carta),
                                    child: SizedBox(
                                      width: 126,
                                      child: PergaminhoEnvelhecido(
                                        seed: 310 + idx * 29 + numeroRodada,
                                        corBorda: EstiloImperial.lataoOuro,
                                        larguraBorda: 2.0,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14, horizontal: 8),
                                        child: Column(
                                          children: [
                                            PecaImperialWidget(
                                              tipo: carta.tipoPeca,
                                              cor: turnoAtual,
                                              tamanho: 48,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              carta.tipoPeca.nome
                                                  .toUpperCase(),
                                              style: EstiloImperial.titulo(
                                                size: 12.5,
                                                color:
                                                    EstiloImperial.tintaSepia,
                                                letterSpacing: 0.9,
                                              ),
                                            ),
                                            const SizedBox(height: 7),
                                            SeloCeraBadge(
                                              texto: '£ ${carta.custo}',
                                              corCera:
                                                  EstiloImperial.verdeTesouro,
                                              fontSize: 11.5,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 11,
                                                      vertical: 3),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              Column(
                                children: opcoesEfeitoAtual
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final int idx = entry.key;
                                  final CartaEfeito efeito = entry.value;
                                  final Color corCard =
                                      corRaridade(efeito.raridade);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6.0),
                                    child: GestureDetector(
                                      onTap: () => _escolherEfeito(efeito),
                                      child: PergaminhoEnvelhecido(
                                        seed: 420 + idx * 37 + numeroRodada,
                                        corBorda: corCard,
                                        larguraBorda: 2.2,
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    efeito.titulo.toUpperCase(),
                                                    style: EstiloImperial.titulo(
                                                      size: 13.5,
                                                      color: EstiloImperial
                                                          .tintaSepia,
                                                      letterSpacing: 0.8,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                SeloCeraBadge(
                                                  texto: efeito.raridade
                                                      .toUpperCase(),
                                                  corCera: corCard,
                                                  fontSize: 9.5,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2.5),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              efeito.descricao,
                                              style: EstiloImperial.corpo(
                                                size: 13,
                                                color: EstiloImperial.tintaSepia,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Placa Central de Proclamação de Turno em Pergaminho Selado
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _mostrarAvisoTurno ? 1.0 : 0.0,
                  child: Center(
                    child: turnoAtual == CorPeca.branco
                        ? PergaminhoEnvelhecido(
                            seed: 701 + numeroRodada,
                            corBorda: EstiloImperial.lataoOuro,
                            larguraBorda: 3.0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PecaImperialWidget(
                                  tipo: TipoPeca.rei,
                                  cor: turnoAtual,
                                  tamanho: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'IMPÉRIO ${turnoAtual.nome.toUpperCase()}',
                                  style: EstiloImperial.titulo(
                                    size: 21,
                                    letterSpacing: 2.2,
                                    color: EstiloImperial.tintaSepia,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '— SUA VEZ DE COMANDAR —',
                                  style: EstiloImperial.corpo(
                                    size: 12,
                                    fontStyle: FontStyle.italic,
                                    color: EstiloImperial.carmesimImperial,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : MadeiraEnvelhecida(
                            seed: 702 + numeroRodada,
                            corBorda: EstiloImperial.lataoOuro,
                            larguraBorda: 3.0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PecaImperialWidget(
                                  tipo: TipoPeca.rei,
                                  cor: turnoAtual,
                                  tamanho: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'IMPÉRIO ${turnoAtual.nome.toUpperCase()}',
                                  style: EstiloImperial.titulo(
                                    size: 21,
                                    letterSpacing: 2.2,
                                    color: EstiloImperial.pergaminhoClaro,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '— SUA VEZ DE COMANDAR —',
                                  style: EstiloImperial.corpo(
                                    size: 12,
                                    fontStyle: FontStyle.italic,
                                    color: EstiloImperial.lataoClaro,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeTerrenoEspecial(TipoTerrenoEspecial terreno) {
    Color fundo;
    Color borda;
    Color texto;

    switch (terreno) {
      case TipoTerrenoEspecial.pocoDePiche:
        fundo = const Color(0xEE14100D);
        borda = const Color(0xFF8C7258);
        texto = const Color(0xFFD6BE9E);
        break;
      case TipoTerrenoEspecial.minaCarvao:
        fundo = const Color(0xEE1C242B);
        borda = const Color(0xFF7B91A6);
        texto = const Color(0xFFD8E4F0);
        break;
      case TipoTerrenoEspecial.fundicaoAco:
        fundo = const Color(0xEE17344A);
        borda = EstiloImperial.lataoOuro;
        texto = EstiloImperial.pergaminhoClaro;
        break;
      case TipoTerrenoEspecial.minaOuro:
        fundo = const Color(0xEE6E1418);
        borda = EstiloImperial.lataoClaro;
        texto = EstiloImperial.lataoClaro;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
      decoration: BoxDecoration(
        color: fundo,
        border: Border.all(color: borda, width: 0.65),
      ),
      child: Text(
        terreno.textoRenda,
        style: EstiloImperial.titulo(
          size: 7.2,
          color: texto,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _buildLegendaTerreno(
      String nome, String valor, Color corTexto, Color corFundoBadge) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$nome ',
          style: EstiloImperial.corpo(
            size: 9.8,
            color: EstiloImperial.pergaminhoMedio,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
          decoration: BoxDecoration(
            color: corFundoBadge,
            border: Border.all(
              color: EstiloImperial.lataoOuro.withOpacity(0.75),
              width: 0.7,
            ),
          ),
          child: Text(
            valor,
            style: EstiloImperial.titulo(
              size: 9.2,
              color: corTexto,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusJogador(String nome, int saldo, int rendaTerritorial,
      bool eTurnoAtual, Color corDestaque) {
    final String textoRenda = rendaTerritorial >= 0
        ? '(+£$rendaTerritorial)'
        : '(-£${rendaTerritorial.abs()})';
    final Color corRenda = rendaTerritorial > 0
        ? EstiloImperial.lataoClaro
        : rendaTerritorial < 0
            ? const Color(0xFFE07A70)
            : EstiloImperial.pergaminhoEscuro.withOpacity(0.75);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: eTurnoAtual
            ? EstiloImperial.carmesimImperial.withOpacity(0.45)
            : Colors.black.withOpacity(0.28),
        border: Border.all(
          color: eTurnoAtual
              ? EstiloImperial.lataoClaro
              : EstiloImperial.lataoEscuro.withOpacity(0.55),
          width: eTurnoAtual ? 1.6 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$nome: ',
            style: EstiloImperial.titulo(
              size: 12,
              letterSpacing: 0.8,
              color: eTurnoAtual
                  ? corDestaque
                  : EstiloImperial.pergaminhoMedio.withOpacity(0.75),
            ),
          ),
          SeloCeraBadge(
            texto: '£$saldo',
            corCera: EstiloImperial.verdeTesouro,
            fontSize: 11.5,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          ),
          const SizedBox(width: 5),
          Text(
            textoRenda,
            style: EstiloImperial.titulo(
              size: 10.8,
              color: corRenda,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}