import 'dart:convert';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../model/conversation_subject.dart';
import '../model/conversation.dart';
import '../variables.dart';

/* ----------------------------------
  Projet 4A : Chatbot App
  Date : 11/06/2025
  discussion_page.dart
---------------------------------- */

/// Page de discussion
/// Cette page permet à l'utilisateur de discuter avec le chatbot.
class DiscussionPage extends StatefulWidget {
  DiscussionPage({super.key, required this.titre, required this.conversation});
  DiscussionPage.empty({super.key}) : titre = "", conversation = null;

  final String titre; // Titre de la discussion
  Conversation? conversation;

  @override
  State<DiscussionPage> createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<DiscussionPage> {
  // Variables
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>(); // Clé pour le Scaffold (utile pour gérer le Drawer)
  TextEditingController inputController = TextEditingController(); // Contrôleur pour le champ de saisie de texte
  final TextEditingController subjectSearchController = TextEditingController();
  String subjectSearch = "";
  late final ScrollController _scrollController; // Contrôleur pour le défilement de la liste des messages
  bool researchMode = false; // true = recherche web, false = recherche locale
  List<File> files = []; // Liste des fichiers sélectionnés
  bool isLoading = false; // Indique si une requête est en cours (animation)

  Future<List<ConversationSubject>>? drawerData; // Données pour le Drawer (liste des sujets de conversation)

  // Liste des émotions disponibles pour les messages du bot
  final listeEmotions = ["naturel","amoureux","colère","détective","effrayant","endormi","fatigué","heureux","inquiet","intello","pensif","professeur","soulagé","surpris","triste"];

  // Instance de SpeechToText pour la reconnaissance vocale
  final SpeechToText _speechToText = SpeechToText();
  bool isListeningMic = false; // Indique si le microphone est en écoute
  bool _speechEnabled = false; // Indique si la reconnaissance vocale est activée
  bool _isListening = false; // Indique si la reconnaissance vocale est en cours
  String _currentText = ""; // Texte actuel saisi dans le champ de saisie (pour ajouter le texte reconnu à la suite de ce qui est déjà écrit)

  // Initialisation de l'utilisateur
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    drawerData = loadSubjects();
    subjectSearchController.addListener(() {
      if (!mounted) return;
      setState(() {
        subjectSearch = subjectSearchController.text;
      });
    });

    // Scroll to the bottom after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    if (widget.conversation != null) {
      launchConversation(); // Charge la conversation (sauf si c'est une nouvelle conversation)
    }

