import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:website_university/constantes/model.dart';
import 'package:website_university/routes/home.dart';

import 'package:website_university/routes/pages/ajoutEtablissement.dart';
import 'package:website_university/routes/pages/ajoutdocument.dart';
import 'package:website_university/routes/profile.dart';
import 'package:website_university/services/authentification.dart';
import 'package:website_university/services/firestorage.dart';
import 'package:website_university/services/variableStatic.dart';
import 'package:website_university/splash.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart';
import 'constantes/widget.dart';

void main() async {
  //await Authentification(FirebaseAuth.instance).deconnection();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Authentification>(
          create: (_) => Authentification(FirebaseAuth.instance),
        ),
        StreamProvider(
            create: (conext) =>
                context.read<Authentification>().authStateChanges),
      ],
      child: GetMaterialApp(
        title: 'Fluse',
        theme: ThemeData(
          primarySwatch: Colors.grey,
        ),
        home: FluseWebsite(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

bool isCharging = true;

class FluseWebsite extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<Authentification>();
    print(firebaseUser);
    return FutureBuilder(
      future: getAssets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return chargement();
        if (snapshot.connectionState == ConnectionState.none) {
          return erreurChargement('Erreur de connexion');
        }
        print(currentVersion);
        return StreamBuilder<User>(
            stream: firebaseUser.authStateChanges,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return chargement();
              if (!snapshot.hasData)
                return Splash();
              else {
                print(snapshot.data.uid);
                return StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('Utilisateur')
                        .doc(snapshot.data.uid)
                        .snapshots(),
                    builder: (context, doc) {
                      if (doc.connectionState == ConnectionState.waiting)
                        return chargement();
                      if (doc.connectionState == ConnectionState.none)
                        return erreurChargement('Erreur de connexion');
                      if (doc.hasError) {
                        Get.rawSnackbar(
                            title: 'Erreur',
                            message: '',
                            icon: Icon(
                              Icons.error_sharp,
                              color: Colors.red,
                            ));
                        Authentification(FirebaseAuth.instance).deconnection();
                      }
                      if (doc.hasData) {
                        var user = doc.data;
                        print(user['nom']);
                        print(user['image']);
                        String imageurl = user['image'] ?? profile;
                        print(profile);
                        return ProxyProvider0(
                          update: (_, __) => Utilisateur(
                              nom: user['nom'],
                              image: imageurl,
                              email: user['email'],
                              password: user['password'],
                              filiere: user['filiere'],
                              semestre: user['semestre'],
                              admin: user['admin'],
                              universite: user['universite'],
                              uid: user['uid']),
                          child: Home(),
                        );
                      } else
                        return chargement();
                    });
              }
            });
      },
    );
  }
}
