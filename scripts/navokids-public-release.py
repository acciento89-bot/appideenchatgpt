"""Submit the explicitly authorized NavoKids 0.3.2 (12) public update."""
import sys,json,time,os
sys.path.insert(0,'scripts/calc-release')
from asc import api
from prepare_review import patch,rel
app='6809038305'; old='3940b0b6-b4c8-4bfc-a573-a9b737b8f715'; bid='ede49bc7-5fa8-4cb3-a682-fc0dd85e258c'
assert api('/apps/'+app)['data']['attributes']['bundleId']=='com.kamilunavo.navokids'
b=api('/builds/'+bid)['data']; assert b['attributes']['version']=='12' and b['attributes']['processingState']=='VALID'
assert api('/builds/'+bid+'/preReleaseVersion')['data']['attributes']['version']=='0.3.2'
versions=api('/apps/'+app+'/appStoreVersions?filter%5Bplatform%5D=IOS&limit=20')['data']
v=next((v for v in versions if v['attributes']['versionString']=='0.3.2'),None)
if not v:
 v=api('/appStoreVersions','POST',{'data':{'type':'appStoreVersions','attributes':{'platform':'IOS','versionString':'0.3.2','copyright':'2026 Kamilunavo','releaseType':'AFTER_APPROVAL'},'relationships':{'app':{'data':{'type':'apps','id':app}},'build':{'data':{'type':'builds','id':bid}}}}})['data']
vid=v['id']; print('TARGET',vid,v['attributes']['appStoreState'],flush=True)
if v['attributes']['appStoreState'] in ['WAITING_FOR_REVIEW','IN_REVIEW','READY_FOR_SALE']:
 assert api('/appStoreVersions/'+vid+'/build')['data']['id']==bid
 print('ALREADY_SUBMITTED',v['attributes']['appStoreState']);sys.exit(0)
assert v['attributes']['appStoreState'] in ['PREPARE_FOR_SUBMISSION','DEVELOPER_REJECTED','REJECTED','METADATA_REJECTED']
patch('appStoreVersions',vid,{'releaseType':'AFTER_APPROVAL'})
rel('appStoreVersions',vid,'build','builds',bid)
oldlocs=api('/appStoreVersions/'+old+'/appStoreVersionLocalizations?limit=50')['data']
locs=api('/appStoreVersions/'+vid+'/appStoreVersionLocalizations?limit=50')['data']
for src in oldlocs:
 locale=src['attributes']['locale']
 loc=next((l for l in locs if l['attributes']['locale']==locale),None)
 if not loc:
  loc=api('/appStoreVersionLocalizations','POST',{'data':{'type':'appStoreVersionLocalizations','attributes':{'locale':locale},'relationships':{'appStoreVersion':{'data':{'type':'appStoreVersions','id':vid}}}}})['data']
 a=src['attributes']
 attrs={k:a[k] for k in ['description','keywords','supportUrl','marketingUrl','promotionalText'] if a.get(k) is not None}
 if locale=='de-DE':
  attrs['description']=attrs['description'].replace('fünf liebevoll','sechs liebevoll').replace('• Wörter, Wortgruppen und erste Sätze','• Wörter, Wortgruppen und erste Sätze\n• Formen erkennen und Muster ergänzen')
  attrs['promotionalText']='Mit Navi entdecken Kinder sechs bunte Lerninseln mit gesprochenen Aufgaben und einer Fortschrittsübersicht für Eltern.'
  attrs['whatsNew']='Neue Lerninsel Formen & Muster. Nach abgeschlossenen Stufen direkt weiterspielen. Die Stufenauswahl kehrt zur zuletzt gespielten Position zurück. Englische Wortkarten korrigiert. Neue Aufgaben mit unserer vertrauten Stimme auf Deutsch und Englisch.'
 elif locale=='en-US':
  attrs['description']=attrs['description'].replace('five colorful','six colorful').replace('• Words, word groups, and first sentences','• Words, word groups, and first sentences\n• Recognizing shapes and completing patterns')
  attrs['promotionalText']='Explore six colorful learning islands with Navi, spoken activities, and a protected progress dashboard for parents.'
  attrs['whatsNew']='New Shapes & Patterns island. Continue straight to the next stage after completing one. The stage list returns to your previous position. English word cards corrected. New activities with our familiar voice in German and English.'
 patch('appStoreVersionLocalizations',loc['id'],attrs)
 sets=api('/appStoreVersionLocalizations/'+loc['id']+'/appScreenshotSets?limit=50')['data']
 counts={}
 for s in sets:
  shots=api('/appScreenshotSets/'+s['id']+'/appScreenshots?limit=50')['data']
  counts[s['attributes']['screenshotDisplayType']]=len(shots)
  assert all(x['attributes']['assetDeliveryState']['state']=='COMPLETE' for x in shots)
 print('SCREENSHOTS',locale,counts,flush=True)
 if locale=='de-DE':
  assert counts.get('APP_IPHONE_65',0)>=3 and counts.get('APP_IPAD_PRO_3GEN_129',0)>=3,'Inherited screenshots missing'
