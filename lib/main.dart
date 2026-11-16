import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

enum TipoPeca { peao, torre, cavalo, bispo, rainha, rei }

enum CorPeca { branco, preto }

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
  final CorPeca cor;
  int posicao;
  bool capturado;
  bool protegida;
  bool paralisada;

  Peca(
    this.tipo,
    this.cor, {
    this.posicao = 0,
    this.capturado = false,
    this.protegida = false,
    this.paralisada = false,
  });
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
  final Function(AppState state) aplicarEfeito;

  CartaEfeito({
    required this.titulo,
    required this.descricao,
    required this.raridade,
    required this.aplicarEfeito,
  });
}

class AppState {
  final _TabuleiroXadrezState state;
  AppState(this.state);

  CorPeca get turnoAtual => state.turnoAtual;

  int get dinheiroBranco => state.dinheiroBranco;
  set dinheiroBranco(int val) => state.dinheiroBranco = val;

  int get dinheiroPreto => state.dinheiroPreto;
  set dinheiroPreto(int val) => state.dinheiroPreto = val;

  List<Carta> get maoBranco => state.maoBranco;
  List<Carta> get maoPreto => state.maoPreto;
  Map<int, Peca> get tabuleiro => state.tabuleiro;

  void ativarSelecaoProtecao() => state.ativarSelecaoProtecao();
  void ativarSelecaoParalisia() => state.ativarSelecaoParalisia();
}

