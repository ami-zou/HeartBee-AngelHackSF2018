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

var docClient = new AWS.DynamoDB.DocumentClient();

var params = {
   TableName: "fitbit_data",
   ProjectionExpression: "heartRate"
};

console.log("Scanning fitbit table.");
docClient.scan(params, onScan);

function onScan(err, data) {
 console.log("scanning");
   if (err) {
       console.error("Unable to scan the table. Error JSON:", JSON.stringify(err, null, 2));
   } else {
       // print all the movies
       console.log("Scan succeeded.");
       data.Items.forEach(function(hR) {
          console.log(
               hR.heartRate);
       });

       // continue scanning if we have more movies, because
       // scan can retrieve a maximum of 1MB of data
       if (typeof data.LastEvaluatedKey != "undefined") {
           console.log("Scanning for more...");
           params.ExclusiveStartKey = data.LastEvaluatedKey;
           docClient.scan(params, onScan);
       }
   }
}
