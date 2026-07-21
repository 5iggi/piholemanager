<?php
require_once "loxberry_system.php";
require_once "loxberry_web.php";

$L = LBSystem::readlanguage("language.ini");
$helper = LBPBINDIR . "/piholemanager.sh";

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
function shq($s) { return escapeshellarg($s); }
function run_helper($args, $sudo = false) {
    global $helper;
    $cmd = ($sudo ? 'sudo -n ' : '') . shq($helper);
    foreach ($args as $a) { $cmd .= ' ' . shq($a); }
    exec($cmd . ' 2>&1', $out, $rc);
    return [$rc, implode("\n", $out)];
}
function j($a) {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($a);
    exit;
}
function valid_conf($f) {
    return preg_match('/^[A-Za-z0-9_.-]+\.conf$/', $f) && strpos($f, '..') === false;
}
function plugin_icon_uri() {
    $uri = '';
    try {
        $plugins = LBSystem::get_plugins();
        foreach ($plugins as $pl) {
            $folder = $pl['PLUGINDB_FOLDER'] ?? '';
            $name = $pl['PLUGINDB_NAME'] ?? '';
            if ($folder === LBPPLUGINDIR || $name === 'piholemanager' || $folder === 'piholemanager') {
                $uri = $pl['PLUGINDB_ICONURI'] ?? '';
                break;
            }
        }
    } catch (Throwable $e) {}
    return $uri;
}

$ajax = $_REQUEST['ajax'] ?? '';

if ($ajax === 'status') {
    [$rc, $out] = run_helper(['status'], true);
    header('Content-Type: application/json; charset=utf-8');
    echo $out;
    exit;
}
if ($ajax === 'install_state') {
    [$rc, $out] = run_helper(['install-state'], true);
    header('Content-Type: application/json; charset=utf-8');
    echo $out;
    exit;
}
if ($ajax === 'install_start') {
    [$rc, $out] = run_helper(['install-start', $_POST['web_port'] ?? '8000'], true);
    j(['ok' => $rc === 0, 'output' => $out]);
}
if ($ajax === 'conf_list') {
    [$rc, $out] = run_helper(['list-confs'], true);
    j(['ok' => $rc === 0, 'files' => array_values(array_filter(explode("\n", trim($out))))]);
}
if ($ajax === 'conf_read') {
    $f = $_GET['file'] ?? '';
    if (!valid_conf($f)) j(['ok' => false, 'output' => 'invalid filename']);
    [$rc, $out] = run_helper(['read-conf', $f], true);
    j(['ok' => $rc === 0, 'output' => $out]);
}

if ($ajax === 'action') {
    $a = $_POST['action'] ?? '';
    $args = [];

    if ($a === 'set_password') {
        $p1 = $_POST['pihole_password'] ?? '';
        $p2 = $_POST['pihole_password_confirm'] ?? '';
        if ($p1 === '' || $p1 !== $p2) j(['ok' => false, 'output' => $GLOBALS['L']['ACTIONS.PASSWORD_MISMATCH']]);
        $tmp = '/tmp/pihole_pw_' . getmypid() . '.txt';
        file_put_contents($tmp, $p1);
        chmod($tmp, 0600);
        $args = ['action-run', 'set-password-file', $tmp];
    } elseif ($a === 'set_port') {
        $args = ['action-run', 'set-port', $_POST['web_port'] ?? '8000'];
    } elseif ($a === 'backup') {
        $args = ['action-run', 'backup', 'frontend'];
    } elseif ($a === 'healthcheck') {
        $args = ['action-run', 'healthcheck'];
    } elseif ($a === 'syntax_test') {
        $args = ['action-run', 'syntax-test'];
    } elseif ($a === 'enable_dnsmasq_d') {
        $args = ['action-run', 'enable-dnsmasq-d'];
    } elseif ($a === 'restart_ftl') {
        $args = ['action-run', 'restart-ftl'];
    } elseif ($a === 'template_custom') {
        $args = ['action-run', 'write-template'];
    } elseif ($a === 'conf_save') {
        $f = $_POST['conf_file'] ?? '';
        if (!valid_conf($f)) j(['ok' => false, 'output' => 'invalid filename']);
        $tmp = '/tmp/phm_conf_' . getmypid() . '.conf';
        file_put_contents($tmp, $_POST['conf_text'] ?? '');
        chmod($tmp, 0600);
        $args = ['action-run', 'write-conf', $f, $tmp];
    } elseif ($a === 'conf_delete') {
        $f = $_POST['conf_file'] ?? '';
        if (!valid_conf($f)) j(['ok' => false, 'output' => 'invalid filename']);
        $args = ['action-run', 'delete-conf', $f];
    } elseif ($a === 'conf_upload') {
        $f = $_POST['upload_target'] ?? '';
        if (!valid_conf($f)) j(['ok' => false, 'output' => 'invalid filename']);
        if (!isset($_FILES['conf_upload'])) j(['ok' => false, 'output' => 'missing upload']);
        $args = ['action-run', 'write-conf', $f, $_FILES['conf_upload']['tmp_name']];
    } else {
        j(['ok' => false, 'output' => 'Unknown action']);
    }

    [$rc, $out] = run_helper($args, true);
    j(['ok' => $rc === 0, 'output' => $out]);
}

