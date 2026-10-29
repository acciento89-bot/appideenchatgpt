"""One owned API35 device, actual free-user Compose UI and a process-cold second invocation."""
import hashlib,io,json,os,pathlib,re,subprocess,tarfile,datetime
PACKAGE='de.kamilunavo.rapportai'
METHODS=['positionsTemplateAcknowledgementRevisionAndPdfThroughRealUi','coldReopenRetainsExactHistoryAndTemplate']
NATIVE_FILES={f'{i:02d}-{name}.png' for i,name in enumerate(['entered-positions','local-acknowledgement','new-unacknowledged-revision','blank-template','cold-reopened'],1)}
OPTIONAL_FILES={'failure-screen.png','failure-semantics.txt'}
NATIVE_FILES |= {'actual-report.pdf','pdf-page-count.txt'} | {f'pdf-page-{i}.png' for i in range(1,13)}
GENERIC_FILES={'result.json','source-commit.txt','build.log','preflight-anr.txt','installed-identity.txt','scenario.txt','cold-reopen.txt','actual-archive.json','before-cold-archive.json','final-screen.png','window.txt','logcat.txt','final-ui.xml','emulator-stop.txt','avd-delete.txt','remaining-avds.txt','remaining-devices.txt','cleanup.json','cleanup-failed.txt'}
def reject_anr(evidence):
 if re.search(rb'ANR in|Application Not Responding|com.android.systemui|com.google.android.apps.nexuslauncher',evidence,re.I):
  raise RuntimeError('System/launcher ANR; evidence rejected without dialog dismissal')

def reject_anr_window(evidence):
 if not re.search(rb'Window\{[^}]+\}',evidence):
  raise RuntimeError('Actual window inventory required')
 if re.search(rb'ANR in|Application Not Responding|isn.t responding',evidence,re.I):
  raise RuntimeError('ANR window; evidence rejected without dialog dismissal')

def preflight(call,serial):
 if serial!='emulator-5554':raise RuntimeError('Only the single workflow-owned emulator is permitted')
 if call(['shell','getprop','ro.build.version.sdk']).strip()!=b'35':raise RuntimeError('Expected API35')
 if call(['shell','getprop','ro.kernel.qemu']).strip()!=b'1':raise RuntimeError('Physical devices prohibited')
 anr=call(['shell','dumpsys','activity','lastanr'])
 reject_anr(anr)
 call(['shell','settings','put','secure','show_ime_with_hard_keyboard','1'])
 if call(['shell','settings','get','secure','show_ime_with_hard_keyboard']).strip()!=b'1':raise RuntimeError('Keyboard preference not established')
 return anr

