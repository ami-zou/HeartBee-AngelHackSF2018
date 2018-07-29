/*<resources>
  <string name="app_name">heartbee</string>

  <string name="agora_app_id">f5e889dc03f844c4aaa5fda833f5cf26</string>
</resources>

'use strict';
console.log("HIIIIII! Main.js is running");



//var AWS = require("aws-sdk");
console.log("scan running");
console.log("trying to scan");

var creds = new AWS.CognitoIdentityCredentials({
  IdentityPoolId: 'us-east-2:047171aa-32a6-41bb-880d-318fbc995875'
});


AWS.config.credentials = creds;

AWS.config.update({
  region: "us-east-2"
});
/*
update({
   region: "us-east-2",
   credentials: {
     accessKeyId: "AKIAIURLYQOLOGXZ7O4Q",
     secreteAccessKey: "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"
   }
   //endpoint: "http://localhost:8000"
});
*/
'use strict';

var heartRate = 200;

var upper_threshhold = 120;
var lower_threshhold = 20;
//===============================================
document.getElementById("insert_heartrate").innerHTML = heartRate;
document.getElementById("notification").style.visibility='hidden';
console.log("Hide notification!");

function checkHeartRate(){
  if(heartRate <= lower_threshhold){
    console.log("heartRate too low!!!");
    document.getElementById("insert_condition").innerHTML = "Heart Rate Too Low";
  }else if(heartRate > upper_threshhold){
    console.log("Display notification!");
    document.getElementById("insert_condition").innerHTML = "Heart Rate Too High";
    document.getElementById("notification").style.visibility='visible';
  //document.getElementById("insert_condition").innerHTML.style.color = red;
    join();
    displayNotification();
  //getDevices();
  }else{
    document.getElementById("insert_condition").innerHTML = "Good";
  }
}

checkHeartRate();

//==========NOTIFICATION===========


//==========DATA BASE SCANNING============
var docClient = new AWS.DynamoDB.DocumentClient();

var params = {
   TableName: "fitbit_data",
  // ProjectionExpression: "heartRate"
};

console.log("Scanning fitbit table.");
//TODO FIX THIS!!!
//docClient.scan(params, onScan);

function onScan(err, data) {
 console.log("scanning");
   if (err) {
       console.error("Unable to scan the table. Error JSON:", JSON.stringify(err, null, 2));
   } else {
       // print all the movies
       console.log("Scan succeeded.");
       data.Items.forEach(function(hR) {
          console.log(
               hR.hearRate);
       });

       // continue scanning if we have more movies, because
       // scan can retrieve a maximum of 1MB of data
       if (typeof data.LastEvaluatedKey != "undefined") {
           console.log("Scanning for more...");
           params.ExclusiveStartKey = data.LastEvaluatedKey;
           docClient.scan(params, onScan);
       }


       //ALL GOOD: UPDATE DATA
       //TRIGGER

/****NEED TO FIX THIS****/
//
//TODO       data.Items.forEach(check);

       function check(hR){
         setInterval(check, 3000);

         heartRate = hR.hearRate;
         document.getElementById("insert_heartrate").innerHTML = heartRate;
         checkHR();


       }



       function checkHR(){
         if(heartRate <= lower_threshhold){
           console.log("heartRate too low!!!");
           document.getElementById("insert_condition").innerHTML = "Heart Rate Too Low";
         }else if(heartRate > upper_threshhold){
           console.log("Display notification!");
           document.getElementById("insert_condition").innerHTML = "Heart Rate Too High";
           document.getElementById("notification").style.visibility='visible';
         //document.getElementById("insert_condition").innerHTML.style.color = red;
           join();
           displayNotification();
         //getDevices();
         }else{
           document.getElementById("insert_condition").innerHTML = "Good";
         }
       }


   }


}
/*
var myHeading = document.querySelector('h1');
myHeading.textContent = 'Hello world!';
*/

/*register sw
*/

//Notification + HeartRate set up



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
