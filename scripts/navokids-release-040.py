"""Publish the authorized NavoKids 0.4.0 build after Apple has validated it."""
import json, os, sys, time
from pathlib import Path
sys.path.insert(0, 'scripts/calc-release')
from asc import api
from prepare_review import patch, rel
APP = '6809038305'
VERSION = '0.4.0'
EDITABLE = {'PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED', 'REJECTED', 'METADATA_REJECTED'}
SUBMITTED = {'WAITING_FOR_REVIEW', 'IN_REVIEW', 'PENDING_APPLE_RELEASE', 'READY_FOR_SALE', 'READY_FOR_DISTRIBUTION'}

def versions():
    return api('/apps/'+APP+'/appStoreVersions?filter%5Bplatform%5D=IOS&limit=30')['data']

def submissions():
    return api('/apps/'+APP+'/reviewSubmissions?limit=50')['data']

def items(sid):
    return api('/reviewSubmissions/'+sid+'/items?include=appStoreVersion&limit=200')['data']

def item_version(item):
    return item.get('relationships', {}).get('appStoreVersion', {}).get('data', {}).get('id')

def inspect():
    print('VERSIONS', json.dumps([{'id':v['id'], 'version':v['attributes']['versionString'], 'state':v['attributes']['appStoreState'], 'releaseType':v['attributes'].get('releaseType')} for v in versions()]), flush=True)
    for b in api('/builds?filter%5Bapp%5D='+APP+'&limit=20')['data']:
        pre = api('/builds/'+b['id']+'/preReleaseVersion')['data']
        print('BUILD', json.dumps({'id':b['id'], 'version':pre['attributes']['version'], 'build':b['attributes']['version'], 'processing':b['attributes']['processingState']}), flush=True)
    print('REVIEWS', json.dumps([{'id':s['id'], 'state':s['attributes']['state']} for s in submissions()]), flush=True)