review=api('/appStoreVersions/'+vid+'/appStoreReviewDetail')['data']
notes='NavoKids 0.3.2 (12) adds the Shapes & Patterns learning island, direct next-stage navigation, restored stage-list position and corrected English word cards. Narration is bundled German/English audio. Existing free stages and parental purchase protection are retained.'
if review:
 patch('appStoreReviewDetails',review['id'],{'notes':notes})
else:
 source=api('/appStoreVersions/'+old+'/appStoreReviewDetail')['data']['attributes']
 attrs={k:source[k] for k in ['contactFirstName','contactLastName','contactPhone','contactEmail','demoAccountRequired','demoAccountName','demoAccountPassword'] if source.get(k) is not None}
 attrs['notes']=notes
 api('/appStoreReviewDetails','POST',{'data':{'type':'appStoreReviewDetails','attributes':attrs,'relationships':{'appStoreVersion':{'data':{'type':'appStoreVersions','id':vid}}}}})
subs=api('/apps/'+app+'/reviewSubmissions?limit=50')['data']
active=[s for s in subs if s['attributes']['state'] in ['READY_FOR_REVIEW','UNRESOLVED_ISSUES']]
assert len(active)<=1
s=active[0] if active else api('/reviewSubmissions','POST',{'data':{'type':'reviewSubmissions','attributes':{'platform':'IOS'},'relationships':{'app':{'data':{'type':'apps','id':app}}}}})['data']
sid=s['id']
items=api('/reviewSubmissions/'+sid+'/items?include=appStoreVersion&limit=200')['data']
for item in items: assert item.get('relationships',{}).get('appStoreVersion',{}).get('data',{}).get('id')==vid
if not items:
 api('/reviewSubmissionItems','POST',{'data':{'type':'reviewSubmissionItems','relationships':{'reviewSubmission':{'data':{'type':'reviewSubmissions','id':sid}},'appStoreVersion':{'data':{'type':'appStoreVersions','id':vid}}}}})
patch('reviewSubmissions',sid,{'submitted':True})
for _ in range(20):
 state=api('/reviewSubmissions/'+sid)['data']['attributes']['state']
 if state in ['WAITING_FOR_REVIEW','IN_REVIEW','COMPLETE']:break
 time.sleep(3)
assert state in ['WAITING_FOR_REVIEW','IN_REVIEW','COMPLETE'],state
final=api('/appStoreVersions/'+vid)['data']['attributes']
assert final['releaseType']=='AFTER_APPROVAL'
print('SUBMITTED',json.dumps({'app':app,'version':'0.3.2','build':'12','versionId':vid,'submission':sid,'state':state,'releaseType':final['releaseType']}),flush=True)
