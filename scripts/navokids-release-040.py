"""Inspect or publish the authorized NavoKids 0.4.0 update; never print credentials."""
import json,sys,os
sys.path.insert(0,'scripts/calc-release')
from asc import api
APP='6809038305'
assert api('/apps/'+APP)['data']['attributes']['bundleId']=='com.kamilunavo.navokids'
versions=api('/apps/'+APP+'/appStoreVersions?filter%5Bplatform%5D=IOS&limit=20')['data']
print('VERSIONS',json.dumps([{'id':v['id'],'version':v['attributes']['versionString'],'state':v['attributes']['appStoreState'],'releaseType':v['attributes'].get('releaseType')}for v in versions]),flush=True)
builds=api('/builds?filter%5Bapp%5D='+APP+'&limit=10')['data']
for b in builds:
    pre=api('/builds/'+b['id']+'/preReleaseVersion')['data']
    print('BUILD',json.dumps({'id':b['id'],'version':pre['attributes']['version'],'build':b['attributes']['version'],'processing':b['attributes']['processingState']}),flush=True)
subs=api('/apps/'+APP+'/reviewSubmissions?limit=20')['data']
print('REVIEWS',json.dumps([{'id':s['id'],'state':s['attributes']['state']}for s in subs]),flush=True)
assert os.environ.get('NAVOKIDS_RELEASE_MODE','inspect')=='inspect','Publication requires a validated exact build ID'
