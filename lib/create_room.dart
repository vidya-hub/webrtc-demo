import 'dart:convert';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_test/webrtc_methods.dart';

class CreateRoom extends StatefulWidget {
  MediaStream? remoteStream;

  CreateRoom({
    super.key,
  });

  @override
  State<CreateRoom> createState() => _CreateRoomState();
}

class _CreateRoomState extends State<CreateRoom> {
  RTCSessionDescription? _localSDP;
  final List _localICE = [];
  RTCPeerConnection? _peerConnection;

  Future initiateWebRtc() async {
    _peerConnection = await createPeerConnection(configuration);

    registerPeerConnectionListeners(_peerConnection);
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      print('Got candidate: ${candidate.toMap()}');
      setState(() {
        _localICE.add(candidate.toMap());
      });
    };
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    setState(() {
      _localSDP = offer;
    });
  }

  @override
  void initState() {
    super.initState();
    initiateWebRtc();
  }

  Future setRemoteSdp(Map<String, dynamic> data) async {
    var answer = RTCSessionDescription(
      data['sdp'],
      data['type'],
    );
    await _peerConnection?.setRemoteDescription(answer);
  }

  Future setIceCandidate(Map<String, dynamic> data) async {
    await _peerConnection!.addCandidate(
      RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      ),
    );
  }

  final TextEditingController _remoteSdpController = TextEditingController();
  final TextEditingController _remoteIceController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Room"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: () {
                        FlutterClipboard.copy(jsonEncode(_localSDP?.toMap()));
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 200,
                            child: Text(
                              _localSDP?.toMap().toString() ?? "",
                            ),
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        FlutterClipboard.copy(jsonEncode(_localICE.first));
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: SizedBox(
                            height: 200,
                            child: Text(
                              _localICE.toString(),
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
              height: 10,
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
                await setRemoteSdp(
                  json.decode(
                    _remoteSdpController.text,
                  ),
                );
                await setIceCandidate(
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
