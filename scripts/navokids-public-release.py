import sys,json
sys.path.insert(0,'scripts/calc-release')
from asc import api
app='6809038305'
assert api('/apps/'+app)['data']['attributes']['bundleId']=='com.kamilunavo.navokids'
versions=api('/apps/'+app+'/appStoreVersions?filter%5Bplatform%5D=IOS&limit=20')['data']
print('VERSIONS',json.dumps(versions))
builds=api('/builds?filter%5Bapp%5D='+app+'&filter%5Bversion%5D=12&limit=20')['data']
print('BUILD12',json.dumps(builds))
for b in builds: print('PRERELEASE',json.dumps(api('/builds/'+b['id']+'/preReleaseVersion')))
print('SUBMISSIONS',json.dumps(api('/apps/'+app+'/reviewSubmissions?limit=50')))
for v in versions[:3]:
 vid=v['id']
 print('VERSIONBUILD',vid,json.dumps(api('/appStoreVersions/'+vid+'/build')))
 locs=api('/appStoreVersions/'+vid+'/appStoreVersionLocalizations?limit=50')['data']
 print('LOCALES',vid,json.dumps(locs))
 for loc in locs:
  sets=api('/appStoreVersionLocalizations/'+loc['id']+'/appScreenshotSets?limit=50')['data']
  for s in sets:
   shots=api('/appScreenshotSets/'+s['id']+'/appScreenshots?limit=50')['data']
   print('SHOTS',loc['attributes']['locale'],s['attributes']['screenshotDisplayType'],len(shots))
