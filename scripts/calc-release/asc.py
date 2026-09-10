"""Scoped App Store Connect client; credentials remain on the GitHub runner."""
import base64,json,os,subprocess,time,urllib.request,urllib.error
from pathlib import Path

def token():
    ruby = '''require 'openssl'; require 'base64'; require 'json'
def b(v); Base64.urlsafe_encode64(v,padding:false); end
key=OpenSSL::PKey.read(File.read(ENV.fetch('ASC_KEY_PATH'))); now=Time.now.to_i
h=b(JSON.generate({alg:'ES256',kid:ENV.fetch('ASC_KEY_ID'),typ:'JWT'}))
p=b(JSON.generate({iss:ENV.fetch('ASC_ISSUER_ID'),iat:now,exp:now+1200,aud:'appstoreconnect-v1'})); s="#{h}.#{p}"
seq=OpenSSL::ASN1.decode(key.sign(OpenSSL::Digest::SHA256.new,s))
raw=seq.value.map{|i|[i.value.to_i.to_s(16).rjust(64,'0')].pack('H*')}.join
puts "#{s}.#{b(raw)}"'''
    return subprocess.check_output(['ruby','-e',ruby],text=True).strip()

def api(path,method='GET',body=None):
    data=json.dumps(body).encode() if body is not None else None
    req=urllib.request.Request('https://api.appstoreconnect.apple.com/v1'+path,data=data,headers={'Authorization':'Bearer '+token(),'Content-Type':'application/json'},method=method)
    try:
        with urllib.request.urlopen(req,timeout=90) as r:
            raw=r.read(); return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raise RuntimeError(f'{method} {path}: {e.code} {e.read().decode()}') from None

def inspect():
    app=os.environ['APP_ID']; bundle=os.environ['BUNDLE_ID']
    info=api('/apps/'+app)['data']; assert info['attributes']['bundleId']==bundle
    versions=api(f'/apps/{app}/appStoreVersions?filter%5Bplatform%5D=IOS&limit=20')['data']
    builds=api(f'/builds?filter%5Bapp%5D={app}&filter%5Bversion%5D=5&limit=20')['data']
    print(json.dumps({'app':app,'bundle':bundle,'versions':[{'id':v['id'],'attributes':v['attributes']} for v in versions],'build5':[{'id':b['id'],'attributes':b['attributes']} for b in builds]},ensure_ascii=False))
    for v in versions:
        if v['attributes']['versionString']=='1.0':
            for endpoint in ['appStoreVersionLocalizations','appStoreReviewDetail','build']:
                result=api(f"/appStoreVersions/{v['id']}/{endpoint}")
                if endpoint=='appStoreReviewDetail':
                    d=result.get('data')
                    if d: result={'data':{'id':d['id'],'attributes':{'notes':d['attributes'].get('notes'),'demoAccountRequired':d['attributes'].get('demoAccountRequired')}}}
                print(endpoint,json.dumps(result,ensure_ascii=False))
    with open(os.environ['GITHUB_OUTPUT'],'a') as f: f.write('exists='+str(bool(builds)).lower()+'\n')
    if builds and any(b['attributes']['processingState']=='INVALID' for b in builds): raise RuntimeError('Existing build 5 invalid; inspect before replacing version')

if __name__=='__main__': inspect()