    // Charge le SpeechToText si l'application est sur Android
    if(Platform.isAndroid) {
      _initSpeech();
    }
  }

  @override
  void dispose() {
    inputController.dispose();
    subjectSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  /// Fonction pour descendre en bas de la liste des messages
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
  }

  // ---------------------------------- Speech-to-text ----------------------------------

  /// Initialise le SpeechToText
  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
    );
    setState(() {});
  }

  /// Démarre ou arrête l'écoute du microphone
  void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
    setState(() => _isListening = true);
  }

  /// Arrête l'écoute du microphone
  void _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  /// Fonction appelée lorsque le résultat de la reconnaissance vocale est disponible
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return; // Vérifie si le widget est toujours monté
    //inputController.text = result.recognizedWords;
    inputController.text = "$_currentText ${result.recognizedWords}";
  }

  // ---------------------------------- Fonctions pour l'API ----------------------------------

  /// Crée un client HTTP sécurisé avec le certificat CA
  Future<HttpClient> createSecureHttpClient() async {
    final context = SecurityContext.defaultContext;
    final ByteData certData = await rootBundle.load('assets/certs/myCA.pem');
    context.setTrustedCertificatesBytes(certData.buffer.asUint8List());
    return HttpClient(context: context);
  }

  /// Supprime une discussion
  void removeDiscussion(String id) async {
    // Prépare l'URL pour la requête de suppression
    final uri = Uri.parse('$urlPrefix/delete_conversation/$id');
    // Ajout du bearer token pour l'authentification
    final request = http.MultipartRequest('POST', uri)..headers['Authorization'] = 'Bearer ${user.accessToken}';

    try {
      // Envoie la requête de suppression
      final response = await request.send();

      if (response.statusCode == 200) {
        //print("La suppression a réussie");
        // Si la suppression réussit, on recharge les sujets
        loadSubjects().then((sujets) {
          // Met à jour les données du Drawer avec les nouveaux sujets
          drawerData = Future.value(sujets);
          if (id == widget.conversation?.id) {
            // Si la conversation supprimée est celle en cours, on redirige vers une nouvelle discussion
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DiscussionPage(titre: "", conversation: null)));
          } else {
            setState(() {});
          }
        });
      } else {
        //print("Erreur lors de la suppression de la conversation : ${response.statusCode}");
      }
    } catch (e) {
      // En cas d'erreur, nous n'avons rien a traité côté client
      //print("Exception pendant la récupération : $e");
    }
  }

  /// Lance la récupération de la conversation
  void launchConversation() async {
    // Charge un objet Conversation
    widget.conversation = Conversation(id: widget.conversation!.id, title: widget.titre, messages: []);

    // Prépare l'URL pour la requête de récupération de la conversation
    final uri = Uri.parse('$urlPrefix/chat/${widget.conversation!.id}');
    final request = http.MultipartRequest('GET', uri)..headers['Authorization'] = 'Bearer ${user.accessToken}';

    try {
      // Envoie la requête pour récupérer la conversation
      final response = await request.send();

      if (response.statusCode == 200) {
        //print("Réception de la conversation réussie");

        // Lit le corps de la réponse et le décode en JSON
        final responseBody = await response.stream.bytesToString();
        final json = jsonDecode(responseBody);
        List<List<String>> messages = [];
        // Parcourt les messages et les ajoute à la liste
        for (var item in json) {
          final role = item["role"].toString();
          final message = item["content"].toString();
          messages.add([role, message, "naturel"]);
        }

        // Ajoute ces messages à la conversation
        widget.conversation?.messages.addAll(messages);

        setState(() {});
        _scrollToBottom();
      } else {
        // En cas d'erreur, nous n'avons rien a traité côté client
        //print("Erreur lors de la récupération de la conversation : ${response.statusCode}");
      }
    } catch (e) {
      // En cas d'exception, nous n'avons rien a traité côté client
      //print("Exception pendant la récupération : $e");
    }
  }

  /// Déconnexion de l'utilisateur
  void logout() async {
    // Préparer l'URL pour la requête de déconnexion
    final uri = Uri.parse('$urlPrefix/logout');
    final request = http.MultipartRequest('POST', uri)..headers['Authorization'] = 'Bearer ${user.accessToken}';
    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        //print("Déconnexion réussie");
      } else {
        //print("Erreur lors de la déconnexion : ${response.statusCode}");
      }
    } catch (e) {
      //print("Exception pendant la récupération : $e");
    }
    // Réinitialiser l'utilisateur
    user.clear();
    // Retourne à la page de connexion
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Charge les sujets de conversation depuis l'API
  Future<List<ConversationSubject>> loadSubjects() async {
    // Crée un client HTTP sécurisé
    final client = await createSecureHttpClient();
    final url = Uri.parse('$urlPrefix/conversations');

    try {
      // Prépare la requête GET pour récupérer les sujets de conversation
      final request = await client.getUrl(url);
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
      // Ajout du token d'authentification
      request.headers.set(HttpHeaders.authorizationHeader, "Bearer ${user.accessToken}");

      final response = await request.close();

      if (response.statusCode == 200) {
        //print("Récupération des sujets réussie");

        final responseBody = await response.transform(utf8.decoder).join();
        final List<dynamic> data = jsonDecode(responseBody);
        // Convertit la liste JSON en liste d'objets ConversationSubject
        List<ConversationSubject> listeSujets = data.map((json) => ConversationSubject.fromJson(json)).toList();
        // Trie la liste des sujets par date de dernière mise à jour
        listeSujets.sort(
          (a, b) => b.lastUpdate.compareTo(a.lastUpdate), // Tri par date de dernière mise à jour, du plus récent au plus ancien
        );
        return listeSujets;
      } else {
        //print("Erreur lors de la récupération des sujets : ${response.statusCode}");
        // En cas d'erreur, nous la faisons remonter
        throw Exception("Erreur lors de la récupération des sujets : ${response.statusCode}");
      }
    } catch (e) {
      //print("Exception pendant la récupération : $e");
      // En cas d'exception, nous la faisons remonter
      throw Exception("Erreur lors de la récupération des sujets.");
    }
  }

  /// Fonction appelée lorsque le Drawer est ouvert
  void _onDrawerOpened() {
    setState(() {
      drawerData = loadSubjects();
    });
  }

  /// Ouvre ou ferme le menu latéral (Drawer)
  void openMenu() {
    scaffoldKey.currentState?.openDrawer();
  }

  /// Ferme le menu latéral (Drawer)
  void closeMenu() {
    scaffoldKey.currentState?.closeDrawer();
  }

  /// Envoie le message saisi par l'utilisateur
  void send() async {
    setState(() {
      if (widget.conversation == null) {
        // Si la conversation est nulle, on crée une nouvelle conversation
        widget.conversation = Conversation(
          id: "-1",
          title: "",
          messages: [
            ["user", inputController.text, ""],
          ],
        );
      } else {
        // Sinon, on ajoute le message à la conversation existante
        widget.conversation?.addMessage("user", inputController.text, "");
      }
      isLoading = true;
      widget.conversation?.messages.add(["system", "loading", ""]); // message temporaire pour l'animation
    });
    _scrollToBottom();

    // Prépare la requête pour envoyer le message
    final uri = Uri.parse('$urlPrefix/send');

    final request =
        http.MultipartRequest('POST', uri)
          ..fields['content'] = inputController.text
          ..fields['use_web'] = researchMode.toString()
          ..fields['conversation_id'] = (widget.conversation?.id).toString()
          ..headers['Authorization'] = 'Bearer ${user.accessToken}';

    // Ajoute les fichiers à la requête s'il y en a
    for (var file in files) {
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final multipartFile = http.MultipartFile('files', fileStream, fileLength, filename: p.basename(file.path));
      request.files.add(multipartFile);
    }

    // Reset le champ de saisie et la liste des fichiers
    inputController.clear();
    if (files.isNotEmpty) {
      files.clear();
    }

    try {
      // Envoie la requête
      final response = await request.send();

      if (response.statusCode == 200) {
        //print("Envoi de message réussi");

        final responseBody = await response.stream.bytesToString();
        final json = jsonDecode(responseBody);

        if(context.mounted) {
          final String conversationId = json['conversation_id'].toString();
          final String responseText = json['response'].toString();
          final String title = json['title'].toString();
          final String emotion = (json['emotion'] ?? 'naturel').toString().replaceAll("#", "");

          if (widget.conversation?.id == "-1") {
            // Si la conversation est nouvelle, on lui donne un ID reçu
            widget.conversation?.id = conversationId;
          }

          setState(() {
            isLoading = false;
            // Remplace le "loading" par la vraie réponse
            final firstIndex = widget.conversation!.messages.indexWhere((msg) => msg[0] == "system" && msg[1] == "loading");
            if (firstIndex != -1) {
              widget.conversation!.messages[firstIndex] = ["assistant", responseText, emotion];
              if (widget.conversation?.title == "") {
                // Si le titre de la conversation est vide, on le met à jour
                widget.conversation?.title = title;
              }
            }
          });
        }

      } else {
        // Message d'erreur
        //print("Erreur lors de la récupération des messages : ${response.statusCode}");
        if(context.mounted) {
          setState(() {
            isLoading = false;
            // Remplace le "loading" par un message d'erreur
            final firstIndex = widget.conversation!.messages.indexWhere((msg) => msg[0] == "system" && msg[1] == "loading");
            if (firstIndex != -1) {
              widget.conversation!.messages[firstIndex] = ["assistant", "Erreur lors de la récupération des messages", ""];
            }
          });
        }

      }
    } catch (e) {
      // Exception : message d'erreur
      //print("Exception pendant la récupération : $e");
      if(context.mounted) {
        setState(() {
          isLoading = false;
          // Remplace le "loading" par un message d'erreur
          final lastIndex = widget.conversation!.messages.lastIndexWhere((msg) => msg[0] == "system" && msg[1] == "loading");
          if (lastIndex != -1) {
            widget.conversation!.messages[lastIndex] = ["assistant", "Erreur lors de la récupération des messages", ""];
          }
        });
      }
    }
  }

  /// Active ou désactive le mode de recherche avancée
  void switchResearchMode() {
    // Si il y a des fichiers, on ne peut pas activer la recherche web
    if(!researchMode && files.isNotEmpty) {
      // Si on est en mode recherche web et qu'il y a des fichiers, on affiche un message d'avertissement
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AutoSizeText(
            "Veuillez supprimer les fichiers avant d'activer la recherche en ligne.",
            style: const TextStyle(color: Colors.white, fontSize: 20),
            maxLines: 1,
            maxFontSize: 20,
            minFontSize: 8,
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      researchMode = !researchMode;
    });

    // Cacher le SnackBar précédent s'il est visible
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Afficher le SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(researchMode ? Icons.check_circle_outline : Icons.highlight_off, color: researchMode ? Colors.white : Colors.white, size: 30),
            const SizedBox(width: 20),
            SizedBox(
              width: MediaQuery.of(context).size.width - 100,
              child: AutoSizeText(
                researchMode ? "Recherche avancée via Internet activée" : "Recherche avancée via Internet désactivée",
                style: const TextStyle(color: Colors.white, fontSize: 20),
                maxLines: 1,
                maxFontSize: 20,
                minFontSize: 8,
              ),
            ),
          ],
        ),
        backgroundColor: researchMode ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Sélectionne des fichiers à envoyer
  Future<void> selectFiles() async {
    // Ouvre le sélecteur de fichiers
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.custom, allowedExtensions: ['txt', 'pdf', 'markdown', 'md']);

    if (result != null) {
      List<File> selectedFiles = result.paths.map((path) => File(path!)).toList();
      for (File f in selectedFiles) {
        if (await f.length() > 24000000 || files.length >= 4 || files.any((file) => file.path == f.path)) {
          // Si le fichier est déjà dans la liste ou qu'on a déjà 4 fichiers, on ne l'ajoute pas
          continue;
        } else {
          files.add(f);
        }
      }

      // Si on est en mode recherche web, on affiche un message d'avertissement
      if (researchMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AutoSizeText(
              "Recherche web désactivée pour pouvoir envoyer des fichiers.",
              style: const TextStyle(color: Colors.white, fontSize: 20),
              maxLines: 1,
              maxFontSize: 20,
              minFontSize: 8,
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        researchMode = false;
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1000;
        return Scaffold(
          key: scaffoldKey,
          backgroundColor: const Color(0xFF0B101A),
          drawer: isWide
              ? null
              : Drawer(
                  width: 320,
                  backgroundColor: const Color(0xFF111827),
                  child: SafeArea(
                    child: _buildConversationSidebar(isDrawer: true),
                  ),
                ),
          onDrawerChanged: (isOpened) {
            if (isOpened) _onDrawerOpened();
          },
          body: SafeArea(
            child: isWide
                ? Row(
                    children: [
                      _buildPrimarySidebar(),
                      _buildConversationSidebar(),
                      Expanded(child: _buildChatSection(isWide: true)),
                    ],
                  )
                : _buildChatSection(isWide: false),
          ),
        );
      },
    );
  }

  Widget _buildPrimarySidebar() {
    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset('assets/logo.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 32),
          _buildSidebarIcon(icon: Icons.chat_bubble_outline, active: true),
          _buildSidebarIcon(icon: Icons.folder_copy_outlined),
          _buildSidebarIcon(icon: Icons.analytics_outlined),
          _buildSidebarIcon(icon: Icons.settings_outlined),
          const Spacer(),
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF1F2937),
              child: Text(
                user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarIcon({required IconData icon, bool active = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {},
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1F2937) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: active ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.06)),
          ),
          child: Icon(icon, color: active ? Colors.white : Colors.white60),
        ),
      ),
    );
  }
  Widget _buildConversationSidebar({bool isDrawer = false}) {
    return Container(
      width: isDrawer ? double.infinity : 320,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(isDrawer ? 0 : 0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Chats',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stay on top of your conversations',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => DiscussionPage.empty()),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'New conversation',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.search, color: Colors.white54),
                  ),
                  Expanded(
                    child: TextField(
                      controller: subjectSearchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search conversations',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (subjectSearch.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        subjectSearchController.clear();
                      },
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<ConversationSubject>>(
              future: drawerData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white24),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        '${snapshot.error}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No conversations yet',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15),
                    ),
                  );
                }

                final sujets = snapshot.data!;
                final filteredSubjects = sujets.where((subject) {
                  if (subjectSearch.isEmpty) return true;
                  return subject.titre.toLowerCase().contains(subjectSearch.toLowerCase());
                }).toList();

                if (filteredSubjects.isEmpty) {
                  return Center(
                    child: Text(
                      'No conversations found',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: filteredSubjects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final subject = filteredSubjects[index];
                    final isActive = widget.conversation?.id == subject.id;
                    final formattedDate = _formatDate(subject.lastUpdate);

                    return GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiscussionPage(
                              titre: subject.titre,
                              conversation: Conversation(
                                id: subject.id,
                                title: subject.titre,
                                messages: [],
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: isActive ? Colors.white.withOpacity(0.3) : Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.forum_outlined, color: Colors.white70),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subject.titre,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () {
                                removeDiscussion(subject.id);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.delete_outline, color: Colors.white70, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF1F2937),
                    child: Text(
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.username,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Active session',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _buildHeaderAction(
                    icon: Icons.logout,
                    tooltip: 'Log out',
                    onTap: logout,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildChatSection({required bool isWide}) {
    final conversationTitle = widget.conversation?.title.isNotEmpty == true
        ? widget.conversation!.title
        : (widget.titre.isNotEmpty ? widget.titre : 'New conversation');

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B101A), Color(0xFF111A2C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 36 : 20,
              vertical: isWide ? 32 : 20,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!isWide)
                  _buildHeaderAction(
                    icon: Icons.menu,
                    tooltip: 'Open conversations',
                    onTap: openMenu,
                  )
                else
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF1F2937),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.white70),
                  ),
                SizedBox(width: isWide ? 20 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        conversationTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isWide ? 24 : 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        researchMode ? 'Web search enabled' : 'Local knowledge base',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  _buildStatusChip('Generating response...'),
                if (!isWide) const SizedBox(width: 8),
                _buildHeaderAction(
                  icon: Icons.refresh,
                  tooltip: 'Reload conversations',
                  onTap: () {
                    setState(() {
                      drawerData = loadSubjects();
                    });
                  },
                ),
                if (isWide) const SizedBox(width: 12),
                _buildHeaderAction(
                  icon: Icons.logout,
                  tooltip: 'Log out',
                  onTap: logout,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: isWide ? 36 : 16),
              padding: EdgeInsets.all(isWide ? 28 : 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(isWide ? 30 : 22),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isWide ? 24 : 18),
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                  child: widget.conversation == null
                      ? _buildEmptyState()
                      : _buildMessagesList(isWide: isWide),
                ),
              ),
            ),
          ),
          if (files.isNotEmpty) _buildFilesPreview(isWide: isWide),
          _buildInputBar(isWide: isWide),
        ],
      ),
    );
  }

  Widget _buildMessagesList({required bool isWide}) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: isWide ? 24 : 20),
      itemCount: widget.conversation?.messages.length ?? 0,
      itemBuilder: (context, index) {
        final messageData = widget.conversation?.messages[index];
        if (messageData == null || messageData.isEmpty || messageData[0] == 'file') {
          return const SizedBox.shrink();
        }

        final role = messageData[0].toString();
        final messageContent = messageData[1].toString();
        final isUser = role == 'user';
        final isBot = role == 'assistant';
        var emotion = 'naturel';
        if (messageData.length >= 3) {
          final rawEmotion = messageData[2];
          if (rawEmotion is String && rawEmotion.isNotEmpty) {
            emotion = rawEmotion;
          }
        }

        final isLoadingMessage = messageContent == 'loading';

        final bubble = Container(
          constraints: BoxConstraints(maxWidth: isWide ? 540 : MediaQuery.of(context).size.width * 0.8),
          padding: EdgeInsets.symmetric(horizontal: isWide ? 20 : 16, vertical: isWide ? 18 : 14),
          decoration: BoxDecoration(
            gradient: isUser
                ? const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isUser ? null : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(22),
              topRight: const Radius.circular(22),
              bottomLeft: Radius.circular(isUser ? 22 : 6),
              bottomRight: Radius.circular(isUser ? 6 : 22),
            ),
            border: Border.all(color: Colors.white.withOpacity(isUser ? 0.0 : 0.05)),
            boxShadow: [
              if (isUser)
                const BoxShadow(
                  color: Color(0x552563EB),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: isLoadingMessage
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : MarkdownBody(
                  data: messageContent,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: isWide ? 15 : 14, height: 1.5),
                    code: TextStyle(color: Colors.white.withOpacity(0.9), fontFamily: 'monospace', fontSize: isWide ? 14 : 13),
                    blockquote: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: isWide ? 15 : 14, fontStyle: FontStyle.italic),
                    h1: TextStyle(color: Colors.white, fontSize: isWide ? 26 : 22, fontWeight: FontWeight.bold),
                    h2: TextStyle(color: Colors.white, fontSize: isWide ? 24 : 20, fontWeight: FontWeight.bold),
                    h3: TextStyle(color: Colors.white, fontSize: isWide ? 22 : 18, fontWeight: FontWeight.bold),
                    h4: TextStyle(color: Colors.white, fontSize: isWide ? 20 : 17, fontWeight: FontWeight.bold),
                    h5: TextStyle(color: Colors.white, fontSize: isWide ? 18 : 16, fontWeight: FontWeight.bold),
                    h6: TextStyle(color: Colors.white, fontSize: isWide ? 16 : 15, fontWeight: FontWeight.bold),
                    a: const TextStyle(color: Color(0xFF60A5FA), decoration: TextDecoration.underline),
                    strong: TextStyle(color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.w700),
                    em: TextStyle(color: Colors.white.withOpacity(0.85), fontStyle: FontStyle.italic),
                    del: TextStyle(color: Colors.white.withOpacity(0.7), decoration: TextDecoration.lineThrough),
                    blockquoteDecoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    listBullet: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: isWide ? 15 : 14),
                  ),
                ),
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (isBot) ...[
                _buildEmotionAvatar(emotion),
                const SizedBox(width: 16),
              ],
              Flexible(child: bubble),
              if (isUser) ...[
                const SizedBox(width: 16),
                _buildUserAvatar(),
              ],
            ],
          ),
        );
      },
    );
  }
  Widget _buildEmotionAvatar(String emotion) {
    final assetName = listeEmotions.contains(emotion) ? emotion : 'naturel';
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset('assets/images/$assetName.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      alignment: Alignment.center,
      child: Text(
        user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white70, size: 40),
          ),
          const SizedBox(height: 24),
          const Text(
            'How can I assist you today?',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'Start by asking a question or describe the context you need help with.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesPreview({required bool isWide}) {
    return Container(
      height: 70,
      margin: EdgeInsets.fromLTRB(isWide ? 36 : 16, 18, isWide ? 36 : 16, 0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.insert_drive_file, color: Colors.white70, size: 20),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    p.basename(file.path),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      files.removeAt(index);
                    });
                  },
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  Widget _buildInputBar({required bool isWide}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 36 : 16, 20, isWide ? 36 : 16, isWide ? 32 : 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildInputIcon(
              icon: Icons.attachment_outlined,
              tooltip: 'Attach files',
              onTap: selectFiles,
            ),
            const SizedBox(width: 12),
            _buildInputIcon(
              icon: Icons.public,
              tooltip: 'Toggle web search',
              onTap: switchResearchMode,
              isActive: researchMode,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: inputController,
                decoration: InputDecoration(
                  hintText: 'Type your message... ',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
                  border: InputBorder.none,
                  counterText: '',
                ),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                cursorColor: const Color(0xFF38BDF8),
                maxLength: 25000,
                minLines: 1,
                maxLines: 6,
                onSubmitted: (_) => send(),
              ),
            ),
            if (Platform.isAndroid)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildInputIcon(
                  icon: isListeningMic ? Icons.stop : Icons.mic,
                  tooltip: isListeningMic ? 'Stop listening' : 'Start voice input',
                  onTap: () {
                    if (_speechEnabled && !_isListening) {
                      setState(() {
                        isListeningMic = true;
                      });
                      _currentText = inputController.text;
                      _startListening();
                    } else if (_speechEnabled && _isListening) {
                      setState(() {
                        isListeningMic = false;
                      });
                      _stopListening();
                    }
                  },
                  isActive: isListeningMic,
                ),
              ),
            GestureDetector(
              onTap: send,
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputIcon({required IconData icon, required VoidCallback onTap, String? tooltip, bool isActive = false}) {
    final iconWidget = Icon(icon, color: isActive ? const Color(0xFF38BDF8) : Colors.white70);
    final content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0B2948) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isActive ? const Color(0xFF38BDF8) : Colors.white.withOpacity(0.06)),
        ),
        child: Center(child: iconWidget),
      ),
    );

    if (tooltip is String) {
      return Tooltip(message: tooltip, child: content);
    }
    return content;
  }

  Widget _buildHeaderAction({required IconData icon, VoidCallback? onTap, String? tooltip}) {
    final action = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: Colors.white70),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip, child: action);
    }
    return action;
  }

  Widget _buildStatusChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} h ago';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
