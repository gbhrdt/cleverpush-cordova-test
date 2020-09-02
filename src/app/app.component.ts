import { Component } from '@angular/core';

import { Platform } from '@ionic/angular';
import { SplashScreen } from '@ionic-native/splash-screen/ngx';
import { StatusBar } from '@ionic-native/status-bar/ngx';

@Component({
  selector: 'app-root',
  templateUrl: 'app.component.html'
})
export class AppComponent {
  constructor(
    private platform: Platform,
    private splashScreen: SplashScreen,
    private statusBar: StatusBar
  ) {
    this.initializeApp();
  }

  initializeApp() {
    this.platform.ready().then(() => {
      this.statusBar.styleDefault();
      this.splashScreen.hide();

      if (window['plugins'] && window['plugins'].CleverPush) {
        console.log('Initializing CleverPush…');
  
        var notificationOpenedCallback = function(data) {
          console.log('notificationOpenedCallback:', JSON.stringify(data));
          alert('CleverPush Notification Opened Callback');
        };
        var notificationReceivedCallback = function(data) {
          console.log('notificationReceivedCallback:', JSON.stringify(data));
        };
        var subscribedCallback = function(subscriptionId) {
          console.log('CleverPush subscriptionId:', subscriptionId);
          alert('CleverPush subscribedCallback: ' + subscriptionId);
        };
  
        window['plugins'].CleverPush.init("QZCYbr96uLMC26E2G", notificationOpenedCallback, notificationReceivedCallback, subscribedCallback);
      }
    });
  }
}

