"""Capture native iOS components, without test controls, on iPhone and iPad."""
import json, os, pathlib, struct, subprocess, time
root=pathlib.Path('source'); capture=pathlib.Path('navokids-store-captures');capture.mkdir(exist_ok=True)
workspace=next((root/'ios').glob('*.xcworkspace'))
project=next((root/'ios').glob('*.xcodeproj'))
subprocess.run(['xcodebuild','build','-workspace',str(workspace),'-scheme',project.stem,'-configuration','Release','-sdk','iphonesimulator','-destination','generic/platform=iOS Simulator','-derivedDataPath','sim-build','CODE_SIGNING_ALLOWED=NO'],check=True)
app=next(pathlib.Path('sim-build/Build/Products/Release-iphonesimulator').glob('*.app'))
devices=json.loads(subprocess.check_output(['xcrun','simctl','list','devices','available','--json']))['devices']
devices=[d for runtime,rows in devices.items() if 'iOS' in runtime for d in rows if d.get('isAvailable')]
for family in ['iPhone','iPad']:
 d=next(d for d in devices if ('Pro Max' in d['name'] if family=='iPhone' else 'iPad Pro 13' in d['name']))
 uid=d['udid'];print('DEVICE',family,d['name'],flush=True)
 def sim(*args,check=True): return subprocess.run(['xcrun','simctl',*args],check=check)
 if d.get('state')!='Booted':sim('boot',uid)
 sim('bootstatus',uid,'-b');sim('status_bar',uid,'override','--time','9:41','--batteryState','charged','--batteryLevel','100')
 sim('install',uid,str(app));sim('launch',uid,'com.kamilunavo.navokids');started=time.monotonic()
 for index in range(10):
  target=started+10+20*index;time.sleep(max(0,target-time.monotonic()))
  locale='de-DE' if index<5 else 'en-US';folder=capture/locale/family;folder.mkdir(parents=True,exist_ok=True)
  path=folder/(f'{index%5+1:02d}-'+['map','new-islands','clock','nature','shapes'][index%5]+'.png')
  sim('io',uid,'screenshot',str(path))
  size=struct.unpack('>II',path.read_bytes()[16:24]);assert size in ([(1320,2868),(1290,2796),(1260,2736)] if family=='iPhone' else [(2064,2752),(2048,2732)]),(family,size)
 sim('shutdown',uid)
print('CAPTURED',len(list(capture.rglob('*.png'))),'native iOS screenshots',flush=True)