def run(execute=subprocess.run):
 runtime=pathlib.Path(os.environ['RUNNER_TEMP']).resolve();proof=runtime/'rapport-native-acceptance'/'rapport'
 assert not proof.is_symlink() and not proof.parent.is_symlink();proof.mkdir(parents=True,exist_ok=True,mode=0o700)
 result={'status':'STARTED','package':PACKAGE,'version':'1.3.0(4)','transactions':False,'fixtureRecordsInjected':False,'testMethods':METHODS};validated=False
 def call(args,timeout=15):
  p=execute(['adb','-s','emulator-5554',*args],stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=timeout)
  if p.returncode:raise RuntimeError('Owned adb command failed: '+args[0])
  return p.stdout
 def capture(name,args):
  try:(proof/name).write_bytes(call(args,15))
  except BaseException as e:result.setdefault('diagnostics',{})[name]=type(e).__name__
 try:
  (proof/'preflight-anr.txt').write_bytes(preflight(call,'emulator-5554'));validated=True
  apks=[pathlib.Path('apps/012-rapport-ai/android/app/build/outputs/apk/debug/app-debug.apk'),pathlib.Path('apps/012-rapport-ai/android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk')]
  result['apkSha256']={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in apks}
  for p in apks:call(['install','-r',str(p)],90)
  identity=call(['shell','dumpsys','package',PACKAGE]);(proof/'installed-identity.txt').write_bytes(identity)
  assert re.search(rb'\bversionCode=5(?=\s|$)',identity) and re.search(rb'\bversionName=1\.3\.0(?=\s|$)',identity),'Installed identity mismatch'
  previous=None
  for method,filename in zip(METHODS,['scenario.txt','cold-reopen.txt']):
   if previous is not None:call(['shell','am','force-stop',PACKAGE])
   command=['adb','-s','emulator-5554','shell','am','instrument','-w','-r','-e','class',PACKAGE+'.StructuredWorkNativeTest#'+method,PACKAGE+'.test/androidx.test.runner.AndroidJUnitRunner']
   p=execute(command,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=360);text=p.stdout or b'';(proof/filename).write_bytes(text+(p.stderr or b''))
   assert p.returncode==0 and b'OK (1 test)' in text and not any(x in text for x in [b'FAILURES',b'INSTRUMENTATION_FAILED',b'Process crashed']),'Actual native scenario failed: '+method
   actual=call(['exec-out','run-as',PACKAGE,'cat','files/RapportAI/workspace.json'])
   document=json.loads(actual);assert document['schemaVersion']==1 and len(document['reports'])==1 and len(document['templates'])==1
   value=document['reports'][0];assert len(value['revisions'])==2 and len(value['acknowledgements'])==1 and len(value['workItems'])==6
   assert value['acknowledgements'][0]['revisionID']==value['revisions'][0]['id'] and value['revisions'][0]['content']['reportText']!=value['revisions'][1]['content']['reportText']
   assert all(set(line)=={'kind','description','unit'} for line in document['templates'][0]['lines'])
   if previous is None:(proof/'before-cold-archive.json').write_bytes(actual);previous=actual
   else:assert previous==actual,'Cold reopen changed immutable archive';(proof/'actual-archive.json').write_bytes(actual)
  reject_anr(call(['shell','dumpsys','activity','lastanr']))
  window=call(['shell','dumpsys','window','windows']);assert window.strip(),'Empty window evidence';reject_anr_window(window)
  result['archiveSha256']=hashlib.sha256(previous).hexdigest()
  result['status']='PASSED'
 except BaseException as e:result['status']='FAILED';result['error']=str(e)
 finally:
  if validated:
   capture('final-screen.png',['exec-out','screencap','-p']);capture('window.txt',['shell','dumpsys','window','windows']);capture('logcat.txt',['logcat','-d','-t','1500'])
   try:
    call(['shell','uiautomator','dump','/sdcard/rapport-native.xml'],15);capture('final-ui.xml',['exec-out','cat','/sdcard/rapport-native.xml'])
   except BaseException:pass
   try:
    packed=call(['exec-out','run-as',PACKAGE,'tar','-cf','-','-C','files','native-proof'],20);assert len(packed)<32*1024*1024
    found=set()
    with tarfile.open(fileobj=io.BytesIO(packed)) as t:
     for m in t.getmembers():
      if m.isdir():continue
      p=pathlib.PurePosixPath(m.name);assert m.isfile() and p.parent==pathlib.PurePosixPath('native-proof') and p.name in NATIVE_FILES | OPTIONAL_FILES and p.name not in found and m.size<8*1024*1024
      found.add(p.name);(proof/p.name).write_bytes(t.extractfile(m).read())
    if result['status']=='PASSED':
     count=int((proof/'pdf-page-count.txt').read_text());assert 2<=count<=12
     expected={n for n in NATIVE_FILES if not n.startswith('pdf-page-')} | {'pdf-page-count.txt'} | {f'pdf-page-{i}.png' for i in range(1,count+1)}
     assert found==expected,'Incomplete actual native screenshot/PDF evidence';result['actualPdfPages']=count
   except BaseException as e:
    result.setdefault('diagnostics',{})['nativeEvidence']=str(e)
    if result['status']=='PASSED':result.update(status='FAILED',error='Native evidence incomplete')
   try:call(['shell','am','force-stop',PACKAGE])
   except BaseException:pass
  result['finishedUTC']=datetime.datetime.now(datetime.timezone.utc).isoformat();(proof/'result.json').write_text(json.dumps(result,indent=2)+'\n')
 return result
if __name__=='__main__':
 os.umask(0o077);r=run();print(json.dumps({'status':r['status'],'evidence':'encrypted artifact only'}));raise SystemExit(0 if r['status']=='PASSED' else 1)
