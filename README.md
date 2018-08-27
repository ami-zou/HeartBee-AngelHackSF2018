# HeartBee-AngelHackSF2018
(A Fitbit App + Web App + iOS Mobile App): HeartBee allows you to take care of your loved ones by providing a dashboard of your family’s heart rates as relayed by the Fitbit watch

## Team

This platform is developed from scratch during [AngelHack SF 2018](https://www.eventbrite.com/e/angelhack-san-francisco-hackathon-2018-tickets-45086935237#) on July 28 - 29, 2018 in Parisoma, San Francisco 
- AngelHack's Call For A Cause Award winner
- Fitbit's Healthcare Challenge winner
- HyperTrack's $1000 Challenge winner

### Team member

- [Wanyi Chen](https://github.com/WanyiChen/Heartbee/): Fitbit App - setting up tracking, threshhold, vibration, of the Fitbit app and sending data to AWS. 
- [Sophia Liu](https://www.linkedin.com/in/sophialiuinc/): Design - designing logo, dashboard, mobile app, and pitch deck.
- [Gabi Stein](https://github.com/gabistein): Database & Project Management - setting up Amazon DynamonDB, connecting it with Fitbit, and hosting the website; making pitch deck and planning for presentation.
- Ami Zou (Me): Web App & iOS App - building the web app using HTML, CSS, and Javascript and using Agora.io's SDK for video streaming; building the iOS App using Swift and using HyperTrack's SDK for location tracking.

## Story

San Francisco Chinatown is full of elderly citizens like my grandmother. And according to the statistics, more than 70% of them suffer from cardiovascular disease. We want to connect elderly parents and their family members in a way that doesn’t intrude on their independence, but make sure they’re being taken care of.

We chose to use a Fitbit watch. 

Heartbee allows you take care of your loved ones by providing a dashboard of your family’s heart rates as relayed by the Fitbit watch.

## Development
![alt text](https://raw.githubusercontent.com/WanyiChen/Heartbee/master/architecture.png)

Using **Fitbit’s API**, we created a demo of the watch you’d give your elderly parents to wear. They can track their current heart rate, receive messages, and call for help if need be. When their heart rate reaches above a certain threshold, a notification is send to their family member.

Using **AWS**, we created the dashboard for family members and caregivers. We can check on elderly parents, send messages, track their heart rates and locations, using Fitbit sensors and Hypertrack.
We can also see the health score of our family members, aka our “hive”.

Using **Agora.io's SDK**, we enabled real-time video streaming so family members can create their fitness channels and watch each other. When emergency happens, we notify the family members directly by calling them via the app.

Using **HyperTrack's SDK**, we enabled location tracking and historical path. In the iOS mobile app, family members can see each others' last visited places and 15-mins path, and when an emergency happens, they know exactly where to rescue the person in danger.

Our apps (Fitbit Ionic, Web, and iOS mobile) work together to keep everyone updated on the health status of their loved ones and keep everyone in check. It can easily be scaled into a tablet, an Anroid app, and other platforms. 

HeartBee is targeted to people with elderly parents at risk of heart attacks. So if you or someone you know has a elderly loved one you care about, give them the freedom they need but also the peace of mind you need, with Heartbee.
