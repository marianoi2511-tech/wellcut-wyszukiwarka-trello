Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { [AppDomain]::CurrentDomain.BaseDirectory }
$ConfigPath = Join-Path $env:LOCALAPPDATA "WELLCUT\WyszukiwarkaTrello\config.json"
$LogPath = Join-Path $env:LOCALAPPDATA "WELLCUT\WyszukiwarkaTrello\log.txt"
New-Item -ItemType Directory -Force -Path (Split-Path $ConfigPath) | Out-Null
$script:cancelRequested=$false;$script:isSearching=$false
function Escape([string]$s){[uri]::EscapeDataString($s.Trim())}
function Protect-Text([string]$s){if(!$s){return ""};ConvertFrom-SecureString (ConvertTo-SecureString $s -AsPlainText -Force)}
function Unprotect-Text([string]$s){if(!$s){return ""};try{$sec=ConvertTo-SecureString $s;$p=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec);try{[Runtime.InteropServices.Marshal]::PtrToStringBSTR($p)}finally{[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($p)}}catch{$s}}
function Save-Config($b1,$b2){[ordered]@{version=8;board1=[ordered]@{name=$b1.name.Trim();apiKey=Protect-Text $b1.apiKey;token=Protect-Text $b1.token;boardUrl=$b1.boardUrl.Trim()};board2=[ordered]@{name=$b2.name.Trim();apiKey=Protect-Text $b2.apiKey;token=Protect-Text $b2.token;boardUrl=$b2.boardUrl.Trim()}}|ConvertTo-Json -Depth 5|Set-Content $ConfigPath -Encoding UTF8}
function Load-Config{if(Test-Path $ConfigPath){try{$c=Get-Content $ConfigPath -Raw|ConvertFrom-Json;foreach($b in @($c.board1,$c.board2)){$b.apiKey=Unprotect-Text ([string]$b.apiKey);$b.token=Unprotect-Text ([string]$b.token)};return $c}catch{}};[pscustomobject]@{board1=[pscustomobject]@{name='Tablica 1';apiKey='';token='';boardUrl=''};board2=[pscustomobject]@{name='Tablica 2';apiKey='';token='';boardUrl=''}}}
function BoardId([string]$v){$v=$v.Trim();if($v -match '(?i)trello\.com/b/([A-Za-z0-9]+)'){return $Matches[1]};if($v -match '^[A-Za-z0-9]{6,32}$'){return $v};throw 'Wklej prawidłowy link do tablicy Trello.'}
function BaseName([string]$n){(($n -split '\\')[0]).Trim()}
function Price([string]$n){$p=$n -split '\\';if($p.Count-lt 2){return ''};$x=$p[-1].Trim();if($x -match '^\d+(?:[,.]\d{1,2})?$'){return ($x-replace '\.',',')+' zł'};''}
function MakeLabel($parent,[string]$text,[int]$x,[int]$y,[int]$size=10,[bool]$bold=$false,$color=[Drawing.Color]::Empty){$l=New-Object Windows.Forms.Label;$l.Text=$text;$l.Location=[Drawing.Point]::new($x,$y);$l.AutoSize=$true;$style=if($bold){[Drawing.FontStyle]::Bold}else{[Drawing.FontStyle]::Regular};$l.Font=[Drawing.Font]::new('Segoe UI',$size,$style);if($color -ne [Drawing.Color]::Empty){$l.ForeColor=$color};$parent.Controls.Add($l);$l}
function MakeText($parent,[int]$x,[int]$y,[int]$w){$t=New-Object Windows.Forms.TextBox;$t.Location=[Drawing.Point]::new($x,$y);$t.Size=[Drawing.Size]::new($w,32);$t.Font=[Drawing.Font]::new('Segoe UI',11);$parent.Controls.Add($t);$t}
function MakeButton($parent,[string]$text,[int]$x,[int]$y,[int]$w,$bg){$b=New-Object Windows.Forms.Button;$b.Text=$text;$b.Location=[Drawing.Point]::new($x,$y);$b.Size=[Drawing.Size]::new($w,38);$b.FlatStyle='Flat';$b.Font=[Drawing.Font]::new('Segoe UI',9,[Drawing.FontStyle]::Bold);$b.BackColor=$bg;$b.ForeColor=[Drawing.Color]::White;$parent.Controls.Add($b);$b}
$navy=[Drawing.Color]::FromArgb(20,36,60);$blue=[Drawing.Color]::FromArgb(37,99,235);$red=[Drawing.Color]::FromArgb(220,38,38);$muted=[Drawing.Color]::FromArgb(100,116,139);$white=[Drawing.Color]::White
$form=New-Object Windows.Forms.Form;$form.Text='WELLCUT - Wyszukiwarka Trello';$form.Size=[Drawing.Size]::new(1180,760);$form.MinimumSize=[Drawing.Size]::new(980,650);$form.StartPosition='CenterScreen';$form.Font=[Drawing.Font]::new('Segoe UI',10);$form.BackColor=[Drawing.Color]::FromArgb(244,247,251)
$header=New-Object Windows.Forms.Panel;$header.Dock='Top';$header.Height=76;$header.BackColor=$navy;$form.Controls.Add($header)
$logo=New-Object Windows.Forms.Label;$logo.Text='W';$logo.Location=[Drawing.Point]::new(22,14);$logo.Size=[Drawing.Size]::new(48,48);$logo.TextAlign='MiddleCenter';$logo.BackColor=$blue;$logo.ForeColor=$white;$logo.Font=[Drawing.Font]::new('Segoe UI',24,[Drawing.FontStyle]::Bold);$header.Controls.Add($logo)
[void](MakeLabel $header 'WELLCUT' 84 14 16 $true $white);[void](MakeLabel $header 'Wyszukiwarka Trello' 84 42 10 $false ([Drawing.Color]::FromArgb(203,213,225)))
$btnSettings=MakeButton $header 'USTAWIENIA' 1000 19 140 ([Drawing.Color]::FromArgb(51,65,85));$btnSettings.Anchor='Top,Right'
$card=New-Object Windows.Forms.Panel;$card.Location=[Drawing.Point]::new(20,94);$card.Size=[Drawing.Size]::new(1125,168);$card.Anchor='Top,Left,Right';$card.BackColor=$white;$form.Controls.Add($card)
[void](MakeLabel $card 'Wyszukiwanie detali' 20 14 13 $true $navy);[void](MakeLabel $card 'Przeszukaj jedną lub obie tablice Trello' 20 42 9 $false $muted)
[void](MakeLabel $card 'TABLICE' 20 74 8 $true $muted);$cmb=New-Object Windows.Forms.ComboBox;$cmb.Location=[Drawing.Point]::new(20,96);$cmb.Size=[Drawing.Size]::new(260,30);$cmb.DropDownStyle='DropDownList';$card.Controls.Add($cmb)
[void](MakeLabel $card 'KLIENT' 305 74 8 $true $muted);$txtClient=MakeText $card 305 96 260;[void](MakeLabel $card 'puste = wszystkie karty' 305 130 8 $false $muted)
[void](MakeLabel $card 'SZUKAJ POZYCJI / DETALU' 590 74 8 $true $muted);$txtSearch=MakeText $card 590 96 310;$btnSearch=MakeButton $card 'SZUKAJ' 920 94 100 $blue;$btnStop=MakeButton $card 'PRZERWIJ' 1028 94 80 $red;$btnStop.Enabled=$false
$status=MakeLabel $form 'Gotowy' 36 290 9 $true $navy
$grid=New-Object Windows.Forms.DataGridView;$grid.Location=[Drawing.Point]::new(20,332);$grid.Size=[Drawing.Size]::new(1125,365);$grid.Anchor='Top,Bottom,Left,Right';$grid.ReadOnly=$true;$grid.AllowUserToAddRows=$false;$grid.RowHeadersVisible=$false;$grid.SelectionMode='FullRowSelect';$grid.AutoSizeColumnsMode='Fill';$form.Controls.Add($grid)
foreach($c in @(@('Tablica','TABLICA'),@('Pozycja','NAZWA DETALU'),@('Karta','KARTA / KLIENT'),@('Cena','CENA'),@('Url','URL'))){[void]$grid.Columns.Add($c[0],$c[1])};$grid.Columns['Url'].Visible=$false
$script:cfg=Load-Config
function RefreshNames{$cmb.Items.Clear();[void]$cmb.Items.Add('Obie tablice');[void]$cmb.Items.Add($(if($script:cfg.board1.name){$script:cfg.board1.name}else{'Tablica 1'}));[void]$cmb.Items.Add($(if($script:cfg.board2.name){$script:cfg.board2.name}else{'Tablica 2'}));$cmb.SelectedIndex=0};RefreshNames
$btnSettings.Add_Click({
 $s=New-Object Windows.Forms.Form;$s.Text='WELLCUT - Ustawienia Trello';$s.Size=[Drawing.Size]::new(720,520);$s.StartPosition='CenterParent';$s.Font=$form.Font
 $controls=@()
 foreach($i in 0..1){$b=if($i -eq 0){$script:cfg.board1}else{$script:cfg.board2};$y=20+($i*205)
  [void](MakeLabel $s ('TABLICA '+($i+1)) 15 $y 11 $true $navy)
  [void](MakeLabel $s 'Nazwa:' 15 ($y+38));$n=MakeText $s 115 ($y+34) 560
  [void](MakeLabel $s 'API Key:' 15 ($y+73));$a=MakeText $s 115 ($y+69) 560;$a.UseSystemPasswordChar=$true
  [void](MakeLabel $s 'Token:' 15 ($y+108));$t=MakeText $s 115 ($y+104) 560;$t.UseSystemPasswordChar=$true
  [void](MakeLabel $s 'Link tablicy:' 15 ($y+143));$u=MakeText $s 115 ($y+139) 560
  $n.Text=$b.name;$a.Text=$b.apiKey;$t.Text=$b.token;$u.Text=$b.boardUrl;$controls+=,[pscustomobject]@{n=$n;a=$a;t=$t;u=$u}
 }
 $show=New-Object Windows.Forms.CheckBox;$show.Text='Pokaż API Key i tokeny';$show.Location=[Drawing.Point]::new(15,435);$show.AutoSize=$true;$s.Controls.Add($show)
 $show.Add_CheckedChanged({foreach($x in $controls){$x.a.UseSystemPasswordChar=-not $show.Checked;$x.t.UseSystemPasswordChar=-not $show.Checked}})
 $save=MakeButton $s 'ZAPISZ' 580 425 105 $blue
 $save.Add_Click({$b1=@{name=$controls[0].n.Text;apiKey=$controls[0].a.Text;token=$controls[0].t.Text;boardUrl=$controls[0].u.Text};$b2=@{name=$controls[1].n.Text;apiKey=$controls[1].a.Text;token=$controls[1].t.Text;boardUrl=$controls[1].u.Text};Save-Config $b1 $b2;$script:cfg=Load-Config;RefreshNames;$s.Close()})
 [void]$s.ShowDialog($form)
})
$btnStop.Add_Click({$script:cancelRequested=$true})
$btnSearch.Add_Click({
 try{$q=$txtSearch.Text.Trim();if(!$q){throw 'Wpisz nazwę detalu.'};$client=$txtClient.Text.Trim();$boards=switch($cmb.SelectedIndex){1{@($script:cfg.board1)}2{@($script:cfg.board2)}default{@($script:cfg.board1,$script:cfg.board2)}};$boards=@($boards|Where-Object{$_.apiKey -and $_.token -and $_.boardUrl});if(!$boards.Count){throw 'Najpierw uzupełnij USTAWIENIA.'};$grid.Rows.Clear();$script:cancelRequested=$false;$btnStop.Enabled=$true
 foreach($b in $boards){if($script:cancelRequested){break};$id=BoardId $b.boardUrl;$key=Escape $b.apiKey;$tok=Escape $b.token;$bn=$b.name;$status.Text="[$bn] Pobieram karty...";[Windows.Forms.Application]::DoEvents();$cards=Invoke-RestMethod "https://api.trello.com/1/boards/$id/cards/all?fields=id,name,url&key=$key&token=$tok" -TimeoutSec 30
  foreach($c in $cards){[Windows.Forms.Application]::DoEvents();if($script:cancelRequested){break};if($client -and $c.name.IndexOf($client,[StringComparison]::OrdinalIgnoreCase)-lt 0){continue};$lists=Invoke-RestMethod "https://api.trello.com/1/cards/$($c.id)/checklists?checkItems=all&fields=name&key=$key&token=$tok" -TimeoutSec 20
   foreach($cl in $lists){if($cl.name -ne 'Lista zadań'){continue};foreach($it in $cl.checkItems){$base=BaseName $it.name;if($base.IndexOf($q,[StringComparison]::OrdinalIgnoreCase)-ge 0){[void]$grid.Rows.Add($bn,$base,$c.name,(Price $it.name),$c.url)}}}
  }
 };$status.Text=if($script:cancelRequested){'Wyszukiwanie przerwane'}else{'Gotowe'}
 }catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Błąd');$status.Text='Błąd'}finally{$btnStop.Enabled=$false}
})
$grid.Add_CellDoubleClick({param($sender,$e);if($e.RowIndex -ge 0){$u=[string]$grid.Rows[$e.RowIndex].Cells['Url'].Value;if($u){Start-Process $u}}})
[void]$form.ShowDialog()
