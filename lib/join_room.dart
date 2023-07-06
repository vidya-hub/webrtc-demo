import 'dart:convert';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_test/webrtc_methods.dart';

class JoinRoom extends StatefulWidget {
  // RTCPeerConnection? peerConnection;

  const JoinRoom({
    super.key,
    // required this.peerConnection,
  });

  @override
  State<JoinRoom> createState() => _JoinRoomState();
}

class _JoinRoomState extends State<JoinRoom> {
  RTCPeerConnection? _peerConnection;

  RTCSessionDescription? _remoteSDP;
  final List _remoteICE = [];
  Future initiateWebRtc() async {
    _peerConnection = await createPeerConnection(configuration);
    registerPeerConnectionListeners(_peerConnection);
    _peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) async {
      if (candidate == null) {
        print('onIceCandidate: complete!');
        return;
      }
      print('onIceCandidate: ${candidate.toMap()}');
      setState(() {
        _remoteICE.add(candidate.toMap());
      });
    };
  }

  Future<void> joinRoom(Map remoteSDP, Map remoteIceCandidate) async {
    await _peerConnection?.setRemoteDescription(
      RTCSessionDescription(remoteSDP['sdp'], remoteSDP['type']),
    );
    _peerConnection!.addCandidate(
      RTCIceCandidate(
        remoteIceCandidate['candidate'],
        remoteIceCandidate['sdpMid'],
        remoteIceCandidate['sdpMLineIndex'],
      ),
    );
    var answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    setState(() {
      _remoteSDP = answer;
    });
  }

  final TextEditingController _remoteSdpController = TextEditingController();
  final TextEditingController _remoteIceController = TextEditingController();
  @override
  void initState() {
    initiateWebRtc();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                actions: [
                  TextButton(
                    child: const Text("Close"),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
                content: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        FlutterClipboard.copy(jsonEncode(_remoteSDP?.toMap()));
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 200,
                            child: Text(
                              _remoteSDP?.toMap().toString() ?? "",
                            ),
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        FlutterClipboard.copy(jsonEncode(_remoteICE.first));
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 200,
                            child: Text(
                              _remoteICE.toString(),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
        child: const Icon(Icons.info_outline),
      ),
      appBar: AppBar(
        title: const Text("Join Room"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: _remoteSdpController,
                  decoration: const InputDecoration(
                    hintText: "Enter Remote SDP",
                  ),
                  maxLines: 10,
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: _remoteIceController,
                  decoration: const InputDecoration(
                    hintText: "Enter Remote Ice",
                  ),
                  maxLines: 10,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await joinRoom(
                  json.decode(
                    _remoteSdpController.text,
                  ),
                  json.decode(
                    _remoteIceController.text,
                  ),
                );
              },
              child: const Text("Start the meeting"),
            )
          ],
        ),
      ),
    );
  }
}
