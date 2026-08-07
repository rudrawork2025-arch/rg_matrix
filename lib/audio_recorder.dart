import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart'as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderScreen extends StatefulWidget {
  const AudioRecorderScreen({super.key});

  @override
  State<AudioRecorderScreen> createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> {

  final AudioRecorder audioRecorder = AudioRecorder();
  final AudioPlayer audioPlayer = AudioPlayer();
  String? recordingPath;
  bool isRecording = false, isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recorder'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
      ),
      ),
      body: const Center(
        child: Text('Audio Recorder'),
      )
    );

    // floatingActionButton: _recordingButton()
  }

  Widget _buildUI() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (recordingPath != null)
            MaterialButton(onPressed: () async {
              if (audioPlayer.playing) {
                audioPlayer.stop();
                setState(() {
                  isPlaying = false;
                });
              }else {
                await audioPlayer.setFilePath(recordingPath!);
                audioPlayer.play();
                setState(() {
                  isPlaying = true;
                });
              }
            },
              color: Theme.of(context).colorScheme.primary,
              child: Text(
                  isPlaying ? "Stop Playing Recording" : "Start Playing Recording",
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          if (recordingPath == null)
            const Text("No Recording was found"),
        ],
      ),
    );
  }

  Widget _recordingButton() {
    return FloatingActionButton(
      onPressed: () async {
      if (isRecording) {
       String? filePath = await audioRecorder.stop();
       if (filePath != null) {
         setState(() {
           isRecording = false;
           recordingPath = filePath;
         });
       }
      }else {
        if (await audioRecorder.hasPermission()) {
          final Directory appDocumentsDir =
            await getApplicationDocumentsDirectory();
          final String filePath =
            p.join(appDocumentsDir.path, "recording.wav");
          await audioRecorder.start(
            const RecordConfig(),
            path: filePath,
          );
          setState(() {
            isRecording = true;
            recordingPath = null;
          });
        }
      }
    },
    child: Icon(
        isRecording ? Icons.stop : Icons.mic,
    ),
    );
  }
}