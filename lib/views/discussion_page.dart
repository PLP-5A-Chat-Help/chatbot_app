import 'dart:convert';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'mails_page.dart';
import 'settings_page.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:path_provider/path_provider.dart';

import '../model/conversation_subject.dart';
import '../model/conversation.dart';
import '../model/mail_analysis.dart';
import '../variables.dart';
import '../utils/mail_report_generator.dart';
import '../utils/app_palette.dart';
import 'widgets/primary_navigation.dart';

/* ----------------------------------
  Projet 4A : Chatbot App
  Date : 11/06/2025
  discussion_page.dart
---------------------------------- */

/// Page de discussion
/// Cette page permet à l'utilisateur de discuter avec le chatbot.
class DiscussionPage extends StatefulWidget {
  DiscussionPage({super.key, required this.titre, required this.conversation, this.initialReport});
  DiscussionPage.empty({super.key, this.initialReport}) : titre = "", conversation = null;

  final String titre; // Titre de la discussion
  Conversation? conversation;
  final MailAnalysis? initialReport;

  @override
  State<DiscussionPage> createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<DiscussionPage> {
  // Variables
  GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<
        ScaffoldState
      >(); // Clé pour le Scaffold (utile pour gérer le Drawer)
  TextEditingController inputController =
      TextEditingController(); // Contrôleur pour le champ de saisie de texte
  final TextEditingController subjectSearchController = TextEditingController();
  String subjectSearch = "";
  late final ScrollController
  _scrollController; // Contrôleur pour le défilement de la liste des messages
  bool researchMode = false; // true = recherche web, false = recherche locale
  List<File> files = []; // Liste des fichiers sélectionnés
  bool isLoading = false; // Indique si une requête est en cours (animation)
  
  void _handleUserUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<List<ConversationSubject>>?
  drawerData; // Données pour le Drawer (liste des sujets de conversation)

  // Liste des émotions disponibles pour les messages du bot
  final listeEmotions = [
    "naturel",
    "amoureux",
    "colère",
    "détective",
    "effrayant",
    "endormi",
    "fatigué",
    "heureux",
    "inquiet",
    "intello",
    "pensif",
    "professeur",
    "soulagé",
    "surpris",
    "triste",
  ];

  // Instance de SpeechToText pour la reconnaissance vocale
  final SpeechToText _speechToText = SpeechToText();
  bool isListeningMic = false; // Indique si le microphone est en écoute
  bool _speechEnabled =
      false; // Indique si la reconnaissance vocale est activée
  bool _isListening = false; // Indique si la reconnaissance vocale est en cours
  String _currentText =
      ""; // Texte actuel saisi dans le champ de saisie (pour ajouter le texte reconnu à la suite de ce qui est déjà écrit)

  // Initialisation de l'utilisateur
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    inputController.addListener(_onInputChanged);
    user.addListener(_handleUserUpdated);

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

    if (widget.initialReport != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prepareInitialReport(widget.initialReport!);
      });
    }

    // Charge le SpeechToText si l'application est sur Android
    if (Platform.isAndroid) {
      _initSpeech();
    }
  }

  @override
  void dispose() {
    inputController.removeListener(_onInputChanged);
    inputController.dispose();
    subjectSearchController.dispose();
    _scrollController.dispose();
    user.removeListener(_handleUserUpdated);
    super.dispose();
  }

  void _onInputChanged() {
    if (!mounted) return;
    setState(() {});
  }

  bool get _canSendMessage => inputController.text.trim().isNotEmpty && !isLoading;

  /// Fonction pour descendre en bas de la liste des messages
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
  }

  Future<void> _prepareInitialReport(MailAnalysis mail) async {
    try {
      final bytes = await MailReportGenerator.buildReport(mail);
      final directory = await getTemporaryDirectory();
      final file = File(p.join(directory.path, _buildReportFileName(mail.subject)));
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      setState(() {
        files.add(file);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rapport "${mail.subject}" attaché à la conversation.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de préparer le rapport : $e')),
      );
    }
  }

  void _openMailsPage() {
    final navigator = Navigator.of(context);
    navigator.push(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => MailsPage(
          onStartConversation: (mailContext, mail) {
            Navigator.of(mailContext).push(
              PageRouteBuilder(
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                pageBuilder: (_, __, ___) => DiscussionPage(
                  titre: mail.subject,
                  conversation: null,
                  initialReport: mail,
                ),
              ),
            );
          },
          onOpenChat: () {
            navigator.pushAndRemoveUntil(
              PageRouteBuilder(
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                pageBuilder: (_, __, ___) => DiscussionPage.empty(),
              ),
              (route) => route.isFirst,
            );
          },
          onOpenSettings: () {
            navigator.pushReplacement(
              PageRouteBuilder(
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                pageBuilder: (_, __, ___) => SettingsPage(
                  onChatRequested: () {
                    navigator.pushAndRemoveUntil(
                      PageRouteBuilder(
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                        pageBuilder: (_, __, ___) => DiscussionPage.empty(),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                  onMailsRequested: () {
                    _openMailsPage();
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openSettingsPage() {
    final navigator = Navigator.of(context);
    navigator.push(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => SettingsPage(
          onChatRequested: () {
            navigator.pushAndRemoveUntil(
              PageRouteBuilder(
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                pageBuilder: (_, __, ___) => DiscussionPage.empty(),
              ),
              (route) => route.isFirst,
            );
          },
          onMailsRequested: () {
            _openMailsPage();
          },
        ),
      ),
    );
  }

  // ---------------------------------- Speech-to-text ----------------------------------

  /// Initialise le SpeechToText
  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
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
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${user.accessToken}';

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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => DiscussionPage(titre: "", conversation: null),
              ),
            );
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
    final loadedConversation = Conversation(
      id: widget.conversation!.id,
      title: widget.titre,
      messages: [],
    );

    // Prépare l'URL pour la requête de récupération de la conversation
    final uri = Uri.parse('$urlPrefix/chat/${loadedConversation.id}');
    final request = http.MultipartRequest('GET', uri)
      ..headers['Authorization'] = 'Bearer ${user.accessToken}';

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
        loadedConversation.messages.addAll(messages);

        setState(() {
          widget.conversation?.messages.clear();
          widget.conversation?.messages.addAll(loadedConversation.messages);
        });
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
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${user.accessToken}';
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
      request.headers.set(
        HttpHeaders.authorizationHeader,
        "Bearer ${user.accessToken}",
      );

      final response = await request.close();

      if (response.statusCode == 200) {
        //print("Récupération des sujets réussie");

        final responseBody = await response.transform(utf8.decoder).join();
        final List<dynamic> data = jsonDecode(responseBody);
        // Convertit la liste JSON en liste d'objets ConversationSubject
        List<ConversationSubject> listeSujets =
            data.map((json) => ConversationSubject.fromJson(json)).toList();
        // Trie la liste des sujets par date de dernière mise à jour
        listeSujets.sort(
          (a, b) => b.lastUpdate.compareTo(
            a.lastUpdate,
          ), // Tri par date de dernière mise à jour, du plus récent au plus ancien
        );
        return listeSujets;
      } else {
        //print("Erreur lors de la récupération des sujets : ${response.statusCode}");
        // En cas d'erreur, nous la faisons remonter
        throw Exception(
          "Erreur lors de la récupération des sujets : ${response.statusCode}",
        );
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
    final message = inputController.text.trim();
    if (message.isEmpty || isLoading) {
      return;
    }
    setState(() {
      if (widget.conversation == null) {
        // Si la conversation est nulle, on crée une nouvelle conversation
        widget.conversation = Conversation(
          id: "-1",
          title: "",
          messages: [
            ["user", message, ""],
          ],
        );
      } else {
        // Sinon, on ajoute le message à la conversation existante
        widget.conversation?.addMessage("user", message, "");
      }
      isLoading = true;
      widget.conversation?.messages.add([
        "system",
        "loading",
        "",
      ]); // message temporaire pour l'animation
    });
    _scrollToBottom();

    // Prépare la requête pour envoyer le message
    final uri = Uri.parse('$urlPrefix/send');

    final request =
        http.MultipartRequest('POST', uri)
          ..fields['content'] = message
          ..fields['use_web'] = researchMode.toString()
          ..fields['conversation_id'] = (widget.conversation?.id).toString()
          ..headers['Authorization'] = 'Bearer ${user.accessToken}';

    // Ajoute les fichiers à la requête s'il y en a
    for (var file in files) {
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final multipartFile = http.MultipartFile(
        'files',
        fileStream,
        fileLength,
        filename: p.basename(file.path),
      );
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

        if (context.mounted) {
          final String conversationId = json['conversation_id'].toString();
          final String responseText = json['response'].toString();
          final String title = json['title'].toString();
          final String emotion = (json['emotion'] ?? 'naturel')
              .toString()
              .replaceAll("#", "");

          if (widget.conversation?.id == "-1") {
            // Si la conversation est nouvelle, on lui donne un ID reçu
            widget.conversation?.id = conversationId;
          }

          setState(() {
            isLoading = false;
            // Remplace le "loading" par la vraie réponse
            final firstIndex = widget.conversation!.messages.indexWhere(
              (msg) => msg[0] == "system" && msg[1] == "loading",
            );
            if (firstIndex != -1) {
              widget.conversation!.messages[firstIndex] = [
                "assistant",
                responseText,
                emotion,
              ];
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
        if (context.mounted) {
          setState(() {
            isLoading = false;
            // Remplace le "loading" par un message d'erreur
            final firstIndex = widget.conversation!.messages.indexWhere(
              (msg) => msg[0] == "system" && msg[1] == "loading",
            );
            if (firstIndex != -1) {
              widget.conversation!.messages[firstIndex] = [
                "assistant",
                "Erreur lors de la récupération des messages",
                "",
              ];
            }
          });
        }
      }
    } catch (e) {
      // Exception : message d'erreur
      //print("Exception pendant la récupération : $e");
      if (context.mounted) {
        setState(() {
          isLoading = false;
          // Remplace le "loading" par un message d'erreur
          final lastIndex = widget.conversation!.messages.lastIndexWhere(
            (msg) => msg[0] == "system" && msg[1] == "loading",
          );
          if (lastIndex != -1) {
            widget.conversation!.messages[lastIndex] = [
              "assistant",
              "Erreur lors de la récupération des messages",
              "",
            ];
          }
        });
      }
    }
  }

  /// Active ou désactive le mode de recherche avancée
  void switchResearchMode() {
    // Si il y a des fichiers, on ne peut pas activer la recherche web
    if (!researchMode && files.isNotEmpty) {
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
            Icon(
              researchMode ? Icons.check_circle_outline : Icons.highlight_off,
              color: researchMode ? Colors.white : Colors.white,
              size: 30,
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: MediaQuery.of(context).size.width - 100,
              child: AutoSizeText(
                researchMode
                    ? "Recherche avancée via Internet activée"
                    : "Recherche avancée via Internet désactivée",
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['txt', 'pdf', 'markdown', 'md'],
    );

    if (result != null) {
      List<File> selectedFiles =
          result.paths.map((path) => File(path!)).toList();
      for (File f in selectedFiles) {
        if (await f.length() > 24000000 ||
            files.length >= 4 ||
            files.any((file) => file.path == f.path)) {
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
    final palette = AppPalette.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1000;
        return Scaffold(
          key: scaffoldKey,
          backgroundColor: palette.background,
          drawer: isWide
              ? null
              : Drawer(
                  width: 320,
                  backgroundColor: palette.surface,
                  child: SafeArea(
                    child: _buildConversationSidebar(
                      palette: palette,
                      isDrawer: true,
                    ),
                  ),
                ),
          onDrawerChanged: (isOpened) {
            if (isOpened) _onDrawerOpened();
          },
          body: SafeArea(
            child: isWide
                ? Row(
                    children: [
                      PrimaryNavigation(
                        palette: palette,
                        activeIndex: 0,
                        onChatPressed: null,
                        onMailsPressed: _openMailsPage,
                        onSettingsPressed: _openSettingsPage,
                      ),
                      _buildConversationSidebar(palette: palette),
                      Expanded(
                        child: _buildChatSection(
                          isWide: true,
                          palette: palette,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      PrimaryNavigation(
                        palette: palette,
                        activeIndex: 0,
                        isHorizontal: true,
                        onChatPressed: null,
                        onMailsPressed: _openMailsPage,
                        onSettingsPressed: _openSettingsPage,
                      ),
                      Expanded(
                        child: _buildChatSection(
                          isWide: false,
                          palette: palette,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
  Widget _buildConversationSidebar({required AppPalette palette, bool isDrawer = false}) {
    return Container(
      width: isDrawer ? double.infinity : 320,
      decoration: BoxDecoration(
        color: palette.surface,
        border: isDrawer
            ? null
            : Border(
                right: BorderSide(color: palette.border),
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
                Text(
                  'Mes discussions',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Retrouvez facilement toutes vos conversations',
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                        pageBuilder: (_, __, ___) => DiscussionPage.empty(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [palette.primary, palette.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: palette.primary.withOpacity(0.3),
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
                            color: palette.accentTextOnPrimary.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Nouvelle discussion',
                            style: TextStyle(
                              color: palette.accentTextOnPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
                color: palette.mutedSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.search, color: palette.textMuted),
                  ),
                  Expanded(
                    child: TextField(
                      controller: subjectSearchController,
                      style: TextStyle(color: palette.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Rechercher une conversation',
                        hintStyle: TextStyle(color: palette.textMuted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (subjectSearch.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        subjectSearchController.clear();
                      },
                      icon: Icon(Icons.close, color: palette.textMuted),
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
                  return Center(
                    child: CircularProgressIndicator(color: palette.primary.withOpacity(0.5)),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        '${snapshot.error}',
                        style: TextStyle(color: palette.textSecondary, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucune conversation pour le moment',
                      style: TextStyle(color: palette.textSecondary, fontSize: 15),
                    ),
                  );
                }

                final sujets = snapshot.data!;
                final filteredSubjects =
                    sujets.where((subject) {
                      if (subjectSearch.isEmpty) return true;
                      return subject.titre.toLowerCase().contains(
                        subjectSearch.toLowerCase(),
                      );
                    }).toList();

                if (filteredSubjects.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucune conversation correspondante',
                      style: TextStyle(color: palette.textSecondary, fontSize: 15),
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
                    final backgroundColor = isActive
                        ? palette.primary.withOpacity(0.16)
                        : palette.surface;
                    final borderColor = isActive
                        ? palette.primary.withOpacity(0.35)
                        : palette.border;

                    final backgroundColor = isActive
                        ? palette.primary.withOpacity(0.16)
                        : palette.surface;
                    final borderColor = isActive
                        ? palette.primary.withOpacity(0.35)
                        : palette.border;

                    return GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                            pageBuilder: (_, __, ___) => DiscussionPage(
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
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: palette.mutedSurface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.forum_outlined, color: palette.textMuted),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subject.titre,
                                    style: TextStyle(
                                      color: palette.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(color: palette.textMuted, fontSize: 12),
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
                                  color: palette.mutedSurface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.delete_outline, color: palette.textMuted, size: 20),
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
                color: palette.mutedSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.border),
              ),
              child: AnimatedBuilder(
                animation: user,
                builder: (context, _) {
                  final avatarImage = resolveAvatarImage(user.avatarPath);
                  final initials = user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U';
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: palette.background,
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? Text(
                                initials,
                                style: TextStyle(
                                  color: palette.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user.username,
                              style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Session active',
                              style: TextStyle(color: palette.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildChatSection({required bool isWide, required AppPalette palette}) {
    final conversationTitle = widget.conversation?.title.isNotEmpty == true
        ? widget.conversation!.title
        : (widget.titre.isNotEmpty ? widget.titre : 'Nouvelle conversation');

    return Container(
      color: palette.background,
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
                    palette,
                    icon: Icons.menu,
                    tooltip: 'Ouvrir les conversations',
                    onTap: openMenu,
                  )
                else
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: palette.mutedSurface,
                    child: Icon(Icons.warning_amber_rounded, color: palette.warning),
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
                          color: palette.textPrimary,
                          fontSize: isWide ? 24 : 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        researchMode
                            ? 'Recherche web activée'
                            : 'Base de connaissances locale',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  _buildStatusChip(palette, 'Réponse en cours...'),
                if (!isWide) const SizedBox(width: 8),
                _buildHeaderAction(
                  palette,
                  icon: Icons.refresh,
                  tooltip: 'Rafraîchir les conversations',
                  onTap: () {
                    setState(() {
                      drawerData = loadSubjects();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: isWide ? 36 : 16),
              padding: EdgeInsets.all(isWide ? 28 : 18),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(isWide ? 30 : 22),
                border: Border.all(color: palette.border),
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isWide ? 24 : 18),
                child: Container(
                  color: palette.background,
                  child: widget.conversation == null
                      ? _buildEmptyState(palette: palette)
                      : _buildMessagesList(isWide: isWide, palette: palette),
                ),
              ),
            ),
          ),
          if (files.isNotEmpty) _buildFilesPreview(isWide: isWide, palette: palette),
          _buildInputBar(isWide: isWide, palette: palette),
        ],
      ),
    );
  }

  Widget _buildMessagesList({required bool isWide, required AppPalette palette}) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 24 : 16,
        vertical: isWide ? 24 : 20,
      ),
      itemCount: widget.conversation?.messages.length ?? 0,
      itemBuilder: (context, index) {
        final messageData = widget.conversation?.messages[index];
        if (messageData == null ||
            messageData.isEmpty ||
            messageData[0] == 'file') {
          return const SizedBox.shrink();
        }

        final role = messageData[0].toString();
        final messageContent = messageData[1].toString();
        final isUser = role == 'user';
        final isBot = role == 'assistant';
        var emotion = 'naturel';
        if (messageData.length >= 3) {
          final rawEmotion = messageData[2];
          // ignore: unnecessary_type_check
          if (rawEmotion is String && rawEmotion.isNotEmpty) {
            emotion = rawEmotion;
          }
        }

        final isLoadingMessage = messageContent == 'loading';

        final bubble = Container(
          constraints: BoxConstraints(
            maxWidth: isWide ? 540 : MediaQuery.of(context).size.width * 0.8,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 20 : 16,
            vertical: isWide ? 18 : 14,
          ),
          decoration: BoxDecoration(
            gradient: isUser
                ? const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isUser ? null : palette.mutedSurface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(22),
              topRight: const Radius.circular(22),
              bottomLeft: Radius.circular(isUser ? 22 : 6),
              bottomRight: Radius.circular(isUser ? 6 : 22),
            ),
            border: Border.all(color: isUser ? Colors.transparent : palette.border),
            boxShadow: [
              if (isUser)
                const BoxShadow(
                  color: Color(0x552563EB),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                )
              else
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: isLoadingMessage
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: palette.primary),
                )
              : MarkdownBody(
                  data: messageContent,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: isUser ? palette.accentTextOnPrimary : palette.textPrimary,
                      fontSize: isWide ? 15 : 14,
                      height: 1.5,
                    ),
                    code: TextStyle(
                      color: palette.textPrimary,
                      fontFamily: 'monospace',
                      fontSize: isWide ? 14 : 13,
                    ),
                    blockquote: TextStyle(
                      color: palette.textSecondary,
                      fontSize: isWide ? 15 : 14,
                      fontStyle: FontStyle.italic,
                    ),
                    h1: TextStyle(color: palette.textPrimary, fontSize: isWide ? 26 : 22, fontWeight: FontWeight.bold),
                    h2: TextStyle(color: palette.textPrimary, fontSize: isWide ? 24 : 20, fontWeight: FontWeight.bold),
                    h3: TextStyle(color: palette.textPrimary, fontSize: isWide ? 22 : 18, fontWeight: FontWeight.bold),
                    h4: TextStyle(color: palette.textPrimary, fontSize: isWide ? 20 : 17, fontWeight: FontWeight.bold),
                    h5: TextStyle(color: palette.textPrimary, fontSize: isWide ? 18 : 16, fontWeight: FontWeight.bold),
                    h6: TextStyle(color: palette.textPrimary, fontSize: isWide ? 16 : 15, fontWeight: FontWeight.bold),
                    a: TextStyle(color: palette.primary, decoration: TextDecoration.underline),
                    strong: TextStyle(
                      color: isUser ? palette.accentTextOnPrimary : palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    em: TextStyle(
                      color: isUser ? palette.accentTextOnPrimary : palette.textPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                    del: TextStyle(color: palette.textMuted, decoration: TextDecoration.lineThrough),
                    blockquoteDecoration: BoxDecoration(
                      color: palette.mutedSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.border),
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: palette.mutedSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.border),
                    ),
                    listBullet: TextStyle(
                      color: isUser ? palette.accentTextOnPrimary : palette.textPrimary,
                      fontSize: isWide ? 15 : 14,
                    ),
                  ),
                ),
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (isBot) ...[
                _buildEmotionAvatar(palette, emotion),
                const SizedBox(width: 16),
              ],
              Flexible(child: bubble),
              if (isUser) ...[
                const SizedBox(width: 16),
                _buildUserAvatar(palette),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmotionAvatar(AppPalette palette, String emotion) {
    final assetName = listeEmotions.contains(emotion) ? emotion : 'naturel';
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: palette.mutedSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset('assets/images/$assetName.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildUserAvatar(AppPalette palette) {
    final avatarImage = resolveAvatarImage(user.avatarPath);
    final initials = user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U';
    return CircleAvatar(
      radius: 21,
      backgroundColor: palette.primary,
      backgroundImage: avatarImage,
      child: avatarImage == null
          ? Text(
              initials,
              style: TextStyle(
                color: palette.accentTextOnPrimary,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState({required AppPalette palette}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: palette.mutedSurface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: palette.border),
            ),
            child: Icon(Icons.auto_awesome, color: palette.primary, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            'Comment puis-je vous aider aujourd\'hui ?',
            style: TextStyle(color: palette.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'Commencez par poser une question ou décrivez le contexte dans lequel vous avez besoin d'aide.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Text(
            'Analysez votre e-mail en 3 étapes simples :',
            style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '1. Connectez-vous à votre boîte mail.',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                '2. Transférez l\'email à analyser à l\'adresse "plp.chaton@gmail.com".',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                '3. Consultez le résultat directement dans cette application.',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilesPreview({required bool isWide, required AppPalette palette}) {
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
              color: palette.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insert_drive_file, color: palette.primary, size: 20),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    p.basename(file.path),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
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
                      color: palette.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: palette.primary, size: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar({required bool isWide, required AppPalette palette}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isWide ? 36 : 16,
        20,
        isWide ? 36 : 16,
        isWide ? 32 : 24,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: palette.border),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildInputIcon(
              palette,
              icon: Icons.attachment_outlined,
              tooltip: 'Joindre des fichiers',
              onTap: selectFiles,
            ),
            const SizedBox(width: 12),
            _buildInputIcon(
              palette,
              icon: Icons.public,
              tooltip: 'Activer ou désactiver la recherche en ligne',
              onTap: switchResearchMode,
              isActive: researchMode,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: inputController,
                decoration: InputDecoration(
                  hintText: 'Écrivez votre message...',
                  hintStyle: TextStyle(color: palette.textMuted),
                  border: InputBorder.none,
                  counterText: '',
                ),
                style: TextStyle(color: palette.textPrimary, fontSize: 15),
                cursorColor: palette.primary,
                maxLength: 25000,
                minLines: 1,
                maxLines: 6,
                onSubmitted: (_) {
                  if (_canSendMessage) {
                    send();
                  }
                },
              ),
            ),
            if (Platform.isAndroid)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildInputIcon(
                  palette,
                  icon: isListeningMic ? Icons.stop : Icons.mic,
                  tooltip: isListeningMic ? 'Arrêter l'écoute' : 'Dicter un message',
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
              onTap: _canSendMessage ? send : null,
              child: Opacity(
                opacity: _canSendMessage ? 1 : 0.35,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputIcon(
    AppPalette palette, {
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    bool isActive = false,
  }) {
    final iconWidget = Icon(icon, color: isActive ? palette.primary : palette.textMuted);
    final content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isActive ? palette.primary.withOpacity(0.18) : palette.mutedSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isActive ? palette.primary : palette.border),
        ),
        child: Center(child: iconWidget),
      ),
    );

    if (tooltip is String) {
      return Tooltip(message: tooltip, child: content);
    }
    return content;
  }

  Widget _buildHeaderAction(
    AppPalette palette, {
    required IconData icon,
    VoidCallback? onTap,
    String? tooltip,
  }) {
    final action = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: palette.mutedSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
        ),
        child: Icon(icon, color: palette.textMuted),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip, child: action);
    }
    return action;
  }

  Widget _buildStatusChip(AppPalette palette, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: palette.mutedSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: palette.primary),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(color: palette.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
  String _buildReportFileName(String subject) {
    final sanitized = subject.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-').replaceAll(RegExp(r'-{2,}'), '-');
    return '${sanitized.toLowerCase()}-rapport.pdf';
  }

  String _buildReportFileName(String subject) {
    final sanitized = subject
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-');
    return '${sanitized.toLowerCase()}-rapport.pdf';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours} h';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