function badge($on, $onTxt, $offTxt) {
    return $on ? '<span class="badge on">' . h($onTxt) . '</span>' : '<span class="badge off">' . h($offTxt) . '</span>';
}
function vers($raw) {
    if (!$raw) return '-';
    $o = [];
    foreach (explode(';', $raw) as $p) {
        if (strpos($p, '=') === false) continue;
        [$k, $v] = explode('=', $p, 2);
        if (preg_match('/^(CORE|WEB|FTL)_VERSION$/', $k) && stripos($v, 'N/A') === false) $o[] = h($k . '=' . $v);
    }
    return $o ? implode('<br>', $o) : '-';
}
function tpl($t, $vars, $L) {
    foreach ($L as $k => $v) $t = str_replace('{{' . $k . '}}', h($v), $t);
    foreach ($vars as $k => $v) $t = str_replace('{{' . $k . '}}', $v, $t);
    return $t;
}
function conf_list_html() {
    [$rc, $out] = run_helper(['list-confs'], true);
    if ($rc !== 0 || trim($out) === '') return '-';
    $html = '<ul>';
    foreach (array_filter(explode("\n", trim($out))) as $f) {
        $hf = h($f);
        $html .= "<li><button type=\"button\" data-role=\"none\" class=\"phm-filelink\" data-file=\"$hf\">$hf</button></li>";
    }
    return $html . '</ul>';
}

[$rc, $out] = run_helper(['status'], true);
$s = json_decode($out, true) ?: [];
$installed = ($s['pihole_installed'] ?? '') === 'true';
$host = preg_replace('/:\d+$/', '', $_SERVER['HTTP_HOST'] ?? 'loxberry');
$port = $s['web_port'] ?? '';
$target = $installed && $port ? $port : ($s['target_web_port'] ?? 8000);
$ftl = (($s['pihole_ftl_active'] ?? '') === 'true') ? badge(true, $L['STATUS.ACTIVE'], $L['STATUS.INACTIVE']) : badge(false, $L['STATUS.ACTIVE'], $L['STATUS.INACTIVE']);
if (!empty($s['pihole_ftl_pid'])) $ftl .= ' <span class="pid">PID ' . h($s['pihole_ftl_pid']) . '</span>';
$icon = plugin_icon_uri();
$pluginUrlFolder = rawurlencode(LBPPLUGINDIR);

$vars = [
    'PLUGIN_ICON_URI' => h($icon),
    'PLUGIN_ICON_STYLE' => $icon ? '' : 'display:none',
    'INSTALLED_BADGE' => $installed ? badge(true, $L['STATUS.INSTALLED'], $L['STATUS.NOT_INSTALLED']) : badge(false, $L['STATUS.INSTALLED'], $L['STATUS.NOT_INSTALLED']),
    'FTL_HTML' => $ftl,
    'VERSIONS_HTML' => vers($s['versions'] ?? ''),
    'WEB_PORT' => $installed && $port ? h($port) : '-',
    'TARGET_PORT' => h($target),
    'PIHOLE_URL' => 'http://' . h($host) . ':' . h($port) . '/admin',
    'OPEN_STYLE' => $installed && $port ? '' : 'display:none',
    'DHCP_BADGE' => badge(($s['dhcp_active'] ?? '') === 'true', $L['STATUS.ACTIVE'], $L['STATUS.INACTIVE']),
    'DNSMASQ_BADGE' => badge(($s['etc_dnsmasq_d'] ?? '') === 'true', $L['STATUS.ACTIVE'], $L['STATUS.INACTIVE']),
    'GRAVITY_BADGE' => badge(($s['gravity_list_present'] ?? '') === 'true', $L['STATUS.PRESENT'], $L['STATUS.MISSING']),
    'INSTALL_STYLE' => $installed ? 'display:none' : '',
    'INSTALL_LOG_URL' => '/admin/system/tools/logfile.cgi?logfile=plugins/' . $pluginUrlFolder . '/install.log&amp;header=html&amp;format=template',
    'ACTIONS_LOG_URL' => '/admin/system/tools/logfile.cgi?logfile=plugins/' . $pluginUrlFolder . '/actions.log&amp;header=html&amp;format=template',
    'PORT_FIELD' => h($target),
    'CONF_LIST' => conf_list_html()
];

