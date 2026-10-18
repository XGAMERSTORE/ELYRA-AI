package com.xgamerstore.elyra;
import android.app.Activity;
import android.os.Bundle;
import android.content.Intent;
import android.speech.RecognizerIntent;
import android.speech.tts.TextToSpeech;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebSettings;
import java.util.ArrayList;
import java.util.Locale;
public class MainActivity extends Activity {
 private WebView view; private TextToSpeech tts; private static final int VOICE_REQUEST=42;
 @Override public void onCreate(Bundle state){super.onCreate(state);
  tts=new TextToSpeech(this,status->{if(status==TextToSpeech.SUCCESS)tts.setLanguage(new Locale("cs","CZ"));});
  view=new WebView(this);view.setWebViewClient(new WebViewClient());WebSettings s=view.getSettings();s.setJavaScriptEnabled(true);s.setDomStorageEnabled(true);s.setAllowFileAccess(true);s.setAllowFileAccessFromFileURLs(false);s.setAllowUniversalAccessFromFileURLs(false);
  view.addJavascriptInterface(new Bridge(),"ElyraNative");setContentView(view);view.loadUrl("file:///android_asset/index.html");
 }
 public class Bridge {
  @JavascriptInterface public void speak(String text){runOnUiThread(()->{if(tts!=null)tts.speak(text,TextToSpeech.QUEUE_FLUSH,null,"elyra");});}
  @JavascriptInterface public void listen(){runOnUiThread(()->{try{Intent i=new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);i.putExtra(RecognizerIntent.EXTRA_LANGUAGE,"cs-CZ");i.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL,RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);startActivityForResult(i,VOICE_REQUEST);}catch(Exception e){view.evaluateJavascript("voiceError()",null);}});}
 }
 @Override protected void onActivityResult(int request,int result,Intent data){super.onActivityResult(request,result,data);if(request==VOICE_REQUEST&&result==RESULT_OK&&data!=null){ArrayList<String> words=data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS);if(words!=null&&!words.isEmpty()){String escaped=org.json.JSONObject.quote(words.get(0));view.evaluateJavascript("voiceResult("+escaped+")",null);}}}
 @Override public void onBackPressed(){if(view.canGoBack())view.goBack();else super.onBackPressed();}
 @Override public void onDestroy(){if(tts!=null){tts.stop();tts.shutdown();}view.destroy();super.onDestroy();}
}