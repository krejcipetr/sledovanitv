# sledovanitv

Jako výchozí podklad jsem použil skript od JiRo (XMBC-Kodi.cz)

Soubor skriptu pro implementaci SledovaniTV.cz do tvheadendu a kodi. Diky implementaci do tvheadendu funguje je nahravani a timeshift
Podporovano je prehravani a EPG

- sledovanitv-autoconfig.sh - je pipe pro automatickou konfiguraci IPTV site
- sledovanitv-epg.sh - na stdout jde EPG celeho sledovanitv na 1 den dopredu 1439s
- sledovanitv-register.sh - slouží k počáteční registraci zařízení

## Postup zprovoznění

### Instalace

Pro Kodi v AmLogic 912/ Linux
- v adresáři $HOME vytvořit adresář _sledovanitv_ (/storage/sledovanitv)
- nahrát do něj soubory z githubu, musí mít právo na spuštění (chmod +x /storage/sledovanitv*.sh /storage/sledovanitv*.py)
- v KODI instalovat balíčky: System Tools, FFmpeg tools, tvheadend server

### Registrace zařízení

- cd $HOME/sledovanitv
- ./sledovanitv-register.sh   vyplnit přihlašovací údaje do sledovánítv. Skript vytvoří nový soubor config.json s authentizačními údaji pro zařízení

### Zprovoznění EPG

Z důvodu, že sledování má kanály pojmenované různě, tak je vhodné nejdříve uprovoznít EPG, které obsahuje identifikátory jednotlivých kanálů

- v konfiguraci doplnku tvh-server, nastavit v XMLTV: 
  - XMLTV source type: SCRIPT
  - XML Script location vybrat sledovanitv-epg.sh
- přihlásit se do webu tvh-serveru http://kodi:9981/
- v části Konfigurace/Program EPG/Moduly EPG grabberů povolit _Interní XMLTV: tv_grab_file is a simple grabber that can be configured through the addon settings from Kodi_
- restartovat tvh-server - zakázat/povolit doplněk
- chvíli počkat
- zpět do webu a v části Konfigurace/Program EPG/Programy EPG grabberů by jste měli vidět seznam všech kanálů v sledovánítv. i těch na které nemáte právo.

### Zprovoznění kanálu

Postup je zcela odlisny od prodchozi koncepce, kdy se vkladaly jednotlive MUXy rucne. Ted jsou vlozeny playlistem z M3U8 souboru, ktery je generovany skriptem sledovenitv-autoconfig.sh

- Konfigurace/DVB vstupy/Sítě přidat novou Atuomatic IPTV Network
  - název: SledováníTV
  - max pocet streamu: 4
  - Ignorovat čísla programů od poskytovatele: true
  - priorita: 10
  - Skip startup scan: false
  - URL: pipe:///storage/sledovanitv/sledovanitv-autoconfig.sh
- přejit do Sluzeb a namapovat sluzbu

## Troubleshooting

- pokud se něco v kodi neprojeví, ale je to vidět v TVH-serveru, tak restart KODI poumůže, stačí KODI, nemusí se celý přehrávač
- v WWW je dole lišta, která když se rozbalí, tak je vidět LOG TVH-serveru
- v sh skriptem můžete udělat debug pomoci přídaní -x na první řádek, výstup opět do logu TVH-serveru
- pokud jste prisli o oprava k sledovanitv, zkuste promazat /storage/.cache/playlist* /storage/.cache/sledovanitv

  