void main() {
  runApp(
    const MaterialApp(
      home: TabuleiroXadrez(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class TabuleiroXadrez extends StatefulWidget {
  const TabuleiroXadrez({super.key});

  @override
  State<TabuleiroXadrez> createState() => _TabuleiroXadrezState();
}

class _TabuleiroXadrezState extends State<TabuleiroXadrez> {
  final Random _random = Random();
  final Map<int, Peca> tabuleiro = {};

  CorPeca turnoAtual = CorPeca.branco;
  int numeroRodada = 1;
  int acoesRestantes = 2;
  bool jaMoveuPecaNesteTurno = false;

  int dinheiroBranco = 30;
  int dinheiroPreto = 30;

  List<Carta> maoBranco = [];
  List<Carta> maoPreto = [];

  Carta? cartaSelecionada;
  int? indiceCartaSelecionada;
  int? indicePecaSelecionada;

  bool exibeEscolhaDeCarta = false;
  bool escolhendoEfeito = false;
  bool selecionandoPecaParaProteger = false;
  bool selecionandoPecaParaParalisar = false;

  List<Carta> opcoesEscolhaAtual = [];
  List<CartaEfeito> opcoesEfeitoAtual = [];

  bool promocaoAtivaBranco = false;
  bool promocaoAtivaPreto = false;
  bool economiaTempoBranco = false;
  bool economiaTempoPreto = false;
  int inflacaoRodadasRestantesPreto = 0;
  int inflacaoRodadasRestantesBranco = 0;

  String? mensagemNotificacao;
  Timer? _timerNotificacao;

  final List<Carta> deckDisponivel = [
    Carta(TipoPeca.peao, 20),
    Carta(TipoPeca.cavalo, 50),
    Carta(TipoPeca.bispo, 50),
    Carta(TipoPeca.torre, 80),
    Carta(TipoPeca.rainha, 150),
  ];

  late final List<CartaEfeito> deckEfeitosDisponiveis = [
    CartaEfeito(
      titulo: 'Investimento',
      descricao: 'Receba 50 moedas extras imediatamente.',
      raridade: 'Comum',
      aplicarEfeito: (app) => _adicionarDinheiro(app.turnoAtual, 50),
    ),
    CartaEfeito(
      titulo: 'Promoção',
      descricao: 'Sua próxima peça custa 25% menos.',
      raridade: 'Comum',
      aplicarEfeito: (app) {
        if (app.turnoAtual == CorPeca.branco) {
          promocaoAtivaBranco = true;
        } else {
          promocaoAtivaPreto = true;
        }
      },
    ),
    CartaEfeito(
      titulo: 'Poupança',
      descricao: 'Guarde 50 moedas e receba mais 25 na próxima rodada.',
      raridade: 'Comum',
      aplicarEfeito: (app) {
        final atual = _getDinheiro(app.turnoAtual);
        if (atual >= 50) {
          _adicionarDinheiro(app.turnoAtual, -50);
          final cor = app.turnoAtual;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() => _adicionarDinheiro(cor, 75));
            }
          });
        }
      },
    ),
    CartaEfeito(
      titulo: 'Proteção',
      descricao: 'Escolha uma peça sua para ser protegida contra captura.',
      raridade: 'Comum',
      aplicarEfeito: (app) => app.ativarSelecaoProtecao(),
    ),
    CartaEfeito(
      titulo: 'Tesouro Escondido',
      descricao: 'Ganhe 30 moedas aleatórias extras.',
      raridade: 'Comum',
      aplicarEfeito: (app) {
        int extra = 20 + _random.nextInt(21);
        _adicionarDinheiro(app.turnoAtual, extra);
      },
    ),
    CartaEfeito(
      titulo: 'Comércio',
      descricao: 'Receba 20 moedas sempre que capturar uma peça adversária.',
      raridade: 'Comum',
      aplicarEfeito: (app) {},
    ),
    CartaEfeito(
      titulo: 'Economia de Tempo',
      descricao: 'Sua próxima compra de peça tem desconto de 15 moedas.',
      raridade: 'Comum',
      aplicarEfeito: (app) {
        if (app.turnoAtual == CorPeca.branco) {
          economiaTempoBranco = true;
        } else {
          economiaTempoPreto = true;
        }
      },
    ),
    CartaEfeito(
      titulo: 'Salário Extra',
      descricao: 'Receba 40 moedas adicionais nesta rodada.',
      raridade: 'Comum',
      aplicarEfeito: (app) => _adicionarDinheiro(app.turnoAtual, 40),
    ),
    CartaEfeito(
      titulo: 'Rei do Mercado',
      descricao: 'Receba 100 moedas extras imediatamente.',
      raridade: 'Rara',
      aplicarEfeito: (app) => _adicionarDinheiro(app.turnoAtual, 100),
    ),
    CartaEfeito(
      titulo: 'Recrutamento',
      descricao: 'Compre uma peça com 50% de desconto.',
      raridade: 'Rara',
      aplicarEfeito: (app) {
        if (app.turnoAtual == CorPeca.branco) {
          promocaoAtivaBranco = true;
        } else {
          promocaoAtivaPreto = true;
        }
      },
    ),
    CartaEfeito(
      titulo: 'Roubo',
      descricao: 'Roube 75 moedas do adversário.',
      raridade: 'Rara',
      aplicarEfeito: (app) {
        CorPeca oponente = app.turnoAtual.oposta;
        int saldoOponente = _getDinheiro(oponente);
        int roubo = saldoOponente >= 75 ? 75 : saldoOponente;
        _adicionarDinheiro(oponente, -roubo);
        _adicionarDinheiro(app.turnoAtual, roubo);
      },
    ),
    CartaEfeito(
      titulo: 'Reforço Militar',
      descricao: 'Escolha uma peça sua para receber proteção reforçada.',
      raridade: 'Rara',
      aplicarEfeito: (app) => app.ativarSelecaoProtecao(),
    ),
    CartaEfeito(
      titulo: 'Inflação',
      descricao: 'Os preços das peças do adversário aumentam 30%.',
      raridade: 'Rara',
      aplicarEfeito: (app) {
        if (app.turnoAtual == CorPeca.branco) {
          inflacaoRodadasRestantesPreto = 2;
        } else {
          inflacaoRodadasRestantesBranco = 2;
        }
      },
    ),
    CartaEfeito(
      titulo: 'Contrato Especial',
      descricao: 'Na próxima rodada, receba 150 moedas em vez de 100.',
      raridade: 'Rara',
      aplicarEfeito: (app) => _adicionarDinheiro(app.turnoAtual, 50),
    ),
    CartaEfeito(
      titulo: 'Fortuna Real',
      descricao: 'Receba 300 moedas imediatamente.',
      raridade: 'Épica',
      aplicarEfeito: (app) => _adicionarDinheiro(app.turnoAtual, 300),
    ),
    CartaEfeito(
      titulo: 'Poder Absoluto',
      descricao:
          'Escolha uma peça adversária (não o Rei) para congelar por uma rodada.',
      raridade: 'Épica',
      aplicarEfeito: (app) => app.ativarSelecaoParalisia(),
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
    super.dispose();
  }

  int _getDinheiro(CorPeca cor) =>
      cor == CorPeca.branco ? dinheiroBranco : dinheiroPreto;

  void _adicionarDinheiro(CorPeca cor, int quantia) {
    if (cor == CorPeca.branco) {
      dinheiroBranco += quantia;
    } else {
      dinheiroPreto += quantia;
    }
  }

  List<Carta> _getMao(CorPeca cor) =>
      cor == CorPeca.branco ? maoBranco : maoPreto;

  void _iniciarJogo({bool comSetState = true}) {
    void acao() {
      tabuleiro.clear();
      maoBranco.clear();
      maoPreto.clear();
      dinheiroBranco = 30;
      dinheiroPreto = 30;
      numeroRodada = 1;
      acoesRestantes = 2;
      jaMoveuPecaNesteTurno = false;
      turnoAtual = CorPeca.branco;
      cartaSelecionada = null;
      indiceCartaSelecionada = null;
      indicePecaSelecionada = null;
      exibeEscolhaDeCarta = false;
      escolhendoEfeito = false;
      selecionandoPecaParaProteger = false;
      selecionandoPecaParaParalisar = false;
      mensagemNotificacao = null;

      tabuleiro[4] = Peca(TipoPeca.rei, CorPeca.preto, posicao: 4);
      tabuleiro[60] = Peca(TipoPeca.rei, CorPeca.branco, posicao: 60);

      _abrirTelaEscolhaCartas(comSetState: false);
    }

    if (comSetState) {
      setState(acao);
    } else {
      acao();
    }
  }

  void ativarSelecaoProtecao() {
    setState(() => selecionandoPecaParaProteger = true);
  }

  void ativarSelecaoParalisia() {
    setState(() => selecionandoPecaParaParalisar = true);
  }

  void _mostrarSnackBar(String mensagem) {
    _timerNotificacao?.cancel();
    setState(() {
      mensagemNotificacao = mensagem;
    });
    _timerNotificacao = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          mensagemNotificacao = null;
        });
      }
    });
  }

  void _abrirTelaEscolhaCartas({bool comSetState = true}) {
    opcoesEscolhaAtual = List.generate(
      2,
      (_) => deckDisponivel[_random.nextInt(deckDisponivel.length)],
    );

    void acao() {
      if (numeroRodada > 1) {
        _adicionarDinheiro(turnoAtual, 30);
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
    if (apenasComum) {
      final comuns = deckEfeitosDisponiveis
          .where((e) => e.raridade == 'Comum')
          .toList();
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

    final cartasFiltradas = deckEfeitosDisponiveis
        .where((e) => e.raridade == raridadeAlvo)
        .toList();

    if (cartasFiltradas.isEmpty) {
      return deckEfeitosDisponiveis[_random.nextInt(
        deckEfeitosDisponiveis.length,
      )];
    }

    return cartasFiltradas[_random.nextInt(cartasFiltradas.length)];
  }

  void _abrirTelaEscolhaEfeitos() {
    final apenasComum = numeroRodada == 1;

    opcoesEfeitoAtual = List.generate(
      2,
      (_) => _sortearCartaPorRaridade(apenasComum: apenasComum),
    );

    setState(() {
      escolhendoEfeito = true;
    });
  }

  void _escolherEfeito(CartaEfeito efeitoEscolhido) {
    setState(() {
      efeitoEscolhido.aplicarEfeito(AppState(this));
      exibeEscolhaDeCarta = false;
      escolhendoEfeito = false;
    });
  }

  void _finalizarTurno() {
    setState(() {
      acoesRestantes = 2;
      jaMoveuPecaNesteTurno = false;
      cartaSelecionada = null;
      indiceCartaSelecionada = null;
      indicePecaSelecionada = null;
      selecionandoPecaParaProteger = false;
      selecionandoPecaParaParalisar = false;

      for (var p in tabuleiro.values) {
        if (p.cor == turnoAtual) {
          p.paralisada = false;
        }
      }

      if (turnoAtual == CorPeca.branco) {
        turnoAtual = CorPeca.preto;
        if (numeroRodada == 1 || numeroRodada % 3 == 0) {
          _abrirTelaEscolhaCartas();
        }
      } else {
        numeroRodada++;
        turnoAtual = CorPeca.branco;
        if (numeroRodada % 3 == 0) {
          _abrirTelaEscolhaCartas();
        }
      }

      if (_estaEmXequeMate(turnoAtual)) {
        Future.microtask(
          () => _mostrarFimDeJogo(turnoAtual.oposta, motivo: 'por Xeque-Mate!'),
        );
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
            pecaDestino == null)
          return true;
        if (diffCol == 1 && destRow == origRow + direcao && pecaDestino != null)
          return true;
        return false;
      case TipoPeca.cavalo:
        return (diffRow == 2 && diffCol == 1) || (diffRow == 1 && diffCol == 2);
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
    int origem,
    int destino,
    TipoPeca tipo,
    CorPeca cor,
  ) {
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
        return (diffRow == 2 && diffCol == 1) || (diffRow == 1 && diffCol == 2);
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

  bool _estaEmXequeMate(CorPeca cor) {
    return _estaEmXeque(cor) && !_temMovimentosValidos(cor);
  }

  void _mostrarFimDeJogo(
    CorPeca vencedor, {
    String motivo = 'ao capturar o Rei adversário!',
  }) {
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
                borderRadius: BorderRadius.circular(8),
              ),
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

  int _calcularCustoFinal(int custoBase) {
    int custoFinal = custoBase;
    if (turnoAtual == CorPeca.branco) {
      if (promocaoAtivaBranco) {
        custoFinal = (custoFinal * 0.5).toInt();
        promocaoAtivaBranco = false;
      }
      if (economiaTempoBranco) {
        custoFinal -= 15;
        economiaTempoBranco = false;
      }
      if (inflacaoRodadasRestantesBranco > 0) {
        custoFinal = (custoFinal * 1.3).toInt();
      }
    } else {
      if (promocaoAtivaPreto) {
        custoFinal = (custoFinal * 0.5).toInt();
        promocaoAtivaPreto = false;
      }
      if (economiaTempoPreto) {
        custoFinal -= 15;
        economiaTempoPreto = false;
      }
      if (inflacaoRodadasRestantesPreto > 0) {
        custoFinal = (custoFinal * 1.3).toInt();
      }
    }
    return max(0, custoFinal);
  }

  void _cliqueCasa(int index) {
    if (exibeEscolhaDeCarta) return;

    setState(() {
      final Peca? pecaNaCasa = tabuleiro[index];

      if (selecionandoPecaParaProteger) {
        if (pecaNaCasa != null && pecaNaCasa.cor == turnoAtual) {
          pecaNaCasa.protegida = true;
          selecionandoPecaParaProteger = false;
          _mostrarSnackBar('Peça protegida com sucesso!');
          _finalizarTurno();
        } else {
          _mostrarSnackBar('Escolha uma peça sua para proteger!');
        }
        return;
      }

      if (selecionandoPecaParaParalisar) {
        if (pecaNaCasa != null && pecaNaCasa.cor == turnoAtual.oposta) {
          if (pecaNaCasa.tipo == TipoPeca.rei) {
            _mostrarSnackBar('Não pode paralisar o Rei!');
            return;
          }
          pecaNaCasa.paralisada = true;
          selecionandoPecaParaParalisar = false;
          _mostrarSnackBar('Peça inimiga paralisada!');
          _finalizarTurno();
        } else {
          _mostrarSnackBar('Escolha uma peça inimiga!');
        }
        return;
      }

      if (cartaSelecionada != null) {
        if (_estaEmXeque(turnoAtual)) {
          _mostrarSnackBar('Rei em xeque! Defenda seu Rei!');
          return;
        }

        if (cartaSelecionada!.tipoPeca != TipoPeca.peao && acoesRestantes < 2) {
          _mostrarSnackBar('Esta peça exige o turno completo!');
          return;
        }

        final int linha = index ~/ 8;
        bool ladoValido =
            (turnoAtual == CorPeca.branco && linha >= 6) ||
            (turnoAtual == CorPeca.preto && linha <= 1);

        if (!ladoValido) {
          _mostrarSnackBar(
            'Invoque apenas nas 2 primeiras fileiras da sua base!',
          );
          return;
        }

        int custoFinal = _calcularCustoFinal(cartaSelecionada!.custo);
        int dinheiroAtual = _getDinheiro(turnoAtual);

        if (dinheiroAtual < custoFinal) {
          _mostrarSnackBar('Dinheiro insuficiente!');
          return;
        }

        if (pecaNaCasa != null) {
          _mostrarSnackBar('Casa já ocupada!');
          return;
        }

        _adicionarDinheiro(turnoAtual, -custoFinal);
        _getMao(turnoAtual).removeAt(indiceCartaSelecionada!);
        tabuleiro[index] = Peca(
          cartaSelecionada!.tipoPeca,
          turnoAtual,
          posicao: index,
        );

        int custoAcao = (cartaSelecionada!.tipoPeca == TipoPeca.peao) ? 1 : 2;
        acoesRestantes -= custoAcao;

        cartaSelecionada = null;
        indiceCartaSelecionada = null;

        bool temOutroPeao = _getMao(
          turnoAtual,
        ).any((c) => c.tipoPeca == TipoPeca.peao);
        bool podeMover = !jaMoveuPecaNesteTurno;

        if (acoesRestantes <= 0 || (!temOutroPeao && !podeMover)) {
          _finalizarTurno();
        } else if (podeMover && temOutroPeao) {
          _mostrarSnackBar('Você ainda pode invocar 1 Peão ou mover 1 peça!');
        } else if (podeMover) {
          _mostrarSnackBar('Você ainda pode mover 1 peça neste turno!');
        } else if (temOutroPeao) {
          _mostrarSnackBar('Você ainda pode invocar mais 1 Peão neste turno!');
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

      if (!_movimentoValido(
        indicePecaSelecionada!,
        index,
        pecaMovendo.tipo,
        pecaMovendo.cor,
      )) {
        _mostrarSnackBar('Movimento inválido!');
        return;
      }

      Peca? pecaDestinoAnterior = tabuleiro[index];
      int origemAntiga = pecaMovendo.posicao;

      tabuleiro.remove(indicePecaSelecionada);
      tabuleiro[index] = pecaMovendo;
      pecaMovendo.posicao = index;

      int? posReiAposMovimento = _encontrarRei(turnoAtual);
      bool aindaEmXeque =
          posReiAposMovimento != null &&
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

      if (pecaNaCasa != null && pecaNaCasa.tipo == TipoPeca.rei) {
        tabuleiro.remove(indicePecaSelecionada);
        tabuleiro[index] = Peca(
          pecaMovendo.tipo,
          pecaMovendo.cor,
          posicao: index,
        );
        _mostrarFimDeJogo(turnoAtual);
        return;
      }

      tabuleiro.remove(indicePecaSelecionada);
      tabuleiro[index] = Peca(
        pecaMovendo.tipo,
        pecaMovendo.cor,
        posicao: index,
      );
      indicePecaSelecionada = null;

      jaMoveuPecaNesteTurno = true;
      acoesRestantes -= 1;

      bool temPeaoNaMao = _getMao(
        turnoAtual,
      ).any((c) => c.tipoPeca == TipoPeca.peao);

      if (acoesRestantes <= 0 || !temPeaoNaMao) {
        _finalizarTurno();
      } else {
        _mostrarSnackBar('Você ainda pode invocar 1 Peão neste turno!');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Carta> maoAtual = _getMao(turnoAtual);
    final bool estaEmXeque = _estaEmXeque(turnoAtual);
    final int? posReiEmXeque = estaEmXeque ? _encontrarRei(turnoAtual) : null;

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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Reiniciar Partida'),
                  content: const Text(
                    'Tem certeza de que deseja reiniciar o jogo?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
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
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatusJogador(
                      'Branco',
                      dinheiroBranco,
                      turnoAtual == CorPeca.branco,
                      Colors.amber,
                    ),
                    Container(height: 24, width: 1, color: Colors.white24),
                    _buildStatusJogador(
                      'Preto',
                      dinheiroPreto,
                      turnoAtual == CorPeca.preto,
                      Colors.lightBlueAccent,
                    ),
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
                              spreadRadius: 4,
                            )
                          else if (selecionandoPecaParaProteger)
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.8),
                              blurRadius: 20,
                              spreadRadius: 4,
                            )
                          else
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                        ],
                        border: Border.all(
                          color: estaEmXeque
                              ? Colors.red.shade700
                              : selecionandoPecaParaProteger
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
                                crossAxisCount: 8,
                              ),
                          itemCount: 64,
                          itemBuilder: (context, gridIndex) {
                            final int index = (turnoAtual == CorPeca.preto)
                                ? (63 - gridIndex)
                                : gridIndex;
                            final int linha = index ~/ 8;
                            final int coluna = index % 8;
                            final bool eCasaBranca = (linha + coluna) % 2 == 0;
                            final Peca? peca = tabuleiro[index];

                            bool podeInvocarAqui =
                                cartaSelecionada != null &&
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
                            bool podeProtegerAqui =
                                selecionandoPecaParaProteger &&
                                peca != null &&
                                peca.cor == turnoAtual;

                            Color corCasa = eCasaBranca
                                ? const Color(0xFFEEDC9A)
                                : const Color(0xFFA86B32);
                            BoxBorder? bordaCasa;

                            if (podeProtegerAqui) {
                              corCasa = Colors.blue.shade700.withOpacity(0.65);
                              bordaCasa = Border.all(
                                color: Colors.lightBlueAccent,
                                width: 3,
                              );
                            } else if (eOReiEmXeque) {
                              corCasa = Colors.red.shade900.withOpacity(0.85);
                              bordaCasa = Border.all(
                                color: Colors.redAccent,
                                width: 3.5,
                              );
                            } else if (podeInvocarAqui) {
                              corCasa = Colors.green.withOpacity(0.5);
                              bordaCasa = Border.all(
                                color: Colors.greenAccent,
                                width: 2,
                              );
                            } else if (casaAmeacadaParaRei) {
                              corCasa = Colors.redAccent.withOpacity(0.6);
                            }

                            if (estaMovendo) {
                              corCasa = Colors.amber.shade400;
                              bordaCasa = Border.all(
                                color: Colors.amberAccent,
                                width: 3,
                              );
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
                                                    color:
                                                        peca.cor ==
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
                                            color: Colors.amber.shade900,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.shield,
                                            size: 12,
                                            color: Colors.amberAccent,
                                          ),
                                        ),
                                      ),
                                    if (peca != null && peca.paralisada)
                                      Center(
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.purple.withOpacity(
                                              0.75,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.purpleAccent,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.lock,
                                            size: 18,
                                            color: Colors.white,
                                          ),
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
                                                blurRadius: 4,
                                              ),
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
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
                            fontSize: 14,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _finalizarTurno,
                          icon: const Icon(Icons.skip_next, size: 18),
                          label: const Text('Passar Turno'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[800],
                            foregroundColor: Colors.black,
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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

                          return GestureDetector(
                            onTap: () {
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
                                          Colors.amber.shade400,
                                        ]
                                      : [
                                          Colors.grey.shade100,
                                          Colors.grey.shade300,
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
                                          color: Colors.amber.withOpacity(0.6),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    carta.tipoPeca.simbolo(turnoAtual),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    carta.tipoPeca.nome,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade800,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '🪙 \$${carta.custo}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
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
                  ],
                ),
              ),
            ],
          ),

          // Banner Fixo de XEQUE (Vermelho)
          if (estaEmXeque && !exibeEscolhaDeCarta)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade900,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amberAccent,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '🚨 REI EM XEQUE! Defenda seu Rei para continuar jogando!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Banner Fixo de PROTEÇÃO (Azul)
          if (selecionandoPecaParaProteger && !exibeEscolhaDeCarta)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.shield_rounded,
                      color: Colors.lightBlueAccent,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '🛡️ MODO PROTEÇÃO: Clique em uma de suas peças azuis para protegê-la!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Banner de Notificação Rápida
          if (mensagemNotificacao != null)
            Positioned(
              top: selecionandoPecaParaProteger || estaEmXeque ? 44 : 12,
              left: 12,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: mensagemNotificacao != null ? 1.0 : 0.0,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 240),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xEE2B0E12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.amber.shade300,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black87,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.amber,
                        size: 18,
                      ),
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

          // Modal de Escolha de Cartas e Efeitos
          if (exibeEscolhaDeCarta)
            Container(
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: Card(
                  elevation: 12,
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: const EdgeInsets.all(20.0),
                  child: Padding(
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
                            color: Colors.white,
                          ),
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
                                        Colors.brown.shade900,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.amber.shade700,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black45,
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        carta.tipoPeca.simbolo(turnoAtual),
                                        style: const TextStyle(
                                          fontSize: 42,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        carta.tipoPeca.nome,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade700,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '🪙 \$${carta.custo}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
                              final Color corCard = corRaridade(
                                efeito.raridade,
                              );
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                ),
                                child: InkWell(
                                  onTap: () => _escolherEfeito(efeito),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[850],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: corCard,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: corCard.withOpacity(0.3),
                                          blurRadius: 6,
                                        ),
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
                                                  Text(
                                                    efeito.titulo,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: corCard,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      efeito.raridade,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                efeito.descricao,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                ),
                                              ),
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
        ],
      ),
    );
  }

  Widget _buildStatusJogador(
    String nome,
    int saldo,
    bool eTurnoAtual,
    Color corDestaque,
  ) {
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
              color: Colors.greenAccent,
            ),
          ),
        ],
      ),
    );
  }
}
