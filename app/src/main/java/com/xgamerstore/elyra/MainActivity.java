package com.xgamerstore.elyra;
import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebSettings;
public class MainActivity extends Activity {
 private WebView view;
 @Override public void onCreate(Bundle state){super.onCreate(state);view=new WebView(this);view.setWebViewClient(new WebViewClient());WebSettings s=view.getSettings();s.setJavaScriptEnabled(true);s.setDomStorageEnabled(true);s.setAllowFileAccess(true);s.setAllowFileAccessFromFileURLs(false);s.setAllowUniversalAccessFromFileURLs(false);setContentView(view);view.loadUrl("file:///android_asset/index.html");}
 @Override public void onBackPressed(){if(view.canGoBack())view.goBack();else super.onBackPressed();}
 @Override public void onDestroy(){view.destroy();super.onDestroy();}
}