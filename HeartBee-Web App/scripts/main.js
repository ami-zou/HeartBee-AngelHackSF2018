/*<resources>
  <string name="app_name">heartbee</string>

  <string name="agora_app_id">f5e889dc03f844c4aaa5fda833f5cf26</string>
</resources>

'use strict';

/*
var myHeading = document.querySelector('h1');
myHeading.textContent = 'Hello world!';
*/
console.log("HIIIIII! Main.js is running");

/*register sw
*/

//Notification + HeartRate set up
var heartRate = 200;
var threshhold = 120;
document.getElementById("insert").innerHTML = heartRate;

document.getElementById("notification").style.visibility='hidden';
console.log("Hide notification!");

/*
* Now let's work on notification
*

$.getscript("url or name of 1st Js File",function(){
fn();
});

*/


Notification.requestPermission( function(status){
    console.log('Notification permission: ',status);
  }
)

if (Notification.permission === "granted") {
  /* do our magic */
} else if (Notification.permission === "blocked") {
 /* the user has previously denied push. Can't reprompt. */
} else {
  /* show a prompt to the user */
}

function displayNotification() {
  if (Notification.permission == 'granted') {
    navigator.serviceWorker.getRegistration().then(function(reg) {
      reg.showNotification('Hello world!');
    });
  }
}


if ('Notification' in window && navigator.serviceWorker) {
  // Display the UI to let the user toggle notifications
}

function subscribeUser() {
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.ready.then(function(reg) {

      reg.pushManager.subscribe({
        userVisibleOnly: true
      }).then(function(sub) {
        console.log('Endpoint URL: ', sub.endpoint);
      }).catch(function(e) {
        if (Notification.permission === 'denied') {
          console.warn('Permission for notifications was denied');
        } else {
          console.error('Unable to subscribe to push', e);
        }
      });
    })
  }
}

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('sw.js').then(function(reg) {
    console.log('Service Worker Registered!', reg);

    reg.pushManager.getSubscription().then(function(sub) {
      if (sub === null) {
        // Update UI to ask user to register for Push
        console.log('Not subscribed to push service!');
      } else {
        // We have a subscription, update the database
        console.log('Subscription object: ', sub);
      }
    });
  })
   .catch(function(err) {
    console.log('Service Worker registration failed: ', err);
  });
}

//TRIGGER

if(heartRate > threshhold){
  console.log("Display notification!");
  document.getElementById("notification").style.visibility='visible';
  join();
  displayNotification();
  //getDevices();
}
