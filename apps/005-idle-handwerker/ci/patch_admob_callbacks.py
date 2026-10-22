# Existing pinned v5.0.0 callback compatibility patch, shared by Android CI.
from pathlib import Path
import sys
root = Path(sys.argv[1])
replacements = {
    "gdscript/src/api/RewardedAd.gd": {
        "var on_ad_paid: Callable = func(_ad_value: AdValue): pass": "var on_ad_paid: Callable = Callable()",
    },
    "gdscript/src/api/listeners/FullScreenContentCallback.gd": {
        "var on_ad_clicked: Callable = func() -> void: pass": "var on_ad_clicked: Callable = Callable()",
        "var on_ad_dismissed_full_screen_content: Callable = func() -> void: pass": "var on_ad_dismissed_full_screen_content: Callable = Callable()",
        "var on_ad_failed_to_show_full_screen_content: Callable = func(adError: AdError) -> void: pass": "var on_ad_failed_to_show_full_screen_content: Callable = Callable()",
        "var on_ad_impression: Callable = func() -> void: pass": "var on_ad_impression: Callable = Callable()",
        "var on_ad_showed_full_screen_content: Callable = func() -> void: pass": "var on_ad_showed_full_screen_content: Callable = Callable()",
    },
    "gdscript/src/api/listeners/RewardedAdLoadCallback.gd": {
        "var on_ad_failed_to_load: Callable = func(adError: LoadAdError) -> void: pass": "var on_ad_failed_to_load: Callable = Callable()",
        "var on_ad_loaded: Callable = func(rewardedAd: RewardedAd) -> void: pass": "var on_ad_loaded: Callable = Callable()",
    },
    "gdscript/src/api/listeners/OnUserEarnedRewardListener.gd": {
        "var on_user_earned_reward: Callable = func(rewarded_item: RewardedItem): pass": "var on_user_earned_reward: Callable = Callable()",
    },
    "gdscript/src/ump/api/ConsentInformation.gd": {
        "on_consent_info_updated_success := func(): pass,": "on_consent_info_updated_success: Callable = Callable(),",
        "on_consent_info_updated_failure := func(form_error: FormError): pass,": "on_consent_info_updated_failure: Callable = Callable(),",
    },
    "gdscript/src/ump/api/UserMessagingPlatform.gd": {
        "on_consent_form_load_success_listener := func(consent_form: ConsentForm): pass,": "on_consent_form_load_success_listener: Callable = Callable(),",
        "on_consent_form_load_failure_listener := func(form_error: FormError): pass": "on_consent_form_load_failure_listener: Callable = Callable()",
        "on_privacy_options_form_dismissed := func(form_error: FormError): pass": "on_privacy_options_form_dismissed: Callable = Callable()",
    },
    "gdscript/src/ump/api/ConsentForm.gd": {
        "func show(on_consent_form_dismissed := func(form_error: FormError): pass) -> void:": "func show(on_consent_form_dismissed: Callable = Callable()) -> void:",
    },
}
for relative, changes in replacements.items():
    path = root / relative
    text = path.read_text()
    for old, new in changes.items():
        if old not in text:
            raise SystemExit(f"Missing expected AdMob callback in {relative}: {old}")
        text = text.replace(old, new, 1)
    path.write_text(text)
