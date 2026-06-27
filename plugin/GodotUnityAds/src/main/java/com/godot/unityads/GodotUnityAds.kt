package com.godot.unityads

import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout

import com.unity3d.ads.IUnityAdsInitializationListener
import com.unity3d.ads.IUnityAdsLoadListener
import com.unity3d.ads.IUnityAdsShowListener
import com.unity3d.ads.UnityAds
import com.unity3d.ads.UnityAdsShowOptions
import com.unity3d.services.banners.BannerErrorInfo
import com.unity3d.services.banners.BannerView
import com.unity3d.services.banners.UnityBannerSize

// ponytail: load/show is the same API for interstitial & rewarded — the ad type
// is decided by the placement in the dashboard. One pair of methods covers both.
// Reward = ad_completed with state "COMPLETED" on a rewarded placement.
class GodotUnityAds(godot: Godot) : GodotPlugin(godot) {

    override fun getPluginName() = "GodotUnityAds"

    override fun getPluginSignals(): Set<SignalInfo> = setOf(
        SignalInfo("initialized"),
        SignalInfo("init_failed", String::class.java, String::class.java),
        SignalInfo("ad_loaded", String::class.java),
        SignalInfo("ad_load_failed", String::class.java, String::class.java, String::class.java),
        SignalInfo("ad_completed", String::class.java, String::class.java),
        SignalInfo("ad_show_failed", String::class.java, String::class.java, String::class.java),
        SignalInfo("banner_loaded", String::class.java),
        SignalInfo("banner_load_failed", String::class.java, String::class.java, String::class.java),
    )

    // ponytail: one banner at a time — load replaces any existing one. Add a map
    // keyed by placement only if a game needs multiple banners on screen at once.
    private var bannerView: BannerView? = null
    private var bannerContainer: FrameLayout? = null

    @UsedByGodot
    fun initialize(gameId: String, testMode: Boolean) {
        val act = activity ?: return
        UnityAds.initialize(
            act.applicationContext, gameId, testMode,
            object : IUnityAdsInitializationListener {
                override fun onInitializationComplete() {
                    emitSignal("initialized")
                }

                override fun onInitializationFailed(
                    error: UnityAds.UnityAdsInitializationError?, message: String?
                ) {
                    emitSignal("init_failed", error?.toString() ?: "UNKNOWN", message ?: "")
                }
            }
        )
    }

    @UsedByGodot
    fun load_ad(placementId: String) {
        UnityAds.load(placementId, object : IUnityAdsLoadListener {
            override fun onUnityAdsAdLoaded(placementId: String) {
                emitSignal("ad_loaded", placementId)
            }

            override fun onUnityAdsFailedToLoad(
                placementId: String, error: UnityAds.UnityAdsLoadError?, message: String?
            ) {
                emitSignal("ad_load_failed", placementId, error?.toString() ?: "UNKNOWN", message ?: "")
            }
        })
    }

    @UsedByGodot
    fun show_ad(placementId: String) {
        val act = activity ?: return
        // ponytail: UnityAds.show must run on the UI thread.
        act.runOnUiThread {
            UnityAds.show(act, placementId, UnityAdsShowOptions(), object : IUnityAdsShowListener {
                override fun onUnityAdsShowFailure(
                    placementId: String, error: UnityAds.UnityAdsShowError?, message: String?
                ) {
                    emitSignal("ad_show_failed", placementId, error?.toString() ?: "UNKNOWN", message ?: "")
                }

                override fun onUnityAdsShowStart(placementId: String) {}

                override fun onUnityAdsShowClick(placementId: String) {}

                override fun onUnityAdsShowComplete(
                    placementId: String, state: UnityAds.UnityAdsShowCompletionState
                ) {
                    emitSignal("ad_completed", placementId, state.toString())
                }
            })
        }
    }

    // position: "<top|center|bottom>_<left|center|right>", e.g. "bottom_center".
    @UsedByGodot
    fun load_banner(placementId: String, position: String) {
        val act = activity ?: return
        act.runOnUiThread {
            destroyBanner()
            val banner = BannerView(act, placementId, UnityBannerSize(320, 50))
            banner.listener = object : BannerView.IListener {
                override fun onBannerLoaded(view: BannerView) {
                    emitSignal("banner_loaded", placementId)
                }

                override fun onBannerFailedToLoad(view: BannerView, info: BannerErrorInfo?) {
                    emitSignal(
                        "banner_load_failed", placementId,
                        info?.errorCode?.toString() ?: "UNKNOWN", info?.errorMessage ?: ""
                    )
                }

                override fun onBannerShown(view: BannerView) {}

                override fun onBannerClick(view: BannerView) {}

                override fun onBannerLeftApplication(view: BannerView) {}
            }
            val container = FrameLayout(act)
            act.addContentView(
                container,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.WRAP_CONTENT, gravityFor(position)
                )
            )
            container.addView(banner)
            container.bringToFront() // keep the banner above the Godot surface
            bannerView = banner
            bannerContainer = container
            banner.load()
        }
    }

    private fun gravityFor(position: String): Int {
        val vertical = when {
            position.startsWith("top") -> Gravity.TOP
            position.startsWith("bottom") -> Gravity.BOTTOM
            else -> Gravity.CENTER_VERTICAL
        }
        val horizontal = when {
            position.endsWith("left") -> Gravity.START
            position.endsWith("right") -> Gravity.END
            else -> Gravity.CENTER_HORIZONTAL
        }
        return vertical or horizontal
    }

    @UsedByGodot
    fun show_banner() {
        activity?.runOnUiThread { bannerContainer?.visibility = View.VISIBLE }
    }

    @UsedByGodot
    fun hide_banner() {
        activity?.runOnUiThread { bannerContainer?.visibility = View.GONE }
    }

    @UsedByGodot
    fun destroy_banner() {
        activity?.runOnUiThread { destroyBanner() }
    }

    private fun destroyBanner() {
        bannerView?.destroy()
        bannerContainer?.let { (it.parent as? ViewGroup)?.removeView(it) }
        bannerView = null
        bannerContainer = null
    }
}