try { LBWeb::lbheader($L['APP.TITLE'], '', 'help.html', true); }
catch (Throwable $e) { LBWeb::lbheader($L['APP.TITLE'], '', 'help.html'); }

$cssHref = '/plugins/' . rawurlencode(LBPPLUGINDIR) . '/css/piholemanager.css?v=1110';
echo '<link rel="stylesheet" href="' . h($cssHref) . '">';
echo tpl(file_get_contents(LBPTEMPLATEDIR . '/main.html'), $vars, $L);
?>
<script>
const T={running:<?=json_encode($L['ACTIONS.RUNNING'])?>,success:<?=json_encode($L['ACTIONS.SUCCESS'])?>,error:<?=json_encode($L['ACTIONS.ERROR'])?>,installStarted:<?=json_encode($L['INSTALL.STARTED'])?>,installFailed:<?=json_encode($L['INSTALL.FAILED'])?>,initial:<?=json_encode($L['INSTALL.INITIAL_PASSWORD'])?>};
const I18N={installed:<?=json_encode($L['STATUS.INSTALLED'])?>,notInstalled:<?=json_encode($L['STATUS.NOT_INSTALLED'])?>,active:<?=json_encode($L['STATUS.ACTIVE'])?>,inactive:<?=json_encode($L['STATUS.INACTIVE'])?>,present:<?=json_encode($L['STATUS.PRESENT'])?>,missing:<?=json_encode($L['STATUS.MISSING'])?>};
const esc=s=>String(s||'').replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]));

function phmBadge(v,on='Aktiv',off='Aus'){
  return String(v)==='true'?'<span class="badge on">'+on+'</span>':'<span class="badge off">'+off+'</span>';
}
function phmVersions(raw){
  if(!raw)return '-';
  let a=[];
  raw.split(';').forEach(p=>{
    let m=p.split('=');
    if(m.length>=2&&!/N\/A/i.test(m.slice(1).join('='))&&/^(CORE|WEB|FTL)_VERSION$/.test(m[0]))a.push(esc(m[0]+'='+m.slice(1).join('=')));
  });
  return a.length?a.join('<br>'):'-';
}

function initPortDirtyTracking(){
  const wp=document.querySelector('input[name=web_port]');
  if(!wp || wp.dataset.phmDirtyInit==='true') return;
  wp.dataset.phmDirtyInit='true';
  wp.dataset.dirty='false';
  wp.addEventListener('input',()=>{wp.dataset.dirty='true';});
  wp.addEventListener('change',()=>{wp.dataset.dirty='true';});
}

async function refreshStatus(){
  try{
    let s=await fetch('?ajax=status',{cache:'no-store'}).then(r=>r.json());
    let inst=s.pihole_installed==='true';
    let install=document.getElementById('install-card');
    if(install)install.style.display=inst?'none':'';
    let st=document.getElementById('st-installed');
    if(st)st.innerHTML=inst?phmBadge(true,I18N.installed,I18N.notInstalled):phmBadge(false,I18N.installed,I18N.notInstalled);
    let f=s.pihole_ftl_active==='true'?phmBadge(true,I18N.active,I18N.inactive):phmBadge(false,I18N.active,I18N.inactive);
    if(s.pihole_ftl_pid)f+=' <span class="pid">PID '+esc(s.pihole_ftl_pid)+'</span>';
    let ftl=document.getElementById('st-ftl');
    if(ftl)ftl.innerHTML=f;
    let ver=document.getElementById('st-ver');
    if(ver)ver.innerHTML=phmVersions(s.versions);
    let port=document.getElementById('st-port');
    if(port)port.innerHTML=(inst&&s.web_port)?esc(s.web_port):'-';
    let target=(inst&&s.web_port)?s.web_port:(s.target_web_port||'');
    let tgt=document.getElementById('st-target');
    if(tgt)tgt.innerHTML=esc(target);
    let wp=document.querySelector('input[name=web_port]');
    if(wp&&target&&document.activeElement!==wp&&wp.dataset.dirty!=='true')wp.value=target;
    let dh=document.getElementById('st-dhcp');
    if(dh)dh.innerHTML=phmBadge(s.dhcp_active,I18N.active,I18N.inactive);
    let dm=document.getElementById('st-dnsmasq');
    if(dm)dm.innerHTML=phmBadge(s.etc_dnsmasq_d,I18N.active,I18N.inactive);
    let grav=document.getElementById('st-gravity');
    if(grav)grav.innerHTML=phmBadge(s.gravity_list_present,I18N.present,I18N.missing);
    let l=document.getElementById('open-pihole');
    if(l){
      if(inst&&s.web_port){l.style.display='inline-block';l.href='http://'+location.host.replace(/:\d+$/,'')+':'+s.web_port+'/admin';}
      else l.style.display='none';
    }
  }catch(e){console.log(e);}
}

