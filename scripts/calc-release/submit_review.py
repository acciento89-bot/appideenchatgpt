"""Submit only prepared Calc 1.0 build 5, checking every prerequisite."""
import json,os,time
from pathlib import Path
from asc import api
from prepare_review import patch

app=os.environ['APP_ID'];scheme=os.environ['SCHEME'];m=json.loads(Path('scripts/calc-release/metadata.json').read_text())[scheme]
assert api('/apps/'+app)['data']['attributes']['bundleId']==os.environ['BUNDLE_ID']
v=next(v for v in api('/apps/'+app+'/appStoreVersions?filter%5Bplatform%5D=IOS&limit=20')['data'] if v['attributes']['versionString']=='1.0');vid=v['id']
b=api('/appStoreVersions/'+vid+'/build')['data'];assert b and b['attributes']['version']=='5' and b['attributes']['processingState']=='VALID'
review=api('/appStoreVersions/'+vid+'/appStoreReviewDetail')['data'];assert review['attributes']['notes']==m['notes'] and not review['attributes']['demoAccountRequired']
locs=api('/appStoreVersions/'+vid+'/appStoreVersionLocalizations?limit=50')['data']
for locale,lang in [('de-DE','de'),('en-US','en')]:
 loc=next(l for l in locs if l['attributes']['locale']==locale);assert loc['attributes']['description']==m['description_'+lang]
 sets=api('/appStoreVersionLocalizations/'+loc['id']+'/appScreenshotSets?limit=50')['data']
 for display in ['APP_IPHONE_67','APP_IPAD_PRO_3GEN_129']:
  s=next(s for s in sets if s['attributes']['screenshotDisplayType']==display)
  shots=api('/appScreenshotSets/'+s['id']+'/appScreenshots?limit=50')['data']
  assert len(shots)>=2 and all(x['attributes']['fileName'].startswith('build5-') and x['attributes']['assetDeliveryState']['state']=='COMPLETE' for x in shots)
if v['attributes']['appStoreState'] in ['WAITING_FOR_REVIEW','IN_REVIEW','READY_FOR_SALE','PENDING_DEVELOPER_RELEASE']:
 print(scheme,'already submitted',v['attributes']['appStoreState']);raise SystemExit(0)
subs=api('/apps/'+app+'/reviewSubmissions?limit=50')['data']
active=[s for s in subs if s['attributes']['state'] in ['READY_FOR_REVIEW','UNRESOLVED_ISSUES']]
assert len(active)<=1,'Multiple active review packages require inspection'
s=active[0] if active else api('/reviewSubmissions','POST',{'data':{'type':'reviewSubmissions','attributes':{'platform':'IOS'},'relationships':{'app':{'data':{'type':'apps','id':app}}}}})['data'];sid=s['id']
items=api('/reviewSubmissions/'+sid+'/items?limit=200')['data']
for item in items:
 assert item.get('relationships',{}).get('appStoreVersion',{}).get('data',{}).get('id')==vid,'Unexpected item in review package'
if not items:
 items=[api('/reviewSubmissionItems','POST',{'data':{'type':'reviewSubmissionItems','relationships':{'reviewSubmission':{'data':{'type':'reviewSubmissions','id':sid}},'appStoreVersion':{'data':{'type':'appStoreVersions','id':vid}}}}})['data']]
for item in items:
 if item['attributes'].get('state')=='REJECTED':patch('reviewSubmissionItems',item['id'],{'resolved':True})
patch('reviewSubmissions',sid,{'submitted':True})
for _ in range(30):
 state=api('/reviewSubmissions/'+sid)['data']['attributes']['state']
 if state in ['WAITING_FOR_REVIEW','IN_REVIEW','COMPLETE']:break
 time.sleep(4)
assert state in ['WAITING_FOR_REVIEW','IN_REVIEW','COMPLETE'],state
print('SUBMITTED',json.dumps({'app':app,'scheme':scheme,'version':'1.0','build':'5','submission':sid,'state':state}))
with open(os.environ['GITHUB_STEP_SUMMARY'],'a') as f:f.write(f'### {scheme}: {state}\nVersion 1.0 (5), DE/EN metadata and actual screenshots submitted.\n')
