"""Prepare only the five explicitly selected Calc build-5 submissions."""
import hashlib,json,os,struct,time,urllib.request
from pathlib import Path
from asc import api

def patch(kind,id,attrs):return api(f'/{kind}/{id}','PATCH',{'data':{'type':kind,'id':id,'attributes':attrs}})
def rel(kind,id,relation,type,rid):return api(f'/{kind}/{id}/relationships/{relation}','PATCH',{'data':{'type':type,'id':rid}})

def upload(setid,path):
 raw=path.read_bytes();name='build5-'+path.name
 existing=api('/appScreenshotSets/'+setid+'/appScreenshots?limit=50')['data']
 old=next((s for s in existing if s['attributes']['fileName']==name),None)
 if old:
  if old['attributes']['assetDeliveryState']['state']=='COMPLETE':return old['id']
  api('/appScreenshots/'+old['id'],'DELETE')
 shot=api('/appScreenshots','POST',{'data':{'type':'appScreenshots','attributes':{'fileName':name,'fileSize':len(raw)},'relationships':{'appScreenshotSet':{'data':{'type':'appScreenshotSets','id':setid}}}}})['data']
 for op in shot['attributes']['uploadOperations']:
  request=urllib.request.Request(op['url'],data=raw[op['offset']:op['offset']+op['length']],headers={h['name']:h['value'] for h in op.get('requestHeaders',[])},method=op['method'])
  with urllib.request.urlopen(request,timeout=120) as r:assert 200<=r.status<300
 patch('appScreenshots',shot['id'],{'uploaded':True,'sourceFileChecksum':hashlib.md5(raw).hexdigest()})
 for _ in range(40):
  s=api('/appScreenshots/'+shot['id'])['data']['attributes']['assetDeliveryState']
  if s['state']=='COMPLETE':return shot['id']
  if s['state']=='FAILED':raise RuntimeError(str(s))
  time.sleep(3)
 raise RuntimeError('Screenshot processing timed out')

