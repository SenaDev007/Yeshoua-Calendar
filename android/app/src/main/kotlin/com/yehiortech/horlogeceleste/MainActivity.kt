package com.yehiortech.horlogeceleste

import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Intent
import com.yehiortech.horlogeceleste.wallpaper.HorlogeWallpaperService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    /// Canal « écran de verrouillage » (§9.5) : ouverture du sélecteur
    /// de fonds d'écran animés pré-sélectionné sur notre service natif,
    /// et consultation de l'état actif (notre wallpaper courant ?).
    private val canalWallpaper = "horloge_celeste/wallpaper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, canalWallpaper)
            .setMethodCallHandler { appel, resultat ->
                when (appel.method) {
                    "ouvrirChoixWallpaper" -> {
                        try {
                            // Sélecteur système PRÉ-SÉLECTIONNÉ sur l'Horloge
                            // Céleste : un seul appui supplémentaire suffit.
                            val intention = Intent(
                                WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER
                            )
                            intention.putExtra(
                                WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
                                ComponentName(
                                    this,
                                    HorlogeWallpaperService::class.java
                                )
                            )
                            startActivity(intention)
                            resultat.success(true)
                        } catch (e: Exception) {
                            // Repli : ouverture du sélecteur générique.
                            try {
                                startActivity(
                                    Intent(
                                        WallpaperManager
                                            .ACTION_LIVE_WALLPAPER_CHOOSER
                                    )
                                )
                                resultat.success(true)
                            } catch (_: Exception) {
                                resultat.success(false)
                            }
                        }
                    }
                    "estWallpaperActif" -> {
                        try {
                            val gestionnaire =
                                WallpaperManager.getInstance(this)
                            val info = gestionnaire.wallpaperInfo
                            val actif = info != null &&
                                    info.service.className ==
                                    HorlogeWallpaperService::class.java.name
                            resultat.success(actif)
                        } catch (_: Exception) {
                            resultat.success(false)
                        }
                    }
                    else -> resultat.notImplemented()
                }
            }
    }
}