function fdFrom(box,a){
  let fd=new FormData();
  fd.append('ajax','action');
  fd.append('action',a);
  box.querySelectorAll('input[name],textarea[name]').forEach(i=>fd.append(i.name,i.value));
  let ed=document.getElementById('conf-editor'),cur=document.getElementById('conf-current');
  if(ed)fd.append('conf_text',ed.value);
  if(cur)fd.append('conf_file',cur.value);
  let uf=document.querySelector('input[name=conf_upload]');
  if(uf&&uf.files[0])fd.append('conf_upload',uf.files[0]);
  return fd;
}

async function run(btn){
  let box=document.getElementById(btn.dataset.box||btn.closest('[data-box]').dataset.box),old=btn.textContent;
  btn.disabled=true;
  btn.textContent=T.running;
  box.style.display='block';
  box.innerHTML=T.running;
  let action=btn.dataset.action;
  let r=await fetch(location.pathname,{method:'POST',body:fdFrom(btn.closest('[data-box]')||btn.parentElement,action)}).then(r=>r.json()).catch(e=>({ok:false,output:String(e)}));
  box.innerHTML=(r.ok?T.success:T.error)+'<pre>'+esc(r.output||'')+'</pre>';
  btn.disabled=false;
  btn.textContent=old;
  if(action==='set_port' && r.ok){
    let wp=document.querySelector('input[name=web_port]');
    if(wp)wp.dataset.dirty='false';
  }
  if(['template_custom','conf_save','conf_delete','conf_upload'].includes(action))loadList();
  await refreshStatus();
}

async function loadList(){
  let r=await fetch('?ajax=conf_list',{cache:'no-store'}).then(r=>r.json());
  let html='<ul>';
  (r.files||[]).forEach(f=>html+='<li><button type="button" data-role="none" class="phm-filelink" data-file="'+esc(f)+'">'+esc(f)+'</button></li>');
  html+='</ul>';
  document.getElementById('conf-list').innerHTML=html;
  bindFileLinks();
}
function bindFileLinks(){
  document.querySelectorAll('.phm-filelink').forEach(b=>b.onclick=async()=>{
    let f=b.dataset.file;
    let r=await fetch('?ajax=conf_read&file='+encodeURIComponent(f),{cache:'no-store'}).then(r=>r.json());
    document.getElementById('conf-current').value=f;
    document.getElementById('conf-editor').value=r.output||'';
  });
}

document.querySelectorAll('.phm-action').forEach(b=>b.onclick=()=>run(b));
bindFileLinks();
initPortDirtyTracking();

document.getElementById('install-btn')?.addEventListener('click',async()=>{
  let box=document.getElementById('install-status');
  box.style.display='block';
  box.innerHTML=T.running;
  let fd=new FormData();
  fd.append('ajax','install_start');
  fd.append('web_port',document.getElementById('st-target').innerText||'8000');
  let r=await fetch(location.pathname,{method:'POST',body:fd}).then(r=>r.json()).catch(e=>({ok:false,output:String(e)}));
  box.innerHTML=(r.ok?T.installStarted:T.installFailed)+'<pre>'+esc(r.output||'')+'</pre>';
  let t=setInterval(async()=>{
    let s=await fetch('?ajax=install_state',{cache:'no-store'}).then(r=>r.json());
    let extra=s.initial_password?'\n'+T.initial+': '+s.initial_password:'';
    box.innerHTML=esc((s.message||s.state)+extra);
    await refreshStatus();
    if(['success','partial'].includes(s.state)){clearInterval(t);await refreshStatus();}
  },3000);
});
setInterval(refreshStatus,5000);
refreshStatus();
</script>
<?php LBWeb::lbfooter(); ?>
