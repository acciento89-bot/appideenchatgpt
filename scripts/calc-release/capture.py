"""Capture real workflows at Apple's required large iPhone and iPad dimensions."""
import json,os,subprocess
from pathlib import Path
scheme=os.environ['SCHEME']; project=os.environ['XCODE_PROJECT']
raw=json.loads(subprocess.check_output(['xcrun','simctl','list','devices','available','--json']))
devices=[d for runtime,rows in raw['devices'].items() if 'iOS' in runtime for d in rows if d.get('isAvailable')]
for family in ['iPhone','iPad']:
 device=next((d for d in devices if ('Pro Max' in d['name'] if family=='iPhone' else 'iPad Pro 13' in d['name'])),None)
 if not device: raise RuntimeError('Required large simulator unavailable: '+family)
 udid=device['udid'];print('Capturing',scheme,device['name'],flush=True)
 if device.get('state')!='Booted':subprocess.run(['xcrun','simctl','boot',udid],check=True)
 subprocess.run(['xcrun','simctl','bootstatus',udid,'-b'],check=True)
 subprocess.run(['xcrun','simctl','status_bar',udid,'override','--time','9:41','--batteryState','charged','--batteryLevel','100'],check=True)
 result=Path(os.environ['RUNNER_TEMP'])/(scheme+'-'+family+'.xcresult')
 subprocess.run(['xcodebuild','test','-project',project,'-scheme',scheme,'-destination','platform=iOS Simulator,id='+udid,'-parallel-testing-enabled','NO','-resultBundlePath',str(result),'CODE_SIGNING_ALLOWED=NO'],check=True)
 attachments=Path(os.environ['RUNNER_TEMP'])/(scheme+'-'+family+'-attachments')
 subprocess.run(['xcrun','xcresulttool','export','attachments','--path',str(result),'--output-path',str(attachments)],check=True)
 out=Path('../release-captures')/scheme/family;out.mkdir(parents=True,exist_ok=True)
 for group in json.loads((attachments/'manifest.json').read_text()):
  for a in group['attachments']:
   name=a['suggestedHumanReadableName'].split('_')[0]
   if not name[:2].isdigit() or 'accessibility' in name:continue
   target=out/(name+'.png');target.write_bytes((attachments/a['exportedFileName']).read_bytes())
   import struct
   width,height=struct.unpack('>II',target.read_bytes()[16:24])
   assert (width,height) in ([(1320,2868),(1290,2796),(1260,2736)] if family=='iPhone' else [(2064,2752),(2048,2732)]),(width,height)
 subprocess.run(['xcrun','simctl','shutdown',udid],check=True)