def main():
 app=os.environ['APP_ID'];scheme=os.environ['SCHEME'];m=json.loads(Path('scripts/calc-release/metadata.json').read_text())[scheme]
 info=api('/apps/'+app)['data'];assert info['attributes']['bundleId']==os.environ['BUNDLE_ID']
 versions=api(f'/apps/{app}/appStoreVersions?filter%5Bplatform%5D=IOS&limit=20')['data']
 v=next(v for v in versions if v['attributes']['versionString']=='1.0');vid=v['id']
 assert v['attributes']['appStoreState'] in ['REJECTED','METADATA_REJECTED','PREPARE_FOR_SUBMISSION','DEVELOPER_REJECTED'],v['attributes']['appStoreState']
 builds=api(f'/builds?filter%5Bapp%5D={app}&filter%5Bversion%5D=5&limit=20')['data']
 assert len(builds)==1 and builds[0]['attributes']['processingState']=='VALID','Build 5 must be processed before metadata replacement'
 bid=builds[0]['id'];pr=api('/builds/'+bid+'/preReleaseVersion')['data'];assert pr['attributes']['version']=='1.0'
 if builds[0]['attributes'].get('usesNonExemptEncryption') is None:patch('builds',bid,{'usesNonExemptEncryption':False})
 root=Path('release-captures')/scheme
 images={}
 for family,display in [('iPhone','APP_IPHONE_67'),('iPad','APP_IPAD_PRO_3GEN_129')]:
  files=sorted((root/family).glob('*.png'))
  assert 2<=len(files)<=10,(family,len(files))
  for f in files:
   size=struct.unpack('>II',f.read_bytes()[16:24]);assert size in ([(1320,2868),(1290,2796),(1260,2736)] if family=='iPhone' else [(2064,2752),(2048,2732)])
  images[display]=files
 locs=api('/appStoreVersions/'+vid+'/appStoreVersionLocalizations?limit=50')['data']
 support=next((l['attributes'].get('supportUrl') for l in locs if l['attributes'].get('supportUrl')),None)
 assert support,'Existing support URL missing'
 for locale in ['de-DE','en-US']:
  if not any(l['attributes']['locale']==locale for l in locs):
   locs.append(api('/appStoreVersionLocalizations','POST',{'data':{'type':'appStoreVersionLocalizations','attributes':{'locale':locale},'relationships':{'appStoreVersion':{'data':{'type':'appStoreVersions','id':vid}}}}})['data'])
 locs=[l for l in locs if l['attributes']['locale'] in ['de-DE','en-US']]
 for loc in locs:
  lid=loc['id'];lang='de' if loc['attributes']['locale']=='de-DE' else 'en'
  patch('appStoreVersionLocalizations',lid,{'description':m['description_'+lang],'promotionalText':m['subtitle_'+lang],'supportUrl':loc['attributes'].get('supportUrl') or support})
  sets=api('/appStoreVersionLocalizations/'+lid+'/appScreenshotSets?limit=50')['data']
  keep={}
  for display,files in images.items():
   s=next((s for s in sets if s['attributes']['screenshotDisplayType']==display),None)
   if not s:s=api('/appScreenshotSets','POST',{'data':{'type':'appScreenshotSets','attributes':{'screenshotDisplayType':display},'relationships':{'appStoreVersionLocalization':{'data':{'type':'appStoreVersionLocalizations','id':lid}}}}})['data']
   keep[s['id']]=[upload(s['id'],f) for f in files]
  # Every new family has reached COMPLETE before obsolete images are removed.
  allsets=api('/appStoreVersionLocalizations/'+lid+'/appScreenshotSets?limit=50')['data']
  for s in allsets:
   shots=api('/appScreenshotSets/'+s['id']+'/appScreenshots?limit=50')['data']
   for shot in shots:
    if shot['id'] not in keep.get(s['id'],[]):api('/appScreenshots/'+shot['id'],'DELETE')
  print('Updated locale and screenshots',scheme,loc['attributes']['locale'],flush=True)
 # Update subtitles on editable app information only.
 infos=api('/apps/'+app+'/appInfos?limit=20')['data']
 editable=[i for i in infos if i['attributes'].get('appStoreState') in ['PREPARE_FOR_SUBMISSION','REJECTED','METADATA_REJECTED','DEVELOPER_REJECTED']]
 for i in editable:
  for l in api('/appInfos/'+i['id']+'/appInfoLocalizations?limit=50')['data']:
   locale=l['attributes']['locale']
   if locale in ['de-DE','en-US']:patch('appInfoLocalizations',l['id'],{'subtitle':m['subtitle_de' if locale=='de-DE' else 'subtitle_en']})
 review=api('/appStoreVersions/'+vid+'/appStoreReviewDetail')['data'];assert review
 patch('appStoreReviewDetails',review['id'],{'notes':m['notes'],'demoAccountRequired':False})
 rel('appStoreVersions',vid,'build','builds',bid)
 subs=api('/apps/'+app+'/reviewSubmissions?limit=50')['data']
 print('REVIEW_STATE',json.dumps({'app':app,'scheme':scheme,'version':vid,'build':bid,'submissions':[{'id':s['id'],'attributes':s['attributes']} for s in subs]}),flush=True)
 for s in subs:
  if s['attributes']['state'] in ['UNRESOLVED_ISSUES','READY_FOR_REVIEW']:
   print('REVIEW_ITEMS',json.dumps(api('/reviewSubmissions/'+s['id']+'/items?limit=200')),flush=True)
 with open(os.environ['GITHUB_STEP_SUMMARY'],'a') as f:f.write(f'### {scheme}\nBuild 5 selected; DE/EN metadata, EULA, review notes and actual iPhone/iPad screenshots saved. Submission remains a separate explicit step.\n')

if __name__=='__main__':main()
