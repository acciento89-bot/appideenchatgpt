import pathlib,unittest,importlib.util
ROOT=pathlib.Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('runner',ROOT/'run_acceptance.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class PreflightTests(unittest.TestCase):
 def fake(self,sdk=b'35',qemu=b'1',anr=b'No ANR',keyboard=b'1'):
  calls=[]
  def call(args):
   calls.append(args)
   if args[-1]=='ro.build.version.sdk':return sdk
   if args[-1]=='ro.kernel.qemu':return qemu
   if args[-1]=='lastanr':return anr
   if args[:3]==['shell','settings','get']:return keyboard
   return b''
  return call,calls
 def test_personal_device_never_receives_an_adb_call(self):
  call,calls=self.fake()
  with self.assertRaises(RuntimeError):m.preflight(call,'personal-phone')
  self.assertEqual([],calls)
 def test_wrong_api_physical_device_or_system_anr_prevent_keyboard_setting(self):
  for options in [{'sdk':b'36'},{'qemu':b'0'},{'anr':b'ANR com.android.systemui'},{'anr':b'ANR in com.google.android.apps.nexuslauncher'},{'anr':b'Application Not Responding: unrelated.package'}]:
   call,calls=self.fake(**options)
   with self.assertRaises(RuntimeError):m.preflight(call,'emulator-5554')
   self.assertFalse(any('settings' in x for x in calls))
 def test_explicit_owned_keyboard_setting_and_exact_readback(self):
  call,calls=self.fake();m.preflight(call,'emulator-5554');self.assertEqual(calls[-2:], [['shell','settings','put','secure','show_ime_with_hard_keyboard','1'],['shell','settings','get','secure','show_ime_with_hard_keyboard']])
  for value in [b'0',b'null',b'1\n0']:
   call,_=self.fake(keyboard=value)
   with self.assertRaises(RuntimeError):m.preflight(call,'emulator-5554')
if __name__=='__main__':unittest.main()

class WindowTests(unittest.TestCase):
 def test_observed_launcher_anr_window_is_rejected(self):
  with self.assertRaises(RuntimeError):m.reject_anr_window(b"Window{e0 u0 Application Not Responding: com.google.android.apps.nexuslauncher}")
 def test_clean_window_is_accepted(self):
  m.reject_anr_window(b"Window{abc u0 de.kamilunavo.rapportai/.MainActivity}")

 def test_normal_launcher_after_test_teardown_is_not_an_anr(self):
  m.reject_anr_window(b"Window{abc u0 com.google.android.apps.nexuslauncher/.NexusLauncherActivity}")
