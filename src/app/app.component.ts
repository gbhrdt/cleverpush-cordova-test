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

      var notificationOpenedCallback = function(data) {
        console.log('notificationOpenedCallback:', JSON.stringify(data));
      };
      var subscribedCallback = function(subscriptionId) {
        console.log('subscriptionId:', subscriptionId);
      };

      window['plugins'].CleverPush.init("Mw29Mswn2DgRD3Zyx", notificationOpenedCallback, subscribedCallback);
    });
  }
}
