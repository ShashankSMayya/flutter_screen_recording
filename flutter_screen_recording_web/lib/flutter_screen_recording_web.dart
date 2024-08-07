import 'dart:async';
import 'package:universal_html/html.dart' as html;
import 'package:universal_html/js.dart' as js;
import 'package:flutter_test_recording/flutter_screen_recording_platform_interface.dart';
import 'get_display_media.dart';

class WebFlutterScreenRecording extends FlutterScreenRecordingPlatform {
  html.MediaStream? stream;
  String? name;
  html.MediaRecorder? mediaRecorder;
  html.Blob? recordedChunks;
  String? mimeType;
  bool isAutoSaveFile = true;

  @override
  Future<bool> startRecordScreen(String name, {bool isAutoSaveFile = true, Function()? onStopSharing}) async {
    return _record(name, true, false, isAutoSaveFile: isAutoSaveFile, onStopSharing: onStopSharing);
  }

  @override
  Future<bool> startRecordScreenAndAudio(String name, {bool isAutoSaveFile = true, Function()? onStopSharing}) async {
    return _record(name, true, true, isAutoSaveFile: isAutoSaveFile, onStopSharing: onStopSharing);
  }

  Future<bool> _record(String name, bool recordVideo, bool recordAudio, {required bool isAutoSaveFile, Function()? onStopSharing}) async {
    try {
      this.isAutoSaveFile = isAutoSaveFile;
      html.MediaStream? audioStream;

      if (recordAudio) {
        audioStream = await Navigator.getUserMedia({"audio": true});
      }
      stream = await Navigator.getDisplayMedia({"audio": recordAudio, "video": recordVideo});
      this.name = name;
      if (recordAudio) {
        stream!.addTrack(audioStream!.getAudioTracks()[0]);
      }

      if (html.MediaRecorder.isTypeSupported('video/mp4;codecs=h264')) {
        print('video/mp4;codecs=h264');
        mimeType = 'video/mp4;codecs=h264';
      } else if (html.MediaRecorder.isTypeSupported('video/webm;codecs=vp9')) {
        print('video/webm;codecs=vp9');
        mimeType = 'video/webm;codecs=vp9,opus';
      } else if (html.MediaRecorder.isTypeSupported('video/webm;codecs=vp8.0')) {
        print('video/webm;codecs=vp8.0');
        mimeType = 'video/webm;codecs=vp8.0,opus';
      } else if (html.MediaRecorder.isTypeSupported('video/webm;codecs=vp8')) {
        print('video/webm;codecs=vp8');
        mimeType = 'video/webm;codecs=vp8,opus';
      } else if (html.MediaRecorder.isTypeSupported('video/mp4;codecs=h265')) {
        mimeType = 'video/mp4;codecs=h265,opus';
        print("video/mp4;codecs=h265");
      } else if (html.MediaRecorder.isTypeSupported('video/mp4;codecs=h264')) {
        print("video/mp4;codecs=h264");
        mimeType = 'video/mp4;codecs=h264,opus';
      } else if (html.MediaRecorder.isTypeSupported('video/webm;codecs=h265')) {
        print("video/webm;codecs=h265");
        mimeType = 'video/webm;codecs=h265,opus';
      } else if (html.MediaRecorder.isTypeSupported('video/webm;codecs=h264')) {
        print("video/webm;codecs=h264");
        mimeType = 'video/webm;codecs=h264,opus';
      } else {
        mimeType = 'video/webm';
      }

      mediaRecorder = html.MediaRecorder(stream!, {'mimeType': mimeType});

      mediaRecorder!.addEventListener('dataavailable', (html.Event event) {
        print("datavailable ${event.runtimeType}");
        recordedChunks = js.JsObject.fromBrowserObject(event)['data'];
        mimeType = mimeType;
        print("blob size: ${recordedChunks?.size ?? 'empty'}");
      });

      stream!.getVideoTracks()[0].addEventListener('ended', (html.Event event) {
        //If user stop sharing screen, stop record
        stopRecordScreen.then((value) => onStopSharing?.call());
      });

      mediaRecorder!.start();

      return true;
    } on Error catch (e) {
      print("--->$e");
      return false;
    }
  }

  @override
  Future<String> get stopRecordScreen {
    final c = Completer<String>();
    mediaRecorder!.addEventListener("stop", (event) async {
      mediaRecorder = null;
      stream!.getTracks().forEach((element) => element.stop());
      stream = null;
      if (isAutoSaveFile) {
        final a = html.document.createElement("a") as html.AnchorElement;
        final url = html.Url.createObjectUrl(blobFile);
        html.document.body!.append(a);
        a.style.display = "none";
        a.href = url;
        a.download = name;
        a.click();
        html.Url.revokeObjectUrl(url);
        c.complete(name);
      } else {
        c.complete('');
      }
    });
    mediaRecorder!.stop();
    return c.future;
  }

  html.Blob? get blobFile {
    try {
      return html.Blob(List<dynamic>.from([recordedChunks]), mimeType);
    } catch (_) {
      return null;
    }
  }
}