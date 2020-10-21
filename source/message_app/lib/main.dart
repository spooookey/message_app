import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:bubble/bubble.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "メッセージアプリ",
      routes: <String, WidgetBuilder> {
        "/": (_) => Splash(),
        "/list": (_) => List(),
      },
    );
  }
}

User firebaseUser;
final FirebaseAuth _auth = FirebaseAuth.instance;
class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    String email;
    String password;
    _getUser(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("新規登録/ログイン"),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(
                  icon: const Icon(Icons.email),
                  hintText: 'メールアドレス入力',
                  labelText: 'メールアドレス',
                ),
                onSaved: (String value) {
                  email = value;
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Emailは必須入力項目です';
                  }
                },
                onChanged: (String value) {
                  email = value;
                },
                initialValue: email,
              ),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(
                  icon: const Icon(Icons.vpn_key),
                  hintText: 'パスワード入力',
                  labelText: 'パスワード',
                ),
                onChanged: (String value) {
                  password = value;
                },
                onSaved: (String value) {
                  print("onSaved");
                  password = value;
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Passwordは必須入力項目です';
                  }
                  if (value.length < 6) {
                    return 'Passwordは6桁以上です';
                  }
                },
                initialValue: password,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  RaisedButton(
                    child: const Text("新規登録"),
                    onPressed: () {
                      _createUser(context, email, password);
                    },
                  ),
                  RaisedButton(
                    child: const Text("ログイン"),
                    onPressed: () {
                      _signIn(context, email, password);
                    },
                  ),
                ],
              )

            ],
          ),
        ),
      )
    );
  }

  void _getUser(BuildContext context) async {
    try {
      firebaseUser = await _auth.currentUser;
      if (firebaseUser != null) {
        // ログイン済みの場合はメッセージ一覧へ
        Navigator.pushReplacementNamed(context, "/list");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Firebaseとの接続に失敗しました");
    }
  }
}

class InputForm extends StatefulWidget {
  InputForm(this.document);
  final DocumentSnapshot document;

  @override
  _MyInputFormState createState() => _MyInputFormState();
}

class _FormData {
  String message;
  String postedBy;
  DateTime date = DateTime.now();
}

class _MyInputFormState extends State<InputForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _FormData _data = _FormData();

  Future<DateTime> _selectTime(BuildContext context) {
    return showDatePicker(context: context,
        initialDate: _data.date,
        firstDate: DateTime(_data.date.year - 2),
        lastDate: DateTime(_data.date.year + 2));
  }

  @override
  Widget build(BuildContext context) {
    DocumentReference _mainReference;
    _mainReference = FirebaseFirestore.instance.collection("messages").doc();

    bool deleteFlg = false;

    if (widget.document != null) {
      _mainReference = FirebaseFirestore.instance.collection('messages').doc();
      deleteFlg = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("メッセージ入力"),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(
                  icon: const Icon(Icons.person),
                  hintText: 'メッセージ入力',
                  labelText: 'メッセージ',
                ),
                onSaved: (String value) {
                  _data.message = value;
                  String name = (firebaseUser.email == "" || firebaseUser.email == null) ? "匿名" : firebaseUser.email;
                  _data.postedBy = name;
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return 'メッセージは必須入力項目です';
                  }
                },
                initialValue: _data.message,
              ),
              RaisedButton(
                child: const Text("送信"),
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    _formKey.currentState.save();
                    _mainReference.set({
                      'message': _data.message,
                      'postedBy': _data.postedBy,
                      'date': _data.date
                    });
                    Navigator.pop(context);
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

class List extends StatefulWidget {
  @override
  _MyList createState() => _MyList();
}

void showBasicDialog(BuildContext context) {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  showDialog(context: context,
      builder: (BuildContext context) =>
          AlertDialog(
            title: const Text("ログアウトしますか？"),
            content: Text(firebaseUser.email + "でログインしています"),
            actions: <Widget>[
              FlatButton(
                child: const Text("キャンセル"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: const Text("ログアウト"),
                onPressed: () {
                  _auth.signOut();
                  Navigator.pushNamedAndRemoveUntil(context, "/", (_) => false);
                },
              )
            ],
          ));
}

void _signIn(BuildContext context, String email, String password) async {
  try {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    firebaseUser = _auth.currentUser;
    Navigator.pushNamedAndRemoveUntil(context, "/list", (_) => false);
  } catch (e) {
    Fluttertoast.showToast(msg: "Firebaseのログインに失敗しました");
  }
}

void _createUser(BuildContext context, String email, String password) async {
  try {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
    firebaseUser = _auth.currentUser;
    Navigator.pushNamedAndRemoveUntil(context, "/list", (_) => false);
  } catch (e) {
    Fluttertoast.showToast(msg: "Firebaseの登録に失敗しました");
  }
}

class _MyList extends State<List> {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("メッセージ一覧"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              showBasicDialog(context);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('messages').orderBy('date').snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: const Text("Loading..."),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data.docs.length,
              padding: const EdgeInsets.only(top: 10.0),
              itemBuilder: (context, index) => _buildListItem(context, snapshot.data.docs[index]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
              settings: const RouteSettings(name: "/new"),
              builder: (BuildContext context) => InputForm(null)
          ));
        },
      ),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    Map<String, dynamic> _data = document.data();
    DateTime _datetime = _data["date"].toDate();
    var _formatter = DateFormat("yyyy/MM/dd HH:mm");
    String postDate = _formatter.format(_datetime);
    bool isMine = firebaseUser.email == _data["postedBy"];

    return Column(
      children: <Widget>[
        ListTile(
          title: Row(
            children: <Widget>[
              Text(_data["postedBy"]),
              SizedBox(
                width: 16.0,
              ),
              Text(
                postDate,
                style: TextStyle(fontSize: 12.0),
              )
            ],
          ),
          subtitle: Bubble(
            color: isMine ? Color.fromRGBO(255, 255, 199, 1.0) : Color.fromRGBO(212, 234, 244, 1.0),
            nip: isMine ? BubbleNip.leftBottom : BubbleNip.rightBottom,
            child: Text(_data["message"],style: TextStyle(fontSize: 20.0)),
            ),
        )
      ],
    );
  }
}

