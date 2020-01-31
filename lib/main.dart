import 'package:flutter/material.dart';
import 'music.dart';
import 'package:audioplayer2/audioplayer2.dart';
import 'package:volume/volume.dart';
import 'package:flutter/services.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Application Music',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Music'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Musique> musicList = [
    new Musique('Grave', 'Eddy de Pretto', 'assets/eddy.jpg',
        'https://www.matieuio.fr/tutoriels/musiques/grave.mp3'),
    new Musique('Nuvole Blanche', 'Ludovico Einaudi', 'assets/le.jpg',
        'https://www.matieuio.fr/tutoriels/musiques/nuvole_bianche.mp3'),
    new Musique('These Days', 'Rudimental', 'assets/thesed.jpg',
        'https://www.matieuio.fr/tutoriels/musiques/these_days.mp3'),
  ];

  AudioManager audioManager;
  AudioPlayer audioPlayer;
  StreamSubscription positionSubscription;
  StreamSubscription stateSubscription;

  Musique actualMusic;
  Duration position = new Duration(seconds: 0);
  Duration duree = new Duration(seconds: 30);
  PlayerState statut = PlayerState.STOPPED;

  int index = 0;
  bool mute = false;
  int maxVol = 0, currentVol = 0;

  @override
  void initState() {
    super.initState();
    audioManager = AudioManager.STREAM_MUSIC;
    actualMusic = musicList[index];
    configAudioPlayer();
    initPlatformState();
    updateVolume();
  }

  double getVolumePourcent() {
    return (currentVol / maxVol) * 100;
  }

  /// Initialiser le volume
  Future<void> initPlatformState() async {
    await Volume.controlVolume(AudioManager.STREAM_MUSIC);
  }

  /// Update le volume
  updateVolume() async {
    maxVol = await Volume.getMaxVol;
    currentVol = await Volume.getVol;
    setState(() {});
  }

  /// Definir le volume
  setVol(int i) async {
    await Volume.setVol(i);
  }

  /// Gestion des Text avec Style.
  Text textWithStyle(String data, double scale) {
    return new Text(data,
        textScaleFactor: scale,
        textAlign: TextAlign.center,
        style: new TextStyle(color: Colors.black, fontSize: 15.0));
  }

  /// Gestion des Boutons
  IconButton bouton(IconData icone, double taille, ActionMusic action) {
    return new IconButton(
        icon: new Icon(icone),
        iconSize: taille,
        color: Colors.white,
        onPressed: () {
          switch (action) {
            case ActionMusic.PLAY:
              play();
              break;
            case ActionMusic.PAUSE:
              pause();
              break;
            case ActionMusic.REWIND:
              rewind();
              break;
            case ActionMusic.FORWARD:
              forward();
              break;
            default:
              break;
          }
        });
  }

  /// Configuration de l'audioPlayer
  void configAudioPlayer() {
    audioPlayer = new AudioPlayer();
    positionSubscription = audioPlayer.onAudioPositionChanged.listen((pos) {
      setState(() {
        position = pos;
      });
      if (position >= duree) {
        position = new Duration(seconds: 0);
        // Passer a la musique suivant (forwards);
      }
    });
    stateSubscription = audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == AudioPlayerState.PLAYING) {
        duree = audioPlayer.duration;
      } else if (state == AudioPlayerState.STOPPED) {
        setState(() {
          statut = PlayerState.STOPPED;
        });
      }
    }, onError: (message) {
      print(message);
      setState(() {
        statut = PlayerState.STOPPED;
        duree = new Duration(seconds: 0);
        position = new Duration(seconds: 0);
      });
    });
  }

  Future play() async {
    await audioPlayer.play(actualMusic.musicURL);
    setState(() {
      statut = PlayerState.PLAYING;
    });
  }

  Future pause() async {
    await audioPlayer.pause();
    setState(() {
      statut = PlayerState.PAUSED;
    });
  }

  Future muted() async {
    await audioPlayer.mute(!mute);
    setState(() {
      mute = !mute;
    });
  }

  ///Passer a la musique suivante
  void forward() {
    if (index == musicList.length - 1) {
      index = 0;
    } else {
      index++;
    }
    actualMusic = musicList[index];
    audioPlayer.stop();
    configAudioPlayer();
    play();
  }

  /// Retour a la musique precedentee
  void rewind() {
    if (position > Duration(seconds: 3)) {
      audioPlayer.seek(0.0);
    } else {
      if (index == 0) {
        index = musicList.length - 1;
      } else {
        index--;
      }
    }
    actualMusic = musicList[index];
    audioPlayer.stop();
    configAudioPlayer();
    play();
  }

  String fromDuration(Duration duree) {
    return duree.toString().split('.').first;
  }

  @override
  Widget build(BuildContext context) {
    double largeur = MediaQuery.of(context).size.width;

    int newVol = getVolumePourcent().toInt();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title),
        backgroundColor: Colors.blueGrey,
        elevation: 20.0,
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Container(
            width: 200,
            color: Colors.red,
            margin: EdgeInsets.only(top: 20.0),
            child: new Image.asset(actualMusic.imagePath),
          ),
          new Container(
            margin: EdgeInsets.only(top: 20.0),
            child: new Text(
              actualMusic.titre,
              textScaleFactor: 2,
            ),
          ),
          new Container(
            margin: EdgeInsets.only(top: 5.0),
            child: new Text(
              actualMusic.auteur,
            ),
          ),
          new Container(
            height: largeur / 5,
            margin: EdgeInsets.only(left: 10.0, right: 10.0),
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                new IconButton(
                    icon: new Icon(Icons.fast_rewind), onPressed: rewind),
                new IconButton(
                  icon: statut != PlayerState.PLAYING
                      ? new Icon(Icons.play_arrow)
                      : new Icon(Icons.pause),
                  onPressed: (statut != PlayerState.PLAYING) ? play : pause,
                  iconSize: 50,
                ),
                new IconButton(
                    icon: (mute)
                        ? new Icon(Icons.headset_off)
                        : new Icon(Icons.headset),
                    onPressed: muted),
                new IconButton(
                    icon: new Icon(Icons.fast_forward), onPressed: forward),
              ],
            ),
          ),
          new Container(
              margin: EdgeInsets.only(left: 10.0, right: 10.0),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  textWithStyle(fromDuration(position), 0.8),
                  textWithStyle(fromDuration(duree), 0.8),
                ],
              )),
          new Container(
            margin: EdgeInsets.only(left: 10.0, right: 10.0),
            child: new Slider(
                value: position.inSeconds.toDouble(),
                min: 0.0,
                max: duree.inSeconds.toDouble(),
                inactiveColor: Colors.deepPurpleAccent,
                onChanged: (double d) {
                  setState(() {
                    audioPlayer.seek(d);
                  });
                }),
          ),
          new Container(
            height: largeur / 5,
            margin: EdgeInsets.only(left: 5.0, right: 5.0, top: 0.0),
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new IconButton(
                    icon: new Icon(Icons.remove),
                    iconSize: 20,
                    onPressed: () {
                      if (!mute) {
                        Volume.volDown();
                        updateVolume();
                      }
                    }),
                new Slider(
                  value: currentVol / 1.0,
                  divisions: maxVol,
                  max: maxVol / 1.0,
                  min: 0,
                  inactiveColor: Colors.deepPurpleAccent,
                  onChanged: (double d) {
                    setVol(d.toInt());
                    updateVolume();
                  },
                ),
                new Text((mute) ? 'Mute' : '$newVol%'),
                new IconButton(
                    icon: new Icon(Icons.add),
                    iconSize: 20,
                    onPressed: () {
                      if (!mute) {
                        Volume.volUp();
                        updateVolume();
                      }
                    }),
              ],
            ),
          )
        ],
      )),
    );
  }
}

enum ActionMusic { PLAY, PAUSE, REWIND, FORWARD }

enum PlayerState { PLAYING, STOPPED, PAUSED }