def publish():
    bid, number = os.environ['NAVOKIDS_BUILD_ID'], os.environ['NAVOKIDS_BUILD_NUMBER']
    b = api('/builds/'+bid)['data']
    assert b['attributes']['version'] == number and b['attributes']['processingState'] == 'VALID', 'Exact build must be valid'
    assert api('/builds/'+bid+'/app')['data']['id'] == APP, 'Wrong app'
    assert api('/builds/'+bid+'/preReleaseVersion')['data']['attributes']['version'] == VERSION, 'Wrong version'
    allversions = versions()
    target = next((v for v in allversions if v['attributes']['versionString'] == VERSION), None)
    if target and target['attributes']['appStoreState'] in SUBMITTED:
        assert api('/appStoreVersions/'+target['id']+'/build')['data']['id'] == bid, 'Different submitted build'
        assert target['attributes']['releaseType'] == 'AFTER_APPROVAL'
        print('ALREADY_SUBMITTED', VERSION, number, target['attributes']['appStoreState'], flush=True)
        return
    # Only replace the known earlier NavoKids update, after the new build is valid.
    earlier = next((v for v in allversions if v['attributes']['versionString'] == '0.3.2'), None)
    if not target and earlier and earlier['attributes']['appStoreState'] in {'WAITING_FOR_REVIEW', 'IN_REVIEW'}:
        matches = []
        for sub in submissions():
            if sub['attributes']['state'] in {'WAITING_FOR_REVIEW', 'IN_REVIEW'}:
                its = items(sub['id'])
                if any(item_version(i) == earlier['id'] for i in its):
                    assert its and all(item_version(i) == earlier['id'] for i in its), 'Review includes unrelated items'
                    matches.append(sub)
        assert len(matches) == 1, 'Expected exact previous review'
        patch('reviewSubmissions', matches[0]['id'], {'canceled':True})
        for _ in range(40):
            earlier = api('/appStoreVersions/'+earlier['id'])['data']
            if earlier['attributes']['appStoreState'] in EDITABLE: break
            time.sleep(3)
        assert earlier['attributes']['appStoreState'] in EDITABLE, 'Previous review cancellation still processing'
        print('REPLACED_PREVIOUS_REVIEW', matches[0]['id'], flush=True)
    source = earlier or next(v for v in allversions if v['attributes']['appStoreState'] in {'READY_FOR_SALE','READY_FOR_DISTRIBUTION'})
    if not target and earlier and earlier['attributes']['appStoreState'] in EDITABLE:
        patch('appStoreVersions', earlier['id'], {'versionString':VERSION, 'releaseType':'AFTER_APPROVAL'})
        target = api('/appStoreVersions/'+earlier['id'])['data']
    if not target:
        assert all(v['attributes']['appStoreState'] in {'READY_FOR_SALE','READY_FOR_DISTRIBUTION','REPLACED_WITH_NEW_VERSION','REMOVED_FROM_SALE','DEVELOPER_REMOVED_FROM_SALE'} for v in allversions), 'Another pending version needs reconciliation'
        target = api('/appStoreVersions', 'POST', {'data':{'type':'appStoreVersions', 'attributes':{'platform':'IOS','versionString':VERSION,'copyright':'2026 Kamilunavo','releaseType':'AFTER_APPROVAL'}, 'relationships':{'app':{'data':{'type':'apps','id':APP}}}}})['data']
    vid = target['id']
    assert target['attributes']['versionString'] == VERSION and target['attributes']['appStoreState'] in EDITABLE
    if b['attributes'].get('usesNonExemptEncryption') is None:
        patch('builds', bid, {'usesNonExemptEncryption':False})
    patch('appStoreVersions', vid, {'releaseType':'AFTER_APPROVAL'})
    rel('appStoreVersions', vid, 'build', 'builds', bid)
    metadata = json.loads(Path('scripts/navokids-040-metadata.json').read_text())
    oldlocs = api('/appStoreVersions/'+source['id']+'/appStoreVersionLocalizations?limit=50')['data']
    locs = api('/appStoreVersions/'+vid+'/appStoreVersionLocalizations?limit=50')['data']
    for locale, updates in metadata.items():
        src = next((l for l in oldlocs if l['attributes']['locale']==locale), oldlocs[0])
        loc = next((l for l in locs if l['attributes']['locale']==locale), None)
        if not loc:
            loc = api('/appStoreVersionLocalizations','POST',{'data':{'type':'appStoreVersionLocalizations','attributes':{'locale':locale},'relationships':{'appStoreVersion':{'data':{'type':'appStoreVersions','id':vid}}}}})['data']
        attrs = {k:src['attributes'][k] for k in ['supportUrl','marketingUrl'] if src['attributes'].get(k)}
        attrs.update(updates)
        patch('appStoreVersionLocalizations',loc['id'],attrs)
        counts = {}
        for s in api('/appStoreVersionLocalizations/'+loc['id']+'/appScreenshotSets?limit=50')['data']:
            shots = api('/appScreenshotSets/'+s['id']+'/appScreenshots?limit=50')['data']
            assert all(x['attributes']['assetDeliveryState']['state']=='COMPLETE' for x in shots), 'Screenshot incomplete'
            counts[s['attributes']['screenshotDisplayType']] = len(shots)
        print('SCREENSHOTS',locale,counts,flush=True)
        if locale == 'de-DE':
            assert any(counts.get(k,0)>=3 for k in ['APP_IPHONE_65','APP_IPHONE_67']), 'iPhone screenshots missing'
            assert any(counts.get(k,0)>=3 for k in ['APP_IPAD_PRO_3GEN_129','APP_IPAD_PRO_3GEN_11']), 'iPad screenshots missing'
    review = api('/appStoreVersions/'+vid+'/appStoreReviewDetail')['data']
    notes = ('NavoKids 0.4.0 ('+number+') adds Nature & Weather and Clock & Time: eight distinct illustrated islands and 30 stages per island in two age groups. The learning clocks draw mathematically accurate hour/minute hands. Shape questions now ask which shape appears only once. All new questions and answer narration use bundled German/English recordings; no device speech. Existing progress, direct next-stage navigation, free stages and parental purchase protection are retained. No child account or login required.')
    if review:
        patch('appStoreReviewDetails',review['id'],{'notes':notes})
    else:
        original = api('/appStoreVersions/'+source['id']+'/appStoreReviewDetail')['data']['attributes']
        attrs = {k:original[k] for k in ['contactFirstName','contactLastName','contactPhone','contactEmail','demoAccountRequired','demoAccountName','demoAccountPassword'] if original.get(k) is not None}
        attrs['notes'] = notes
        api('/appStoreReviewDetails','POST',{'data':{'type':'appStoreReviewDetails','attributes':attrs,'relationships':{'appStoreVersion':{'data':{'type':'appStoreVersions','id':vid}}}}})
    active = [s for s in submissions() if s['attributes']['state'] in {'READY_FOR_REVIEW','UNRESOLVED_ISSUES'}]
    assert len(active)<=1, 'Multiple editable reviews'
    sub = active[0] if active else api('/reviewSubmissions','POST',{'data':{'type':'reviewSubmissions','attributes':{'platform':'IOS'},'relationships':{'app':{'data':{'type':'apps','id':APP}}}}})['data']
    sid = sub['id']; its = items(sid)
    assert all(item_version(i)==vid for i in its), 'Unrelated review item'
    if not its:
        api('/reviewSubmissionItems','POST',{'data':{'type':'reviewSubmissionItems','relationships':{'reviewSubmission':{'data':{'type':'reviewSubmissions','id':sid}},'appStoreVersion':{'data':{'type':'appStoreVersions','id':vid}}}}})
    patch('reviewSubmissions',sid,{'submitted':True})
    for _ in range(30):
        state = api('/reviewSubmissions/'+sid)['data']['attributes']['state']
        if state in {'WAITING_FOR_REVIEW','IN_REVIEW','COMPLETE'}: break
        time.sleep(3)
    assert state in {'WAITING_FOR_REVIEW','IN_REVIEW','COMPLETE'}, state
    final = api('/appStoreVersions/'+vid)['data']['attributes']
    assert final['releaseType']=='AFTER_APPROVAL'
    assert api('/appStoreVersions/'+vid+'/build')['data']['id']==bid
    print('SUBMITTED',json.dumps({'app':APP,'version':VERSION,'build':number,'versionId':vid,'submission':sid,'reviewState':state,'versionState':final['appStoreState'],'releaseType':final['releaseType']}),flush=True)

def main():
    assert api('/apps/'+APP)['data']['attributes']['bundleId']=='com.kamilunavo.navokids'
    mode = os.environ.get('NAVOKIDS_RELEASE_MODE','inspect')
    assert mode in {'inspect','publish'}
    inspect() if mode=='inspect' else publish()

if __name__=='__main__': main()
