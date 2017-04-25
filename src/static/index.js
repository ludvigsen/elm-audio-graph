var Elm = require( '../elm/Main' );
var app = Elm.Main.fullscreen({
  width:  window.innerWidth,
  height: window.innerHeight
});

// Slightly modified code from stack overflow:
// http://stackoverflow.com/questions/27846392/access-microphone-from-a-browser-javascript
(function () {
  var audioContext = new AudioContext();

  var BUFF_SIZE = 16384;

  if (!navigator.getUserMedia) {
    navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia ||
      navigator.mozGetUserMedia || navigator.msGetUserMedia;
  }

  if (navigator.getUserMedia) {
    navigator.getUserMedia(
      {audio:true},
      function(stream) {
        startMicrophone(stream);
      },
      function(e) {
        alert('Error capturing audio.');
      }
    );
  } else { alert('getUserMedia not supported in this browser.'); }

  function sendData(arr) {
    var total = 0;
    var index = 0;

    for (; index < arr.length; index += 1) {
      total += Math.abs( arr[index] );
    }
    var rms = Math.sqrt( total / arr.length );
    app.ports.newData.send([Date.now(), rms * 10]);
  }

  function processBuffer(event) {
    var buffer = event.inputBuffer.getChannelData(0); // just mono - 1 channel for now
    sendData(buffer);
  }

  function startMicrophone(stream){

    var gainNode = audioContext.createGain();
    gainNode.connect( audioContext.destination );

    var microphoneStream = audioContext.createMediaStreamSource(stream);
    microphoneStream.connect(gainNode);

    var scriptProcessorNode = audioContext.createScriptProcessor(BUFF_SIZE, 1, 1);
    scriptProcessorNode.onaudioprocess = processBuffer;

    microphoneStream.connect(scriptProcessorNode);

    var scriptProcessorFftNode = audioContext.createScriptProcessor(2048, 1, 1);
    scriptProcessorFftNode.connect(gainNode);

    var analyserNode = audioContext.createAnalyser();
    analyserNode.smoothingTimeConstant = 0;
    analyserNode.fftSize = 2048;

    microphoneStream.connect(analyserNode);

    analyserNode.connect(scriptProcessorFftNode);

    scriptProcessorFftNode.onaudioprocess = function() {

      // get the average for the first channel
      var array = new Uint8Array(analyserNode.frequencyBinCount);
      analyserNode.getByteFrequencyData(array);

      // draw the spectrogram
      if (microphoneStream.playbackState == microphoneStream.PLAYING_STATE) {

        sendData(array);
      }
    };
  }
})();
