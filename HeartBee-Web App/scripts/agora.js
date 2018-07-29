if(!AgoraRTC.checkSystemRequirements()) {
  alert("browser is no support webRTC");
}

/* select Log type */
// AgoraRTC.Logger.setLogLevel(AgoraRTC.Logger.NONE);
// AgoraRTC.Logger.setLogLevel(AgoraRTC.Logger.ERROR);
// AgoraRTC.Logger.setLogLevel(AgoraRTC.Logger.WARNING);
// AgoraRTC.Logger.setLogLevel(AgoraRTC.Logger.INFO);
// AgoraRTC.Logger.setLogLevel(AgoraRTC.Logger.DEBUG);

/* simulated data to proof setLogLevel() */
AgoraRTC.Logger.error('this is error');
AgoraRTC.Logger.warning('this is warning');
AgoraRTC.Logger.info('this is info');
AgoraRTC.Logger.debug('this is debug');

//===========GOOD TO EXECUTE===================
//STYLING
var heartRate = 200;
var threshhold = 120;
document.getElementById("insert").innerHTML = heartRate;

document.getElementById("notification").style.visibility='hidden';
console.log("Hide notification!");


//FOR ARGORA

var client, localStream, camera, microphone;

var audioSelect = document.querySelector('select#audioSource');
var videoSelect = document.querySelector('select#videoSource');

var default_key_value = "f5e889dc03f844c4aaa5fda833f5cf26";
var default_channel_value = "1000";
//or use Input key value: key.value
//or use Input channel value: channel.value

function join() {
  document.getElementById("join").disabled = true;
  document.getElementById("video").disabled = true;
  var channel_key = null;

  console.log("Init AgoraRTC client with vendor key: " + default_key_value);
  client = AgoraRTC.createClient({mode: 'interop'});
  client.init(default_key_value, function () {
    console.log("AgoraRTC client initialized");
    client.join(channel_key, default_channel_value, null, function(uid) {
      console.log("User " + uid + " join channel successfully");

      if (document.getElementById("video").checked) {
        camera = videoSource.value;
        microphone = audioSource.value;
        localStream = AgoraRTC.createStream({streamID: uid, audio: true, cameraId: camera, microphoneId: microphone, video: document.getElementById("video").checked, screen: false});
        //localStream = AgoraRTC.createStream({streamID: uid, audio: false, cameraId: camera, microphoneId: microphone, video: false, screen: true, extensionId: 'minllpmhdgpndnkomcoccfekfegnlikg'});
        if (document.getElementById("video").checked) {
          localStream.setVideoProfile('720p_3');

        }

        // The user has granted access to the camera and mic.
        localStream.on("accessAllowed", function() {
          console.log("accessAllowed");
        });

        // The user has denied access to the camera and mic.
        localStream.on("accessDenied", function() {
          console.log("accessDenied");
        });

        localStream.init(function() {
          console.log("getUserMedia successfully");
          localStream.play('agora_local');

          client.publish(localStream, function (err) {
            console.log("Publish local stream error: " + err);
          });

          client.on('stream-published', function (evt) {
            console.log("Publish local stream successfully");
          });
        }, function (err) {
          console.log("getUserMedia failed", err);
        });
      }
    }, function(err) {
      console.log("Join channel failed", err);
    });
  }, function (err) {
    console.log("AgoraRTC client init failed", err);
  });

  channelKey = "";
  client.on('error', function(err) {
    console.log("Got error msg:", err.reason);
    if (err.reason === 'DYNAMIC_KEY_TIMEOUT') {
      client.renewChannelKey(channelKey, function(){
        console.log("Renew channel key successfully");
      }, function(err){
        console.log("Renew channel key failed: ", err);
      });
    }
  });


  client.on('stream-added', function (evt) {
    var stream = evt.stream;
    console.log("New stream added: " + stream.getId());
    console.log("Subscribe ", stream);
    client.subscribe(stream, function (err) {
      console.log("Subscribe stream failed", err);
    });
  });

  client.on('stream-subscribed', function (evt) {
    var stream = evt.stream;
    console.log("Subscribe remote stream successfully: " + stream.getId());
    if ($('div#video #agora_remote'+stream.getId()).length === 0) {
      $('div#video').append('<div id="agora_remote'+stream.getId()+'" style="float:left; width:810px;height:607px;display:inline-block;"></div>');
    }
    stream.play('agora_remote' + stream.getId());
  });

  client.on('stream-removed', function (evt) {
    var stream = evt.stream;
    stream.stop();
    $('#agora_remote' + stream.getId()).remove();
    console.log("Remote stream is removed " + stream.getId());
  });

  client.on('peer-leave', function (evt) {
    var stream = evt.stream;
    if (stream) {
      stream.stop();
      $('#agora_remote' + stream.getId()).remove();
      console.log(evt.uid + " leaved from this channel");
    }
  });
}

function leave() {
  document.getElementById("leave").disabled = true;
  document.getElementById("join").disabled = false; //enable user to re-join
  client.leave(function () {
    console.log("Leavel channel successfully");
  }, function (err) {
    console.log("Leave channel failed");
  });

// TODO: Remove video after leave()
  document.getElementById("video").display='none';
}

function publish() {
  document.getElementById("publish").disabled = true;
  document.getElementById("unpublish").disabled = false;
  client.publish(localStream, function (err) {
    console.log("Publish local stream error: " + err);
  });
}

function unpublish() {
  document.getElementById("publish").disabled = false;
  document.getElementById("unpublish").disabled = true;
  client.unpublish(localStream, function (err) {
    console.log("Unpublish local stream failed" + err);
  });
}

function getDevices() {
  AgoraRTC.getDevices(function (devices) {
    for (var i = 0; i !== devices.length; ++i) {
      var device = devices[i];
      var option = document.createElement('option');
      option.value = device.deviceId;
      if (device.kind === 'audioinput') {
        option.text = device.label || 'microphone ' + (audioSelect.length + 1);
        audioSelect.appendChild(option);
      } else if (device.kind === 'videoinput') {
        option.text = device.label || 'camera ' + (videoSelect.length + 1);
        videoSelect.appendChild(option);
      } else {
        console.log('Some other kind of source/device: ', device);
      }
    }
  });
}

//audioSelect.onchange = getDevices;
//videoSelect.onchange = getDevices;
getDevices();

if(heartRate > threshhold){
  console.log("Display notification!");
  document.getElementById("notification").style.visibility='visible';
  join();
  //getDevices();
}
