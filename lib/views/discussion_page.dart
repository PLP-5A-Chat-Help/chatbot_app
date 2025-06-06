import 'dart:convert';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:path/path.dart' as p;

import '../model/conversation_subject.dart';
import '../variables.dart';

class DiscussionPage extends StatefulWidget {
  const DiscussionPage({super.key, required this.titre, required this.listeMessages});
  const DiscussionPage.empty({super.key}) : titre = "", listeMessages = const [];

  final String titre; // Titre de la discussion
  final List<List<String>> listeMessages; // Map des messages de la discussion associés à qui les envoie

  @override
  State<DiscussionPage> createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<DiscussionPage> {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController inputController = TextEditingController();
  List<ConversationSubject> listeSujets = [];
  bool researchMode = false; // true = recherche web, false = recherche locale
  List<File> files = []; // Liste des fichiers sélectionnés

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Scroll to the bottom after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }


  void _scrollToBottom() {
    if(_scrollController.hasClients) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      });
    }
  }



  void logout() {
    user.clear();
    Navigator.pop(context);
  }

  void openMenu() async {

    // final client = await createSecureHttpClient();
    final client = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;

    final url = Uri.parse('$urlPrefix/conversations');
    final body = {
    };

    try {
      final request = await client.getUrl(url);
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
      // Ajout du token d'authentification
      request.headers.set(HttpHeaders.authorizationHeader, "Bearer ${user.accessToken}");


      final response = await request.close();

      if (response.statusCode == 200) {

        print("Récupération des sujets réussie");

        final responseBody = await response.transform(utf8.decoder).join();
        final List<dynamic> data = jsonDecode(responseBody);

        List<ConversationSubject> listeSujets = data.map((json) => ConversationSubject.fromJson(json)).toList();
        this.listeSujets = listeSujets;

      } else {
        print("Erreur lors de la récupération des sujets : ${response.statusCode}");
      }
    } catch (e) {
      print("Exception pendant la récupération : $e");
    }

    scaffoldKey.currentState?.openDrawer();

  }

  void closeMenu() {
    scaffoldKey.currentState?.closeDrawer();
  }

  void send() {
    // TODO
    inputController.clear();
  }

  void switchResearchMode() {
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

  Future<void> selectFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'markdown', 'md']
    );

    if (result != null) {
      List<File> selectedFiles = result.paths.map((path) => File(path!)).toList();

      for (File f in selectedFiles) {

        if( files.length >= 4 || files.any((file) => file.path == f.path)) {
          // Si le fichier est déjà dans la liste ou qu'on a déjà 4 fichiers, on ne l'ajoute pas
          continue;
        }
        else {
          files.add(f);
        }
      }
    }

    setState(() { });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color.fromRGBO(59, 59, 63, 1),

      // Menu latéral (Drawer)
      drawer: Drawer(
        width: 300,
        backgroundColor: const Color.fromRGBO(70, 70, 70, 1),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset("assets/logo.png", width: 128, height: 128),

              // Bouton pour créer une nouvelle discussion
              RawMaterialButton(
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DiscussionPage.empty()));
                },

                child: Container(
                  width: 300,
                  height: 50,
                  decoration: BoxDecoration(color: const Color.fromRGBO(103, 103, 103, 1)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(width: 10),
                      Text("Nouvelle discussion", style: TextStyle(color: Colors.white, fontSize: 20)),
                      Expanded(child: SizedBox()),
                      Icon(Icons.add_circle_outline, color: Colors.white, size: 32),
                      SizedBox(width: 16),
                    ],
                  ),
                ),
              ),

              // Liste des discussions
              SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: ListView.builder(
                  itemCount: listeSujets.length, // TODO : Remplacer par le nombre de discussions
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: RawMaterialButton(
                        onPressed: () {
                          // TODO : Ouvrir la discussion
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => DiscussionPage(
                                    titre: listeSujets[index].id,
                                    listeMessages: [],
                                  ),
                            ),
                          );
                        },

                        child: Container(
                          width: 300,
                          height: 50,
                          decoration: BoxDecoration(color: const Color.fromRGBO(103, 103, 103, 1)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(width: 10),
                              SizedBox(width: 230, child: AutoSizeText(listeSujets[index].titre, style: TextStyle(color: Colors.white, fontSize: 20), maxLines: 1, maxFontSize: 20, minFontSize: 8)),
                              const Expanded(child: SizedBox()),
                              IconButton(
                                onPressed: () {
                                  listeSujets.removeAt(index);
                                  setState(() {});
                                  // TODO : Supprimer la discussion
                                },
                                icon: const Icon(Icons.delete, color: Colors.white, size: 32),
                              ),
                              const SizedBox(width: 10),
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
      ),

      // Page de discussion
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Barre en haut
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(onPressed: openMenu, icon: Icon(Icons.menu, color: Colors.white, size: 50)),

              const Expanded(child: SizedBox()),

              SizedBox(
                width: MediaQuery.of(context).size.width - 150,
                height: 50,
                child: Center(child: AutoSizeText(widget.titre, maxLines: 1, maxFontSize: 40, minFontSize: 8, style: const TextStyle(color: Colors.white, fontSize: 40))),
              ),

              const Expanded(child: SizedBox()),

              IconButton(onPressed: logout, icon: Icon(Icons.logout, color: Colors.white, size: 50)),
            ],
          ),

          // Contenu de la discussion
          if (widget.listeMessages.isEmpty) const Expanded(child: SizedBox()),

          if (widget.listeMessages.isEmpty)
            const Center(child: Text("Comment puis-je vous aider ?", style: TextStyle(color: Colors.white, fontSize: 32), textAlign: TextAlign.center))
          else // Liste des messages
            Expanded(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: widget.listeMessages.length,
                  itemBuilder: (context, index) {
                    final isUser = widget.listeMessages[index][0] == "user";
                    final message = widget.listeMessages[index][1];

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7, // largeur max
                        ),
                        decoration: BoxDecoration(color: const Color.fromRGBO(85, 85, 85, 1), borderRadius: BorderRadius.circular(15)),
                        child: SelectableText(message, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ),
                    );
                  },
                ),
              ),
            ),

          if (widget.listeMessages.isEmpty) const Expanded(child: SizedBox()),
          const SizedBox(height: 5),

          // Barre de saisie
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 50,
            decoration: BoxDecoration(color: const Color.fromRGBO(85, 85, 85, 1), borderRadius: BorderRadius.circular(25)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(onPressed: selectFiles, icon: Icon(Icons.add, color: Colors.black45, size: 30)),
                IconButton(onPressed: switchResearchMode, icon: Icon(Icons.language, color: researchMode ? Colors.white70 : Colors.black45, size: 30)),

                Expanded(
                  child: TextField(
                    controller: inputController,
                    decoration: InputDecoration(hintText: "Posez votre question...", hintStyle: const TextStyle(color: Colors.white30), border: InputBorder.none, counterText: ""),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    cursorColor: Colors.white,
                    maxLength: 25000,

                    onSubmitted: (value) {
                      send();
                    },
                  ),
                ),

                IconButton(onPressed: send, icon: const Icon(Icons.send_rounded, color: Colors.black45, size: 30)),
              ],
            ),
          ),

          files.isEmpty ?
            const SizedBox(height: 50) :
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: files.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(85, 85, 85, 1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: SizedBox(
                      width: 200,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              p.basename(files[index].path),
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                files.removeAt(index);
                              });
                            },
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          )


        ],
      ),
    );
  }
}
