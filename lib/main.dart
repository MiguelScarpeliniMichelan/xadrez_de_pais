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

  String simbolo(CorPeca cor) {
    switch (this) {
      case TipoPeca.rei:
        return cor == CorPeca.branco ? '♔' : '♚';
      case TipoPeca.rainha:
        return cor == CorPeca.branco ? '♕' : '♛';
      case TipoPeca.torre:
        return cor == CorPeca.branco ? '♖' : '♜';
      case TipoPeca.bispo:
        return cor == CorPeca.branco ? '♗' : '♝';
      case TipoPeca.cavalo:
        return cor == CorPeca.branco ? '♘' : '♞';
      case TipoPeca.peao:
        return cor == CorPeca.branco ? '♙' : '♟';
    }
  }
}

Color corRaridade(String raridade) {
  switch (raridade) {
    case 'Rara':
      return Colors.blue.shade700;
    case 'Épica':
      return Colors.purple.shade700;
    case 'Comum':
    default:
      return Colors.amber.shade800;
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
  int dinheiro = 30;
  List<Carta> mao = [];
  double descontoPercentualProximaPeca = 0.0;
  int descontoFixoProximaPeca = 0;
  int descontoPeaoProximaCompra = 0;
  int taxaExtraProximaPeca = 0;
  int bonusProximaRodada = 0;
  bool comercioAtivo = false;
  int companhiaMonopolistaRodadas = 0;
  int impostoSeloCargas = 0;
  int inflacaoRodadas = 0;
  int bloqueioNavalRodadas = 0;
  bool mobilizacaoRapidaAtiva = false;

  void resetar() {
    dinheiro = 30;
    mao.clear();
    descontoPercentualProximaPeca = 0.0;
    descontoFixoProximaPeca = 0;
    descontoPeaoProximaCompra = 0;
    taxaExtraProximaPeca = 0;
    bonusProximaRodada = 0;
    comercioAtivo = false;
    companhiaMonopolistaRodadas = 0;
    impostoSeloCargas = 0;
    inflacaoRodadas = 0;
    bloqueioNavalRodadas = 0;
    mobilizacaoRapidaAtiva = false;
  }
}

void main() {
  runApp(const MaterialApp(
    home: TabuleiroXadrez(),
    debugShowCheckedModeBanner: false,
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
    // ==================== COMUNS ====================
    CartaEfeito(
      titulo: 'Investimento',
      descricao: 'Receba 20 moedas extras imediatamente.',
      raridade: 'Comum',
      aplicarEfeito: (s) => s._status(s.turnoAtual).dinheiro += 20,
    ),
    CartaEfeito(
      titulo: 'Salário Extra',
      descricao: 'Receba 15 moedas adicionais nesta rodada.',
      raridade: 'Comum',
      aplicarEfeito: (s) => s._status(s.turnoAtual).dinheiro += 15,
    ),
    CartaEfeito(
      titulo: 'Tesouro Escondido',
      descricao: 'Ganhe entre 10 e 25 moedas aleatórias extras.',
      raridade: 'Comum',
      aplicarEfeito: (s) {
        int extra = 10 + s._random.nextInt(16);
        s._status(s.turnoAtual).dinheiro += extra;
      },
    ),
    CartaEfeito(
      titulo: 'Economia de Tempo',
      descricao: 'Sua próxima compra de peça tem desconto de 10 moedas.',
      raridade: 'Comum',
      aplicarEfeito: (s) {
        s._status(s.turnoAtual).descontoFixoProximaPeca += 10;
      },
    ),
    CartaEfeito(
      titulo: 'Promoção',
      descricao: 'Sua próxima peça custa 20% menos.',
      raridade: 'Comum',
      aplicarEfeito: (s) {
        final st = s._status(s.turnoAtual);
        st.descontoPercentualProximaPeca =
            max(st.descontoPercentualProximaPeca, 0.20);
      },
    ),
    CartaEfeito(
      titulo: 'Poupança',
      descricao:
          'Guarde 20 moedas agora e receba 30 moedas no início da sua próxima rodada.',
      raridade: 'Comum',
      podeUsar: (s) => s._status(s.turnoAtual).dinheiro >= 20,
      aplicarEfeito: (s) {
        final st = s._status(s.turnoAtual);
        if (st.dinheiro >= 20) {
          st.dinheiro -= 20;
          st.bonusProximaRodada += 30;
        }
      },
    ),
    CartaEfeito(
      titulo: 'Comércio',
      descricao: 'Receba 10 moedas sempre que capturar uma peça adversária.',
      raridade: 'Comum',
      podeUsar: (s) => !s._status(s.turnoAtual).comercioAtivo,
      aplicarEfeito: (s) {
        s._status(s.turnoAtual).comercioAtivo = true;
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
          'Os recursos das províncias fluem para a metrópole. Receba 20 moedas imediatamente.',
      raridade: 'Comum',
      aplicarEfeito: (s) => s._status(s.turnoAtual).dinheiro += 20,
    ),
    CartaEfeito(
      titulo: 'Corvée',
      descricao:
          'Sacrifique um Peão seu no tabuleiro para receber 30 moedas imediatamente.',
      raridade: 'Comum',
      podeUsar: (s) => s._existeAlvoParaModo(ModoSelecao.corvee),
      aplicarEfeito: (s) => s._iniciarModoSelecao(ModoSelecao.corvee),
    ),
    CartaEfeito(
      titulo: 'Tarifa Alfandegária',
      descricao:
          'A próxima peça invocada pelo adversário custa 10 moedas a mais.',
      raridade: 'Comum',
      aplicarEfeito: (s) {
        s._status(s.turnoAtual.oposta).taxaExtraProximaPeca += 10;
      },
    ),
    CartaEfeito(
      titulo: 'Alistamento das Colônias',
      descricao: 'Sua próxima invocação de Peão custa 10 moedas a menos.',
      raridade: 'Comum',
      aplicarEfeito: (s) {
        s._status(s.turnoAtual).descontoPeaoProximaCompra += 10;
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

    // ==================== RARAS ====================
    CartaEfeito(
      titulo: 'Rei do Mercado',
      descricao: 'Receba 40 moedas extras imediatamente.',
      raridade: 'Rara',
      aplicarEfeito: (s) => s._status(s.turnoAtual).dinheiro += 40,
    ),
    CartaEfeito(
      titulo: 'Contrato Especial',
      descricao:
          'Receba 25 moedas agora e mais 20 moedas na sua próxima rodada.',
      raridade: 'Rara',
      aplicarEfeito: (s) {
        final st = s._status(s.turnoAtual);
        st.dinheiro += 25;
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
      descricao: 'Compre sua próxima peça com 35% de desconto.',
      raridade: 'Rara',
      aplicarEfeito: (s) {
        final st = s._status(s.turnoAtual);
        st.descontoPercentualProximaPeca =
            max(st.descontoPercentualProximaPeca, 0.35);
      },
    ),
    CartaEfeito(
      titulo: 'Inflação',
      descricao:
          'Os preços das peças do adversário aumentam 20% durante 1 rodada.',
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
          'Acordo sob mira de mosquetes. Roube 20 moedas do adversário.',
      raridade: 'Rara',
      aplicarEfeito: (s) => s._roubarDinheiro(20),
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
          'Escolha um Peão, Cavalo ou Bispo seu para ficar protegido até o início do seu próximo turno.',
      raridade: 'Rara',
      podeUsar: (s) => s._existeAlvoParaModo(ModoSelecao.protetoradoFantoche),
      aplicarEfeito: (s) =>
          s._iniciarModoSelecao(ModoSelecao.protetoradoFantoche),
    ),
    CartaEfeito(
      titulo: 'Mobilização Rápida',
      descricao:
          'Neste turno, invocar um Cavalo ou Bispo custa apenas 1 ação em vez de 2.',
      raridade: 'Rara',
      aplicarEfeito: (s) {
        s._status(s.turnoAtual).mobilizacaoRapidaAtiva = true;
      },
    ),

    // ==================== ÉPICAS ====================
    CartaEfeito(
      titulo: 'Fortuna Real',
      descricao: 'Receba 75 moedas imediatamente.',
      raridade: 'Épica',
      aplicarEfeito: (s) => s._status(s.turnoAtual).dinheiro += 75,
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
          'As reservas reais financiam uma ofensiva. Receba 60 moedas imediatamente.',
      raridade: 'Épica',
      aplicarEfeito: (s) => s._status(s.turnoAtual).dinheiro += 60,
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
          'Escolha 1 Peão seu que já tenha cruzado a metade do tabuleiro e promova-o para Cavalo ou Bispo.',
      raridade: 'Épica',
      podeUsar: (s) => s._existeAlvoParaModo(ModoSelecao.decretoPromocao),
      aplicarEfeito: (s) => s._iniciarModoSelecao(ModoSelecao.decretoPromocao),
    ),
    CartaEfeito(
      titulo: 'Bloqueio Naval',
      descricao:
          'Durante 1 rodada, o adversário fica impedido de invocar peças que custem 50 moedas ou mais.',
      raridade: 'Épica',
      aplicarEfeito: (s) {
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

  void _roubarDinheiro(int quantia) {
    final atual = _status(turnoAtual);
    final oponente = _status(turnoAtual.oposta);
    final int roubo = min(quantia, oponente.dinheiro);
    oponente.dinheiro -= roubo;
    atual.dinheiro += roubo;
  }

  void _iniciarModoSelecao(ModoSelecao modo) {
    if (!_existeAlvoParaModo(modo)) {
      _mostrarSnackBar('Nenhum alvo válido disponível no tabuleiro!');
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
    final int rowTras = (turnoAtual == CorPeca.branco) ? origRow + 1 : origRow - 1;

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
    }
  }

  String _textoBannerSelecao() {
    switch (modoSelecao) {
      case ModoSelecao.protecaoTemporaria:
        return '🛡️ PROTEÇÃO: Clique em uma peça sua para protegê-la por 1 rodada!';
      case ModoSelecao.protecaoPermanenteMenor:
        return '🛡️ REFORÇO MILITAR: Escolha um Peão, Cavalo ou Bispo seu para proteção permanente!';
      case ModoSelecao.protecaoPeaoPermanente:
        return '👑 HEGEMONIA IMPERIAL: Escolha 1 Peão seu para receber proteção permanente!';
      case ModoSelecao.paralisia2Rodadas:
        return '❄️ PODER ABSOLUTO: Clique em uma peça inimiga (não o Rei) para congelar por 2 rodadas!';
      case ModoSelecao.corvee:
        return '⚒️ CORVÉE: Clique em um Peão seu para sacrificá-lo por 30 moedas!';
      case ModoSelecao.ferroviaOrigem:
        return '🚂 CONCESSÃO FERROVIÁRIA: Escolha uma peça sua (exceto o Rei) para reposicionar!';
      case ModoSelecao.ferroviaDestino:
        return '🚂 CONCESSÃO FERROVIÁRIA: Clique em uma casa destacada ao lado ou atrás!';
      case ModoSelecao.suborno:
        return '💰 SUBORNO DE GUARNIÇÃO: Clique em um Peão inimigo para convertê-lo!';
      case ModoSelecao.canhoneiras:
        return '⚓ CANHONEIRAS: Escolha uma peça inimiga (exceto o Rei) nas 4 fileiras centrais!';
      case ModoSelecao.protetoradoFantoche:
        return '🛡️ PROTETORADO FANTOCHE: Escolha um Peão, Cavalo ou Bispo seu para proteger!';
      case ModoSelecao.conferenciaPartilha:
        return '📜 CONFERÊNCIA DE PARTILHA: Escolha uma peça inimiga (exceto Rei/Rainha) para devolver à mão!';
      case ModoSelecao.decretoPromocao:
        return '🎖️ DECRETO DE PROMOÇÃO: Clique em um Peão seu além da metade do tabuleiro!';
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
    _timerNotificacao = Timer(const Duration(milliseconds: 1800), () {
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
        _status(turnoAtual).dinheiro += 30;
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
        _mostrarSnackBar('Peão promovido para ${novoTipo.nome} por Decreto!');
        _verificarEstadoFimDeJogo();
        return;
      }

      bool temCartaJogavel = _getMao(turnoAtual)
          .any((c) => _custoAcaoCarta(c, turnoAtual) <= acoesRestantes);

      if (acoesRestantes <= 0 || !temCartaJogavel) {
        _finalizarTurno();
      } else {
        _mostrarSnackBar(
            'Peão promovido para ${novoTipo.nome}! Você ainda tem $acoesRestantes ação restante!');
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
      custo = (custo * 1.2).round();
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
      {String motivo = 'ao capturar o Rei adversário!'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Fim de Jogo!'),
          ],
        ),
        content: Text('O Jogador ${vencedor.nome} venceu $motivo'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _iniciarJogo();
            },
            child: const Text('Jogar Novamente'),
          ),
        ],
      ),
    );
  }

  void _mostrarEmpateAfogamento(CorPeca jogadorSemMovimentos) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.handshake_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Empate por Afogamento!'),
          ],
        ),
        content: Text(
            'O Jogador ${jogadorSemMovimentos.nome} não está em xeque, mas não possui nenhum movimento válido. A partida terminou empatada!'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _iniciarJogo();
            },
            child: const Text('Jogar Novamente'),
          ),
        ],
      ),
    );
  }

  void _processarSelecaoCartaEfeito(int index) {
    final Peca? pecaNaCasa = tabuleiro[index];

    if (!_casaValidaParaModo(index, modoSelecao)) {
      _mostrarSnackBar('Alvo inválido para o efeito da carta!');
      return;
    }

    switch (modoSelecao) {
      case ModoSelecao.protecaoTemporaria:
      case ModoSelecao.protetoradoFantoche:
        pecaNaCasa!.rodadasProtegida = 1;
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('Peça protegida até o seu próximo turno!');
        break;

      case ModoSelecao.protecaoPermanenteMenor:
      case ModoSelecao.protecaoPeaoPermanente:
        pecaNaCasa!.rodadasProtegida = -1;
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('Proteção permanente aplicada!');
        break;

      case ModoSelecao.paralisia2Rodadas:
        pecaNaCasa!.rodadasParalisada = 2;
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('Peça inimiga congelada por 2 rodadas!');
        break;

      case ModoSelecao.canhoneiras:
        pecaNaCasa!.rodadasParalisada = 1;
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('Guarnição inimiga paralisada por 1 rodada!');
        break;

      case ModoSelecao.corvee:
        tabuleiro.remove(index);
        _status(turnoAtual).dinheiro += 30;
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('Peão sacrificado: +30 moedas recebidas!');
        break;

      case ModoSelecao.ferroviaOrigem:
        indiceOrigemFerrovia = index;
        modoSelecao = ModoSelecao.ferroviaDestino;
        _mostrarSnackBar('Escolha a casa vazia ao lado ou atrás!');
        return;

      case ModoSelecao.ferroviaDestino:
        final Peca peca = tabuleiro.remove(indiceOrigemFerrovia!)!;
        peca.posicao = index;
        tabuleiro[index] = peca;
        indiceOrigemFerrovia = null;
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('Peça reposicionada pela ferrovia!');
        break;

      case ModoSelecao.suborno:
        pecaNaCasa!.cor = turnoAtual;
        pecaNaCasa.rodadasParalisada = 1;
        pecaNaCasa.rodadasProtegida = 0;
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('Peão inimigo convertido para o seu exército!');
        break;

      case ModoSelecao.conferenciaPartilha:
        final TipoPeca tipoDevolvido = pecaNaCasa!.tipo;
        tabuleiro.remove(index);
        _status(turnoAtual.oposta)
            .mao
            .add(Carta(tipoDevolvido, tipoDevolvido.custoBase));
        modoSelecao = ModoSelecao.nenhum;
        _mostrarSnackBar('${tipoDevolvido.nome} devolvido à mão do oponente!');
        break;

      case ModoSelecao.decretoPromocao:
        modoSelecao = ModoSelecao.nenhum;
        indicePromocaoPeao = index;
        promocaoPorDecreto = true;
        escolhendoPromocaoPeao = true;
        return;

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
          _mostrarSnackBar('Rei em xeque! Defenda seu Rei!');
          return;
        }

        if (stAtual.bloqueioNavalRodadas > 0 && cartaSelecionada!.custo >= 50) {
          _mostrarSnackBar('Bloqueio Naval ativo! Só pode invocar Peões!');
          return;
        }

        final int custoAcao = _custoAcaoCarta(cartaSelecionada!, turnoAtual);
        if (acoesRestantes < custoAcao) {
          _mostrarSnackBar('Esta peça exige o turno completo!');
          return;
        }

        final int linha = index ~/ 8;
        bool ladoValido = (turnoAtual == CorPeca.branco && linha >= 6) ||
            (turnoAtual == CorPeca.preto && linha <= 1);

        if (!ladoValido) {
          _mostrarSnackBar(
              'Invoque apenas nas 2 primeiras fileiras da sua base!');
          return;
        }

        int custoFinal =
            _calcularCustoCarta(cartaSelecionada!, turnoAtual, consumir: false);

        if (stAtual.dinheiro < custoFinal) {
          _mostrarSnackBar('Dinheiro insuficiente!');
          return;
        }

        if (pecaNaCasa != null) {
          _mostrarSnackBar('Casa já ocupada!');
          return;
        }

        _calcularCustoCarta(cartaSelecionada!, turnoAtual, consumir: true);
        stAtual.dinheiro -= custoFinal;
        stAtual.mao.removeAt(indiceCartaSelecionada!);
        tabuleiro[index] =
            Peca(cartaSelecionada!.tipoPeca, turnoAtual, posicao: index);

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

        if (acoesRestantes <= 0 || (!temCartaJogavel && !podeMover)) {
          _finalizarTurno();
        } else if (podeMover && temCartaJogavel) {
          _mostrarSnackBar(
              'Você ainda pode invocar 1 carta de 1 ação ou mover 1 peça!');
        } else if (podeMover) {
          _mostrarSnackBar('Você ainda pode mover 1 peça neste turno!');
        } else if (temCartaJogavel) {
          _mostrarSnackBar('Você ainda pode invocar outra carta de 1 ação!');
        }
        return;
      }

      if (indicePecaSelecionada == null) {
        if (pecaNaCasa != null && pecaNaCasa.cor == turnoAtual) {
          if (jaMoveuPecaNesteTurno) {
            _mostrarSnackBar('Você já moveu uma peça neste turno!');
            return;
          }
          if (pecaNaCasa.paralisada) {
            _mostrarSnackBar('Esta peça está paralisada!');
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
          _mostrarSnackBar('Esta peça está paralisada!');
          return;
        }
        indicePecaSelecionada = index;
        return;
      }

      Peca pecaMovendo = tabuleiro[indicePecaSelecionada!]!;

      if (!_movimentoValido(indicePecaSelecionada!, index, pecaMovendo.tipo,
          pecaMovendo.cor)) {
        _mostrarSnackBar('Movimento inválido!');
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
        _mostrarSnackBar('O Rei fica em xeque!');
        return;
      }

      if (pecaMovendo.tipo == TipoPeca.rei &&
          _casaSobAtaque(index, turnoAtual.oposta)) {
        _mostrarSnackBar('Casa sob ataque inimigo!');
        return;
      }

      if (pecaNaCasa != null && pecaNaCasa.protegida) {
        _mostrarSnackBar('Peça inimiga protegida!');
        return;
      }

      if (pecaNaCasa != null) {
        int bonusCaptura = 0;
        if (stAtual.comercioAtivo) bonusCaptura += 10;
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

      final int linhaDestino = index ~/ 8;
      final bool chegouUltimaCasa = pecaMovendo.tipo == TipoPeca.peao &&
          ((pecaMovendo.cor == CorPeca.branco && linhaDestino == 0) ||
              (pecaMovendo.cor == CorPeca.preto && linhaDestino == 7));

      if (chegouUltimaCasa) {
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
        _finalizarTurno();
      } else {
        _mostrarSnackBar(
            'Você ainda pode invocar 1 carta de 1 ação neste turno!');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Carta> maoAtual = _getMao(turnoAtual);
    final bool estaEmXeque = _estaEmXeque(turnoAtual);
    final int? posReiEmXeque = estaEmXeque ? _encontrarRei(turnoAtual) : null;
    final bool emModoSelecao = modoSelecao != ModoSelecao.nenhum;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              turnoAtual == CorPeca.branco
                  ? Icons.brightness_7
                  : Icons.brightness_2,
              color: turnoAtual == CorPeca.branco
                  ? Colors.amber
                  : Colors.blueGrey.shade200,
            ),
            const SizedBox(width: 10),
            Text(
              'Rodada $numeroRodada - ${turnoAtual.nome} (${acoesRestantes == 2 ? "2/2 ações" : "1/2 ação"})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        backgroundColor: Colors.brown[900],
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reiniciar Jogo',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text('Reiniciar Partida'),
                  content:
                      const Text('Tem certeza de que deseja reiniciar o jogo?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _iniciarJogo();
                      },
                      child: const Text('Reiniciar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Barra Financeira
              Container(
                margin: const EdgeInsets.all(12),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatusJogador('Branco', statusBranco.dinheiro,
                        turnoAtual == CorPeca.branco, Colors.amber),
                    Container(height: 24, width: 1, color: Colors.white24),
                    _buildStatusJogador('Preto', statusPreto.dinheiro,
                        turnoAtual == CorPeca.preto, Colors.lightBlueAccent),
                  ],
                ),
              ),

              // Tabuleiro de Xadrez
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      margin: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          if (estaEmXeque)
                            BoxShadow(
                                color: Colors.redAccent.withOpacity(0.8),
                                blurRadius: 20,
                                spreadRadius: 4)
                          else if (emModoSelecao)
                            BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.8),
                                blurRadius: 20,
                                spreadRadius: 4)
                          else
                            BoxShadow(
                                color: Colors.black.withOpacity(0.6),
                                blurRadius: 12,
                                spreadRadius: 2),
                        ],
                        border: Border.all(
                          color: estaEmXeque
                              ? Colors.red.shade700
                              : emModoSelecao
                                  ? Colors.blue.shade600
                                  : Colors.brown.shade800,
                          width: 6,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 8),
                          itemCount: 64,
                          itemBuilder: (context, gridIndex) {
                            final int index = (turnoAtual == CorPeca.preto)
                                ? (63 - gridIndex)
                                : gridIndex;
                            final int linha = index ~/ 8;
                            final int coluna = index % 8;
                            final bool eCasaBranca = (linha + coluna) % 2 == 0;
                            final Peca? peca = tabuleiro[index];

                            bool podeInvocarAqui = cartaSelecionada != null &&
                                !tabuleiro.containsKey(index) &&
                                ((turnoAtual == CorPeca.branco && linha >= 6) ||
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
                                if (_casaSobAtaque(index, turnoAtual.oposta)) {
                                  casaAmeacadaParaRei = true;
                                }
                              }
                            }

                            bool estaMovendo = indicePecaSelecionada == index;
                            bool eOReiEmXeque = index == posReiEmXeque;
                            bool alvoValidoEfeito = emModoSelecao &&
                                _casaValidaParaModo(index, modoSelecao);

                            Color corCasa = eCasaBranca
                                ? const Color(0xFFEEDC9A)
                                : const Color(0xFFA86B32);
                            BoxBorder? bordaCasa;

                            if (alvoValidoEfeito) {
                              corCasa = Colors.blue.shade700.withOpacity(0.68);
                              bordaCasa = Border.all(
                                  color: Colors.lightBlueAccent, width: 3);
                            } else if (eOReiEmXeque) {
                              corCasa = Colors.red.shade900.withOpacity(0.85);
                              bordaCasa =
                                  Border.all(color: Colors.redAccent, width: 3.5);
                            } else if (podeInvocarAqui) {
                              corCasa = Colors.green.withOpacity(0.5);
                              bordaCasa =
                                  Border.all(color: Colors.greenAccent, width: 2);
                            } else if (casaAmeacadaParaRei) {
                              corCasa = Colors.redAccent.withOpacity(0.6);
                            }

                            if (estaMovendo) {
                              corCasa = Colors.amber.shade400;
                              bordaCasa =
                                  Border.all(color: Colors.amberAccent, width: 3);
                            }

                            return GestureDetector(
                              onTap: () => _cliqueCasa(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: corCasa,
                                  border: bordaCasa,
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: peca != null
                                          ? Text(
                                              peca.tipo.simbolo(peca.cor),
                                              style: TextStyle(
                                                fontSize: 34,
                                                color: peca.cor == CorPeca.preto
                                                    ? Colors.black
                                                    : Colors.white,
                                                shadows: [
                                                  Shadow(
                                                    offset: const Offset(1, 1),
                                                    blurRadius: 3,
                                                    color: peca.cor ==
                                                            CorPeca.preto
                                                        ? Colors.white54
                                                        : Colors.black87,
                                                  ),
                                                ],
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    if (peca != null && peca.protegida)
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: peca.protecaoPermanente
                                                ? Colors.amber.shade900
                                                : Colors.blue.shade900,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.shield,
                                            size: 12,
                                            color: peca.protecaoPermanente
                                                ? Colors.amberAccent
                                                : Colors.lightBlueAccent,
                                          ),
                                        ),
                                      ),
                                    if (peca != null && peca.paralisada)
                                      Center(
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.purple.withOpacity(0.75),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.purpleAccent,
                                                width: 2),
                                          ),
                                          child: const Icon(Icons.lock,
                                              size: 18, color: Colors.white),
                                        ),
                                      ),
                                    if (movimentoValidoParaCasa &&
                                        !casaAmeacadaParaRei)
                                      Center(
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: Colors.blueAccent
                                                .withOpacity(0.9),
                                            shape: BoxShape.circle,
                                            boxShadow: const [
                                              BoxShadow(
                                                  color: Colors.white70,
                                                  blurRadius: 4),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Baralho Inferior
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, -4)),
                  ],
                ),
                height: 155,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🂠 Sua Mão de Cartas:',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                        ElevatedButton.icon(
                          onPressed: (exibeEscolhaDeCarta ||
                                  escolhendoPromocaoPeao ||
                                  emModoSelecao)
                              ? null
                              : _finalizarTurno,
                          icon: const Icon(Icons.skip_next, size: 18),
                          label: const Text('Passar Turno'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[800],
                            foregroundColor: Colors.black,
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
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

                          Color corBadgeCusto = Colors.green.shade800;
                          if (bloqueada) {
                            corBadgeCusto = Colors.grey.shade700;
                          } else if (custoAtual < carta.custo) {
                            corBadgeCusto = Colors.teal.shade700;
                          } else if (custoAtual > carta.custo) {
                            corBadgeCusto = Colors.red.shade800;
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
                              width: 95,
                              margin: EdgeInsets.only(
                                right: 12,
                                top: estaSelecionada ? 0 : 6,
                                bottom: estaSelecionada ? 8 : 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: estaSelecionada
                                      ? [
                                          Colors.amber.shade200,
                                          Colors.amber.shade400
                                        ]
                                      : [
                                          Colors.grey.shade100,
                                          Colors.grey.shade300
                                        ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: estaSelecionada
                                      ? Colors.amber.shade900
                                      : Colors.grey.shade400,
                                  width: estaSelecionada ? 3 : 1.5,
                                ),
                                boxShadow: estaSelecionada
                                    ? [
                                        BoxShadow(
                                            color:
                                                Colors.amber.withOpacity(0.6),
                                            blurRadius: 10,
                                            spreadRadius: 2),
                                      ]
                                    : [
                                        BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2)),
                                      ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    carta.tipoPeca.simbolo(turnoAtual),
                                    style: const TextStyle(
                                        fontSize: 28, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    carta.tipoPeca.nome,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.black),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: corBadgeCusto,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      bloqueada
                                          ? '🚫 Bloq.'
                                          : '🪙 \$$custoAtual',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11),
                                    ),
                                  ),
                                ],
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

          // Banner Fixo de XEQUE (Vermelho)
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
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade900,
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.amberAccent, size: 24),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '🚨 REI EM XEQUE! Defenda seu Rei para continuar jogando!',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Banner Fixo de Seleção de Alvo de Carta (Azul)
          if (emModoSelecao && !exibeEscolhaDeCarta && !escolhendoPromocaoPeao)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black54,
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
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Banner de Notificação Rápida
          if (mensagemNotificacao != null)
            Positioned(
              top: (emModoSelecao || estaEmXeque) ? 44 : 12,
              left: 12,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: mensagemNotificacao != null ? 1.0 : 0.0,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 260),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xEE2B0E12),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.amber.shade300, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black87,
                          blurRadius: 8,
                          offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          mensagemNotificacao!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Modal de Promoção do Peão (Última Fileira ou Decreto de Promoção)
          if (escolhendoPromocaoPeao)
            Container(
              color: Colors.black.withOpacity(0.78),
              child: Center(
                child: Card(
                  elevation: 12,
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  margin: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          promocaoPorDecreto
                              ? '🎖️ Decreto de Promoção!'
                              : '👑 Promoção de Peão!',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.amberAccent),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Escolha em qual peça deseja transformar seu Peão:',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: (promocaoPorDecreto
                                  ? [TipoPeca.cavalo, TipoPeca.bispo]
                                  : [
                                      TipoPeca.rainha,
                                      TipoPeca.torre,
                                      TipoPeca.bispo,
                                      TipoPeca.cavalo,
                                    ])
                              .map((tipo) {
                            return InkWell(
                              onTap: () => _promoverPeao(tipo),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 110,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.brown.shade700,
                                      Colors.brown.shade900
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.amber.shade600, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black45,
                                        blurRadius: 6,
                                        offset: Offset(0, 3)),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      tipo.simbolo(turnoAtual),
                                      style: const TextStyle(
                                          fontSize: 40, color: Colors.white),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      tipo.nome,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 14),
                                    ),
                                  ],
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

          // Modal de Escolha de Cartas e Efeitos
          if (exibeEscolhaDeCarta)
            Container(
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: Card(
                  elevation: 12,
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  margin: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          escolhendoEfeito
                              ? '✨ Escolha uma Carta de Efeito'
                              : '⚔️ Escolha uma Nova Peça',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        if (!escolhendoEfeito)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: opcoesEscolhaAtual.map((carta) {
                              return InkWell(
                                onTap: () => _escolherCarta(carta),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 120,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.brown.shade700,
                                        Colors.brown.shade900
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.amber.shade700, width: 2),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black45,
                                          blurRadius: 6,
                                          offset: Offset(0, 3)),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(carta.tipoPeca.simbolo(turnoAtual),
                                          style: const TextStyle(
                                              fontSize: 42,
                                              color: Colors.white)),
                                      const SizedBox(height: 8),
                                      Text(carta.tipoPeca.nome,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade700,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text('🪙 \$${carta.custo}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        else
                          Column(
                            children: opcoesEfeitoAtual.map((efeito) {
                              final Color corCard =
                                  corRaridade(efeito.raridade);
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6.0),
                                child: InkWell(
                                  onTap: () => _escolherEfeito(efeito),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[850],
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: corCard, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                            color: corCard.withOpacity(0.3),
                                            blurRadius: 6),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
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
                                                    child: Text(efeito.titulo,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                            color:
                                                                Colors.white)),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: corCard,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Text(
                                                        efeito.raridade,
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(efeito.descricao,
                                                  style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 13)),
                                            ],
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

          // Aviso Central de Vez do Jogador
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _mostrarAvisoTurno ? 1.0 : 0.0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(
                      color: turnoAtual == CorPeca.branco
                          ? const Color(0xF2F7F4EB)
                          : const Color(0xF218191C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: turnoAtual == CorPeca.branco
                            ? Colors.amber.shade700
                            : Colors.lightBlueAccent,
                        width: 3.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black87,
                          blurRadius: 24,
                          spreadRadius: 4,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          turnoAtual == CorPeca.branco
                              ? Icons.brightness_7
                              : Icons.brightness_2,
                          size: 46,
                          color: turnoAtual == CorPeca.branco
                              ? Colors.amber.shade800
                              : Colors.lightBlueAccent,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'VEZ DO ${turnoAtual.nome.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: turnoAtual == CorPeca.branco
                                ? Colors.brown.shade900
                                : Colors.white,
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
    );
  }

  Widget _buildStatusJogador(
      String nome, int saldo, bool eTurnoAtual, Color corDestaque) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: eTurnoAtual ? corDestaque.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: eTurnoAtual
            ? Border.all(color: corDestaque, width: 2)
            : Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          Text(
            '$nome: ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: eTurnoAtual ? FontWeight.bold : FontWeight.normal,
              color: eTurnoAtual ? corDestaque : Colors.white70,
            ),
          ),
          Text(
            '🪙 \$$saldo',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent),
          ),
        ],
      ),
    );
  }
}