import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MeuAplicativo());
}

class MeuAplicativo extends StatelessWidget {
  const MeuAplicativo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perfil e Localização',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD71920),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
        fontFamily: 'Roboto',
      ),
      home: const TelaPerfil(),
    );
  }
}

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  static const Color vermelho = Color(0xFFD71920);
  static const Color textoEscuro = Color(0xFF1C2430);

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nomeController =
      TextEditingController();

  File? foto;
  String localizacao = 'Localização ainda não obtida';
  String ultimaAtualizacao = '';

  bool localizacaoObtida = false;
  bool buscandoLocalizacao = false;
  bool buscandoFoto = false;

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  // Abrir câmera ou galeria
  Future<void> escolherFoto(ImageSource origem) async {
    if (buscandoFoto) return;

    setState(() {
      buscandoFoto = true;
    });

    try {
      final XFile? imagem = await _picker.pickImage(
        source: origem,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (!mounted) return;

      if (imagem != null) {
        setState(() {
          foto = File(imagem.path);
        });

        mostrarMensagem('Foto atualizada com sucesso!');
      }
    } catch (erro) {
      if (!mounted) return;
      mostrarMensagem('Não foi possível acessar a imagem.');
    } finally {
      if (mounted) {
        setState(() {
          buscandoFoto = false;
        });
      }
    }
  }

  // Remover foto
  void removerFoto() {
    setState(() {
      foto = null;
    });

    mostrarMensagem('Foto removida.');
  }

  // Obter localização do dispositivo
  Future<void> obterLocalizacao() async {
    if (buscandoLocalizacao) return;

    setState(() {
      buscandoLocalizacao = true;
      localizacao = 'Buscando sua localização...';
    });

    try {
      final bool servicoAtivo =
          await Geolocator.isLocationServiceEnabled();

      if (!mounted) return;

      if (!servicoAtivo) {
        atualizarErroLocalizacao(
          'Ative o GPS do dispositivo para continuar.',
        );
        return;
      }

      LocationPermission permissao =
          await Geolocator.checkPermission();

      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }

      if (!mounted) return;

      if (permissao == LocationPermission.denied) {
        atualizarErroLocalizacao(
          'Permissão de localização negada.',
        );
        return;
      }

      if (permissao == LocationPermission.deniedForever) {
        atualizarErroLocalizacao(
          'Permissão bloqueada. Libere a localização '
          'nas configurações do dispositivo.',
        );
        return;
      }

      final Position posicao =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      final DateTime agora = DateTime.now();

      setState(() {
        localizacao =
            'Latitude: ${posicao.latitude.toStringAsFixed(4)}\n'
            'Longitude: ${posicao.longitude.toStringAsFixed(4)}';

        localizacaoObtida = true;
        buscandoLocalizacao = false;

        ultimaAtualizacao =
            '${agora.day.toString().padLeft(2, '0')}/'
            '${agora.month.toString().padLeft(2, '0')}/'
            '${agora.year} às '
            '${agora.hour.toString().padLeft(2, '0')}:'
            '${agora.minute.toString().padLeft(2, '0')}';
      });

      mostrarMensagem('Localização obtida com sucesso!');
    } catch (erro) {
      if (!mounted) return;

      atualizarErroLocalizacao(
        'Não foi possível obter a localização. '
        'Verifique o GPS e tente novamente.',
      );
    }
  }

  void atualizarErroLocalizacao(String mensagem) {
    if (!mounted) return;

    setState(() {
      localizacao = mensagem;
      localizacaoObtida = false;
      buscandoLocalizacao = false;
      ultimaAtualizacao = '';
    });
  }

  void mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        behavior: SnackBarBehavior.floating,
        backgroundColor: textoEscuro,
      ),
    );
  }

  // Componentes reutilizáveis
  Widget tituloSecao(String titulo, String subtitulo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textoEscuro,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitulo,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget botaoAcao({
    required String titulo,
    required IconData icone,
    required VoidCallback? aoClicar,
    bool destaque = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: aoClicar,
        icon: Icon(icone, size: 20),
        label: Text(
          titulo,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              destaque ? vermelho : const Color(0xFFF2F3F5),
          foregroundColor:
              destaque ? Colors.white : textoEscuro,
          disabledBackgroundColor: Colors.grey.shade200,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget card({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8E9ED),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Row(
          children: [
            Icon(
              Icons.account_circle_outlined,
              color: vermelho,
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              'Meu Perfil',
              style: TextStyle(
                color: textoEscuro,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE8E9ED),
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Cabeçalho
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: vermelho,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 32,
                        color: Colors.white,
                      ),
                      SizedBox(height: 15),
                      Text(
                        'Seu perfil, suas informações.',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Gerencie sua fotografia e consulte '
                        'sua localização em um só lugar.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Perfil
                card(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 65,
                            backgroundColor:
                                const Color(0xFFFCE8E9),
                            backgroundImage: foto != null
                                ? FileImage(foto!)
                                : null,
                            child: foto == null
                                ? const Icon(
                                    Icons.person_outline,
                                    size: 64,
                                    color: vermelho,
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: vermelho,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Fotografia de perfil',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                          color: textoEscuro,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        foto == null
                            ? 'Nenhuma foto selecionada'
                            : 'Fotografia adicionada',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 24),

                      TextField(
                        controller: _nomeController,
                        textCapitalization:
                            TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Nome completo',
                          hintText: 'Digite seu nome',
                          prefixIcon: const Icon(
                            Icons.person_outline,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      botaoAcao(
                        titulo: 'Tirar foto',
                        icone: Icons.camera_alt_outlined,
                        destaque: true,
                        aoClicar: buscandoFoto
                            ? null
                            : () => escolherFoto(
                                  ImageSource.camera,
                                ),
                      ),

                      const SizedBox(height: 10),

                      botaoAcao(
                        titulo: 'Escolher da galeria',
                        icone: Icons.photo_library_outlined,
                        aoClicar: buscandoFoto
                            ? null
                            : () => escolherFoto(
                                  ImageSource.gallery,
                                ),
                      ),

                      if (foto != null) ...[
                        const SizedBox(height: 10),
                        botaoAcao(
                          titulo: 'Remover fotografia',
                          icone: Icons.delete_outline,
                          aoClicar:
                              buscandoFoto ? null : removerFoto,
                        ),
                      ],

                      if (buscandoFoto) ...[
                        const SizedBox(height: 15),
                        const LinearProgressIndicator(
                          color: vermelho,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Localização
                card(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      tituloSecao(
                        'Localização atual',
                        'Consulte as coordenadas do dispositivo.',
                      ),

                      const SizedBox(height: 24),

                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: localizacaoObtida
                                ? const Color(0xFFE8F7EE)
                                : const Color(0xFFF2F3F5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            localizacaoObtida
                                ? Icons.location_on
                                : Icons.location_searching,
                            size: 42,
                            color: localizacaoObtida
                                ? const Color(0xFF198754)
                                : Colors.grey,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Center(
                        child: Text(
                          localizacaoObtida
                              ? 'Localização encontrada'
                              : 'Aguardando localização',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: localizacaoObtida
                                ? const Color(0xFF198754)
                                : textoEscuro,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          localizacao,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.8,
                            color: textoEscuro,
                          ),
                        ),
                      ),

                      if (ultimaAtualizacao.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Atualizado em $ultimaAtualizacao',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      botaoAcao(
                        titulo: buscandoLocalizacao
                            ? 'Obtendo localização...'
                            : localizacaoObtida
                                ? 'Atualizar localização'
                                : 'Usar minha localização',
                        icone: Icons.my_location,
                        destaque: true,
                        aoClicar: buscandoLocalizacao
                            ? null
                            : obterLocalizacao,
                      ),

                      if (buscandoLocalizacao) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(
                          color: vermelho,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Center(
                  child: Text(
                    'Projeto Flutter • Câmera e Localização',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
